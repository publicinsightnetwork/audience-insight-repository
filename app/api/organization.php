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
 * Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update');
    protected $CREATE_DATA = array('org_parent_uuid', 'org_name', 'org_display_name',
        'org_site_uri', 'org_status', 'org_max_users', 'org_html_color');
    protected $QUERY_ARGS  = array('excl_user', 'excl_proj', 'excl_src',
        'excl_inq', 'role', 'status', 'type');
    protected $UPDATE_DATA = array('org_name', 'org_display_name',
        'org_summary', 'org_desc', 'org_address', 'org_city', 'org_state', 'org_zip', 'org_site_uri',
        'org_welcome_msg', 'org_email',
        'org_status', 'org_max_users', 'org_html_color', 'banner', 'logo');

    // default paging/sorting
    protected $query_args_default = array('status' => 'APG'); //Active&Guest&Published
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'org_display_name asc';
    protected $sort_valids    = array('org_display_name', 'org_name', 'org_cre_dtim');

    // metadata
    protected $ident = 'org_uuid';
    protected $fields = array(
        'org_uuid',
        'org_name',
        'org_display_name',
        'org_summary',
        'org_desc',
        'org_welcome_msg',
        'org_email',
        'org_address',
        'org_city',
        'org_state',
        'org_zip',
        'org_site_uri',
        'org_type',
        'org_status',
        'org_max_users',
        'org_html_color',
        'org_cre_dtim',
        'org_upd_dtim',
        'Banner'  => 'DEF::IMAGE',
        'Logo'    => 'DEF::IMAGE',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'ProjectOrg' => array(
            'porg_status',
            'Project' => 'DEF::PROJECT',
        ),
        'DefaultProject' => 'DEF::PROJECT',
        'parent' => 'DEF::ORGANIZATION',
        'active_users',
    );


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $o = new Organization();

        // org parent (optional)
        if (isset($data['org_parent_uuid'])) {
            $parent = AIR2_Record::find('Organization', $data['org_parent_uuid']);
            if (!$parent) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid parent Org specified!');
            }
            $o->parent = $parent;
        }
        return $o;
    }


    /**
     * Handle image creation/deletion
     *
     * @param Organization $u
     * @param array $data
     */
    protected function air_update($o, $data) {
        if (isset($data['banner'])) {
            try {
                if (!$o->Banner) $o->Banner = new ImageOrgBanner();
                $o->Banner->set_image($data['banner']);
            }
            catch (Exception $e) {
                throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
            }
        }
        if (isset($data['logo'])) {
            try {
                if (!$o->Logo) $o->Logo = new ImageOrgLogo();
                $o->Logo->set_image($data['logo']);
            }
            catch (Exception $e) {
                throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
            }
        }

        // delete if null is passed
        if (array_key_exists('banner', $data) && !$data['banner']) {
            if ($o->Banner) {
                $o->Banner->delete();
                $o->clearRelated('Banner');
            }
        }
        if (array_key_exists('logo', $data) && !$data['logo']) {
            if ($o->Logo) {
                $o->Logo->delete();
                $o->clearRelated('Logo');
            }
        }
    }


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Organization o');
        $q->leftJoin('o.DefaultProject def');
        $q->leftJoin('o.ProjectOrg po');
        $q->leftJoin('po.Project p');
        $q->leftJoin('o.parent r');
        $q->leftJoin("o.Logo ilg WITH ilg.img_ref_type = ?", 'L');
        $q->leftJoin("o.Banner ibn WITH ibn.img_ref_type = ?", 'B');
        $q->leftJoin('o.CreUser cu');
        $q->leftJoin('o.UpdUser uu');

        // process query args
        if (isset($args['excl_user'])) {
            $usrq = "select user_id from user where user_uuid = ?";
            $excl = "select uo_org_id from user_org where uo_user_id = ($usrq)";
            $q->addWhere("o.org_id not in ($excl)", $args['excl_user']);
        }
        if (isset($args['excl_proj'])) {
            $prjq = "select prj_id from project where prj_uuid = ?";
            $excl = "select porg_org_id from project_org where porg_prj_id = ($prjq)";
            $q->addWhere("o.org_id NOT IN ($excl)", $args['excl_proj']);
        }
        if (isset($args['excl_src'])) {
            $srcq = "select src_id from source where src_uuid = ?";
            $excl = "select so_org_id from src_org where so_src_id = ($srcq)";
            $q->addWhere("o.org_id NOT IN ($excl)", $args['excl_src']);
        }
        if (isset($args['excl_inq'])) {
            $srcq = "select inq_id from inquiry where inq_uuid = ?";
            $excl = "select iorg_org_id from inq_org where iorg_inq_id = ($srcq)";
            $q->addWhere("o.org_id NOT IN ($excl)", $args['excl_inq']);
        }
        if (isset($args['role']) && !$this->user->is_system()) {
            // look for valid role string
            $role = strtoupper($args['role']);
            if ($role == 'READER') {
                $role = 'R';
            }
            elseif ($role == 'READERPLUS' || $role == 'E' || $role == 'EDITOR') {
                $role = 'P';
            }
            elseif ($role == 'WRITER') {
                $role = 'W';
            }
            elseif ($role == 'MANAGER') {
                $role = 'M';
            }
            if (!isset(AdminRole::$CODES[$role])) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid role specified: '$role'");
            }

            // check for the specified role OR BETTER
            $role_or_better = array();
            $roles_in_order = array('N', 'X', 'R', 'F', 'P', 'W', 'M');
            foreach ($roles_in_order as $code) {
                if ($role == $code || count($role_or_better)) {
                    if (defined("AIR2_AUTHZ_ROLE_$code")) {
                        $role_or_better[] = constant("AIR2_AUTHZ_ROLE_$code");
                    }
                }
            }

            // check each org in user authz for the role bitmasks
            $role_or_better_orgs = array(0); //default - none
            $user_authz = $this->user->get_authz();
            foreach ($user_authz as $orgid => $role) {
                foreach ($role_or_better as $mask) {
                    if ($mask == $role) $role_or_better_orgs[] = $orgid;
                }
            }

            // add to where
            $q->andWhereIn("o.org_id", $role_or_better_orgs);
        }
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'o.org_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'o.org_type');
        }

        // add user_org count
        Organization::add_counts($q, 'o');
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->where('o.org_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
