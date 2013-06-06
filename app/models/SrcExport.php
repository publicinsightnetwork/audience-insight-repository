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
 * SrcExport
 *
 * Register an export of Source information. Initially this is for mailer
 * integration but could be re-used for other kinds of exports where you
 * need to defer the creation of an activity till after a transaction has
 * completed, and you need to store some metadata about the export in the
 * meantime.
 *
 * @property integer $se_id
 * @property string  $se_uuid
 * @property integer $se_inq_id
 * @property integer $se_prj_id
 * @property integer $se_email_id
 * @property string  $se_name
 * @property string  $se_type
 * @property string  $se_status
 * @property string  $se_notes
 * @property integer $se_xid
 * @property integer $se_ref_type
 * @property integer $se_cre_user
 * @property integer $se_upd_user
 * @property timestamp $se_cre_dtim
 * @property timestamp $se_upd_dtim
 * @property Inquiry $Inquiry
 * @property Project $Project
 * @property Project $Email
 * @package default
 */
class SrcExport extends AIR2_Record {

    public static $TYPE_MAILCHIMP    = 'M';
    public static $TYPE_CSV          = 'C';
    public static $TYPE_XLSX         = 'X';
    public static $REF_TYPE_BIN      = 'I';
    public static $STATUS_COMPLETE   = 'C';
    public static $STATUS_INCOMPLETE = 'I';
    public static $STATUS_QUEUED     = 'Q';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_export');
        $this->hasColumn('se_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('se_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            )
        );
        $this->hasColumn('se_prj_id', 'integer', 4, array(
                //'notnull' => true,    // null ok
            )
        );
        $this->hasColumn('se_inq_id', 'integer', 4, array(
                //'notnull' => true,    // null ok
            )
        );
        $this->hasColumn('se_email_id', 'integer', 4, array(
                //'notnull' => true,    // null ok
            )
        );
        $this->hasColumn('se_name', 'string', 255, array(
                'notnull' => true,
                //'unique'  => true,    // only unique with se_type=L
            )
        );
        $this->hasColumn('se_type', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$TYPE_MAILCHIMP,
            )
        );
        $this->hasColumn('se_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_INCOMPLETE,
            )
        );
        $this->hasColumn('se_notes', 'string', null, array(

            )
        );
        $this->hasColumn('se_xid', 'integer', 4, array(

            )
        );
        $this->hasColumn('se_ref_type', 'string', 1, array(
                'fixed' => true,
            )
        );
        $this->hasColumn('se_cre_user', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('se_upd_user', 'integer', 4, array(

            )
        );
        $this->hasColumn('se_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('se_upd_dtim', 'timestamp', null, array(

            )
        );

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'se_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            )
        );
        $this->hasOne('Inquiry', array(
                'local' => 'se_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            )
        );
        $this->hasOne('Email', array(
                'local' => 'se_email_id',
                'foreign' => 'email_id',
                'onDelete' => 'CASCADE'
            )
        );
    }


    /**
     * Convenience function for getting fields from json-encoded se_notes
     *
     * @param string  $name the meta-field name
     * @return mixed
     */
    public function get_meta($name) {
        if (!$this->se_notes) {
            return null;
        }
        else {
            $data = json_decode($this->se_notes, true);
            return ($data && isset($data[$name])) ? $data[$name] : null;
        }
    }


    /**
     * Convenience function for setting json-encoded se_notes
     *
     * @param string  $name  the meta-field name
     * @param mixed   $value the new value
     */
    public function set_meta($name, $value) {
        $json = json_decode($this->se_notes, true);
        $data = ($json && is_array($json)) ? $json : array();
        $data[$name] = $value;
        $this->se_notes = json_encode($data);
    }


}
