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
SHARED=/opt/pin/shared

if [ -z "$AIR2_ROOT" ]; then
    echo "AIR2_ROOT not set";
    exit 2;
fi

MYENV=`cat $AIR2_ROOT/etc/my_profile`

if [ $MYENV == "visi_prod" ]; then
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

# remove temp csv export files after 90 days.
$PERL $AIR2_ROOT/bin/clean-up-lyris-export-csv 90

# remake budghero.ini
$PERL $AIR2_ROOT/bin/mk-budgethero-ini > $AIR2_ROOT/etc/budgethero.ini

# send dezi-stats-report
if [ $IS_PRODUCTION ]; then
    $PERL $AIR2_ROOT/bin/mail-output --to pijdev@mpr.org \
          --subject 'Dezi Stats Report' \
          --attachment dezi-stats-report-`date +'%F'`.csv -- \
          $PERL $AIR2_ROOT/bin/dezi-stats-report

    $PERL $AIR2_ROOT/bin/check-file-upload-perms.pl
    $PERL $AIR2_ROOT/bin/make-timeline-tsv $SHARED/downloadable/secure/stats/air-sources.tsv $SHARED/downloadable/secure/stats/air-source-growth.tsv
fi

