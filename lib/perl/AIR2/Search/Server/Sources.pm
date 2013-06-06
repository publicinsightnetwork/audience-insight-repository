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

package AIR2::Search::Server::Sources;
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
        smadd_state
        smadd_zip
        smadd_cntry
        smadd_county
        src_political_affiliation
        src_education_level
        src_household_income
        user_gender
        user_ethnicity
        user_religion
        birth_year
        lifecycle
        timezone
        last_contacted_date
        last_response_date
        last_activity_date
        first_response_date
        last_queried_date
        last_exported_date
        org_uuid
        org_status
        src_status
        tag
        prj_uuid
    );

    # REMEMBER to update AIR2::Search::Field
    # with any @profile_fields change
    # since these all require min length of 2 chars
    # in query terms
    my @profile_fields = qw(
        email
        phone
        src_last_name
        src_first_name
        src_username
        src_pre_name
        src_post_name
        src_uuid
        sa_first_name
        sa_last_name
        birth_year
        ethnicity
        gender
        experience_where
        experience_what
        interest
        tag
        annotation
        political_affiliation
        household_income
        education_level
        src_ethnicity
        src_gender
        src_political_affiliation
        src_household_income
        src_education_level
        primary_city
        primary_state
        primary_country
        primary_county
        primary_zip
        smadd_line_1
        smadd_line_2
    );
    my $field_defs = {
        profile  => { alias_for => \@profile_fields, },
        default  => { alias_for => [ @profile_fields, 'qa' ] },
        activity => { alias_for => [qw( sact_notes sact_desc )] },
    };

    # alias for an alias
    $field_defs->{'bio'} = $field_defs->{profile};

    my @no_hilite = qw(
        first_responded_date
        last_activity_date
        last_contacted_date
        last_response_date
        org_name
        org_status
        org_status_date
        org_uuid
        primary_city
        primary_country
        primary_county
        primary_email
        primary_phone
        primary_state
        primary_zip
        primary_org_name
        primary_org_uuid
        orgid_status
        so_org_id
        src_first_name
        src_last_name
        src_username
        src_uuid
        src_status
        src_id
        user_education_level_id
        user_ethnicity_id
        user_gender_id
        user_household_income_id
        src_education_level_id
        src_ethnicity_id
        src_gender_id
        src_household_income_id
        user_political_affiliation_id
        src_political_affiliation_id
        user_religion_id
        src_religion_id
        srs_id
        srs_uuid
        sact_actm_id
        so_org_id
        org_id
        response_sets.count
        activities.count
        valid_email
        src_channel
        src_has_acct
        out_uuid
        out_url
    );

    my $index
        = AIR2::Config->get_search_index_path( $class->air_get_index_name );
    $class->air_build_meta( $index, $field_defs );

    my %args;

    # merge passed config with defaults here.
    $args{engine_config} = {
        type          => '+AIR2::Search::Engine::Sources',
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

            # Fuzzy* subclases define this, we do not.
            stemmer => $class->air_get_stemmer(),
        },
        snipper_config => {
            occur         => 3,     # number of snips
            context       => 100,   # number of words in each snip
            as_sentences  => 1,
            ignore_length => 1,     # ignore max_chars, return entire snippet.
            show          => 0,     # only show if match, no dumb substr
            treat_phrases_as_singles => 0,    # keep phrases together
        },
        facets        => { names => \@facet_names, },
        fields        => $class->air_property_names,
        do_not_hilite => \@no_hilite,
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
    src_id
    orgid_status
    srs_id

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

sub air_get_index_name    {'sources'}
sub air_get_authz_field   {'source.authz'}
sub air_get_default_field {'default'}
sub air_get_uuid_field    {'src_uuid'}
sub air_get_stemmer       { return undef }

1;
