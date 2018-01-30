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

package AIR2::Inquiry;
use strict;
use base qw(AIR2::DB);
use Carp;
use JSON;
use Data::Dump qw( dump );
use Rose::DateTime::Parser;
use Search::Tools::UTF8;
use Encode;

my $date_parser
    = Rose::DateTime::Parser->new( time_zone => $AIR2::Config::TIMEZONE );

our @EVERGREEN_QUERY_UUIDS = qw( a5e5f19b1c58 b6be40de1385 c729062daffb );

use constant TYPE_FORMBUILDER  => 'F';
use constant TYPE_QUERYBUILDER => 'Q';
use constant TYPE_TEST         => 'T';
use constant TYPE_NONJOURN     => 'N';
use constant TYPE_MANUAL_ENTRY => 'E';
use constant TYPE_COMMENT      => 'C';

__PACKAGE__->meta->setup(
    table => 'inquiry',

    columns => [
        inq_id   => { type => 'serial', not_null => 1 },
        inq_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        inq_title => {
            type     => 'varchar',
            length   => 128,
            not_null => 1
        },
        inq_ext_title    => { type => 'text',    length => 65535 },
        inq_expire_msg   => { type => 'text',    length => 65555, },
        inq_deadline_msg => { type => 'text',    length => 65555, },
        inq_confirm_msg  => { type => 'text',    length => 65555, },
        inq_desc         => { type => 'varchar', length => 255 },
        inq_type         => {
            type     => 'character',
            default  => TYPE_FORMBUILDER,
            length   => 1,
            not_null => 1
        },
        inq_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        inq_stale_flag => { type => 'integer', default => 1, not_null => 1 },
        inq_xid        => { type => 'integer' },
        inq_loc_id     => {
            type     => 'integer',
            default  => 52,          # en_US
            not_null => 1
        },
        inq_cre_user => { type => 'integer', not_null => 1 },
        inq_upd_user => { type => 'integer' },
        inq_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        inq_upd_dtim      => { type => 'datetime' },
        inq_expire_dtim   => { type => 'datetime' },
        inq_publish_dtim  => { type => 'datetime' },
        inq_deadline_dtim => { type => 'datetime' },
        inq_rss_intro     => { type => 'text', length => 65535, },
        inq_rss_status => {
            type     => 'character',
            length   => 1,
            default  => 'N',
            not_null => 1,
        },
        inq_intro_para  => { type => 'text',    length => 65535 },
        inq_ending_para => { type => 'text',    length => 65535 },
        inq_url         => { type => 'varchar', length => 255 },
        inq_tpl_opts    => { type => 'varchar', length => 255 },
        inq_cache_user  => { type => 'integer' },
        inq_cache_dtim  => { type => 'datetime' },
        inq_public_flag =>
            { type => 'integer', default => '0', not_null => 1, },
    ],

    primary_key_columns => ['inq_id'],

    unique_key => ['inq_uuid'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { inq_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { inq_upd_user => 'user_id' },
        },

        cache_user => {
            class       => 'AIR2::User',
            key_columns => { inq_cache_user => 'user_id' },
        },

        locale => {
            class       => 'AIR2::Locale',
            key_columns => { inq_loc_id => 'loc_id' },
        },
    ],

    relationships => [

        activities => {
            class      => 'AIR2::InquiryActivity',
            column_map => { inq_id => 'ia_inq_id' },
            type       => 'one to many',
        },

        authors => {
            class      => 'AIR2::InquiryUser',
            column_map => { 'inq_id' => 'iu_inq_id' },
            query_args => [ iu_type => 'A' ],
            type       => 'one to many',
        },

        bin_responses => {
            class      => 'AIR2::BinSrcResponseSet',
            column_map => { inq_id => 'bsrs_inq_id' },
            type       => 'one to many',
        },

        bins => {
            map_class => 'AIR2::BinSrcResponseSet',
            map_from  => 'inquiry',
            map_to    => 'bin',
            type      => 'many to many',
        },

        watchers => {
            class      => 'AIR2::InquiryUser',
            column_map => { 'inq_id' => 'iu_inq_id' },
            query_args => [ iu_type => 'W' ],
            type       => 'one to many',
        },

        organizations => {
            map_class => 'AIR2::InqOrg',
            map_from  => 'inquiry',
            map_to    => 'organization',
            type      => 'many to many',
        },

        project_inquiries => {
            class      => 'AIR2::ProjectInquiry',
            column_map => { inq_id => 'pinq_inq_id' },
            type       => 'one to many',
        },

        projects => {
            map_class => 'AIR2::ProjectInquiry',
            map_from  => 'inquiry',
            map_to    => 'project',
            type      => 'many to many',
        },

        questions => {
            class      => 'AIR2::Question',
            column_map => { inq_id => 'ques_inq_id' },
            type       => 'one to many',
        },

        src_inquiries => {
            class      => 'AIR2::SrcInquiry',
            column_map => { inq_id => 'si_inq_id' },
            type       => 'one to many',
        },

        src_response_sets => {
            class      => 'AIR2::SrcResponseSet',
            column_map => { inq_id => 'srs_inq_id' },
            type       => 'one to many',
        },

        tank_response_sets => {
            class      => 'AIR2::TankResponseSet',
            column_map => { inq_id => 'srs_inq_id' },
            type       => 'one to many',
        },

        inquiry_annotations => {
            class      => 'AIR2::InquiryAnnotation',
            column_map => { inq_id => 'inqan_inq_id' },
            type       => 'one to many',
        },

        inquiry_orgs => {
            class      => 'AIR2::InqOrg',
            column_map => { inq_id => 'iorg_inq_id' },
            type       => 'one to many',
        },

        tags => {
            class      => 'AIR2::Tag',
            column_map => { inq_id => 'tag_xid' },
            query_args => [ tag_ref_type => tag_ref_type() ],
            type       => 'one to many',
        },

        users => {
            map_class => 'AIR2::InquiryUser',
            map_from  => 'inquiry',
            map_to    => 'user',
            type      => 'many to many',
        },
    ],
);

sub add_users_as_authors {
    my $self = shift;
    my $authors = shift or croak "authors required";
    if ( ref $authors ne 'ARRAY' ) {
        $authors = [$authors];
    }
    my @to_add;
    for my $author (@$authors) {
        push @to_add, { iu_user_id => $author->user_id, iu_type => 'A' };
    }
    return $self->add_authors( \@to_add );
}

sub add_users_as_watchers {
    my $self = shift;
    my $watchers = shift or croak "watchers required";
    if ( ref $watchers ne 'ARRAY' ) {
        $watchers = [$watchers];
    }
    my @to_add;
    for my $watcher (@$watchers) {
        push @to_add, { iu_user_id => $watcher->user_id, iu_type => 'W' };
    }
    return $self->add_watchers( \@to_add );
}

sub add_activity {
    my $self = shift;
    $self->add_activities(@_);
}

sub tag_ref_type {'I'}

sub init_indexer {
    my $self = shift;
    return $self->SUPER::init_indexer(
        prune => {

        },
        max_depth        => 2,
        xml_root_element => 'inquiry',
        force_load       => 0,
        @_
    );
}

my @indexables = qw(
    questions
    src_inquiries
    project_inquiries
    organizations
    inquiry_annotations
);

my @searchables = qw(
    bin_responses
    tags
    questions
    src_inquiries
    project_inquiries
    inquiry_annotations
);

sub get_searchable_rels { return [@searchables] }

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        $self->$rel;
    }
    for my $pi ( @{ $self->project_inquiries } ) {
        $pi->project;
    }
}

sub find_a_project {
    my $self = shift;
    for my $pi ( @{ $self->project_inquiries || [] } ) {
        next if $pi->pinq_status ne 'A';
        return $pi->get_project;
    }
    for my $io ( @{ $self->inquiry_orgs || [] } ) {
        next if $io->iorg_status ne 'A';
        return $io->organization->default_project;
    }
    return AIR2::Project->new( prj_name => 'apmpin' )->load;
}

sub find_an_org {
    my $self = shift;
    for my $org ( @{ $self->organizations } ) {
        next unless $org->is_active();
        return $org;
    }
    return AIR2::Organization->new( org_name => 'apmpin' )->load;
}

sub get_uri {
    my $self = shift;

    # uuid is char (fixed width)
    # so we sanity check for paddding spaces
    my $uuid = $self->inq_uuid;
    $uuid =~ s/\ +//g;
    my $org = $self->find_an_org();
    return sprintf(
        "%s/%s/insight/%s/%s/%s",
        AIR2::Config::get_constant('AIR2_MYPIN2_URL'),
        $self->get_uri_locale(),
        $org->org_name,
        $uuid,
        AIR2::Utils::urlify( $self->get_title() )
    );
}

sub locale_key {
    my $self = shift;
    if ( $self->locale ) {
        return $self->locale->loc_key;
    }
    else {
        return 'en_US';
    }
}

sub get_uri_locale {
    my $self   = shift;
    my $locale = $self->locale_key;
    $locale =~ s/_\w\w$//;
    return $locale;
}

sub get_title {
    my $self = shift;
    return $self->inq_ext_title || $self->inq_title;
}

sub get_prj_uuids {
    my $self = shift;
    my @uuids;
    for my $pi ( @{ $self->project_inquiries } ) {
        next if $pi->pinq_status ne 'A';
        push @uuids, $pi->get_project->prj_uuid;
    }
    return \@uuids;
}

sub get_prj_names {
    my $self = shift;
    my @names;
    for my $pi ( @{ $self->project_inquiries } ) {
        next if $pi->pinq_status ne 'A';
        push @names, $pi->get_project->prj_name;
    }
    return \@names;
}

sub get_owner_org_ids {
    my $self = shift;
    my @ids;
    for my $io ( @{ $self->inquiry_orgs } ) {
        push @ids, $io->iorg_org_id;
    }
    return \@ids;
}

sub get_project_authz {
    my $self = shift;
    my @prj_authz;
    for my $pinq ( @{ $self->project_inquiries } ) {
        push @prj_authz, @{ $pinq->project->get_authz() };
    }
    return \@prj_authz;
}

=head2 as_xml( I<args> )

Returns Inquiry as XML string, suitable for indexing.

I<args> should contain a Rose::DBx::Object::Indexed::Indexer
object and other objects relevant to the XML structure.
See bin/inq2xml.pl for example usage.

=cut

sub as_xml {
    my $inq     = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $inq->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');
    my $sources = delete $args->{sources}
        || AIR2::SearchUtils::get_source_id_uuid_matrix();
    my $publishable = delete $args->{publishable}
        || 0;

    $inq->load_indexable_rels;

    my $dmp = $indexer->serialize_object($inq);

    $dmp->{status} = $inq->get_status_string();

    # we don't load the sources themselves but do reference their uuids
    # this is not strictly necessary because
    # the src_id is in the sources index too,
    # but as an exercise it's a good idea.
    for my $src ( @{ $dmp->{src_inquiries} } ) {
        my $sid = $src->{si_src_id};
        if ( !exists $sources->{$sid} ) {
            croak "No such src_id $sid in sources";
        }
        push @{ $dmp->{src_uuids} }, $sources->{$sid};
    }

    # TODO audit this
    # for authz we need the org_ids
    # that this inquiry is related to via its parent project(s).
    my @org_ids;
    my @org_names;
    my @org_uuids;
    my @authz;
    my @prj_uuid_titles;
    for my $prjinq ( @{ $inq->project_inquiries } ) {
        next if $prjinq->pinq_status ne 'A';
        push @org_ids,   @{ $prjinq->project->get_org_ids() };
        push @org_names, @{ $prjinq->project->get_org_names() };
        push @org_uuids, @{ $prjinq->project->get_org_uuids() };
        push @authz,     @{ $prjinq->project->get_authz() };
        push @prj_uuid_titles,
            join( ":",
            $prjinq->project->prj_uuid,
            $prjinq->project->prj_display_name ),
            ;
    }
    $dmp->{org_ids}         = \@org_ids;
    $dmp->{org_names}       = \@org_names;
    $dmp->{org_uuids}       = \@org_uuids;
    $dmp->{prj_uuid_titles} = \@prj_uuid_titles;
    $dmp->{owner_org_uuids}
        = [ map { $_->{org_uuid} } @{ $dmp->{organizations} } ];
    $dmp->{owner_org_names}
        = [ map { $_->{org_name} } @{ $dmp->{organizations} } ];

    # virtual field for question sequence+value for display
    for my $q ( @{ $dmp->{questions} } ) {
        $q->{ques_seq_value}
            = join( ':', $q->{ques_dis_seq}, $q->{ques_value} );

        # decode json fields
        for my $json_field ( @{ AIR2::Question->json_encoded_columns } ) {

            if ( $q->{$json_field} and lc( $q->{$json_field} ) ne 'null' ) {
                my $decoded_field = $json_field . '_values';
                eval {
                    $q->{$json_field} = to_utf8( $q->{$json_field} );
                    $q->{$decoded_field}
                        = decode_json( encode_utf8( $q->{$json_field} ) );
                };
                if ($@) {
                    warn sprintf(
                        "error parsing json in Inquiry %s question %s : [%s] %s\n",
                        $dmp->{inq_id}, $q->{ques_uuid},
                        ( $q->{$json_field} || '(NULL)' ), $@ );
                }

                # boolean values are objects, which we must stringify
                if ( ref $q->{$decoded_field} eq 'ARRAY' ) {
                    for my $qcv ( @{ $q->{$decoded_field} } ) {
                        if ( ref $qcv eq 'HASH' ) {
                            for my $key (qw( isdefault ischecked )) {
                                if ( exists $qcv->{$key} ) {
                                    $qcv->{$key} .= "";
                                }
                            }
                        }
                    }
                }
                elsif ( ref $q->{$decoded_field} eq 'HASH' ) {
                    for my $qcv_key ( keys %{ $q->{$decoded_field} } ) {
                        next
                            unless ref $q->{$decoded_field}->{$qcv_key} eq
                            'JSON::XS::Boolean';
                        $q->{$decoded_field}->{$qcv_key} .= '';
                    }
                }
            }

        }
    }

    my %srs_ts;
    my $srs_count = 0;
    my $srsets    = $inq->src_response_sets_iterator;
    while ( my $srs = $srsets->next ) {
        if ( $publishable == 1 ) {
            if ( $srs->srs_public_flag == 1 ) {
                $srs_ts{ AIR2::SearchUtils::dtim_string_to_ymd(
                        $srs->srs_date ) }++;
                $srs_count++;
            }
        }
        else {
            $srs_ts{ AIR2::SearchUtils::dtim_string_to_ymd( $srs->srs_date )
            }++;
            $srs_count++;
        }
    }
    $dmp->{response_sets_count} = $srs_count;
    $dmp->{srs_tses}            = [ keys %srs_ts ];
    $dmp->{tags} = [ map { $_->get_name } @{ $inq->get_tags } ];

    $dmp->{creator}      = $inq->cre_user->get_name;
    $dmp->{creator_fl}   = $inq->cre_user->get_name_first_last;
    $dmp->{creator_uuid} = $inq->cre_user->user_uuid;

    my @authors;
    for my $iu ( @{ $inq->authors } ) {
        push @authors,
            {
            author      => $iu->user->get_name,
            author_fl   => $iu->user->get_name_first_last,
            author_uuid => $iu->user->user_uuid,
            };
    }

    # do not name the key "authors" because that creates 2 <author> tags
    $dmp->{author_sets} = \@authors;

    my @watchers;
    for my $iu ( @{ $inq->watchers } ) {
        push @watchers,
            {
            watcher      => $iu->user->get_name,
            watcher_fl   => $iu->user->get_name_first_last,
            watcher_uuid => $iu->user->user_uuid,
            };
    }

    # do not name the key "watchers" because that creates 2 <author> tags
    $dmp->{watcher_sets} = \@watchers;

    $dmp->{inq_uuid_title} = join( ':', $inq->inq_uuid, $inq->get_title );
    $dmp->{inq_title_sort} = lc( $dmp->{inq_ext_title} );
    $dmp->{inq_title_sort} =~ s/^\W+//;
    $dmp->{inq_cre_date}
        = AIR2::SearchUtils::dtim_string_to_ymd( $dmp->{inq_cre_dtim} );
    $dmp->{inq_upd_date}
        = AIR2::SearchUtils::dtim_string_to_ymd( $dmp->{inq_upd_dtim} );

    if ( defined $dmp->{inq_publish_dtim} ) {
        my $publish_date
            = $date_parser->parse_date( $dmp->{inq_publish_dtim} );
        $dmp->{inq_publish_date} = $publish_date->ymd('');
        $dmp->{inq_publish_year} = $publish_date->year;
        $dmp->{inq_publish_month}
            = sprintf( "%s%02d", $publish_date->year, $publish_date->month );
    }

    $dmp->{title} = $inq->get_title();

    # bins, just uuids
    for my $bin ( @{ $inq->bins } ) {
        push @{ $dmp->{bins} }, $bin->bin_uuid;
    }

    my $xml = $indexer->to_xml( $dmp, $inq, 1 );    # last 1 to strip plurals

    # hack in the authz string
    my $authz_str = join( ",", @authz );
    my $root = $indexer->xml_root_element;
    $xml =~ s,^<$root,<$root authz="$authz_str",;

    return $xml;

}

sub get_authors {
    my $self = shift;
    return [ map { $_->user } @{ $self->authors } ];
}

sub get_published_dtim {
    croak "deprecated method -- use inq_publish_dtim column directly";
    my $self = shift;
    my $dtm
        = defined $self->inq_publish_dtim
        ? $self->inq_publish_dtim
        : $self->inq_upd_dtim;
    return $dtm;
}

=head2 make_manual_entry

Create a new "Manual Entry" type of inquiry, complete with the standard
questions.

=cut

sub make_manual_entry {
    my $inq = AIR2::Inquiry->new(
        inq_title     => 'manual_entry',
        inq_ext_title => 'Submission Manual Entry',
        inq_desc      => 'Query object to hold manual User input',
        inq_type      => TYPE_MANUAL_ENTRY,
        questions => [
            {   ques_type    => 'O',            #dropdown
                ques_value   => 'Entry type',
                ques_choices => encode_json(
                    [   { value => 'Email',                 isdefault => 0 },
                        { value => 'Phone Call',            isdefault => 0 },
                        { value => 'Text Message',          isdefault => 0 },
                        { value => 'In-person Interaction', isdefault => 0 },
                    ]
                ),
                ques_dis_seq => 1,
            },
            {   ques_type    => 'T',             #text
                ques_value   => 'Description',
                ques_dis_seq => 2,
            },
            {   ques_type    => 'T',             #text
                ques_value   => 'Text',
                ques_dis_seq => 3,
            },
        ],
    );
    return $inq;
}

my %STATUS = (
    A => 'Published',
    F => 'Inactive',
    D => 'Draft',
    L => 'Deadline',
    E => 'Expired',
    S => 'Scheduled',
);

sub get_status_string {
    my $self = shift;
    return $STATUS{ $self->inq_status };
}

sub is_published {
    my $self   = shift;
    my $status = $self->inq_status;
    my $type   = $self->inq_type;
    my $now    = time();
    if ((     !$self->inq_publish_dtim
            or $self->inq_publish_dtim->epoch <= $now
        )
        and
        ( !$self->inq_expire_dtim or $self->inq_expire_dtim->epoch >= $now )
        and ( !$self->inq_deadline_dtim
            or $self->inq_deadline_dtim->epoch >= $now )
        and ( $status eq 'A' or $status eq 'L' or $status eq 'E' )
        and (  $type eq TYPE_FORMBUILDER
            or $type eq TYPE_QUERYBUILDER
            or $type eq TYPE_TEST
            or $type eq TYPE_NONJOURN )
        )
    {
        return 1;
    }
    return 0;
}

sub has_been_published {
    my $self   = shift;
    my $status = $self->inq_status;
    if (   $status eq 'A'
        or $status eq 'L'
        or $status eq 'E'
        or $status eq 'F' )
    {
        return 1;
    }
    return 0;
}

sub save {
    my $self = shift;
    my $ret  = $self->SUPER::save(@_);

    # clear parent project(s) and org(s) rss cache
    for my $project ( @{ $self->projects } ) {
        if ( -s $project->get_rss_cache_path ) {
            unlink( $project->get_rss_cache_path );
        }
    }
    for my $org ( @{ $self->organizations } ) {
        if ( -s $org->get_rss_cache_path ) {
            unlink( $org->get_rss_cache_path );
        }
    }

    if ( -s AIR2::Project->get_combined_rss_cache_path ) {
        unlink( AIR2::Project->get_combined_rss_cache_path );
    }
    return $ret;
}

sub insert {
    my $self = shift;
    my $ret  = $self->SUPER::insert(@_);
    if ($ret) {

        # default related objects

        # log activity
        my $activity = AIR2::InquiryActivity->new(
            ia_inq_id  => $self->inq_id,
            ia_actm_id => 42,                    # TODO project activity type
            ia_desc    => 'created by {USER}',
            ia_dtim    => time(),
        );
        $activity->save();

        # create author
        my $author = AIR2::InquiryUser->new(
            iu_inq_id  => $self->inq_id,
            iu_user_id => $self->inq_cre_user,
            iu_type    => 'A',
        );
        $author->save();

        # create watcher
        my $watcher = AIR2::InquiryUser->new(
            iu_inq_id  => $self->inq_id,
            iu_user_id => $self->inq_cre_user,
            iu_type    => 'W',
        );
        $watcher->save();

    }
    return $ret;
}

sub questions_in_display_order {
    my $self    = shift;
    my @sorted  = ();
    my %grouped = ();
    my $permission_question;

    # initial sort to make sure we have no dis_seq collisions
    my @questions = sort { $a->ques_dis_seq <=> $b->ques_dis_seq }
        grep { $_->ques_status eq 'A' } @{ $self->questions };
    my $dis_seq = 0;
    for my $q (@questions) {
        if (   lc( $q->ques_type ) eq 'z'
            or lc( $q->ques_type ) eq 's'
            or lc( $q->ques_type ) eq 'y' )
        {
            $grouped{contributor}->{$dis_seq} = $q;
        }

        # group permission question with public questions,
        # even though it is itself private.
        # redmine #8031 says we only group it if there are
        # public questions defined so defer that decision till
        # after we've seen all the questions.
        elsif ( lc( $q->ques_type ) eq 'p' ) {
            $permission_question = $q;
        }
        elsif ( $q->ques_public_flag ) {
            $grouped{public}->{$dis_seq} = $q;
        }
        else {
            $grouped{private}->{$dis_seq} = $q;
        }

        $dis_seq++;
    }

    # now decide where to put the permission question
    if ( $permission_question and scalar( keys %{ $grouped{public} } ) >= 1 )
    {
        # force it to sort last
        $grouped{public}->{1_000_000} = $permission_question;
    }
    elsif ($permission_question) {
        $grouped{private}->{ $permission_question->ques_dis_seq }
            = $permission_question;
    }

    for my $group (qw( contributor public private )) {
        push @sorted, map { $grouped{$group}->{$_} }
            sort { $a <=> $b } keys %{ $grouped{$group} };
    }
    return \@sorted;
}

sub get_contributor_questions {
    my $self = shift;
    my @contrib;
    for my $q ( @{ $self->questions } ) {
        if (   lc( $q->ques_type ) eq 'z'
            or lc( $q->ques_type ) eq 's'
            or lc( $q->ques_type ) eq 'y' )
        {
            push @contrib, $q;
        }
    }
    return \@contrib;
}

sub get_evergreens {
    my $self = shift;
    my $class = ref($self) || $self;
    my @green;
    for my $uuid (@EVERGREEN_QUERY_UUIDS) {
        push @green, $class->new( inq_uuid => $uuid )->load;
    }
    return \@green;
}

sub get_default_expire_msg {
    my $self   = shift;
    my $locale = $self->get_uri_locale();
    if ( $locale eq 'en' ) {
        return 'This query has expired';
    }
    elsif ( $locale eq 'es' ) {
        return 'Este tema ha caducado.';
    }
    return 'This query has expired';
}

1;

