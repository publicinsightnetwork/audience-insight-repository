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
 * Job queue
 *
 * Register background asynchronous background jobs for execution.
 *
 * @property integer   $jq_id
 * @property string    $jq_job
 * @property integer   $jq_pid
 * @property string    $jq_host
 * @property string    $jq_error_msg
 * @property timestamp $jq_start_dtim
 * @property timestamp $jq_complete_dtim
 * @property integer   $jq_cre_user
 * @property timestamp $jq_cre_dtim
 * @package default
 */
class JobQueue extends AIR2_Record {

    public static $TYPE_EMAIL = 'E';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('job_queue');
        $this->hasColumn('jq_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('jq_job', 'string', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('jq_pid', 'integer', 4, array(
            )
        );
        $this->hasColumn('jq_host', 'string', 255, array(
            )
        );
        $this->hasColumn('jq_error_msg', 'string', null, array(
            )
        );
        $this->hasColumn('jq_type', 'string', 1, array());
        $this->hasColumn('jq_xid', 'integer', 4, array());
        $this->hasColumn('jq_cre_user', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('jq_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('jq_start_dtim', 'timestamp', null, array(
            )
        );
        $this->hasColumn('jq_start_after_dtim', 'timestamp', null, array(
            )
        );
        $this->hasColumn('jq_complete_dtim', 'timestamp', null, array(
            )
        );

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
    }


    /**
     * Run this job
     *
     * @return unknown
     */
    public function run() {
        $cmd = $this->jq_job;
        if (!isset($cmd) || !strlen($cmd)) {
            throw new Exception("jq_job is empty for jq_id " . $this->jq_id);
        }
        if ($this->jq_start_dtim || $this->jq_pid) {
            throw new Exception('Job already run');
        }

        // write our pid and hostname
        $this->jq_pid = getmypid();
        $this->jq_host = php_uname('n');
        $this->jq_start_dtim = air2_date();
        $this->save();

        // replace vars
        $php = PHP_BINDIR.'/php';
        $perl = '/usr/bin/env perl';
        $root = realpath(APPPATH.'../');

        // simple interpolation
        $cmd = preg_replace('/PHP /', "$php ", $cmd);
        $cmd = preg_replace('/PERL /', "$perl ", $cmd);
        $cmd = preg_replace('/AIR2_ROOT/', $root, $cmd);

        // redirect STDERR to STDOUT (so it's captured correctly)
        $cmd .= " 2>&1";

        // exec the cmd, saving the completion time
        exec($cmd, $output, $ret);
        $this->jq_complete_dtim = air2_date();

        if ($ret != 0) {
            // truncate long output
            $output = implode("\n", $output);
            if (($len = strlen($output)) > 65535) {
                $output = substr($output, $len-65535);
            }
            $this->jq_error_msg = $output;
        }

        // save and return success
        $this->save();
        return $ret == 0;
    }


    /**
     *
     *
     * @return unknown
     */
    public function lock() {
        $this->jq_start_dtim = date(AIR2_DTIM_FORMAT);
        $this->save();
    }


    /**
     * All JobQueue objects in $job_list will be locked.
     *
     * @return array $job_list
     */
    public static function get_queued() {
        Carper::croak("rewrite get_queue to use AIR2_Query dql");
        $proto = new JobQueue();
        $where = "(jq_start_dtim is null or jq_pid = -1) and (jq_start_after_dtim is null or jq_start_dtim <= NOW())";
        $jobs = $proto->fetchAll( "where $where order by jq_cre_dtim ASC" );

        // get lock on all these jobs.
        $job_list = array();
        while ( $job = $jobs->next() ) {

            $job->lock();
            $job_list[] = $job;

        }
        return $job_list;
    }


    /**
     *
     *
     * @return array $locked
     */
    public static function get_locked() {
        Carper::croak("rewrite get_locked to use AIR2_Query dql");
        $proto = new JobQueue();
        $jobs = $proto->fetchAll(
            "where jq_start_dtim is not null and jq_complete_dtim is null"
        );
        $locked = array();
        while ( $job = $jobs->next() ) {
            $locked[] = $job;
        }
        return $locked;
    }



    /**
     *
     *
     * @return unknown
     */
    public function is_locked() {
        if ( isset($this->jq_start_dtim) && !isset($this->jq_complete_dtim)) {
            return true;
        }
        return false;
    }


}
