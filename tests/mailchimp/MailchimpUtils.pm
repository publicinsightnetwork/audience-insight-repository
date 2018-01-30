package MailchimpUtils;
use strict;
use Test::More;
use Data::Dump qw( dump );

my $API;
my $LIST_ID = AIR2::Config::get_constant('AIR2_EMAIL_TEST_LIST_ID');

sub list_id {$LIST_ID}
sub debug { $ENV{AIR2_DEBUG} || $ENV{MAILCHIMP_DEBUG} }

sub client {
    $API ||= AIR2::Mailchimp->new( list_id => $LIST_ID, @_ );
}

sub clear_list {
    client()->delete_all();
}

sub clear_segments {
    my $res = client()->api->segments( list_id => $LIST_ID );
    for my $segment ( @{ $res->{content}->{segments} } ) {
        debug and diag("DELETE segment $segment->{name} [$segment->{id}]\n");
        my $r = client()->api->delete_segment(
            list_id    => $LIST_ID,
            segment_id => $segment->{id},
        );
        debug and diag dump $r;
    }
}

sub clear_campaigns {
    my $res = client()->api->campaigns( list_id => $LIST_ID );
    for my $campaign ( @{ $res->{content}->{campaigns} } ) {
        debug and diag("DELETE campaign $campaign->{id}");
        my $r = client()->api->delete_campaign(
            list_id     => $LIST_ID,
            campaign_id => $campaign->{id},
        );
        debug and diag dump $r;
    }
}

END {
    clear_campaigns();
    clear_segments();
    clear_list();
}

sub test_org {
    AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'mailchimp-test-org',
        @_,
    )->load_or_save();
}

sub debug_list {
    my $list_members = client()->list_members();
    unless ( ref($list_members) eq 'ARRAY' ) {
        diag( "List has zero members: " . dump($list_members) );
        return;
    }
    for my $member (@$list_members) {
        diag("$member->{email_address} => $member->{status}");
    }
}

sub list_members {
    my $list_members = client()->list_members();
    return { map { $_->{email_address} => $_->{status} } @$list_members };
}

sub compare_list {
    my $compare_to   = shift;
    my $description  = shift;
    my $list_members = list_members();
    debug() and diag dump $list_members;

    #diag dump $list_members;
    is_deeply( $compare_to, $list_members, $description );
}

1;
