###########################################################################
#
#   Copyright 2012 American Public Media Group
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

package AIR2::Search::Authenticator;
use strict;
use warnings;
use base 'Plack::Middleware';
use Carp;
use AIR2::AuthTkt;
use JSON;
use AIR2::Config;
use Data::Dump qw( dump );
use Plack::Request;

=pod

=head1 NAME

AIR2::Search::Authenticator - provide authentication to Plack applications

=head1 METHODS

This is a Plack::Middleware subclass that provides
AIR2 auth_tkt authentication.

=cut

my $TKT_NAME = AIR2::Config->get_auth_tkt_name();
my $AUTHTKT_CONF
    = AIR2::Config::get_app_root->subdir('etc')->file('auth_tkt.conf');
my $AT = AIR2::AuthTkt->new(
    conf      => $AUTHTKT_CONF,
    ignore_ip => 1,
);

=head2 call( I<env> )

Required Plack method.

=cut

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);

    # check authn
    my $params      = $req->parameters;
    my $auth_cookie = $req->cookies->{$TKT_NAME}
        || $params->{$TKT_NAME};
    if ( ref($auth_cookie) ) {
        $auth_cookie = $auth_cookie->value;
    }
    if ( !$auth_cookie ) {
        my $res = $req->new_response;
        $res->status(401);
        $res->body("Permission denied: missing ticket");
        return $res->finalize();
    }

    my $tkt = $AT->parse_ticket( $auth_cookie, ignore_ip => 1 );

    if ( !$tkt ) {
        my $res = $req->new_response;
        $res->status(401);
        $res->body("Permission denied: invalid ticket");
        return $res->finalize();
    }

    # abuse params to pass authz
    $params->set( 'auth_tkt', $tkt->{data} );

    $req->logger->(
        {   level   => 'debug',
            message => $req->path . ' : ' . dump($tkt),
        }
    );

    # get username into access log
    $env->{REMOTE_USER} = $tkt->{uid};

    return $self->app->($env);
}

1;
