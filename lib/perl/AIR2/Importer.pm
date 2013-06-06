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

package AIR2::Importer;
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
        dry_run
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

AIR2::Importer - abstract base class defining the Importer interface

=head1 SYNOPSIS

 use AIR2::Importer;
 my $importer = AIR2::Importer->new(
    reader      => MyReader->new( url => 'interestingstuff.com',
    atomic      => 1,  # default
    max_errors  => 1,  # conservative
 );
 $importer->run();
 print $importer->report;
 printf("%d errors, %d completed, %d skipped\n", 
    $importer->errored, $importer->completed, $importer->skipped );

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
    if ( !$self->dry_run and !$self->reader ) {
        croak "reader required";
    }

    if ( !$self->user ) {
        croak "user required";
    }

    return $self;
}

=head2 run

Perform the import. Calls start_transaction() and end_transaction()
if atomic() is true. Calls do_import() on each thing returned
by writer()'s next() method.

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
        my $ret = $self->do_import($thing);
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

=head2 do_import( I<thing> )

Subclasses should implement this method. I<thing>
is whatever the reader() iterator returns from its
next() method.

Should return 1 on success, 0 on error, and -1 to indicate
I<thing> was skipped. If do_export() returns -2, the iteration
will be ignored (no counted).

=cut

sub do_import {

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

=head2 reconcile_existing_source( I<tank_source> )

Utility method intended for use and extension by
subclasses.

The base method implementation looks at the C<src_username>
and C<sem_email> values on I<tank_source> and tries to match
them against an existing AIR2::Source record. If a match is found,
the C<src_id> and C<src_uuid> values are set on I<tank_source>
so that the Discriminator correctly merges incoming records.

Returns the matching Source on match, false (0) on no match.

=cut

sub reconcile_existing_source {
    my $self = shift;
    my $tsrc = shift;
    if ( !$tsrc or !ref($tsrc) or !$tsrc->isa('AIR2::TankSource') ) {
        croak "AIR2::TankSource object required";
    }
    my $email = $tsrc->src_username || $tsrc->sem_email;
    if ( !$email ) {
        return 0;
    }

    # NOTE that in both cases we re-set the src_username value on the
    # TankSource, so that it doesn't cause unnecessary conflict.
    # The Source->src_username is not used for anything, but is guaranteed
    # to be unique and is, by convention, the same as the primary email,
    # but is not required to be.

    # easy match
    my $src = AIR2::Source->new( src_username => $email );
    $src->load_speculative();
    if ( $src->src_id ) {
        $tsrc->src_id( $src->src_id );
        $tsrc->src_uuid( $src->src_uuid );
        $tsrc->src_username( $src->src_username );
        return $src;
    }

    # a little harder
    my $sem = AIR2::SrcEmail->new( sem_email => $email );
    $sem->load_speculative();
    if ( $sem->sem_id ) {
        $tsrc->src_id( $sem->source->src_id );
        $tsrc->src_uuid( $sem->source->src_uuid );
        $tsrc->src_username( $sem->source->src_username );
        return $sem->source;
    }

    # no love
    return 0;
}

=head2 report

Subclasses should implement. Expectation is that this method
returns a human-friendly text string summarizing the export()
results.

=cut

sub report {
    my $self = shift;
    return sprintf( "%d errors, %d completed, %d skipped\n",
        $self->has_errors, $self->completed, $self->skipped );
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

=head2 has_errors

Returns number of errors.

=cut

sub has_errors {
    my $self = shift;
    return scalar @{ $self->{errors} };
}

=head2 has_warnings

Returns number of warnings.

=cut

sub has_warnings {
    my $self = shift;
    return scalar @{ $self->{warnings} };
}

1;
