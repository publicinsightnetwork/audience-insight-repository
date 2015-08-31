#!/bin/bash
#
# daily jobs, run sequentially with no dependence on exit status
# of each other
#
# NOTE that AIR2_ROOT env var must be set before calling this script.
#

# verbose output
set -x

PERL=/opt/pin/local/bin/perl
SHARED=/opt/pin/shared/prod

if [ -z "$AIR2_ROOT" ]; then
    echo "AIR2_ROOT not set";
    exit 2;
fi

MYENV=`cat $AIR2_ROOT/etc/my_profile`

if [ $MYENV == "prod" ]; then
    IS_PRODUCTION=1
fi

$PERL $AIR2_ROOT/bin/opt-into-apmg
$PERL $AIR2_ROOT/bin/mk_src_org_cache.pl
$PERL $AIR2_ROOT/bin/fact-sanity
$PERL $AIR2_ROOT/bin/geo-fillin-gaps
$PERL $AIR2_ROOT/bin/clean-up-stale-imports 90
$PERL $AIR2_ROOT/bin/set-src-stat
$PERL $AIR2_ROOT/bin/check-user-orgs.pl
#$PERL $AIR2_ROOT/bin/clean-up-empty-srs --debug

# zap old reports
find $AIR2_ROOT/assets/downloads -type f -mtime +5 -exec rm {} \;

# send dezi-stats-report
if [ $IS_PRODUCTION ]; then
    $PERL $AIR2_ROOT/bin/check-file-upload-perms.pl '' apache
    $PERL $AIR2_ROOT/bin/make-timeline-tsv $SHARED/downloadable/secure/stats/air-sources.tsv $SHARED/downloadable/secure/stats/air-source-growth.tsv
fi

