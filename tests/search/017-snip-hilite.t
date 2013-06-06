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
use Carp;
use Test::More tests => 20;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2::Search::MasterServer;
use URI::Query;
use Plack::Test;
use JSON;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 20;
    }
    my $idx_dir = AIR2::Config->get_search_index();
    if ( !-d $idx_dir ) {
        skip "Index dir $idx_dir is not a directory on this system", 20;
    }

    my $tkt   = AIR2TestUtils::dummy_tkt();
    my $raw_q = qq/
city=(alberta or aldrich or alpha or arco or avoca or "beaver creek" or
bigelow or birchdale or bock or borup or brimson or brooks or brookston
or bruno or burtrum or calumet or comstock or conger or darfur or
donaldson or dumont or euclid or flensburg or "fort ripley" or freeborn
or georgetown or granada or grandy or "hanley falls" or hardwick or
hayward or hendrum or hines or hitterdal or iona or kent or kerrick or
kilkenny or "lake bronson" or "lake george" or lengby or magnolia or
makinen or mcgrath or millville or mizpah or naytahwaush or "new auburn"
or nielsville or norcross or "north mankato" or ormsby or pemberton or
perley or peterson or ponemah or ponsford or shelly or "squaw lake" or
strathcona or sunburg or taconite or "twin lakes" or vining or waltham
or wanda or wannaska or waskish or watson or wolverton or wright) 
AND 
state=("MN")
/;

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $query    = URI::Query->new(
                {   q        => $raw_q,
                    air2_tkt => $tkt,
                }
            );

            my $count = 0;

            while ( $count++ < 10 ) {
                my $req = HTTP::Request->new(
                    GET => "/sources/search?" . $query );
                my $resp = $callback->($req);

                ok( my $json = decode_json( $resp->content ),
                    "json decode body of response" );

                # 4 secs isn't blazing fast, but the bug was 35+ secs.
                cmp_ok( $json->{build_time}, '<', 4,
                    "build time less than 4 sec" );

                diag( "build_time: " . $json->{build_time} );
                diag( "total: " . $json->{total} );
            }

        },
    );

}
