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

package AIR2::Search::Server::Responses;
use strict;
use warnings;
use base qw( AIR2::Search::Server );
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;

sub new {
    my $class  = shift;
    my %config = @_;

    my @facet_names = qw(
        org_uuid
        tag
        inq_uuid_title
        prj_uuid_title
        srs_ts
    );

    # if no field specified in the search string,
    # limit search to these fields.
    my @default_search_fields = qw(
        qa
        qa_mod
        tag
        annotation
        src_uuid
        src_name
        src_username
        src_first_name
        src_last_name
        primary_email
        primary_phone
        primary_city
        primary_state
        primary_country
        primary_zip
        primary_county
        birth_year
        education_level
        ethnicity
        gender
        household_income
        political_affiliation
        religion
        primary_lat
        primary_long
        primary_lat_norm
        primary_long_norm
    );
    my $field_defs = {
        'answers_and_tags' => { alias_for => [qw( qa qa_mod tag )] },
        'submission'       => { alias_for => [qw( qa qa_mod )] },
        'default_fields'   => { alias_for => \@default_search_fields },
        'filter_fields' =>
            { alias_for => [ @default_search_fields, 'inq_uuid_title' ] },
    };

    my @no_hilite = qw(
        sact_prj_id
        inq_uuid
        permission_granted
        org_uuid
        srs_ts
    );

    my $index
        = AIR2::Config->get_search_index_path( $class->air_get_index_name );
    $class->air_build_meta( $index, $field_defs );

    my %args;

    # merge passed config with defaults here.
    $args{engine_config} = {
        type          => '+AIR2::Search::Engine::Responses',
        index         => [$index],
        parser_config => {

            # do not include - as term char
            term_re => qr/\w+(?:[\']\w+)*/,

            # do not include - as word char
            word_characters => q/\w/ . quotemeta(q/'/),
            query_dialect   => 'Lucy',
            ignore_fields   => [ @no_hilite, $class->air_get_authz_field, ],
            debug           => $config{debug},
            treat_uris_like_phrases => 1,

            # ignore terms shorter than 3 when hiliting/snipping
            term_min_length => 3,

            # Fuzzy* subclass uses this
            stemmer => $class->air_get_stemmer(),

        },
        snipper_config => {
            occur         => 3,     # number of snips
            context       => 100,   # number of words in each snip
            as_sentences  => 0,
            ignore_length => 1,     # ignore max_chars, return entire snippet.
            show          => 0,     # only show if match, no dumb substr
            treat_phrases_as_singles => 0,    # keep phrases together
        },
        facets        => { names => \@facet_names, },
        fields        => $class->air_property_names,
        do_not_hilite => { map { $_ => 1 } @no_hilite },
    };

    # merge with anything in config
    # we prefer anything set explicitly here to whatever is in dezi.config.pl
    for my $key ( keys %{ $config{engine_config} } ) {
        next if exists $args{engine_config}->{$key};
        $args{engine_config}->{$key} = $config{engine_config}->{$key};
    }
    for my $key ( keys %config ) {
        next if $key eq 'engine_config';
        $args{$key} = $config{$key};
    }

    my $self = $class->SUPER::new(%args);

    return $self;
}

my %no_response_fields = map { $_ => $_ } qw(

);

my $property_names;

sub air_property_names {
    my $self = shift;
    return $property_names if $property_names;

    my $base_fields = $self->SUPER::air_property_names();

    # mask some internal-use-only fields from public API response
    my @fields = sort grep { !exists $no_response_fields{$_} } @$base_fields;

    # memo-ize
    $property_names = \@fields;

    return \@fields;
}

sub air_get_index_name    {'responses'}
sub air_get_authz_field   {'responseset.authz'}
sub air_get_default_field {'default_fields'}
sub air_get_stemmer       { return undef }
sub air_get_uuid_field    {'srs_uuid'}

1;
