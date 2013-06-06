package AIR2::CSVReader;
use strict;
use warnings;
use Text::CSV_XS;
use POSIX;
use IO::String;
use Carp;
use Data::Dump qw( dump );

sub new {
    my $class     = shift;
    my $input     = shift or die "CSV file handle or string required";
    my $no_header = shift || 0;

    # decipher input
    my $fh;
    my $fstr;
    if ( ref($input) eq 'GLOB' ) {
        $fh = $input;
    }
    else {
        $fstr = IO::String->new($input);
    }

    # setup internal CSV parser and create self
    my $csv = Text::CSV_XS->new( { binary => 1 } )
        or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
    my $self = {
        _fileHandle => $fh,
        _fileString => $fstr,
        _parser     => $csv,
        _headers    => undef,
        _curr       => undef,
    };
    bless $self, $class;

    # optionally parse headers
    my $hdrs;
    unless ($no_header) {
        $hdrs = $self->_read_next_line();
        $self->{_parser}->column_names($hdrs);

        for ( my $i = 0; $i < @{$hdrs}; $i++ ) {
            my $name = $hdrs->[$i];
            $self->{_headers}->{$name} = $i;
        }
    }

    return $self;
}

sub _read_next_line {
    my $self = shift;
    my $row;
    if ( $self->{_fileHandle} ) {
        $row = $self->{_parser}->getline( $self->{_fileHandle} );
    }
    else {
        $row = $self->{_parser}->getline( $self->{_fileString} );

        #die "TODO: string parsing\n";
    }

    return $row;
}

sub next {
    my $self = shift;
    $self->{_curr} = $self->_read_next_line();

    # return hash, if we have headers
    if ( $self->{_curr} && $self->{_headers} ) {
        my $data;
        foreach my $key ( keys %{ $self->{_headers} } ) {
            my $idx = $self->{_headers}->{$key};
            $data->{$key} = $self->{_curr}->[$idx];
        }
        return $data;
    }
    else {
        return $self->{_curr};
    }
}

sub get_column {
    my $self = shift;
    my $col = shift or die "Column name/index required";
    if ( isdigit($col) ) {
        return $self->{_curr}->[$col];
    }
    else {
        if ( defined $self->{_headers}->{$col} ) {
            my $idx = $self->{_headers}->{$col};
            return $self->{_curr}->[$idx];
        }
        else {
            die "Unknown column $col\n";
        }
    }
}

sub get_headers {
    my $self = shift;
    return $self->{_headers};
}

1;
