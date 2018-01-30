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

package AIR2::User;
use strict;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );
use AIR2::Password;
use AIR2::AuthTkt;
use AIR2::Config;
use JSON;
use Crypt::Eksblowfish::Bcrypt qw( bcrypt_hash en_base64 de_base64 );

__PACKAGE__->meta->setup(
    table => 'user',

    columns => [
        user_id   => { type => 'serial',    not_null => 1 },
        user_uuid => { type => 'character', length   => 12, not_null => 1 },
        user_username => { type => 'varchar', length => 255 },

        user_first_name => { type => 'varchar', length => 64, not_null => 1 },
        user_last_name  => { type => 'varchar', length => 64, not_null => 1 },
        user_summary => { type => 'varchar', length => 255 },
        user_desc    => { type => 'text',    length => 65535 },

        user_password           => { type => 'character', length => 32 },
        user_encrypted_password => { type => 'varchar',   length => 255 },
        user_pswd_dtim          => { type => 'datetime' },

        user_pref => { type => 'text', length => 65535 },
        user_type => {
            type     => 'character',
            length   => 1,
            default  => 'A',
            not_null => 1
        },
        user_status => {
            type     => 'character',
            length   => 1,
            default  => 'A',
            not_null => 1
        },

        user_login_dtim => { type => 'datetime' },
        user_cre_user   => { type => 'integer' },
        user_upd_user   => { type => 'integer' },
        user_cre_dtim   => { type => 'datetime', not_null => 1 },
        user_upd_dtim   => { type => 'datetime' },
    ],

    primary_key_columns => ['user_id'],

    unique_keys => [ ['user_username'], ['user_uuid'], ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { user_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { user_upd_user => 'user_id' },
        },
    ],

    relationships => [
        activity_master => {
            class      => 'AIR2::ActivityMaster',
            column_map => { user_id => 'actm_cre_user' },
            type       => 'one to many',
        },

        activity_master_updated => {
            class      => 'AIR2::ActivityMaster',
            column_map => { user_id => 'actm_upd_user' },
            type       => 'one to many',
        },

        admin_role => {
            class      => 'AIR2::AdminRole',
            column_map => { user_id => 'ar_cre_user' },
            type       => 'one to many',
        },

        admin_role_updated => {
            class      => 'AIR2::AdminRole',
            column_map => { user_id => 'ar_upd_user' },
            type       => 'one to many',
        },

        avatar => {
            class      => 'AIR2::Image',
            column_map => { user_id => 'img_xid' },
            query_args => [ img_ref_type => 'A' ],
            type       => 'one to one',
        },

        bins => {
            class      => 'AIR2::Bin',
            column_map => { user_id => 'bin_user_id' },
            type       => 'one to many',
        },

        code_master => {
            class      => 'AIR2::CodeMaster',
            column_map => { user_id => 'cm_cre_user' },
            type       => 'one to many',
        },

        code_master_updated => {
            class      => 'AIR2::CodeMaster',
            column_map => { user_id => 'cm_upd_user' },
            type       => 'one to many',
        },

        fact => {
            class      => 'AIR2::Fact',
            column_map => { user_id => 'fact_cre_user' },
            type       => 'one to many',
        },

        fact_updated => {
            class      => 'AIR2::Fact',
            column_map => { user_id => 'fact_upd_user' },
            type       => 'one to many',
        },

        fact_value => {
            class      => 'AIR2::FactValue',
            column_map => { user_id => 'fv_cre_user' },
            type       => 'one to many',
        },

        fact_value_updated => {
            class      => 'AIR2::FactValue',
            column_map => { user_id => 'fv_upd_user' },
            type       => 'one to many',
        },

        inq_outcome => {
            class      => 'AIR2::InqOutcome',
            column_map => { user_id => 'iout_cre_user' },
            type       => 'one to many',
        },

        inq_outcome_updated => {
            class      => 'AIR2::InqOutcome',
            column_map => { user_id => 'iout_upd_user' },
            type       => 'one to many',
        },

        inquiry => {
            class      => 'AIR2::Inquiry',
            column_map => { user_id => 'inq_cre_user' },
            type       => 'one to many',
        },

        inquiry_updated => {
            class      => 'AIR2::Inquiry',
            column_map => { user_id => 'inq_upd_user' },
            type       => 'one to many',
        },

        inquiries_as_author => {
            map_class  => 'AIR2::InquiryUser',
            map_from   => 'user',
            map_to     => 'inquiry',
            type       => 'many to many',
            query_args => [ iu_type => 'A' ],
        },

        inquiries_as_watcher => {
            map_class  => 'AIR2::InquiryUser',
            map_from   => 'user',
            map_to     => 'inquiry',
            type       => 'many to many',
            query_args => [ iu_type => 'W' ],
        },

        iptc_master => {
            class      => 'AIR2::IptcMaster',
            column_map => { user_id => 'iptc_cre_user' },
            type       => 'one to many',
        },

        iptc_master_updated => {
            class      => 'AIR2::IptcMaster',
            column_map => { user_id => 'iptc_upd_user' },
            type       => 'one to many',
        },

        org_sys_id => {
            class      => 'AIR2::OrgSysId',
            column_map => { user_id => 'osid_cre_user' },
            type       => 'one to many',
        },

        org_sys_id_updated => {
            class      => 'AIR2::OrgSysId',
            column_map => { user_id => 'osid_upd_user' },
            type       => 'one to many',
        },

        organization => {
            class      => 'AIR2::Organization',
            column_map => { user_id => 'org_cre_user' },
            type       => 'one to many',
        },

        organization_updated => {
            class      => 'AIR2::Organization',
            column_map => { user_id => 'org_upd_user' },
            type       => 'one to many',
        },

        organizations => {
            map_class => 'AIR2::UserOrg',
            map_from  => 'user',
            map_to    => 'organization',
            type      => 'many to many',
        },

        outcome => {
            class      => 'AIR2::Outcome',
            column_map => { user_id => 'out_cre_user' },
            type       => 'one to many',
        },

        outcome_updated => {
            class      => 'AIR2::Outcome',
            column_map => { user_id => 'out_upd_user' },
            type       => 'one to many',
        },

        preference_type => {
            class      => 'AIR2::PreferenceType',
            column_map => { user_id => 'pt_cre_user' },
            type       => 'one to many',
        },

        preference_type_updated => {
            class      => 'AIR2::PreferenceType',
            column_map => { user_id => 'pt_upd_user' },
            type       => 'one to many',
        },

        preference_type_value => {
            class      => 'AIR2::PreferenceTypeValue',
            column_map => { user_id => 'ptv_cre_user' },
            type       => 'one to many',
        },

        preference_type_value_updated => {
            class      => 'AIR2::PreferenceTypeValue',
            column_map => { user_id => 'ptv_upd_user' },
            type       => 'one to many',
        },

        project => {
            class      => 'AIR2::Project',
            column_map => { user_id => 'prj_cre_user' },
            type       => 'one to many',
        },

        project_activity => {
            class      => 'AIR2::ProjectActivity',
            column_map => { user_id => 'pa_cre_user' },
            type       => 'one to many',
        },

        project_activity_updated => {
            class      => 'AIR2::ProjectActivity',
            column_map => { user_id => 'pa_upd_user' },
            type       => 'one to many',
        },

        project_annotation => {
            class      => 'AIR2::ProjectAnnotation',
            column_map => { user_id => 'prjan_cre_user' },
            type       => 'one to many',
        },

        project_annotation_updated => {
            class      => 'AIR2::ProjectAnnotation',
            column_map => { user_id => 'prjan_upd_user' },
            type       => 'one to many',
        },

        project_inquiry => {
            class      => 'AIR2::ProjectInquiry',
            column_map => { user_id => 'pinq_cre_user' },
            type       => 'one to many',
        },

        project_inquiry_updated => {
            class      => 'AIR2::ProjectInquiry',
            column_map => { user_id => 'pinq_upd_user' },
            type       => 'one to many',
        },

        project_message => {
            class      => 'AIR2::ProjectMessage',
            column_map => { user_id => 'pm_cre_user' },
            type       => 'one to many',
        },

        project_message_updated => {
            class      => 'AIR2::ProjectMessage',
            column_map => { user_id => 'pm_upd_user' },
            type       => 'one to many',
        },

        project_updated => {
            class      => 'AIR2::Project',
            column_map => { user_id => 'prj_upd_user' },
            type       => 'one to many',
        },

        project_org => {
            class      => 'AIR2::ProjectOrg',
            column_map => { user_id => 'porg_cre_user' },
            type       => 'one to many',
        },

        project_org_objects => {
            class      => 'AIR2::ProjectOrg',
            column_map => { user_id => 'porg_contact_user_id' },
            type       => 'one to many',
        },

        project_org_updated => {
            class      => 'AIR2::ProjectOrg',
            column_map => { user_id => 'porg_upd_user' },
            type       => 'one to many',
        },

        prj_outcome => {
            class      => 'AIR2::PrjOutcome',
            column_map => { user_id => 'pout_cre_user' },
            type       => 'one to many',
        },

        prj_outcome_updated => {
            class      => 'AIR2::PrjOutcome',
            column_map => { user_id => 'pout_upd_user' },
            type       => 'one to many',
        },

        question => {
            class      => 'AIR2::Question',
            column_map => { user_id => 'ques_cre_user' },
            type       => 'one to many',
        },

        question_updated => {
            class      => 'AIR2::Question',
            column_map => { user_id => 'ques_upd_user' },
            type       => 'one to many',
        },

        signatures => {
            class      => 'AIR2::UserSignature',
            column_map => { user_id => 'usig_user_id' },
            type       => 'one to many',
        },

        sma_annotation => {
            class      => 'AIR2::SmaAnnotation',
            column_map => { user_id => 'smaan_cre_user' },
            type       => 'one to many',
        },

        sma_annotation_updated => {
            class      => 'AIR2::SmaAnnotation',
            column_map => { user_id => 'smaan_upd_user' },
            type       => 'one to many',
        },

        source => {
            class      => 'AIR2::Source',
            column_map => { user_id => 'src_cre_user' },
            type       => 'one to many',
        },

        source_updated => {
            class      => 'AIR2::Source',
            column_map => { user_id => 'src_upd_user' },
            type       => 'one to many',
        },

        sr_annotation => {
            class      => 'AIR2::SrAnnotation',
            column_map => { user_id => 'sran_cre_user' },
            type       => 'one to many',
        },

        sr_annotation_updated => {
            class      => 'AIR2::SrAnnotation',
            column_map => { user_id => 'sran_upd_user' },
            type       => 'one to many',
        },

        src_activity => {
            class      => 'AIR2::SrcActivity',
            column_map => { user_id => 'sact_cre_user' },
            type       => 'one to many',
        },

        src_activity_updated => {
            class      => 'AIR2::SrcActivity',
            column_map => { user_id => 'sact_upd_user' },
            type       => 'one to many',
        },

        src_alias => {
            class      => 'AIR2::SrcAlias',
            column_map => { user_id => 'sa_cre_user' },
            type       => 'one to many',
        },

        src_alias_updated => {
            class      => 'AIR2::SrcAlias',
            column_map => { user_id => 'sa_upd_user' },
            type       => 'one to many',
        },

        src_annotation => {
            class      => 'AIR2::SrcAnnotation',
            column_map => { user_id => 'srcan_cre_user' },
            type       => 'one to many',
        },

        src_annotation_updated => {
            class      => 'AIR2::SrcAnnotation',
            column_map => { user_id => 'srcan_upd_user' },
            type       => 'one to many',
        },

        src_email => {
            class      => 'AIR2::SrcEmail',
            column_map => { user_id => 'sem_cre_user' },
            type       => 'one to many',
        },

        src_email_updated => {
            class      => 'AIR2::SrcEmail',
            column_map => { user_id => 'sem_upd_user' },
            type       => 'one to many',
        },

        src_fact => {
            class      => 'AIR2::SrcFact',
            column_map => { user_id => 'sf_cre_user' },
            type       => 'one to many',
        },

        src_fact_updated => {
            class      => 'AIR2::SrcFact',
            column_map => { user_id => 'sf_upd_user' },
            type       => 'one to many',
        },

        src_inquiry => {
            class      => 'AIR2::SrcInquiry',
            column_map => { user_id => 'si_cre_user' },
            type       => 'one to many',
        },

        src_inquiry_updated => {
            class      => 'AIR2::SrcInquiry',
            column_map => { user_id => 'si_upd_user' },
            type       => 'one to many',
        },

        src_mail_address => {
            class      => 'AIR2::SrcMailAddress',
            column_map => { user_id => 'smadd_cre_user' },
            type       => 'one to many',
        },

        src_mail_address_updated => {
            class      => 'AIR2::SrcMailAddress',
            column_map => { user_id => 'smadd_upd_user' },
            type       => 'one to many',
        },

        src_media_asset => {
            class      => 'AIR2::SrcMediaAsset',
            column_map => { user_id => 'sma_cre_user' },
            type       => 'one to many',
        },

        src_media_asset_updated => {
            class      => 'AIR2::SrcMediaAsset',
            column_map => { user_id => 'sma_upd_user' },
            type       => 'one to many',
        },

        src_org => {
            class      => 'AIR2::SrcOrg',
            column_map => { user_id => 'so_cre_user' },
            type       => 'one to many',
        },

        src_org_updated => {
            class      => 'AIR2::SrcOrg',
            column_map => { user_id => 'so_upd_user' },
            type       => 'one to many',
        },

        src_outcome => {
            class      => 'AIR2::SrcOutcome',
            column_map => { user_id => 'sout_cre_user' },
            type       => 'one to many',
        },

        src_outcome_updated => {
            class      => 'AIR2::SrcOutcome',
            column_map => { user_id => 'sout_upd_user' },
            type       => 'one to many',
        },

        src_phone_number => {
            class      => 'AIR2::SrcPhoneNumber',
            column_map => { user_id => 'sph_cre_user' },
            type       => 'one to many',
        },

        src_phone_number_updated => {
            class      => 'AIR2::SrcPhoneNumber',
            column_map => { user_id => 'sph_upd_user' },
            type       => 'one to many',
        },

        src_pref_org => {
            class      => 'AIR2::SrcPrefOrg',
            column_map => { user_id => 'spo_cre_user' },
            type       => 'one to many',
        },

        src_pref_org_updated => {
            class      => 'AIR2::SrcPrefOrg',
            column_map => { user_id => 'spo_upd_user' },
            type       => 'one to many',
        },

        src_preference => {
            class      => 'AIR2::SrcPreference',
            column_map => { user_id => 'sp_cre_user' },
            type       => 'one to many',
        },

        src_preference_updated => {
            class      => 'AIR2::SrcPreference',
            column_map => { user_id => 'sp_upd_user' },
            type       => 'one to many',
        },

        src_relationship => {
            class      => 'AIR2::SrcRelationship',
            column_map => { user_id => 'srel_cre_user' },
            type       => 'one to many',
        },

        src_relationship_updated => {
            class      => 'AIR2::SrcRelationship',
            column_map => { user_id => 'srel_upd_user' },
            type       => 'one to many',
        },

        src_response => {
            class      => 'AIR2::SrcResponse',
            column_map => { user_id => 'sr_cre_user' },
            type       => 'one to many',
        },

        src_response_updated => {
            class      => 'AIR2::SrcResponse',
            column_map => { user_id => 'sr_upd_user' },
            type       => 'one to many',
        },

        src_response_set => {
            class      => 'AIR2::SrcResponseSet',
            column_map => { user_id => 'srs_cre_user' },
            type       => 'one to many',
        },

        src_response_set_updated => {
            class      => 'AIR2::SrcResponseSet',
            column_map => { user_id => 'srs_upd_user' },
            type       => 'one to many',
        },

        src_uri => {
            class      => 'AIR2::SrcUri',
            column_map => { user_id => 'suri_cre_user' },
            type       => 'one to many',
        },

        src_uri_updated => {
            class      => 'AIR2::SrcUri',
            column_map => { user_id => 'suri_upd_user' },
            type       => 'one to many',
        },

        srs_annotation => {
            class      => 'AIR2::SrsAnnotation',
            column_map => { user_id => 'srsan_cre_user' },
            type       => 'one to many',
        },

        srs_annotation_updated => {
            class      => 'AIR2::SrsAnnotation',
            column_map => { user_id => 'srsan_upd_user' },
            type       => 'one to many',
        },

        system_message => {
            class      => 'AIR2::SystemMessage',
            column_map => { user_id => 'smsg_cre_user' },
            type       => 'one to many',
        },

        system_message_updated => {
            class      => 'AIR2::SystemMessage',
            column_map => { user_id => 'smsg_upd_user' },
            type       => 'one to many',
        },

        tag => {
            class      => 'AIR2::Tag',
            column_map => { user_id => 'tag_cre_user' },
            type       => 'one to many',
        },

        tag_master => {
            class      => 'AIR2::TagMaster',
            column_map => { user_id => 'tm_cre_user' },
            type       => 'one to many',
        },

        tag_master_updated => {
            class      => 'AIR2::TagMaster',
            column_map => { user_id => 'tm_upd_user' },
            type       => 'one to many',
        },

        tag_updated => {
            class      => 'AIR2::Tag',
            column_map => { user_id => 'tag_upd_user' },
            type       => 'one to many',
        },

        user => {
            class      => 'AIR2::User',
            column_map => { user_id => 'user_cre_user' },
            type       => 'one to many',
        },

        user_email_address => {
            class      => 'AIR2::UserEmailAddress',
            column_map => { user_id => 'uem_user_id' },
            type       => 'one to many',
        },

        user_updated => {
            class      => 'AIR2::User',
            column_map => { user_id => 'user_upd_user' },
            type       => 'one to many',
        },

        user_orgs_created => {
            class      => 'AIR2::UserOrg',
            column_map => { user_id => 'uo_cre_user' },
            type       => 'one to many',
        },

        user_orgs => {
            class      => 'AIR2::UserOrg',
            column_map => { user_id => 'uo_user_id' },
            type       => 'one to many',
        },

        user_orgs_updated => {
            class      => 'AIR2::UserOrg',
            column_map => { user_id => 'uo_upd_user' },
            type       => 'one to many',
        },

        user_phone_number => {
            class      => 'AIR2::UserPhoneNumber',
            column_map => { user_id => 'uph_user_id' },
            type       => 'one to many',
        },

        user_uri => {
            class      => 'AIR2::UserUri',
            column_map => { user_id => 'uuri_user_id' },
            type       => 'one to many',
        },
    ],
);

sub is_active {
    my $self = shift;
    return $self->user_status =~ m/^[AP]$/;
}

sub find_by_email {
    my $self  = shift;
    my $email = shift or croak "email required";
    my $user  = AIR2::User->new( user_username => $email );
    if ( $user->load_speculative ) {
        return $user;
    }
    my $user_emails = AIR2::UserEmailAddress->fetch_all(
        query => [ uem_address => $email ] );
    if ( $user_emails && @$user_emails == 1 ) {
        return $user_emails->[0]->user;
    }
    return undef;
}

sub get_signature {
    my $self     = shift;
    my $inq_uuid = shift;    # undef ok

    if ( !$self->has_related('signatures') ) {
        my $primary_email
            = $self->get_primary_email
            ? $self->get_primary_email->uem_address
            : $self->user_username;
        return {
            name  => $self->get_name_first_last,
            title => $self->get_title(),
            email => $primary_email,
            phone => (
                  $self->get_primary_phone
                ? $self->get_primary_phone->as_string()
                : ''
            ),
        };
    }

    # TODO how to determine which sig to use?
    return $self->signatures->[0];
}

sub get_title {
    my $self = shift;
    return $self->user_summary;
}

sub get_avatar_uri {
    my $self     = shift;
    my $filename = shift || 'avatar_thumb.png';
    my $base     = AIR2::Config::get_constant('AIR2_BASE_URL');
    my $avatar   = $self->avatar;
    return unless $avatar;
    return sprintf( "%simg/user/%s/%s?%s",
        $base, $avatar->img_uuid, $filename, $avatar->img_upd_dtim->epoch );
}

sub get_name {
    my $self = shift;
    return join( ', ',
        grep {defined} ( $self->user_last_name, $self->user_first_name ) );
}

sub get_name_first_last {
    my $self = shift;
    return join( ' ',
        grep {defined} ( $self->user_first_name, $self->user_last_name ) );
}

sub get_primary_email {
    my $self = shift;
    return $self->find_user_email_address( q => [ uem_primary_flag => 1 ] )
        ->[0];
}

sub set_primary_email {
    my $self = shift;
    my $address = shift or confess "address required";
    $self->user_email_address(
        [   {   uem_address      => $address,
                uem_primary_flag => 1,
            }
        ]
    );
}

sub get_primary_phone {
    my $self = shift;
    return $self->find_user_phone_number( q => [ uph_primary_flag => 1 ] )
        ->[0];
}

sub get_home_org {
    my $self = shift;
    for my $uo ( @{ $self->user_orgs } ) {
        if ( $uo->uo_home_flag ) {
            return $uo->organization;
        }
    }
    return;
}

sub _encrypt_password {
    my ( $self, $str ) = @_;
    return md5_hex( $str . md5_hex($str) );
}

sub _hash_encrypted_password {
    my $self = shift;
    my $str  = shift;
    my $salt = shift || AIR2::Utils->random_str(16);

    # cost MUST match what we do on PHP side.
    my $cost = 13;
    my $bcrypt_hashed
        = bcrypt_hash( { key_nul => 1, cost => $cost, salt => $salt }, $str );

    # the PHP format is slightly different so return compatible string
    return sprintf( '$2y$%02d$%s%s',
        $cost, en_base64($salt), en_base64($bcrypt_hashed) );
}

sub set_password {
    my $self = shift;
    my $str = shift or croak "password string required";

    # validate before save
    my $ap = AIR2::Password->new(
        username => $self->user_username,
        phrase   => $str,
    );
    if ( !$ap->validate ) {
        $self->error( $ap->error );
        return;
    }
    $self->user_encrypted_password( $self->_hash_encrypted_password($str) );
    $self->user_pswd_dtim( time() );
    return $self->check_password($str);
}

sub set_random_password {
    my $self = shift;
    $self->set_password( AIR2::Password->generate( $self->user_username ) );
}

sub check_password {
    my $self = shift;
    my $str = shift or croak "password string required";

    # one-time upgrade to new hashing scheme
    if ( $self->user_password && !$self->user_encrypted_password ) {
        my $md5_match
            = $self->user_password eq $self->_encrypt_password($str);
        if ( $md5_match ) {
            $self->set_password($str);
            $self->user_password(undef);
            $self->update;
        }
        else {
            return 0;
        }
    }

    my $hashed_password = $self->user_encrypted_password;
    return unless $hashed_password;

    # extract the salt so we can compare encryptions
    my @hashed_parts = split( /\$/, $hashed_password );
    my $salt = substr( $hashed_parts[3], 0, 22 );

    # Use a letter by letter match rather than
    # a complete string match to avoid timing attacks
    my $match = $self->_hash_encrypted_password( $str, de_base64($salt) );
    my $bad = 0;
    for ( my $n = 0; $n < length $match; $n++ ) {
        $bad++
            if substr( $match, $n, 1 ) ne substr( $hashed_password, $n, 1 );
    }

    return $bad == 0;
}

=head2 get_authz

Get authorization object for this User, cascading roles DOWN the org tree.
  array(org_id => bitmask-role)

=cut

my %authz;
my %local_authz;

sub get_authz {
    my $self = shift;
    if ( !ref $self ) {
        my $user_id = shift or die "static calls must include a user id";
        $self = AIR2::User->new( user_id => $user_id )->load;
    }
    my $uid = $self->user_id;
    if ( exists $authz{$uid} ) {
        return $authz{$uid};
    }

    # get sorted user_orgs
    my $dbh   = $self->db->retain_dbh;
    my $sel   = "select * from user_org where uo_user_id = $uid";
    my $uorgs = $dbh->selectall_arrayref( $sel, { Slice => {} } );
    $uorgs = AIR2::Organization::sort_by_depth( $uorgs, 'uo_org_id' );

    # calculate authz (DOWNWARD ONLY)
    for my $uo ( @{$uorgs} ) {
        if ( $uo->{uo_status} eq 'A' ) {
            my $children
                = AIR2::Organization::get_org_children( $uo->{uo_org_id} );
            my $bitmask = AIR2::AdminRole::get_bitmask( $uo->{uo_ar_id} );
            for my $org_id ( @{$children} ) {
                $authz{$uid}->{$org_id} = $bitmask;
            }
        }
    }
    return $authz{$uid};
}

sub get_explicit_authz {
    my $self = shift;
    if ( !ref $self ) {
        my $user_id = shift or die "static calls must include a user id";
        $self = AIR2::User->new( user_id => $user_id )->load;
    }
    my $uid = $self->user_id;
    if ( exists $local_authz{$uid} ) {
        return $local_authz{$uid};
    }

    my $dbh   = $self->db->retain_dbh;
    my $sel   = "select * from user_org where uo_user_id = $uid";
    my $uorgs = $dbh->selectall_arrayref( $sel, { Slice => {} } );

    for my $uo (@$uorgs) {
        if ( $uo->{uo_status} eq 'A' ) {
            my $bitmask = AIR2::AdminRole::get_bitmask( $uo->{uo_ar_id} );
            $local_authz{$uid}->{ $uo->{uo_org_id} } = $bitmask;
        }
    }

    return $local_authz{$uid};
}

sub clear_authz_caches {
    %authz       = ();
    %local_authz = ();
}

sub set_role_for_org {
    my $self       = shift;
    my $role_code  = shift or croak "role required";
    my $org_id     = shift or croak "org_id required";
    my $admin_role = AIR2::AdminRole->new( ar_code => $role_code )->load;
    for my $user_org ( @{ $self->user_orgs } ) {
        if ( $user_org->uo_org_id == $org_id ) {
            $user_org->uo_ar_id( $admin_role->ar_id );

            #warn "set $org_id to ar_id " . $admin_role->ar_id;
            return $user_org->save;
        }
    }
    return 0;
}

#########################
# auth tkt methods

sub get_new_air2_auth_tkt {
    my $self = shift;
    my $conf
        = AIR2::Config::get_app_root->subdir('etc')->file('auth_tkt.conf');
    my $at = AIR2::AuthTkt->new(
        conf      => $conf,
        ignore_ip => 1,
    );
    return $at;
}

sub create_tkt {
    my $self = shift;
    my $use_explicit = shift || 0;
    my $authz
        = $use_explicit
        ? $self->get_explicit_authz()
        : $self->get_authz();
    my $packed_authz = AIR2::Utils::pack_authz($authz);
    my $payload      = {
        type       => $self->user_type,
        uuid       => $self->user_uuid,
        username   => $self->user_username,
        first_name => $self->user_first_name,
        last_name  => $self->user_last_name,
        user_id    => $self->user_id,
        status     => $self->user_status,
        authz      => $packed_authz,
    };
    my $at  = $self->get_new_air2_auth_tkt();
    my $tkt = $at->ticket(
        uid     => $self->user_username,
        id_addr => '0.0.0.0',
        data    => encode_json($payload),
    );

    return $tkt;
}

1;

