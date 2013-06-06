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
 * SrcInquiry
 *
 * Inquiry that was sent to a Source
 *
 * @property integer $si_id
 * @property integer $si_src_id
 * @property integer $si_inq_id
 * @property string $si_sent_by
 * @property integer $si_cre_user
 * @property integer $si_upd_user
 * @property timestamp $si_cre_dtim
 * @property timestamp $si_upd_dtim
 * @property Source $Source
 * @property Inquiry $Inquiry
 * @author rcavis
 * @package default
 */
class SrcInquiry extends AIR2_Record {
    public static $STATUS_COMPLETE = 'C';
    public static $STATUS_EXPORTED = 'E';
    public static $STATUS_IGNORED  = 'I';
    public static $STATUS_PENDING  = 'P';
    public static $STATUS_DELETED  = 'X';
    public static $STATUS_AIR1     = 'A';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_inquiry');
        $this->hasColumn('si_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('si_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('si_inq_id', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('si_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_PENDING,
            )
        );
        $this->hasColumn('si_sent_by', 'string', 255, array(
            )
        );
        $this->hasColumn('si_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('si_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('si_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('si_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'si_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'si_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            ));
    }


}
