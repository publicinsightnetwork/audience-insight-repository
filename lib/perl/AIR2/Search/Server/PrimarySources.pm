package AIR2::Search::Server::PrimarySources;
use strict;
use warnings;
use base qw( AIR2::Search::Server::ActiveSources );
use Carp;
use Data::Dump qw( dump );
use Search::Query::Clause;

sub air_parse_query {
    my ( $self, $q, $opts ) = @_;
    my $query = $self->SUPER::air_parse_query( $q, $opts );
    my $org
        = ( $opts->{authz}->{user}->{type} eq 'S' )
        ? 0
        : $opts->{authz}->{user}->{home_org};
    my $clause = Search::Query::Clause->new(
        field => 'primary_org_name',
        op    => ':',
        value => $org,
    );
    $query->add_and_clause($clause);
    if ( !defined $query ) {
        croak "failed to add clause $clause";
    }
    $self->log("added primary_org_name to query: '$query'");
    return $query;
}

1;

