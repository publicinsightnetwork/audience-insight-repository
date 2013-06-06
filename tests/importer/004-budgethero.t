#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use Text::CSV_XS;
use AIR2::User;
use AIR2::Config;
use AIR2::CSVReader;
use AIR2::Importer::BudgetHero;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::Inquiry;
use AIR2Test::Organization;
use AIR2Test::User;
use Data::Dump qw( dump );
use Test::More tests => 51;

# db handle
my $dbh = AIR2::DBManager->new_or_cached()->get_write_handle()->retain_dbh;

# open test csv file
# my $filename = "$FindBin::Bin/budgethero/budget_hero_export.csv";
my $filename
    = "$FindBin::Bin/budgethero/pij_export_budget_hero_v4_20110101.csv";
my $fileopts = "<:encoding(utf8)";
open my $fh, $fileopts, $filename or die "budget_hero_export.csv: $!";

# convert file to string for testing
my $str = '';
open my $tmp, $fileopts, $filename or die "budget_hero_export.csv: $!";
while (<$tmp>) {
    $str .= $_;
}
close $tmp;

# other test data
my $usr = AIR2::User->new( user_id => 1 )->load;
my $fnm = "test_004-budgethero.csv";
my $dtm = "20110101";

# cleanup previous tests
my $n = $dbh->do("delete from tank where tank_notes = '$fnm'");
if ( $n > 0 ) {
    diag("Cleaned up $n existing budgethero tests");
}

# create reader and importer
my $rdr      = AIR2::CSVReader->new($str);
my $importer = AIR2::Importer::BudgetHero->new(
    reader     => $rdr,
    user       => $usr,
    debug      => 1,
    max_errors => 1,

    #dry_run      => 1,
    csv_filename => $fnm,
    csv_filedate => $dtm,
);

#####################################
## TankSource helpers
#####################################
sub get_tank_sources {
    my $tsrcs = AIR2::TankSource->fetch_all(
        query => [
            sem_email => [
                qw(
                    test01@004budgethero.org
                    test02@004budgethero.org
                    test03@004budgethero.org
                    test04@004budgethero.org
                    test05@004budgethero.org
                    test06@004budgethero.org
                    )
            ],
        ],
        order => 'tsrc_id asc',
    );
    return $tsrcs;
}

sub cleanup_tank_sources {
    my $cleanup_tsrcs = get_tank_sources();
    for my $tsrc ( @{$cleanup_tsrcs} ) {
        $tsrc->delete();
    }
}
cleanup_tank_sources();

#####################################
## Lookup the shared tanks
#####################################
my $tank_apm = AIR2::Tank->new(
    tank_uuid    => '8d0379d4ca4a',
    tank_name    => 'apm_bh',
    tank_user_id => 1
)->load_or_save;
my $tank_mkp = AIR2::Tank->new(
    tank_uuid    => 'ba67db80b759',
    tank_name    => 'mkp_bh',
    tank_user_id => 1
)->load_or_save;
my $tank_opb = AIR2::Tank->new(
    tank_uuid    => '36cb92be1b8a',
    tank_name    => 'opb_bh',
    tank_user_id => 1
)->load_or_save;

my $start_count_apm = $tank_apm->sources_count;
my $start_count_mkp = $tank_mkp->sources_count;
my $start_count_opb = $tank_opb->sources_count;

#####################################
## Test tanks
#####################################
ok( $importer->run(), "importer->run()" );
is( $importer->completed, 7, "7 completed" );
is( $importer->errored,   0, "0 errored" );
is( $importer->skipped,   1, "1 skipped" );

# tank_apm
is( $tank_apm->sources_count, $start_count_apm + 5, 'tank_apm - +5 sources' );
is( $tank_apm->orgs_count, 2, 'tank_apm - 2 orgs' );
is( $tank_apm->activities_count, 1, 'tank_apm - 1 activity' );

my $to      = $tank_apm->orgs->[0];
my $def_prj = $to->organization->org_default_prj_id;
is( lc $to->organization->org_name, 'apmpin', 'tank_apm - APM org' );
my $ta = $tank_apm->activities->[0];
is( $ta->tact_prj_id, $def_prj, 'tank_apm - tact_prj_id' );
$to = $tank_apm->orgs->[1];
is( lc $to->organization->org_name, 'global', 'tank_apm - global-PIN org' );

# tank_mkp
is( $tank_mkp->sources_count, $start_count_mkp + 1, 'tank_mkp - +1 sources' );
is( $tank_mkp->orgs_count, 2, 'tank_mkp - 2 orgs' );
is( $tank_mkp->activities_count, 1, 'tank_mkp - 1 activity' );

$to      = $tank_mkp->orgs->[0];
$def_prj = $to->organization->org_default_prj_id;
is( lc $to->organization->org_name, 'marketplace', 'tank_mkp - APM org' );
$ta = $tank_mkp->activities->[0];
is( $ta->tact_prj_id, $def_prj, 'tank_mkp - tact_prj_id' );
$to = $tank_mkp->orgs->[1];
is( lc $to->organization->org_name, 'global', 'tank_mkp - global-PIN org' );

# tank_opb
is( $tank_opb->sources_count, $start_count_opb + 1, 'tank_opb - +1 sources' );
is( $tank_opb->orgs_count, 2, 'tank_opb - 2 orgs' );
is( $tank_opb->activities_count, 1, 'tank_opb - 1 activity' );

$to      = $tank_opb->orgs->[0];
$def_prj = $to->organization->org_default_prj_id;
is( lc $to->organization->org_name, 'opb', 'tank_opb - APM org' );
$ta = $tank_opb->activities->[0];
is( $ta->tact_prj_id, $def_prj, 'tank_opb - tact_prj_id' );
$to = $tank_opb->orgs->[1];
is( lc $to->organization->org_name, 'global', 'tank_opb - global-PIN org' );

#####################################
## Test tank_sources
#####################################
my $tsrcs = get_tank_sources();
is( scalar @{$tsrcs}, 7, 'created 7 tank_sources' );

is( $tsrcs->[0]->tsrc_tank_id,   $tank_opb->tank_id, 'line 1 - tank opb' );
is( $tsrcs->[0]->src_first_name, 'First1',           'line 1 - first' );
is( $tsrcs->[0]->src_last_name,  'Last1',            'line 1 - last' );
is( $tsrcs->[0]->sem_email, 'test01@004budgethero.org', 'line 1 - email' );
is( $tsrcs->[0]->facts->[0]->sf_src_value, 'Male', 'line 1 - gender fact' );
is( $tsrcs->[0]->facts->[1]->sf_src_value,
    '1940', 'line 1 - birth year fact' );
is( $tsrcs->[0]->facts->[2]->sf_src_value, undef, 'line 1 - politic fact' );
is( $tsrcs->[0]->facts->[2]->sf_src_fv_id, 20, 'line 1 - politic fact map' );
is( $tsrcs->[0]->facts->[3]->sf_src_value, undef, 'line 1 - income fact' );
is( $tsrcs->[0]->facts->[3]->sf_src_fv_id, 9, 'line 1 - income fact map' );
is( $tsrcs->[0]->response_sets_count,      1, 'line 1 - 1 response set' );
is( $tsrcs->[0]->responses_count,          1, 'line 1 - 1 response' );
ok( length $tsrcs->[0]->responses->[0]->sr_orig_value > 10,
    'line 1 - sr length' );

is( $tsrcs->[1]->tsrc_tank_id, $tank_apm->tank_id, 'line 2 - tank apm' );
is( $tsrcs->[1]->sem_email, 'test02@004budgethero.org', 'line 2 - email' );
is( $tsrcs->[1]->facts->[3]->sf_src_value,
    'White', 'line 2 - ethnicity fact' );

is( $tsrcs->[2]->tsrc_tank_id, $tank_mkp->tank_id, 'line 4 - tank mkp' );
is( $tsrcs->[2]->sem_email, 'test04@004budgethero.org', 'line 4 - email' );

is( $tsrcs->[3]->tsrc_tank_id, $tank_apm->tank_id, 'line 5 - tank apm' );
is( $tsrcs->[3]->sem_email, 'test05@004budgethero.org', 'line 5 - email' );

is( $tsrcs->[4]->tsrc_tank_id, $tank_apm->tank_id, 'line 6 - tank apm' );
is( $tsrcs->[4]->sem_email, 'test06@004budgethero.org', 'line 6 - email' );

# last 2 should NOT include conflicting first/last names
is( $tsrcs->[5]->tsrc_tank_id, $tank_apm->tank_id, 'line 7 - tank apm' );
is( $tsrcs->[5]->src_first_name, undef, 'line 7 - no first name' );
is( $tsrcs->[5]->src_last_name,  undef, 'line 7 - no last name' );

is( $tsrcs->[6]->tsrc_tank_id, $tank_apm->tank_id, 'line 8 - tank apm' );
is( $tsrcs->[6]->src_first_name, undef, 'line 8 - no first name' );
is( $tsrcs->[6]->src_last_name,  undef, 'line 8 - no last name' );

#####################################
## Cleanup
#####################################
cleanup_tank_sources();
