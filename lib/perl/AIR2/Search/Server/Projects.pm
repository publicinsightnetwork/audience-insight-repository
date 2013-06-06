package AIR2::Search::Server::Projects;
use strict;
use warnings;
use base 'AIR2::Search::Server';
use AIR2::Config;
use JSON;

sub new {

    my $class  = shift;
    my %config = @_;

    # single index for projects with stemming on
    my $snowball = Lingua::Stem::Snowball->new(
        lang     => 'en',
        encoding => 'UTF-8',
    );
    my $stemmer = sub {
        my ( $qp, $term ) = @_;
        return $snowball->stem($term);
    };

    my @facet_names = qw(
        org_uuid
        tag
    );

    my $field_defs = { 1 => { alias_for => [qw( XXX )] }, };
    my @no_hilite = qw(
        org_id
        org_uuid
        ques_choices
    );

    my $index = AIR2::Config->get_search_index_path('projects');
    $class->air_build_meta( $index, $field_defs );

    my %args;

    # merge passed config with defaults here.

    $args{engine_config} = {
        type          => '+AIR2::Search::Engine::Projects',
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
        do_not_hilite => \@no_hilite,

        # TODO
        #            cache          => $FACET_CACHE,
        #            cache_ttl      => $CACHE_TTL,
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

sub air_get_authz_string {
    my ( $self, $org_masks ) = @_;
    my $str = $self->SUPER::air_get_authz_string($org_masks);
    return $str;
}

sub air_get_authz_field   {'project.authz'}
sub air_get_default_field {'project'}

1;
