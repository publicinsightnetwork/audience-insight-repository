#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 6;
use FindBin;
use Try::Tiny;
use lib "$FindBin::Bin/../lib/perl";

use AIR2::Emailer;
use Email::Sender::Transport::Test;

my $test_transport = Email::Sender::Transport::Test->new;
my $bad_smtp_transport
    = Email::Sender::Transport::SMTP->new( host => 'nosuchhost', );

ok( my $emailer = AIR2::Emailer->new( debug => $ENV{'AIR2_DEBUG'} ),
    "Emailer->new" );
ok( my $resp = $emailer->send(
        to        => 'foo@example.com',
        subject   => 'test',
        text      => 'hello world',
        html      => '<p>hello world</p>',
        transport => $test_transport,
    ),
    "emailer->send"
);

#diag( dump $transport );

my $sender     = AIR2::Config::get_constant('AIR2_SUPPORT_EMAIL');
my @deliveries = $test_transport->deliveries;
like( $deliveries[0]->{email}->get_header("From"),
    qr/$sender/, "email defaults to sender == support" );

# live test with bad From

try {
    my $live_resp = $emailer->send(
        to      => 'foo@example.com',
        subject => 'test rejection',
        text    => 'hello world',
        from    => 'badsender@nosuchemail.org',
    );
}
catch {
    ok( $_, "live send with bad From" );
};

# trigger error
$resp = $emailer->send(
    transport => $bad_smtp_transport,
    to        => 'foo@example.com',
    subject   => 'test',
    text      => 'die!'
);
is( $resp, 0, "got false response on bad send" );

#diag( $emailer->error );
like(
    $emailer->error,
    qr/unable to establish SMTP connection/i,
    "expected SMTP error"
);
