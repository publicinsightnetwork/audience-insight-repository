###########################################################################
#
#   Copyright 2012 American Public Media Group
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

package AIR2::Search::Engine::PublicResponses;
use strict;
use warnings;
use base qw( AIR2::Search::Engine );
use Carp;
use Data::Dump qw( dump );
use AIR2::Utils;

my %multival_fields = map { $_ => $_ } qw(
    qa
);

my %collapse_dupe_fields = (

);

my @virtual_fields = (
    qw(
        questions
        responses
        )
);

sub get_virtual_fields { return \@virtual_fields }

sub _summarize_srs_ts {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub process_result {
    my ( $self, %args ) = @_;
    my $result       = $args{result};
    my $hiliter      = $args{hiliter};
    my $XMLer        = $args{XMLer};
    my $snipper      = $args{snipper};
    my $fields       = $args{fields};
    my $apply_hilite = $args{apply_hilite};
    my $org_masks    = $args{args}->{args}->{authz};
    my $query        = $snipper->query;

    my %res = (
        score => $result->score,
        uri   => $result->uri,
        title => $result->title,
        mtime =>
            AIR2::Utils->strtotime( $result->get_property('srs_upd_dtim') ),
    );

    $self->_fetch_prop_values( $result, \%res, $fields, \%multival_fields,
        \%collapse_dupe_fields, $XMLer );

   # we can't trust relevant_fields or query->fields
   # because we always want to return qa array regardless of where we searched
   #warn "relevant fields for $res{uri}=" . dump( $result->relevant_fields );
   #warn "query fields for $res{uri}=" . dump( $snipper->query->fields );
    my %questions;
    my %responses;

    if ( exists $res{qa} && $res{qa} ne "" ) {
        for my $qa ( @{ $res{qa} } ) {
            my ( $ques_uuid, $ques_type, $ques_seq, $ques_value, $resp )
                = ( $qa =~ m/^(.+?):(.+?):(.+?):(.+?):(.*?)$/s );

            if ( defined $resp ) {

                # IMPORTANT turn on utf8 flag
                $resp = Search::Tools::UTF8::to_utf8($resp);

                my $question = {
                    'seq'   => $ques_seq,
                    'type'  => $ques_type,
                    'value' => (
                          $apply_hilite
                        ? $hiliter->light($ques_value)
                        : $ques_value
                    ),
                };

                $questions{"$ques_uuid"} = $question;
                $responses{"$ques_uuid"}
                    = $apply_hilite ? $hiliter->light($resp) : $resp;
            }
        }

        $res{questions} = \%questions;
        $res{responses} = \%responses;
    }

    delete $res{qa};
    delete $res{swishdescription};
    delete $res{swishtitle};

    $res{summary} = '';    # required but empty

    # finally, apply hiliting
    for my $f (
        qw(
        title
        src_first_name
        src_last_name
        primary_city
        primary_state
        primary_country
        primary_zip
        primary_county
        )
        )
    {

        if ( $apply_hilite and exists $res{$f} ) {

            # TODO worry about multi-val
            $res{$f} = $hiliter->light( $res{$f} );
        }
    }

    return \%res;
}

=head2 search( I<args> )

Overrides base Engine method to hardcode public-only fields.

=cut

my @public_fields = qw(
    primary_city
    primary_country
    primary_county
    primary_lat
    primary_long
    primary_state
    primary_zip
    query_title
    query_uuid
    src_first_name
    src_last_name
    srs_upd_dtim
    questions
    responses
    lastmod
);

sub search {
    my $self = shift;
    my $resp = $self->SUPER::search(@_);
    if ( $resp->fields ) {
        $resp->fields( \@public_fields );
    }
    return $resp;
}

1;
