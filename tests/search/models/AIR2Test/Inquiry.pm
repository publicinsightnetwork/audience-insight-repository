package AIR2Test::Inquiry;
use strict;
use warnings;
use base qw( AIR2::Inquiry );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self";
    $self->delete();    # cleanup
}

1;
