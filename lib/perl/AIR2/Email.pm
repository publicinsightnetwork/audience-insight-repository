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

package AIR2::Email;
use strict;
use base qw(AIR2::DB);
use Carp;
use Email::Stuff;
use Email::Valid;
use Template;
use AIR2::SrcEmail;
use AIR2::SrcActivity;

__PACKAGE__->meta->setup(
    table => 'email',

    columns => [

        # identifiers
        email_id      => { type => 'serial',    not_null => 1 },
        email_org_id  => { type => 'integer',   not_null => 1 },
        email_usig_id => { type => 'integer',   not_null => 1 },
        email_uuid    => { type => 'character', not_null => 1, length => 12 },
        email_campaign_name =>
            { type => 'varchar', not_null => 1, length => 255 },

        # text
        email_from_name    => { type => 'varchar', length => 255 },
        email_from_email   => { type => 'varchar', length => 255 },
        email_subject_line => { type => 'varchar', length => 255 },
        email_headline     => { type => 'varchar', length => 255 },
        email_body         => { type => 'text',    length => 65535 },

        # meta
        email_type => {
            type     => 'character',
            default  => 'O',
            length   => 1,
            not_null => 1
        },
        email_status => {
            type     => 'character',
            default  => 'D',
            length   => 1,
            not_null => 1
        },
        email_report        => { type => 'text',     length   => 65535 },
        email_schedule_dtim => { type => 'datetime' },
        email_cre_user      => { type => 'integer',  not_null => 1 },
        email_upd_user      => { type => 'integer' },
        email_cre_dtim      => { type => 'datetime', not_null => 1 },
        email_upd_dtim      => { type => 'datetime' },
    ],

    primary_key_columns => ['email_id'],

    unique_key => ['email_uuid'],

    foreign_keys => [
        organization => {
            class       => 'AIR2::Organization',
            key_columns => { email_org_id => 'org_id' },
        },

        user_signature => {
            class       => 'AIR2::UserSignature',
            key_columns => { email_usig_id => 'usig_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { email_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { email_upd_user => 'user_id' },
        },
    ],

    relationships => [
        logo => {
            class      => 'AIR2::Image',
            column_map => { email_id => 'img_xid' },
            query_args => [ img_ref_type => 'E' ],
            type       => 'one to one',
        },

        email_inquiries => {
            class      => 'AIR2::EmailInquiry',
            column_map => { email_id => 'einq_email_id' },
            type       => 'one to many',
        },

        inquiries => {
            map_class => 'AIR2::EmailInquiry',
            map_from  => 'email',
            map_to    => 'inquiry',
            type      => 'many to many',
        },

        src_exports => {
            class      => 'AIR2::SrcExport',
            column_map => { email_id => 'se_email_id' },
            type       => 'one to many',
        },
    ],
);

# get a public uri to the logo
sub get_logo_uri {
    my $self     = shift;
    my $filename = shift || 'logo_medium.png';
    my $logo     = $self->logo;
    if ( !$logo || !$logo->img_uuid ) {
        return '';
    }
    my $base = AIR2::Config::get_base_url();
    $base =~ s,/$,,;
    return sprintf( "%s/img/email/%s/%s?%s",
        $base, $logo->img_uuid, $filename, $logo->img_upd_dtim->epoch );
}

# get the text of the user signature
sub get_signature {
    my $self = shift;
    if ( $self->user_signature ) {
        return $self->user_signature->usig_text;
    }
    return '';
}

# create an html email body
sub compile_html_body {
    my $self = shift;
    my $html = '';

    my $base_url = AIR2::Config::get_constant('AIR2_BASE_URL');
    $base_url =~ s,/$,,;

    my $unsubscribe_url = sprintf( "%s/email/unsubscribe", $base_url, );

    # TODO: only 1 newsroom? maybe i should just nuke this section in the tpl
    my @newsrooms;
    if ( $self->organization ) {
        push @newsrooms,
            {
            name => $self->organization->org_display_name,
            uri  => (
                       $self->organization->org_site_uri
                    || $self->organization->get_uri()
            ),
            logo_uri => (
                       $self->organization->org_logo_uri
                    || $self->organization->get_logo_uri()
            ),
            location => $self->organization->get_location(),
            };
    }

    # variables
    my $vars = {
        email => {
            title => $self->email_subject_line || '',
            logo_uri  => $self->get_logo_uri(),
            headline  => $self->email_headline || '',
            body      => $self->email_body || '',
            signature => $self->get_signature(),
        },
        newsrooms => \@newsrooms,
        pin       => {
            asset_uri   => $base_url,
            uri         => 'http://pinsight.org/',
            terms_uri   => 'http://pinsight.org/terms',
            privacy_uri => 'http://pinsight.org/privacy',
        },
        unsubscribe_url => $unsubscribe_url,
    };

    # load the template
    # TODO: should these be different for email_types?
    my $tpl_dir = AIR2::Config::get_app_root()->subdir('templates')->resolve;
    my $tpl = Template->new( { INCLUDE_PATH => "$tpl_dir" } );

    # process the template
    $tpl->process( 'email/query.html.tt', $vars, \$html )
        or die $tpl->error();

    return $html;
}

# send a preview email
sub send_preview {
    my $self = shift;

    # allow calling statically with an email_id
    unless ( ref $self ) {
        my $eml_id = shift or die "email_id required";
        $self = AIR2::Email->new( email_id => $eml_id )->load;
    }

    # validate address to send to
    my $addr = shift or die "email address required";
    if ( !Email::Valid->address($addr) ) {
        die "invalid email address '$addr'";
    }
    if ( $addr =~ m/\@nosuchemail\.org$/ ) {
        die "'$addr' is not a real email address";
    }

    # crunch the "from" address
    my $from = sprintf( "%s <%s>", $self->email_from_name,
        $self->email_from_email );

    # smtp setup
    my %mailer_args = ( Host => AIR2::Config->get_smtp_host, );
    if ( AIR2::Config->smtp_host_requires_auth ) {
        $mailer_args{username} = AIR2::Config->get_smtp_username;
        $mailer_args{password} = AIR2::Config->get_smtp_password;
    }
    my $smtp = Email::Send->new(
        {   mailer      => 'SMTP',
            mailer_args => [ %mailer_args, ]
        }
    ) or die "failed to create Email::Send::SMTP: $@ $!\n";

    # send it
    Email::Stuff->to($addr)->from($from)
        ->subject( $self->email_subject_line )
        ->html_body( $self->compile_html_body )->using($smtp)->send;
    return 1;
}

# send an email to a single source
sub send_single {
    my $self = shift;

    # allow calling statically with an email_id
    unless ( ref $self ) {
        my $eml_id = shift or die "email_id required";
        $self = AIR2::Email->new( email_id => $eml_id )->load;
    }

    # email address to send to, and optional srs_id
    my $addr   = shift or die "email address required";
    my $srs_id = shift;
    my $sem    = AIR2::SrcEmail->new( sem_email => $addr )->load;

    # make sure this is okay to send, then hit it!
    if ( $sem->sem_status ne 'G' ) {
        die "Cannot send to non-good email address '$addr'";
    }
    if ( !Email::Valid->address($addr) ) {
        die "invalid email address '$addr'";
    }
    if ( $addr =~ m/\@nosuchemail\.org$/ ) {
        die "'$addr' is not a real email address";
    }
    if ( !AIR2::Utils::allow_email_export($addr) ) {
        die "Cannot email '$addr' from a non-prod environment";
    }
    $self->send_preview($addr);

    # log src_activity
    my %actm_ids = (
        'Q' => 13,
        'F' => 29,
        'R' => 29,
        'T' => 17,
        'O' => 29,
    );
    my $now = AIR2::Utils::current_time();
    my $act = AIR2::SrcActivity->new(
        sact_src_id   => $sem->sem_src_id,
        sact_prj_id   => undef,
        sact_actm_id  => $actm_ids{ $self->email_type },
        sact_dtim     => $now,
        sact_desc     => '{USER} emailed {XID} to source {SRC}',
        sact_notes    => $srs_id ? "srs_id=$srs_id" : undef,
        sact_cre_user => $self->email_cre_user,
        sact_upd_user => $self->email_cre_user,
        sact_cre_dtim => $now,
        sact_upd_dtim => $now,
        sact_xid      => $self->email_id,
        sact_ref_type => 'E',
    );
    $act->save();

    # log export
    my $src_export = AIR2::SrcExport->new(
        se_email_id => $self->email_id,
        se_name     => 'mandrillapp',
        se_type     => 'M',
        se_status   => 'C',
        se_xid      => $srs_id ? $srs_id : $sem->sem_src_id,
        se_ref_type => $srs_id ? 'R' : 'S',
        se_cre_user => $self->email_cre_user,
        se_upd_user => $self->email_cre_user,
    );
    $src_export->save();

    # close-out this email
    $self->email_status('A');    # sent
    $self->save();

    return 1;
}

1;
