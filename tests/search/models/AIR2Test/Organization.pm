package AIR2Test::Organization;
use strict;
use warnings;
use base qw( AIR2::Organization );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}
1;
