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

package AIR2::EmailInquiry;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'email_inquiry',

    columns => [

        # identifiers
        einq_email_id => { type => 'integer', not_null => 1 },
        einq_inq_id   => { type => 'integer', not_null => 1 },

        # meta
        einq_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        einq_cre_user => { type => 'integer',  not_null => 1 },
        einq_upd_user => { type => 'integer' },
        einq_cre_dtim => { type => 'datetime', not_null => 1 },
        einq_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'einq_email_id', 'einq_inq_id' ],

    foreign_keys => [
        email => {
            class       => 'AIR2::Email',
            key_columns => { einq_email_id => 'email_id' },
        },

        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { einq_inq_id => 'inq_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { einq_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { einq_upd_user => 'user_id' },
        },
    ],
);

1;
