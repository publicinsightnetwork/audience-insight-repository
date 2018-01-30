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
 * SrcOrgEmail
 *
 * Cache Lyris mailing list status for quick lookup on export.
 *
 * @package default
 */
class SrcOrgEmail extends AIR2_Record {

    public static $STATUS_ACTIVE       = 'A';
    public static $STATUS_BOUNCED      = 'B';
    public static $STATUS_UNSUBSCRIBED = 'U';
    public static $STATUS_ERROR        = 'E';
    public static $STATUS_PENDING      = 'P';
    public static $TYPE_LYRIS          = 'L';
    public static $TYPE_MAILCHIMP      = 'M';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_org_email');
        $this->hasColumn('soe_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('soe_sem_id', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('soe_org_id', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('soe_status', 'string', 1, array(
                'notnull' => true,
                'fixed'   => true,
            )
        );
        $this->hasColumn('soe_status_dtim', 'timestamp', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('soe_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_LYRIS,
            ));

        parent::setTableDefinition();

        $this->index('soe_uniqueidx_1', array(
                'fields' => array('soe_sem_id', 'soe_org_id', 'soe_type'),
                'type' => 'unique'
            )
        );
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcEmail', array(
                'local' => 'soe_sem_id',
                'foreign' => 'sem_id',
                'onDelete' => 'CASCADE'
            )
        );
        $this->hasOne('Organization', array(
                'local' => 'soe_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE'
            )
        );
    }


}
