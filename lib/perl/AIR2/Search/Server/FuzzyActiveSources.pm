package AIR2::Search::Server::FuzzyActiveSources;
use strict;
use warnings;
use base qw( AIR2::Search::Server::ActiveSources );
use Carp;
use Data::Dump qw( dump );
use Lingua::Stem::Snowball;

sub air_get_index_name {'fuzzy_sources'}

sub air_get_stemmer {

    # single index for projects with stemming on
    my $snowball = Lingua::Stem::Snowball->new(
        lang     => 'en',
        encoding => 'UTF-8',
    );
    my $stemmer = sub {
        my ( $qp, $term ) = @_;
        return $snowball->stem($term);
    };
    return $stemmer;
}

1;
