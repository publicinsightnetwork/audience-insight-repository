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

#
# check that all users are assigned to at least one org
# and have a home org.
# See Redmine #3718
#

my $users = AIR2::User->fetch_all_iterator(
    query   => [ user_status => 'A', user_type => { ne => 'S' }, ],
    sort_by => 'user_username',
);
while ( my $user = $users->next ) {
    my $uorgs    = $user->user_orgs;
    my $has_home = 0;
    if ( !$uorgs or !@$uorgs ) {
        printf( "User %s has no UserOrgs assigned\n", $user->user_username );
        next;
    }
    for my $uo (@$uorgs) {
        if ( $uo->uo_home_flag ) {
            $has_home = 1;
        }
    }
    if ( !$has_home ) {
        printf( "User %s has no home org assigned\n", $user->user_username );
    }
}
