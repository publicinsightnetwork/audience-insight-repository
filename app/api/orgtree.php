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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * Organization Tree API
 *
 * @author rcavis
 * @package default
 */
class AAPI_OrgTree extends AAPI_Organization {

    // only allow query
    protected $ALLOWED = array('query');

    // default to no query args
    protected $query_args_default = array();


    /**
     * Add 'children' to the field def
     *
     * @param Rframe_Parser $parser
     * @param array         $path
     * @param array         $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        $this->fields[] = 'children';
        parent::__construct($parser, $path, $inits);
    }


    /**
     * Format the value returned from rec_query() into an array radix.
     *
     * @param Doctrine_Query $q
     * @return array $radix
     */
    protected function format_query_radix(Doctrine_Query $q) {
        $q2 = $q->copy()->select('org_id');
        $rs = $q2->fetchArray();

        // also select all parent orgs
        $ids = array();
        foreach ($rs as $org) {
            $parent_ids = Organization::get_org_parents($org['org_id']);
            $ids = array_merge($ids, $parent_ids);
            $ids[] = $org['org_id'];
        }
        $q->orWhereIn('o.org_id', $ids);
        $q->removeDqlQueryPart('limit');

        // now get the radix
        $this->_fields['org_parent_id'] = 1;
        $this->_fields['org_id'] = 1;
        $radix = parent::format_query_radix($q);

        // display organizations as a tree
        return $this->get_tree_data($radix);
    }


    /**
     * Helper function to format results as a tree
     *
     * @param array   $radix
     * @param int     $root_id
     * @return array
     */
    protected function get_tree_data($radix, $root_id=null) {
        $level = array();
        foreach ($radix as $org) {
            // determine if org belongs under this root
            if ($org['org_parent_id'] === $root_id) {
                // get children and add to level
                $org['children'] = $this->get_tree_data($radix, $org['org_id']);
                $level[] = $org;
            }
        }
        return $level;
    }


}
