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

package AIR2::Utils;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );
use Search::Tools::UTF8;
use DateTime;
use DateTime::Format::MySQL;
use AIR2::Config;
use MIME::Base64;

my $hostname = AIR2::Config->get_hostname();

sub logger {
    local $| = 1;
    printf( "[%s][%s][%s] %s",
        $hostname, scalar localtime(),
        $$, join( ' ', @_ ) );
}

sub random_str {
    my $self = shift;
    my $n = shift || 12;
    if ( $n =~ m/\D/ ) {
        croak "error: 'n' must be a positive integer, not $n";
    }
    my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    return join( "", @chars[ map { rand @chars } ( 1 .. $n ) ] );
}

sub str_to_uuid {
    my $self = shift;
    my $str  = shift;
    my $len  = shift || 12;
    my $uuid = substr( md5_hex($str), 0, $len );
    return $uuid;
}

=head2 strtotime( I<timestamp> )

Uses DateTime::Format::MySQL internally to convert I<timestamp> to an epoch
integer. I<timestamp> should be in format understood
by DateTime::Format::MySQL.

Assumes all I<timestamp> values are in $AIR2::Config::TIMEZONE
unless explicitly stated.

=cut

sub strtotime {
    my $self      = shift;
    my $timestamp = shift;

    my $dt = DateTime::Format::MySQL->parse_datetime($timestamp);
    $dt->set_time_zone($AIR2::Config::TIMEZONE);

    return $dt->epoch;
}

sub str_clean {
    my $self = shift;
    my $str  = shift;
    my $len  = shift;
    return $str unless ( defined $str && length $str );

    $str = to_utf8($str);    # utf8-ify
    $str =~ s/^\s+|\s+$//g;  #trim whitespace
    $str =~ s/\\$//g
        ;    # trim any trailing \ because they break data infile import

# substr works on characters, but we want absolute bytes.
# note that this might break the utf8 validity by splitting on bytes rather than characters.
    {
        use bytes;
        $str = substr( $str, 0, $len ) if $len;    #optional max len
    }
    return to_utf8($str);    # turn utf8 flag back on, hopefully.
}

sub current_time {
    my $dt = DateTime->now();
    $dt->set_time_zone( AIR2::Config->get_tz() );
    return sprintf( "%s %s", $dt->ymd('-'), $dt->hms(':') );
}

sub current_ymd {
    my $dt = DateTime->now();
    $dt->set_time_zone( AIR2::Config->get_tz() );
    return $dt->ymd('');
}

sub parse_phone_number {
    my $n = shift;
    my %phone;
    if ( defined($n) and length($n) ) {
        my $n_len = length($n);

        #carp "match phone '$n' len $n_len";

        # US (mypin1 pattern)
        if ( $n =~ m/^\(?(\d{3})[)\s\.]*(\d{3})[-\s\.]*(\d{4})$/ ) {
            $phone{number} = "$1.$2.$3";
        }

# see http://stackoverflow.com/questions/123559/a-comprehensive-regex-for-phone-number-validation
        elsif ( $n
            =~ m/^1?\W*([2-9][0-8][0-9])\W*([2-9][0-9]{2})\W*([0-9]{4})(\s*e?x?t?\D*(\d*)\D*)?$/
            )
        {
            $phone{number} = "$1.$2.$3";
            $phone{ext}    = $5;
        }

        # international
        elsif ( $n =~ m/^[0-9 ():.ext,+-]{$n_len}$/ ) {
            $phone{number} = $n;
        }
        else {
            $phone{number} = $n;
        }

        #carp "match: " . dump \%phone;
    }
    return \%phone;
}

sub pack_authz {
    my $org_hash = shift or croak "org_hash required";
    return encode_base64( pack( "(NN)*", %$org_hash ) );
}

sub unpack_authz {
    my $packed = shift or croak "packed authz string required";
    my $decoded_packed = decode_base64($packed);
    if ( length($decoded_packed) % 8 ) {
        croak "invalid packed authz string: $decoded_packed";
    }
    return { unpack( "(NN)*", $decoded_packed ) };
}

# analog to PHP function of same name

sub urlify {
    my $str = shift;

    # tricky - convert CamelCase to camel-case
    $str =~ s/([A-Z][a-z])/-$1/g;

    # all lowercase
    $str = lc($str);

    # non-alphas, strip any markup
    $str =~ s/['",.!?;:]//g;
    $str =~ s/<.+?>|&[\S];//g;
    $str =~ s/\W+/-/g;

    # clean up
    $str =~ s/^-+|-+$//g;
    $str =~ s/--*/-/g;

    return $str;
}

sub generate_stderr {
    my $n = 0;
    my $foo;
    while ( $n++ < 100 ) { print $foo }
}

1;
