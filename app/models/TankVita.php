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
 * TankVita
 *
 * Tank version of a SrcVita.
 *
 * @property integer $tv_id
 * @property integer $tv_tsrc_id
 *
 * @property integer $sv_type
 * @property integer $sv_origin
 * @property date $sv_start_date
 * @property date $sv_end_date
 * @property float $sv_lat
 * @property float $sv_long
 * @property string $sv_value
 * @property string $sv_basis
 * @property string $sv_notes
 * @property TankSource $TankSource
 *
 * @package default
 */
class TankVita extends AIR2_Record {

    /* Fields to copy from SrcVita */
    protected $copy_fields = array(
        'sv_type',
        'sv_origin',
        'sv_start_date',
        'sv_end_date',
        'sv_lat',
        'sv_long',
        'sv_value',
        'sv_basis',
        'sv_notes'
    );


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_vita');
        $this->hasColumn('tv_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('tv_tsrc_id', 'integer', 4, array(
                'notnull' => true,
            )
        );

        // copy some specific columns of SrcVita
        $c = Doctrine::getTable('SrcVita')->getColumns();
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
                'local' => 'tv_tsrc_id',
                'foreign' => 'tsrc_id',
                'onDelete' => 'CASCADE'
            )
        );
    }


}
