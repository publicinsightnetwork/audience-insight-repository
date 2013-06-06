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

package AIR2::AdminRole;

use strict;
use base qw(AIR2::DB);
use Carp;
use AIR2::Config;

__PACKAGE__->meta->setup(
    table => 'admin_role',

    columns => [
        ar_id   => { type => 'serial',    not_null => 1 },
        ar_code => { type => 'character', length   => 1, not_null => 1 },
        ar_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        ar_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        ar_cre_user => { type => 'integer', not_null => 1 },
        ar_upd_user => { type => 'integer' },
        ar_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        ar_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['ar_id'],

    unique_keys => [ ['ar_code'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { ar_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { ar_upd_user => 'user_id' },
        },
    ],

    relationships => [
        user_org => {
            class      => 'AIR2::UserOrg',
            column_map => { ar_id => 'uo_ar_id' },
            type       => 'one to many',
        },
    ],
);

# ar_code => ar_id, as defined by fixture
my %fixture = (
    1 => 'X',    # reporter
    2 => 'R',    # reader
    3 => 'W',    # writer
    4 => 'M',    # manager
    5 => 'N',    # no-access
    6 => 'P',    # reader-plus/editor
    7 => 'F',    # freemium
);

=head2 get_bitmask( I<ar_id_or_code> )

Static method to get the bitmask representing a role

=cut

sub get_bitmask {
    my $code = shift or croak "ar_id or ar_code required";
    $code = $fixture{$code} if exists $fixture{$code};
    return $AIR2::Config::AUTHZ{$code} || 0;
}

1;

