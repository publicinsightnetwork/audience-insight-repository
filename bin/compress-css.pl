#!/usr/bin/env perl

=head1
Slightly modified version of compress-js.pl that slurps up all the css
and minifies it.

Update get_css_files() if there are any new css files that need to be ignored
=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Config;
use Path::Class;
use File::Slurp;
use CSS::Minifier qw( minify );
use File::Find;

my $css_dir         = AIR2::Config::get_app_root()->subdir('public_html/css');
my $compressed_file = $css_dir->file('air2-compressed.css');
$compressed_file->remove();    # do not find
my $files = get_css_files();
my $css    = "";
my $total = 0;
for my $f (@$files) {
    my $buf = file($f)->slurp;
    $total += length($buf);
    $css .= "\n" . $buf;
}

my $mini  = scalar(@ARGV) ? $css : minify( input => $css );
my $after = length($mini);
my $saved = int( $after / $total * 100 );
write_file( "$compressed_file", $mini );
print
    "Compressed $total bytes to $after (saved $saved\%) in $compressed_file\n";

=head2 get_css_files()
filters out non-shared css files and returns the rest in a big ol' array
=cut
sub get_css_files {

    # these must load first in this order
    # none currently for css
    my @css = ();

    # these should not be compressed
    my %skip = map { $_ => 1 }
        ( "$css_dir/docbook.css",
        "$css_dir/login.css",
        "$css_dir/ie.css",
        "$css_dir/print.css",
        "$css_dir/ext-theme-air2.css",
        "$css_dir/query.css",
        "$css_dir/pinform.css" );
    my @rest;
    my %known = map { $_ => $_ } @css;
    find(
        {   wanted => sub {
                return if m/\.svn/;
                return unless m/\.css$/;
                return if exists $known{$_};
                return if exists $skip{$_};

                push @rest, $_;

            },
            follow   => 0,
            no_chdir => 1,
        },
        "$css_dir"
    );
    return [ @css, @rest ];
}
