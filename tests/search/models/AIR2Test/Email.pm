package AIR2Test::Email;
use strict;
use warnings;
use base qw( AIR2::Email );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
