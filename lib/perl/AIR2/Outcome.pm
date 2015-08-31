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
package AIR2::Outcome;
use strict;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );

__PACKAGE__->meta->setup(
    table => 'outcome',

    columns => [
        out_id   => { type => 'serial', not_null => 1 },
        out_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        out_org_id   => { type => 'integer', not_null => 1, default => 1 },
        out_headline => { type => 'varchar', length => 255, not_null => 1 },
        out_internal_headline => { type => 'varchar', length => 255 },
        out_url      => { type => 'varchar', length => 255 },
        out_teaser   => { type => 'text',    length => 65535, not_null => 1 },
        out_internal_teaser   => { type => 'text',    length => 65535 },
        out_show     => { type => 'varchar', length => 255 },
        out_survey   => { type => 'text',    length => 65535 },
        out_dtim     => { type => 'datetime' },
        out_meta     => { type => 'text',    length => 65535 },
        out_type     => {
            type     => 'character',
            default  => 'S',
            length   => 1,
            not_null => 1
        },
        out_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        out_cre_user => { type => 'integer',  not_null => 1 },
        out_upd_user => { type => 'integer' },
        out_cre_dtim => { type => 'datetime', not_null => 1 },
        out_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['out_id'],

    unique_key => ['out_uuid'],

    foreign_keys => [
        organization => {
            class       => 'AIR2::Organization',
            key_columns => { out_org_id => 'org_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { out_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { out_upd_user => 'user_id' },
        },
    ],

    relationships => [

        # Annotations
        annotations => {
            class      => 'AIR2::OutAnnotation',
            column_map => { out_id => 'oa_out_id' },
            type       => 'one to many',
        },

        # Projects
        prj_outcomes => {
            class      => 'AIR2::PrjOutcome',
            column_map => { out_id => 'pout_out_id' },
            type       => 'one to many',
        },
        projects => {
            map_class => 'AIR2::PrjOutcome',
            map_from  => 'outcome',
            map_to    => 'project',
            type      => 'many to many',
        },

        # Inquiries
        inq_outcomes => {
            class      => 'AIR2::InqOutcome',
            column_map => { out_id => 'iout_out_id' },
            type       => 'one to many',
        },
        inquiries => {
            map_class => 'AIR2::InqOutcome',
            map_from  => 'outcome',
            map_to    => 'inquiry',
            type      => 'many to many',
        },

        # Sources
        src_outcomes => {
            class      => 'AIR2::SrcOutcome',
            column_map => { out_id => 'sout_out_id' },
            type       => 'one to many',
        },
        sources => {
            map_class => 'AIR2::SrcOutcome',
            map_from  => 'outcome',
            map_to    => 'source',
            type      => 'many to many',
        },

        tags => {
            class      => 'AIR2::Tag',
            column_map => { out_id => 'tag_xid' },
            query_args => [ tag_ref_type => tag_ref_type() ],
            type       => 'one to many',
        },
    ],
);

sub tag_ref_type {'O'}

sub init_indexer {
    my $self = shift;
    return $self->SUPER::init_indexer(
        prune            => {},
        max_depth        => 2,
        xml_root_element => 'outcome',
        force_load       => 0,
        @_
    );
}

my @indexables = qw(
    projects
    inquiries
    sources
    organization
    cre_user
    upd_user
    tags
    annotations
);

my @searchables = qw(
);

sub get_searchable_rels { return [@searchables] }

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        $self->$rel;
    }
}

sub as_xml {
    my $self    = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $self->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');
    my $sources = delete $args->{sources}
        || AIR2::SearchUtils::get_source_id_uuid_matrix();
    my $publishable = delete $args->{publishable}
        || 0;

    $self->load_indexable_rels;

    my $dmp = $indexer->serialize_object($self);

    for my $inq ( @{ $self->inquiries } ) {
        push @{ $dmp->{inq_uuids} }, $inq->inq_uuid;
        push @{ $dmp->{inq_uuid_titles} },
            join( ':', $inq->inq_uuid, $inq->get_title );
    }
    for my $prj ( @{ $self->projects } ) {
        push @{ $dmp->{prj_uuids} }, $prj->prj_uuid;
        push @{ $dmp->{prj_uuid_titles} },
            join( ":", $prj->prj_uuid, $prj->prj_display_name );
    }
    for my $src ( @{ $self->sources } ) {
        push @{ $dmp->{src_uuids} }, $src->src_uuid;
        push @{ $dmp->{src_names} }, $src->get_name;
    }
    $dmp->{creator}      = $self->cre_user->get_name;
    $dmp->{creator_fl}   = $self->cre_user->get_name_first_last;
    $dmp->{creator_uuid} = $self->cre_user->user_uuid;
    $dmp->{updater}      = $self->upd_user->get_name;
    $dmp->{updater_uuid} = $self->upd_user->user_uuid;
    $dmp->{tags}         = [ map { $_->get_name } @{ $self->get_tags } ];

    # zap full rel structs to reduce noise
    for my $rel (qw( projects inquiries sources cre_user upd_user )) {
        delete $dmp->{$rel};
    }

    $debug and dump $dmp;

    my $xml = $indexer->to_xml( $dmp, $self, 1 );    # last 1 to strip plurals

    # hack in the authz string
    # currently Outcome authz is public to all users,
    # so this is just a placeholder.
    my @authz;
    my $authz_str = join( ",", @authz );
    my $root = $indexer->xml_root_element;
    $xml =~ s,^<$root,<$root authz="$authz_str",;

    return $xml;
}

1;

