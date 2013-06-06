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

package AIR2::Search::Engine::Projects;
use strict;
use warnings;
use base qw( AIR2::Search::Engine );
use Carp;
use Data::Dump qw( dump );

# fields snipped/highlighted in the summary
my @summary_fields = qw(
    inq_desc
    prj_desc
    inq_ext_title
    ques_value
);

# fields returned as an array instead of a string
my %multival_fields = map { $_ => $_ } qw(
    inq_uuid
    inq_desc
    inq_ext_title
    inq_uuid_title
    inq_title
    ques_uuid
    ques_value
    ques_choices
    org_name
    org_display_name
    org_uuid
    tag
);

# fields where unique values matter
my %collapse_dupe_fields = (

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
            AIR2::Utils->strtotime( $result->get_property('prj_upd_dtim') ),
    );

    $self->_fetch_prop_values( $result, \%res, $fields, \%multival_fields,
        \%collapse_dupe_fields, $XMLer );

    delete $res{ques_uuid};       # TODO re-evaluate
    delete $res{ques_value};      # TODO re-evaluate
    delete $res{ques_choices};    # TODO re-evaluate

    # hand-craft some values
    $res{uri} = $res{prj_uuid};
    $res{title} = $res{prj_display_name} || $res{prj_name};

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

    my %fields_matched
        = map { $_ => 1 } grep {length} @{ $swish_result->relevant_fields };

FIELD: for my $f (@summary_fields) {

        next unless exists $fields_matched{$f};

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
