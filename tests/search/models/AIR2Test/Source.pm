package AIR2Test::Source;
use strict;
use warnings;
use base qw( AIR2::Source );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
