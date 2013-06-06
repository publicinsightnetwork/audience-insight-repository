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
 * TankActivity
 *
 * Activity to be created for each Tank or TankSource (depending on tact_type)
 * at their time of import.
 *
 * @property integer   $tact_id
 * @property integer   $tact_tank_id
 * @property string    $tact_type
 * @property integer   $tact_actm_id
 * @property integer   $tact_prj_id
 * @property timestamp $tact_dtim
 * @property string    $tact_desc
 * @property string    $tact_notes
 * @property int       $tact_xid
 * @property string    $tact_ref_type
 * @property Tank           $Tank
 * @property ActivityMaster $ActivityMaster
 * @property Project        $Project
 *
 * @author rcavis
 * @package default
 */
class TankActivity extends AIR2_Record {

    /* types */
    public static $TYPE_SOURCE  = 'S';
    public static $TYPE_PROJECT = 'P';

    /* map evtype/evdir combos to actm_id's */
    public static $ACTM_MAP = array(
        'EI' => ActivityMaster::EMAIL_IN,
        'EO' => ActivityMaster::EMAIL_OUT,
        'PI' => ActivityMaster::PHONE_IN,
        'PO' => ActivityMaster::PHONE_OUT,
        'TI' => ActivityMaster::TEXT_IN,
        'TO' => ActivityMaster::TEXT_OUT,
        'II' => ActivityMaster::PERSONEVENT,
        'IO' => ActivityMaster::PERSONEVENT,
        'OI' => ActivityMaster::ONLINEEVENT,
        'OO' => ActivityMaster::ONLINEEVENT,
    );

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_activity');
        $this->hasColumn('tact_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tact_tank_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tact_type', 'string', 1, array(
                'notnull' => true,
                'fixed'   => true,
                'default' => self::$TYPE_SOURCE,
            ));
        $this->hasColumn('tact_actm_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tact_prj_id', 'integer', 4, array());
        $this->hasColumn('tact_dtim', 'timestamp', null, array(
            ));
        $this->hasColumn('tact_desc', 'string', 255, array());
        $this->hasColumn('tact_notes', 'string', null, array());
        $this->hasColumn('tact_xid', 'integer', 4, array());
        $this->hasColumn('tact_ref_type', 'string', 1, array(
                'fixed' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Tank', array(
                'local' => 'tact_tank_id',
                'foreign' => 'tank_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('ActivityMaster', array(
                'local' => 'tact_actm_id',
                'foreign' => 'actm_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Project', array(
                'local' => 'tact_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Create a SrcActivity record for a Source.
     *
     * @param Source  $src
     */
    public function process_source(Source $src) {
        if ($this->tact_type != self::$TYPE_SOURCE) {
            return;
        }

        // get data
        $data = array(
            'sact_actm_id'  => $this->tact_actm_id,
            'sact_src_id'   => $src->src_id,
            'sact_prj_id'   => $this->tact_prj_id,
            'sact_dtim'     => $this->tact_dtim,
            'sact_desc'     => $this->tact_desc,
            'sact_notes'    => $this->tact_notes,
            'sact_cre_user' => $this->Tank->tank_user_id,
            'sact_upd_user' => $this->Tank->tank_user_id,
            'sact_cre_dtim' => $this->Tank->tank_cre_dtim,
            'sact_upd_dtim' => $this->Tank->tank_upd_dtim,
        );
        if ($this->tact_xid && $this->tact_ref_type) {
            $data['sact_xid'] = $this->tact_xid;
            $data['sact_ref_type'] = $this->tact_ref_type;
        }

        // run raw-sql for efficiency
        $conn = AIR2_DBManager::get_master_connection();
        $flds = implode(',', array_keys($data));
        $vals = air2_sql_param_string($data);
        $q = "insert into src_activity ($flds) values ($vals)";
        $conn->exec($q, array_values($data));
    }


    /**
     * Add event metadata to a query, including 'evtype', 'evdir', 'evdtim',
     * and 'evdesc'.  These are derived from the activity data.
     *
     * @param Doctrine_Query $q
     * @param char    $alias
     * @param array   $fld_defs (optional, reference)
     */
    public static function add_event_meta($q, $alias, &$fld_defs=null) {
        $q->addSelect("$alias.tact_notes as evdesc");
        $q->addSelect("$alias.tact_dtim as evdtim");

        // translate actm_id into evtype/evdir --- ack!
        $casetyp = "(case $alias.tact_actm_id ";
        $casedir = "(case $alias.tact_actm_id ";
        foreach (self::$ACTM_MAP as $code => $actm_id) {
            $casetyp .= "when $actm_id then \"{$code[0]}\" ";
            $casedir .= "when $actm_id then \"{$code[1]}\" ";
        }
        $casetyp .= "end) as evtype";
        $casedir .= "end) as evdir";
        $q->addSelect($casetyp);
        $q->addSelect($casedir);

        // add to field defs
        if (is_array($fld_defs)) {
            $fld_defs []= array('name' => 'evdesc', 'type' => 'string');
            $fld_defs []= array('name' => 'evdtim', 'type' => 'date');
            $fld_defs []= array('name' => 'evtype', 'type' => 'string');
            $fld_defs []= array('name' => 'evdir',  'type' => 'string');
        }

    }


}
