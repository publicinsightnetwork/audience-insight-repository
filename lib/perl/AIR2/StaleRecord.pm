##########################################################################
#
#   Copyright 2013 American Public Media Group
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
package AIR2::StaleRecord;
use strict;
use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'stale_record',

    columns => [
        str_xid      => { type => 'integer',   not_null => 1 },
        str_upd_dtim => { type => 'datetime',  not_null => 1 },
        str_type     => { type => 'character', length   => 1, not_null => 1 },
    ],

    primary_key_columns => [ 'str_xid', 'str_type' ],
);

sub delete_all {
    my $class = shift;
    AIR2::DBManager->new->get_write_handle->dbh->do(
        "DELETE FROM " . $class->meta->table );
}

1;

