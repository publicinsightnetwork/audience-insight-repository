package AIR2::Search::Server::ActiveResponses;
use strict;
use warnings;
use base qw( AIR2::Search::Server::Responses );
use Carp;
use Data::Dump qw( dump );
use Search::Query::Clause;

sub air_parse_query {
    my ( $self, $q, $opts ) = @_;
    my $query = $self->SUPER::air_parse_query( $q, $opts );
    my $clause = Search::Query::Clause->new(
        field => 'src_status',
        op    => ':',
        value => '(engaged or enrolled or unverified)'
    );
    $query->add_and_clause($clause);
    if ( !defined $query ) {
        croak "failed to add clause $clause";
    }
    $self->log("added active src_status to query: '$query'");
    return $query;
}

sub air_apply_authz {
    my ( $self, $query, $org_masks ) = @_;
    return $query unless defined $org_masks;
    $query = $self->SUPER::air_apply_authz( $query, $org_masks );

    # Active Responses should exclude hits where the source
    # is not active in the same org(s) as the user
    my $active_orgs = sprintf( "orgid_status=(%s)",
        join( ' OR ', map { $_ . '_A' } keys %$org_masks ) );
    $query = $query->parser->parse("($query) AND ($active_orgs)");
    return $query;
}

1;
