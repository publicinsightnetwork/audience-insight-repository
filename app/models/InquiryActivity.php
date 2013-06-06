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

/**
 * InquiryActivity
 *
 * Activity occuring in reference to an inquiry
 *
 * @property integer $ia_id
 * @property integer $ia_actm_id
 * @property integer $ia_inq_id
 * @property timestamp $ia_dtim
 * @property string $ia_desc
 * @property string $ia_notes
 * @property integer $ia_cre_user
 * @property integer $ia_upd_user
 * @property timestamp $ia_cre_dtim
 * @property timestamp $ia_upd_dtim
 * @property ActivityMaster $ActivityMaster
 * @property User $User
 * @package default
 */
class InquiryActivity extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('inquiry_activity');
        $this->hasColumn('ia_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ia_actm_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ia_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ia_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ia_desc', 'string', 255, array(

            ));
        $this->hasColumn('ia_notes', 'string', null, array(

            ));
        $this->hasColumn('ia_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ia_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('ia_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ia_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('ActivityMaster', array(
                'local' => 'ia_actm_id',
                'foreign' => 'actm_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'ia_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Custom AIR2 validation before update/save
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        parent::preValidate($event);

    }



}
