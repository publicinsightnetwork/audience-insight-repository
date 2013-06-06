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
 * ProjectSavedSearch
 *
 * Saved searches that were created under a project
 *
 * @property integer $pss_prj_id
 * @property integer $pss_ssearch_id
 * @property integer $pss_cre_user
 * @property integer $pss_upd_user
 * @proptery timestamp $pss_cre_dtim
 * @property timestamp $pss_upd_dtim
 * @property Project $Project
 * @property SavedSearch $SavedSearch
 * @author plewis
 * @package default
 */
class ProjectSavedSearch extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_saved_search');
        $this->hasColumn('pss_prj_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pss_ssearch_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pss_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pss_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pss_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pss_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'pss_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            )
        );
        $this->hasOne('SavedSearch', array(
                'local' => 'pss_ssearch_id',
                'foreign' => 'ssearch_id',
                'onDelete' => 'CASCADE'
            )
        );
    }


    /**
     * Get the mapped-UUID column for this model
     *
     * @return string
     */
    public function get_uuid_col() {
        return 'SavedSearch:ssearch_uuid';
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        // make sure "SavedSearch" is part of the query
        $from_parts = $q->getDqlPart('from');
        foreach ($from_parts as $string_part) {
            if ($match = strpos($string_part, "$alias.SavedSearch")) {
                $offset = strlen("$alias.SavedSearch") + 1; // remove space
                $pss_alias = substr($string_part, $match + $offset);
                $a = ($pss_alias) ? "$pss_alias." : "";
                $str = "(".$a."ssearch_name LIKE ?)";
                if ($useOr) {
                    $q->orWhere($str, array("$search%"));
                }
                else {
                    $q->addWhere($str, array("$search%"));
                }
                break;
            }
        }
    }


}
