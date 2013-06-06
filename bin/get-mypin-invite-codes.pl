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
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Source;
use MIME::Base64;

my $sources = AIR2::Source->fetch_all_iterator(
    query => [ src_status => [qw/ A E /] ] );

while ( my $s = $sources->next ) {
    my $email = $s->get_primary_email;
    if ( !$email ) {
        warn "No email for " . $s->src_username . "\n";
        next;
    }
    printf( "%s,%s", $email->sem_email, encode_base64( $s->src_uuid ) );
}
