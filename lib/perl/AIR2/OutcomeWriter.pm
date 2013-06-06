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

package AIR2::OutcomeWriter;
use strict;
use warnings;
use Text::CSV_XS;
use POSIX;
use IO::String;
use Carp;
use JSON;
use Rose::DateTime::Parser;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::User;
use AIR2::Organization;
use AIR2::Project;
use AIR2::Inquiry;
use AIR2::Outcome;
use AIR2::CSVWriter;

# define header order
my @hdr_order = (
    'PINfluence UUID',
    'Story Headline',
    'How the PIN influenced this story',
    'Content Link',
    'Publish/Air/Event Date',
    'Content Type',
    'Show in feeds',
    'Program/Event/Website',
    'Additional Information',
    'Created',
    'Creator',
    'Modified',
    'Organization',
    '# Projects',
    'Projects',
    '# Queries',
    'Queries',
    '# Informing Sources',
    '# Cited Sources',
    '# Featured Sources',
    'How: find authentic voices',
    'How: find insight quickly',
    'How: get ahead of the news',
    'How: identify stories that might have otherwise been missed',
    'How: pursue investigative reporting',
    'How: collaborate with another program, project or newsroom',
    'How: define a coverage stream or project',
    'How: other',
);

# simple out_column => header_name
my %hdr_map = (
    'PINfluence UUID'                   => 'out_uuid',
    'Story Headline'                    => 'out_headline',
    'How the PIN influenced this story' => 'out_teaser',
    'Content Link'                      => 'out_url',
    'Publish/Air/Event Date'            => 'out_dtim',
    'Content Type'                      => 'out_type',
    'Show in feeds'                     => 'out_status',
    'Program/Event/Website'             => 'out_show',
    'Additional Information'            => 'out_internal_teaser',
    'Created'                           => 'out_cre_dtim',
    'Modified'                          => 'out_upd_dtim',
);

=head2 get_obj( I<user_id>, [I<opts>] )

Get a generic object of outcomes.  A user_id MUST be passed, to run
authz against.

Valid options are:
   org_id:      limit to outcomes associated with an org
   prj_id:      limit to outcomes associated with a project
   inq_id:      limit to outcomes associated with an inquiry
   start_date:  limit to outcomes occurring after this dtim
   end_date:    limit to outcomes occurring before this dtim
   sources:     include source profile information on each row
   count:       just return the number of outcomes matched

=cut

sub get_obj {
    my $self    = shift;
    my $user_id = shift or die "user_id required";
    my $opts    = shift or ();

    # parser for dtim options
    my $date_parser = Rose::DateTime::Parser->new();

    # verify user TODO: authz
    my $user = AIR2::User->new( user_id => $user_id )->load_speculative;
    croak "user_id($user_id) not found!" unless ($user);

    # build query from opts
    my $query = [];
    if ($opts->{org_id}) {
        my $org_id = $opts->{org_id};
        my $org = AIR2::Organization->new( org_id => $org_id );
        croak "org_id($org_id) not found!" unless $org->load_speculative;
        push @{$query}, 'organization.org_id' => $org_id;
    }
    if ($opts->{prj_id}) {
        my $prj_id = $opts->{prj_id};
        my $prj = AIR2::Project->new( prj_id => $prj_id );
        croak "prj_id($prj_id) not found!" unless $prj->load_speculative;
        push @{$query}, 'projects.prj_id' => $prj_id;
    }
    if ($opts->{inq_id}) {
        my $inq_id = $opts->{inq_id};
        my $inq = AIR2::Inquiry->new( inq_id => $inq_id );
        croak "inq_id($inq_id) not found!" unless $inq->load_speculative;
        push @{$query}, 'inquiries.inq_id' => $inq_id;
    }
    if ($opts->{start_date}) {
        my $dt = $opts->{start_date};
        my $start = $date_parser->parse_date($dt) or die "Bad date: $dt";
        push @{$query}, out_dtim => {ge => $start};
    }
    if ($opts->{end_date}) {
        my $dt = $opts->{end_date};
        my $end = $date_parser->parse_date($dt) or die "Bad date: $dt";
        push @{$query}, out_dtim => {lt => $end};
    }

    # count-mode just returns the count
    if ($opts->{count}) {
        return Rose::DB::Object::Manager->get_objects_count(
            with_objects => [qw(projects inquiries organization)],
            multi_many_ok => 1,
            object_class => 'AIR2::Outcome',
            query => $query,
        );
    }

    # create query to get the outcomes
    my $out_it = AIR2::Outcome->fetch_all_iterator(
        with_objects => [
            qw(projects inquiries organization)
        ],
        multi_many_ok => 1,
        query => $query,
    );

    # create the csv object
    my @csv_obj;
    push( @csv_obj, [@hdr_order] );

    # add a bunch of stuff to the header, if this is a source csv
    if ($opts->{sources}) {
        my $src_hdrs = AIR2::CSVWriter->from_sources([], $user_id, {complex_facts => 1});
        die "bad headers from AIR2::CSVWriter" unless scalar @{$src_hdrs} == 1;
        push @{$csv_obj[0]}, "PINfluence Type";
        push @{$csv_obj[0]}, @{$src_hdrs->[0]};
    }

    # process outcomes
    while ( my $out = $out_it->next ) {
        my $row = outcome_to_row($out);

        # optionally transform into many rows, with source as key
        if ($opts->{sources}) {
            for my $sout ( @{$out->src_outcomes} ) {
                my $srow = src_outcome_to_row($sout, $row, $user_id);
                push @csv_obj, $srow;
            }
        }
        else {
            push @csv_obj, $row;
        }
    }

    # return ref
    return \@csv_obj;
}

# helper to transform outcome to row
sub outcome_to_row {
    my $out = shift or die "outcome required";
    my @row;
    my $survey_json = {};
    eval {
        my $json = decode_json( $out->out_survey );
        $survey_json = $json if $json; #ignore decode errors
    };

    # iterate through headers
    for my $colname ( @hdr_order ) {
        my $map_from = $hdr_map{$colname};

        #get column value
        if ($map_from) {
            my $val = $out->$map_from;
            if (ref $val eq 'DateTime') {
                $val = DateTime::Format::MySQL->format_datetime($val);
            }
            push @row, $val;
        }
        elsif ($colname eq 'Creator') {
            push @row, $out->cre_user->user_username;
        }
        elsif ($colname eq 'Projects') {
            my @prjnames;
            for my $prj ( @{$out->projects} ) {
                push @prjnames, $prj->prj_display_name;
            }
            push @row, join(', ', @prjnames);
        }
        elsif ($colname eq 'Organization') {
            push @row, $out->organization->org_display_name;
        }
        elsif ($colname eq 'Queries') {
            my @inqnames;
            for my $iout ( @{$out->inq_outcomes} ) {
                my $inq = $iout->inquiry;
                push @inqnames, $inq->inq_ext_title || $inq->inq_title;
            }
            push @row, join(', ', @inqnames);
        }
        elsif ($colname eq '# Projects') {
            push @row, $out->prj_outcomes_count;
        }
        elsif ($colname eq '# Queries') {
            push @row, $out->inq_outcomes_count;
        }
        elsif ($colname eq '# Informing Sources') {
            push @row, $out->src_outcomes_count( query => [sout_type => 'I']);
        }
        elsif ($colname eq '# Cited Sources') {
            push @row, $out->src_outcomes_count( query => [sout_type => 'C']);
        }
        elsif ($colname eq '# Featured Sources') {
            push @row, $out->src_outcomes_count( query => [sout_type => 'F']);
        }
        elsif ($colname =~ m/^How: /) {
            push @row, $survey_json->{substr($colname,5)} ? 'Yes' : 'No';
        }
        else {
            push @row, '';
            #die "Unknown column $colname";
        }
    }
    return \@row;
}

# helper to transform src_outcome to row
sub src_outcome_to_row {
    my $sout    = shift or die "src_outcome required";
    my $out_row = shift or die "outcome row required";
    my $user_id = shift or die "user_id required";
    my @row;

    # get the source data
    my $src_rows = AIR2::CSVWriter->from_sources( [$sout->sout_src_id],
        $user_id, {complex_facts => 1} );
    if (defined $src_rows->[1]) {
        push @row, @{$out_row};
        push @row, AIR2::CodeMaster::lookup( "sout_type", $sout->sout_type );
        push @row, @{$src_rows->[1]};
    }
    return \@row;
}

1;
