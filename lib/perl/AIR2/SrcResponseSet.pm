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

package AIR2::SrcResponseSet;
use strict;
use warnings;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );
use Rose::DateTime::Parser;
use Digest::MD5 qw( md5_hex );
use Encode qw( encode_utf8 );
use AIR2::GeoLookup;
use AIR2::State;

my $date_parser
    = Rose::DateTime::Parser->new( time_zone => $AIR2::Config::TIMEZONE );

# redmine #6459, order is important
use constant PUBLISHABLE         => 1;
use constant NOTHING_TO_PUBLISH  => 2;
use constant UNPUBLISHED_PRIVATE => 3;
use constant PUBLISHED           => 4;
use constant UNPUBLISHABLE       => 5;

use constant PINSIGHTFUL_TAG => AIR2::Config->get_pinsightful_tag();

__PACKAGE__->meta->setup(
    table => 'src_response_set',

    columns => [
        srs_id     => { type => 'serial',  not_null => 1 },
        srs_src_id => { type => 'integer', not_null => 1 },
        srs_inq_id => { type => 'integer', not_null => 1 },
        srs_date   => {
            type     => 'datetime',
            not_null => 1
        },
        srs_uri  => { type => 'text', length => 65535 },
        srs_type => {
            type     => 'character',
            default  => 'F',
            length   => 1,
            not_null => 1
        },
        srs_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        srs_xuuid => {
            type   => 'varchar',
            length => 255,
        },
        srs_city    => { type => 'varchar', length    => 128, },
        srs_state   => { type => 'char',    length    => 2, },
        srs_country => { type => 'char',    length    => 2, },
        srs_county  => { type => 'varchar', length    => 128, },
        srs_lat     => { type => 'float',   precision => 32, },
        srs_long    => { type => 'float',   precision => 32, },
        srs_public_flag => { type => 'integer', default => 0, not_null => 1 },
        srs_delete_flag => { type => 'integer', default => 0, not_null => 1 },
        srs_translated_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        srs_export_flag => { type => 'integer', default => 0, not_null => 1 },
        srs_fb_approved_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        srs_loc_id => {
            type     => 'integer',
            default  => 52,          # en_US
            not_null => 1,
        },
        srs_conf_level => { type => 'character', length   => 1 },
        srs_cre_user   => { type => 'integer',   not_null => 1 },
        srs_upd_user   => { type => 'integer' },
        srs_cre_dtim   => {
            type     => 'datetime',
            not_null => 1
        },
        srs_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['srs_id'],

    unique_keys => [ ['srs_uuid'], [ 'srs_type', 'srs_xuuid' ] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { srs_cre_user => 'user_id' },
        },

        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { srs_inq_id => 'inq_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { srs_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { srs_upd_user => 'user_id' },
        },

        locale => {
            class       => 'AIR2::Locale',
            key_columns => { srs_loc_id => 'loc_id' },
        },
    ],

    relationships => [
        responses => {
            class      => 'AIR2::SrcResponse',
            column_map => { srs_id => 'sr_srs_id' },
            type       => 'one to many',
        },

        annotations => {
            class      => 'AIR2::SrsAnnotation',
            column_map => { srs_id => 'srsan_srs_id' },
            type       => 'one to many',
        },

        bin_responses => {
            class      => 'AIR2::BinSrcResponseSet',
            column_map => { srs_id => 'bsrs_srs_id' },
            type       => 'one to many',
        },

        bins => {
            map_class => 'AIR2::BinSrcResponseSet',
            map_from  => 'response_set',
            map_to    => 'bin',
            type      => 'many to many',
        },

        tags => {
            class      => 'AIR2::Tag',
            column_map => { srs_id => 'tag_xid' },
            query_args => [ tag_ref_type => tag_ref_type() ],
            type       => 'one to many',
        },

        users => {
            class      => 'AIR2::UserSrs',
            type       => 'one to many',
            column_map => { 'srs_id' => 'usrs_srs_id' },
        },
    ],
);

my @indexables = qw(
    responses
    annotations
);

my @searchables = (
    @indexables, qw(
        bin_responses
        tags
        users
        )
);

sub tag_ref_type {'R'}

sub get_searchable_rels { return [@searchables] }

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        $self->$rel;
    }
}

sub init_indexer {
    my $self = shift;
    return $self->SUPER::init_indexer(
        prune => {

        },
        max_depth        => 2,
        xml_root_element => 'responseset',
        force_load       => 0,
        @_
    );
}

=head2 get_authz( I<project_authz>, I<src_authz> )

Returns array of org_ids representing the intersection
of the Project- and Source-related authz values.

=cut

sub get_authz {
    my $self          = shift;
    my $project_authz = shift or croak "project_authz required";
    my $src_authz     = shift or croak "src_authz required";

    # get intersection
    my @authz;
    my %p = map { $_ => $_ } @$project_authz;
    for my $oid (@$src_authz) {
        if ( exists $p{$oid} ) {
            push @authz, $oid;
        }
    }
    return \@authz;
}

# memoize
my %inquiries;

sub get_inquiry {
    my $self   = shift;
    my $inq_id = $self->srs_inq_id;
    return $inquiries{$inq_id} if exists $inquiries{$inq_id};
    $inquiries{$inq_id} = $self->inquiry;
    return $inquiries{$inq_id};
}

sub as_qa_set {
    my $self          = shift;
    my $inq_uuid      = $self->get_inquiry->inq_uuid;
    my $owner_org_ids = $self->get_inquiry->get_owner_org_ids();
    my $prj_uuids     = $self->get_inquiry->get_prj_uuids();
    my $prj_names     = $self->get_inquiry->get_prj_names();
    my $translated    = $self->srs_translated_flag;
    my $confidence    = $self->srs_conf_level;
    my $referrer      = $self->srs_uri;
    my $srs_date      = $self->srs_date;
    my $srs_ymdhms    = AIR2::SearchUtils::dtim_to_ymd_hms($srs_date);
    my $authz         = $self->get_inquiry->get_project_authz();

    my @resp;
    for my $sr ( @{ $self->responses } ) {
        my $question  = AIR2::SearchUtils::get_question( $sr->sr_ques_id );
        my $ques_uuid = $question->ques_uuid;
        my $r         = {
            sr_uuid             => $sr->sr_uuid,
            sr_media_asset_flag => $sr->sr_media_asset_flag,
            qa                  => join( ':',
                join( ',', @$authz ),
                join( ',', @$owner_org_ids ),
                $self->srs_uuid,
                $inq_uuid,
                $ques_uuid,
                $sr->sr_public_flag,
                ( $question->ques_dis_seq || 0 ),
                $srs_ymdhms,
                ( $sr->sr_mod_value || $sr->sr_orig_value || '' ) ),
            annotations => [
                map { { sran_value => $_->sran_value || '' } }
                    $sr->annotations
            ],
        };
        if ( defined $sr->sr_mod_value and length $sr->sr_mod_value ) {
            $r->{modified_qa} = join( ':',
                join( ',', @$authz ), $self->srs_uuid,
                $inq_uuid, $ques_uuid,
                ( $question->ques_dis_seq || 0 ), $srs_ymdhms,
                $sr->sr_mod_value );
        }
        push @resp, $r;
    }

    my %qa_set = (
        srs_uuid      => $self->srs_uuid,
        inq_uuid      => $inq_uuid,
        prj_uuids     => $prj_uuids,
        prj_names     => $prj_names,
        is_translated => $translated,
        confidence    => $confidence,
        referrer      => $referrer,
        srs_ts        => $srs_date->ymd(''),    # used in facets
        srs_year      => $srs_date->year,
        srs_month => sprintf( "%s%02d", $srs_date->year, $srs_date->month ),
        responses => \@resp,
        annotations =>
            [ map { { srsan_value => $_->srsan_value } } $self->annotations ],
    );

    return \%qa_set;
}

=head2 as_xml( I<args> )

Returns SrcResponseSet as XML string, suitable for indexing.

I<args> should contain a Rose::DBx::Object::Indexed::Indexer
object and other objects relevant to the XML structure.
See bin/resp2xml.pl for example usage.

=cut

sub as_xml {
    my $set     = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $set->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');

    # since there are relatively few responses-per-source, we'll just
    # load the source and related data every time.
    # TODO: is this really the fastest?
    # TODO: more indexable rels
    $set->load_indexable_rels;
    for my $sr ( @{ $set->responses } ) {
        $sr->load_indexable_rels;
    }

    # load standalone ojbects, so they don't get serialized into the xml
    my $source  = AIR2::SearchUtils::get_source( $set->srs_src_id );
    my $inquiry = AIR2::SearchUtils::get_inquiry( $set->srs_inq_id );

    # turn object into a hash tree
    my $dmp = $indexer->serialize_object($set);

    $dmp->{title} = join( ', ', $source->get_xml_title, $set->srs_uuid );

    # src_response_set data
    my $srs_date = $date_parser->parse_date( $dmp->{srs_date} );
    $dmp->{srs_ts}   = $srs_date->ymd('');
    $dmp->{srs_year} = $srs_date->year;
    $dmp->{srs_month}
        = sprintf( "%s%02d", $srs_date->year, $srs_date->month );
    my $creator = AIR2::SearchUtils::get_user( $set->srs_cre_user );
    $dmp->{creator}      = $creator->get_name;
    $dmp->{creator_fl}   = $creator->get_name_first_last;
    $dmp->{creator_uuid} = $creator->user_uuid;
    my $updater = AIR2::SearchUtils::get_user( $set->srs_upd_user );
    $dmp->{updater}      = $updater->get_name;
    $dmp->{updater_fl}   = $updater->get_name_first_last;
    $dmp->{updater_uuid} = $updater->user_uuid;

    # source
    $dmp->{src_uuid}       = $source->src_uuid;
    $dmp->{src_name}       = $source->get_name;
    $dmp->{src_username}   = $source->src_username;
    $dmp->{src_first_name} = $source->src_first_name;
    $dmp->{src_last_name}  = $source->src_last_name;
    $dmp->{src_status}
        = AIR2::CodeMaster::lookup( 'src_status', $source->src_status );

    # authz for 'active responses' -- see redmine #8359
    $dmp->{orgid_statuses} = $source->get_orgid_statuses();

    my $sem   = $source->get_primary_email;
    my $sph   = $source->get_primary_phone;
    my $smadd = $source->get_primary_address;
    my $sorg  = $source->get_primary_newsroom;
    if ($sem) {
        $dmp->{primary_email}
            = join( ':', $sem->sem_email, $sem->sem_status );
    }
    if ($sph) {
        $dmp->{primary_phone} = join(
            ' ',
            grep {defined} AIR2::SrcPhoneNumber->format_number(
                $sph->{sph_number} || ''
            ),
            $sph->{sph_ext}
        );
    }
    if ($smadd) {
        $dmp->{primary_city}    = $smadd->{smadd_city};
        $dmp->{primary_state}   = $smadd->{smadd_state};
        $dmp->{primary_country} = $smadd->{smadd_cntry};
        $dmp->{primary_zip}     = $smadd->{smadd_zip};
        $dmp->{primary_county}  = $smadd->{smadd_county};
        $dmp->{primary_lat}     = $smadd->{smadd_lat};
        $dmp->{primary_long}    = $smadd->{smadd_long};

        # for range-searching, normalize lat/long (lat+90, long+180),
        # and fix the width, resulting in a range of:
        # latitude  - 000.000000..180.000000
        # longitude - 000.000000..360.000000
        if ( $dmp->{primary_lat} && $dmp->{primary_long} ) {
            $dmp->{primary_lat_norm}
                = sprintf( "%010.6f", $dmp->{primary_lat} + 90.0 );
            $dmp->{primary_long_norm}
                = sprintf( "%010.6f", $dmp->{primary_long} + 180.0 );
        }
    }
    if ($sorg) {
        $dmp->{primary_org_uuid}         = $sorg->org_uuid;
        $dmp->{primary_org_name}         = $sorg->org_name;
        $dmp->{primary_org_display_name} = $sorg->org_display_name;
    }

    my @alpha_sort_facts = qw(birth_year ethnicity gender religion);
    for my $fname (@alpha_sort_facts) {
        $dmp->{$fname}
            = AIR2::SearchUtils::get_source_fact( $source, $fname );
    }

    my @seq_sort_facts
        = qw(household_income education_level political_affiliation);
    for my $fname (@seq_sort_facts) {
        my $fs
            = AIR2::SearchUtils::get_source_fact_and_seq( $source, $fname );
        $dmp->{$fname} = $fs->[0];
        $dmp->{ $fname . "_seq" } = sprintf( "%04d", $fs->[1] );
    }

    # inquiry - inq_orgs - project - organization
    $dmp->{inq_uuid}      = $inquiry->inq_uuid;
    $dmp->{inq_title}     = $inquiry->inq_title;
    $dmp->{inq_ext_title} = $inquiry->inq_ext_title;
    my $inq_creator = AIR2::SearchUtils::get_user( $inquiry->inq_cre_user );
    $dmp->{inq_cre_user} = $inq_creator->user_uuid;
    $dmp->{inq_uuid_title}
        = join( ':', $dmp->{inq_uuid}, $inquiry->get_title );
    $dmp->{inq_cre_dtim}
        = AIR2::SearchUtils::dtim_to_ymd_hms( $inquiry->inq_cre_dtim );

    if ( $inquiry->inq_publish_dtim ) {
        $dmp->{inq_publish_dtim} = AIR2::SearchUtils::dtim_to_ymd_hms(
            $inquiry->inq_publish_dtim );
    }

    my @inq_orgs;
    for my $org ( @{ $inquiry->organizations } ) {
        push @inq_orgs,
            {
            inq_org_name       => $org->org_name,
            inq_org_id         => $org->org_id,
            inq_org_uuid       => $org->org_uuid,
            inq_org_html_color => $org->org_html_color,
            };
    }
    $dmp->{inq_orgs} = \@inq_orgs;

    my @prj_authz;    # while we're at it, get authz
    my @projects;
    my @organizations;
    for my $pinq ( @{ $inquiry->project_inquiries } ) {
        push @projects,
            {
            prj_uuid         => $pinq->project->prj_uuid,
            prj_name         => $pinq->project->prj_name,
            prj_display_name => $pinq->project->prj_display_name,
            prj_uuid_title   => join( ':',
                $pinq->project->prj_uuid,
                $pinq->project->prj_display_name ),
            };
        push @organizations,
            {
            org_names => $pinq->project->get_org_names(),
            org_uuids => $pinq->project->get_org_uuids(),
            org_ids   => $pinq->project->get_org_ids(),
            };
        push @prj_authz, @{ $pinq->project->get_authz() };
    }
    $dmp->{projects}      = \@projects;
    $dmp->{organizations} = \@organizations;
    my $prj_authz_str = join ',', @prj_authz;

    # response - question
    my @resp_ids;
    my @perm_granted = ();
    for my $resp ( @{ $dmp->{responses} } ) {

        # get the question from the memoized inquiry
        my $ques;
        for my $q ( @{ $inquiry->questions } ) {
            if ( $resp->{sr_ques_id} == $q->ques_id ) {
                $ques = $q;
                last;
            }
        }

        # WOH! For some reason, there's a chance the question won't be under
        # the parent inquiry... try to find it anyways!
        unless ($ques) {
            $ques = AIR2::SearchUtils::get_question( $resp->{sr_ques_id} );
        }

        if ( lc( $ques->ques_type ) eq 'p' ) {
            my $answer
                = $resp->{sr_mod_value}
                || $resp->{sr_orig_value}
                || 'no';
            $answer =~ s/\W//g;
            my $perm
                = ( AIR2::Utils::looks_like_yes($answer) ? 'yes' : 'no' );
            push @perm_granted, $perm;
        }

        my $sr_upd_user_id = $resp->{sr_upd_user} || $resp->{srs_cre_user};
        my $sr_upd_user = AIR2::SearchUtils::get_user($sr_upd_user_id);

        # Flatten the related orgs, inquiry, question and answer into a single
        # virtual field so we can find it as a set.
        # Delete original response to avoid duplicating search-able data.
        $resp->{qa} = join( ':',
            $prj_authz_str,
            join( ',', @{ $inquiry->get_owner_org_ids } ),
            $inquiry->inq_uuid,
            $ques->ques_uuid,
            $ques->ques_dis_seq,
            $ques->ques_type,
            $resp->{sr_uuid},
            $resp->{sr_public_flag},
            $ques->ques_public_flag,
            $resp->{sr_upd_dtim},
            $sr_upd_user->user_uuid,
            ( delete $resp->{sr_orig_value} || '' ) );
        $resp->{ques_uuid_value}
            = join( ':', $ques->ques_uuid, $ques->ques_value );
        push @resp_ids, $resp->{sr_id};

        # include any mod values, but insert a dummy char to preserve ordering
        # per #6963, only include : if sr_mod_value is defined, so we can
        # discern between null and !length
        if (    defined $resp->{sr_mod_value}
            and $resp->{sr_upd_dtim}
            and ( $resp->{sr_upd_dtim} ne $resp->{sr_cre_dtim} ) )
        {
            $resp->{qa_mod} = ':' . delete $resp->{sr_mod_value};
        }
        else {
            $resp->{qa_mod} = '.';
        }
    }
    $dmp->{sr_ids} = join ':', @resp_ids;

    # redmine #6459
    # pack all related public_flags into one field for unpack at search time
    $dmp->{public_flags} = join( ':',
        $inquiry->inq_public_flag,  $dmp->{srs_public_flag},
        $set->has_public_questions, $set->has_public_responses,
    );

    # redmine #6909 and #6872.
    # only 1 permission_granted response per set, and
    # any 'no' answer invalidates the entire set.
    my $permission_granted = 0;
    if (@perm_granted) {
        if ( grep { $_ eq 'no' } @perm_granted ) {
            $dmp->{permission_granted} = 'no';
        }
        else {
            $dmp->{permission_granted} = 'yes';
            $permission_granted = 1;
        }
    }

    # redmine #6459
    # compute Publish State to make search sorting easier
    $dmp->{publish_state} = UNPUBLISHABLE;    # default
    if ( $dmp->{public_flags} eq '1:1:1:1' and $permission_granted ) {
        $dmp->{publish_state} = PUBLISHED;
    }
    elsif ( $dmp->{public_flags} eq '1:0:1:1' and $permission_granted ) {
        $dmp->{publish_state} = PUBLISHABLE;
    }
    elsif ( $dmp->{public_flags} =~ m/^1:\d:1:0$/ and $permission_granted ) {
        $dmp->{publish_state} = NOTHING_TO_PUBLISH;
    }
    elsif ( $dmp->{public_flags} =~ m/^1:\d:1:\d$/ and !$permission_granted )
    {
        $dmp->{publish_state} = UNPUBLISHED_PRIVATE;
    }

    #warn "public_flags=$dmp->{public_flags}";
    #warn "publish_state=$dmp->{publish_state}";

    # tags - annotations
    $dmp->{tags} = [ map { $_->get_name } @{ $set->get_tags } ];

    # who has read and starred this srs
    my $users = $set->users_iterator;
    while ( my $usrs = $users->next ) {
        if ( $usrs->usrs_read_flag ) {
            push @{ $dmp->{user_reads} }, $usrs->user->user_uuid;
        }
        if ( $usrs->usrs_favorite_flag ) {
            push @{ $dmp->{user_stars} }, $usrs->user->user_uuid;
        }
    }

    # if anyone has starred this srs, tag it for search only
    if ( $dmp->{user_stars} and @{ $dmp->{user_stars} } ) {
        push @{ $dmp->{tags} }, PINSIGHTFUL_TAG;
    }

    # lowercase versions of fields, for sortability
    my @lowercase
        = qw(src_first_name src_last_name primary_city primary_org_name
        primary_org_display_name inq_title inq_ext_title ethnicity gender religion);
    for my $fld (@lowercase) {
        if ( $dmp->{$fld} ) {
            $dmp->{ $fld . "_lc" } = lc $dmp->{$fld};
        }
    }

    # bins, just uuids
    for my $bin ( @{ $set->bins } ) {
        push @{ $dmp->{bins} }, $bin->bin_uuid;
    }

    # to xml! - only need project authz now (not source authz)
    my $xml = $indexer->to_xml( $dmp, $set, 1 );    # 1 to strip plurals
    my $root = $indexer->xml_root_element;

    # add xinclude support for fuzzy search
    $xml
        =~ s,^<$root,<$root authz="$prj_authz_str" xmlns:xi="http://www.w3.org/2001/XInclude",;
    return $xml;
}

sub to_md5 {
    my $self = shift;

    # inq_uuid, srs_date, sr_orig_values
    my $data = '';
    $data .= $self->inquiry->inq_uuid;
    $data .= $self->srs_date->strftime("%F %T");
    for my $sr ( @{ $self->responses } ) {
        $data .= $sr->sr_orig_value;
    }
    return md5_hex( encode_utf8($data) );
}

=head2 flatten( I<args> )

Returns a very flat SrcResponseSet.

=cut

sub flatten {
    my $self = shift;

    # flatten the simple stuff!

    my $inquiry = $self->get_inquiry();

    my $flat = {
        srs_uuid => $self->srs_uuid,
        srs_date => "" . $self->srs_date,
        srs_type => $self->srs_type,
        cre_user => {
            user_uuid       => $self->cre_user->user_uuid,
            user_username   => $self->cre_user->user_username,
            user_first_name => $self->cre_user->user_first_name,
            user_last_name  => $self->cre_user->user_last_name,
            user_type       => $self->cre_user->user_type,
        },
        inq_uuid      => $inquiry->inq_uuid,
        inq_title     => $inquiry->inq_title,
        inq_ext_title => $inquiry->inq_ext_title,
        inq_type      => $inquiry->inq_type,
        inq_cre_user  => {
            user_uuid       => $inquiry->cre_user->user_uuid,
            user_username   => $inquiry->cre_user->user_username,
            user_first_name => $inquiry->cre_user->user_first_name,
            user_last_name  => $inquiry->cre_user->user_last_name,
            user_type       => $inquiry->cre_user->user_type,
        },
        annotations   => [],
        projects      => [],
        organizations => [],
        responses     => [],
    };

    # annotations
    for my $ann ( $self->annotations ) {
        push @{ $flat->{annotations} },
            {
            srsan_value     => $ann->srsan_value,
            srsan_cre_dtim  => "" . $ann->srsan_cre_dtim,
            srsan_upd_dtim  => "" . $ann->srsan_upd_dtim,
            user_uuid       => $ann->cre_user->user_uuid,
            user_username   => $ann->cre_user->user_username,
            user_first_name => $ann->cre_user->user_first_name,
            user_last_name  => $ann->cre_user->user_last_name,
            user_type       => $ann->cre_user->user_type,
            };
    }

    # projects
    for my $prj ( $self->inquiry->projects ) {
        push @{ $flat->{projects} },
            {
            prj_uuid         => $prj->prj_uuid,
            prj_name         => $prj->prj_name,
            prj_display_name => $prj->prj_display_name,
            prj_desc         => $prj->prj_desc,
            prj_type         => $prj->prj_type,
            prj_status       => $prj->prj_status,
            };
    }

    # organizations
    for my $org ( $self->inquiry->organizations ) {
        push @{ $flat->{organizations} },
            {
            org_uuid         => $org->org_uuid,
            org_name         => $org->org_name,
            org_display_name => $org->org_display_name,
            org_logo_uri     => $org->org_logo_uri,
            org_html_color   => $org->org_html_color,
            org_type         => $org->org_type,
            org_status       => $org->org_status,
            };
    }

    # responses, in display order
    my $questions = $inquiry->questions_in_display_order();
    for my $question (@$questions) {
        my $response = $self->response_for_question($question);
        next unless $response;
        if ( $response->sr_orig_value ) {
            my $flat_sr = {
                sr_uuid         => $response->sr_uuid,
                sr_orig_value   => $response->sr_orig_value,
                sr_mod_value    => $response->sr_mod_value,
                sr_upd_dtim     => "" . $response->sr_upd_dtim,
                ques_uuid       => $response->question->ques_uuid,
                ques_dis_seq    => $response->question->ques_dis_seq,
                ques_type       => $response->question->ques_type,
                ques_value      => $response->question->ques_value,
                ques_choices    => $response->question->ques_choices,
                user_username   => $response->upd_user->user_username,
                user_type       => $response->upd_user->user_type,
                user_first_name => $response->upd_user->user_first_name,
                user_last_name  => $response->upd_user->user_last_name,
                annotations     => [],
            };

            # annotations
            for my $ann ( $response->annotations ) {
                push @{ $flat_sr->{annotations} },
                    {
                    sran_value      => $ann->sran_value,
                    sran_cre_dtim   => "" . $ann->sran_cre_dtim,
                    sran_upd_dtim   => "" . $ann->sran_upd_dtim,
                    user_uuid       => $ann->cre_user->user_uuid,
                    user_username   => $ann->cre_user->user_username,
                    user_first_name => $ann->cre_user->user_first_name,
                    user_last_name  => $ann->cre_user->user_last_name,
                    user_type       => $ann->cre_user->user_type,
                    };
            }
            push @{ $flat->{responses} }, $flat_sr;
        }

    }
    return $flat;
}

sub is_public {
    my $self         = shift;
    my $public_count = 0;

    if ( $self->srs_public_flag == 1 ) {
        for my $response ( $self->responses ) {
            if ( $response->is_public ) {
                $public_count++;
            }
        }
    }

    return $public_count;
}

sub has_public_responses {
    my $self = shift;
    my $i    = 0;
    for my $sr ( @{ $self->responses } ) {
        $i += $sr->sr_public_flag;
    }

    return $i ? 1 : 0;
}

sub has_public_questions {
    my $self = shift;
    my $i    = 0;
    for my $sr ( @{ $self->responses } ) {
        my $ques = AIR2::SearchUtils::get_question( $sr->sr_ques_id );

        # contributor questions may have public flag but do
        # not count as "public"
        if ( $ques->ques_type =~ m/^[zsy]$/i ) {
            next;
        }
        $i += $ques->ques_public_flag;
    }
    return $i ? 1 : 0;
}

sub get_contributor_response {
    my $self    = shift;
    my $pmap_id = shift or croak "pmap_id required";
    my $type    = shift || 'Z';
    for my $sr ( @{ $self->responses } ) {
        my $ques = AIR2::SearchUtils::get_question( $sr->sr_ques_id );
        next unless $ques->ques_pmap_id;
        if ( $ques->ques_type eq $type and $ques->ques_pmap_id eq $pmap_id ) {
            return $sr;
        }
    }
    return undef;
}

sub get_postal_code_response {
    my $self = shift;
    return $self->get_contributor_response('34');
}

sub get_first_name_response {
    my $self = shift;
    return $self->get_contributor_response('2');

}

sub get_last_name_response {
    my $self = shift;
    return $self->get_contributor_response('3');

}

sub get_email_response {
    my $self = shift;
    return $self->get_contributor_response('10');
}

sub get_phone_response {
    my $self = shift;
    return $self->get_contributor_response('20');
}

sub get_state_response {
    my $self = shift;
    return $self->get_contributor_response( '33', 'S' );
}

sub get_country_response {
    my $self = shift;
    return $self->get_contributor_response( '35', 'Y' );
}

sub get_city_response {
    my $self = shift;
    return $self->get_contributor_response('32');
}

sub get_street_response {
    my $self = shift;
    return $self->get_contributor_response('31');
}

# cache states for lookup ease
my %states
    = map { $_->state_name => $_->state_code } @{ AIR2::State->fetch_all };

sub set_geo_cache {
    my $self = shift;
    my $override = shift || 0;

    # assume if state is set, everything else is.
    if ( $self->srs_state and !$override ) {
        return 0;
    }

    my $postal_response = $self->get_postal_code_response() or return 0;
    my $zip = $postal_response->sr_mod_value
        || $postal_response->sr_orig_value;

    #warn "zip=$zip";

    return 0 unless $zip and $zip =~ m/^(\d\d\d\d\d)(-\d\d\d\d)?$/;
    my $zip5 = $1;

    my $geo = AIR2::GeoLookup->find( zip_code => $zip5, ) or return 0;

    # only update if our value is null, and geo_lookup is not
    my $return = 0;
    if ( $geo->state && ( !$self->srs_state or $override ) ) {
        $self->srs_state( $states{ $geo->state } );
        $self->srs_country('US');    # TODO canada?
        $return++;
    }
    if ( $geo->county && ( !$self->srs_county or $override ) ) {
        $self->srs_county( $geo->county );
        $return++;
    }
    if ( $geo->city && ( !$self->srs_city or $override ) ) {
        $self->srs_city( $geo->city );
        $return++;
    }
    if ( $geo->latitude && ( !$self->srs_lat or $override ) ) {
        $self->srs_lat( $geo->latitude );
        $return++;
    }
    if ( $geo->longitude && ( !$self->srs_long or $override ) ) {
        $self->srs_long( $geo->longitude );
        $return++;
    }

    return $return;

}

sub response_for_question {
    my $self = shift;
    my $question = shift or croak "question required";
    if ( !$question->isa('AIR2::Question') ) {
        croak "question must be a AIR2::Question object";
    }

    for my $sr ( @{ $self->responses } ) {
        if ( $sr->sr_ques_id == $question->ques_id ) {
            return $sr;
        }
    }

}

1;
