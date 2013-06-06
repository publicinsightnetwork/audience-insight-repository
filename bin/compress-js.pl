#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Config;
use Path::Class;
use File::Slurp;
use JavaScript::Minifier qw( minify );
use File::Find;

my $js_dir          = AIR2::Config::get_app_root()->subdir('public_html/js');
my $compressed_file = $js_dir->file('air2-compressed.js');
$compressed_file->remove();    # do not find
my $files = get_js_files();
my $js    = "";
my $total = 0;
for my $f (@$files) {
    my $buf = file($f)->slurp;
    $total += length($buf);
    $js .= "\n" . $buf;
}

my $mini  = scalar(@ARGV) ? $js : minify( input => $js );
my $after = length($mini);
my $saved = int( $after / $total * 100 );
write_file( "$compressed_file", $mini );
print
    "Compressed $total bytes to $after (saved $saved\%) in $compressed_file\n";

sub get_js_files {

    # these must load first in this order
    my @js = (
        "$js_dir/extpatches.js",      "$js_dir/air2.js",
        "$js_dir/util/ajaxlogin.js",  "$js_dir/util/console.js",
        "$js_dir/ui/panel.js",        "$js_dir/ui/dataview.js",
        "$js_dir/ui/jsondataview.js", "$js_dir/ui/window.js",
        "$js_dir/ui/createwin.js",
    );
    my %skip = map { $_ => 1 }
        ( "$js_dir/pinform.js", "$js_dir/cache/fixtures.min.js" );
    my @ui;
    my @rest;
    my %known = map { $_ => $_ } @js;
    find(
        {   wanted => sub {
                return if m/\.svn/;
                return unless m/\.js$/;
                return if exists $known{$_};
                return if exists $skip{$_};

                #print "$_\n";
                if ( m/\/ui/ and !m/ui\/(panel|dataview)/ ) {
                    push @ui, $_;
                    return;
                }
                push @rest, $_;

            },
            follow   => 0,
            no_chdir => 1,
        },
        "$js_dir"
    );
    return [ @js, @ui, @rest ];
}
