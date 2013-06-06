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
        email_cre_user => { type => 'integer',  not_null => 1 },
        email_upd_user => { type => 'integer' },
        email_cre_dtim => { type => 'datetime', not_null => 1 },
        email_upd_dtim => { type => 'datetime' },
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

1;
