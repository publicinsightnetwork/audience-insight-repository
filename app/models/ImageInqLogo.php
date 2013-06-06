<?php
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

require_once 'Image.php';

/**
 * Inquiry logo subclass of Image
 *
 * @package default
 */
class ImageInqLogo extends Image {

    /**
     * Connect to Image table
     */
    public function setUp() {
        parent::setUp();
        $this->setAttribute(Doctrine::ATTR_EXPORT, Doctrine::EXPORT_NONE);
        $this->hasColumn('img_ref_type', 'string', 1, array('default' => 'Q'));
        $this->hasOne('Inquiry', array('local' => 'img_xid', 'foreign' => 'inq_id'));
    }


    /**
     * read authz - same as inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
      return $this->Inquiry->user_may_read($user);
    }


    /**
     * write authz - same as inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
      return $this->Inquiry->user_may_write($user);
    }


    /**
     * manage authz - same as inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
      return $this->Inquiry->user_may_manage($user);
    }


}
