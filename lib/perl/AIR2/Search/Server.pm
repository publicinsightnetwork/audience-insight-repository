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

package AIR2::Search::Server;
use strict;
use warnings;
use base 'Dezi::Server';
use Carp;
use JSON;
use SWISH::Prog::InvIndex;
use Data::Dump qw( dump );
use Lingua::Stem::Snowball;
use AIR2::SearchUtils;
use AIR2::Search::Field;
use Search::Tools::UTF8;

our $VERSION = '2.000';

my %FORMATS = (
    'XML'   => 1,
    'JSON'  => 1,
    'ExtJS' => 1,
    'Tiny'  => 1,
);

# class metadata
my %server_meta = ();

=pod

=head1 NAME

AIR2::Search::Server - base class for searchers

=head1 METHODS

All AIR-specific method names are prefixed with C<air_>.

=cut

=head2 air_parse_params( I<params> )

Set up server defaults from HTTP request I<params>.

Returns hashref of request options.

=cut

sub air_parse_params {
    my $self = shift;
    my $params = shift or croak "params required";
    my %opts;

    $opts{q} = $params->{q} || $params->{query};
    $opts{sort} = $params->{s} || $params->{sort} || 'score DESC';
    $opts{dir}    = $params->{d} || $params->{dir} || '';  # direction in sort
    $opts{offset} = $params->{o} || $params->{start} || 0;
    $opts{size}   = $params->{p} || $params->{limit} || 25;
    $opts{hilite} = $params->{h};
    $opts{hilite} = 1
        unless ( defined $opts{hilite} and length $opts{hilite} );
    $opts{count_only}    = $params->{c} || $params->{count_only} || 0;
    $opts{limits}        = $params->{L} || [];
    $opts{meta_map}      = $params->{M} || 0;
    $opts{return_facets} = $params->{f} || 0;
    $opts{facet_cache_ok} = $params->{no_cache} ? 0 : 1;    # TODO support?
    $opts{uuids_only}     = $params->{u} || 0;
    $opts{return_results} = $params->{r};
    $opts{return_results} = 1 unless defined $opts{return_results};
    $opts{resp_format}    = $params->{t} || $params->{format} || 'ExtJS';
    $opts{authz}          = decode_json( $params->{auth_tkt} );
    $opts{boolop}         = $params->{b};

    # map "rank" to "score"
    $opts{sort} =~ s/\brank\b/score/gi;

    # concat sort+dir if necessary
    if ( length $opts{dir} and $opts{sort} !~ m/asc|desc/i ) {
        $opts{sort} .= ' ' . $opts{dir};
    }

    # only system users may avoid the required authz string
    if ((      !defined $opts{authz}->{authz}
            or !length $opts{authz}->{authz}
        )
        and ( exists $opts{authz}->{user}->{type}
            and $opts{authz}->{user}->{type} ne "S" )
        )
    {
        croak "Permission denied: missing authz for non-SYSTEM user.";
    }

    return \%opts;
}

=head2 air_parse_query( I<string>, I<opts> )

Returns a Search::Query::Dialect object.

=cut

sub air_parse_query {
    my ( $self, $q, $opts ) = @_;
    my $meta_map = $opts->{meta_map};

    #dump $self;
    my %args = %{ $self->{engine_config}->{searcher_config}->{qp_config} };
    $args{fields} = $self->air_get_meta('query_fields');

    if ($meta_map) {
        $args{default_field} = $meta_map;
    }
    elsif ( $self->air_get_default_field ) {
        $args{default_field} = $self->air_get_default_field;
    }

    # redmine #7142, disallow ? mark as wildcard
    $q =~ s/\?//g;

    # syntactic sugar for date fields
    $q =~ s/(\w+)[:=]NEVER/$1=19700101/g;

    #$self->log( dump \%args );

    my $parser = Search::Query->parser(%args);
    my $query = $parser->parse($q) or die $parser->error;
    return $query;
}

=head2 air_transform_query( I<query> )

Returns I<query> object updated with any server-side mutations.
Examples include always adding a:

 pin_status=active

clause.

=cut

sub air_transform_query {
    my ( $self, $query, $org_masks ) = @_;
    $query = $self->air_apply_authz( $query, $org_masks );
    return $query;
}

=head2 air_apply_authz( I<query_obj>, I<org_masks> )

Apply authorization rules to I<query_obj> based on permissions
specified in I<org_masks>.

Returns a new query object.

=cut

sub air_apply_authz {
    my ( $self, $query, $org_masks ) = @_;

    return $query unless defined $org_masks;

    # apply authz filter to exclude results for which the requester
    # does not have privileges.
    my $authz_str = $self->air_get_authz_string($org_masks);
    $query = $query->parser->parse("($query) AND ($authz_str)");

    return $query;
}

=head2 air_get_authz_string( I<org_masks> )

Returns string of organization ids OR'd together. Used by air_apply_authz().

=cut

sub air_get_authz_string {
    my ( $self, $org_masks ) = @_;
    return sprintf( "%s=(%s)",
        $self->air_get_authz_field,
        join( ' OR ', map {$_} keys %$org_masks ) );
}

=head2 air_get_authz_field

Should return string of the field name that authorization checks
are performed against. All subclasses must implement this method.

=cut

sub air_get_authz_field { croak "Must define air_get_authz_field() method" }

=head2 air_get_default_field

Should return name of field where all unspecified terms
are assigned.

Though the default is the empty string (""), 
B<never> leave it empty in a subclass, since it will be expanded to C<OR>
together every field, which can dramatically increase search time.
Instead, if you want all fields searched, use the top-level tag for the index, 
or swishdefault (since the top-level tag is aliased to 'swishdefault').

=cut

sub air_get_default_field { return "" }

=head2 air_get_meta

Returns invindex metadata for this Server.

=cut

sub air_get_meta {
    my $self  = shift;
    my $class = ref($self) ? ref($self) : $self;
    my $key   = shift or croak "key required";
    return $server_meta{$class}->{$key};
}

=head2 air_get_metanames 

Returns array ref of metanames (searchable fields).

=cut

sub air_get_field_names {
    my $self   = shift;
    my $class  = ref($self) ? ref($self) : $self;
    my @fields = keys %{ $server_meta{$class}->{metanames} };
    return \@fields;
}

=head2 air_get_real_metanames

Returns array ref of metanames like air_get_metanames, without
any field aliases.

=cut

sub air_get_real_metanames {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    my @fields
        = grep { !$server_meta{$class}->{metanames}->{$_}->{alias_for} }
        keys %{ $server_meta{$class}->{metanames} };
    return \@fields;
}

=head2 air_property_names

Returns array ref of field values returned in results.

=cut

sub air_property_names {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    my @fields
        = grep { !$server_meta{$class}->{properties}->{$_}->{alias_for} }
        keys %{ $server_meta{$class}->{properties} };
    return \@fields;
}

=head2 air_build_meta( I<index_path>, I<field_defs> )

Class method that should be called within each subclass new()
method.

=cut

sub air_build_meta {
    my ( $class, $index, $field_defs ) = @_;
    if ( ref($class) ) {
        croak "air_build_meta must be called as a class method";
    }
    my $invindex = SWISH::Prog::InvIndex->new( path => $index );
    my $meta = $invindex->meta;

    #dump $meta;

    # build field list to supplement what is hardcoded in $field_defs
    for my $metaname ( keys %{ $meta->MetaNames } ) {
        my $rec = $meta->MetaNames->{$metaname};
        $field_defs->{$metaname} = {};
        $server_meta{$class}->{metanames}->{$metaname} = {};
        if ( $rec->{alias_for} ) {
            push @{ $field_defs->{$metaname}->{alias_for} },
                $rec->{alias_for};
            push
                @{ $server_meta{$class}->{metanames}->{$metaname}->{alias_for}
                },
                $rec->{alias_for};
        }
    }

    # properties
    for my $propname ( keys %{ $meta->PropertyNames } ) {
        my $rec = $meta->PropertyNames->{$propname};
        $server_meta{$class}->{properties}->{$propname} = {};
        if ( $rec->{alias_for} ) {
            push @{ $server_meta{$class}->{properties}->{$propname}
                    ->{alias_for} },
                $rec->{alias_for};
        }
    }

    # add the built-ins
    $field_defs->{swishdefault} = {};

    # shortcut for all defined fields
    $field_defs->{all_fields}->{alias_for}
        = [ sort grep { !$field_defs->{$_}->{alias_for} } keys %$field_defs ];

    # store in class struct
    $server_meta{$class}->{query_fields} = $field_defs;

}

=head2 do_search

Override the Search::OpenSearch::Server::Plack method
to add query mangling and authorization rules.

=cut

sub do_search {
    my ( $self, $req ) = @_;
    my $params   = $req->parameters->mixed;
    my $opts     = $self->air_parse_params($params);
    my $response = $req->new_response;

    #$self->log( "opts: " . dump $opts );
    my $q = $opts->{q};
    if ( !defined($q) or !length($q) ) {
        $q = "swishlastmodified=(not 0)";    # i.e. find everything

        # last mod first unless explicitly overridden in request
        $opts->{sort} = 'lastmod DESC'
            if $opts->{sort} eq 'score DESC';
    }
    my $query;
    my $unauthz_total;
    my $search_response;

    # limit response fields per-request
    if ( exists $params->{x} ) {
        if ( ref $params->{x} ) {
            $opts->{x} = $params->{x};
        }
        elsif ( !defined $params->{x} or !length $params->{x} ) {

            # turn into empty array
            # this effectively limits fields to built-ins.
            $opts->{x} = [];
        }
        else {

            # force array
            $opts->{x} = [ $params->{x} ];
        }
    }

    eval {
        $query = $self->air_parse_query( to_utf8($q), $opts );

        $self->log("parsed query: $query");

        # trac #1362 add unauthz_total before we transform the query
        if (    exists $opts->{authz}
            and defined $opts->{authz}->{authz}
            and exists $opts->{authz}->{user}->{type}
            and $opts->{authz}->{user}->{type} ne "S" )
        {
            $opts->{org_masks}
                = AIR2::SearchUtils::unpack_authz( $opts->{authz}->{authz} );
        }
        $unauthz_total = $self->engine->searcher->search($query)->hits;

        $query = $self->air_transform_query( $query, $opts->{org_masks} );

        if ( !exists $FORMATS{ $opts->{resp_format} } ) {
            $self->log("bad format $opts->{resp_format} -- using ExtJS");
            $opts->{resp_format} = 'ExtJS';
        }

        if ( $opts->{uuids_only} ) {
            $search_response = $self->engine->get_uuids_only(
                q          => "$query",
                u          => $opts->{uuids_only},
                p          => $opts->{size},
                b          => $opts->{boolop},
                t          => $opts->{resp_format},
                link       => ( $self->engine->link || $req->base . '' ),
                authz      => $opts->{org_masks},
                uuid_field => $self->air_get_uuid_field,
            );
        }
        else {
            $search_response = $self->engine->search(
                q     => "$query",
                s     => $opts->{sort},
                o     => $opts->{offset},
                p     => $opts->{size},
                h     => $opts->{hilite},
                c     => $opts->{count_only},
                L     => $opts->{limits},
                f     => $opts->{return_facets},
                r     => $opts->{return_results},
                b     => $opts->{boolop},
                t     => $opts->{resp_format},
                x     => ( $opts->{x} || undef ),
                link  => ( $self->engine->link || $req->base . '' ),
                authz => $opts->{org_masks},
            );
        }
        $search_response->unauthz_total($unauthz_total);
    };

    my $errmsg;
    if (   $@
        or ( $search_response and $search_response->error )
        or $self->engine->error )
    {
        $errmsg = "$@";
        if ( !$errmsg and $search_response and $search_response->error ) {
            $errmsg = $search_response->error;
        }
        elsif ( !$errmsg and $self->engine->error ) {
            $errmsg = $self->engine->error;
        }
        warn sprintf( "[%s] %s", scalar localtime(), $errmsg );    # log it

        # trim the return to hide file and linenum
        $errmsg =~ s/ at [\w\/\.]+ line \d+\.?.*$//s;

        # reset
        $self->engine->error(undef);
        $search_response->error(undef) if $search_response;
    }

    if ( !$search_response or $errmsg ) {
        $errmsg ||= 'Internal error';
        $response->status(500);
        $response->content_type('application/json');
        $response->body( encode_json( { success => 0, error => $errmsg } ) );
    }
    else {
        $search_response->debug(1) if $opts->{debug};
        $response->status(200);
        $response->content_type( $search_response->content_type );
        $response->body("$search_response");
        if ( $self->stats_logger ) {
            $self->stats_logger->log( $req, $search_response );
        }
    }

    return $response->finalize();
}

1;
