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

package AIR2::Config;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Path::Class;
use Config::IniFiles;
use Sys::Hostname;

my $hostname = hostname();
$hostname =~ s/\..+//;
my $user = $ENV{AIR2_USER} || $ENV{USER} || $ENV{REMOTE_USER} || 'nobody';
my $path_to_this_pm = file( $INC{"AIR2/Config.pm"} );
my $etc_dir
    = $path_to_this_pm->dir->absolute->parent->parent->parent . '/etc';
my $profiles_ini = $etc_dir . "/profiles.ini";
my $profiles     = Config::IniFiles->new( -file => $profiles_ini );
my $profile      = $ENV{'AIR2_PROFILE'} || get_profile_name();
my $version_file = file( $etc_dir, 'my_version' );
my $version      = '2.x.y';

if ( -s $version_file ) {
    chomp( $version = $version_file->slurp );
}
my $air2_constants = _load_constants_file(
    get_app_root()->file('app/config/air2_constants.php') );

_override_constants_with_profile( $air2_constants, $profiles, $profile );

#dump $air2_constants;

#warn "hostname=$hostname\n";
#dump $profiles->val($profile);

# set the global app timezone based on $hostname config
our $TIMEZONE = $profiles->val( $profile, 'server_time_zone' );

# same for search
our $SEARCH_URI  = $profiles->val( $profile, 'search_uri' );
our $SEARCH_ROOT = $profiles->val( $profile, 'search_root' );
our $SHARED_DIR  = $profiles->val( $profile, 'shared_dir' )
    || '/opt/pij/shared';

# set the authz constants
# $AIR2::Config::ACTION{ACTION_SOMETHING_READ}
# $AIR2::Config::AUTHZ{W}
my $actions_ini = Config::IniFiles->new(
    -file => get_app_root() . '/app/config/actions.ini' );
my $roles_ini = Config::IniFiles->new(
    -file          => get_app_root() . '/app/config/roles.ini',
    -allowcontinue => 1
);

# package hashes of bitmask look up tables
our %ACTIONS;
our %AUTHZ;
for my $name ( $actions_ini->Parameters('ACTIONS') ) {
    my $bitmask = $actions_ini->val( 'ACTIONS', $name );
    $ACTIONS{$name} = $bitmask;
}
for my $name ( $roles_ini->Sections ) {
    my $mask   = 0;
    my $code   = $roles_ini->val( $name, 'ar_code' );
    my @authzs = split( /[\s"]+/, $roles_ini->val( $name, 'authz' ) );
    for my $act ( grep {m/./} @authzs ) {
        if ( !exists $ACTIONS{$act} ) {
            croak "Unknown action $act in roles.ini";
        }
        $mask = $mask | $ACTIONS{$act};
    }
    $AUTHZ{$code} = $mask;
}

sub get_global_pin_org_id { get_constant('AIR2_GLOBALPIN_ORG_ID') }
sub get_apmpin_org_id     { get_constant('AIR2_APMPIN_ORG_ID') }

sub get_php_path {
    return ( $profiles->val( $profile, 'php_path' ) || '/usr/local/bin/php' );
}
sub get_profiles { return $profiles }
sub get_profile  { return $profile }

sub get_profile_val {
    my $v = $profiles->val( $profile, pop(@_) );
    $v =~ s/^['"]|['"]$//g;
    return $v;
}
sub get_hostname { return $hostname }
sub get_user     { return $user }
sub get_tz       { return $TIMEZONE }
sub get_version  { return $version }
sub get_tmp_dir  { return Path::Class::dir( '/tmp/air2-temp-' . $profile ) }

sub get_smtp_host {
    return $air2_constants->{AIR2_SMTP_HOST} . ':'
        . $air2_constants->{AIR2_SMTP_PORT};
}

sub get_smtp_username {
    return $air2_constants->{AIR2_SMTP_USERNAME};
}

sub get_smtp_password {
    return $air2_constants->{AIR2_SMTP_PASSWORD};
}

sub smtp_host_requires_auth {
    return get_smtp_host() =~ m/mandrill/;
}

sub get_upload_base_dir {
    my $upload_base
        = Path::Class::dir( $air2_constants->{AIR2_UPLOAD_BASE_DIR} );
    return $upload_base;
}

sub get_mypin2_url {
    return $air2_constants->{AIR2_MYPIN2_URL};
}

sub get_base_url {
    return $air2_constants->{AIR2_BASE_URL};
}

sub get_tandc_queue_root {
    return Path::Class::dir( $profiles->val( $profile, 'tandc_queue_path' )
            || '/opt/pin/shared/tandc' );
}

sub get_pinsightful_tag {
    return $air2_constants->{AIR2_PINSIGHTFUL_TAG};
}

sub get_constant {
    my $const = shift or croak "constant name required";
    return $air2_constants->{$const};
}

sub get_rss_cache_dir {
    return Path::Class::dir( $air2_constants->{AIR2_RSS_CACHE_ROOT}
            || get_app_root()->subdir('assets/rss_cache') );
}

sub get_auth_tkt_conf {
    return Path::Class::file( get_app_root()->file('etc/auth_tkt.conf') );
}
sub get_auth_tkt_name { return $air2_constants->{'AIR2_AUTH_TKT_NAME'} }

sub get_search_root {
    if ( !$SEARCH_ROOT ) {
        croak "Invalid search_root for $profile -- check etc/profiles.ini";
    }
    return Path::Class::dir($SEARCH_ROOT);
}
sub get_search_uri   { return $SEARCH_URI }
sub get_search_xml   { return Path::Class::dir( $SEARCH_ROOT, 'xml' ) }
sub get_search_stale { return Path::Class::dir( $SEARCH_ROOT, 'stale' ) }
sub get_search_index { return Path::Class::dir( $SEARCH_ROOT, 'index' ) }

sub get_search_config {
    my $type = shift or croak "type required";
    return get_app_root()->file( 'etc/search/' . $type . '.config' );
}

sub get_email_export_path {
    return Path::Class::dir(
        $profiles->val( $profile, 'email_export_path' ) );
}
sub get_shared_dir { return Path::Class::dir($SHARED_DIR) }

sub get_search_port {
    my ($port) = ( $SEARCH_URI =~ m/:(\d+)/ );
    return $port || 80;
}

sub get_search_index_path {

    # can call as function or method
    if ( $_[0] eq __PACKAGE__ ) {
        shift @_;
    }
    return get_search_index->subdir(@_)->stringify;
}

sub get_app_root {
    return $path_to_this_pm->dir->absolute->parent->parent->parent;
}

sub get_submission_pen {
    return Path::Class::dir( get_constant('AIR2_QUERY_INCOMING_ROOT') );
}

sub get_pin_logo_uri {
    return $profiles->val( $profile, 'pin_logo_uri' )
        || 'https://www.publicinsightnetwork.org/air2/img/org/49896787525b/logo_medium.png';
}

sub get_profile_name {
    my $root = get_app_root();
    my $profile = $root->file( 'etc', 'my_profile' );
    if ( !-s $profile ) {
        return $hostname;
    }
    my $name = $profile->slurp;
    chomp($name);
    return $name;
}

sub _load_constants_file {
    my $file = shift;
    my @buf  = $file->slurp;
    my %const;
    for my $line (@buf) {
        if ( $line =~ m/define\((['"])([A-Z\_0-9]+)\1,\ +(['"])(.+)\3\)/ ) {
            $const{$2} = $4;
        }
        elsif ( $line =~ m/define\((['"])([A-Z\_0-9]+)\1,\ +(.+)\)/ ) {
            $const{$2} = $3;
        }
        elsif ( $line =~ m/array\('(AIR2_[A-Z\_\d]+)',\ +(['"])(.+)\2\)/ ) {
            $const{$1} = $3;
        }
        elsif ( $line =~ m/array\('(AIR2_[A-Z\_\d]+)',\ +(.+)\)/ ) {
            $const{$1} = $2;
        }
    }
    _massage_constants( \%const );
    return \%const;
}

sub _massage_constants {
    my $consts = shift;
    my $root   = get_app_root();
    for my $k ( keys %$consts ) {
        my $v = $consts->{$k};
        if ( $v =~ m/\ \.\ |[']/ ) {
            if ( $v =~ m/AIR2_CODEROOT/ ) {
                $v =~ s/AIR2_CODEROOT/"$root"/;
                $consts->{$k} = eval "$v";
            }
            elsif ( $v =~ m/APPPATH/ ) {
                $v =~ s/APPPATH/"$root\/"/;
                $consts->{$k} = eval "$v";
            }
            elsif ( $v =~ m/AIR2_VERSION/ ) {
                $v =~ s/AIR2_VERSION/"$version"/;
                $consts->{$k} = eval "$v";
            }
        }
        if ( $v eq 'null' ) {
            $consts->{$k} = undef;
        }
    }
}

sub _override_constants_with_profile {
    my ( $air2_constants, $profiles, $profile ) = @_;
    my @param_names = $profiles->Parameters($profile);
    for my $pn (@param_names) {

        # filter some out for security
        next if $pn eq 'password';
        next if $pn eq 'username';

        my $const_name = 'AIR2_' . uc($pn);
        $air2_constants->{$const_name} = $profiles->val( $profile, $pn );
    }
}

1;

__END__

=head2 NAME

AIR2::Config - get application configuration

=head2 SYNOPSIS

 use AIR2::Config;
 my $profiles = AIR2::Config::get_profiles();
 my $tz = AIR2::Config::get_tz();  # or just $AIR2::Config::TIMEZONE;
 my $hostname = AIR2::Config::get_hostname();
 my $username = AIR2::Config::get_user();
 my $dir = AIR2::Config::get_app_root();

=head2 FUNCTIONS

=head2 get_profiles

Returns Config::IniFiles object representing app_root/etc/profiles.ini.

=head2 get_tz

Returns timezone configured for current hostname.

=head2 get_hostname

Returns current hostname.

=head2 get_user

Returns username of the current process. Looks at environment variables in the following
order:

=over

=item

AIR2_USER

=item

USER

=item

REMOTE_USER

=back

Defaults to "pijuser."

=head2 get_app_root

Returns Path::Class::Dir object for the application root directory.

=head2 get_search_uri

Returns string.

=head2 get_search_root

Returns Path::Class::Dir object.

=head2 get_search_xml

Returns Path::Class::Dir object.

=head2 get_search_index

Returns Path::Class::Dir object.

=head2 get_search_port

Returns string.

=head2 get_search_index_path('subdir')

Returns full path string for 'subdir'.

=head2 get_profile_name

Returns current profile name.

=cut

