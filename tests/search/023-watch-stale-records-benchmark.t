#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use lib 'tests/search';
use AIR2TestUtils;
use Data::Dump qw( dump );
use AIR2::Source;
use Unix::PID::Tiny;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 1;
    }

    # make sure our watcher is running
    my $unix_pid = Unix::PID::Tiny->new;
    my $watcher_pid_file
        = AIR2::Config->get_app_root->file('var/watch-stale-records.pid');
    if ( !-s $watcher_pid_file ) {
        skip "The watch-stale-records script is not running", 1;
    }
    my $watcher_pid = $watcher_pid_file->slurp;
    if ( !$watcher_pid or !$unix_pid->is_pid_running($watcher_pid) ) {
        skip "The watch-stale-records script is not running", 1;
    }

    # mark 20 sources as stale so we can compare before and after parallel performance.
    # this is not really a test, just a way to measure difference.
    
    ok( my $sources = AIR2::Source->fetch_all( limit => 20 ), "fetch 20 sources");
    for my $s (@$sources) {
        AIR2::SearchUtils::touch_stale($s);
    }

}
