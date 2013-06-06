#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::SrcResponse;

my $upload_base = '/opt/pij/shared/upload/Formbuilder';

# find all responses claiming to be files and make sure they exist
my $resps = AIR2::SrcResponse->fetch_all_iterator(
    require_objects => [qw( question )],
    query           => [ 'question.ques_type' => 'F', ]
);

while ( my $sr = $resps->next ) {
    next unless $sr->sr_orig_value;

    my $orig = sprintf( "%s/%s", $upload_base, $sr->sr_orig_value );

    if ( !-s $orig ) {
        printf( "%s : does not exist\n", $orig );
    }

}
