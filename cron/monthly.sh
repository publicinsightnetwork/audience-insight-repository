#!/bin/sh

FROM=`date --date="1 month ago" +'%F'`
TODAY=`date +'%F'`
PERL=/opt/pin/local/bin/perl

if [ -z "$AIR2_ROOT" ]; then
    echo "AIR2_ROOT not set";
    exit 2;
fi

# monthly fact report
$PERL $AIR2_ROOT/bin/mail-output \
    --to 'pij@mpr.org, pijdev@mpr.org' \
    --subject 'PIN Facts' \
    --attachment pin-facts-$TODAY.txt -- \
    $PERL $AIR2_ROOT/bin/fact-stats --end $TODAY

# monthly unmapped translations
$PERL $AIR2_ROOT/bin/mail-output \
    --to 'pij@mpr.org, pijdev@mpr.org' \
    --subject 'PIN Unmapped Values' \
    --attachment pin-unmapped-values-$TODAY.csv -- \
    $PERL $AIR2_ROOT/bin/unmapped-fact.pl --end $TODAY

# monthly "how sources join" report
$PERL $AIR2_ROOT/bin/first-activities \
    --start=$FROM \
    --end=$TODAY \
    --format=email \
    --mailto 'pij@mpr.org, pijdev@mpr.org'

# monthly "query totals" report
$PERL $AIR2_ROOT/bin/mail-output \
    --to 'pij@mpr.org, pijdev@mpr.org' \
    --subject 'PIN Query Totals' \
    --attachment pin-query-totals-$TODAY.txt -- \
    $PERL $AIR2_ROOT/bin/queries-emails-sent --start $FROM --end $TODAY

# monthly email export
$PERL $AIR2_ROOT/bin/mail-output \
    --to 'pij@mpr.org' \
    --subject 'PIN Email Report' \
    --attachment pin-email-report-$TODAY.csv -- \
    $PERL $AIR2_ROOT/bin/email-report --start $FROM --end $TODAY

$PERL $AIR2_ROOT/bin/mail-output \
    --to 'pij@mpr.org, pijdev@mpr.org' \
    --subject 'PIN Newsroom Totals' \
    --attachment pin-newsroom-totals-$TODAY.txt -- \
    $PERL $AIR2_ROOT/bin/newsroom-report

