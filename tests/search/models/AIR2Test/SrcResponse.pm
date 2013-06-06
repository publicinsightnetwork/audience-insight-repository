package AIR2Test::SrcResponse;
use strict;
use warnings;
use base qw( AIR2::SrcResponse );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
