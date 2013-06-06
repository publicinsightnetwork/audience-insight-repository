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
use Getopt::Long;
use Pod::Usage;
use File::Path qw( make_path );
use FindBin;

=pod

=head1 NAME

mk_docs.pl - build AIR2 docbook documentation

=head1 SYNOPSIS

 mk_docs.pl --pdf
 mk_docs.pl --html

=head1 DESCRIPTION

mk_docs.pl is a simple wrapper around the various docbook-utils tools.

=head1 OPTIONS

=head2 pdf

Create PDF version of the documentation.

=head2 html

Create HTML version of the documentation.

=cut

my $build_pdf  = 0;
my $build_html = 0;
GetOptions(
    'pdf'  => \$build_pdf,
    'html' => \$build_html,
) or pod2usage(2);

if ( !$build_pdf and !$build_html ) {
    pod2usage(2);
}

my $outdir = "$FindBin::Bin/../public_html/doc";
make_path($outdir);

my $redhat = `cat /etc/redhat-release`;
my $xsldir;

# RHEL4
if ( $redhat =~ m/release 4/ ) {
    $xsldir = '/opt/pij/share/docbook-xsl';
}

# ubuntu
elsif ( !$redhat ) {
    $xsldir = "/usr/share/xml/docbook/stylesheet/nwalsh";
}

# create PDF - NOTE only works where fop is installed (not RHEL4)
if ($build_pdf) {
    my $fo_cmd
        = "xsltproc -o /tmp/air2-doc.fo $xsldir/fo/docbook.xsl doc/book/air2.xml";
    system($fo_cmd) and die "$fo_cmd failed: $!";
    my $pdf_cmd = "fop -pdf $outdir/air2.pdf -fo /tmp/air2-doc.fo";
    system($pdf_cmd) and die "$pdf_cmd failed: $!";
}

# create HTML
if ($build_html) {
    my $cmd
        = "xsltproc -o $outdir/index.html /opt/pij/etc/docbook.xsl doc/book/air2.xml";
    system($cmd) and die "$cmd failed: $!";
}
