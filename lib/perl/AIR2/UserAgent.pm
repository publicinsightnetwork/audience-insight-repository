package AIR2::UserAgent;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Sub::Retry;
use base 'LWP::UserAgent';

my $retries            = 3;
my $wait_between_tries = 5;

sub request {
    my $self = shift;
    my @args = @_;
    retry $retries, $wait_between_tries, sub {
        $self->SUPER::request(@args);
    };
}

1;
