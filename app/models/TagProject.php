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
 * TagProject
 *
 * @property Project $Project
 * @author rcavis
 * @package default
 */
class TagProject extends Tag {

    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->setAttribute(Doctrine::ATTR_EXPORT, Doctrine::EXPORT_NONE);
        $this->hasColumn('tag_ref_type', 'string', 1, array('default' => 'P'));
        $this->hasOne('Project', array(
                'local' => 'tag_xid',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from Project
     *
     * @param User $u
     * @return int $bitmask
     */
    public function user_may_read(User $u) {
        return $this->Project->user_may_read($u);
    }


    /**
     * Inherit from Project
     *
     * @param User $u
     * @return int $bitmask
     */
    public function user_may_write(User $u) {
        return $this->Project->user_may_write($u);
    }


}
