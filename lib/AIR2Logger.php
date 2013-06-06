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

require_once 'mover/air2reader/ArrayReader.php';
require_once 'mover/air2writer/SqlWriter.php';
require_once 'mover/air2writer/MySqlImporter.php';

/**
 * AIR2Logger utility class
 *
 * Static class for activity-logging functions relating to AIR2.
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2Logger {
    public static $ENABLE_LOGGING = false; //TODO: enable

    /* Logging configuration */
    protected static $CONFIG = array(
        /*
         * PROJECT LOGGING
         */
        'Project' => array(
            // inserted project
            array(
                'oninsert' => true,
                'fields'   => array(),
                'action'   => 'log_project_activity',
                'actm_id'  => ActivityMaster::PROJECT_UPDATED,
                'desc'     => '{USER} created project {PROJ}',
            ),
            // updated existing project
            array(
                'onupdate' => true,
                'fields'   => array('prj_name', 'prj_display_name', 'prj_desc', 'prj_status', 'prj_type'),
                'action'   => 'log_project_activity',
                'actm_id'  => ActivityMaster::PROJECT_UPDATED,
                'desc'     => '{USER} updated project {PROJ}',
            ),
        ),
        /*
         * PROJECT_ORG LOGGING
         */
        'ProjectOrg' => array(
            // added org to project
            array(
                'oninsert' => true,
                'fields'   => array('porg_org_id'),
                'action'   => 'log_project_activity',
                'actm_id'  => ActivityMaster::PRJORGS_UPDATED,
                'desc'     => '{USER} added {XID} to project {PROJ}',
                'xid'      => array('porg_org_id', 'O'),
            ),
            // updated existing project_org
            array(
                'onupdate' => true,
                'fields'   => array('porg_contact_user_id', 'porg_status'),
                'action'   => 'log_project_activity',
                'actm_id'  => ActivityMaster::PRJORGS_UPDATED,
                'desc'     => '{USER} updated project {PROJ} member {XID}',
                'xid'      => array('porg_org_id', 'O'),
            ),
            // removed project_org
            array(
                'ondelete' => true,
                'fields'   => array(),
                'action'   => 'log_project_activity',
                'actm_id'  => ActivityMaster::PRJORGS_UPDATED,
                'desc'     => '{USER} removed project {PROJ} member {XID}',
                'xid'      => array('porg_org_id', 'O'),
            ),
        ),
        /*
         * SOURCE LOGGING
         */
        'Source' => array(
            // updated existing source
            array(
                'onupdate' => true,
                'fields'   => array('src_username', 'src_first_name', 'src_last_name',
                    'src_middle_initial', 'src_pre_name', 'src_post_name'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} updated source {SRC} profile',
            ),
        ),
        'SrcEmail' => array(
            // changed email
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('sem_email', 'sem_primary_flag', 'sem_context', 'sem_status'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} <OP> source {SRC} email',
            ),
        ),
        'SrcPhoneNumber' => array(
            // changed phone
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('sph_number', 'sph_ext', 'sph_primary_flag',
                    'sph_context', 'sph_country'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} <OP> source {SRC} phone number',
            ),
        ),
        'SrcMailAddress' => array(
            // changed address
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('smadd_primary_flag', 'smadd_context', 'smadd_line_1',
                    'smadd_line_2', 'smadd_city', 'smadd_state', 'smadd_cntry', 'smadd_zip'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} <OP> source {SRC} mail address',
            ),
        ),
        'SrcFact' => array(
            // changed fact
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('sf_fv_id', 'sf_src_value', 'sf_src_fv_id'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} <OP> source {SRC} <FACT>',
            ),
        ),
        'SrcVita' => array(
            // changed vita (experience or interest)
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('sv_conf_level', 'sv_start_date',
                    'sv_end_date', 'sv_value', 'sv_basis', 'sv_notes'),
                'action'   => 'log_srcinfo_activity',
                'actm_id'  => ActivityMaster::SRCINFO_UPDATED,
                'desc'     => '{USER} <OP> source {SRC} <VITA>',
            ),
        ),
        'SrcOutcome' => array(
            // added or removed outcome
            array(
                'oninsert' => true,
                'ondelete' => true,
                'fields'   => array('out_uuid', 'out_headline', 'out_url',
                    'out_teaser', 'out_dtim'),
                'action'   => 'log_srcout_activity',
                'actm_id'  => ActivityMaster::OUTCOME_OR_ANNOT,
                'desc'     => '{USER} <OP> source {SRC} outcome <OUT>',
            ),
        ),
        /*
         * SRCORG LOGGING
         */
        'SrcOrg' => array(
            // changed src_org (optin/optout/deactivate)
            array(
                'oninsert' => true,
                'onupdate' => true,
                'ondelete' => true,
                'fields'   => array('so_status'),
                'action'   => 'log_srcorg_activity',
                'desc'     => '{USER} <OPT> source {SRC} <OPT2> {XID}',
                'xid'      => array('so_org_id', 'O'),
            ),
        ),

    );


    /**
     * Log something in AIR2, as determined by our $CONFIG.
     *
     * @param AIR2_Record $record
     * @param string  $op     (optional) operation to perform (update/insert/delete)
     */
    public static function log($record, $op='update') {
        // return now if logging is NOT enabled
        if (!self::$ENABLE_LOGGING) return;

        // sanity checks
        $user_id = self::_get_remote_user($record);
        $op = self::_get_operation($op);

        // check for loggable changes
        foreach (self::$CONFIG as $class => $log_defs) {
            // check class type
            if (!is_a($record, $class)) continue;

            // look through each logging def
            foreach ($log_defs as $def) {
                // check operation type
                if (!isset($def[$op])) continue;

                // check the changed fields
                $filter = array_flip($def['fields']);
                $new_vals = array_intersect_key($record->getModified(false), $filter);
                $old_vals = array_intersect_key($record->getModified(true), $filter);

                // make sure something relevant changed
                $always_log = in_array($op, array('oninsert', 'ondelete'));
                if (!$always_log && count($new_vals) == 0) continue;

                // call the action method
                $params = array(
                    'def' => $def,
                    'old' => $old_vals,
                    'new' => $new_vals,
                    'rec' => $record,
                    'user_id' => $user_id,
                    'op'  => $op,
                );
                call_user_func(array('AIR2Logger', $def['action']), $params);
            }
        }
    }


    /**
     * Helper function to calculate remote user ID, either from the global
     * constant, or from the record's upd_user.
     *
     * @param AIR2_Record $rec
     * @return int
     */
    private static function _get_remote_user($rec) {
        $user_id = false;

        // check remote user id constant
        if (defined('AIR2_REMOTE_USER_ID')) {
            return AIR2_REMOTE_USER_ID;
        }

        // check update column
        $upd_col = preg_grep('/_upd_user$/', array_keys($rec->toArray()));
        $upd_col = array_pop($upd_col);
        if ($upd_col && $rec->$upd_col) {
            $user_id = $rec->$upd_col;
        }

        // throw exception if not found
        if (!$user_id) {
            throw new Exception("Unable to get remote user ID!");
        }
        return $user_id;
    }


    /**
     * Helper function to sanity check the type of logging operation.
     *
     * @param string  $op
     * @return string
     */
    private static function _get_operation($op) {
        if (!in_array($op, array('update', 'insert', 'delete'))) {
            throw new Exception("Invalid logging operation '$op'");
        }
        return "on$op";
    }


    /**
     * Log a ProjectActivity on a changed record
     *
     * @param array   $params
     */
    protected static function log_project_activity($params) {
        $def = $params['def'];
        $rec = $params['rec'];

        // log the activity
        $pa = new ProjectActivity();
        $pa->pa_actm_id = $def['actm_id'];
        $pa->pa_dtim = air2_date();
        $pa->pa_desc = $def['desc'];
        $pa->pa_notes = json_encode(
            array(
                'old' => $params['old'],
                'new' => $params['new'],
            )
        );

        // optional xid
        if (isset($def['xid'])) {
            $pa->pa_xid = $rec->$def['xid'][0];
            $pa->pa_ref_type = $def['xid'][1];
        }

        // get the actual project and add an activity
        $project = ($rec->hasRelation('Project')) ? $rec->Project : $rec;
        if ($project->exists()) {
            $pa->pa_prj_id = $project->prj_id;
            $pa->save();
        }
        else {
            $project->ProjectActivity[] = $pa; //saving will happen later
        }
    }


    /**
     * Log a SrcActivity for changed source info
     *
     * @param array   $params
     */
    protected static function log_srcinfo_activity($params) {
        $def = $params['def'];
        $rec = $params['rec'];

        // put operation into description
        $str_op = 'updated';
        if ($params['op'] == 'oninsert') $str_op = 'added';
        if ($params['op'] == 'ondelete') $str_op = 'removed';
        $desc = preg_replace('/<OP>/', $str_op, $def['desc']);

        // add facts to description
        if (preg_match('/<FACT>/', $desc)) {
            $str_fact = $rec->Fact->fact_name;
            $desc = preg_replace('/<FACT>/', $str_fact, $desc);
        }

        // add vita type (interest/experience) to description
        if (preg_match('/<VITA>/', $desc)) {
            $str_vita = $rec->sv_type == 'E' ? 'Experience' : 'Interest';
            $desc = preg_replace('/<VITA>/', $str_vita, $desc);
        }

        // log the activity
        $sact = new SrcActivity();
        $sact->sact_actm_id = $def['actm_id'];
        $sact->sact_prj_id = null; //no project
        $sact->sact_dtim = air2_date();
        $sact->sact_desc = $desc;
        $sact->sact_notes = json_encode(
            array(
                'old' => $params['old'],
                'new' => $params['new'],
            )
        );

        // get the actual source and add an activity
        $source = ($rec->hasRelation('Source')) ? $rec->Source : $rec;
        if ($source->exists()) {
            $sact->sact_src_id = $source->src_id;
            $sact->save();
        }
        else {
            $source->SrcActivity[] = $sact; //saving will happen later
        }
    }


    /**
     * Log a SrcActivity for SrcOrg opt-in, opt-out, and deactivate
     *
     * @param array   $params
     */
    protected static function log_srcorg_activity($params) {
        $def = $params['def'];
        $rec = $params['rec'];

        // find which type of "opt" this is
        $opt;
        $opt2;
        $actm_id;
        switch ($rec->so_status) {
        case SrcOrg::$STATUS_OPTED_IN:
            $opt = 'Opted-in';
            $opt2 = 'to';
            $actm_id = ActivityMaster::SRCINFO_UPDATED;
            break;
        case SrcOrg::$STATUS_OPTED_OUT:
            $opt = 'Opted-out';
            $opt2 = 'of';
            $actm_id = ActivityMaster::SRCINFO_UPDATED;
            break;
        default:
            $opt = 'Deactivated';
            $opt2 = 'from';
            $actm_id = ActivityMaster::SRCINFO_UPDATED;
            break;
        }
        $desc = preg_replace('/<OPT>/', $opt, $def['desc']);
        $desc = preg_replace('/<OPT2>/', $opt2, $desc);

        // log the activity
        $sact = new SrcActivity();
        $sact->sact_actm_id = $actm_id;
        $sact->sact_prj_id = null; //no project
        $sact->sact_dtim = air2_date();
        $sact->sact_desc = $desc;
        $sact->sact_notes = json_encode(
            array(
                'old' => $params['old'],
                'new' => $params['new'],
            )
        );
        $sact->sact_xid = $rec->$def['xid'][0];
        $sact->sact_ref_type = $def['xid'][1];

        // get the actual source and add an activity
        $source = ($rec->hasRelation('Source')) ? $rec->Source : $rec;
        if ($source->exists()) {
            $sact->sact_src_id = $source->src_id;
            $sact->save();
        }
        else {
            $source->SrcActivity[] = $sact; //saving will happen later
        }
    }


    /**
     * Log a SrcActivity for SrcOutcome creation/deletion
     *
     * @param array   $params
     */
    protected static function log_srcout_activity($params) {
        $def = $params['def'];
        $rec = $params['rec'];

        // try really hard to get the outcome data (arrgg! Doctrine!!!)
        $outdata = $rec->Outcome->toArray();
        if (!$outdata || !isset($outdata['out_headline'])) {
            $rec->clearRelated();
            $outdata = $rec->Outcome->toArray();
        }
        if (!$outdata || !isset($outdata['out_headline'])) {
            $rec->Outcome->refresh();
            $outdata = $rec->Outcome->toArray();
        }
        $hdl = isset($outdata['out_headline']) ? $outdata['out_headline'] : '';
        $hdl = $hdl ? "\"$hdl\"" : '';

        // put operation/outcome-text into description
        $str_op = 'inserted';
        if ($params['op'] == 'oninsert') $str_op = 'added';
        if ($params['op'] == 'ondelete') $str_op = 'removed';
        $desc = preg_replace('/<OP>/', $str_op, $def['desc']);
        $desc = preg_replace('/<OUT>/', $hdl, $desc);
        $filter = array_flip($def['fields']);
        if ($outdata && is_array($outdata)) {
            $outdata = array_intersect_key($outdata, $filter);
        }

        // log the activity
        $sact = new SrcActivity();
        $sact->sact_actm_id = $def['actm_id'];
        $sact->sact_prj_id = null; //no project
        $sact->sact_dtim = air2_date();
        $sact->sact_desc = $desc;
        $sact->sact_notes = json_encode(array('outcome' => $outdata));

        // get the actual source and add an activity
        $source = ($rec->hasRelation('Source')) ? $rec->Source : $rec;
        if ($source->exists()) {
            $sact->sact_src_id = $source->src_id;
            $sact->save();
        }
        else {
            $source->SrcActivity[] = $sact; //saving will happen later
        }
    }


    /**
     * Public utility to log a src_activity without using doctrine.
     *
     * @param int     $usrid
     * @param array   $srcids
     * @param string  $dtim
     * @param string  $desc
     * @param string  $note
     */
    public static function log_raw($usrid, $srcids, $dtim, $desc, $note) {
        // collect default values
        if (!$dtim) $dtim = air2_date();
        if (!$desc) $desc = '';
        if (!$note) $note = '';

        // create generic mapping
        $mapping = array(
            'src_activity' => array(
                'sact_src_id'   => array('map' => 0),
                'sact_actm_id'  => array('val' => 40),
                'sact_dtim'     => array('val' => $dtim),
                'sact_desc'     => array('val' => $desc),
                'sact_notes'    => array('val' => $note),
                'sact_cre_user' => array('val' => $usrid),
                'sact_upd_user' => array('val' => $usrid),
                'sact_cre_dtim' => array('val' => $dtim),
                'sact_upd_dtim' => array('val' => $dtim),
            ),
        );

        // import data (FAST if there are alot of rows)
        $rdr = new ArrayReader($srcids);
        $conn = AIR2_DBManager::get_master_connection();
        if (count($srcids) < 10) {
            $wrt = new SqlWriter($conn, $mapping);
            $wrt->write_data($rdr);
        }
        else {
            $wrt = new MySqlImporter('/tmp', $mapping, $conn);
            $wrt->write_data($rdr);
            $wrt->exec_load_infile();
        }

        // check for errors
        $errs = $wrt->get_errors();
        if (count($errs) > 0) {
            $str = implode(', ', $errs);
            throw new Exception("Errors on activity logging: $str");
        }
    }


}
