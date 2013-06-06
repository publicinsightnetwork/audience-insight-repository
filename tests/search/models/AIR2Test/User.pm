package AIR2Test::User;
use strict;
use warnings;
use base qw( AIR2::User );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
