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
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use lib "$FindBin::Bin/../lib/shared/perl";
sub logger { AIR2::Utils::logger(@_) }

# AIR2 perl ORM
use AIR2::Config;
use AIR2::Utils;
use AIR2::DBManager;
my $dbh = AIR2::DBManager->new->get_write_handle;

# file to load
my $dumpfile = "$FindBin::Bin/../etc/sql/geo_lookup.sql.gz";

# database connection info
my $usr  = $dbh->username;
my $pwd  = $dbh->password;
my $db   = $dbh->database;
my $host = $dbh->host;
my $loadcmd = "mysql -u'$usr' -p'$pwd' -h'$host' $db";

# run the command
my $cmd = "gunzip < $dumpfile | $loadcmd";
system($cmd) and die "$cmd failed: $!";
