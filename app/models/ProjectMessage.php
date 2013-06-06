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
 * ProjectMessage
 *
 * Messages for Users associated with a Project
 *
 * @property integer $pm_id
 * @property integer $pm_pj_id
 * @property string $pm_type
 * @property string $pm_channel
 * @property integer $pm_channel_xid
 * @property integer $pm_cre_user
 * @property integer $pm_upd_user
 * @property timestamp $pm_cre_dtim
 * @property timestamp $pm_upd_dtim
 * @property Project $Project
 * @author rcavis
 * @package default
 */
class ProjectMessage extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_message');
        $this->hasColumn('pm_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('pm_pj_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pm_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('pm_channel', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('pm_channel_xid', 'integer', 4, array(

            ));
        $this->hasColumn('pm_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pm_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pm_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pm_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'pm_pj_id',
                'foreign' => 'prj_id'
            ));
    }


}
