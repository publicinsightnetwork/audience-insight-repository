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
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use AIR2::Config;
use Data::Dump qw( dump );
use JSON;
use WWW::Mailchimp;

my $API_KEY = AIR2::Config::get_constant('AIR2_MAILCHIMP_KEY');
my $mcapi = WWW::Mailchimp->new( apikey => $API_KEY );

# just make sure we can connect
is( $mcapi->ping, "Everything's Chimpy!", "ping message" );
