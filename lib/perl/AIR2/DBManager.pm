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

package AIR2::DBManager;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use base 'Rose::DBx::AutoReconnect';

my $cfg      = AIR2::Config::get_profiles();
my $user     = AIR2::Config::get_user();
my $hostname = AIR2::Config::get_hostname();
my $profile  = AIR2::Config::get_profile_name();

__PACKAGE__->use_private_registry;

my %master_slave;
for my $section ( $cfg->Sections ) {
    __PACKAGE__->register_db(
        domain   => $section,
        type     => $user,
        driver   => 'mysql',
        database => $cfg->val( $section, 'dbname' ),
        host     => $cfg->val( $section, 'hostname' ),
        username => $cfg->val( $section, 'username' ),
        password => $cfg->val( $section, 'password' ),
        post_connect_sql =>
            [ 'SET NAMES utf8', qq/SET sql_mode='STRICT_ALL_TABLES'/ ],
        mysql_enable_utf8 => 1,
        server_time_zone  => $cfg->val( $section, 'server_time_zone' ),
    );
    if ( $section =~ m/^(.+)_master$/ ) {
        $master_slave{$1} = $section;
    }
}

sub get_write_handle {
    my $self   = shift;
    my $domain = $self->domain;
    my $class  = ref($self) || $self;
    if ( exists $master_slave{$domain} ) {
        return $class->new_or_cached( domain => $master_slave{$domain} );
    }
    return $self;
}

sub get_master_domain_for {
    my $self = shift;
    my $domain = shift or croak "domain required";
    return $master_slave{$domain} || $domain;
}

# override to optionally return master if AIR2_USE_MASTER is set
sub new_or_cached {
    my $class = shift;
    my %arg   = @_;
    if ( $ENV{AIR2_USE_MASTER} ) {
        $arg{domain} = $class->get_master_domain_for( $arg{domain}
                || $class->default_domain );
    }

    #dump( \%arg );
    my $db;
    eval { $db = $class->SUPER::new_or_cached(%arg); };
    if ( $@ or !$db ) {
        warn "DB connection failed: $@";
        $arg{domain} = $class->get_master_domain_for( $arg{domain}
                || $class->default_domain );

        #dump( \%arg );
        $db = $class->SUPER::new_or_cached(%arg);
    }
    return $db;
}

__PACKAGE__->default_domain( $ENV{AIR2_DOMAIN}
        || $profile
        || $hostname
        || 'dev' );
__PACKAGE__->default_type($user);

1;

