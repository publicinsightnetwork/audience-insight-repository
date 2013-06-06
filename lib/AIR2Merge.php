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


/**
 * AIR2Merge utility class
 *
 * Static class for Source-merge functionality
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2Merge {

    /* indicates which record to choose if there's a conflict */
    const OPTPRIME = 'P';
    const OPTMERGE = 'M';

    /* configuration for "easy" merges, where we just need to change a FK */
    protected static $EASY_CONFIG = array(
        //'src_org' => 'so_src_id', //combine
        //'src_stat' => 'sstat_src_id', //combine

        'BinSource'         => 'bsrc_src_id', //avoid dups
        'SrcActivity'       => 'sact_src_id',
        'SrcAlias'          => 'sa_src_id',
        'SrcAnnotation'     => 'srcan_src_id',
        'SrcEmail'          => 'sem_src_id', //primary flag
        'SrcInquiry'        => 'si_src_id',
        'SrcMailAddress'    => 'smadd_src_id', //primary flag
        'SrcMediaAsset'     => 'sma_src_id',
        'SrcPhoneNumber'    => 'sph_src_id', //primary flag
        //'SrcRelationship' => 'srel_src_id', how to handle?
        'SrcResponse'       => 'sr_src_id',
        'SrcResponseSet'    => 'srs_src_id',
        'SrcUri'            => 'suri_src_id',
        'SrcVita'           => 'sv_src_id',
        'Tags'              => 'tag_xid', //avoid dups
        'TankSource'        => 'src_id',
        'Trackback'         => 'tb_src_id',
    );
    protected static $PRIMARY_FLAGS = array(
        'SrcEmail'       => 'sem_primary_flag',
        'SrcMailAddress' => 'smadd_primary_flag',
        'SrcPhoneNumber' => 'sph_primary_flag',
        'SrcUri'         => 'suri_primary_flag',
    );

    /* cache of merge options */
    protected static $MERGE_OPTS = array();

    /* the result data from the last attempted merge */
    protected static $MERGE_RESULT = array();


    /**
     * Merge 2 source records together, including all related data.
     *
     * @param Source  $prime   the record to merge into (will be preserved)
     * @param Source  $merge   the record to merge from (will be deleted)
     * @param array   $options (optional) options to use in merging conflicting data
     * @param boolean $commit  (optional)
     * @return boolean|string|array
     */
    public static function merge($prime, $merge, $options=array(), $commit=false) {
        self::$MERGE_OPTS = $options;
        self::$MERGE_RESULT = array(
            'errs'    => array(),
            'prime'   => array(),
            'merge'   => array(),
            'moved'   => array(),
            'skipped' => array(),
        );

        // make sure we have fresh objects
        $prime->clearRelated();
        $merge->clearRelated();

        // start a transaction
        $conn = AIR2_DBManager::get_master_connection();
        $conn->beginTransaction();

        // run the merges
        try {
            self::merge_source($prime, $merge);
            self::merge_facts($prime, $merge);

            // remaining data produces no errors... so only run on commit
            if ($commit) {
                self::merge_easy($prime, $merge);
                self::combine_orgs($prime, $merge);
                self::combine_stat($prime, $merge);
            }

            // delete the merged source
            $merge->delete();
        }
        catch (Exception $e) {
            $conn->rollback();
            self::$MERGE_RESULT['fatal_error'] = $e->getMessage();
            return self::$MERGE_RESULT['fatal_error'];
        }

        // cache the merge result
        self::$MERGE_RESULT['result'] = $prime->toArray(true);

        // commit or rollback
        $errors = self::$MERGE_RESULT['errs'];
        if (count($errors) == 0 && $commit) {
            $conn->commit();
        }
        else {
            $conn->rollback();
            $prime->clearRelated();
            $prime->refresh();
            $merge->clearRelated();
            $merge->refresh();
        }

        // return errors or true on success
        if (count($errors) > 0) {
            return $errors;
        }
        else {
            return true;
        }
    }


    /**
     * Static function to get the resulting object from the last merge, even
     * if it wasn't commited.
     *
     * @return array
     */
    public static function get_result() {
        return self::$MERGE_RESULT;
    }


    /**
     * Determines what (if any) merge options are set for a specific column
     *
     * @param string  $model
     * @param string  $col
     * @return char|false
     */
    protected static function get_opt($model, $col) {
        if (isset(self::$MERGE_OPTS[$model])) {
            if (is_string(self::$MERGE_OPTS[$model])) {
                return self::$MERGE_OPTS[$model]; //same opt for every column
            }
            elseif (isset(self::$MERGE_OPTS[$model][$col])) {
                return self::$MERGE_OPTS[$model][$col];
            }
        }
        return false; //no option!
    }


    /**
     * Update a column of the prime record with the merge record, checking for
     * conflict resolutions in $opts, and throwing Exceptions for any
     * unresolved conflicts.
     *
     * @param AIR2_Record $prime
     * @param AIR2_Record $merge
     * @param string  $model
     * @param string  $col
     * @return char|bool true for no conflict, false for unresolved, or opt
     */
    protected static function update_prime($prime, $merge, $model, $col) {
        if ($merge->$col && !$prime->$col) {
            // merge can replace NULL prime
            $prime->$col = $merge->$col;
        }
        elseif ($merge->$col && $prime->$col && $merge->$col != $prime->$col) {
            // conflict! check options
            $opt = self::get_opt($model, $col);
            if ($opt == AIR2Merge::OPTPRIME) {
                return $opt;
            }
            elseif ($opt == AIR2Merge::OPTMERGE) {
                $prime->$col = $merge->$col;
                return $opt;
            }
            else {
                return false;
            }
        }
        return true;
    }


    /**
     * Merge the Source records together.
     *
     * @param Source  $prime the record to merge into (will be preserved)
     * @param Source  $merge the record to merge from (will be deleted)
     */
    protected static function merge_source($prime, $merge) {
        // FAIL if $merge has_acct!
        if ($merge->src_has_acct == Source::$ACCT_YES) {
            throw new Exception('Cannot merge Source with SOURCE account!');
        }

        // fail if fields will overwrite (without a resolving $opts)
        $flds = array('src_first_name', 'src_last_name', 'src_middle_initial',
            'src_pre_name', 'src_post_name');
        foreach ($flds as $colname) {
            $r = self::update_prime($prime, $merge, 'Source', $colname);
            if ($r === false) {
                self::$MERGE_RESULT['errs'][] = array('Source' => $colname);
            }
            elseif ($r === AIR2Merge::OPTPRIME) {
                self::$MERGE_RESULT['prime'][] = array('Source' => $colname);
            }
            elseif ($r === AIR2Merge::OPTMERGE) {
                self::$MERGE_RESULT['merge'][] = array('Source' => $colname);
            }
        }

        // save changes
        $prime->save();
    }


    /**
     * Merge SrcFacts together.
     *
     * @param Source  $prime the record to merge facts into
     * @param Source  $merge the record to merge facts from
     */
    protected static function merge_facts($prime, $merge) {
        // index by fact_id
        $indexed_facts = array();
        foreach ($prime->SrcFact as $sf) {
            $fact_id = $sf->sf_fact_id;
            $indexed_facts[$fact_id] = $sf;
        }

        // check for conflicts with $merge
        foreach ($merge->SrcFact as $sf) {
            $fact_id = $sf->sf_fact_id;

            if (isset($indexed_facts[$fact_id])) {
                $prime_sf = $indexed_facts[$fact_id];

                // pick truest of the flags
                if ($sf->sf_lock_flag) {
                    $prime_sf->sf_lock_flag = true;
                }
                if ($sf->sf_public_flag) {
                    $prime_sf->sf_public_flag = true;
                }

                // merge fields
                $model = "Fact.$fact_id";
                $flds = array('sf_fv_id', 'sf_src_value', 'sf_src_fv_id');
                foreach ($flds as $colname) {
                    $r = self::update_prime($prime_sf, $sf, $model, $colname);
                    if ($r === false) {
                        self::$MERGE_RESULT['errs'][] = array($model => $colname);
                    }
                    elseif ($r === AIR2Merge::OPTPRIME) {
                        self::$MERGE_RESULT['prime'][] = array($model => $colname);
                    }
                    elseif ($r === AIR2Merge::OPTMERGE) {
                        self::$MERGE_RESULT['merge'][] = array($model => $colname);
                    }
                }
            }
            else {
                // duplicate fact to $prime
                $dup = $sf->copy();
                $dup->sf_src_id = $prime->src_id;
                $dup->save();
                $indexed_facts[$fact_id] = $dup;
            }
        }

        // clear the stuff we loaded
        $prime->clearRelated('SrcFact');
        $merge->clearRelated('SrcFact');
    }


    /**
     * Merge the easy-to-handle tables, where we just need to change the
     * src_id foreign key to point at the new source.
     *
     * @param Source  $prime the record to merge into (will be preserved)
     * @param Source  $merge the record to merge from (will be deleted)
     */
    protected static function merge_easy($prime, $merge) {
        $prime_id = $prime->src_id;

        foreach (self::$EASY_CONFIG as $rel_name => $fk_col) {
            // figure out any primary flags
            $primary_obj_id = false;
            $flag_col = (isset(self::$PRIMARY_FLAGS[$rel_name])) ?
                self::$PRIMARY_FLAGS[$rel_name] : false;
            if ($flag_col && $merge->$rel_name->count() > 0) {
                // look for a primary on the prime source
                foreach ($prime->$rel_name as $related) {
                    if ($related->$flag_col) {
                        $primary_obj_id = $related->identifier();
                        break;
                    }
                }

                // not found?  check the merge source
                if (!$primary_obj_id) {
                    foreach ($merge->$rel_name as $related) {
                        $primary_obj_id = $related->identifier(); //default
                        if ($related->$flag_col) {
                            $primary_obj_id = $related->identifier();
                            break;
                        }
                    }
                }
            }

            // change the foreign key of each merge-related item
            foreach ($merge->$rel_name as $related) {
                // check for primary flag
                if ($flag_col) {
                    $related->$flag_col = ($related->identifier() == $primary_obj_id);
                }

                // try to use 'link' instead of setting keys directly
                if ($related->hasRelation('Source')) {
                    $related->link('Source', array($prime_id));
                }
                else {
                    $related->$fk_col = $prime_id;
                }
                try {
                    $related->save();
                    if (!isset(self::$MERGE_RESULT['moved'][$rel_name])) {
                        self::$MERGE_RESULT['moved'][$rel_name] = 1;
                    }
                    else {
                        self::$MERGE_RESULT['moved'][$rel_name]++;
                    }
                }
                catch (Doctrine_Connection_Exception $e) {
                    // okay to skip unique-key duplicate errs
                    if ($e->getPortableCode() == Doctrine_Core::ERR_ALREADY_EXISTS) {
                        if (!isset(self::$MERGE_RESULT['skipped'][$rel_name])) {
                            self::$MERGE_RESULT['skipped'][$rel_name] = 1;
                        }
                        else {
                            self::$MERGE_RESULT['skipped'][$rel_name]++;
                        }
                    }
                    else {
                        throw $e; //re-throw
                    }
                }
            }

            // clear the stuff we loaded
            $prime->clearRelated($rel_name);
            $merge->clearRelated($rel_name);
        }
    }


    /**
     * Combine src_orgs for the sources, picking the highest level of opt-in
     * for any conflicting orgs.
     *
     * @param Source  $prime the record to merge into (will be preserved)
     * @param Source  $merge the record to merge from (will be deleted)
     */
    protected static function combine_orgs($prime, $merge) {
        // priority of src_org status
        $priority = array(
            SrcOrg::$STATUS_OPTED_IN => 4,
            SrcOrg::$STATUS_EDITORIAL_DEACTV => 3,
            SrcOrg::$STATUS_OPTED_OUT => 2,
            SrcOrg::$STATUS_DELETED => 1,
        );

        // index by org_id
        $prime_orgs = array();
        foreach ($prime->SrcOrg as $so) {
            $prime_orgs[$so->so_org_id] = $so;
        }

        // add/update from merge
        foreach ($merge->SrcOrg as $so) {
            $orgid = $so->so_org_id;
            $stat = $so->so_status;

            // update or insert
            if (isset($prime_orgs[$orgid])) {
                $current = $prime_orgs[$orgid]->so_status;
                if ($priority[$stat] > $priority[$current]) {
                    $prime_orgs[$orgid]->so_status = $stat;
                    $prime_orgs[$orgid]->save();
                }
                if (!isset(self::$MERGE_RESULT['skipped']['SrcOrg'])) {
                    self::$MERGE_RESULT['skipped']['SrcOrg'] = 1;
                }
                else {
                    self::$MERGE_RESULT['skipped']['SrcOrg']++;
                }
            }
            else {
                $so->so_src_id = $prime->src_id;
                $so->save();
                if (!isset(self::$MERGE_RESULT['moved']['SrcOrg'])) {
                    self::$MERGE_RESULT['moved']['SrcOrg'] = 1;
                }
                else {
                    self::$MERGE_RESULT['moved']['SrcOrg']++;
                }
            }
        }

        // clear loaded
        $prime->clearRelated('SrcOrg');
        $merge->clearRelated('SrcOrg');

        // recalculate prime SrcOrgCache
        SrcOrgCache::refresh_cache($prime->src_id);
    }


    /**
     * Combine src_stats for the sources, picking the most recent of any dtim
     * columns.
     *
     * @param Source  $prime
     * @param Source  $merge
     */
    protected static function combine_stat($prime, $merge) {
        $prime_stat = $prime->SrcStat;
        $merge_stat = $merge->SrcStat;

        $data = $merge_stat->toArray();
        foreach ($data as $key => $value) {
            if (preg_match('/_dtim$/', $key)) {
                // check for more recent dtim in merge
                if ($prime_stat->$key < $merge_stat->$key) {
                    $prime_stat->$key = $merge_stat->$key;
                }
            }
        }
        $prime_stat->save();

        // clear loaded
        $prime->clearRelated('SrcStat');
        $merge->clearRelated('SrcStat');
    }


}
