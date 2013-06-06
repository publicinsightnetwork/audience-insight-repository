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
 * AIR2 Discriminator
 *
 * Process to look at a row in the tank table, and attempt to import all of its
 * tank_sources, tank_response_sets, and tank_responses into the normal AIR2
 * tables.  Used to import bulk data into AIR2, and resolve any conflicts
 * between that data and existing AIR2 data.
 *
 * @author rcavis
 * @package default
 */
class Discriminator {
    protected $tank;
    protected $conn;
    public $conflict_count;
    public $error_count;
    public $done_count;

    /* define how large of chunks to process at a time */
    public static $TSRC_BATCH_SIZE = 40;

    /**
     * Cache a reference to the master db connection.
     */
    public function __construct() {
        AIR2_DBManager::$FORCE_MASTER_ONLY = true;
        $this->conn = AIR2_DBManager::get_master_connection();
        $this->src_table = Doctrine::getTable('Source');
    }


    /**
     * Starting point for the Discriminator.  Attempts to lock a specific tank
     * record, and synchronously processes tank_sources for that tank.  Returns
     * true if the tank was retrieved, locked, and the discriminator run on the
     * tank_sources in that tank (regardless of the success/failure of those
     * tank_sources).  Return false if the tank or any of the tank_sources
     * could not be locked.
     *
     * Can also be run on a subset of tank_sources by passing in an integer or
     * array as the second param.
     *
     * Specific ignore/replace/add operations can be passed in through the $ops
     * parameter.  Normally, this is only used on a single $tsrc_id, coming
     * through the conflict-resolver UI.  The operations will have the format:
     *      $ops = array(
     *          [Model] => [operation]
     *          'SrcPhoneNumber] => AIR2_DISCRIM_ADD,
     *          'Source' => AIR2_DISCRIM_REPLACE,
     *          [Fact.fact_id] = [operation]
     *          'Fact.3' = AIR2_DISCRIM_REPLACE,
     *      );
     *
     * @param integer $tank_id
     * @param integer|array $tsrc_ids
     * @param array   $ops
     * @return boolean
     */
    public function run($tank_id, $tsrc_ids=null, $ops=null) {
        // make sure tsrc_id is an array
        if (!is_array($tsrc_ids) && !is_null($tsrc_ids)) {
            $tsrc_ids = array($tsrc_ids);
        }

        // reset counts
        $this->conflict_count = 0;
        $this->error_count = 0;
        $this->done_count = 0;

        // get the tank record
        $this->tank = Doctrine::getTable('Tank')->find($tank_id);

        // lock the table for processing
        if (!$this->tank || !$this->lock_tank($tsrc_ids)) {
            return false;
        }

        // process tank_sources, running as the tank_user
        if (!defined('AIR2_REMOTE_USER_ID')) {
            define('AIR2_REMOTE_USER_ID', $this->tank->tank_user_id);
        }
        $this->process_tank_sources($tsrc_ids, $ops);

        // unlock the tank, setting the status
        $this->tank->refresh(); //make sure cache is in-sync
        $q = 'select count(*) from tank_source where tsrc_tank_id = ? and tsrc_status != ?';
        $not_done = $this->conn->fetchOne($q, array($this->tank->tank_id, TankSource::$STATUS_DONE), 0);
        if ($not_done > 0) {
            $this->tank->tank_status = Tank::$STATUS_TSRC_CONFLICTS;
        }
        else {
            $this->tank->tank_status = Tank::$STATUS_READY;
        }
        $this->tank->save();
        return true;
    }


    /**
     * Attempt to lock the running tank record and all of its tank_sources.
     * Optionally filter the tank_sources down to a subset identified by their
     * keys. Returns true if the tank and all its tank_sources could be locked.
     *
     * @param array   $tsrc_ids
     * @return boolean
     */
    protected function lock_tank($tsrc_ids=null) {
        $this->conn->beginTransaction();
        $tank_locked = true;
        $tank_sources_locked = true;

        // attempt to lock the tank record
        $q = Doctrine_Query::create()->update('Tank');
        $q->set('tank_status', '?', Tank::$STATUS_LOCKED);
        $q->whereIn('tank_status', array(Tank::$STATUS_READY,
            Tank::$STATUS_TSRC_CONFLICTS, Tank::$STATUS_TSRC_ERRORS));
        $q->andWhere('tank_id = ?', $this->tank->tank_id);
        $rows = $q->execute();
        $q->free();
        $tank_locked = ($rows == 1);

        // if that worked, try to lock all the tank_source records
        if ($tank_locked) {
            // make sure nothing is locked yet
            $q = Doctrine_Query::create()->from('TankSource');
            $q->where('tsrc_tank_id = ?', $this->tank->tank_id);
            $q->andWhere('tsrc_status = ?', TankSource::$STATUS_LOCKED);
            if ($tsrc_ids) $q->andWhereIn('tsrc_id', $tsrc_ids);

            if ($q->count() > 0) {
                $q->free();
                $tank_sources_locked = false;
            }
            else {
                // lock the tank_sources (not errors or dones)
                $q->free();
                $q = Doctrine_Query::create()->update('TankSource');
                $q->set(array('tsrc_status' => TankSource::$STATUS_LOCKED));
                $q->where('tsrc_tank_id = ?', $this->tank->tank_id);

                // explicit tsrc_ids may lock ERROR rows
                $allowed = array(TankSource::$STATUS_NEW, TankSource::$STATUS_CONFLICT);
                if ($tsrc_ids) {
                    $allowed[] = TankSource::$STATUS_ERROR;
                    $q->andWhereIn('tsrc_id', $tsrc_ids);
                }
                $q->andWhereIn('tsrc_status', $allowed);
                $num = $q->execute();
                $q->free();

                // make sure we locked everything we should have
                if ($tsrc_ids && $num != count($tsrc_ids)) {
                    $tank_sources_locked = false;
                }
            }
        }

        // commit if everything locked OK
        if ($tank_locked && $tank_sources_locked) {
            $this->conn->commit();
            return true;
        }
        else {
            $this->conn->rollback();
            return false;
        }
    }


    /**
     * Process the locked tank_sources for the loaded tank.  Optionally allows
     * you to process a subset of tank_sources identified by their keys.
     *
     * @param array   $tsrc_ids
     * @param array   $ops
     */
    protected function process_tank_sources($tsrc_ids=null, $ops=null) {
        if (!$tsrc_ids) {
            // get the ID's of everything we're going to process
            $q = 'SELECT tsrc_id FROM tank_source WHERE tsrc_tank_id = ? AND tsrc_status = ?';
            $params = array($this->tank->tank_id, TankSource::$STATUS_LOCKED);
            $conn = AIR2_DBManager::get_connection();
            $tsrc_ids = $this->conn->fetchColumn($q, $params, 0);

            if (count($tsrc_ids) == 0) return;
        }

        // process query in chunks
        $chunks = array_chunk($tsrc_ids, self::$TSRC_BATCH_SIZE);

        foreach ($chunks as $idx => $ids) {
            // debugging for memory leaks
            if (defined('DISCRIM_MEM_DEBUG')) {
                echo "RUNNING CHUNK $idx => ".(memory_get_usage()/1024)."\n";
            }

            $q = Doctrine_Query::create()->from('TankSource');
            $q->andWhere('tsrc_tank_id = ?', $this->tank->tank_id);
            $q->andWhereIn('tsrc_id', $ids);
            $recs = $q->execute();
            $this->run_batch($recs, $ops);

            // cleanup
            $recs->free(true);
            unset($recs);
            $q->free();
        }
    }


    /**
     * Process a subset of TankSources
     *
     * @param Doctrine_Collection $recs
     * @param array   $ops
     */
    protected function run_batch($recs, $ops) {
        foreach ($recs as $tsrc) {
            // make sure we don't hold (and clear) any Tank ref
            $tsrc->clearRelated('Tank');

            // if $ops were passed, set tsrc to resolution mode
            if ($ops && count($ops) > 0) {
                $tsrc->set_conflict_mode(false);
            }
            $tsrc->clear_errors();

            $src = $this->identify_source($tsrc);
            $exists = false; // track whether source already existed
            if ($src) {
                $exists = $src->exists();

                // existing sources - cache ID, and MUST be opted-in right away
                if ($exists) {
                    $tsrc->src_id = $src->src_id;
                    $tsrc->src_uuid = $src->src_uuid;
                    $this->tank->process_orgs($src);
                }

                // move the source
                $this->move_tank_source($tsrc, $src, $ops);
            }

            // update done/conflict/error counts
            if ($tsrc->tsrc_status == TankSource::$STATUS_ERROR) {
                $this->error_count++;
            }
            elseif ($tsrc->tsrc_status == TankSource::$STATUS_CONFLICT) {
                $this->conflict_count++;
            }
            else {
                // new sources - cache id and opt-in
                if (!$exists) {
                    $tsrc->src_id = $src->src_id;
                    $tsrc->src_uuid = $src->src_uuid;
                    $this->tank->process_orgs($src);
                }

                // log activity and increment done
                $this->tank->process_activity($src);
                $this->done_count++;
            }
            $tsrc->save();

            // cleanup
            if ($src) {

                // set status after all children are saved
                $src->set_and_save_src_status();

                $src->free();
            }
        }
    }


    /**
     * Attempts to move a tank_source into its source-record tables.
     *
     * @param TankSource $tsrc
     * @param Source  $src
     * @param array   $ops
     */
    protected function move_tank_source($tsrc, $src, $ops) {
        // start a transaction and track any conflicts
        $this->conn->beginTransaction();

        // move all related data out of the tank_source
        foreach (TankSource::$COLS as $name => $def) {
            $data = $tsrc->get_tank_data($name);
            if ($name == 'Source') {
                $op = isset($ops['Source']) ? $ops['Source'] : null;
                $this->resolve_conflicts($src, $data, $tsrc, $op);
            }
            else {
                $rec = new $name;

                // set the FK before resolving
                $col = $rec->getTable()->getRelation('Source')->getLocal();
                $rec->$col = $src->src_id;
                $op = isset($ops[$name]) ? $ops[$name] : null;
                $this->resolve_conflicts($rec, $data, $tsrc, $op);

                // cleanup
                $rec->free();
            }
        }

        // move tank_facts to src_facts
        $q = Doctrine_Query::create()->from('TankFact tf');
        $q->where('tf.tf_tsrc_id = ?', $tsrc->tsrc_id);
        $tfacts = $q->fetchArray();
        $q->free();

        foreach ($tfacts as $idx => $tf) {
            $new_fact = new SrcFact();
            $new_fact->sf_src_id = $src->src_id;
            $new_fact->sf_fact_id = $tf['tf_fact_id'];
            $f = 'Fact.'.$tf['tf_fact_id'];
            $op = isset($ops[$f]) ? $ops[$f] : null;

            foreach ($tf as $key => $val) {
                if (substr($key, 0, 2) != 'sf') unset($tf[$key]);
            }
            $this->resolve_conflicts($new_fact, $tf, $tsrc, $op);

            $new_fact->free();
        }

        // move tank_vita to src_vita
        $q = Doctrine_Query::create()->from('TankVita tv');
        $q->where('tv.tv_tsrc_id = ?', $tsrc->tsrc_id);
        $tvita = $q->fetchArray();
        $q->free();

        foreach ($tvita as $idx => $tv) {
            $new_vita = new SrcVita();
            $new_vita->sv_src_id = $src->src_id;

            // unset non-"sv" keys
            foreach ($tv as $key => $val) {
                if (substr($key, 0, 2) != 'sv') unset($tv[$key]);
            }

            // no ops allowed on vita (yet)
            $this->resolve_conflicts($new_vita, $tv, $tsrc);
            $new_vita->free();
        }

        // move any tank_response_sets for the tank_source
        $q = Doctrine_Query::create()->from('TankResponseSet trs');
        $q->leftJoin('trs.TankResponse tr');
        $q->where('trs.trs_tsrc_id = ?', $tsrc->tsrc_id);
        $trsets = $q->fetchArray();
        $q->free();

        foreach ($trsets as $trs) {
            $this->move_tank_response_set($trs, $src->src_id, $tsrc);
        }

        // process any tags on the source
        if ($tsrc->tsrc_tags || strlen($tsrc->tsrc_tags)) {
            $tags = $tsrc->tsrc_tags;
            $tags = explode(',', $tags);
            foreach ($tags as $tag) {
                Tag::make_tag($src->src_id, Tag::$TYPE_SOURCE, trim($tag));
            }
        }

        // commit or rollback based on any conflicts
        if ($tsrc->tsrc_status == TankSource::$STATUS_ERROR
            || $tsrc->tsrc_status == TankSource::$STATUS_CONFLICT) {
            $this->conn->rollback();
        }
        else {
            $this->conn->commit();
            $tsrc->tsrc_status = TankSource::$STATUS_DONE;
            $tsrc->tsrc_errors = null; //delete any errors/conflicts
        }
    }


    /**
     * Attempts to discriminate data being saved to a record, tracking any
     * conflicts.  Note that the AIR2_Record->discriminate() method should
     * save the record, so call it from a try-catch.
     *
     * @param AIR2_Record $rec
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    protected function resolve_conflicts($rec, $data, $tsrc, $op=null) {
        // ignore this piece of the tank_source
        if ($op == AIR2_DISCRIM_IGNORE) return;

        // unset any null data vals
        foreach ($data as $key => $val) {
            if (is_null($val)) {
                unset($data[$key]);
            }
            elseif (is_string($val) && strlen($val) == 0) {
                unset($data[$key]);
            }
        }

        // discriminate, if we have data
        if (count($data) > 0) {
            $rec->discriminate($data, $tsrc, $op);
            // try to save the record
            try {
                $rec->save();
            }
            catch (Doctrine_Validator_Exception $e) {
                $cls = get_class($rec);
                $stack = $rec->getErrorStack()->toArray();
                foreach ($stack as $col => $problem) {
                    $tsrc->add_conflict($cls, $col, $problem);
                }
            }
            catch (Exception $e) {
                $cls = get_class($rec);
                $msg = $e->getMessage();
                $tsrc->add_error("FATAL ERROR on $cls - $msg");
            }
        }
    }


    /**
     * Identify a Source from a TankSource, or create a new Source.
     *
     * @param TankSource $tsrc
     * @return boolean|Source success
     */
    protected function identify_source($tsrc) {
        // src_id and src_uuid ONLY identify existing records
        if ($tsrc->src_id || $tsrc->src_uuid) {
            $col = ($tsrc->src_id) ? 'src_id' : 'src_uuid';
            $q = Doctrine_Query::create()->from('Source');
            $q->where("$col = ?", $tsrc->$col);
            $rec = $q->fetchOne();
            $q->free();

            // return early
            if ($rec) {
                return $rec;
            }
            else {
                $tsrc->add_error("Invalid $col!");
                return false;
            }
        }

        // src_username and sem_email identify existing OR new records
        elseif ($tsrc->src_username || $tsrc->sem_email) {
            // trim on first run
            if ($tsrc->src_username) $tsrc->src_username = trim($tsrc->src_username);
            if ($tsrc->sem_email) $tsrc->sem_email = trim($tsrc->sem_email);
            $q = Doctrine_Query::create()->from('Source a');
            if ($tsrc->src_username) {
                $q->where('a.src_username = ?', $tsrc->src_username);
            }
            else {
                $q->leftJoin('a.SrcEmail e');
                $q->where('e.sem_email = ?', $tsrc->sem_email);
            }
            $rec = $q->fetchOne();
            $q->free();

            // create if DNE
            if (!$rec) {
                $rec = new Source();
                $rec->src_uuid = air2_generate_uuid();

                // special case: handle nosuchemail.org
                $nosuch = '/@nosuchemail.org$/i';
                if (preg_match($nosuch, $tsrc->src_username) || preg_match($nosuch, $tsrc->sem_email)) {
                    $tsrc->src_username = $rec->src_uuid.'@nosuchemail.org';
                    $tsrc->sem_email = $tsrc->src_username;
                }

                // if no username, set to email
                elseif (!$tsrc->src_username) {
                    $tsrc->src_username = strtolower($tsrc->sem_email);

                    // make sure username isn't taken
                    $chk = 'select count(*) from source where src_username = ?';
                    $n = $this->conn->fetchOne($chk, array($tsrc->src_username), 0);

                    // if taken, prepend UUID to username
                    if ($n > 0) {
                        $tsrc->src_username = $rec->src_uuid.'@'.$tsrc->src_username;
                    }
                }
            }
            return $rec;
        }

        // no identifiers set!
        $tsrc->add_error('Unable to resolve a Source record!');
        return false;
    }


    /**
     * Move tank_response_set records into src_response_set.
     *
     * @param array   $data   TankResponseSet data
     * @param integer $src_id
     * @param TankSource $tsrc
     */
    protected function move_tank_response_set($data, $src_id, $tsrc) {
        // get array data from the tank_response_set
        $data['SrcResponse'] = $data['TankResponse'];

        // create a new response set
        $new_resp = new SrcResponseSet();
        $new_resp->fromArray($data, true); //deep

        // add the source id's
        $new_resp->srs_src_id = $src_id;
        foreach ($new_resp->SrcResponse as $r) {
            $r->sr_src_id = $src_id;
        }

        try {
            $new_resp->save();
        }
        catch (Exception $e) {
            $msg = $e->getMessage();
            $tsrc->add_error("FATAL ERROR creating Source Responses - $msg");
        }

        // cleanup
        $new_resp->free(true);
    }


}
