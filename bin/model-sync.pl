#!/usr/bin/env perl
#
# compare PHP (Doctrine) model classes against Perl (RDBO) classes.
# work-in-progress. 
# TODO: actual schema comparison to identify differences.
#
###########################################################################
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use Data::Dump qw( dump );
use File::Slurp;
use Path::Class;
use AIR2::Config;
use AIR2::DBManager;
use AIR2::ConventionManager;
use Rose::DB::Object::Loader;

my $gpl = <<GPL;
###########################################################################
#
#   Copyright 2013 American Public Media Group
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
GPL

my %perl_only = map { $_ => $_ } qw(
    DB
    DBManager
    Utils
    Search
    Config
    AuthTkt
    ConventionManager
);

my %php_only = map { $_ => $_ } qw(
    UserStamp
    TagSource
    TagInquiry
    TagProject
    TagResponseSet
    BatchUser
    BatchSource
);

my $app_root  = AIR2::Config::get_app_root();
my $php_root  = $app_root->subdir( 'app', 'models' );
my $perl_root = $app_root->subdir( 'lib', 'perl', 'AIR2' );

my $loader = Rose::DB::Object::Loader->new(
    db                 => AIR2::DBManager->new(),
    class_prefix       => 'AIR2',
    base_class         => 'AIR2::DB',
    with_managers      => 0,
    convention_manager => 'AIR2::ConventionManager',
    module_dir         => $app_root->subdir( 'lib', 'perl' ) . "",
    module_preamble    => $gpl,
);

# compare .php against .pm
while ( my $file = $php_root->next ) {
    next unless $file =~ m/\.php$/;
    my $class = $file->basename;
    $class =~ s/\.php//;
    next if exists $php_only{$class};

    #print "file=$file\n";
    print "php class=$class\n";

    #my $schema = get_php_schema($file);
    my $table_name = get_php_table_name($file);

    #print dump($schema) . "\n";

    my $pm_file = $perl_root->file( $class . '.pm' );
    if ( !-s $pm_file ) {
        warn "No pm_file $pm_file\n";
        $loader->make_modules( include_tables => [$table_name] );

        #next;
    }
}

# compare .pm against .php
while ( my $file = $perl_root->next ) {
    next unless $file =~ m/\.pm$/;
    my $class = $file->basename;
    $class =~ s/\.pm$//;
    next if exists $perl_only{$class};
    my $php_file = $php_root->file( $class . '.php' );
    if ( !-s $php_file ) {
        warn "No php_file $php_file\n";
        next;
    }
}

sub get_php_table_name {
    my $file = shift;
    my $buf  = $file->slurp;
    my ($table_name) = ( $buf =~ m/setTableName\(.(\w+).\)/ );
    return $table_name;
}

sub get_php_schema {
    my $file = shift;
    my @buf  = $file->slurp;
    my @def;
    for my $line (@buf) {
        if ( $line =~ m/function setTableDefinition/ ) {
            push @def, $line;
            next;
        }
        if ( $line =~ m/^    \}/ ) {
            last;
        }
        if (@def) {
            push @def, $line;
        }
    }
    return parse_php_schema( join( '', @def ) );
}

sub parse_php_schema {
    my $def = shift;
    my %schema;
    while (
        $def =~ m/hasColumn\('(\w+)', '(\w+)', (\S+), array\((.*?)\)\)/sg )
    {
        my $colname = $1;
        my $type    = $2;
        my $len     = $3;
        my $att     = $4;

        my %attr;
        while ( $att =~ m/(['"])(.+?)\1\s*=>\s*(\S+),/gs ) {
            $attr{$2} = $3;
        }

        #perl-ify
        for my $k ( keys %attr ) {
            my $v = $attr{$k};
            $v = 1 if $v eq 'true';
            $v = 0 if $v eq 'false';
            if ( $k eq 'notnull' ) {
                $attr{'not_null'} = $v;
                delete $attr{$k};
            }
        }

        $type = 'datetime' if $type eq 'timestamp';    # perl syntax
        $schema{$colname} = { type => $type };
        $schema{$colname}->{length} = $len if length($len) and $len ne "null";
        $schema{$colname}->{$_} = $attr{$_} for keys %attr;

    }

    return \%schema;

}
