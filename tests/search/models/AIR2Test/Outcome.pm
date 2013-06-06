package AIR2Test::Outcome;
use strict;
use warnings;
use base qw( AIR2::Outcome );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}
1;
