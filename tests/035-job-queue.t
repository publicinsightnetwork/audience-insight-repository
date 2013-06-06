#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use Test::More tests => 13;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Config;
use AIR2::JobQueue;

SKIP: {

    if ( !$ENV{AIR2_TEST_JOB_QUEUE} ) {
        skip "set AIR2_TEST_JOB_QUEUE to test job_queue features", 13;
    }

    my $tmp_file = "/tmp/air2-job-queue-test";

    # setup
    if ( -e $tmp_file ) {
        diag("Removing old temp file $tmp_file");
        unlink($tmp_file) or die "can't unlink $tmp_file: $!";
    }

    # TODO this whole series could fail if we are using a live db
    my $old = AIR2::JobQueue->get_locked();
    if (@$old) {
        for my $job (@$old) {
            diag( "Deleting (old) locked job " . $job->jq_id );
            $job->delete();
        }
    }

    # create dummy job
    my $job = AIR2::JobQueue->new( 'jq_job' => "touch $tmp_file" );
    $job->save();

    # TODO this whole series could fail if we are using a live db
    my $locked = AIR2::JobQueue->get_locked();
    ok( !scalar(@$locked), "no locked jobs in queue" );

    ok( my $queued = AIR2::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 1, "one queued job" );
    ok( $queued->[0]->is_locked, "queued job has lock" );

    for my $j (@$queued) {
        if ( !$j->run() ) {
            fail( "Job: " . $j->jq_id );
        }
        else {
            pass( "Job ran: " . $j->jq_pid );
        }
    }

    ok( -e $tmp_file, "$tmp_file exists (job ran successfully)" );

    # cleanup
    unlink($tmp_file);
    $job->delete();

    # start_after
    $job = AIR2::JobQueue->add_job( "touch $tmp_file", time() + 2 );
    $locked = AIR2::JobQueue->get_locked();
    ok( !scalar(@$locked), "no locked jobs in queue" );

    ok( $queued = AIR2::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 0, "zero queued jobs" );

    diag("sleeping 3 seconds to let start_after_dtim elapse");
    sleep(3);

    ok( $queued = AIR2::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 1, "zero queued jobs" );

    for my $j (@$queued) {
        if ( !$j->run() ) {
            fail( "Job: " . $j->jq_id );
        }
        else {
            pass( "Job ran: " . $j->jq_pid );
        }
    }

    ok( -e $tmp_file, "$tmp_file exists (job ran successfully)" );

    # cleanup
    unlink($tmp_file);
    $job->delete();
}
