package AIR2Test::Project;
use strict;
use warnings;
use base qw( AIR2::Project );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
