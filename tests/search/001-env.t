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
use Test::More tests => 9;
use lib 'tests/search';
use AIR2TestUtils;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 9; 
    }
    my $idx_dir = AIR2::Config->get_search_index();
    my $xml_dir = AIR2::Config->get_search_xml();
    if ( !-d $idx_dir ) {
        skip "Index dir $idx_dir is not a directory on this system", 9;
    }

    use_ok('AIR2::Search::Server');
    use_ok('AIR2::Search::Server::Sources');
    use_ok('AIR2::Search::Server::ActiveSources');
    use_ok('AIR2::Search::Server::PrimarySources');
    use_ok('AIR2::Search::Server::Inquiries');
    use_ok('AIR2::Search::Server::Projects');
    use_ok('AIR2::Search::Server::Responses');

    ok( -d $xml_dir->subdir('sources'), "xml/sources dir exists" );
    ok( -d $idx_dir->subdir('sources'), "index/sources dir exists" );

}
