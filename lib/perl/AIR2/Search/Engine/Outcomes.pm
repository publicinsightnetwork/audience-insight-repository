###########################################################################
#
#   Copyright 2015 American Public Media Group
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

package AIR2::Search::Engine::Outcomes;
use strict;
use warnings;
use base qw( AIR2::Search::Engine );
use Carp;
use Data::Dump qw( dump );

my @summary_fields = qw(
    out_teaser
);

my %multival_fields = map { $_ => $_ } qw(
    src_uuid
    src_name
    prj_uuid
    prj_uuid_title
    inq_uuid
    inq_uuid_title
    tag
    annotation
);

my %collapse_dupe_fields = map { $_ => $_ } qw(
    inq_uuid
    prj_uuid
    inq_uuid_title
    prj_uuid_title
);

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
        mtime =>
            AIR2::Utils->strtotime( $result->get_property('out_dtim') ),
    );

    $self->_fetch_prop_values( $result, \%res, $fields, \%multival_fields,
        \%collapse_dupe_fields, $XMLer );

    # hand-craft some values
    $res{uri} = $res{out_uuid};
    $res{title} = $res{out_headline} || $res{out_internal_headline};

    # build the summary
    $self->_build_summary(
        swish_result => $result,
        snipper      => $snipper,
        result       => \%res,
        authz        => $org_masks,
        XMLer        => $XMLer,
        hiliter      => ( $apply_hilite ? $hiliter : 0 ),
    );

    # finally, apply hiliting
    for my $f (
        qw(
        summary
        title
        )
        )
    {
        if ($apply_hilite) {
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

    my @summary;
FIELD: for my $f (@summary_fields) {

        # already fetched
        if ( exists $result->{$f} ) {
            if ( ref $result->{$f} ) {
                for my $v ( @{ $result->{$f} } ) {
                    if ( $query->matches_text($v) ) {
                        push @summary, $v;
                        next FIELD;
                    }
                }
            }
            elsif ( $query->matches_text( $result->{$f} ) ) {
                push @summary, $result->{$f};
                next FIELD;
            }
        }

        # need to fetch
        else {
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

                for my $v ( split( m/\003/, $prop ) ) {
                    if ( $query->matches_text($v) ) {
                        push @summary, $v;
                        next FIELD;
                    }
                }
            }
        }
    }

    return $self->_cleanup_summary( $result, @summary );
}

1;
