<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
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

require_once 'lib/extensions/DOCframe_Resource.php';

/**
 * AIRAPI Fields
 *
 * Static class to define some shared object-field definitions for API
 * resources.  (Since PHP doesn't allow const arrays).
 *
 * @author rcavis
 * @package default
 */
class AIRAPI_Fields {

    // special fields will start with
    const FLAG = 'DEF::';

    /**
     * Replace any DEF::SOMETHING fields in an array with self::$SOMETHING
     *
     * @param array $fields (reference)
     */
    public static function replace_defaults(&$fields) {
        if (!is_array($fields)) {
            return;
        }

        $len = strlen(self::FLAG);
        foreach ($fields as $idx => $val) {
            // recurse on arrays
            if (is_string($idx) && is_array($val)) {
                self::replace_defaults($fields[$idx]);
            }

            // look for strings starting with self::FLAG
            if (is_string($val) && substr($val, 0, $len) == self::FLAG) {
                $name = substr($val, $len);

                if (!isset(self::$DEFAULTS[$name])) {
                    throw new Exception("Invalid $name in $val");
                }

                // add these fields to the def
                if (is_int($idx)) {
                    unset($fields[$idx]);

                    // since this could be assoc-array, insert manually
                    foreach (self::$DEFAULTS[$name] as $i => $fld) {
                        if ($i == 0) $fields[$idx] = $fld;
                        else $fields[] = $fld;
                    }
                }
                elseif (is_string($idx)) {
                    $fields[$idx] = self::$DEFAULTS[$name];
                }
            }
        }
    }


    // define default fields
    public static $DEFAULTS = array(
        'SOURCE' => array(
            'src_uuid',
            'src_username',
            'src_first_name',
            'src_last_name',
            'src_middle_initial',
            'src_pre_name',
            'src_post_name',
            'src_status',
            'src_has_acct',
            'src_channel',
        ),
        'USERSTAMP' => array(
            'user_uuid',
            'user_username',
            'user_first_name',
            'user_last_name',
            'user_type',
            'user_status',
        ),
        'USERORG' => array(
            'uo_uuid',
            'uo_home_flag',
            'uo_user_title',
            'Organization' => array(
                'org_uuid',
                'org_name',
                'org_display_name',
                'org_html_color'
            ),
            'AdminRole' => array(
                'ar_id',
                'ar_code',
                'ar_name',
            ),
        ),
        'ORGANIZATION' => array(
            'org_uuid',
            'org_name',
            'org_logo_uri',
            'org_display_name',
            'org_type',
            'org_status',
            'org_html_color',
        ),
        'INQUIRY' => array(
            'inq_uuid',
            'inq_title',
            'inq_ext_title',
            'inq_publish_dtim',
            'inq_deadline_dtim',
            'inq_desc',
            'inq_type',
            'inq_status',
            'inq_stale_flag',
            'inq_cre_dtim',
            'inq_upd_dtim',
        ),
        'PROJECT' => array(
            'prj_uuid',
            'prj_name',
            'prj_display_name',
            'prj_desc',
            'prj_status',
            'prj_type',
        ),
        'TANK' => array(
            'tank_uuid',
            'tank_name',
            'tank_notes',
            'tank_meta',
            'tank_type',
            'tank_status',
            'tank_cre_dtim',
            'tank_upd_dtim',
        ),
        'SRCEMAIL' => array(
            'sem_uuid',
            'sem_primary_flag',
            'sem_context',
            'sem_email',
            'sem_effective_date',
            'sem_expire_date',
            'sem_status',
        ),
        'SRCPHONE' => array(
            'sph_uuid',
            'sph_primary_flag',
            'sph_context',
            'sph_country',
            'sph_number',
            'sph_ext',
            'sph_status',
        ),
        'SRCMAIL' => array(
            'smadd_uuid',
            'smadd_primary_flag',
            'smadd_context',
            'smadd_line_1',
            'smadd_line_2',
            'smadd_city',
            'smadd_state',
            'smadd_cntry',
            'smadd_county',
            'smadd_zip',
            'smadd_lat',
            'smadd_long',
            'smadd_status',
        ),
        'SRCRESPONSESET' => array(
            'srs_uuid',
        ),
        'SRCRESPONSE' => array(
            'sr_uuid',
            'sr_media_asset_flag',
            'sr_orig_value',
            'sr_mod_value',
            'sr_status',
            'SrAnnotation' => array(
                'sran_value',
            )
        ),
        'FACTVALUE' => array(
            'fv_seq',
            'fv_value',
            'fv_status',
        ),
        'IMAGE' => array(
            'img_uuid',
            'img_file_name',
            'img_file_size',
            'img_content_type',
            'img_dtim',
        ),
        'LOCALE' => array(
            'loc_key',
            'loc_lang',
            'loc_region'
        ),
        'USERSIGNATURE' => array(
            'usig_uuid',
            'usig_text',
            'usig_status',
            'User' => array(
                'user_uuid',
                'user_username',
                'user_first_name',
                'user_last_name',
                'user_type',
                'user_status',
            ),
        ),
        'EMAIL' => array(
            'email_uuid',
            'email_campaign_name',
            'email_from_name',
            'email_from_email',
            'email_subject_line',
            'email_type',
            'email_status',
        ),
    );


}
