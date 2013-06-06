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

package AIR2::CSVWriter;
use strict;
use warnings;
use Text::CSV_XS;
use POSIX;
use IO::String;
use Carp;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::Bin;
use AIR2::User;
use AIR2::Source;
use AIR2::SrcActivity;
use AIR2::SrcExport;

# define header order
my @hdr_order = (
    'Source UUID',
    'Email Address',
    'Email Type',
    'First Name',
    'Last Name',
    'Middle Initial',
    'Address Type',
    'Address Line 1',
    'Address Line 2',
    'City',
    'State',
    'Country',
    'Postal Code',
    'Phone Type',
    'Phone Number',
    'Phone Extension',
    'Gender',
    'Ethnicity',
    'Religion',
    'Household Income',
    'Education Level',
    'Political Affiliation',
    'Birth Year',
    'Source Website',
    'Lifecycle',
    'Timezone',
    'Job Title',
    'Employer',
);
my %hdr_map = (
    'Source UUID',          => 'src_uuid',
    'Email Address'         => 'sem_email',
    'Email Type'            => 'sem_context',
    'First Name'            => 'src_first_name',
    'Last Name'             => 'src_last_name',
    'Middle Initial'        => 'src_middle_initial',
    'Address Type'          => 'smadd_context',
    'Address Line 1'        => 'smadd_line_1',
    'Address Line 2'        => 'smadd_line_2',
    'City'                  => 'smadd_city',
    'State'                 => 'smadd_state',
    'Country'               => 'smadd_cntry',
    'Postal Code'           => 'smadd_zip',
    'Phone Type'            => 'sph_context',
    'Phone Number'          => 'sph_number',
    'Phone Extension'       => 'sph_country',
    #gender
    'Gender'                => 'gender',
    'Gender Src Text'       => 'gender:srcval',
    'Gender Src Map'        => 'gender:srcmap',
    'Gender Map'            => 'gender:usrmap',
    #ethnicity
    'Ethnicity'             => 'ethnicity',
    'Ethnicity Src Text'    => 'ethnicity:srcval',
    'Ethnicity Src Map'     => 'ethnicity:srcmap',
    'Ethnicity Map'         => 'ethnicity:usrmap',
    #religion
    'Religion'              => 'religion',
    'Religion Src Text'     => 'religion:srcval',
    'Religion Src Map'      => 'religion:srcmap',
    'Religion Map'          => 'religion:usrmap',
    #household_income
    'Household Income'          => 'household_income',
    'Household Income Src Map'  => 'household_income:srcmap',
    'Household Income Map'      => 'household_income:usrmap',
    #education_level
    'Education Level'           => 'education_level',
    'Education Level Src Map'   => 'education_level:srcmap',
    'Education Level Map'       => 'education_level:usrmap',
    #political_affiliation
    'Political Affiliation'         => 'political_affiliation',
    'Political Affiliation Src Map' => 'political_affiliation:srcmap',
    'Political Affiliation Map'     => 'political_affiliation:usrmap',
    #birth_year
    'Birth Year'            => 'birth_year',
    'Birth Year Src Text'   => 'birth_year:srcval',
    #source_website
    'Source Website'            => 'source_website',
    'Source Website Src Text'   => 'source_website:srcval',
    #lifecycle
    'Lifecycle'             => 'lifecycle',
    'Lifecycle Src Map'     => 'lifecycle:srcmap',
    'Lifecycle Map'         => 'lifecycle:usrmap',
    #timezone
    'Timezone'              => 'timezone',
    'Timezone Src Text'     => 'timezone:srcval',
    #vita
    'Job Title'             => 'job_title',
    'Employer'              => 'employer',
);

# track the src_id order of the last csv object
my %last_order = ();

=head2 from_sources( I<src_ids>, I<user_id>, [I<opts>] )

Create a csv object from a bin_id.

Valid options are:
   complex_facts: use complex facts instead of the simplified ones
   log_activity:  create src_activity and src_export records
   bin_notes:     also append a bin_source notes column

=cut

sub from_bin {
    my $self     = shift;
    my $bin_id   = shift or die "bin_id required";
    my $user_id  = shift or die "user_id required";
    my $opts     = shift or ();

    # verify bin
    my $bin = AIR2::Bin->new( bin_id => $bin_id )->load_speculative;
    croak "bin_id($bin_id) not found!" unless ($bin);
    # TODO: authz on bin?

    # select sources from bin
    my $dbh = AIR2::DBManager->new()->get_write_handle->retain_dbh;
    my $fld = $opts->{bin_notes} ? 'bsrc_src_id, bsrc_notes' : 'bsrc_src_id';
    my $sel = "select $fld from bin_source where bsrc_bin_id = $bin_id";
    my $all = $dbh->selectall_arrayref( $sel );
    my @src_ids = map { $_->[0] } @{ $all };

    # apply authz and get csv
    my $authz_srcs = apply_authz( \@src_ids, $user_id );
    my $csv_obj = get_csv_obj( $authz_srcs, $opts );

    # optional notes
    if ( $opts->{bin_notes} ) {
        push( @{$csv_obj->[0]}, 'Bin Notes' );
        for my $row ( @{$all} ) {
            my $srcid = $row->[0];
            my $notes = $row->[1] ? $row->[1] : '';
            if ( $last_order{$srcid} ) {
                push( @{$csv_obj->[$last_order{$srcid}]}, $notes );
            }
        }
    }

    # log activity
    if ( $opts->{log_activity} ) {
        log_src_activity( $authz_srcs, $user_id, $bin );
        my $count_all = scalar @src_ids;
        my $count_exp = scalar @{$authz_srcs};
        log_src_export( $user_id, $bin, scalar @src_ids, scalar @{$authz_srcs} );
    }
    return $csv_obj;
}

=head2 from_sources( I<src_ids>, I<user_id>, [I<opts>] )

Create a csv object from an array of source ids.

Valid options are:
   complex_facts: use complex facts instead of the simplified ones
   log_activity:  create src_activity and src_export records

=cut

sub from_sources {
    my $self    = shift;
    my $src_ids = shift or die "array reference src_ids required";
    my $user_id = shift or die "user_id required";
    my $opts    = shift or ();

    # verify user
    my $user = AIR2::User->new( user_id => $user_id )->load_speculative;
    croak "user_id($user_id) not found!" unless ($user);

    # apply authz and get csv
    my $authz_srcs = apply_authz( $src_ids, $user_id );
    my $csv_obj = get_csv_obj( $authz_srcs, $opts );

    # log activity
    if ( $opts->{log_activity} ) {
        log_src_activity( $authz_srcs, $user_id );
    }
    return $csv_obj;
}

sub apply_authz {
    my $src_ids = shift or die "src_ids arrayref required";
    my $user_id = shift or die "user_id required";
    my $user = AIR2::User->new( user_id => $user_id )->load_speculative;
    croak "user_id($user_id) not found!" unless ($user);

    my $authz_srcs = $src_ids;
    if ($user->user_type ne 'S') {
        my $authz = $user->get_authz();
        my @orgs;
        for my $orgid ( keys %{$authz} ) {
            my $bitmask = $authz->{$orgid};
            push(@orgs, $orgid) if ($AIR2::Config::ACTIONS{ACTION_EXPORT_CSV} & $bitmask);
        }

        # use src_org_cache to find READable sources
        my $dbh = AIR2::DBManager->new()->get_write_handle->retain_dbh;
        my $sel = "select distinct soc_src_id from src_org_cache";
        my $orgstr = scalar @orgs ? join(',', @orgs) : 'null';
        my $srcstr = scalar @{$src_ids} ? join(',', @{$src_ids}) : 'null';
        $sel .= " where soc_org_id in ($orgstr) and soc_src_id in ($srcstr)";
        my $all = $dbh->selectall_arrayref( $sel );

        # swap $src_ids
        my @new_src_ids = map { $_->[0] } @{ $all };
        $authz_srcs = \@new_src_ids;
    }
    return $authz_srcs;
}

sub get_csv_obj {
    my $src_ids = shift or die "src_ids arrayref required";
    my $opts    = shift or ();

    # optionally use complex facts
    my @my_headers = @hdr_order;
    if ( $opts->{complex_facts} ) {
        my @complex = ('Src Text', 'Src Map', 'Map');

        @my_headers = ();
        for my $hdr ( @hdr_order ) {
            my $complex_used = 0;

            # check for complex fact
            for my $suffix ( @complex ) {
                my $cpx_hdr = "$hdr $suffix";
                if ($hdr_map{$cpx_hdr}) {
                    push(@my_headers, $cpx_hdr);
                    $complex_used = 1;
                }
            }

            # normal header
            push(@my_headers, $hdr) unless $complex_used;
        }
    }

    # create the csv object
    my @csv_obj;
    push( @csv_obj, [@my_headers] );
    return \@csv_obj unless scalar @{ $src_ids };

    my $src_it = AIR2::Source->fetch_all_iterator(
        with_objects => [
            qw(emails phone_numbers mail_addresses facts vitas)
        ],
        multi_many_ok => 1,
        query => [ src_id => $src_ids ],
    );

    # get unsorted results
    my %unsrt;
    while ( my $src = $src_it->next ) {
        my $flat = $src->flatten();
        my @row;

        for my $hdr ( @my_headers ) {
            my $fld = $hdr_map{$hdr};
            my $val = $flat->{$fld};
            $val = "" unless defined $val;
            push( @row, $val );
        }
        $unsrt{$src->src_id} = [@row];
    }

    # sort by the first column (email or blank)
    my @sort = sort { lc $unsrt{$a}->[0] cmp lc $unsrt{$b}->[0] } keys %unsrt;
    my $index = 0;
    %last_order = ();
    for my $key ( @sort ) {
        push( @csv_obj, $unsrt{$key} );
        $last_order{$key} = ++$index;
    }
    return \@csv_obj;
}

sub log_src_activity {
    my $src_ids = shift or die "src_ids arrayref required";
    my $user_id = shift or die "user_id required";
    my $bin     = shift;
    my $now     = time();
    my $desc    = '{USER} exported csv containing source {SRC}';
    my $notes   = $bin ? $bin->bin_name : undef;
    for my $srcid ( @{$src_ids} ) {
        my $sact = AIR2::SrcActivity->new(
            sact_src_id  => $srcid,
            sact_actm_id => 40,
            sact_dtim    => $now,
            sact_desc    => $desc,
            sact_notes   => $notes,
            sact_cre_dtim => $now,
            sact_upd_dtim => $now,
            sact_cre_user => $user_id,
            sact_upd_user => $user_id,
        );
        $sact->set_admin_update( 1 );
        $sact->save(); # TODO: transaction?
    }
}

sub log_src_export {
    my $user_id   = shift or die "user_id required";
    my $bin       = shift or die "bin object required";
    my $count_all = shift;
    my $count_exp = shift;
    my $se = AIR2::SrcExport->new(
        se_name     => $bin->bin_name.'.csv',
        se_uuid     => AIR2::Utils->random_str(),
        se_type     => 'C',
        se_status   => 'C',
        se_xid      => $bin->bin_id,
        se_ref_type => 'I', #type bin
        se_cre_dtim => time(),
        se_upd_dtim => time(),
        se_cre_user => $user_id,
        se_upd_user => $user_id,
    );
    $se->set_admin_update( 1 );
    $se->set_meta('initial_count', $count_all) if defined $count_all;
    $se->set_meta('export_count',  $count_exp) if defined $count_exp;
    $se->save(); # TODO: transaction?
}

1;
