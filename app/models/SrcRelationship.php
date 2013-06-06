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
 * SrcRelationship
 *
 * Relationship between 2 Sources
 *
 * @property integer $srel_src_id
 * @property integer $src_src_id
 * @property string $srel_context
 * @property string $srel_status
 * @property integer $srel_cre_user
 * @property integer $srel_upd_user
 * @property timestamp $srel_cre_dtim
 * @property timestamp $srel_upd_dtim
 * @property Source $Source
 * @property Source $Source_2
 * @author rcavis
 * @package default
 */
class SrcRelationship extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $CONTEXT_HOUSEHOLD = 'H';
    public static $CONTEXT_SPOUSE_OR_PARTNER = 'S';
    public static $CONTEXT_PARENT_OR_CHILD = 'P';
    public static $CONTEXT_REFER = 'R';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_relationship');
        $this->hasColumn('srel_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('src_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('srel_context', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('srel_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('srel_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srel_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('srel_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('srel_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'src_src_id',
                'foreign' => 'src_id'
            ));
        $this->hasOne('Source as Source_2', array(
                'local' => 'srel_src_id',
                'foreign' => 'src_id'
            ));
    }


}
