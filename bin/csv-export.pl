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
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Getopt::Long;
use Pod::Usage;
use Email::Stuff;
use Text::CSV_XS;
use JSON;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::Bin;
use AIR2::User;
use AIR2::Source;
use AIR2::CSVWriter;

=pod

=head1 NAME

csv-export

=head1 SYNOPSIS

 csv-export [options]
    --help
    --debug
    --logging
    --user_id=i
    --src_id=i
    --bin_id=i
    --format=[csv|json|email]
    --complex_facts

=head1 DESCRIPTION

csv-export prints out a csv for a source

=head1 OPTIONS

=head2 user_id

=cut

my ($help,   $debug, $logging,   $user_id, $src_id,
    $bin_id, $fmt,   $cpx_facts, $bin_notes
);
GetOptions(
    'help'          => \$help,
    'debug'         => \$debug,
    'logging'       => \$logging,
    'user_id=i'     => \$user_id,
    'src_id=i'      => \$src_id,
    'bin_id=i'      => \$bin_id,
    'format=s'      => \$fmt,
    'complex_facts' => \$cpx_facts,
    'notes'         => \$bin_notes,
) or pod2usage(2);

if ($help) {
    pod2usage(2);
}
if ( !( $src_id || $bin_id ) || ( $src_id && $bin_id ) ) {
    pod2usage('Specify either a src_id or a bin_id.');
}
$debug     = 0 unless defined $debug;
$logging   = 0 unless defined $logging;
$cpx_facts = 0 unless defined $cpx_facts;
$bin_notes = 0 unless defined $bin_notes;

# check user
my $user = AIR2::User->new( user_id => $user_id )->load;
if ( !$user->get_primary_email() && $fmt eq 'email' ) {
    croak "User " . $user->user_username . " has no email address!";
}

# format defaults to outputting a csv to screen
$fmt = 'csv' unless $fmt;
if ( $fmt ne 'csv' && $fmt ne 'json' && $fmt ne 'email' ) {
    pod2usage(
        'Invalid format specified! Valid formats are (csv, json, email)');
}

# get the csv object
my $obj;
my $opts = ();
$opts->{complex_facts} = 1 if $cpx_facts;
$opts->{log_activity}  = 1 if $logging;
$opts->{bin_notes}     = 1 if $bin_notes;
if ($src_id) {
    $obj = AIR2::CSVWriter->from_sources( [$src_id], $user_id, $opts );
}
else {
    $obj = AIR2::CSVWriter->from_bin( $bin_id, $user_id, $opts );
}

# write to output format
if ( $fmt eq 'csv' ) {
    my $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } )
        or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
    $csv->print( "STDOUT", $_ ) for @{$obj};
}
elsif ( $fmt eq 'json' ) {
    my $json = encode_json($obj);
    print $json;
}
elsif ( $fmt eq 'email' ) {
    my $eml  = $user->get_primary_email()->uem_address();
    my $name = 'unknown';
    if ($src_id) {
        my $src = AIR2::Source->new( src_id => $src_id )->load;
        $name = $src->src_username;
    }
    else {
        my $bin = AIR2::Bin->new( bin_id => $bin_id )->load;
        $name = $bin->bin_name;
    }

    my $url = AIR2::Utils::write_secure_csv_report( rows => $obj );

    # fire!
    send_email(
        to      => $eml,
        from    => 'support@publicinsightnetwork.org',
        subject => "AIR CSV export results - $name",
        text    => (
            $src_id
            ? "Exported source $name\n$url"
            : "Exported bin $name\n$url"
        ),
    );

}

sub send_email {
    my %args = @_;
    if ($debug) {
        dump \%args;
    }
    my $stuff = Email::Stuff->to( $args{to} )->from( $args{from} )
        ->subject( $args{subject} );
    if ( $args{text} ) {
        $stuff->text_body( $args{text} );
    }
    if ( $args{html} ) {
        $stuff->html_body( $args{html} );
    }
    if ( $args{attach} ) {
        $stuff->attach( @{ $args{attach} } );
    }
    my %mailer_args = ( Host => AIR2::Config->get_smtp_host, );
    if ( AIR2::Config->smtp_host_requires_auth ) {
        $mailer_args{username} = AIR2::Config->get_smtp_username;
        $mailer_args{password} = AIR2::Config->get_smtp_password;
    }
    my $smtp = Email::Send->new(
        {   mailer      => 'SMTP',
            mailer_args => [ %mailer_args, ]
        }
    ) or die "failed to create Email::Send::SMTP: $@ $!\n";
    my $result = $stuff->using($smtp)->send();

    $debug and warn $result;

    return $result;
}
