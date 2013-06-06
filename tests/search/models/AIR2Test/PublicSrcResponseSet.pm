package AIR2Test::PublicSrcResponseSet;
use strict;
use warnings;
use base qw( AIR2::PublicSrcResponseSet );
use Carp;

sub DESTROY {
    my $self = shift;

    #carp "DESTROY $self with srs_id=".$self->srs_id." and srs_src_id=".$self->srs_src_id;
    $self->delete();    # cleanup
}

1;
