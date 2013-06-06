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
use Test::More tests => 6;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::User;
use JSON;
use URI::Query;
use Plack::Test;

my $stxml   = Search::Tools::XML->new;
my $debug   = $ENV{PERL_DEBUG} || 0;
my $TMP_DIR = Path::Class::dir('/tmp/air2-test/search');
$AIR2::Config::SEARCH_ROOT = $TMP_DIR;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

$TMP_DIR->mkpath($debug);
my $xml_dir = $TMP_DIR->subdir('xml/sources');
$xml_dir->mkpath($debug);
my $index_dir = $TMP_DIR->subdir('index/sources');
$index_dir->mkpath($debug);

##################################################################################
## set up test data
##################################################################################

# some src_uuid values we know about
my @uuids = qw(
    5813ca01e545

);

# create tmp xml and index from the uuids
my @sources;
for my $src_uuid (@uuids) {
    my $src = AIR2::Source->new( src_uuid => $src_uuid )->load;

    for my $srs ( @{ $src->response_sets } ) {
        my $resp_xml = $srs->as_xml(
            {   debug    => $debug,
                base_dir => $TMP_DIR->subdir('xml/responses')
            }
        );
        AIR2::SearchUtils::write_xml_file(
            pk     => $srs->srs_id,
            base   => $TMP_DIR->subdir('xml/responses'),
            xml    => $resp_xml,
            pretty => 0,
        );
    }

    my $xml = $src->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    );

    #diag($stxml->tidy($xml));

    # write XML to disk
    AIR2::SearchUtils::write_xml_file(
        pk     => $src->src_id,
        base   => $xml_dir,
        xml    => $xml,
        pretty => 0,
        debug  => $debug,
    );

    # cache for later
    push @sources, $src;
}

$debug and diag(`tree $TMP_DIR`);

# create index
is( AIR2TestUtils::create_index(
        invindex => $index_dir,
        config =>
            AIR2::Config->get_app_root->file('etc/search/sources.config'),
        input => $xml_dir,
        debug => $debug,
    ),
    scalar(@uuids),
    "create tmp source index"
);

##########################################################################################
## authz tests
##########################################################################################

ok( my $at = AIR2TestUtils->new_auth_tkt(), "get auth tkt object" );

# defer loading this till after test is compiled so that TMP_DIR is
# correctly recognized by AI2::Config and all the Search::Server classes.
require AIR2::Search::MasterServer;

# test access to source1
my $src1_authz = $sources[0]->get_authz();

#diag( dump($src1_authz) );
my $authz = encode_json(
    {   authz =>
            AIR2::SearchUtils::pack_authz( { map { $_ => 1 } @$src1_authz } )
    }
);
my $tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $authz
);

# only create a sources index for this test, so skip the others.
my $skip_routes = {
    projects                => 1,
    inquiries               => 1,
    responses               => 1,
    sources                 => 1,
    'active-sources'        => 1,
    'primary-sources'       => 1,
    'fuzzy-sources'         => 1,
    'fuzzy-active-sources'  => 1,
    'fuzzy-primary-sources' => 1,
    'fuzzy-responses'       => 1,
    'strict-responses'      => 1,
    'public-responses'      => 1,
};

# SHHHHHHHHHH!
#$ENV{AIR2_QUIET} = 1;

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $query    = URI::Query->new(
            {   q        => 'inq_uuid=28932b1e24eb',
                air2_tkt => $tkt,
            }
        );
        my $req
            = HTTP::Request->new( GET => "/strict-sources/search?" . $query );
        my $resp = $callback->($req);

        #dump($resp);

        ok( my $json = decode_json( $resp->content ),
            "json decode body of response" );

        #dump($json);

        is( $json->{unauthz_total}, 1, "tkt has unauthz hits" );
        is( $json->{total},         1, "tkt has authz to 1 hit" );
        ok( !exists $json->{results}->[0]->{qa}, "zero qa sets" );

    },
);

END {

    # clean up unless debug is on
    if ( !$debug ) {
        $TMP_DIR->rmtree;
    }
}
