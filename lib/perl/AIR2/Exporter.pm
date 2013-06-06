###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

package AIR2::Exporter;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base 'Rose::ObjectX::CAF';

__PACKAGE__->mk_accessors(
    qw(
        max_errors
        reader
        atomic
        debug
        user
        )
);

__PACKAGE__->mk_ro_accessors(
    qw(
        completed
        skipped
        errored
        errors
        warnings
        )
);

=head1 NAME

AIR2::Exporter - abstract base class defining the Exporter interface

=head1 SYNOPSIS

 use AIR2::Exporter;
 my $exporter = AIR2::Exporter->new(
    reader => AIR2::SrcEmail->fetch_all_iterator( 
        q => [ sem_email => { like => '%@gmail.com' } ] 
    ),
    atomic => 1,      # default
    max_errors => 1,  # conservative
 );
 $exporter->export();
 print $exporter->report;
 printf("%d errors, %d completed, %d skipped\n", 
    $exporter->errored, $exporter->completed, $exporter->skipped );

=head1 METHODS

=cut

=head2 init

Default internal instantiation method. Subclasses should override this
and not new().

=cut

sub init {
    my $self = shift;

    # defaults
    $self->{atomic}     = 1;
    $self->{max_errors} = 0;    # unlimited
    $self->{errors}     = [];
    $self->{warnings}   = [];
    $self->{errored}    = 0;
    $self->{completed}  = 0;
    $self->{skipped}    = 0;

    # setup
    $self->SUPER::init(@_);

    # check
    if ( !$self->reader ) {
        croak "reader required";
    }

    if ( !$self->user ) {
        croak "user required";
    }

    return $self;
}

=head2 run

Perform the export. Calls start_transaction() and end_transaction()
if atomic() is true. Calls do_export() on each thing returned
by reader()'s next() method.

Returns the completed count (same as completed()).

=cut

sub run {
    my $self     = shift;
    my $reader   = $self->reader;
    my $max_errs = $self->max_errors;
    my $count    = 0;
    my $skipped  = 0;
    my $errs     = 0;
    $self->start_transaction() if $self->atomic;
    while ( my $thing = $reader->next ) {
        my $ret = $self->do_export($thing);
        if ( $ret == 0 ) {
            last if $max_errs and ++$errs > $max_errs;
        }
        elsif ( $ret == -1 ) {
            $skipped++;
        }
        elsif ( $ret == -2 ) {
            # ignore
        }
        else {
            $count++;
        }
    }
    $self->{completed} = $count; 
    $self->{errored}   = $errs;
    $self->{skipped}   = $skipped;

    $self->end_transaction() if $self->atomic;

    return $count;
}

=head2 do_export( I<thing> )

Subclasses should implement this method. I<thing>
is whatever the reader() iterator returns from its
next() method.

Should return 1 on success, 0 on error, and -1 to indicate
I<thing> was skipped. If do_export() returns -2, the iteration
will be ignored (no counted).

=cut

sub do_export {

    # default no-op. Subclasses must implement
    return 1;    # success
}

=head2 start_transaction

Subclasses should implement based on their own logic.
Default just sets the internal flag indicating a transaction
is in progress.

=cut

sub start_transaction {
    my $self = shift;
    $self->{_in_transaction} = 1;
    return $self;
}

=head2 end_transaction

Subclasses should implement based on their own logic.
Default just unsets the internal flag indicating a transaction
is in progress.

=cut

sub end_transaction {
    my $self = shift;
    $self->{_in_transaction} = 0;
    return $self;
}

=head2 report

Subclasses should implement. Expectation is that this method
returns a human-friendly text string summarizing the export()
results.

=cut

sub report {
    my $self = shift;
    return sprintf(
        "%d errors, %d completed, %d skipped\n",
        scalar( @{ $self->errors } ),
        $self->completed, $self->skipped
    );
}

=head2 add_error( I<msg> )

Add I<msg> to internal errors() stack.

=cut

sub add_error {
    my $self = shift;
    my $msg = shift or croak "msg required";
    push @{ $self->{errors} }, $msg;
}

=head2 add_warning( I<msg> )

Add I<msg> to internal warnings() stack.

=cut

sub add_warning {
    my $self = shift;
    my $msg = shift or croak "msg required";
    push @{ $self->{warnings} }, $msg;
}

1;

