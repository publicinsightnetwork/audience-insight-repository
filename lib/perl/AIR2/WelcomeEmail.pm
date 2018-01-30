package AIR2::WelcomeEmail;
use strict;
use warnings;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Emailer;
use Template;
use HTML::FormatText::Elinks;
use Path::Class;
use JSON;
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::Source;
use AIR2::SrcOrg;
use AIR2::SearchUtils;
use Search::Tools::XML;
use Search::Tools::UTF8;
use MIME::Base64;

use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(
    qw( debug strict dry_run locale source org to from log_activity ));

our $WELCOME_SENT_ACTM_ID = 18;

my %SUBJECTS = (
    'en_US' => "Welcome to \%s's Public Insight Network",
    'es_US' => "Bienvenido/a a la Red de Perspectivas Públicas de \%s",
);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    confess "source required" unless $self->source;
    confess "org required"    unless $self->org;
    return $self;
}

sub create_log_activity {
    my $self             = shift;
    my $welcome_activity = AIR2::SrcActivity->new(
        sact_actm_id  => $WELCOME_SENT_ACTM_ID,
        sact_src_id   => $self->source->src_id,
        sact_dtim     => time(),
        sact_desc     => "Welcome email sent to {SRC}",
        sact_ref_type => 'O',
        sact_xid      => $self->org->org_id,
    );

    $welcome_activity->save();
}

sub send_email {
    my $self = shift;
    my %args = @_;
    if ( $self->dry_run ) {
        $self->debug and dump \%args;
        return;
    }
    my $emailer = AIR2::Emailer->new(
        debug   => $self->debug,
        dry_run => $self->dry_run
    );
    $emailer->send(%args);
}

sub get_template_vars {
    my $self          = shift;
    my $source        = $self->source;
    my $org           = $self->org;
    my $primary_email = $source->get_primary_email;
    if ( !$primary_email ) {
        confess "No primary email defined for Source: "
            . $source->src_username;
    }

    my $newsroom = {
        name => ( $org->org_display_name || $org->org_name ),
        email    => $org->get_email(),
        msg      => ( $org->org_welcome_msg || '' ),
        uri      => ( $org->org_site_uri || $org->get_uri() ),
        logo_uri => (
                   $org->org_logo_uri
                || $org->get_logo_uri()
                || AIR2::Config::get_pin_logo_uri()
        ),
        location => $org->get_location(1),
    };

    # fallback
    $newsroom->{email} ||= 'support@publicinsightnetwork.org';

    my @related;

    # second true value to get evergreens if none explicit to org
    my $rss = $org->get_rss_feed( 5, 1 );
INQ: for my $inq (@$rss) {

        # skip any the source has already responded to
        for my $srs ( @{ $source->response_sets } ) {
            if ( $srs->srs_inq_id == $inq->inq_id ) {
                $self->debug
                    and warn "skipping already-responded to "
                    . $inq->inq_uuid . "\n";
                next INQ;
            }
        }

        push @related, { title => $inq->get_title(), uri => $inq->get_uri() };
    }

    # if we still have none,
    # use the evergreens explicitly (ok to answer those more than once)
    if ( !@related ) {
        for my $inq ( @{ AIR2::Inquiry->get_evergreens() } ) {
            push @related,
                { title => $inq->get_title(), uri => $inq->get_uri() };
        }
    }

    my $base_url = AIR2::Config::get_constant('AIR2_BASE_URL');
    $base_url =~ s,/$,,;

    my $unsubscribe_url = sprintf(
        "%s/email/unsubscribe/%s",
        $base_url,
        encode_base64(
            encode_json(
                {   email => $primary_email->sem_email,
                    org   => $org->org_name
                }
            )
        )
    );

    my $locale = $self->locale || $source->get_pref_lang || 'en_US';
    if ( $locale !~ m/_US/ ) {
        $locale = AIR2::Locale->language_to_locale($locale);
    }

    my $vars = {
        locale          => $locale,
        newsroom        => $newsroom,
        related_queries => \@related,
        pin             => {
            asset_uri   => $base_url,
            uri         => 'http://pinsight.org/',
            terms_uri   => 'http://pinsight.org/terms',
            privacy_uri => 'http://pinsight.org/privacy',
        },
        source => {
            name  => $source->get_first_last_name,
            email => $primary_email->sem_email,
        },
        unsubscribe_url => $unsubscribe_url,
    };
    $self->debug and dump $vars;
    return $vars;
}

sub send {
    my $self          = shift;
    my $template_vars = $self->get_template_vars;
    my $html          = '';
    my $template_dir
        = AIR2::Config::get_app_root()->subdir('templates')->resolve;
    my $template = Template->new(
        {   ENCODING     => 'utf8',
            INCLUDE_PATH => "$template_dir",
        }
    );
    my $template_file = 'email/welcome.html.tt';
    my $locale        = $template_vars->{locale};
    $self->debug and warn "locale == $locale";

    if ( $locale ne 'en_US' ) {
        my $locale_template_file = "email/welcome-${locale}.html.tt";
        if ( -s $template_dir->file($locale_template_file) ) {
            $template_file = $locale_template_file;
        }
    }
    $self->debug and warn "template_file == $template_file";

    $template->process( $template_file, $template_vars, \$html )
        or confess $template->error();

    my $text = HTML::FormatText::Elinks->format_string(
        Search::Tools::XML->escape_utf8($html) );
    my $to = sprintf( "%s <%s>",
        $template_vars->{source}->{name},
        $template_vars->{source}->{email} );
    my $reply_to = sprintf( "%s <%s>",
        $template_vars->{newsroom}->{name},
        $template_vars->{newsroom}->{email} );
    my $subject = to_utf8(
        sprintf(
            ( $SUBJECTS{$locale} || $SUBJECTS{'en_US'} ),
            $template_vars->{newsroom}->{name}
        )
    );
    my $sent = $self->send_email(
        html      => $html,
        text      => $text,
        from      => $self->from,
        from_name => $template_vars->{newsroom}->{name},
        reply_to  => $reply_to,
        to        => ( $self->to || $to ),
        subject   => $subject,
    );

    if ( !$self->dry_run and !$sent ) {
        warn sprintf( "Failed to send to %s: %s",
            ( $self->to || $to ), "$sent" );
    }

    if ( $sent && $self->log_activity ) {
        $self->create_log_activity();
    }

    return {
        sent => ( $sent || undef ),
        template_vars => $template_vars
    };
}

1;
