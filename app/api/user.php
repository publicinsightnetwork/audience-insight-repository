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
 * User API
 *
 * @author rcavis
 * @package default
 */
class AAPI_User extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $QUERY_ARGS  = array('home_org', 'sort_home', 'status', 'type',
        'excl_org', 'filter', 'incl_contact_org');
    protected $CREATE_DATA = array('user_username', 'user_first_name',
        'user_last_name', 'uem_address', 'org_uuid', 'ar_code', 'uo_user_title',
        'user_type');
    protected $UPDATE_DATA = array('user_username', 'user_first_name', 'user_last_name',
        'user_summary', 'user_desc', 'user_type', 'user_status', 'avatar',
        'uem_address', 'uph_number', 'uph_ext', 'uo_user_title', 'org_uuid');

    // default paging/sorting
    protected $query_args_default = array('status' => 'AP');
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'user_username asc';
    protected $sort_valids    = array('user_username', 'user_first_name',
        'user_last_name', 'org_display_name', 'user_cre_dtim', 'uo_user_title',
        'uem_address', 'user_type', 'cre_username', 'upd_username');

    // metadata
    protected $ident = 'user_uuid';
    protected $fields = array(
        'user_uuid',
        'user_username',
        'user_first_name',
        'user_last_name',
        'user_summary',
        'user_desc',
        'user_type',
        'user_status',
        'user_cre_dtim',
        'user_upd_dtim',
        'user_login_dtim',
        'Avatar'  => 'DEF::IMAGE',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        // flattened fields (since we only allow 1 email/phone right now)
        'uem_address',
        'uph_number',
        'uph_ext',
        'uo_user_title',
        'org_uuid',
        'org_name',
        'org_display_name',
        'org_html_color',
    );


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $u = new User();

        // email (req'd)
        if (!isset($data['uem_address'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'uem_address required');
        }
        $u->UserEmailAddress[0]->uem_address = $data['uem_address'];
        $u->UserEmailAddress[0]->uem_primary_flag = true;

        // default username to email address
        if (!isset($data['user_username']) || $data['user_username'] == '') {
            $u->user_username = $data['uem_address'];
        }

        // home org (optional)
        $org_uuid = isset($data['org_uuid']) ? $data['org_uuid'] : null;
        $ar_code = isset($data['ar_code']) ? $data['ar_code'] : 'R';
        $title = isset($data['uo_user_title']) ? $data['uo_user_title'] : null;
        if ($org_uuid) {
            $org = AIR2_Record::find('Organization', $org_uuid);
            if (!$org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid org_uuid '$org_uuid'");
            }
            $ar = Doctrine::getTable('AdminRole')->findOneBy('ar_code', $ar_code);
            if (!$ar) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid ar_code '$ar_code'");
            }

            // make sure specified Org isn't full
            if ($org->is_full()) {
                $n = $org->org_display_name;
                throw new Rframe_Exception(Rframe::BAD_DATA, "Max users for '$n' reached");
            }
            $u->UserOrg[0]->Organization = $org;
            $u->UserOrg[0]->AdminRole = $ar;
            $u->UserOrg[0]->uo_notify_flag = true;
            $u->UserOrg[0]->uo_home_flag = true;
            $u->UserOrg[0]->uo_user_title = $title;
        }

        return $u;
    }


    /**
     * Update
     *
     * @param User $u
     * @param array $data
     */
    protected function air_update(User $u, $data) {
        if (isset($data['uem_address'])) {
            $u->UserEmailAddress[0]->uem_address = $data['uem_address'];
            $u->UserEmailAddress[0]->uem_primary_flag = true;

            // for NON-system users, sync username with email
            if (!$u->is_system()) {
                $u->user_username = $data['uem_address'];
            }
        }
        if (isset($data['uph_number']) || isset($data['uph_ext'])) {
            $n = isset($data['uph_number']) ? $data['uph_number'] : $u->UserPhoneNumber[0]->uph_number;
            $e = isset($data['uph_ext']) ? $data['uph_ext'] : $u->UserPhoneNumber[0]->uph_ext;
            $u->UserPhoneNumber[0]->uph_number = $n;
            $u->UserPhoneNumber[0]->uph_ext = $e;
            $u->UserPhoneNumber[0]->uph_country = 'USA';
            $u->UserPhoneNumber[0]->uph_primary_flag = true;
        }
        $old_title = null;
        if (isset($data['org_uuid'])) {
            // run through all orgs, and change home
            $found = false;
            foreach ($u->UserOrg as $uo) {
                if ($uo->uo_home_flag) $old_title = $uo->uo_user_title;
                if ($uo->Organization->org_uuid == $data['org_uuid']) {
                    $found = $uo;
                    $uo->uo_home_flag = true;
                }
                else {
                    $uo->uo_home_flag = false;
                }
            }
            if (!$found) {
                $u = $data['org_uuid'];
                throw new Rframe_Exception(RFrame::BAD_DATA, "Invalid home-org UUID '$u'");
            }
            if ($old_title) $found->uo_user_title = $old_title;
        }
        if (isset($data['uo_user_title'])) {
            // run through all orgs, and change home-org title
            $found = false;
            foreach ($u->UserOrg as $uo) {
                if ($uo->uo_home_flag) {
                    $uo->uo_user_title = $data['uo_user_title'];
                    $found = true;
                }
            }
            if (!$found) {
                throw new Rframe_Exception(RFrame::BAD_DATA, "Cannot change title: no home org");
            }
        }
        if (isset($data['avatar'])) {
            try {
                if (!$u->Avatar) {
                    $u->Avatar = new ImageUserAvatar();
                }
                $u->Avatar->set_image($data['avatar']);
            }
            catch (Exception $e) {
                throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
            }
        }
        if (array_key_exists('avatar', $data) && !$data['avatar']) {
            if ($u->Avatar) {
                $u->Avatar->delete();
                $u->clearRelated('Avatar');
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
        $q = Doctrine_Query::create()->from('User u');
        $q->leftJoin('u.UserOrg uo WITH uo.uo_home_flag = true');
        $q->leftJoin('uo.Organization o');
        $q->leftJoin('u.UserEmailAddress e with e.uem_primary_flag = true');
        $q->leftJoin('u.UserPhoneNumber p with p.uph_primary_flag = true');
        $q->leftJoin("u.Avatar av WITH av.img_ref_type = ?", 'A');
        $q->leftJoin('u.CreUser cu');
        $q->leftJoin('u.UpdUser uu');

        // flatten
        $q->addSelect('e.uem_address as uem_address');
        $q->addSelect('p.uph_number as uph_number');
        $q->addSelect('p.uph_ext as uph_ext');
        $q->addSelect('uo.uo_user_title as uo_user_title');
        $q->addSelect('o.org_uuid as org_uuid');
        $q->addSelect('o.org_name as org_name');
        $q->addSelect('o.org_display_name as org_display_name');
        $q->addSelect('o.org_html_color as org_html_color');

        // sort by some home_org first
        if (isset($args['sort_home'])) {
            $q->addSelect("(o.org_name = '{$args['sort_home']}') as myhome");
            $q->addOrderBy('myhome desc');
        }

        // restrict to some home_org
        if (isset($args['home_org'])) {
            $q->addWhere("o.org_name = '{$args['home_org']}'");
        }

        // status and type
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'u.user_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'u.user_type');
        }

        // text filter
        $str = isset($args['filter']) ? $args['filter'] : false;
        if ($str && strlen($str) > 0) {
            $usrs = "u.user_username LIKE '$str%' OR u.user_first_name ".
                "LIKE '$str%' OR u.user_last_name LIKE '$str%'";
            $orgs = "o.org_display_name LIKE '$str%' OR o.org_name LIKE '$str%'";
            $titles = "uo.uo_user_title LIKE '$str%'";
            $emails = "e.uem_address LIKE '$str%'";
            $q->addWhere("(($usrs) OR ($orgs) OR ($titles) OR ($emails))");
        }

        // exclude users belonging to an organization
        if (isset($args['excl_org'])) {
            $conn = AIR2_DBManager::get_connection();
            $orgq = "select z.org_id from organization z where z.org_uuid = ?";
            $excl = "select uo_user_id from user_org where uo_org_id = ($orgq)";
            $exclude = $conn->fetchColumn($excl, array($args['excl_org']), 0);
            if (count($exclude) > 0) {
                $q->whereNotIn('u.user_id', $exclude);
            }
        }

        // users that are eligible contacts for an organization
        if (isset($args['incl_contact_org'])) {
            $org = AIR2_Record::find('Organization', $args['incl_contact_org']);
            if (!$org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'invalid incl_contact_org');
            }
            $orgids = Organization::get_org_parents($org->org_id);
            $orgids[] = $org->org_id;

            // assemble query
            $orgids = implode(',', $orgids);
            $orgids = "uo_org_id in ($orgids)";
            $arids  = "select ar_id from admin_role where ar_code in ('M','W')";
            $arids  = "uo_ar_id in ($arids)";
            $uids   = "select uo_user_id from user_org where $orgids and $arids";
            $q->addWhere("u.user_id in ($uids)");
        }
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('User u');
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('u.user_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Handle custom sorters
     *
     * @param Doctrine_Query $q
     * @param string $fld
     * @param string $dir
     */
    protected function rec_query_add_sort(Doctrine_Query $q, $fld, $dir) {
        if ($fld == 'cre_username') {
            $q->addOrderBy("cu.user_username $dir");
        }
        elseif ($fld == 'upd_username') {
            $q->addOrderBy("uu.user_username $dir");
        }
        else {
            parent::rec_query_add_sort($q, $fld, $dir);
        }
    }


}
