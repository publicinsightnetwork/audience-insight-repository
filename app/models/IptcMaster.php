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
 * IptcMaster
 *
 * List of valid IPTC codes for use in AIR2 tags
 *
 * @property integer $iptc_id
 * @property string $iptc_concept_id
 * @property string $iptc_name
 * @property integer $iptc_cre_user
 * @property integer $iptc_upd_user
 * @property timestamp $iptc_cre_dtim
 * @property timestamp $iptc_upd_dtim
 * @property TagMaster $TagMaster
 * @author rcavis
 * @package default
 */
class IptcMaster extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('iptc_master');
        $this->hasColumn('iptc_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('iptc_concept_code', 'string', 32, array(
                'notnull' => true,
            ));
        $this->hasColumn('iptc_name', 'string', 255, array(
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('iptc_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('iptc_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('iptc_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('iptc_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('TagMaster', array(
                'local' => 'iptc_id',
                'foreign' => 'tm_iptc_id'
            ));
    }


    /**
     * Check for valid iptc_name
     */
    public function validate() {
        // check for valid characters
        if (preg_match('/[^a-zA-Z0-9 _\-\.\/]/', $this->iptc_name)) {
            $this->getErrorStack()->add('iptc_name', 'Invalid character(s)! Use [A-Za-z0-9] and "-_./"');
        }

        // check for leading/trailing spaces
        if (preg_match('/^[ ]+|[ ]+$/', $this->iptc_name)) {
            $this->getErrorStack()->add('iptc_name', 'Invalid leading/trailing whitespace!');
        }
    }


}
