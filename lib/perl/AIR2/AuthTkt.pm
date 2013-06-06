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

package AIR2::AuthTkt;
use strict;
use warnings;
use base qw( Apache::AuthTkt );
use Crypt::CBC;
use Carp;
use Data::Dump qw( dump );
use MIME::Base64;

sub _get_cipher {
    my $self   = shift;
    my $secret = $self->secret;
    while ( length($secret) < 48 ) {
        $secret .= $secret;
    }
    my $cipher = Crypt::CBC->new(
        {   'key'            => substr( $secret, 0,  32 ),
            'cipher'         => 'Rijndael',
            'iv'             => substr( $secret, 32, 16 ),
            'regenerate_key' => 0,
            'padding'        => 'null',
            'prepend_iv'     => 0
        }
    );
    return $cipher;
}

sub _encrypt {
    my $self      = shift;
    my $str       = shift or croak "str required";
    my $cipher    = $self->_get_cipher;
    my $encrypted = $cipher->encrypt($str);
    my $unpacked  = unpack( "H*", $encrypted );

    #warn "str='$str'";
    #warn "encrypted='$encrypted'";
    #warn "unpacked ='$unpacked'";

    return $unpacked;
}

sub _decrypt {
    my $self      = shift;
    my $str       = shift or croak "str required";
    my $packed    = pack( "H*", $str );
    my $decrypted = $self->_get_cipher->decrypt($packed);
    $decrypted =~ s/\000$//;

    #warn "str='$str'";
    #warn "decrypted='$decrypted'";

    return $decrypted;
}

sub _get_digest {
    my ( $self, $ts, $ip_addr, $uid, $tokens, $data, $debug ) = @_;
    my @ip = split /\./, $ip_addr;
    my @ts = (
        ( ( $ts & 0xff000000 ) >> 24 ),
        ( ( $ts & 0xff0000 ) >> 16 ),
        ( ( $ts & 0xff00 ) >> 8 ),
        ( ( $ts & 0xff ) )
    );
    my $ipts = pack( "C8", @ip, @ts );
    if ($data) {
        $data = $self->_encrypt($data);
    }
    my $raw = $ipts . $self->secret . $uid . "\0" . $tokens . "\0" . $data;
    my $digest_function = $self->_get_digest_function;
    my $digest0         = $digest_function->($raw);
    my $digest          = $digest_function->( $digest0 . $self->secret );

    if ($debug) {
        print STDERR
            "ts: $ts\nip_addr: $ip_addr\nuid: $uid\ntokens: $tokens\ndata: $data\n";
        print STDERR "secret: " . $self->secret . "\n";
        print STDERR "raw: '$raw'\n";
        my $len = length($raw);
        print STDERR "digest0: $digest0 (input length $len)\n";
        print STDERR "digest: $digest\n";
    }

    return $digest;
}

sub parse_ticket {
    my $self  = shift;
    my $parts = $self->SUPER::parse_ticket(@_);
    return $parts unless $parts;
    $parts->{data} = $self->_decrypt( $parts->{data} ) if $parts->{data};
    return $parts;
}

sub ticket {
    my $self     = shift;
    my %DEFAULTS = (
        base64 => 1,
        data   => '',
        tokens => '',
    );
    my %arg = ( %DEFAULTS, %$self, @_ );
    $arg{uid} = $self->guest_user unless exists $arg{uid};
    $arg{ip_addr} = $arg{ignore_ip} ? '0.0.0.0' : $ENV{REMOTE_ADDR}
        unless exists $arg{ip_addr};

    # 0 or undef ip_addr treated as 0.0.0.0
    $arg{ip_addr} ||= '0.0.0.0';

    # Data cleanups
    if ( $arg{tokens} ) {
        $arg{tokens} =~ s/\s+,/,/g;
        $arg{tokens} =~ s/,\s+/,/g;
    }

    # Data checks
    if ( $arg{ip_addr} !~ m/^([12]?[0-9]?[0-9]\.){3}[12]?[0-9]?[0-9]$/ ) {
        $self->errstr("invalid ip_addr '$arg{ip_addr}'");
        return undef;
    }
    if ( $arg{tokens} =~ m/[!\s]/ ) {
        $self->errstr("invalid chars in tokens '$arg{tokens}'");
        return undef;
    }

    # Calculate the hash for the ticket
    my $ts = $arg{ts} || time;
    my $digest = $self->_get_digest(
        $ts,          $arg{ip_addr}, $arg{uid},
        $arg{tokens}, $arg{data},    $arg{debug}
    );

    # Construct the ticket itself
    my $ticket = sprintf "%s%08x%s!", $digest, $ts, $arg{uid};
    $ticket .= $arg{tokens} . '!' if $arg{tokens};
    $ticket .= $self->_encrypt( $arg{data} );

    return $arg{base64} ? encode_base64( $ticket, '' ) : $ticket;

}

1;
