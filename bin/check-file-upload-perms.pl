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
use Getopt::Long;
use Pod::Usage;
use AIR2::Config;
use File::Find;
use File::Strmode;
use Path::Class;

my $shared_dir = shift(@ARGV) || AIR2::Config->get_shared_dir();
$shared_dir = dir($shared_dir) unless ref $shared_dir;
my $upload_base = $shared_dir->subdir('upload/Formbuilder');

my $pijuser = 'pijuser';
my $apache  = shift(@ARGV) || 'w3user';    # will be apache at VISI
my $webhome = 'webhome';

my @pijuser_pw  = getpwnam($pijuser);
my $pijuser_uid = $pijuser_pw[2];

my @apache_pw  = getpwnam($apache);
my $apache_uid = $apache_pw[2];

my @webhome_pw  = getgrnam($webhome);
my $webhome_gid = $webhome_pw[2];

find(
    {   wanted   => \&check_file,
        no_chdir => 1,
    },
    $upload_base
);

# crawl the tree.
# if dir is owned by pijuser, must be group 'webhome' and write-able
# if dir is owned by apache, must be owner write-able

sub check_file {
    return unless -d $_;
    my $dir  = $_;
    my @stat = stat($dir);
    my $uid  = $stat[4];
    my $gid  = $stat[5];
    my $perm = strmode( $stat[2] );

    if (    $gid == $webhome_gid
        and $uid == $pijuser_uid
        and $perm !~ m/^....rwx... $/ )
    {
        warn "$dir : $pijuser owns but not group write-able\n";
    }

    if ( $uid == $apache_uid and $perm !~ m/^.rwx...... $/ ) {
        warn "$dir : $apache owns but not owner write-able\n";
    }

}
