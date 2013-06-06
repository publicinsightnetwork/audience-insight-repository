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
use Carp;
use AIR2::User;
use AIR2::Config;

my $users = AIR2::User->fetch_all_iterator( sort_by => 'user_username' );

while ( my $user = $users->next ) {
    printf( "%s:\n", $user->user_username );
    for my $uo ( @{ $user->user_orgs } ) {
        printf( "  %s %s %s\n",
            $uo->organization->org_name,
            $uo->adminrole->ar_name,
            ( $uo->uo_home_flag ? "**HOME**" : "" ) );
    }
}

