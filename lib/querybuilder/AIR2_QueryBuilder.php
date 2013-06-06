<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/


/**
 * AIR2_QueryBuilder utility class
 *
 * Static class for Query Building functions
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2_QueryBuilder {

    // cached template definition file
    protected static $TPL_DEFS = false;


    /**
     * Cache the template file
     */
    protected static function cache_template_file() {
        if (!self::$TPL_DEFS) {
            $path = dirname(__FILE__).'/templates.php';
            @include $path;
            self::$TPL_DEFS = $qb_templates;
        }
    }


    /**
     * Get the contents of the template definition file.
     *
     * @return array $defs
     */
    public static function get_defs() {
        self::cache_template_file();
        return self::$TPL_DEFS;
    }


    /**
     * Update a new question from a template definition.
     *
     * @param Question $q
     * @param string   $tpl_name
     */
    public static function make_question(Question $q, $tpl_name) {
        self::cache_template_file();
        if (!isset(self::$TPL_DEFS[$tpl_name])) {
            throw new Exception("Invalid template name '$tpl_name'");
        }

        $tpl = self::$TPL_DEFS[$tpl_name];
        foreach ($tpl as $key => $val) {

            // special localization consideration for question value
            if ($key == 'ques_value' || $key == 'ques_choices') {
                $loc_key = $q->Inquiry->Locale->loc_key;
                if (array_key_exists($loc_key, $val)) {
                    $val = $val[$loc_key];
                }
                else {
                    $val = $val['en_US'];
                }
                $val = is_array($val) ? json_encode($val) : $val;
                $q->$key = $val;
            }
            elseif (preg_match('/^ques_/', $key)) {
                $val = is_array($val) ? json_encode($val) : $val;
                $q->$key = $val;
            }
        }
        $q->ques_template = $tpl_name;
    }


    /**
     * Update a new question from an existing question
     *
     * @param Question $q
     * @param string   $ques_uuid
     */
    public static function copy_question(Question $q, $ques_uuid) {
        $from = AIR2_Record::find('Question', $ques_uuid);
        if (!$from) throw new Exception("Invalid ques_uuid($ques_uuid)");

        $from_array = $from->toArray();

        $reset_keys = array(
            'ques_id',
            'ques_uuid',
            'ques_inq_id',
            'ques_upd_user',
            'ques_upd_dtim',
            'ques_cre_user',
            'ques_cre_dtim',
        );

        foreach ($reset_keys as $reset_key) {
            $from_array[$reset_key] = NULL;
            unset($from_array[$reset_key]);
        }

        $q->fromArray($from_array);
    }


}
