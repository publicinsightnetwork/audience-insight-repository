#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 9;
use AIR2::DBManager;
use Data::Dump qw( dump );
use Rose::DB::Object;
use Rose::DB::Object::Metadata;

# "our" to share between packages
our $DB = AIR2::DBManager->new_or_cached();

#############################################
# Inquiry

{

    package DummyInquiry;
    @DummyInquiry::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $inq_meta = Rose::DB::Object::Metadata->new(
        table => 'inquiry',
        class => 'DummyInquiry',
    ),
    "new inq_meta"
);
$inq_meta->auto_initialize();

my %has_column = (
    inq_rss_intro   => 0,
    inq_rss_status  => 0,
    inq_intro_para  => 0,
    inq_ending_para => 0,
    inq_url         => 0,
);

my $inq_rss_flag_cleanup_required = 0;
for my $col ( @{ $inq_meta->columns } ) {

    #diag( $col->name );
    if ( exists $has_column{ $col->name } ) {
        $has_column{ $col->name } = 1;
    }

    if ( $col->name eq 'inq_rss_flag' ) {
        $inq_rss_flag_cleanup_required = 1;
    }
}

for my $col ( keys %has_column ) {
    if ( !$has_column{$col} ) {

        my $sql;
        if ( $col eq 'inq_rss_intro' ) {
            $sql = 'alter table inquiry add column inq_rss_intro text';
        }
        elsif ( $col eq 'inq_rss_status' ) {
            $sql
                = "alter table inquiry add column inq_rss_status char(1) default 'N' not null";
        }
        elsif ( $col eq 'inq_intro_para' ) {
            $sql = "alter table inquiry add column inq_intro_para text";
        }
        elsif ( $col eq 'inq_ending_para' ) {
            $sql = "alter table inquiry add column inq_ending_para text";
        }
        elsif ( $col eq 'inq_url' ) {
            $sql = "alter table inquiry add column inq_url varchar(255)";
        }

        #diag("$col => $sql");
        ok( $DB->dbh->do($sql), "add $col to inquiry" );
    }
    else {
        pass("$col already exists");
    }

}

# clean up inq_rss_flag
if ($inq_rss_flag_cleanup_required) {
    my $sql;
    $sql = "update inquiry set inq_rss_status = 'Y' where inq_rss_flag = 'Y'";
    diag($sql);
    ok( $DB->dbh->do($sql), "update inq_rss_status with inq_rss_flag" );
    $sql = "update inquiry set inq_rss_status = 'N' where inq_rss_flag = 'N'";
    diag($sql);
    ok( $DB->dbh->do($sql), "update inq_rss_status with inq_rss_flag" );
    $sql = "alter table inquiry drop column inq_rss_flag";
    diag($sql);
    ok( $DB->dbh->do($sql), "drop inq_rss_flag" );
}
else {
    pass('inq_rss_status=Y already updated from inq_rss_flag');
    pass('inq_rss_status=N already updated from inq_rss_flag');
    pass('inq_rss_flag already dropped');
}

