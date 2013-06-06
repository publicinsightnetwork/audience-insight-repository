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

package AIR2TestUtils;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/models";
use lib "$FindBin::Bin/search/models";
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::AuthTkt;
use AIR2::SearchUtils;
use LWP::UserAgent;
use JSON::XS;
use Crypt::CBC;
use HTTP::Engine::Test::Request;
use IPC::Cmd ();

sub search_env_ok {

    # must explicitly call for search tests (as in smoke tests)
    # we do this because the in-house tests require a live index.
    if ( !$ENV{AIR2_TEST_SEARCH} ) {
        warn "set AIR2_TEST_SEARCH to test search\n";
        return 0;
    }
    my $idx_dir = AIR2::Config->get_search_index();
    if ( !-d $idx_dir ) {
        warn "no dir at $idx_dir\n";
        return 0;
    }

    return 1;
}

my $AUTHTKT_CONF = AIR2::Config->get_auth_tkt_conf();

sub new_auth_tkt {
    return AIR2::AuthTkt->new(
        conf      => $AUTHTKT_CONF,
        ignore_ip => 1,
    );
}

sub dummy_authz {
    my @org_ids = @_;
    my $authz;
    if (@org_ids) {
        $authz = { map { $_ => 1 } @org_ids };
    }
    else {
        $authz = { 1 => 3, 2 => 1 };
    }
    return encode_json(
        {   user  => { type => "A" },
            authz => AIR2::SearchUtils::pack_authz($authz)
        }
    );
}

sub dummy_tkt {
    my $at     = new_auth_tkt();
    my $json   = dummy_authz(@_);
    my $ticket = $at->ticket(
        uid     => 'nosuchuser',
        ip_addr => '0.0.0.0',
        data    => $json,
    );
    return $ticket;
}

sub dummy_system_tkt {
    my $at     = new_auth_tkt();
    my $json   = encode_json( { user => { type => "S" }, } );
    my $ticket = $at->ticket(
        uid     => 'system-user',
        ip_addr => '0.0.0.0',
        data    => $json,
    );
    return $ticket;
}

sub get_server_pid_file {
    return AIR2::Config->get_search_root()->file('var/search-server.pid');
}

sub new_http_request {
    my $req = HTTP::Engine::Test::Request->new(@_);
    return $req;
}

sub run_it {
    my $cmd = shift;
    my $debug = shift || 0;
    AIR2::Utils::logger($cmd) if $debug;
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf )
        = IPC::Cmd::run( command => $cmd, verbose => $debug );

    if ( !$success ) {
        die "$cmd failed with [$error_code]: " . join( "\n", @$stderr_buf );
    }
    return $full_buf;
}

sub create_index {
    my %arg      = @_;
    my $invindex = $arg{invindex} or croak "invindex required";
    my $config   = $arg{config} or croak "config required";
    my $input    = $arg{input} or croak "input required";
    my $cmd
        = "swish3 -F lucy -f $invindex -c $config -i $input --lucy_highlightable";
    my $buf = run_it( $cmd, $arg{debug} );
    $buf = join( "", @$buf );

    #warn $buf;

    # pull out num indexed
    my ($num) = ( $buf =~ m/(\d+) documents/ );
    return $num;
}

1;
