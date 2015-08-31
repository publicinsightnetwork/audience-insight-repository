#!/usr/bin/env perl

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

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use Getopt::Long;
use Pod::Usage;
use Benchmark qw(timethis);
use AIR2::Inquiry;
use AIR2::InquiryPublisher;
use Term::ProgressBar::Simple;

=pod

=head1 NAME

publish_inquiry.pl

=head1 SYNOPSIS

 publish_inquiry.pl inq_uuid [options]
    --help
    --all
    --format=[json|html]
    --benchmark

=head1 DESCRIPTION



=cut

my ( $inq_uuid, @formats, $help, $benchmark, $do_all );

GetOptions(
    'format=s'  => \@formats,
    'help'      => \$help,
    'benchmark' => \$benchmark,
    'all'       => \$do_all,
) or pod2usage(2);

if ($help) {
    pod2usage(2);
}

$inq_uuid = shift(@ARGV);

unless ( $inq_uuid or $do_all ) {
    pod2usage(2);
}

@formats = split( /,/, join( ',', @formats ) );

if ($benchmark) {
    timethis( 100,
        "AIR2::InquiryPublisher->publish( \"$inq_uuid\", @formats );" );
}
elsif ($inq_uuid) {
    AIR2::InquiryPublisher->publish( $inq_uuid, @formats );
}
elsif ($do_all) {
    my $progress = Term::ProgressBar::Simple->new(
        AIR2::Inquiry->fetch_count(
            query => [
                inq_status => [qw( A L E S )],
                inq_type   => [
                    AIR2::Inquiry::TYPE_FORMBUILDER,
                    AIR2::Inquiry::TYPE_QUERYBUILDER,
                    AIR2::Inquiry::TYPE_NONJOURN,
                ]
            ],
        )
    );
    my $inquiries = AIR2::Inquiry->fetch_all_iterator(
        query => [
            inq_status => [qw( A L E S )],
            inq_type   => [
                AIR2::Inquiry::TYPE_FORMBUILDER,
                AIR2::Inquiry::TYPE_QUERYBUILDER,
                AIR2::Inquiry::TYPE_NONJOURN,
            ],
        ],
    );
    while ( my $inq = $inquiries->next ) {

        if (    $inq->inq_publish_dtim
            and $inq->inq_publish_dtim->epoch > time() )
        {
            # scheduled for the future
            next;
        }
        AIR2::InquiryPublisher->publish( $inq->inq_uuid, @formats );
        $progress++;
    }
}

