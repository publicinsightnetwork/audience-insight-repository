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

package AIR2::CodeMaster;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'code_master',

    columns => [
        cm_id         => { type => 'serial', not_null => 1 },
        cm_field_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        cm_code => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        cm_table_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        cm_disp_value => { type => 'varchar', length  => 128 },
        cm_disp_seq   => { type => 'integer', default => 10, not_null => 1 },
        cm_area       => { type => 'varchar', length  => 255 },
        cm_status => { type => 'character', length => 1, default => 'A', },
        cm_cre_user => { type => 'integer', not_null => 1 },
        cm_upd_user => { type => 'integer' },
        cm_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        cm_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['cm_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { cm_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { cm_upd_user => 'user_id' },
        },
    ],
);

=head2 lookup

Static method to get the display value for a code.

=cut

my %cm_lookup;

sub lookup {
    my $name = shift or die "field name required";
    my $code = shift;

    # cache on the first call
    if ( !%cm_lookup ) {
        %cm_lookup
            = map { $_->cm_field_name . '-' . $_->cm_code => $_->cm_disp_value }
            @{ AIR2::CodeMaster->fetch_all };
    }
    return ( defined $cm_lookup{"$name-$code"} )
        ? $cm_lookup{"$name-$code"}
        : $code;
}

1;

