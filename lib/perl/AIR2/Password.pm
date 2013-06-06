package AIR2::Password;
use strict;
use warnings;
use Carp;
use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(qw( username phrase error ));

=head1 NAME

AIR2::Password - generate and validate passwords

=head1 SYNOPSIS

 use AIR2::Password;
 my $ap = AIR2::Password->new(username => 'joe', phrase => 'secret');
 if (!$ap->validate) {
   die "invalid password: " . $ap->error;
 }
 
 # create a random password
 my $genpass = AIR2::Password->generate('joe');
 
=head1 DESCRIPTION

Class for generating and validating passwords.

=head1 METHODS

=cut

=head2 init

Called internally.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->username ) {
        Carp::croak "username required";
    }
    if ( !$self->phrase ) {
        Carp::croak "phrase required";
    }
    return $self;
}

=head2 generate([ I<username> ])

Class method. Returns random 10-character string guaranteed
to pass all rules in validate().                           

=cut

# possible characters (omits common mistaken letters/punc)
my @charset = (
    'a' .. 'k', 'm' .. 'z', 'A' .. 'N', 'P' .. 'Z', '2' .. '9', ',',
    '?',        '.',        '$',        '!',        '+',        '=',
);

sub generate {
    my $class    = shift;
    my $username = shift || ' ';
    my $len      = shift || 10;

    my $self = $class->new( username => $username, phrase => $username );

    # set random seed
    my ( $usert, $system, $cuser, $csystem ) = times;
    srand( ( $$ ^ $usert ^ $system ^ time ) );

    my @chars;
    my $str = ' ';
    until ( $self->validate( $username, $str ) ) {
        @chars = ();
        for ( my $i = 0; $i <= ( $len - 1 ); $i++ ) {
            $chars[$i] = $charset[ int( rand($#charset) + 1 ) ];
        }
        $str = join( '', @chars );
    }

    return $str;
}

=head2 validate( I<username>, I<phrase> )

Returns true if I<phrase> represents a valid password for I<username>.

Returns false and sets error() if I<phrase> is invalid.

If I<username> or I<phrase> are missing or false, defaults
to the value set in new().                                

=cut

sub validate {
    my $self = shift;
    my $user = shift || $self->username;
    my $str  = shift || $self->phrase;

    for my $validator (qw( length nousername punc lower upper number )) {
        my $method = 'valid_' . $validator;
        if ( !$self->$method( $user, $str ) ) {
            return 0;
        }
    }

    return 1;
}

=head2 valid_length( I<username>, I<phrase> )

Returns true if I<phrase> is long enough. Sets error() and returns
false otherwise.                                                  

=cut

sub valid_length {
    my ( $self, $user, $str ) = @_;
    unless ( length($str) > 7 ) {
        $self->error('must be minimum of 8 characters');
        return 0;
    }
    return 1;
}

=head2 valid_nousername( I<username>, I<phrase> )

Returns true if I<phrase> is not based on I<username>. 
Sets error() and returns false otherwise.              

=cut

sub valid_nousername {
    my ( $self, $user, $str ) = @_;
    my $index = 0;
    my $len   = length($user);
    while ( $index <= ( $len - 3 ) ) {
        my $three = substr( $user, $index++, 3 );
        if ( $str =~ m/\Q$three\E/i ) {
            $self->error('may not be based on your username');
            return 0;
        }
    }
    return 1;
}

=head2 valid_punc( I<username>, I<phrase> )

Returns true if I<phrase> contains punctuation.
Sets error() and returns false otherwise.      

=cut

sub valid_punc {
    my ( $self, $user, $str ) = @_;
    unless ( $str =~ m/\W/ ) {
        $self->error("must contain punctuation");
        return 0;
    }
    return 1;
}

=head2 valid_lower( I<username>, I<phrase> )

Returns true if I<phrase> contains lowercase letters.
Sets error() and returns false otherwise.            

=cut

sub valid_lower {
    my ( $self, $user, $str ) = @_;
    unless ( $str =~ m/[a-z]/ ) {
        $self->error("must contain lower case");
        return 0;
    }
    return 1;
}

=head2 valid_upper( I<username>, I<phrase> )

Returns true if I<phrase> contains uppercase letters.
Sets error() and returns false otherwise.            

=cut

sub valid_upper {
    my ( $self, $user, $str ) = @_;
    unless ( $str =~ m/[A-Z]/ ) {
        $self->error("must contain UPPER case");
        return 0;
    }
    return 1;
}

=head2 valid_number( I<username>, I<phrase> )

Returns true if I<phrase> contains numeric character.
Sets error() and returns false otherwise.            

=cut

sub valid_number {
    my ( $self, $user, $str ) = @_;
    unless ( $str =~ m/\d/ ) {
        $self->error("must contain number");
        return 0;
    }
    return 1;
}

1;

__END__
