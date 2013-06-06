#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More tests => 2;
use AIR2::DBManager;
use Data::Dump qw( dump );

ok( my $dbh = AIR2::DBManager->new->get_write_handle->retain_dbh, "new dbh" );
eval {
    $dbh->{PrintError} = 0;
    $dbh->do(
        "insert into source (src_username,src_uuid,src_cre_user,src_cre_dtim)
         values ('"
            . ( 'z' x 300 )
            . "','abcdef123456',1,'2000-01-01 00:00:00')"
    );
};

like( $@, qr/Data too long for column 'src_username'/, "insert too long src_username" );

