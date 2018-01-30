package AIR2::SrsConfirmation;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Template;
use HTML::FormatText::Elinks;
use Search::Tools::XML;
use Search::Tools::UTF8;
use AIR2::Config;
use AIR2::Emailer;
use AIR2::SrcResponseSet;
use JSON;
use Path::Class;
use MIME::Base64;

use base qw( Rose::ObjectX::CAF );

my $CONFIRMATION_SENT_ACTM_ID = 48;

my %SUBJECTS = (
    'en_US' => 'Thank you for sharing your insight with',
    'es_US' => 'Gracias por unirse a nuestra cadena',
);

__PACKAGE__->mk_accessors(
    qw( help debug strict dry_run from to log_activity ));

sub get_template_vars {
    my $self = shift;
    my $srs_uuid = shift or confess "srs_uuid required";

    # srs_uuid may be a string or a submission.json file path
    my ( $srs, $query, $locale );
    if ( -s $srs_uuid ) {
        $srs = decode_json( file($srs_uuid)->slurp );

        #dump $srs;
        $query
            = AIR2::Inquiry->new( inq_uuid => $srs->{meta}->{query} )->load;
        $locale = $query->locale_key;
    }
    else {
        $srs    = AIR2::SrcResponseSet->new( srs_uuid => $srs_uuid )->load;
        $query  = $srs->inquiry;
        $locale = $srs->source->get_pref_lang || $query->locale_key;
    }
    my @submission;
    my ( $first_name, $last_name, $email, $pref_lang );
    $first_name = '';
    $last_name  = '';
    $pref_lang  = '';
    for my $question ( @{ $query->questions_in_display_order } ) {
        my $response = get_response( $srs, $question );
        $response = '' unless defined $response;

        push @submission,
            {
            question  => $question->ques_value,
            ques_type => $question->ques_type,
            answer    => $response,
            };

        $self->debug and warn sprintf( "%s : %s %s\n",
            $question->ques_value, $question->ques_type,
            ( $question->ques_template || '[undef]' ) );

        next unless $question->ques_template;
        if ( $question->ques_template eq 'firstname' ) {
            $first_name = $response;
        }
        elsif ( $question->ques_template eq 'lastname' ) {
            $last_name = $response;
        }
        elsif ( $question->ques_template eq 'email' ) {
            $email = $response;

            #warn "found email '$email'";
        }
        elsif ( $question->ques_template eq 'preflang' ) {
            $pref_lang
                = AIR2::Locale->language_to_locale( to_utf8($response) );
        }
    }
    if ( !$self->to and !$email ) {
        confess "No email address found in submission";
    }
    my @newsrooms;
    my @related;
    my %seen_queries;
    my @orgs = @{ $query->organizations };
    for my $org (@orgs) {

        # redmine 8249 apmpin disguises global org
        if ( $org->org_id == AIR2::Config::get_global_pin_org_id() ) {
            if ( @orgs == 1 ) {
                $org = AIR2::Organization->new(
                    org_id => AIR2::Config::get_apmpin_org_id() )->load;
            }
            else {
                # ignore global pin completely if more than one org. #10548
                next;
            }
        }

        push @newsrooms,
            {
            name     => $org->org_display_name,
            uri      => ( $org->org_site_uri || $org->get_uri() ),
            logo_uri => (
                       $org->org_logo_uri
                    || $org->get_logo_uri()
                    || AIR2::Config::get_pin_logo_uri()
            ),
            location   => $org->get_location(1),
            short_name => $org->org_name,
            };

        # second true value == get evergreens if none explicitly tied to org
        my $rss = $org->get_rss_feed( 3, 1 );
        for my $inq (@$rss) {
            next if $inq->inq_uuid eq $query->inq_uuid;
            next if $seen_queries{ $inq->inq_uuid }++;
            push @related,
                { title => $inq->get_title(), uri => $inq->get_uri() };
        }
    }

    # if we have none, get the evergreens explicitly
    if ( !@related ) {
        for my $inq ( @{ AIR2::Inquiry->get_evergreens() } ) {
            push @related,
                { title => $inq->get_title(), uri => $inq->get_uri() };
        }
    }

    my $from;
    for my $author ( @{ $query->authors } ) {
        next unless $author->user->is_active;
        if ( !$author->user->get_primary_email ) {
            warn "User "
                . $author->user->get_name_first_last
                . " has no primary email defined";
            next;
        }
        $from = {
            name  => $author->user->get_name_first_last,
            email => $author->user->get_primary_email->uem_address
        };
    }
    if ( !$from ) {

        if ( $query->cre_user->is_active ) {
            my $from_email = 'support@publicinsightnetwork.org';
            if ( $query->cre_user->get_primary_email ) {
                $from_email
                    = $query->cre_user->get_primary_email->uem_address;
            }
            else {
                warn "User "
                    . $query->cre_user->get_name_first_last
                    . " has no primary email defined";
            }

            $from = {
                name  => $query->cre_user->get_name_first_last,
                email => $from_email,
            };
        }
        else {

            # grab the first one. very random.
            my $org = $orgs[0];

            # redmine 8249 apmpin disguises global org
            if ( $org->org_id == AIR2::Config::get_global_pin_org_id() ) {

                # if we have multiple orgs, grab the next one instead.
                if ( @orgs > 1 ) {
                    $org = $orgs[1];
                }
                else {
                    $org = AIR2::Organization->new(
                        org_id => AIR2::Config::get_apmpin_org_id() )->load;
                }
            }

            $from = {
                name => $org->org_display_name,
                email =>
                    ( $org->org_email || 'support@publicinsightnetwork.org' ),
            };
        }
    }

    my $base_url = AIR2::Config::get_constant('AIR2_BASE_URL');
    $base_url =~ s,/$,,;

    my $unsubscribe_url = sprintf(
        "%s/email/unsubscribe/%s",
        $base_url,
        encode_base64(
            encode_json(
                {   email => ( $email || $self->to ),
                    org => $newsrooms[0]->{short_name},
                }
            )
        )
    );

    return {
        submission => \@submission,
        pin        => {
            asset_uri   => $base_url,
            uri         => 'http://pinsight.org/',
            terms_uri   => 'http://pinsight.org/terms',
            privacy_uri => 'http://pinsight.org/privacy',
        },
        locale => $pref_lang || $locale || 'en_US',
        from => $from,
        authors   => [ map { $_->user } @{ $query->authors } ],
        newsrooms => \@newsrooms,
        query  => { uri => $query->get_uri(), uuid => $query->inq_uuid, },
        source => {
            src_id => ( ref $srs eq 'HASH' ? '' : $srs->srs_src_id ),
            name => join( ' ', $first_name, $last_name ),
            email => ( $email || $self->to ),
        },
        related_queries => \@related,
        project         => $query->find_a_project(),
        unsubscribe_url => $unsubscribe_url,
    };
}

sub get_response {
    my ( $srs, $question ) = @_;
    my $response;
    if ( ref $srs eq 'HASH' ) {

        # from json file
        $response = $srs->{ $question->ques_uuid };
        if ( ref $response ) {
            if ( ref $response eq 'ARRAY' ) {
                $response = join( ', ', @$response );
            }
            elsif ( ref $response eq 'HASH' ) {
                $response = $response->{orig_name};
            }
            else {
                #croak "Unknown response type: $response";
                # force whatever-it-is to stringify
                $response .= "";
            }
        }

    }
    else {
        $response = $srs->response_for_question($question);
        if ($response) {
            $response = $response->sr_orig_value;
        }

    }

    return $response;
}

sub send_email {
    my $self = shift;
    my %args = @_;
    if ( $self->dry_run ) {
        $self->debug and dump \%args;
        return;
    }
    my $emailer = AIR2::Emailer->new(
        dry_run => $self->dry_run,
        debug   => $self->debug
    );
    $emailer->send(%args);
}

sub send {
    my $self = shift;
    my $srs_uuid = shift or confess "srs_uuid required";

    my $template_vars = $self->get_template_vars($srs_uuid);
    my $html          = '';
    my $template_dir
        = AIR2::Config::get_app_root()->subdir('templates')->resolve;
    my $template_file = 'email/confirmation.html.tt';
    my $locale        = $template_vars->{locale};
    if ( $locale ne 'en_US' ) {
        $self->debug and warn "locale == $locale";
        my $locale_template_file = "email/confirmation-${locale}.html.tt";
        if ( -s $template_dir->file($locale_template_file) ) {
            $template_file = $locale_template_file;
            $self->debug and warn "template_file == $template_file";
        }
    }
    my $template = Template->new(
        {   ENCODING     => 'utf8',
            INCLUDE_PATH => "$template_dir",
        }
    );

    $template->process( $template_file, $template_vars, \$html )
        or confess $template->error();

    my $text = HTML::FormatText::Elinks->format_string(
        Search::Tools::XML->escape_utf8($html) );
    my $to = sprintf( "%s <%s>",
        $template_vars->{source}->{name},
        $template_vars->{source}->{email} );
    my $from = sprintf( "%s <%s>",
        $template_vars->{from}->{name},
        $template_vars->{from}->{email} );
    my $subject = to_utf8(
        sprintf( "%s %s!",
            ( $SUBJECTS{$locale} || $SUBJECTS{"en_US"} ),
            $template_vars->{newsrooms}->[0]->{name} )
    );
    my $sent = $self->send_email(
        html     => $html,
        text     => $text,
        reply_to => ( $self->from || $from ),
        to       => ( $self->to || $to ),
        subject  => $subject,
    );

    if ( !$self->dry_run and !$sent ) {
        warn "$sent";
    }

    if ( $sent && $self->log_activity ) {
        $self->create_activity($template_vars);
    }

    return { sent => $sent, template_vars => $template_vars };
}

sub create_activity {
    my $self = shift;
    my $vars = shift or confess "vars required";
    if ( $vars->{source}->{src_id} ) {
        my $sact = AIR2::SrcActivity->new(
            sact_actm_id => $CONFIRMATION_SENT_ACTM_ID,
            sact_src_id  => $vars->{source}->{src_id},
            sact_dtim    => time(),
            sact_desc    => "Submission confirmation email sent to {SRC}",
            sact_prj_id  => $vars->{project}->{prj_id},
        );

        $sact->save();
    }
    else {
        warn "Can't log activity since we do not have a src_id\n";
    }
}

1;
