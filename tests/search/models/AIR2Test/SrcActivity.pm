package AIR2Test::SrcActivity;
use strict;
use warnings;
use base qw( AIR2::SrcActivity );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
