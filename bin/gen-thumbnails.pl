#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Basename;
use Path::Class;
use Image::Size;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Config;

my $debug       = $ENV{AIR2_DEBUG} || 0;
my $shared_dir  = AIR2::Config->get_shared_dir();
my $upload_base = $shared_dir->subdir('upload/Formbuilder');
my $thumb_base  = $shared_dir->subdir('mypin2/preview');

# crawl all uploaded files and make sure we have thumbnails where needed.
find(
    {   wanted   => \&check_file,
        no_chdir => 1,
    },
    $upload_base
);

sub check_file {
    return if -d $_;
    my $f = $_;
    if ( $f =~ m/[\'\"\|\s\(\)<>]/ ) {

        # bad file names (with markup) just skip
        return;
    }
    my ( $n, $d, $ext )
        = fileparse( $f, qw( JPG jpg JPEG jpeg GIF gif PDF pdf PNG png ) );
    $n =~ s/\.$//;
    if ( length($n) != 12 or $n =~ m/\W/ ) {
        $debug and print "Skipping $f\n";
        return;    # skip suspicious files
    }
    my $thumb = $f;
    $thumb =~ s,$upload_base,$thumb_base,;
    $thumb =~ s/\.$ext/.png/;
    $debug and print "file: $f\n";
    $debug and print "thumb: $thumb\n";
    file($thumb)->dir->mkpath;
    if ( $ext =~ m/(jpe?g|png|gif)/i and !-s $thumb ) {
        make_thumb( $f, $thumb );
    }
}

sub make_thumb {
    my ( $orig, $thumb ) = @_;
    my ( $w,    $h )     = imgsize($orig);
    return unless $w;
    my $cmd;
    if ( $w > 320 ) {
        $cmd = "/usr/bin/convert -size 320x240 $orig $thumb";
    }
    else {
        $cmd = "/usr/bin/convert $orig $thumb";
    }
    $debug and print "Creating $thumb\n";
    if (system($cmd)) {
        warn "$cmd failed: $!";
        system("mv $orig $orig.failed-to-convert");
    }
}
