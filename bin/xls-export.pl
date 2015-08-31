#!/usr/bin/env perl
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

use strict;
use warnings;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Getopt::Long;
use Pod::Usage;
use Email::Stuff;
use JSON;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::Bin;
use AIR2::User;
use AIR2::SrcResponseSet;
use Excel::Writer::XLSX;

=pod

=head1 NAME

xls-export

=head1 SYNOPSIS

 xls-export [options]
    --help
    --debug
    --logging
    --user_id=i
    --srs_id=i
    --bin_id=i
    --format=[stdout|file|email]
    --file=s

=head1 DESCRIPTION

xls-export outputs an excel spreadsheet for a src_response_set
or a bin containing multiple src_response_sets.

=cut

my ( $help, $debug, $logging, $user_id, $srs_id, $bin_id, $format, $file );
GetOptions(
    'help'      => \$help,
    'debug'     => \$debug,
    'logging'   => \$logging,
    'user_id=i' => \$user_id,
    'srs_id=i'  => \$srs_id,
    'bin_id=i'  => \$bin_id,
    'format=s'  => \$format,
    'file=s'    => \$file,
) or pod2usage(2);

if ($help) {
    pod2usage(2);
}
if ( !( $srs_id || $bin_id ) || ( $srs_id && $bin_id ) ) {
    pod2usage('Specify either a srs_id or a bin_id.');
}
$debug   = 0 unless defined $debug;
$logging = 0 unless defined $logging;

# file output
$format = 'file' if ( $file && !$format );
if ( $format && $format eq 'file' && !$file ) {
    pod2usage('Must specify a filename to write to');
}

# default to emailing the spreadsheet
$format = 'email' unless $format;
if ( $format ne 'stdout' && $format ne 'file' && $format ne 'email' ) {
    pod2usage(
        'Invalid format specified! Valid formats are (stdout|file|email)');
}

# check user and bin
my $user = AIR2::User->new( user_id => $user_id )->load;
if ( $format eq 'email' && !$user->get_primary_email() ) {
    croak "User " . $user->user_username . " has no email address!";
}
my $bin = 0;
if ($bin_id) {
    $bin = AIR2::Bin->new( bin_id => $bin_id )->load;
}

#################################################
## REAL WORK                                   ##
#################################################

# responses to process
my $srs_ids = $srs_id;
if ($bin_id) {
    $srs_ids
        = "select bsrs_srs_id from bin_src_response_set where bsrs_bin_id=$bin_id";
}

# authz on inquiry
my $readable_inq_ids = "select inq_id from inquiry";
if ( $user->user_type ne 'S' ) {
    my $authz = $user->get_authz();
    my @orgs;
    for my $orgid ( keys %{$authz} ) {
        my $bitmask = $authz->{$orgid};
        push( @orgs, $orgid )
            if (
            $AIR2::Config::ACTIONS{ACTION_ORG_PRJ_INQ_SRS_READ} & $bitmask );
    }
    my $org_ids = scalar @orgs ? join( ',', @orgs ) : 'null';
    my $prj_ids
        = "select porg_prj_id from project_org where porg_org_id in ($org_ids)";
    $readable_inq_ids
        = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";
}

# get bin_src_response_sets
my $srs_it = AIR2::SrcResponseSet->fetch_all_iterator(
    multi_many_ok => 1,
    with_objects  => [qw(source responses)],
    clauses => ["srs_id in ($srs_ids) and srs_inq_id in ($readable_inq_ids)"],
    sort_by => "srs_inq_id asc",
);

# Create a new Excel workbook
open my $fh, '>', \my $str or die "Failed to open filehandle: $!";
my $workbook = Excel::Writer::XLSX->new($fh);

# stylez
my $hstyle = $workbook->add_format();
$hstyle->set_bold();
$hstyle->set_align('center');
my $qstyle = $workbook->add_format();
$qstyle->set_bold();
$qstyle->set_align('left');
my $nstyle = $workbook->add_format();
$nstyle->set_align('left');

# keep things unique
my %inq_sheets;
my %inq_sheet_row_idx;
my %ques_id_to_col;
my %sheet_titles;

# go!
while ( my $srs = $srs_it->next ) {
    my $sheet = $inq_sheets{ $srs->srs_inq_id };
    my $row   = $inq_sheet_row_idx{ $srs->srs_inq_id };

    # create new sheet for inquiry
    unless ($sheet) {
        my $title = $srs->inquiry->inq_ext_title || $srs->inquiry->inq_title;
        $title =~ s/[\[\]:\*\?\/\\]/ /g;
        $title = substr( $title, 0, 31 );

        # try really hard to get a unique worksheet title
        $title = substr( "2 - $title", 0, 31 ) if $sheet_titles{ lc $title };
        $title = substr( "3 - $title", 0, 31 ) if $sheet_titles{ lc $title };
        $title = $srs->inquiry->inq_uuid if $sheet_titles{ lc $title };
        $sheet_titles{ lc $title } = $title;

        $sheet = $workbook->add_worksheet($title);
        $inq_sheets{ $srs->srs_inq_id } = $sheet;

        # generic headers
        my $col   = 0;
        my @names = (
            'Source UUID',
            'Tags',
            'Annotations',
            'Email Address',
            'First Name',
            'Last Name',
            'City',
            'State',
            'Postal Code',
            'Phone Number',
            'Gender',
            'Household Income',
            'Education Level',
            'Political Affiliation',
            'Ethnicity',
            'Religion',
            'Birth Year'
        );
        my @widths = (
            12, 13, 13, 20, 13, 13, 13, 13, 13, 13,
            13, 13, 13, 13, 13, 13, 13
        );
        for my $hdr (@names) {
            $sheet->set_column( $col, $col, $widths[$col] );
            $sheet->write( 0, $col++, $hdr, $hstyle );
        }

        # question headers
        my $num   = 1;
        my $quess = $srs->inquiry->questions_in_display_order();
        for my $ques (@$quess) {
            my $val = AIR2::Utils->str_clean( $ques->ques_value, 32000 );
            if ($val) {
                $ques_id_to_col{ $ques->ques_id } = $col;
                $sheet->set_column( $col, $col, 45 );
                $sheet->write_string( 0, $col++, $num++ . ' - ' . $val,
                    $qstyle );
            }
        }

        # start writing actual data at row 1
        $inq_sheet_row_idx{ $srs->srs_inq_id } = 1;
        $row = 1;
    }

    # write source data
    my $col = 0;
    $sheet->write_string( $row, $col++, $srs->source->src_uuid, $nstyle );

    # set tags
    my $tag_string = 0;

    for my $tag ( $srs->tags ) {

        # value
        if ($tag_string) {
            $tag_string .= ", ";
        }
        else {
            $tag_string = '';
        }

        $tag_string
            .= AIR2::Utils->str_clean( $tag->tagmaster->tm_name, 32000 );
    }

    $sheet->write_string( $row, $col++, $tag_string, $nstyle );

    # set annotations
    my $annot_string = 0;

    for my $srsa ( $srs->annotations ) {
        if ($annot_string) {
            $annot_string .= "\n\n";
        }
        else {
            $annot_string = '';
        }

        # value
        $annot_string .= AIR2::Utils->str_clean( $srsa->srsan_value, 32000 );

        #creator stamp
        $annot_string .= "\nCreated: " . $srsa->srsan_cre_dtim . " by ";
        $annot_string .= $srsa->cre_user->user_first_name . ' ';
        $annot_string .= $srsa->cre_user->user_last_name . ' (';
        $annot_string .= $srsa->cre_user->user_username . ")";

        #updater stamp
        if ( $srsa->srsan_upd_dtim != $srsa->srsan_cre_dtim ) {
            $annot_string .= "\n";
            $annot_string .= "Updated: " . $srsa->srsan_upd_dtim . " by ";
            $annot_string .= $srsa->upd_user->user_first_name . ' ';
            $annot_string .= $srsa->upd_user->user_last_name . ' (';
            $annot_string .= $srsa->upd_user->user_username . ")";
        }
    }

    $sheet->write_string( $row, $col++, $annot_string, $nstyle );

    my $eml = $srs->source->get_primary_email();
    $sheet->write_string( $row, $col++, $eml ? $eml->sem_email : '',
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->src_first_name || '',
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->src_last_name || '',
        $nstyle );

    my $addr = $srs->source->get_primary_address();
    my $phn  = $srs->source->get_primary_phone();
    $sheet->write_string( $row, $col++, $addr ? $addr->smadd_city : '',
        $nstyle );
    $sheet->write_string( $row, $col++, $addr ? $addr->smadd_state : '',
        $nstyle );
    $sheet->write_string( $row, $col++, $addr ? $addr->smadd_zip : '',
        $nstyle );
    $sheet->write_string( $row, $col++, $phn ? $phn->sph_number : '',
        $nstyle );

    $sheet->write_string( $row, $col++, $srs->source->get_gender(), $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_income(), $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_edu_level(),
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_pol_affiliation(),
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_ethnicity(),
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_religion(),
        $nstyle );
    $sheet->write_string( $row, $col++, $srs->source->get_dob(), $nstyle );

    # write responses
    for my $sr ( $srs->responses ) {
        my $val      = AIR2::Utils->str_clean( $sr->sr_orig_value, 32000 );
        my $modified = AIR2::Utils->str_clean( $sr->sr_mod_value,  32000 );
        if ($modified) {
            $val = 'Original: ' . $val . ' Modified: ' . $modified;
        }

        # add in question annotations
        my $annot_string = '';

        for my $sra ( $sr->annotations ) {

            # value
            $annot_string
                .= "\n\n" . AIR2::Utils->str_clean( $sra->sran_value, 32000 );

            #creator stamp
            $annot_string .= "\nCreated: " . $sra->sran_cre_dtim . " by ";
            $annot_string .= $sra->cre_user->user_first_name . ' ';
            $annot_string .= $sra->cre_user->user_last_name . ' (';
            $annot_string .= $sra->cre_user->user_username . ')';

            #updater stamp
            if ( $sra->sran_upd_dtim != $sra->sran_cre_dtim ) {
                $annot_string .= "\nUpdated: " . $sra->sran_upd_dtim . " by ";
                $annot_string .= $sra->upd_user->user_first_name . ' ';
                $annot_string .= $sra->upd_user->user_last_name . ' (';
                $annot_string .= $sra->upd_user->user_username . ')';
            }
        }

        if ( length($annot_string) ) {
            $val .= "\n\nAnnotations:" . $annot_string;
        }

        my $col = $ques_id_to_col{ $sr->sr_ques_id };
        $sheet->write_string( $row, $col, $val, $nstyle ) if ( $val && $col );
    }

    # increment row number on this sheet
    $inq_sheet_row_idx{ $srs->srs_inq_id }++;

    if ($logging) {
        my $now    = time();
        my $desc   = '{USER} exported XLSX containing source {SRC}';
        my $notes  = $bin ? $bin->bin_name : undef;
        my $srcid  = $srs->source->src_id;
        my $srs_id = $srs->srs_id;

        my $sact = AIR2::SrcActivity->new(
            sact_src_id   => $srcid,
            sact_actm_id  => 40,
            sact_ref_type => "R",
            sact_xid      => $srs_id,
            sact_dtim     => $now,
            sact_desc     => $desc,
            sact_notes    => $notes,
            sact_cre_dtim => $now,
            sact_upd_dtim => $now,
            sact_cre_user => $user_id,
            sact_upd_user => $user_id,
        );
        $sact->set_admin_update(1);
        $sact->save();
    }

}

if ( $logging && $bin != 0 ) {
    my $se = AIR2::SrcExport->new(
        se_name     => $bin->bin_name . '.xlsx',
        se_uuid     => AIR2::Utils->random_str(),
        se_type     => 'X',
        se_status   => 'C',
        se_xid      => $bin->bin_id,
        se_ref_type => 'I',                         #type bin
        se_cre_dtim => time(),
        se_upd_dtim => time(),
        se_cre_user => $user_id,
        se_upd_user => $user_id,
    );
    my $srs_count_query
        = "select count(*) bsrs_srs_id from bin_src_response_set where bsrs_bin_id=$bin_id";
    my $dbh       = $se->db->get_write_handle->retain_dbh;
    my $rs        = $dbh->selectrow_arrayref( $srs_count_query, undef );
    my $srs_count = $rs->[0];
    my $count_all = scalar $srs_count;
    my $count_exp = scalar $srs_it->total;
    $se->set_admin_update(1);
    $se->set_meta( 'initial_count', $count_all ) if defined $count_all;
    $se->set_meta( 'export_count',  $count_exp ) if defined $count_exp;
    $se->save();    # TODO: transaction?
}

# dump output to $str
$workbook->close();

# write to output format
if ( $format eq 'stdout' ) {
    binmode STDOUT;
    print $str;
    close STDOUT;
}
elsif ( $format eq 'file' ) {
    open OUTFILE, ">$file";
    binmode OUTFILE;
    print OUTFILE $str;
    close OUTFILE;
}
elsif ( $format eq 'email' ) {
    my $eml  = $user->get_primary_email()->uem_address();
    my $name = 'unknown';
    if ($srs_id) {
        my $srs = AIR2::SrcResponseSet->new( srs_id => $srs_id )->load;
        $name = $srs->inquiry->inq_title || $srs->inquiry->inq_ext_title;
    }
    else {
        my $bin = AIR2::Bin->new( bin_id => $bin_id )->load;
        $name = $bin->bin_name;
    }

    my $url = AIR2::Utils::write_secure_report( str => $str, ext => 'xlsx' );

    # fire!
    send_email(
        to      => $eml,
        from    => 'support@publicinsightnetwork.org',
        subject => "AIR Submission export results - $name",
        text    => (
            $srs_id
            ? "Exported submission for $name\n$url"
            : "Exported submissions for bin $name\n$url"
        ),
    );
}

sub send_email {
    my %args = @_;
    if ($debug) {
        dump \%args;
    }
    my $stuff = Email::Stuff->to( $args{to} )->from( $args{from} )
        ->subject( $args{subject} );
    if ( $args{text} ) {
        $stuff->text_body( $args{text} );
    }
    if ( $args{html} ) {
        $stuff->html_body( $args{html} );
    }
    if ( $args{attach} ) {
        $stuff->attach( @{ $args{attach} } );
    }
    my %mailer_args = ( Host => AIR2::Config->get_smtp_host, );
    if ( AIR2::Config->smtp_host_requires_auth ) {
        $mailer_args{username} = AIR2::Config->get_smtp_username;
        $mailer_args{password} = AIR2::Config->get_smtp_password;
    }
    my $smtp = Email::Send->new(
        {   mailer      => 'SMTP',
            mailer_args => [ %mailer_args, ]
        }
    ) or die "failed to create Email::Send::SMTP: $@ $!\n";
    my $result = $stuff->using($smtp)->send();

    $debug and warn $result;

    return $result;
}
