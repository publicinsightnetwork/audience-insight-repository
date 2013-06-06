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
use lib "$FindBin::Bin/../../lib/perl";
use DateTime;
use JSON;
use Data::Dump qw( dump );

##
# CallPerl.pl
#
# Executes a perl subroutine, based on json-encoded input passed through STDIN.
# This json-object must have keys (fn argc argv).  The string 'fn' describes
# what perl sub will be eval'd, and 'argc' and 'argv' are the arguments array
# and their count.  The argv array should always be passed, even if empty.
#
# Upon successful execution, the results will be json-encoded and printed to
# STDOUT.  If something goes awry, the error string (NOT encoded) will be
# printed to STDERR, and this script will return non-0.
#
# You can only use this script with functions that have simple, json-encodable
# inputs and outputs.
##

# read the whole STDIN (ignore newlines)
my $holdTerminator = $/;
undef $/;
my $stdin = <STDIN>;
$/ = $holdTerminator;

# try to decode it all
my $params = decode_json($stdin);
my $fn     = $params->{fn};
my $argc   = $params->{argc};
my $argv   = $params->{argv};
croak 'Invalid fn'                     unless ($fn);
croak 'Invalid argc'                   unless ( defined $argc );
croak 'Invalid argv'                   unless ($argv);
croak 'Mismatch between argc and argv' unless ( scalar @{$argv} == $argc );
my @argv = @{$argv};

# attempt to dynamically include package
my $reqd = $fn;
$reqd =~ s/[:-][:>]\w+$//i;
if ($reqd) {
    eval "require $reqd";
    croak($@) if ($@);
}

# run function, rethrowing errors
my $res = undef;
my $call = $fn =~ m/\-\>/ ? "$fn(\@argv)" : "$fn \@argv";
$res = "call=$call";
eval "\$res = $call";
croak($@) if ($@);

# encode results back to STDOUT
my $return = { result => $res };
print encode_json($return);
