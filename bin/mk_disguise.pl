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

=pod

=head1 NAME

mk_disguise.pl - anonymize AIR data for demo purposes

=head1 SYNOPSIS

 mk_disguise.pl

=head1 DESCRIPTION

mk_disguise.pl executes SQL that anonymizes AIR2 data, removing
names, phone numbers, addresses and any other identifying Source
profile information.

Obviously this is a development tool only, and should never, ever 
be run against the live production database. To ensure that,
the AIR2_DOMAIN environment variable is checked and this tool
will die if it is set to "prod".

=cut

if ( $ENV{AIR2_DOMAIN} && $ENV{AIR2_DOMAIN} eq 'prod' ) {
    die "Cannot be run on production database";
}

use strict;
use warnings;
use lib 'lib/perl';
use AIR2::DBManager;
use AIR2::Utils;

my $dbh = AIR2::DBManager->new()->get_write_handle->retain_dbh;

my $sql = <<EOF;
update source set 
    src_first_name='First',
    src_last_name='Last',
    src_username=CONCAT(src_uuid, '\@nosuchemail.org')
EOF

update($sql);

$sql = <<EOF;
update src_phone_number set
    sph_number='000.123.4567'
EOF

update($sql);

$sql = <<EOF;
update src_email set
    sem_email=CONCAT(sem_uuid, '\@nosuchemail.org')
EOF

update($sql);

$sql = <<EOF;
update src_mail_address set
    smadd_line_1='1234 Main St',
    smadd_line_2=''
EOF

update($sql);

sub update {
    my $sql = shift;
    print "$sql\n";
    my $rows = $dbh->do("$sql;");
    if ( !$rows ) {
        die "No rows updated for $sql";
    }
    print "$rows affected\n";
}
