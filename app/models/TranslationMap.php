<?php
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

/**
 * TranslationMap
 *
 * Fact value mapping table
 *
 * @property integer   $xm_id
 * @property integer   $xm_fact_id
 * @property string    $xm_xlate_from
 * @property integer   $xm_xlate_to_fv_id
 * @property Fact      $Fact
 * @property FactValue $FactValue
 * @author rcavis
 * @package default
 */
class TranslationMap extends AIR2_Record {
    /* cache of translated values we've already looked up */
    protected static $xlate_cache = array();

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('translation_map');
        $this->hasColumn('xm_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('xm_fact_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('xm_xlate_from', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('xm_xlate_to_fv_id', 'integer', 4, array(
                'notnull' => true,
            ));

        $this->hasColumn('xm_cre_dtim', 'timestamp', null, array(
                'notnull' => false,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Fact', array(
                'local' => 'xm_fact_id',
                'foreign' => 'fact_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('FactValue', array(
                'local' => 'xm_xlate_to_fv_id',
                'foreign' => 'fv_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Find a translation for a given text, if one exists.  Returns null if not
     * found, otherwise the fv_id.
     *
     * @param int     $fact_id
     * @param string  $text
     * @return null|int
     */
    public static function find_translation($fact_id, $text) {
        $lower = strtolower($text);

        // look for a cached value
        if (isset(self::$xlate_cache[$fact_id])) {
            if (isset(self::$xlate_cache[$fact_id][$lower])) {
                return self::$xlate_cache[$fact_id][$lower];
            }
        }

        // lookup
        $conn = AIR2_DBManager::get_connection();
        $q = 'select xm_xlate_to_fv_id from translation_map where ' .
            'xm_fact_id = ? and xm_xlate_from = ?';
        $fv_id = $conn->fetchOne($q, array($fact_id, $text), 0);

        // cache
        if (!isset(self::$xlate_cache[$fact_id])) {
            self::$xlate_cache[$fact_id] = array();
        }
        self::$xlate_cache[$fact_id][$lower] = $fv_id;
        return $fv_id;
    }


    /**
     * Translations are public
     *
     * @param User    $u
     * @return int
     */
    public function user_may_read(User $u) {
        return AIR2_AUTHZ_IS_PUBLIC;
    }


    /**
     * WRITER in any Organization may write.
     *
     * @param User    $u
     * @return int
     */
    public function user_may_write(User $u) {
        if ($u->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // look for WRITER role in any organization
        $authz = $u->get_authz();
        foreach ($authz as $orgid => $role) {
            if (ACTION_ORG_UPDATE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }

        // no WRITER role found
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Same as writing.
     *
     * @param User    $u
     * @return int
     */
    public function user_may_manage(User $u) {
        return $this->user_may_write($u);
    }


    /**
     * Add a query string to for "from" text
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr  (optional)
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "{$a}xm_xlate_from like ?";
        if ($useOr) {
            $q->orWhere($str, array("%$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%"));
        }
    }


    /**
     * Custom validation to enforce uniqueness-per-fact of xm_xlate_from.
     *
     * @param array   $data
     * @return array
     */
    public static function remote_validate($data) {
        $errs = array();
        if (isset($data['xm_xlate_from']) && isset($data['xm_fact_id'])) {
            $conn = AIR2_DBManager::get_connection();
            $q = 'select count(*) from translation_map where xm_fact_id = ? '.
                'and xm_xlate_from = ?';
            $n = $conn->fetchOne($q, array($data['xm_fact_id'], $data['xm_xlate_from']), 0);
            if ($n > 0) {
                $errs['xm_xlate_from'] = 'unique';
            }
        }
        return $errs;
    }


}
