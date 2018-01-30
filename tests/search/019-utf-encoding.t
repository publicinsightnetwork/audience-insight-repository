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

#
# addressing Trac #9405
#

use strict;
use warnings;
use Test::More tests => 8;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::User;
use Rose::DBx::Object::Indexed::Indexer;
use Search::Tools::XML;
use Search::Tools::UTF8;
use JSON;
use Plack::Test;
use AIR2::Search::MasterServer;
use URI::Query;

my $stxml   = Search::Tools::XML->new;
my $debug   = $ENV{PERL_DEBUG} || 0;
my $TMP_DIR = AIR2::Config::get_tmp_dir->subdir('search');
$AIR2::Config::SEARCH_ROOT = $TMP_DIR;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

$TMP_DIR->mkpath($debug);
my $xml_dir = $TMP_DIR->subdir('xml');
$xml_dir->mkpath($debug);
my $index_dir = $TMP_DIR->subdir('index');
$index_dir->mkpath($debug);

ok( my $inquiry = AIR2::Inquiry->new( inq_uuid => 'e56b187c799c' )->load(),
    "load utf-8 encoded inquiry" );

# make sure we are related to at least one active org
for my $prjinq ( @{ $inquiry->project_inquiries } ) {
    for my $porg ( @{ $prjinq->project->project_orgs } ) {
        $porg->organization->org_status('A');    # DO NOT SAVE
    }
}

ok( my $inqxml = $inquiry->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inqxml"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $inquiry->inq_id,
        base   => $TMP_DIR->subdir('xml/inquiries'),
        xml    => $inqxml,
        pretty => $debug,
        debug  => $debug,
    ),
    "write inqxml file"
);

is( AIR2TestUtils::create_index(
        invindex => $TMP_DIR->subdir('index/inquiries'),
        config =>
            AIR2::Config->get_app_root->file('etc/search/inquiries.config'),
        input => $TMP_DIR->subdir('xml/inquiries'),
        debug => $debug,
    ),
    1,
    "create tmp inquiries index with 1 doc in it"
);

ok( my $at = AIR2TestUtils::new_auth_tkt(), "get auth tkt object" );
my $org_authz = encode_json(
    {   user  => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz(
            { $inquiry->organizations->[0]->org_id => 1 }
        )
    }
);
my $org_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $org_authz
);

########################################################################
# defer loading this till after test is compiled so that TMP_DIR is
# correctly recognized by AI2::Config and all the Search::Servers
require AIR2::Search::MasterServer;

test_psgi(
    app => AIR2::Search::MasterServer->app(
        {   skip => {
                sources                   => 1,
                outcomes                  => 1,
                'active-sources'          => 1,
                'primary-sources'         => 1,
                'strict-sources'          => 1,
                'strict-active-sources'   => 1,
                'strict-primary-sources'  => 1,
                projects                  => 1,
                responses                 => 1,
                'fuzzy-sources'           => 1,
                'fuzzy-active-sources'    => 1,
                'fuzzy-primary-sources'   => 1,
                'fuzzy-responses'         => 1,
                'strict-responses'        => 1,
                'active-responses'        => 1,
                'fuzzy-active-responses'  => 1,
                'strict-active-responses' => 1,
                'public-responses'        => 1,
            }
        }
    ),
    client => sub {
        my $callback = shift;
        my $query    = URI::Query->new(
            {   q        => "",
                air2_tkt => $org_tkt,
            }
        );

        my $req = HTTP::Request->new( GET => "/inquiries/search?" . $query );
        my $resp = $callback->($req);

        ok( my $json = decode_json( $resp->content ),
            "json decode body of response" );

        my $title = $json->{results}->[0]->{inq_ext_title};
        is( $title,
            "Ay\xFAdenos reportar sobre educaci\xF3n",
            "inq_ext_title has correct title"
        );

        #diag($title);
        ok( is_sane_utf8( $title, 1 ), "$title is sane utf8" );

        #debug_bytes($title);

    },
);

#################################################################
# clean up unless debug is on
#################################################################
END {
    if ( !$debug ) {
        $TMP_DIR->rmtree;
    }
}
