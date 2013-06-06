#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use Test::More tests => 43;

use AIR2::Bin;
use AIR2::SrcEmail;
use AIR2Test::Source;
use AIR2Test::User;
use AIR2::SrcOrgCache;

my $EMAIL_NOTIFY = $ENV{LYRIS_NOTIFY} || $ENV{USER} . '@mpr.org';
my $DEBUG        = $ENV{LYRIS_DEBUG}  || 0;

# temp package to clean up bins when we end the script
{

    package MyBin;
    @MyBin::ISA = ('AIR2::Bin');

    sub DESTROY {
        my $self = shift;

        #warn "cleaning up $self id==" . $self->bin_id;
        $self->delete();
    }

}

use_ok('AIR2::Exporter::Lyris');

# make a bin with 100 random sources in it
ok( my $gmails = AIR2::SrcEmail->fetch_all_iterator(
        query => [
            sem_email           => { like => '%gmail.com' },
            sem_primary_flag    => 1,
            'source.src_status' => { ne   => 'G' },
        ],
        limit        => 100,
        with_objects => ['source'],
    ),
    "get gmail SrcEmail records"
);

my @items;
my %src;
my %gmail;
while ( my $sem = $gmails->next ) {
    $gmail{ $sem->sem_email }++;
    next if $src{ $sem->sem_src_id }++;
    push @items, { bsrc_src_id => $sem->sem_src_id };
}

ok( my $bin = MyBin->new(
        bin_name    => 'test-lyris-bucket',
        bin_user_id => 1,                     # admin
    ),
    "test Bin"
);
$bin->load_or_save();    # in case we aborted on previous run

ok( $bin->sources( \@items ), "add items to bin" );
ok( $bin->save(),           "save bin" );

ok( my $apmg_org = AIR2::Organization->new( org_name => 'apmpin' )->load(),
    "get APMG Org" );

# get the Reader iterator for the bin
# NOTE we must call this again to reset the iterator when we create the Exporter.
ok( my $emails = $bin->get_exportable_emails($apmg_org),
    "get exportable emails" );

#
my $count = 0;
my %uniq;
while ( my $e = $emails->next ) {

    #diag( dump($e) );
    $uniq{ $e->{sem_email} }++;
    $count++;
}
#diag("count=$count");
#diag( "items=" . scalar(@items) );
#diag( "uniq =" . scalar( keys %uniq ) );
is( scalar(@items), scalar( keys %uniq ), "items == unique emails" );

for my $g ( keys %gmail ) {
    if ( !exists $uniq{$g} ) {
        diag("missing $g in uniq");
    }
}

# NOTE: this is actually the apm-child-project NOT apmg/apmpin
ok( my $apmg_prj
        = AIR2::Project->new( prj_name => 'apm' )->load,
    "load apmg project"
);
ok( my $inq = $apmg_prj->find_inquiries( limit => 1 )->[0],
    "find one inquiry" );

ok( my $exporter = AIR2::Exporter::Lyris->new(
        dry_run => 1,  # do not actually export to Lyris, just generate report
        reader => $bin->get_exportable_emails($apmg_org),
        name   => $bin->bin_name,
        strict => 1,           # enforce the 24-hour rule
        org    => $apmg_org,
        user         => AIR2::User->new( user_id => 1 )->load(),
        project      => $apmg_prj,
        inquiry      => $inq,
        email_notify => $EMAIL_NOTIFY,
        debug        => $DEBUG,
    ),
    "new Lyris exporter"
);

# must test for defined here since we cannot know if/how many would be counted.
ok( defined $exporter->run(), "run()" );
is( $exporter->errored + $exporter->skipped + $exporter->completed,
    scalar(@items), "counts match" );
#diag( $exporter->report );

##################################
## live tests

# set up some temp sources
# some of these usernames already exist in Lyris from AIR1 tests so we get
# to re-use them
my @sources;
my @usernames = qw(
    tempuser_1@fake-email-domain.org
    tempuser_2@fake-email-domain.org
    tempuser_3@nosuchemail.org
    tempuser_4@fake-email-domain.org
    tempuser_5@fake-email-domain.org
);

for my $u (@usernames) {
    my $src = AIR2Test::Source->new( src_username => $u );
    $src->load_or_save();
    push @sources, $src;
}

my $apmg_user = AIR2Test::User->new(
    user_username   => 'i-love-apm',
    user_first_name => 'i',
    user_last_name  => 'apm',
)->load_or_save();
$apmg_user->add_user_orgs(
    [   {   uo_org_id => $apmg_org->org_id,
            uo_ar_id  => 1,
        }
    ]
);
$apmg_user->save();

@items = ();
for my $src (@sources) {
    $src->add_emails( [ { sem_email => $src->src_username } ] );
    unless ( $src->src_username eq 'tempuser_4@fake-email-domain.org' ) {
        $src->add_organizations( [$apmg_org] );
    }
    else {
        $src->add_organizations(
            [ AIR2::Organization->new( org_name => 'NHPR' )->load() ] );
    }
    $src->save();
    AIR2::SrcOrgCache::refresh_cache($src);
    unless ( $src->src_username eq 'tempuser_5@fake-email-domain.org' ) {
        for my $sem ( @{ $src->emails } ) {
            $sem->add_src_org_emails(
                [   {   soe_org_id      => $apmg_org->org_id,
                        soe_status      => 'A',
                        soe_status_dtim => time(),
                        soe_type        => 'L',
                    }
                ]
            );
            $sem->save();
        }
    }
    push @items, { bsrc_src_id => $src->src_id };
}

# put the sources in a bin
$bin = MyBin->new(
    bin_name    => 'air2-test-lyris-bucket',
    bin_user_id => 1,                          # admin
);
$bin->load_or_save();    # in case we aborted on previous run
$bin->sources( \@items );
$bin->save();

# export the bin
ok( my $live_exporter = AIR2::Exporter::Lyris->new(
        reader => $bin->get_exportable_emails($apmg_org),
        reuse_demographic => 1,    # keep noise down while testing
        name         => $bin->bin_name,
        strict       => 1,                    # enforce the 24-hour rule
        org          => $apmg_org,
        user         => $apmg_user,
        project      => $apmg_prj,
        inquiry      => $inq,
        email_notify => $EMAIL_NOTIFY,
        debug        => $DEBUG,
        dry_run => ( $ENV{LYRIS_DRY_RUN} || 0 ),
        no_export => ( $ENV{LYRIS_NO_EXPORT} || 0 ),
        export_bin_id => $bin->bin_id,
    ),
    "live Lyris exporter"
);

# lyris clean up from previous test just to reduce noise in their db,
# since our tests should succeed regardless.
$live_exporter->lyris->delete_filter( $bin->bin_name );

# clean up just in case
my $name = 'air2-test-lyris-bucket';
my $dbh  = $bin->db->get_write_handle->retain_dbh;
my $num  = $dbh->do("delete from src_export where se_name = '$name'");

#Temporarily suppress warnings
{
    local $SIG{__WARN__}=sub{};
    ok( $live_exporter->run(), "run()" );
}

my $live_errd = $live_exporter->errored;
my $live_skip = $live_exporter->skipped;
my $live_comp = $live_exporter->completed;
my $live_warn = scalar( @{ $live_exporter->warnings } );

# see note below about the -1
is( $live_errd + $live_skip + $live_comp, scalar(@items) - 1, "counts match" );

# note that 'tempuser_4@fake-email-domain.org' is silently skipped
# with no warning in report, due to authz failure. In theory, the User
# does not even know they were in the bucket to begin with.
is( $live_skip, 1, "1 skipped" );
is( $live_comp, 3, "3 exported" );
is( $live_errd, 0, "0 errored" );
is( $live_warn, 2, "2 warnings" );

if ($live_skip != 1 || $live_comp != 3 || $live_errd != 0 || $live_warn != 2) {
    diag( dump $live_exporter->warnings );
    diag( $live_exporter->report );
}

# check logging
# debug with json so that DateTimes are stringified
my %src_exports;
for my $src (@sources) {
    next if $src->src_username =~ m/nosuchemail/;
    next if $src->src_username eq 'tempuser_4@fake-email-domain.org';
    $src->load();
    is( $src->has_related('activities'), 1, "one activity created" );
    is( $src->has_related('inquiries'),  1, "one src_inquiry created" );
    for my $sact ( @{ $src->activities } ) {

        #diag( $sact->column_values_as_json );
        like( $sact->sact_desc, qr/Exported for/, "got sact logged" );
    }
    for my $si ( @{ $src->inquiries } ) {

        #diag( $si->column_values_as_json );
        #diag( $si->src_export->column_values_as_json );
        is( $si->si_sent_by, $live_exporter->filter_name,
            "sent_by==filter_name" );
        is( $si->src_export->se_name, $live_exporter->filter_name,
            "se_name==filter_name" );

        is( $si->si_cre_dtim, $src->last_export_dtim,
            "last_export_dtim==si_cre_dtim" );

        # remember so we can clean up at the end
        $src_exports{ $si->src_export->se_id }++;
    }
}

# check the metadata about the export
my $my_se_id = 0;
for my $se_id ( keys %src_exports ) {
    $my_se_id = $se_id;
    last;
}

if ($my_se_id) {
    my $se = AIR2::SrcExport->new( se_id => $my_se_id )->load;
    is( $se->se_type, 'L', "src_export type 'Lyris'" );
    is( $se->se_xid, $bin->bin_id, "src_export bin_id" );
    is( $se->se_ref_type, 'I', "src_export ref_type 'Bin'" );
    is( $se->get_meta('initial_count'), 4, "src_export initial count" );
    is( $se->get_meta('export_count'), 3, "src_export export count" );
}
else {
    fail( "src_export type 'Lyris'" );
    fail( "src_export bin_id" );
    fail( "src_export ref_type 'Bin'" );
    fail( "src_export initial count" );
    fail( "src_export export count" );
}

# other db clean up is automatic with DESTROY magic
# but must delete src_exports manually since they are linked to project/inquiry
for my $se_id ( keys %src_exports ) {
    AIR2::SrcExport->new( se_id => $se_id )->load->delete();
}

# delete tmp .csv files
system(
    "ssh pij01 rm -f /opt/pij/shared/lyris-exports/air2-test-lyris-bucket.csv"
);
system("rm -f /tmp/lyris-api/air2-test-lyris-bucket.csv");

