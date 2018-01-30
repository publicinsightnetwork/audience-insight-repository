package AIR2::Emailer;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Email::Stuffer;
use Email::Sender::Transport::SMTP;
use AIR2::Config;

use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(qw( debug strict dry_run ));

sub sender_email {
    my $self = shift;
    my $name = shift || 'Public Insight Network';
    sprintf( "%s <%s>",
        $name, AIR2::Config::get_constant('AIR2_SUPPORT_EMAIL') );
}

sub send {
    my $self = shift;
    my %args = @_;
    if ( $self->dry_run ) {
        $self->debug and dump \%args;
        return;
    }
    my $from = $args{from} || $self->sender_email( $args{from_name} );
    my $stuff
        = Email::Stuffer->to( $args{to} )
        ->header( 'Reply-To' => $args{reply_to} || $from )->from($from)
        ->subject( $args{subject} );
    if ( $args{cc} ) {
        $stuff->cc( $args{cc} );
    }
    if ( $args{text} ) {
        $stuff->text_body( $args{text} );
    }
    if ( $args{html} ) {
        $stuff->html_body( $args{html} );
    }
    if ( $args{attach} ) {
        $stuff->attach( @{ $args{attach} } );
    }
    my $smtp = $args{transport} || _smtp_transport();

    my $result = $stuff->transport($smtp)->send();

    $self->debug and warn $result;

    return $result;
}

sub _smtp_transport {
    my ( $host, $port ) = split( ":", AIR2::Config->get_smtp_host );
    my %mailer_args = ( host => $host, port => $port, );
    if ( AIR2::Config->smtp_host_requires_auth ) {
        $mailer_args{sasl_username} = AIR2::Config->get_smtp_username;
        $mailer_args{sasl_password} = AIR2::Config->get_smtp_password;
    }
    Email::Sender::Transport::SMTP->new(%mailer_args)
        or confess "failed to create Email::Sender::Transport::SMTP: $@ $!\n";
}

1;
