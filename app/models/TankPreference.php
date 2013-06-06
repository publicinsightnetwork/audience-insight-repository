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
 * TankPreference
 *
 * Tank version of a SrcPreference.
 *
 *
 * @property TankSource $TankSource
 *
 * @package default
 */
class TankPreference extends AIR2_Record {

    /* Fields to copy from SrcPreference */
    protected $copy_fields = array(
        'sp_uuid',
        'sp_status',
        'sp_lock_flag',
        'sp_ptv_id',
    );


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_preference');
        $this->hasColumn('tp_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('tp_tsrc_id', 'integer', 4, array(
                'notnull' => true,
            )
        );

        // copy some specific columns of SrcVita
        $c = Doctrine::getTable('SrcPreference')->getColumns();
        foreach ($c as $idx => $def) {
            if (in_array($idx, $this->copy_fields)) {
                $this->hasColumn($idx, $def['type'], $def['length'], $def);
            }
        }

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('TankSource', array(
                'local' => 'tp_tsrc_id',
                'foreign' => 'tsrc_id',
                'onDelete' => 'CASCADE'
            )
        );
    }


}
