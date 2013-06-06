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

package AIR2::ConventionManager;
use strict;
use warnings;
use base qw( Rose::DB::Object::ConventionManager );
use Data::Dump qw( dump );

# APM convention is to prefix table name to all columns.
# that is not RDBO convention. hack around it.

my %seen = ();

sub auto_foreign_key_name {
    my $self = shift;
    my ( $fclass, $cname ) = @_;

    #dump \@_;

    my $ret = $self->SUPER::auto_foreign_key_name(@_);

    #dump $ret;

    $ret = lc($fclass);
    $ret =~ s/^\w+:://;

    #warn "$fclass\n";

    if ( $ret eq 'factvalue' ) {

        #dump \@_;

        if ( $cname eq "src_fact_sf_src_fv_id_fact_value_fv_id" ) {
            $ret = 'source_facet_value';

        }
        elsif ( $cname eq "src_fact_sf_fv_id_fact_value_fv_id" ) {
            $ret = 'fact_value';
        }
        else {
            $ret = 'fact_value_unknown';
        }
    }

    if ( $ret eq 'source' ) {

        #dump \@_;

        if ( $cname eq "src_relationship_src_src_id_source_src_id" ) {

            $ret = 'source_2';

        }

    }
    if ( $ret eq 'user' ) {

        #dump \@_;

        if ( $cname =~ m/upd_user/ ) {

            $ret = 'upd_user';

        }
        elsif ( $cname =~ m/cre_user/ ) {

            $ret = 'cre_user';

        }

    }

    return $ret;
}
1;

