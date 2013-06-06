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

package AIR2::Search::Engine::Sources;
use strict;
use warnings;
use base qw( AIR2::Search::Engine );
use Carp;
use Data::Dump qw( dump );

# map fields => use_snip
my %summary_fields = (
    experience_what       => 1,
    experience_where      => 1,
    political_office      => 0,
    birth_year            => 0,
    education_level       => 0,
    ethnicity             => 0,
    gender                => 0,
    household_income      => 0,
    lifecycle             => 0,
    political_affiliation => 0,
    religion              => 0,
    source_website        => 0,
    interest              => 1,
    tag                   => 0,
    sact_notes            => 1,
    sact_desc             => 0,
    annotation            => 1,
    outcome               => 1,
    alias                 => 1,
);

# some fields (e.g. experience) are virtual,
# or search-only, not for display.
# map them to the fields that should be displayed instead.
my %summary_fields_alias
    = ( experience => [qw( experience_what experience_where )], );

my %multival_fields = map { $_ => $_ } qw(
    src_uuid
    qa
    response
    tag
    org_name
    org_uuid
    so_org_id
    org_status
    org_status_date
    org_status_year
    org_status_month
    inq_uuid
    prj_uuid
    sv_basis
    sv_value
    experience_what
    experience_where
    interest
    sact_desc
    sact_notes
    annotation
    outcome
    alias
    srs_uuid
    user_read
    inq_sent_date
    inq_org_date
    contacted_date
    contacted_year
    contacted_month
    activity_type_year
    activity_type_month
    activity_type_date

);

my %collapse_dupe_fields = map { $_ => $_ } qw(
    org_name
    org_uuid
    so_org_id
    inq_uuid
    prj_uuid
    src_username
    tag
    outcome
    alias
);

my @virtual_fields = qw(
    primary_location
    primary_email_html
);

sub get_virtual_fields { return \@virtual_fields }

sub search {
    my $self = shift;
    my $resp = $self->SUPER::search(@_);

    # more virtual fields, but not in index,
    # so we do not list them in @virtual_fields
    push @{ $resp->{fields} }, 'excerpts';
    push @{ $resp->{fields} }, 'qa_excerpts';

    # qa must be present to create qa_excerpts,
    # but we do not return it.
    $resp->{fields} = [ grep { $_ ne 'qa' } @{ $resp->{fields} } ];

    return $resp;
}

sub _summarize_last_contacted_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_last_response_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_first_response_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_last_activity_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_last_queried_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_last_exported_date {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
}

sub _summarize_smadd_zip {
    my ( $self, $facets ) = @_;

    my @zips;
    for my $f (@$facets) {
        my $zip = $f->{term};
        my $c   = $f->{count};

        # strip any zip-4 extensions
        $zip =~ s/^(\d\d\d\d\d).*/$1/;

        # skip any non-numerics (e.g. canadian)
        next if $zip =~ m/\D/;

        # segment
        next unless $zip =~ m/^(((\d)\d\d)\d\d)$/;
        my $one   = $3;
        my $three = $2;
        my $five  = $1;

        $zips[$one]->{count}                                       += $c;
        $zips[$one]->{threes}->{$three}->{count}                   += $c;
        $zips[$one]->{threes}->{$three}->{fives}->{$five}->{count} += $c;

    }

    # TODO this breaks API format
    return \@zips;
}

sub _summarize_birth_year {
    my ( $self, $facets ) = @_;

    my $this_year = (localtime)[5] + 1900;
    my %spans;
    my %terms = (
        "0-18" => sprintf( "(%d..%d)", ( $this_year - 18 ), $this_year ),
        "19-24" =>
            sprintf( "(%d..%d)", ( $this_year - 24 ), ( $this_year - 19 ) ),
        "25-34" =>
            sprintf( "(%d..%d)", ( $this_year - 34 ), ( $this_year - 25 ) ),
        "35-44" =>
            sprintf( "(%d..%d)", ( $this_year - 44 ), ( $this_year - 35 ) ),
        "45-54" =>
            sprintf( "(%d..%d)", ( $this_year - 54 ), ( $this_year - 45 ) ),
        "55-64" =>
            sprintf( "(%d..%d)", ( $this_year - 64 ), ( $this_year - 55 ) ),
        "65+" => sprintf( "(%d..%d)", 1900, ( $this_year - 65 ) ),
    );
    for my $f (@$facets) {
        my $year = $f->{term};
        my $c    = $f->{count};

        # skip any garbage
        if ( !$year or $year =~ m/\D/ or $year > $this_year or $year < 1900 )
        {
            $spans{"invalid"} += $c;
            next;
        }

        my $age = $this_year - $year;

        if ( $age < 19 ) {
            $spans{"0-18"} += $c;
        }
        elsif ( $age < 25 ) {
            $spans{"19-24"} += $c;
        }
        elsif ( $age < 35 ) {
            $spans{"25-34"} += $c;
        }
        elsif ( $age < 45 ) {
            $spans{"35-44"} += $c;
        }
        elsif ( $age < 55 ) {
            $spans{"45-54"} += $c;
        }
        elsif ( $age < 65 ) {
            $spans{"55-64"} += $c;
        }
        else {
            $spans{"65+"} += $c;
        }
    }

    # put it back in the API format
    my @ages;
    for my $span ( keys %spans ) {
        push @ages,
            {
            term  => $terms{$span},
            label => $span,
            count => $spans{$span}
            };
    }
    return \@ages;
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

    my %res = (
        score => $result->score,
        uri   => $result->uri,
        mtime => $result->mtime,
    );

    $self->_fetch_prop_values( $result, \%res, $fields, \%multival_fields,
        \%collapse_dupe_fields, $XMLer );

    # hand-craft some values
    $res{uri}      = $result->uri;
    $res{src_uuid} = $result->uri;
    $res{title}    = join( ', ',
        ( $res{src_last_name}  || '[last name]' ),
        ( $res{src_first_name} || '[first name]' ) );

    # use aliases
    $res{experience_what}  = delete $res{sv_value} || '';
    $res{experience_where} = delete $res{sv_basis} || '';

    $res{primary_location} = join(
        ', ',
        grep { defined and length } (
            $res{primary_city}, $res{primary_state},
            $res{primary_zip},  $res{primary_county}
        )
    );

    $res{primary_email_html} = $res{primary_email};

    # build the summary
    $self->_build_summary(
        swish_result => $result,
        snipper      => $snipper,
        result       => \%res,
        authz        => $org_masks,
        XMLer        => $XMLer,
        hiliter      => ( $apply_hilite ? $hiliter : 0 ),
    );

    # do not include full-text of responses,
    # instead preferring qa_extracts set in _build_summary()
    delete $res{qa};

    # finally, apply hiliting
    if ($apply_hilite) {
        for my $f (
            qw(
            summary
            title
            primary_location
            primary_email_html
            )
            )
        {
            $res{$f} = $hiliter->light( $res{$f} );
        }
    }

    return \%res;
}

sub _build_summary {
    my ( $self, %args ) = @_;
    my $swish_result = $args{swish_result};
    my $snipper      = $args{snipper};
    my $result       = $args{result};
    my $hiliter      = $args{hiliter};
    my $org_masks    = $args{authz};
    my $XMLer        = $args{XMLer};
    my $query        = $snipper->query;

    my @qa_excerpts;
    my @summary;
    my @excerpts;
    my %srs;
    my %fields_matched
        = map { $_ => 1 } grep {length} @{ $swish_result->relevant_fields };

    # some fields are aliased in etc/search config,
    # so the field name reported from relevant_fields
    # may need to be re-aliased to what we know it
    # as in %summary_fields
    my $prop_map = $swish_result->property_map;

    for my $f ( keys %fields_matched ) {
        if ( exists $summary_fields_alias{$f} ) {
            for my $alias ( @{ $summary_fields_alias{$f} } ) {

                # account for 2-steps of indirection
                my $field_name
                    = exists $prop_map->{$alias}
                    ? $prop_map->{$alias}
                    : $alias;
                $fields_matched{$field_name} = $f;
            }
        }
    }

    #warn dump( \%fields_matched );

    if ( exists $fields_matched{qa} and exists $result->{qa} ) {
        for my $qa ( @{ $result->{qa} } ) {
            my ($authz_org_ids, $owner_org_ids, $srs_uuid,
                $inq_uuid,      $ques_uuid,     $sr_public_flag,
                $seq,           $date,          $resp
                )
                = ( $qa
                    =~ m/^(.*?):(.*?):(\w+):(\w+):(\w+):(\d+):(\d+):(\d+-\d+-\d+ \d+:\d+:\d+):(.*)$/s
                );

            #warn "resp=$resp";
            if ( defined $resp and length $resp ) {
                my $snip = $snipper->snip($resp);

                #warn "snip=$snip";
                if ($snip) {
                    push @summary, $snip;
                    my $qae = {
                        srs_uuid      => $srs_uuid,
                        inq_uuid      => $inq_uuid,
                        public_flag   => $sr_public_flag,
                        date          => $date,
                        owner_org_ids => [ split( /,/, $owner_org_ids ) ],
                        authz_org_ids => [ split( /,/, $authz_org_ids ) ],
                        response =>
                            ( $hiliter ? $hiliter->hilite($snip) : $snip ),
                    };
                    if ( $srs{$srs_uuid} ) {
                        $qa_excerpts[ $srs{$srs_uuid} ]->{response}
                            .= ' ... ' . $qae->{response};
                    }
                    else {
                        push @qa_excerpts, $qae;
                        $srs{$srs_uuid} = $#qa_excerpts;
                    }
                }
            }
        }
    }
    else {
        $self->debug and warn sprintf(
            "[%s] %s = no qa in result\n",
            scalar localtime,
            $result->{uri}
        );
    }

    # summary fields are usually not snipped,
    # since the assumption is that they
    # are (a) short and (b) relevant only in full.
    if ( $query->num_terms ) {

    FIELD: for my $f ( keys %summary_fields ) {

            my $field_name
                = exists $prop_map->{$f}
                ? $prop_map->{$f}
                : $f;

            if ( !exists $fields_matched{$field_name} ) {
                $self->debug
                    and warn "$result->{uri}: No match for $field_name";
                next FIELD;
            }

            my $do_snip = 0;
            if ( $summary_fields{$f} ) {
                $do_snip = 1;
            }

            #warn "looking for $f snip=$do_snip";

            # already fetched
            if ( exists $result->{$f} ) {

                #warn "$f exists in result";
                if ( ref $result->{$f} ) {

                    #warn "$f is ref";
                VAL: for my $v ( @{ $result->{$f} } ) {
                        next if !defined $v or !length $v;

                        #warn "\$v=$v";

                        # some sact_notes store json values
                        if ( $f eq 'sact_notes' and $v =~ m/^\{/ ) {
                            next VAL;
                        }

                        if ( $query->matches_html($v) ) {

                            #warn "$v matches";

                            my $excerpt
                                = ( $do_snip ? $snipper->snip($v) : $v );

                            #warn "excerpt = $excerpt";
                            push @summary, $excerpt;
                            my $hilited_excerpt = (
                                  $hiliter
                                ? $hiliter->light($excerpt)
                                : $excerpt
                            );

                            #warn "hilited = $hilited_excerpt";
                            push @excerpts,
                                {
                                field => $f,
                                snip  => $hilited_excerpt,
                                };
                            next FIELD;
                        }
                        else {

                            #warn "$query does not match $v";
                        }
                    }
                }

                elsif ( defined $result->{$f}
                    and length $result->{$f}
                    and $query->matches_html( $result->{$f} ) )
                {
                    my $excerpt = (
                          $do_snip
                        ? $snipper->snip( $result->{$f} )
                        : $result->{$f}
                    );
                    push @summary, $excerpt;
                    push @excerpts,
                        {
                        field => $f,
                        snip  => $hiliter
                        ? $hiliter->light($excerpt)
                        : $excerpt
                        };
                    next FIELD;
                }
                else {

                    #warn "$query does not match $result->{$f}";
                }
            }

            # need to fetch
            else {

                #warn "$f not yet in result";
                my $prop;
                eval {
                    $prop = $XMLer->escape(
                        $XMLer->strip_markup(
                            $swish_result->get_property($f), 1
                        )
                    );
                };
                if ($prop) {

                    # See redmine #6423
                    $prop =~ s/&apos;/'/g;

                VAL: for my $v ( split( m/\003/, $prop ) ) {
                        next if !defined $v or !length $v;

                        # some sact_notes store json values
                        if ( $f eq 'sact_notes' and $v =~ m/^\{/ ) {
                            next VAL;
                        }

                        if ( $query->matches_html($v) ) {

                            my $excerpt
                                = ( $do_snip ? $snipper->snip($v) : $v );
                            push @summary, $excerpt;
                            push @excerpts,
                                {
                                field => $f,
                                snip  => (
                                      $hiliter
                                    ? $hiliter->light($excerpt)
                                    : $excerpt
                                ),
                                };
                            next FIELD;
                        }
                        else {

                            #warn "$query does not match $v";
                        }
                    }
                }
            }
        }
    }

    $result->{excerpts}    = \@excerpts;
    $result->{qa_excerpts} = \@qa_excerpts;

    return $self->_cleanup_summary( $result, @summary );
}

1;
