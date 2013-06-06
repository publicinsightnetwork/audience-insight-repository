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

package AIR2::Discriminator;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );
use AIR2::Config;
use AIR2::Utils;

my $OP_IGNORE      = 'I';
my $OP_REPLACE     = 'R';
my $OP_ADD         = 'A';
my $OP_ADD_PRIMARY = 'P';

my $APMPIN_ORG_ID    = 1;
my $GLOBALPIN_ORG_ID = 44;

my %case_insensitive = (
    src_username       => 1,
    src_first_name     => 1,
    src_last_name      => 1,
    src_middle_initial => 1,
    src_pre_name       => 1,
    src_post_name      => 1,
    sa_name            => 1,
    sa_first_name      => 1,
    sa_last_name       => 1,
    sa_post_name       => 1,
    smadd_line_1       => 1,
    smadd_line_2       => 1,
    smadd_city         => 1,
    smadd_zip          => 1,
    sf_src_value       => 1,
    sem_email          => 1,
);

sub update_field {
    my ( $fldname, $tsrc, $rec, $ops, $valid_ops, $default_op ) = @_;
    my $newval = AIR2::Utils->str_clean( $tsrc->$fldname );
    my $op = $ops->{$fldname} || $default_op;

    # decode the operation --- can be something like "R|new_value_here"
    $op = '' unless $op;
    if ( length $op > 1 && substr( $op, 1, 1 ) eq '|' ) {
        $newval = substr( $op, 2 );    #replace newval
        $op = substr( $op, 0, 1 );     #chop to 1 char
    }

    # ignore invalid operations
    $valid_ops = '' unless $valid_ops;
    $op = '' if ( index( $valid_ops, $op ) == -1 );

    # update the current value
    my $currval = AIR2::Utils->str_clean( $rec->$fldname );
    if ( defined $newval && length $newval ) {
        if ( !defined $currval || !length $currval ) {
            $rec->$fldname($newval);
        }
        else {

            my $exists = $rec->primary_key_value()   ? 1           : 0;
            my $v1     = $case_insensitive{$fldname} ? lc $currval : $currval;
            my $v2     = $case_insensitive{$fldname} ? lc $newval  : $newval;

            # conflict - process operations
            if ( $v1 ne $v2 ) {
                if ( $op eq $OP_IGNORE ) {

                    # no-op
                }
                elsif ( $op eq $OP_REPLACE ) {
                    $rec->$fldname($newval);
                }
                elsif ( $op eq $OP_ADD && !$exists ) {
                    $rec->$fldname($newval);
                }
                elsif ( $op eq $OP_ADD_PRIMARY && !$exists ) {
                    $rec->$fldname($newval);

                    # attemp to set as primary
                    if ( $fldname =~ m/^(\w+)_.+/ ) {
                        my $prime = $1 . '_primary_flag';
                        $rec->$prime(1) if defined $rec->$prime;
                    }
                }
                elsif ( !$exists ) {
                    $rec->$fldname($newval);    #just overwrite default values
                }
                else {

                    # no good! return conflict - MUST be encodable!!
                    my $confl = {
                        fld => $fldname,
                        val => $currval,
                        ops => $valid_ops,
                    };
                    if ( $fldname =~ m/^([^_]+)/ ) {
                        my $uuid = $1 . '_uuid';
                        my $pkid = $1 . '_id';
                        if ( $rec->meta->column($uuid) ) {
                            $confl->{uuid} = $rec->$uuid;
                        }
                        elsif ( $rec->meta->column($pkid) ) {
                            $confl->{uuid} = $rec->$pkid;
                        }
                    }

                    # format date objects
                    if (   $currval
                        && blessed($currval)
                        && $currval->isa('DateTime') )
                    {
                        $confl->{val}
                            = DateTime::Format::MySQL->format_datetime(
                            $currval);
                    }
                    return $confl;
                }
            }
        }
    }
    return 0;    #no conflict
}

sub source {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;

    # process alias-able fields
    my %alias = (
        src_first_name => 'sa_first_name',
        src_last_name  => 'sa_last_name',
    );
    for my $fld ( keys %alias ) {
        if ( $tsrc->$fld ) {
            my $sa_fld = $alias{$fld};

            # add as an alias
            if ( $ops->{$fld} && $ops->{$fld} eq 'A' ) {
                my $sal = AIR2::SrcAlias->new();
                $sal->$sa_fld( $tsrc->$fld );
                $tsrc->source->add_aliases($sal);
                $sal->sa_src_id( $tsrc->source->src_id )
                    ; # TODO: why does above line fail to set src_id ONLY for alias?
                $sal->save();
            }

            # search for alias (case insensitive)
            elsif ( my $c
                = update_field( $fld, $tsrc, $tsrc->source, $ops, 'IRA' ) )
            {
                my $has_alias = 0;
                for my $sal ( @{ $tsrc->source->aliases } ) {
                    my $salval = lc( $sal->$sa_fld || '' );
                    $has_alias = 1 if ( lc $tsrc->$fld eq $salval );
                }
                $conflicts->{$fld} = $c unless $has_alias;
            }
        }
    }

    # remaining fields
    my @flds
        = qw(src_username src_middle_initial src_pre_name src_post_name src_channel);
    for my $fld (@flds) {
        if ( my $c = update_field( $fld, $tsrc, $tsrc->source, $ops, 'IR' ) )
        {
            $conflicts->{$fld} = $c;
        }
    }
    $tsrc->source->save();
}

sub email {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;
    return 0 unless ( $tsrc->sem_email );

    # search for existing (or create new)
    my $main_op = $ops->{sem_email} || '';
    my $rec = 0;
    for my $sem ( @{ $tsrc->source->emails } ) {
        next if ( $main_op eq 'A' || $main_op eq 'P' );
        next unless ( $sem->sem_email && $tsrc->sem_email );
        $rec = $sem if ( lc $sem->sem_email eq lc $tsrc->sem_email );
    }
    unless ($rec) {
        $rec = AIR2::SrcEmail->new();
        $tsrc->source->add_emails($rec);
    }

    # update primary (no conflict)
    $rec->sem_primary_flag(1) if ( $tsrc->sem_primary_flag );

    # process
    my @flds = qw(sem_context sem_effective_date sem_expire_date);
    for my $fld (@flds) {
        if ( my $c = update_field( $fld, $tsrc, $rec, $ops, 'IR' ) ) {
            $conflicts->{$fld} = $c;
        }
    }
    my $c = update_field( 'sem_email', $tsrc, $rec, $ops, 'IRAP' );
    $conflicts->{sem_email} = $c if $c;
    $rec->sem_email( lc $rec->sem_email );    #ALWAYS lowercased
    $rec->save();

    # update the primary (most primary, most recent)
    my @sorted = sort {
               $b->sem_primary_flag <=> $a->sem_primary_flag
            || $b->sem_id <=> $a->sem_id
    } @{ $tsrc->source->emails };
    my $idx = 0;
    for my $sem (@sorted) {
        $sem->sem_primary_flag( ( $idx++ == 0 ) ? 1 : 0 );
        $sem->save();
    }
}

sub phone {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;
    return 0 unless ( $tsrc->sph_number );

    # search for existing (or create new)
    my $main_op = $ops->{sph_number} || '';
    my $rec = 0;
    for my $sph ( @{ $tsrc->source->phone_numbers } ) {
        next if ( $main_op eq 'A' || $main_op eq 'P' );
        next unless ( $sph->sph_number && $tsrc->sph_number );

        # TODO: smarter number comparison
        $rec = $sph if ( $sph->sph_number eq $tsrc->sph_number );
    }
    unless ($rec) {
        $rec = AIR2::SrcPhoneNumber->new();
        $tsrc->source->add_phone_numbers($rec);
    }

    # update primary (no conflict)
    $rec->sph_primary_flag(1) if ( $tsrc->sph_primary_flag );

    # process
    my @flds = qw(sph_context sph_country sph_ext);
    for my $fld (@flds) {
        if ( my $c = update_field( $fld, $tsrc, $rec, $ops, 'IR' ) ) {
            $conflicts->{$fld} = $c;
        }
    }
    my $c = update_field( 'sph_number', $tsrc, $rec, $ops, 'IRAP' );
    $conflicts->{sph_number} = $c if $c;
    $rec->save();

    # update the primary (most primary, most recent)
    my @sorted = sort {
               $b->sph_primary_flag <=> $a->sph_primary_flag
            || $b->sph_id <=> $a->sph_id
    } @{ $tsrc->source->phone_numbers };
    my $idx = 0;
    for my $sph (@sorted) {
        $sph->sph_primary_flag( ( $idx++ == 0 ) ? 1 : 0 );
        $sph->save();
    }
}

sub address {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;
    return 0
        unless ( $tsrc->smadd_line_1
        || $tsrc->smadd_line_2
        || $tsrc->smadd_city
        || $tsrc->smadd_state
        || $tsrc->smadd_zip );

    # default to creating new
    my $newrec = AIR2::SrcMailAddress->new();

    # search for existing
    my $currec = 0;
    my @idents = qw(smadd_line_1 smadd_city smadd_zip);
    for my $smadd ( @{ $tsrc->source->mail_addresses } ) {
        for my $col (@idents) {
            next unless ( $tsrc->$col && $smadd->$col );
            $currec = $smadd if ( lc $tsrc->$col eq lc $smadd->$col );
        }
    }

    # SPECIAL: pick the longest zip if they match (55102 vs 55102-1533)
    if ( $currec && $currec->smadd_zip && $tsrc->smadd_zip ) {
        my $old = $currec->smadd_zip;
        my $new = $tsrc->smadd_zip;
        $tsrc->smadd_zip($old)   if ( $old =~ m/^$new/ );
        $currec->smadd_zip($new) if ( $new =~ m/^$old/ );
    }

    # if there are any ADDs, don't copy to existing record
    my $used_add = 0;
    for my $fld ( keys %{$ops} ) {
        my $fld_op = $ops->{$fld};
        if ( $ops->{$fld}
            && ( $ops->{$fld} eq $OP_ADD || $ops->{$fld} eq $OP_ADD_PRIMARY )
            )
        {
            $used_add = 1;
        }
    }

    # process - in this case, we can split the input into new/existing recs
    my $used_newrec    = 0;
    my $new_is_primary = 0;
    my @flds           = qw(smadd_context smadd_line_1 smadd_line_2 smadd_city
        smadd_state smadd_cntry smadd_zip smadd_lat smadd_long);
    my %def_ops = (
        smadd_primary_flag => 'R',    #replace!
    );
    for my $fld (@flds) {
        my $fld_op     = $ops->{$fld} || '';
        my $fld_df     = $def_ops{$fld};
        my $rec_to_use = $currec;
        if ( !$rec_to_use ) {
            $rec_to_use  = $newrec;
            $used_newrec = 1;
        }

        # special case: primary
        $new_is_primary = 1 if ( $fld_op eq $OP_ADD_PRIMARY );

        # update new record if any ADDs were used
        if ( $fld_op ne $OP_REPLACE && $used_add ) {
            $used_newrec = 1;
            $rec_to_use  = $newrec;
        }
        if ( my $c = update_field( $fld, $tsrc, $rec_to_use, $ops, 'IRAP' ) )
        {
            $conflicts->{$fld} = $c;
        }

        # copy to both if both an ADD and REPLACE are used
        if ( $fld_op eq $OP_REPLACE && $used_add ) {
            update_field( $fld, $tsrc, $newrec, undef, 'I', 'I' );
        }
    }

    # set primary from tsrc
    if ($new_is_primary) {
        $newrec->smadd_primary_flag(1);
    }
    elsif ( $tsrc->smadd_primary_flag && $currec ) {
        $currec->smadd_primary_flag(1);
    }
    elsif ( $tsrc->smadd_primary_flag && !$currec ) {
        $newrec->smadd_primary_flag(1);
    }

    # save changes
    $tsrc->source->add_mail_addresses($newrec) if ($used_newrec);
    $newrec->save()                            if ($used_newrec);
    $currec->save()                            if ($currec);

    # update the primary (most primary, most recent)
    my @sorted = sort {
               $b->smadd_primary_flag <=> $a->smadd_primary_flag
            || $b->smadd_id <=> $a->smadd_id
    } @{ $tsrc->source->mail_addresses };
    my $idx = 0;
    for my $smadd (@sorted) {
        $smadd->smadd_primary_flag( ( $idx++ == 0 ) ? 1 : 0 );
        $smadd->save();
    }
}

# facts which will default to overwriting existing values
my %overwrite_facts = (
    household_income      => 1,
    education_level       => 1,
    political_affiliation => 1,
    religion              => 1,
    source_website        => 1,
    lifecycle             => 1,
    timezone              => 1,
);

sub fact {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;

    # move facts
    for my $tf ( @{ $tsrc->facts } ) {
        next
            unless ( $tf->sf_fv_id
            || defined $tf->sf_src_value
            || $tf->sf_src_fv_id );

        # lookup/create src_fact
        my $id = $tf->fact->fact_identifier;
        my $sf = $tsrc->source->get_srcfact($id);
        unless ($sf) {
            $sf = AIR2::SrcFact->new( sf_fact_id => $tf->tf_fact_id );
            $tsrc->source->add_facts($sf);
        }

        # custom validation on birth year
        if ( $id eq 'birth_year' ) {
            my $currsane
                = ( $sf->sf_src_value || '' ) =~ m/[12][0-9][0-9][0-9]/;
            my $newsane
                = ( $tf->sf_src_value || '' ) =~ m/[12][0-9][0-9][0-9]/;

            # try to keep the sanest thing
            next if ( $currsane && !$newsane );
            $sf->sf_src_value( $tf->sf_src_value )
                if ( $newsane && !$currsane );
        }

        # decode operations for this fact_ident
        my $default_op = $overwrite_facts{$id} ? 'R' : undef;
        my $ident_ops;
        if ( $ops->{$id} ) {
            $ident_ops->{sf_fv_id}     = $ops->{$id};
            $ident_ops->{sf_src_value} = $ops->{$id};
            $ident_ops->{sf_src_fv_id} = $ops->{$id};
        }

        # update from tank_fact, encoding/decoding ops
        my @flds = qw(sf_fv_id sf_src_value sf_src_fv_id);
        for my $fld (@flds) {
            $ident_ops->{$fld} = $ops->{"$id.$fld"} if $ops->{"$id.$fld"};
            if ( my $c
                = update_field( $fld, $tf, $sf, $ident_ops, 'IR',
                    $default_op ) )
            {

                # set the conflict UUID manually as "sf_src_id.sf_fact_id"
                $c->{uuid} = $sf->sf_src_id . "." . $sf->sf_fact_id;
                $conflicts->{"$id.$fld"} = $c;
            }
        }
        $sf->save();
    }
}

sub vita {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;

    # move vita
    for my $tv ( @{ $tsrc->vitas } ) {
        my $sv = AIR2::SrcVita->new(
            sv_src_id     => $tsrc->src_id,
            sv_type       => $tv->sv_type,
            sv_origin     => $tv->sv_origin,
            sv_start_date => $tv->sv_start_date,
            sv_end_date   => $tv->sv_end_date,
            sv_lat        => $tv->sv_lat,
            sv_long       => $tv->sv_long,
            sv_value      => $tv->sv_value,
            sv_basis      => $tv->sv_basis,
            sv_notes      => $tv->sv_notes,
        );
        $tsrc->source->add_vitas($sv);
        $sv->save();
    }
}

sub preference {
    my ( $self, $tsrc, $ops, $conflicts ) = @_;

    #dump $conflicts;

    # move preference
    for my $tp ( @{ $tsrc->preferences } ) {
        my $sp = AIR2::SrcPreference->new(
            sp_src_id => $tsrc->src_id,
            sp_ptv_id => $tp->sp_ptv_id,
        );
        $sp->load_speculative();    # update if exists already
        $sp->sp_status( $tp->sp_status );
        $sp->sp_lock_flag( $tp->sp_lock_flag );

        #warn "save preference=".$sp->sp_ptv_id;
        $tsrc->source->set_preference($sp);
        $sp->save();
    }
}

sub submissions {
    my ( $self, $tsrc ) = @_;

    # move response sets
    for my $trs ( @{ $tsrc->response_sets } ) {
        my $srs = AIR2::SrcResponseSet->new(
            srs_src_id           => $tsrc->src_id,
            srs_inq_id           => $trs->srs_inq_id,
            srs_date             => $trs->srs_date,
            srs_uri              => $trs->srs_uri,
            srs_uuid             => $trs->srs_uuid,
            srs_xuuid            => $trs->srs_xuuid,
            srs_type             => $trs->srs_type,
            srs_public_flag      => $trs->srs_public_flag,
            srs_delete_flag      => $trs->srs_delete_flag,
            srs_translated_flag  => $trs->srs_translated_flag,
            srs_export_flag      => $trs->srs_export_flag,
            srs_fb_approved_flag => $trs->srs_fb_approved_flag,
            srs_loc_id           => $trs->srs_loc_id,
            srs_conf_level       => $trs->srs_conf_level,
        );

        # add the responses
        for my $tr ( @{ $trs->responses } ) {
            my $sr = AIR2::SrcResponse->new(
                sr_src_id           => $tsrc->src_id,
                sr_srs_id           => $srs->srs_id,
                sr_ques_id          => $tr->sr_ques_id,
                sr_media_asset_flag => $tr->sr_media_asset_flag,
                sr_orig_value       => $tr->sr_orig_value,
                sr_mod_value        => $tr->sr_mod_value,
                sr_status           => $tr->sr_status,
                sr_uuid             => $tr->sr_uuid,
                sr_public_flag      => $tr->sr_public_flag,
            );
            $srs->add_responses($sr);
        }

        # add to source and save
        $tsrc->source->add_response_sets($srs);
        $srs->save();
    }
}

sub organizations {
    my ( $self, $tsrc ) = @_;

    # get map of source orgs
    my %sorgs = map { $_->so_org_id => $_ } @{ $tsrc->source->src_orgs };

    # opt-into organizations
    my $force_home = 0;
    for my $to ( @{ $tsrc->tank->orgs } ) {
        if ( my $so = $sorgs{ $to->to_org_id } ) {

            # just update home/status
            $so->so_home_flag(1) if $to->to_so_home_flag;
            $so->so_status( $to->to_so_status ) if $to->to_so_status;
            $so->save();
        }
        else {
            $so = AIR2::SrcOrg->new(
                so_org_id         => $to->to_org_id,
                so_effective_date => time(),
                so_home_flag      => $to->to_so_home_flag ? 1 : 0,
                so_status         => $to->to_so_status,
                so_cre_dtim       => $tsrc->tsrc_cre_dtim,
            );
            $tsrc->source->add_src_orgs($so);
            $so->save();
            $sorgs{ $to->to_org_id } = $so;
        }

        # record setting a home-org
        $force_home = $to->to_org_id if $to->to_so_home_flag;
    }

    # force APMG opt-in
    unless ( $sorgs{$APMPIN_ORG_ID} ) {
        my $apmpin = AIR2::SrcOrg->new(
            so_org_id         => $APMPIN_ORG_ID,
            so_effective_date => time(),
        );
        $tsrc->source->add_src_orgs($apmpin);
        $apmpin->save();
        $sorgs{$APMPIN_ORG_ID} = $apmpin;
    }

    # set the home-org (most not-apmpin, most home, most recent)
    my @sorted = sort {
        ( $b->so_org_id != $APMPIN_ORG_ID )
            <=> ( $a->so_org_id != $APMPIN_ORG_ID )
            || ( $b->so_org_id == $force_home )
            <=> ( $a->so_org_id == $force_home )
            || $b->so_home_flag <=> $a->so_home_flag
            || $b->so_upd_dtim <=> $a->so_upd_dtim
    } @{ $tsrc->source->src_orgs };
    my $idx = 0;
    for my $so (@sorted) {
        $so->so_home_flag( ( $idx++ == 0 ) ? 1 : 0 );
        $so->save();
    }
}

sub activity {
    my ( $self, $tsrc ) = @_;

    # blindly add activity
    for my $tact ( @{ $tsrc->tank->activities } ) {
        next if $tact->tact_type ne 'S';

        # per-tank vs per-tsrc dtim
        my $dtim = $tact->tact_dtim ? $tact->tact_dtim : $tsrc->tsrc_cre_dtim;

        # create
        my $sact = AIR2::SrcActivity->new(
            sact_src_id   => $tsrc->src_id,
            sact_actm_id  => $tact->tact_actm_id,
            sact_prj_id   => $tact->tact_prj_id,
            sact_dtim     => $dtim,
            sact_desc     => $tact->tact_desc,
            sact_notes    => $tact->tact_notes,
            sact_cre_dtim => $tsrc->tsrc_cre_dtim,
        );
        if ( $tact->tact_xid && $tact->tact_ref_type ) {
            $sact->sact_xid( $tact->tact_xid );
            $sact->sact_ref_type( $tact->tact_ref_type );
        }
        $tsrc->source->add_activities($sact);
        $sact->save();
    }
}

sub tags {
    my ( $self, $tsrc ) = @_;
    return unless ( defined $tsrc->tsrc_tags && length $tsrc->tsrc_tags );

    # split, validate, save tags
    my @tags = split( / *, */, $tsrc->tsrc_tags );
    for my $tag (@tags) {
        if ( $tag =~ m/^[a-zA-Z0-9 _\-\.]+$/ ) {
            my $tm = AIR2::TagMaster->new( tm_name => $tag, )->load_or_save();
            my $tag = AIR2::Tag->new(
                tag_tm_id    => $tm->tm_id,
                tag_xid      => $tsrc->src_id,
                tag_ref_type => 'S',
            )->load_or_save();
        }
    }
}
