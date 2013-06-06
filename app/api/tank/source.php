<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'rframe/AIRAPI_Resource.php';
require_once 'phperl/callperl.php';

/**
 * Tank/Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tank_Source extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update');
    protected $QUERY_ARGS  = array('status');
    protected $UPDATE_DATA = array('resolve', 'redo');

    // default paging/sorting
    protected $sort_default   = 'src_username asc';
    protected $sort_valids    = array('src_username', 'src_first_name', 'src_last_name', 'status_sort');

    // metadata
    protected $ident = 'tsrc_id';
    protected $fields = array(
        // tank_source fields added by constructor
        'Source' => 'DEF::SOURCE',
        'TankFact' => array(
            'tf_fact_id',
            'sf_fv_id',
            'sf_src_value',
            'sf_src_fv_id',
            'Fact',
            'AnalystFV',
            'SourceFV',
        ),
        'tsrc_withs',
        'next_conflict',
    );



    /**
     * Add the many tank_source fields to $fields
     *
     * @param Rframe_Parser $parser
     * @param array   $path
     * @param array   $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        $flds = Doctrine::getTable('TankSource')->getFieldNames();
        $this->fields = array_merge($flds, $this->fields);
        parent::__construct($parser, $path, $inits);
    }


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('TankSource t');
        $q->where('t.tsrc_tank_id = ?', $this->parent_rec->tank_id);
        $q->leftJoin('t.Source s');

        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 't.tsrc_status');
        }

        $this->add_status_sort($q);
        return $q;
    }


    /**
     * sortable STATUS column (to sort by status MEANING, not char val)
     *
     * @param Doctrine_Query $q
     */
    protected function add_status_sort($q) {
        $stat_sort = array(
            TankSource::$STATUS_ERROR,
            TankSource::$STATUS_CONFLICT,
            TankSource::$STATUS_LOCKED,
            TankSource::$STATUS_RESOLVED,
            TankSource::$STATUS_DONE,
            TankSource::$STATUS_NEW,
        );
        $sel = 'select case';
        foreach ($stat_sort as $idx => $stat) {
            $sel .= " when t.tsrc_status = '$stat' then $idx";
        }
        $sel .= ' else 99 end';
        $q->addSelect("($sel) as status_sort");
    }


    /**
     * Fetch
     *
     * @param string  $uuid
     * @param unknown $minimal (optional)
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        $q = Doctrine_Query::create()->from('TankSource t');
        $q->where('t.tsrc_tank_id = ?', $this->parent_rec->tank_id);
        $q->andWhere('t.tsrc_id = ?', $uuid);

        // join more stuff
        if (!$minimal) {
            $q->leftJoin('t.Source s');
            $q->leftJoin('t.TankFact tf');
            $q->leftJoin('tf.Fact f');
            $q->leftJoin('tf.AnalystFV afv');
            $q->leftJoin('tf.SourceFV sfv');
        }

        // fetch
        $rec = $q->fetchOne();
        return $rec;
    }


    /**
     * Update
     *
     * @param TankSource $rec
     * @param array   $data
     */
    protected function air_update($rec, $data) {
        $this->check_authz($rec, 'write'); // DO FIRST!

        // validation
        if (isset($data['resolve']) && isset($data['redo'])) {
            $msg = 'Cannot resolve and redo at the same time';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
        if (isset($data['resolve']) && !is_array($data['resolve'])) {
            $msg = "Key 'resolve' must be an array";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // run operation
        if (isset($data['resolve'])) {
            $this->_resolve_conflict($rec, $data['resolve']);
        }
        elseif (isset($data['redo'])) {
            $this->_redo_discrimination($rec);
        }
    }


    /**
     * Resolve conflicts on a tank_source
     *
     * @param TankSource $rec
     * @param array   $ops
     */
    private function _resolve_conflict($rec, $ops) {
        if ($rec->tsrc_status != TankSource::$STATUS_CONFLICT) {
            $msg = 'Must be in CONFLICT status to use resolve operations';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // convert model-names to column-names
        foreach ($ops as $key => $op) {
            if (isset(TankSource::$COLS[$key])) {
                foreach (TankSource::$COLS[$key] as $colname) {
                    if (!isset($ops[$colname])) {
                        $ops[$colname] = $op;
                    }
                }
                unset($ops[$key]);
            }
        }

        // decide what's valid
        $conn = AIR2_DBManager::get_connection();
        $valid_ops = array('I', 'R', 'A', 'P');
        $valid_keys = Doctrine::getTable('TankSource')->getFieldNames();
        $fs = $conn->fetchAll('select fact_identifier, fact_fv_type from fact');
        foreach ($fs as $row) {
            $t = $row['fact_fv_type'];
            $valid_keys[] = $row['fact_identifier'];
            if ($t == Fact::$FV_TYPE_MULTIPLE || $t == Fact::$FV_TYPE_FK_ONLY) {
                $valid_keys[] = $row['fact_identifier'].'.sf_fv_id';
                $valid_keys[] = $row['fact_identifier'].'.sf_src_fv_id';
            }
            if ($t == Fact::$FV_TYPE_MULTIPLE || $t == Fact::$FV_TYPE_STR_ONLY) {
                $valid_keys[] = $row['fact_identifier'].'.sf_src_value';
            }
        }

        // validate resolve data
        foreach ($ops as $key => $op) {
            if (!in_array($key, $valid_keys)) {
                $msg = "Invalid resolve key $key";
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }
            if (!in_array($op, $valid_ops)) {
                $vs = 'Valid ops are: ('.implode(',', $valid_ops).')';
                $msg = "Invalid operation '$op' for key $key - $vs";
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }
        }

        // call perl discriminator ... hope for the best!
        try {
            $ops = count($ops) ? $ops : null;
            CallPerl::set_env('REMOTE_USER='.$this->user->user_username);
            $stat = CallPerl::exec('AIR2::TankSource->discriminate', $rec->tsrc_id, $ops);
            $this->_queue_notification($rec);
        }
        catch (PerlException $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
    }


    /**
     * Entirely redo discrimination on a tank_source
     *
     * @param TankSource $rec
     */
    private function _redo_discrimination($rec) {
        $valid = array(TankSource::$STATUS_ERROR, TankSource::$STATUS_CONFLICT);
        if (!in_array($rec->tsrc_status, $valid)) {
            $msg = 'Must be in ERROR or CONFLICT status to use redo';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // reset tank_source entirely (BUT to error --- avoid NEW status)
        $rec->tsrc_status = TankSource::$STATUS_ERROR;
        $rec->tsrc_errors = null;
        $this->air_save($rec);

        // call perl discriminator
        try {
            CallPerl::set_env('REMOTE_USER='.$this->user->user_username);
            $stat = CallPerl::exec('AIR2::TankSource->discriminate', $rec->tsrc_id);
        }
        catch (PerlException $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
    }


    /**
     * Create JobQueue for send-watcher-email.
     *
     * @param TankSource $tsrc
     */
    private function _queue_notification($tsrc) {
        $tank = $tsrc->Tank;

        // querymaker imports only
        if ($tank->tank_type != Tank::$TYPE_QM) {
            return;
        }
        $job = new JobQueue();
        $job->jq_job = sprintf("PERL AIR2_ROOT/bin/send-watcher-email --inq_uuid %s --complete 1 --srs_uuid %s",
            $tank->tank_xuuid, $tsrc->TankResponseSet[0]->srs_uuid);
        $job->jq_start_after_dtim = air2_date(time() + (5 * 60));  // let search index update
        $this->air_save($job);
    }


    /**
     * Add "Conflict-With" data to fetch
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @param array   $extra  (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $data = parent::format($mixed, $method, $uuid, $extra);

        // only add on update/fetch, and only when status = CONFLICT
        if (!$data['success']) return $data;
        if ($method != 'update' && $method != 'fetch') return $data;
        if ($data['radix']['tsrc_status'] != TankSource::$STATUS_CONFLICT) return $data;

        // look for conflicts with something
        $withs = array();
        $cons = json_decode($data['radix']['tsrc_errors'], true);
        if ($cons) {
            if (isset($cons['initial'])) {
                foreach ($cons['initial'] as $key => $confl) {
                    if (($c = $this->_get_with($key, $confl))) {
                        $withs[$key] = $c;
                    }
                }
            }

            // make sure we didn't miss any
            if (isset($cons['last'])) {
                foreach ($cons['initial'] as $key => $confl) {
                    if (!isset($withs[$key]) && ($c = $this->_get_with($key, $confl))) {
                        $withs[$key] = $c;
                    }
                }
            }
        }
        $data['radix']['tsrc_withs'] = $withs;

        // also return the tsrc_id of the next conflict (if any)
        $conn = AIR2_DBManager::get_connection();
        $tid = $this->parent_rec->tank_id;
        $tsid = $data['radix']['tsrc_id'];
        $st = TankSource::$STATUS_CONFLICT;
        $q = "select tsrc_id from tank_source where tsrc_tank_id = ? " .
            "and tsrc_id != ? and tsrc_status = ? limit 1";
        $next = $conn->fetchOne($q, array($tid, $tsid, $st), 0);
        $data['radix']['next_conflict'] = $next;

        return $data;
    }


    /**
     * Attempt to fetch conflict-with existing record from database
     *
     * @param type    $key
     * @param type    $confl
     * @return type
     */
    private function _get_with($key, $confl) {
        $mname = TankSource::get_model_for($key);
        if ($mname && isset($confl['uuid'])) {
            if ($mname != 'SrcFact') {
                $rec = AIR2_Record::find($mname, $confl['uuid']);
                if ($rec) {
                    $data = $rec->toArray();
                    air2_clean_radix($data);
                    return $data;
                }
            }
            else {
                // facts suck ... src_id.fact_id ... use raw sql for speed!
                $ids = explode('.', $confl['uuid']);
                if ($ids && count($ids) == 2) {
                    $conn = AIR2_DBManager::get_connection();
                    $s = 'f.fact_id, f.fact_name, f.fact_identifier, f.fact_fv_type, ' .
                        'afv.fv_value as analyst_fv, sfv.fv_value as source_fv, ' .
                        'sf.sf_src_value as source_text, sf.sf_lock_flag';
                    $f = 'src_fact sf join fact f on (sf.sf_fact_id=f.fact_id) left ' .
                        'join fact_value afv on (sf.sf_fv_id=afv.fv_id) left join ' .
                        'fact_value sfv on (sf.sf_src_fv_id=sfv.fv_id)';
                    $w = 'sf_src_id=? and sf_fact_id=?';
                    $rs = $conn->fetchRow("select $s from $f where $w", array($ids[0], $ids[1]));
                    if ($rs) {
                        return $rs;
                    }
                }
            }
        }
        return false;
    }


}
