package AIR2::Reader;
use strict;
use warnings;
use base 'Rose::ObjectX::CAF';
use Carp;

__PACKAGE__->mk_accessors(
    qw(
        sth
        )
);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->sth ) {
        croak "sth required";
    }
    return $self;
}

sub next { return shift->sth->fetchrow_hashref }

1;
