package AIR2::Reader::FS;
use strict;
use warnings;
use base 'Rose::ObjectX::CAF';
use Carp;
use Path::Class::Iterator;

__PACKAGE__->mk_accessors(
    qw(
        root
        pci
        debug
        )
);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->root ) {
        croak "root required";
    }
    $self->{pci} = Path::Class::Iterator->new(
        root          => $self->root,
        show_warnings => 1,
    ) or die $Path::Class::Iterator::Err;
    return $self;
}

sub next {
    my $self = shift;
    return undef if $self->pci->done;
    return $self->pci->next;
}

1;
