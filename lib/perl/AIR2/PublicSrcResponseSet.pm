###########################################################################
#
#   Copyright 2010 American Public Media Group
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

package AIR2::PublicSrcResponseSet;
use strict;
use warnings;
use base qw( AIR2::SrcResponseSet );
use Carp;
use Data::Dump qw( dump );
use Rose::DateTime::Parser;
use Search::Tools::XML;

# legacy hacks
my %last_initial_only = ( b6f315470887 => 'librarius', );

my $date_parser
    = Rose::DateTime::Parser->new( time_zone => $AIR2::Config::TIMEZONE );

my @indexables = qw(
    responses
);

my @searchables = (@indexables);

sub get_searchable_rels { return [@searchables] }

=head2 as_xml( I<args> )

Returns SrcResponseSet as XML string, suitable for indexing.

I<args> should contain a Rose::DBx::Object::Indexed::Indexer
object and other objects relevant to the XML structure.
See bin/resp2xml.pl for example usage.

=cut

sub as_xml {
    my $set     = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $set->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');

    # since there are relatively few responses-per-source, we'll just
    # load the source and related data every time.
    # TODO: is this really the fastest?
    # TODO: more indexable rels
    $set->load_indexable_rels;
    for my $sr ( @{ $set->responses } ) {
        $sr->load_indexable_rels;
    }

    # load standalone ojbects, so they don't get serialized into the xml
    my $source  = AIR2::SearchUtils::get_source( $set->srs_src_id );
    my $inquiry = AIR2::SearchUtils::get_inquiry( $set->srs_inq_id );

    # turn object into a hash tree
    my $dmp = $indexer->serialize_object($set);

    # annotations are private, internal only
    delete $dmp->{annotations};

    $dmp->{title} = $set->srs_uuid;

    # src_response_set data
    my $srs_date = $date_parser->parse_date( $dmp->{srs_date} );
    $dmp->{srs_ts}    = $srs_date->ymd('');
    $dmp->{srs_year}  = $srs_date->year;
    $dmp->{srs_month} = $srs_date->year . $srs_date->month;

    # source
    $dmp->{src_uuid} = $source->src_uuid;

    # build contributor field hash from individual responses,
    # and cached srs_* geo columns,
    # not the source profile. redmine #7103
    my %contributor = ();
    for my $contrib_field (
        qw( first_name last_name city state country postal_code ))
    {
        my $method   = 'get_' . $contrib_field . '_response';
        my $response = $set->$method;
        if ($response) {
            $contributor{$contrib_field}
                = $response->sr_mod_value
                || $response->sr_orig_value
                || '';
        }
        else {
            $contributor{$contrib_field} = '';
        }
    }

    # make sure geo fields are populated
    my $geo_updated = $set->set_geo_cache();

    # TODO should we save() if $geo_updated ?
    # altering the db on an assumed read-only method like this
    # is philosophically suspect.
    # the regular cron job geo-fillin-gaps will save the changes
    # eventually anyway.

    for my $geo_field (qw( county city state country lat long )) {
        if (    exists $contributor{$geo_field}
            and defined $contributor{$geo_field}
            and length $contributor{$geo_field} )
        {
            next;
        }
        my $cached_method = 'srs_' . $geo_field;
        $contributor{$geo_field} = $set->$cached_method || '';
    }
    $dmp->{src_first_name} = $contributor{'first_name'};
    $dmp->{src_last_name}  = $contributor{'last_name'};

    if ( exists $last_initial_only{ $inquiry->inq_uuid } ) {
        $dmp->{src_last_name} =~ s/^(.).*/$1/;
    }
    $dmp->{primary_city}    = $contributor{city};
    $dmp->{primary_state}   = $contributor{state};
    $dmp->{primary_country} = $contributor{country};
    $dmp->{primary_zip}     = $contributor{postal_code};
    $dmp->{primary_county}  = $contributor{county};
    $dmp->{primary_lat}     = $contributor{lat};
    $dmp->{primary_long}    = $contributor{long};

    # for range-searching, normalize lat/long (lat+90, long+180),
    # and fix the width, resulting in a range of:
    # latitude  - 000.000000..180.000000
    # longitude - 000.000000..360.000000
    if ( $dmp->{primary_lat} && $dmp->{primary_long} ) {
        $dmp->{primary_lat_norm}
            = sprintf( "%010.6f", $dmp->{primary_lat} + 90.0 );
        $dmp->{primary_long_norm}
            = sprintf( "%010.6f", $dmp->{primary_long} + 180.0 );
    }

    my $sorg = $source->get_primary_newsroom;

    if ($sorg) {
        $dmp->{primary_org_uuid}         = $sorg->org_uuid;
        $dmp->{primary_org_name}         = $sorg->org_name;
        $dmp->{primary_org_display_name} = $sorg->org_display_name;
    }

    # inquiry - inq_orgs - project - organization
    $dmp->{query_uuid}  = $inquiry->inq_uuid;
    $dmp->{query_title} = $inquiry->get_title();
    $dmp->{inq_uri}     = $inquiry->get_uri();
    if ( $inquiry->inq_publish_dtim ) {
        $dmp->{inq_publish_dtim} = AIR2::SearchUtils::dtim_to_ymd_hms(
            $inquiry->inq_publish_dtim );
    }

    my @inq_orgs;
    for my $org ( @{ $inquiry->organizations } ) {
        push @inq_orgs,
            {
            inq_org_name       => $org->org_name,
            inq_org_id         => $org->org_id,
            inq_org_uuid       => $org->org_uuid,
            inq_org_html_color => $org->org_html_color,
            };
    }
    $dmp->{inq_orgs} = \@inq_orgs;

    my @prj_authz;    # while we're at it, get authz
    my @projects;
    my @organizations;
    for my $pinq ( @{ $inquiry->project_inquiries } ) {
        push @projects,
            {
            prj_uuid         => $pinq->project->prj_uuid,
            prj_name         => $pinq->project->prj_name,
            prj_display_name => $pinq->project->prj_display_name,
            prj_uuid_title   => join( ':',
                $pinq->project->prj_uuid,
                $pinq->project->prj_display_name ),
            };
        push @organizations,
            {
            org_names => $pinq->project->get_org_names(),
            org_uuids => $pinq->project->get_org_uuids(),
            org_ids   => $pinq->project->get_org_ids(),
            };
        push @prj_authz, @{ $pinq->project->get_authz() };
    }
    $dmp->{projects}      = \@projects;
    $dmp->{organizations} = \@organizations;
    my $prj_authz_str = join ',', @prj_authz;

    # response - question
    my @resp_ids;
    my @public_questions;
    my @public_responses;
    my @public_response_values;
    for my $resp ( @{ $dmp->{responses} } ) {

        if ( $resp->{sr_public_flag} == 1 ) {

            # get the question from the memoized inquiry
            my $ques;
            for my $q ( @{ $inquiry->questions } ) {
                if (   $resp->{sr_ques_id} == $q->ques_id
                    && $q->ques_public_flag == 1 )
                {
                    $ques = $q;
                    last;
                }
            }

            if ($ques) {

                # in theory no contributor-type response will
                # have a public_flag of 1, but we exclude here
                # just in case
                next if $ques->ques_type eq 'Z';
                next if $ques->ques_type eq 'S';    # state
                next if $ques->ques_type eq 'Y';    # country

                my $mod_value  = delete $resp->{sr_mod_value};
                my $orig_value = delete $resp->{sr_orig_value};
                my $value      = $orig_value;

                # make sure we have a visible modified value,
                # before we override. redmine #7382
                if (    defined($mod_value)
                    and length($mod_value)
                    and $mod_value =~ m/\S/ )
                {
                    $value = $mod_value;
                }

                # virtual field for finding
                # specific answers to specific questions
                # preserve html in questions #9149
                my $ques_value = Search::Tools::XML->escape($ques->ques_value);
                push @public_responses,
                    join( '|',
                    $ques->ques_uuid,    $ques->ques_type,
                    $ques->ques_dis_seq, $ques_value,
                    ( $value || '' ) );
                push( @public_response_values, $value ) if $value;
                push(
                    @public_questions,
                    {   ques_uuid  => $ques->ques_uuid,
                        ques_value => $ques->ques_value,
                    }
                );
            }

        }

    }

    $dmp->{questions} = \@public_questions;

    # only public responses go in the XML.
    $dmp->{responses} = \@public_response_values;

    # virtual field 'qas' will get split by to_xml()
    # into individual 'qa' virtual fields.
    $dmp->{qas} = \@public_responses;

    # lowercase versions of fields, for sortability
    my @lowercase
        = qw(src_first_name src_last_name primary_city primary_org_name
        primary_org_display_name inq_title inq_ext_title);
    for my $fld (@lowercase) {
        if ( $dmp->{$fld} ) {
            $dmp->{ $fld . "_lc" } = lc $dmp->{$fld};
        }
    }

    my $xml = $indexer->to_xml( $dmp, $set, 1 );    # 1 to strip plurals

    return $xml;
}

sub requires_indexing_ids {
    my $self     = shift;
    my $mod_date = shift or croak "mod_date required";
    my $count    = shift || 0;
    if ( !$mod_date->isa('DateTime') ) {
        croak "mod_date must be a DateTime object";
    }
    my $dt = join( ' ', $mod_date->ymd('-'), $mod_date->hms(':') );
    my $debug = $Rose::DB::Object::Manager::Debug;
    my %ids;
    my $dbh = $self->init_db->retain_dbh;

    # use hand-crafted sql for speed and consistency with find-all
    my $sql;
    if ($count) {
        $sql = $self->get_sql_all_count();
    }
    else {
        $sql = $self->get_sql_all();
    }

    my @tstamps = qw(srs_upd_dtim sr_upd_dtim inq_upd_dtim);
    $sql .= sprintf( "and (%s)", join( ' or ', map {"$_ >= ?"} @tstamps ) );

    #warn "sql: $sql";
    my $sth = $dbh->prepare($sql);
    $sth->execute( map {$dt} @tstamps );

    if ($count) {
        return $sth->fetch->[0];
    }

    while ( my $r = $sth->fetch ) {
        my $id = $r->[0];
        $ids{$id}++;
    }

    return [ keys %ids ];
}

sub get_sql_all {
    my $class = shift;    # class or instance method ok

    my $sql = <<SQL;
select distinct(srs_id)
from src_response_set,inquiry,src_response
where srs_inq_id=inq_id 
  and srs_id=sr_srs_id
  and srs_public_flag=1 
  and inq_public_flag=1 
  and srs_id in 
   (select sr_srs_id    
    from src_response
    where sr_public_flag=1      
      and sr_ques_id in 
      (select ques_id from question where ques_public_flag=1) 
   )
SQL

    return $sql;
}

sub get_sql_all_count {
    my $class = shift;                   # class or instance method ok
    my $sql   = $class->get_sql_all();
    $sql =~ s/^select distinct\(srs_id\)/select count(distinct srs_id)/;
    return $sql;
}

1;
