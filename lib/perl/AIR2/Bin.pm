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

package AIR2::Bin;

use strict;
use base qw(AIR2::DB);
use AIR2::Reader;
use Carp;

__PACKAGE__->meta->setup(
    table => 'bin',

    columns => [
        bin_id   => { type => 'serial', not_null => 1 },
        bin_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        bin_user_id => { type => 'integer', default => '0', not_null => 1 },
        bin_name    => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        bin_desc => {
            type   => 'varchar',
            length => 255
        },
        bin_type => {
            type     => 'character',
            default  => 'S',
            length   => 1,
            not_null => 1
        },
        bin_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        bin_shared_flag => { type => 'integer', default => 0, not_null => 1 },
        bin_cre_user => { type => 'integer', not_null => 1 },
        bin_upd_user => { type => 'integer' },
        bin_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        bin_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['bin_id'],

    unique_key => ['bin_uuid'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { bin_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { bin_upd_user => 'user_id' },
        },

        user => {
            class       => 'AIR2::User',
            key_columns => { bin_user_id => 'user_id' },
        },
    ],

    relationships => [
        sources => {
            class      => 'AIR2::BinSource',
            column_map => { bin_id => 'bsrc_bin_id' },
            type       => 'one to many',
        },
        response_sets => {
            class      => 'AIR2::BinSrcResponseSet',
            column_map => { bin_id => 'bsrs_bin_id' },
            type       => 'one to many',
        },
    ],
);

sub get_exportable_emails {
    my $self = shift;
    my $org  = shift or croak "org required";
    my $type = shift || 'E';
    my $soet = ( $type eq 'E' ) ? 'L' : 'M';
    my $mlid = ( $type eq 'E' ) ? $org->get_mlid() : $org->get_mailchimp_id();
    my $oid  = $org->org_id;
    my $sql  = qq/
    select sem_email,
           sem_status,
           sem_id,
           src_id,
           src_status,
           soe_id,
           soe_org_id,
           soe_status,
           soe_status_dtim,
           soe_type,
           soc_org_id,
           soc_status,
           org_name,
           UNIX_TIMESTAMP(sstat_export_dtim) as sstat_export_epoch
    from bin_source,source
    left join src_stat on src_id=sstat_src_id
    left join src_email on src_id=sem_src_id and sem_primary_flag=1
    left join src_org_cache on src_id=soc_src_id and soc_org_id = ?
    left join organization on soc_org_id=org_id
    left join src_org_email on sem_id=soe_sem_id and soe_type = ?  and soc_org_id in
        (select osid_org_id from org_sys_id where osid_type = ? and osid_xuuid = ? and osid_org_id = ?) and
        soc_org_id=soe_org_id
    where bsrc_bin_id = ? and bsrc_src_id=src_id
    order by sem_email
    /;

    my $dbh = $self->db->retain_dbh;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $oid, $soet, $type, $mlid, $oid, $self->bin_id );
    return AIR2::Reader->new( sth => $sth );
}

sub get_exportable_mailchimp_emails {
    my $self       = shift;
    my $org        = shift or croak "org required";
    my $oid        = $org->org_id;
    my $apm_org_id = AIR2::Config::get_apmpin_org_id();
    my $sql        = qq/ 
    select sem_email,
           sem_status,
           sem_id,
           src_id,
           src_status,
           soe_id,
           soe_type,
           soe_status,
           soe_status_dtim,
           soc_org_id,
           soc_status,
           org_name,
           UNIX_TIMESTAMP(sstat_export_dtim) as sstat_export_epoch
    from bin_source,source
    left join src_stat on src_id=sstat_src_id
    left join src_email on src_id=sem_src_id and sem_primary_flag=1
    left join src_org_cache on src_id=soc_src_id and soc_org_id = ?
    left join organization on soc_org_id=org_id
    left join src_org_email on sem_id=soe_sem_id and soe_type = 'M' and soe_org_id = ?
    where bsrc_bin_id = ? and bsrc_src_id=src_id
    order by sem_email
    /;

    my $dbh = $self->db->retain_dbh;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $oid, $apm_org_id, $self->bin_id );
    return AIR2::Reader->new( sth => $sth );
}

=head2 flatten( I<bin_id> )

Flatten the contents of a bin.  No authz will be applied here.

=cut

sub flatten {
    my $self = shift;
    my $bin_id;
    if ( !ref $self ) {
        $bin_id = shift or die "bin_id required";
        $self = AIR2::Bin->new( bin_id => $bin_id )->load;
    }
    else {
        $bin_id = $self->bin_id;
    }

    my @flat;

    # bin_src_response_sets (will be placed under the sources later)
    my %srcid_to_flatsrs;
    my $srs_ids
        = "select bsrs_srs_id from bin_src_response_set where bsrs_bin_id=$bin_id";
    my $srs_it = AIR2::SrcResponseSet->fetch_all_iterator(

    # with_objects  => [ qw(cre_user inquiry inquiry.cre_user inquiry.projects
    #     inquiry.organizations responses responses.question) ],
    # multi_many_ok => 1,
        clauses => ["srs_id in ($srs_ids)"],
    );
    while ( my $srs = $srs_it->next ) {
        my $src_id = $srs->srs_src_id;
        push @{ $srcid_to_flatsrs{$src_id} }, $srs->flatten;
    }

    # bin_sources
    my $bsrc_it = AIR2::BinSource->fetch_all_iterator(
        with_objects => [qw(source)],
        query        => [ bsrc_bin_id => $bin_id ],
    );
    while ( my $bsrc = $bsrc_it->next ) {
        my $src_id = $bsrc->source->src_id;
        my $src    = $bsrc->source->flatten;
        $src->{bsrc_notes} = $bsrc->bsrc_notes;
        $src->{bsrc_meta}  = $bsrc->bsrc_meta;

        # put any bin_src_response_sets under this source
        $src->{response_sets} = $srcid_to_flatsrs{$src_id} || [];
        push @flat, $src;
    }

    return \@flat;
}

1;
