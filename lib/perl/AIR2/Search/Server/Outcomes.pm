package AIR2::Search::Server::Outcomes;
use strict;
use warnings;
use base 'AIR2::Search::Server';
use AIR2::Config;
use JSON;

sub new {

    my $class  = shift;
    my %config = @_;

    # single index for inquiries with stemming on
    my $snowball = Lingua::Stem::Snowball->new(
        lang     => 'en',
        encoding => 'UTF-8',
    );
    my $stemmer = sub {
        my ( $qp, $term ) = @_;
        return $snowball->stem($term);
    };

    my @facet_names = qw(
        tag
        inq_uuid_title
        prj_uuid_title
        org_uuid
    );

    my $field_defs = {
        1 => { alias_for => [qw( XXXask_title )] },
        2 => { alias_for => [qw( XXXaskq_text )] },
        3 => { alias_for => [qw( XXXcard_value )] },
    };
    my @no_hilite = qw(
        out_id
        out_uuid
        org_id
        org_uuid
        src_uuid
        prj_uuid
    );

    my $index = AIR2::Config->get_search_index_path('outcomes');
    $class->air_build_meta( $index, $field_defs );

    my %args;

    # merge passed config with defaults here.

    $args{engine_config} = {
        type          => '+AIR2::Search::Engine::Outcomes',
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
            stemmer         => $stemmer,
        },
        snipper_config => {
            occur         => 2,     # number of snips
            context       => 200,   # number of words in each snip
            as_sentences  => 1,
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
    XXX
);

sub air_property_names {
    return [
        qw(
            out_uuid
            out_headline
            out_internal_headline
            out_teaser
            out_internal_teaser
            out_show
            out_survey
            out_meta
            out_cre_dtim
            out_dtim
            out_url
            prj_uuid
            prj_uuid_title
            inq_uuid
            inq_uuid_title
            creator
            creator_uuid
            creator_fl
            tag
            org_id
            org_name
            org_uuid
            src_uuid
            )
    ];
}

sub air_get_authz_field   {'outcome.authz'}
sub air_get_default_field {'outcome'}

# authz is currently not applied to Outcomes search
sub air_apply_authz {
    my ( $self, $query, $org_masks ) = @_; 

    return $query;
}

1;
