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

package AIR2::Search::Engine::Responses;
use strict;
use warnings;
use base qw( AIR2::Search::Engine );
use Carp;
use Data::Dump qw( dump );

my %multival_fields = map { $_ => $_ } qw(
    qa
    qa_mod
    ques_uuid_value
    srsan_value
    sran_value
);

my %collapse_dupe_fields = map { $_ => $_ } qw(
);

my @virtual_fields = qw(
    primary_email_html
);

sub get_virtual_fields { return \@virtual_fields }

sub _summarize_srs_ts {
    my ( $self, $facets ) = @_;
    return $self->_do_date_range_summary($facets);
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
    my $query        = $snipper->query;

    my %res = (
        score => $result->score,
        uri   => $result->uri,
        mtime =>
            AIR2::Utils->strtotime( $result->get_property('srs_upd_dtim') ),
    );

    $self->_fetch_prop_values( $result, \%res, $fields, \%multival_fields,
        \%collapse_dupe_fields, $XMLer );

    # hand-craft some values
    $res{uri}   = $res{srs_uuid};
    $res{title} = $res{src_name};

    $res{primary_email_html} = $res{primary_email};

    # build the summary
    my @summary;

    # qa is a little tricky.
    # have to split out responses for highlighting.
    my @qa_ok;

   # we can't trust relevant_fields or query->fields
   # because we always want to return qa array regardless of where we searched
   #warn "relevant fields for $res{uri}=" . dump( $result->relevant_fields );
   #warn "query fields for $res{uri}=" . dump( $snipper->query->fields );

    # break ques_uuid_value into separate lookup hash for qa inflation
    my %ques_uuids = ();
    for my $quv ( @{ $res{ques_uuid_value} } ) {
        my ( $uuid, $value ) = ( $quv =~ m/^(\w+):(.+)$/s );
        $ques_uuids{$uuid} = $value;
    }

    my $got_qa_for_summary = 0;
    for my $qa ( @{ $res{qa} } ) {
        my ($authz_org_ids, $owner_org_ids, $inq_uuid,
            $ques_uuid,     $seq,           $type,
            $sr_uuid,       $public_flag,   $ques_public_flag,
            $date,          $upd_user,      $resp
            )
            = ( $qa
                =~ m/^(.+?):(.*?):(\w+):(\w+):(\d+):(\w):(\w+):(.):(.):(\d+-\d+-\d+ \d+:\d+:\d+):(\w+):(.*)$/os
            );

        my $hilited_resp = $resp;
        if ( defined $resp
            and length $resp )
        {

            # IMPORTANT turn on utf8 flag
            $resp = Search::Tools::UTF8::to_utf8($resp);
            if ( !$got_qa_for_summary and $query->matches_html($resp) ) {
                push @summary, $snipper->snip($resp);
                $got_qa_for_summary = 1;
            }

            if ($apply_hilite) {

                # 'F'ile question type does not get highlighting
                # see Redmine #5086
                if ( $type ne 'F' ) {
                    $hilited_resp = $hiliter->light($resp);
                }
                else {
                    $hilited_resp = $resp;
                }
            }
            else {
                $hilited_resp = $resp;
            }

        }
        $qa = {
            authz_orgs       => $authz_org_ids,
            owner_orgs       => $owner_org_ids,
            inq_uuid         => $inq_uuid,
            ques_uuid        => $ques_uuid,
            ques_value       => $ques_uuids{$ques_uuid},
            seq              => $seq,
            type             => $type,
            public_flag      => $public_flag,
            date             => $date,
            upd_user_uuid    => $upd_user,
            resp             => $hilited_resp,
            sr_uuid          => $sr_uuid,
            ques_public_flag => $ques_public_flag,
        };
        push @qa_ok, $qa;

    }

    $res{qa} = \@qa_ok;

    # modified responses
    if ($apply_hilite) {
        for my $qa_mod ( @{ $res{qa_mod} } ) {
            $qa_mod = $hiliter->light($qa_mod);
        }
    }

    # unpack public_flags
    my @public_flags = split( m/:/, $res{public_flags} );
    $res{public_flags} = {
        inq  => $public_flags[0],
        subm => $public_flags[1],
        ques => $public_flags[2],
        resp => $public_flags[3],
    };

    for my $v ( @{ $res{srsan_value} }, @{ $res{sran_value} } ) {
        if ( $query->matches_text($v) ) {
            push @summary, $hiliter->light( $snipper->snip($v) );
        }
    }

    my $summ = join( '...', @summary );

    # clean up
    $summ =~ s/(\.\.\.\ +)+/... /g;

    $res{summary} = $summ;

    # finally, apply hiliting

    # skip any fields we don't expect to have matches.
    my %fields_matched
        = map { $_ => 1 } grep {length} @{ $result->relevant_fields };
    for my $f (
        qw(
        summary
        title
        tag
        annotation
        src_name
        src_username
        src_first_name
        src_last_name
        primary_email_html
        primary_phone
        primary_city
        primary_state
        primary_country
        primary_zip
        primary_county
        birth_year
        education_level
        ethnicity
        gender
        household_income
        political_affiliation
        religion
        )
        )
    {

        if ( exists $fields_matched{$f} and $apply_hilite ) {

            # TODO worry about multi-val
            $res{$f} = $hiliter->light( $res{$f} );
        }
    }

    return \%res;
}

1;

