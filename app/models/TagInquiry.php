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

require_once 'Tag.php';

/**
 * TagInquiry
 *
 * @property Inquiry $Inquiry
 * @author rcavis
 * @package default
 */
class TagInquiry extends Tag {

    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->setAttribute(Doctrine::ATTR_EXPORT, Doctrine::EXPORT_NONE);
        $this->hasColumn('tag_ref_type', 'string', 1, array('default' => 'I'));
        $this->hasOne('Inquiry', array(
                'local' => 'tag_xid',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $u
     * @return int $bitmask
     */
    public function user_may_read(User $u) {
        return $this->Inquiry->user_may_read($u);
    }


    /**
     * 
     * @param User  $user
     * @return int $bitmask
     */
    public function user_may_write(User $user) {
        //Carper::carp(sprintf('check if user_may_write tag %s for %s', $this->tag_tm_id, $user->user_username));
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // authz only by role + org
        $authz = $user->get_authz();
        foreach ($authz as $orgid => $role) {
            if (ACTION_ORG_PRJ_INQ_TAG_CREATE & $role) {
                //Carper::carp(sprintf("User %s may write to tag with role %s in org %s", $user->user_username, $role, $orgid));
                return AIR2_AUTHZ_IS_OWNER;
            }
        }

        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     *
     *
     * @param User  $user
     * @return int authz flag
     */
    public function user_may_delete(User $user) {
        //Carper::carp(sprintf('check if user_may_delete tag %s for %s', $this->tag_tm_id, $user->user_username));
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // authz only by role + org
        $authz = $user->get_authz();
        foreach ($authz as $orgid => $role) {
            if (ACTION_ORG_PRJ_INQ_TAG_DELETE & $role) {
                //Carper::carp(sprintf("User %s may write to tag with role %s in org %s", $user->user_username, $role, $orgid));
                return AIR2_AUTHZ_IS_OWNER;
            }
        }

        return AIR2_AUTHZ_IS_DENIED;
    }


}
