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
 * Trackback
 *
 * Log Source views (profile, search results, etc).
 *
 * @property integer $tb_src_id
 * @property integer $tb_user_id
 * @property integer $tb_ip
 * @property datetime $tb_dtim
 * @property Source $Source
 * @property User   $User
 * @package default
 */
class Trackback extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('trackback');
        $this->hasColumn('tb_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('tb_src_id', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('tb_user_id', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('tb_ip', 'integer', 4, array(
                'notnull' => true,
                'unsigned' => true,
            )
        );
        $this->hasColumn('tb_dtim', 'timestamp', null, array(
                'notnull' => true,
            )
        );

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'tb_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            )
        );
        $this->hasOne('User', array(
                'local' => 'tb_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE',
            )
        );
    }


    /**
     * Converts dotted quad to long integer for tb_ip.
     *
     * @param unknown $event
     * @return parent preValidate
     */
    public function preValidate($event) {
        if (!is_numeric($this->tb_ip)) {
            $this->tb_ip = ip2long($this->tb_ip);
        }
        if (!$this->tb_dtim) {
            $this->tb_dtim = air2_date();
        }
        return parent::preValidate($event);
    }


    /**
     *
     *
     * @return string dotted-quad equivalent of tb_ip.
     */
    public function get_ip_address() {
        return long2ip($this->tb_ip);
    }


}
