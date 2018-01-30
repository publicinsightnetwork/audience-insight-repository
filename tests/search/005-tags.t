#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use Data::Dump qw( dump );
use AIR2Test::Inquiry;

ok( my $inq
        = AIR2Test::Inquiry->new( inq_title => 'test inquiry tags' )->save,
    "Inquiry"
);
ok( my $tag = AIR2::Tag->new(
        tag_xid      => $inq->inq_id,
        tag_tm_id    => 1,
        tag_ref_type => 'I',
        )->save,
    "Tag"
);
ok( my $tags = $inq->get_tags, "get_tags" );
is( scalar @$tags, 1, "one tag" );
ok( $tags->[0]->isa('AIR2::TagMaster'), "isa TagMaster" );
is( $tag->tagmaster->tm_id, $tags->[0]->tm_id, 'got the tag' );
