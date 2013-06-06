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

package AIR2::SrcExport;
use strict;
use base qw(AIR2::DB);
use Carp;
use JSON;
use Data::Dump qw( dump );

__PACKAGE__->meta->setup(
    table => 'src_export',

    columns => [
        se_id   => { type => 'serial', not_null => 1 },
        se_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        se_prj_id   => { type => 'integer', },
        se_inq_id   => { type => 'integer', },
        se_email_id => { type => 'integer', },
        se_name     => { type => 'varchar', length => 255 },
        se_type => {
            type     => 'character',
            default  => 'L',
            length   => 1,
            not_null => 1
        },
        se_status => {
            type     => 'character',
            default  => 'I',
            length   => 1,
            not_null => 1
        },
        se_notes    => { type => 'text',      length   => 65535 },
        se_xid      => { type => 'integer' },
        se_ref_type => { type => 'character', length   => 1 },
        se_cre_user => { type => 'integer',   not_null => 1 },
        se_upd_user => { type => 'integer' },
        se_cre_dtim => { type => 'datetime',  not_null => 1 },
        se_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['se_id'],

    unique_keys => [ ['se_uuid'], ],

    foreign_keys => [
        email => {
            class       => 'AIR2::Email',
            key_columns => { se_email_id => 'email_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { se_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { se_upd_user => 'user_id' },
        },
    ],

);

sub get_meta {
    my $self    = shift;
    my $fldname = shift or croak "meta field name required";
    my $data    = {};
    eval {
        my $json = decode_json( $self->se_notes );    #ignore decode errors
        $data = $json if ($json);
    };
    return $data->{$fldname};
}

sub set_meta {
    my $self    = shift;
    my $fldname = shift or croak "meta field name required";
    my $fldval  = shift;
    my $data    = {};
    eval {
        my $json = decode_json( $self->se_notes );    #ignore decode errors
        $data = $json if ($json);
    };
    $data->{$fldname} = $fldval;
    $self->se_notes( encode_json($data) );
}

1;

