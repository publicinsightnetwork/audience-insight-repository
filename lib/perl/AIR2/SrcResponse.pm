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

package AIR2::SrcResponse;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'src_response',

    columns => [
        sr_id   => { type => 'serial', not_null => 1 },
        sr_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        sr_src_id  => { type => 'integer', default => '0', not_null => 1 },
        sr_ques_id => { type => 'integer', default => '0', not_null => 1 },
        sr_srs_id  => { type => 'integer', default => '0', not_null => 1 },
        sr_media_asset_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        sr_orig_value => { type => 'text', length => 65535 },
        sr_mod_value  => { type => 'text', length => 65535 },
        sr_status     => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        sr_public_flag => {
            type     => 'integer',
            default  => '0',
            not_null => 1,
        },
        sr_cre_user => { type => 'integer', not_null => 1 },
        sr_upd_user => { type => 'integer' },
        sr_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        sr_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['sr_id'],

    unique_keys => [ ['sr_uuid'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { sr_cre_user => 'user_id' },
        },

        question => {
            class       => 'AIR2::Question',
            key_columns => { sr_ques_id => 'ques_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { sr_src_id => 'src_id' },
        },

        srcresponseset => {
            class       => 'AIR2::SrcResponseSet',
            key_columns => { sr_srs_id => 'srs_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { sr_upd_user => 'user_id' },
        },
    ],

    relationships => [
        annotations => {
            class      => 'AIR2::SrAnnotation',
            column_map => { sr_id => 'sran_sr_id' },
            type       => 'one to many',
        },
    ],
);

my @indexables = qw(
    annotations
);

my @searchables = (
    @indexables, qw(
        )
);

sub get_searchable_rels { return [@searchables] }

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        $self->$rel;
    }
}

sub is_public {
    my $self     = shift;
    my $question = AIR2::SearchUtils::get_question( $self->sr_ques_id );

    my $public = 0;
    if ( $question->ques_public_flag == 1 && $self->sr_public_flag == 1 ) {
        $public = 1;
    }

    return $public;
}

1;

