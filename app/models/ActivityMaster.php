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
 * ActivityMaster
 *
 * Metadata concerning a generic type of "Activity"
 *
 * @property integer $actm_id
 * @property string $actm_status
 * @property string $actm_name
 * @property string $actm_type
 * @property string $actm_subject
 * @property boolean $actm_contact_rule_flag
 * @property integer $actm_disp_seq
 * @property integer $actm_cre_user
 * @property integer $actm_upd_user
 * @property timestamp $actm_cre_dtim
 * @property timestamp $actm_upd_dtim
 * @property Doctrine_Collection $ProjectActivity
 * @property Doctrine_Collection $SrcActivity
 * @author rcavis
 * @package default
 */
class ActivityMaster extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $TABLE_TYPE_SOURCE = 'S';
    public static $TABLE_TYPE_PROJECT = 'P';
    public static $TYPE_INBOUND = 'I';
    public static $TYPE_ADMINISTRATIVE = 'A';
    public static $TYPE_OUTBOUND = 'O';
    public static $TYPE_CONTACT = 'C';
    public static $TYPE_RELATIONSHIP = 'R';
    public static $TYPE_STATUS = 'S';
    public static $TYPE_MESSAGE = 'M';
    public static $TYPE_JOURNALISM = 'J';
    public static $TYPE_UPLOAD = 'U';

    /* static id references */
    const PROJECT_UPDATED = 34;
    const PRJORGS_UPDATED = 35;
    const SRCINFO_UPDATED = 11;
    const OUTCOME_OR_ANNOT = 41;

    /* incoming/outgoing happenings */
    const EMAIL_IN    = 43;
    const EMAIL_OUT   = 29;
    const PHONE_IN    = 44;
    const PHONE_OUT   = 45;
    const TEXT_IN     = 36;
    const TEXT_OUT    = 37;
    const PERSONEVENT = 46;
    const ONLINEEVENT = 47;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('activity_master');
        $this->hasColumn('actm_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('actm_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('actm_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('actm_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('actm_table_type', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('actm_contact_rule_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('actm_disp_seq', 'integer', 2, array(
                'notnull' => true,
            ));
        $this->hasColumn('actm_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('actm_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('actm_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('actm_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('ProjectActivity', array(
                'local' => 'actm_id',
                'foreign' => 'pa_actm_id'
            ));
        $this->hasMany('SrcActivity', array(
                'local' => 'actm_id',
                'foreign' => 'sact_actm_id'
            ));
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "(".$a."actm_name LIKE ?)";
        if ($useOr) {
            $q->orWhere($str, array("%$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%"));
        }
    }


}
