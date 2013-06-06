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
 * TankSource
 *
 * Tank file for a very flattened version of a Source.
 *
 * @property integer $tsrc_id
 * @property integer $tsrc_tank_id
 * @property string $tsrc_status
 * @property boolean $tsrc_created_flag
 * @property string $tsrc_errors
 * @property integer $tsrc_cre_user
 * @property integer $tsrc_upd_user
 * @property timestamp $tsrc_cre_dtim
 * @property timestamp $tsrc_upd_dtim
 * @property string $tsrc_tags
 * @property Tank $Tank
 * @property TankFact $TankFact
 * @property TankVita $TankVita
 * @property Source $Source
 * @property Doctrine_Collection $TankResponse
 * @property Doctrine_Collection $TankResponseSet
 *
 * @see TankSource::$COLS for many other generated properties
 *
 * @author rcavis
 * @package default
 */
class TankSource extends AIR2_Record {
    // cache of json-decoded errors
    protected $error_cache = array();

    /* conflict mode or resolution mode */
    protected $conflict_mode = true;

    /* Flattened tables mapped into the tank */
    public static $COLS = array(
        'Source' => array(
            'src_id',
            'src_uuid',
            'src_username',
            'src_first_name',
            'src_last_name',
            'src_middle_initial',
            'src_pre_name',
            'src_post_name',
            'src_status',
            'src_channel',
        ),
        'SrcMailAddress' => array(
            'smadd_uuid',
            'smadd_primary_flag',
            'smadd_context',
            'smadd_line_1',
            'smadd_line_2',
            'smadd_city',
            'smadd_state',
            'smadd_cntry',
            'smadd_zip',
            'smadd_lat',
            'smadd_long',
        ),
        'SrcPhoneNumber' => array(
            'sph_uuid',
            'sph_primary_flag',
            'sph_context',
            'sph_country',
            'sph_number',
            'sph_ext',
        ),
        'SrcEmail' => array(
            'sem_uuid',
            'sem_primary_flag',
            'sem_context',
            'sem_email',
            'sem_effective_date',
            'sem_expire_date',
        ),
        'SrcUri' => array(
            'suri_primary_flag',
            'suri_context',
            'suri_type',
            'suri_value',
            'suri_handle',
            'suri_feed',
        ),
        'SrcAnnotation' => array(
            'srcan_type',
            'srcan_value',
        ),
    );

    /* Status codes */
    public static $STATUS_NEW = 'N';
    public static $STATUS_CONFLICT = 'C';
    public static $STATUS_RESOLVED = 'R';
    public static $STATUS_LOCKED = 'L';
    public static $STATUS_DONE = 'D';
    public static $STATUS_ERROR = 'E';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_source');

        $this->hasColumn('tsrc_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tsrc_tank_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tsrc_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_NEW,
            ));
        $this->hasColumn('tsrc_created_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('tsrc_errors', 'string', null, array(
            ));
        $this->hasColumn('tsrc_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tsrc_upd_user', 'integer', 4, array(
            ));
        $this->hasColumn('tsrc_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('tsrc_upd_dtim', 'timestamp', null, array(
            ));

        /* special case --- tags (not a real table column */
        $this->hasColumn('tsrc_tags', 'string', 255, array(
            ));

        /* add all the mapped columns */
        foreach (self::$COLS as $mod => $cols) {
            $tbl = Doctrine::getTable($mod);
            foreach ($cols as $idx => $val) {
                // copy the column def
                if (is_string($val)) {
                    $d = $tbl->getColumnDefinition($val);
                    $this->_copy_column_def($val, $d);
                }
                else {
                    $tbl2 = $tbl->getRelation($idx)->getTable();
                    foreach ($val as $val2) {
                        $d = $tbl2->getColumnDefinition($val2);
                        $this->_copy_column_def($val2, $d);
                    }
                }
            }
        }

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Tank', array(
                'local' => 'tsrc_tank_id',
                'foreign' => 'tank_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasMany('TankResponse', array(
                'local' => 'tsrc_id',
                'foreign' => 'tr_tsrc_id'
            ));
        $this->hasMany('TankResponseSet', array(
                'local' => 'tsrc_id',
                'foreign' => 'trs_tsrc_id'
            ));
        $this->hasMany('TankFact', array(
                'local' => 'tsrc_id',
                'foreign' => 'tf_tsrc_id'
            ));
        $this->hasMany('TankVita', array(
                'local' => 'tsrc_id',
                'foreign' => 'tv_tsrc_id'
            )
        );
        $this->hasMany('TankPreference', array(
                'local' => 'tsrc_id',
                'foreign' => 'tp_tsrc_id'
            )
        );

        // non-exported relationship to Source
        $this->hasOne('Source', array(
                'local' => 'src_id',
                'foreign' => 'src_id',
                'export' => false,
            ));
        $this->hasOne('SrcPhoneNumber' ,array(
                'local' => 'sph_uuid',
                'foreign' => 'sph_uuid',
                'export' =>false,
            ));
        $this->hasOne('SrcMailAddress' ,array(
                'local' => 'smadd_uuid',
                'foreign' => 'smadd_uuid',
                'export' =>false,
            ));
    }


    /**
     * Make sure tsrc_id is the identifier (NOT src_id or src_uuid)
     *
     * @return string
     */
    public function get_uuid_col() {
        return 'tsrc_id';
    }


    /**
     * Get the model that a tank column exists in
     *
     * @param  string $colname
     * @return string $modelname
     */
    public static function get_model_for($colname) {
        // remove anything before a dot
        $colname = preg_replace('/^.+\./', '', $colname);

        // check the tank_source columns
        foreach (self::$COLS as $modelname => $modelcolumns) {
            foreach ($modelcolumns as $col) {
                if ($col == $colname) return $modelname;
            }
        }

        // is it a fact?
        if (preg_match('/^sf_/', $colname)) {
            return 'SrcFact';
        }

        // unknown!
        return null;
    }


    /**
     * Get an associative array of data for a given related model.  This
     * effectively turns this flat table back into it's multidimensional parts.
     *
     * @param string  $model_name
     * @return assoc-array
     */
    public function get_tank_data($model_name) {
        if (!isset(self::$COLS[$model_name])) {
            throw new Exception("Unknown or unrelated TankSource model $model_name");
        }

        // lookup columns for that model
        $data = array();
        foreach (self::$COLS[$model_name] as $idx => $val) {
            if (is_string($val)) {
                if (!is_null($this->$val)) {
                    $data[$val] = $this->$val;
                }
            }
            else {
                foreach ($val as $val2) {
                    if (!is_null($this->$val2)) {
                        if (!isset($data[$idx])) $data[$idx] = array();
                        $data[$idx][$val2] = $this->$val2;
                    }
                }
            }
        }
        return $data;
    }


    /**
     * True to put the tank into 'resolution' mode, where conflict messages
     * will not be modified, but instead a new 'resolve' key will be set.
     *
     * @param boolean $is_conflict (optional)
     */
    public function set_conflict_mode($is_conflict=true) {
        $this->conflict_mode = $is_conflict;
    }


    /**
     * Clear the TankSource tsrc_errors of errors/conflicts.
     */
    public function clear_errors() {
        if ($this->conflict_mode) {
            $this->tsrc_errors = null;
            $this->error_cache = array();
        }
        else {
            // for resolution mode, don't clear conflicts
            $this->error_cache = json_decode($this->tsrc_errors, true);
            unset($this->error_cache['errors']);
            unset($this->error_cache['resolve']);
            $this->tsrc_errors = json_encode($this->error_cache);
        }
    }


    /**
     * Add an error to the TankSource tsrc_errors. Also causes the tsrc_status
     * to be set to STATUS_ERROR.  This happens in both conflict and resolution
     * modes.
     *
     * @param string  $msg
     */
    public function add_error($msg) {
        $this->error_cache['errors'][] = $msg;
        $this->tsrc_errors = json_encode($this->error_cache);
        $this->tsrc_status = self::$STATUS_ERROR;
    }


    /**
     * Add a column conflict to the TankSource tsrc_errors. Also causes the
     * tsrc_status to be set to STATUS_CONFLICT if it isn't already in
     * STATUS_ERROR.  If in resolution mode, the conflict will instead be added
     * to the 'resolve' array.  The $with parameter optionally sets a conflict
     * with a particular record, and $with is the identifier of the record.
     *
     * @param string  $model
     * @param string  $column
     * @param string  $msg
     * @param string  $with
     */
    public function add_conflict($model, $column, $msg, $with=null) {
        $key = ($this->conflict_mode) ? 'conflicts' : 'resolve';
        $data = array(
            'model' => $model,
            'column' => $column,
            'msg' => $msg,
        );
        if ($with) $data['with'] = $with;
        $this->error_cache[$key][] = $data;
        $this->tsrc_errors = json_encode($this->error_cache);
        if ($this->tsrc_status != self::$STATUS_ERROR) {
            $this->tsrc_status = self::$STATUS_CONFLICT;
        }
    }


    /**
     * Helper function to copy a column def from another model
     *
     * @param string  $name
     * @param array   $def
     * @param boolean $allow_null
     */
    private function _copy_column_def($name, $def, $allow_null=true) {
        unset($def['primary']);
        unset($def['autoincrement']);
        unset($def['unique']);
        unset($def['default']);
        if ($allow_null) unset($def['notnull']);
        $this->hasColumn($name, $def['type'], $def['length'], $def);
    }


    /**
     * Check tank
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Tank->user_may_read($user);
    }


    /**
     * Check tank
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Tank->user_may_write($user);
    }


    /**
     * Check tank
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Tank->user_may_manage($user);
    }

    /** 
     * Fixing the 
     * 
     * @param 
     * @return return value from parent::save($conn)
     */
     public function save(Doctrine_Connection $conn=null) {
        $zip = $this->smadd_zip;
        if(strlen($zip) == 4) {
            $this->smadd_zip = '0' . $zip;
        }  

        $this->sph_number = preg_replace('/\D/', '', $this->sph_number);
        
        $ret = parent::save($conn);
        
        return $ret;
    }
}
