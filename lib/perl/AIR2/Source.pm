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

package AIR2::Source;
use strict;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );
use Rose::DateTime::Parser;
use Search::Tools::Transliterate;
use Search::Tools::UTF8;
use Email::Address;
use AIR2::SrcOrgCache;
use Scalar::Util qw( blessed );

my $date_parser
    = Rose::DateTime::Parser->new( time_zone => $AIR2::Config::TIMEZONE );

# for empty datetime values
my $EPOCH_YMD = '19700101';

my $STATUS_ENGAGED          = 'A';
my $STATUS_DEACTIVATED      = 'D';
my $STATUS_ENROLLED         = 'E';
my $STATUS_OPTED_OUT        = 'F';
my $STATUS_INVITEE          = 'I';
my $STATUS_UNSUBSCRIBED     = 'U';
my $STATUS_EDITORIAL_DEACTV = 'X';
my $STATUS_DECEASED         = 'P';
my $STATUS_TEMP_HOLD        = 'T';
my $STATUS_NO_PRIMARY_EMAIL = 'N';
my $STATUS_NO_ORGS          = 'G';
my $STATUS_ANONYMOUS        = 'Z';
my $PROFILE_CHANGE_ACTM_ID  = 11;

__PACKAGE__->meta->setup(
    table => 'source',

    columns => [
        src_id   => { type => 'serial', not_null => 1 },
        src_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        src_username => { type => 'varchar', length => 255, not_null => 1, },
        src_first_name => { type => 'varchar', default => '', length => 64, },
        src_last_name      => { type => 'varchar',   length => 64 },
        src_middle_initial => { type => 'character', length => 1 },
        src_pre_name       => { type => 'varchar',   length => 64 },
        src_post_name      => { type => 'varchar',   length => 64 },
        src_status =>
            { type => 'character', length => 1, default => $STATUS_ENGAGED, },
        src_has_acct => { type => 'character', length => 1, default => 'N', },
        src_channel  => { type => 'character', length   => 1 },
        src_cre_user => { type => 'integer',   not_null => 1 },
        src_upd_user => { type => 'integer' },
        src_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        src_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['src_id'],

    unique_keys => [ ['src_username'], ['src_uuid'], ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { src_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { src_upd_user => 'user_id' },
        },
    ],

    relationships => [

        activities => {
            class      => 'AIR2::SrcActivity',
            column_map => { src_id => 'sact_src_id' },
            type       => 'one to many',
        },

        aliases => {
            class      => 'AIR2::SrcAlias',
            column_map => { src_id => 'sa_src_id' },
            type       => 'one to many',
        },

        annotations => {
            class      => 'AIR2::SrcAnnotation',
            column_map => { src_id => 'srcan_src_id' },
            type       => 'one to many',
        },

        bin_sources => {
            class      => 'AIR2::BinSource',
            column_map => { src_id => 'bsrc_src_id' },
            type       => 'one to many',
        },

        bin_responses => {
            class      => 'AIR2::BinSrcResponseSet',
            column_map => { src_id => 'bsrs_src_id' },
            type       => 'one to many',
        },

        bins => {
            map_class => 'AIR2::BinSource',
            map_from  => 'source',
            map_to    => 'bin',
            type      => 'many to many',
        },

        response_bins => {
            map_class => 'AIR2::BinSrcResponseSet',
            map_from  => 'source',
            map_to    => 'bin',
            type      => 'many to many',
        },

        emails => {
            class      => 'AIR2::SrcEmail',
            column_map => { src_id => 'sem_src_id' },
            type       => 'one to many',
        },

        facts => {
            class      => 'AIR2::SrcFact',
            column_map => { src_id => 'sf_src_id' },
            type       => 'one to many',
        },

        inquiries => {
            class      => 'AIR2::SrcInquiry',
            column_map => { src_id => 'si_src_id' },
            type       => 'one to many',
        },

        mail_addresses => {
            class      => 'AIR2::SrcMailAddress',
            column_map => { src_id => 'smadd_src_id' },
            type       => 'one to many',
        },

        media_assets => {
            class      => 'AIR2::SrcMediaAsset',
            column_map => { src_id => 'sma_src_id' },
            type       => 'one to many',
        },

        organizations => {
            map_class => 'AIR2::SrcOrg',
            map_from  => 'source',
            map_to    => 'organization',
            type      => 'many to many',
        },

        outcomes => {
            map_class => 'AIR2::SrcOutcome',
            map_from  => 'source',
            map_to    => 'outcome',
            type      => 'many to many',
        },

        phone_numbers => {
            class      => 'AIR2::SrcPhoneNumber',
            column_map => { src_id => 'sph_src_id' },
            type       => 'one to many',
        },

        src_orgs => {
            class      => 'AIR2::SrcOrg',
            column_map => { src_id => 'so_src_id' },
            type       => 'one to many',
        },

        src_org_cache => {
            class      => 'AIR2::SrcOrgCache',
            column_map => { src_id => "soc_src_id" },
            type       => 'one to many',
        },

        src_outcomes => {
            class      => 'AIR2::SrcOutcome',
            column_map => { src_id => "sout_src_id" },
            type       => 'one to many',
        },

        src_pref_org => {
            class      => 'AIR2::SrcPrefOrg',
            column_map => { src_id => 'spo_src_id' },
            type       => 'one to many',
        },

        preferences => {
            class      => 'AIR2::SrcPreference',
            column_map => { src_id => 'sp_src_id' },
            type       => 'one to many',
        },

        relationships => {
            class      => 'AIR2::SrcRelationship',
            column_map => { src_id => 'srel_src_id' },
            type       => 'one to many',
        },

        self_relationships => {
            class      => 'AIR2::SrcRelationship',
            column_map => { src_id => 'src_src_id' },
            type       => 'one to many',
        },

        responses => {
            class      => 'AIR2::SrcResponse',
            column_map => { src_id => 'sr_src_id' },
            type       => 'one to many',
        },

        response_sets => {
            class      => 'AIR2::SrcResponseSet',
            column_map => { src_id => 'srs_src_id' },
            type       => 'one to many',
        },

        stat => {
            class      => 'AIR2::SrcStat',
            column_map => { src_id => 'sstat_src_id' },
            type       => 'one to one',
        },

        uris => {
            class      => 'AIR2::SrcUri',
            column_map => { src_id => 'suri_src_id' },
            type       => 'one to many',
        },

        tags => {
            class      => 'AIR2::Tag',
            column_map => { src_id => 'tag_xid' },
            query_args => [ tag_ref_type => tag_ref_type() ],
            type       => 'one to many',
        },

        vitas => {
            class      => 'AIR2::SrcVita',
            column_map => { src_id => 'sv_src_id' },
            type       => 'one to many',
        },
    ],
);

sub get_name {
    my $self  = shift;
    my $first = $self->src_first_name || '[first name]';
    my $last  = $self->src_last_name || '[last name]';
    return "$last, $first";
}

sub get_first_last_name {
    my $self = shift;
    my @name;
    push @name, $self->src_first_name if $self->src_first_name;
    push @name, $self->src_last_name  if $self->src_last_name;
    return join( ' ', @name );
}

sub tag_ref_type {'S'}

sub init_indexer {
    my $self = shift;
    return $self->SUPER::init_indexer(
        prune => {

        },
        max_depth        => 1,
        xml_root_element => 'source',
        force_load       => 0,
        @_
    );
}

my @indexables = qw(
    src_orgs
    emails
    phone_numbers
    mail_addresses
    vitas
    facts
    preferences
    activities
    annotations
    inquiries
    outcomes
    aliases
);

my @searchables = (
    @indexables, qw(
        activities
        bin_sources
        bin_responses
        tags
        response_sets
        response_sets.tags
        response_sets.annotations
        )
);

# return src_outcomes instead of outcomes for indexing purposes
my @srchable;    # memoize

sub get_searchable_rels {
    return \@srchable if @srchable;
    for my $rel (@searchables) {
        if ( $rel eq 'outcomes' ) {
            push @srchable, 'src_outcomes';    # use timestamp from o2m rel
        }
        else {
            push @srchable, $rel;
        }
    }
    return \@srchable;
}

my %authz;

sub get_authz {
    my $self = shift;
    if ( exists $authz{ $self->src_id } ) {
        return $authz{ $self->src_id };
    }

    # status doesn't matter for authz, so org_ids sufficient
    my $org_ids = get_authz_org_ids( $self->src_id );
    $authz{ $self->src_id } = $org_ids;
    return $authz{ $self->src_id };
}

=head2 get_authz_status( I<src_id> )

Static method to get a mapping of org_id => so_status, cascading everything
down the org tree.  Only src_orgs with a DELETED status will be ignored here.

=cut

my %authz_status;

sub get_authz_status {
    my $src_id = shift or croak "src_id required";
    if ( exists $authz_status{$src_id} ) {
        return $authz_status{$src_id};
    }

    # get src_orgs
    my $dbh            = AIR2::DBManager->new_or_cached()->retain_dbh;
    my $sel            = "select * from src_org where so_src_id = $src_id";
    my $unsorted_sorgs = $dbh->selectall_arrayref( $sel, { Slice => {} } );
    my $sorted_sorgs
        = AIR2::Organization::sort_by_depth( $unsorted_sorgs, 'so_org_id' );

    # calculate authz
    my %org_status;
    for my $so ( @{$sorted_sorgs} ) {

        # ignore deleted src_orgs
        my $stat = $so->{so_status};
        next if ( $stat eq 'X' );

        # apply status to self and all children
        my $children
            = AIR2::Organization::get_org_children( $so->{so_org_id} );
        for my $oid ( @{$children} ) {
            $org_status{$oid} = $stat;
        }

    }

    # cache and return
    $authz_status{$src_id} = \%org_status;
    return \%org_status;
}

=head2 get_authz_org_ids( I<src_id> )

Returns array ref of all org_ids to which I<src_id> is related,
implicitly or explicitly, both children and parents of explicit
SrcOrg records.

=cut

sub get_authz_org_ids {
    my $src_id = shift or croak "src_id required";

    # get src_orgs
    my $dbh            = AIR2::DBManager->new_or_cached()->retain_dbh;
    my $sel            = "select * from src_org where so_src_id = $src_id";
    my $unsorted_sorgs = $dbh->selectall_arrayref( $sel, { Slice => {} } );
    my $sorted_sorgs
        = AIR2::Organization::sort_by_depth( $unsorted_sorgs, 'so_org_id' );

    # crawl up and down the tree
    my %org_ids;
    for my $so ( @{$sorted_sorgs} ) {

        # ignore deleted src_orgs
        my $stat = $so->{so_status};
        next if ( $stat eq 'X' );

        my $children
            = AIR2::Organization::get_org_children( $so->{so_org_id} );
        for my $oid ( @{$children} ) {
            $org_ids{$oid}++;
        }

        my $parents = AIR2::Organization::get_org_parents( $so->{so_org_id} );
        for my $oid (@$parents) {
            $org_ids{$oid}++;
        }
    }

    # sort for debug ease
    return [ sort { $a <=> $b } keys %org_ids ];
}

sub clear_authz_caches {
    %authz        = ();
    %authz_status = ();
}

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        $self->$rel;
    }
}

sub get_primary_email {
    my $self = shift;
    for my $email ( @{ $self->emails || [] } ) {
        if ( $email->sem_primary_flag ) {
            return $email;
        }
    }
    return;
}

sub has_email {
    my $self = shift;
    my $email = shift or croak "email address required";
    for my $sem ( @{ $self->emails || [] } ) {
        if ( $email eq $sem->sem_email ) {
            return $sem;
        }
    }
    return 0;
}

sub has_valid_email {
    my $self = shift;
    my $primary_email;
    eval { $primary_email = $self->get_primary_email->sem_email; };
    if ( !$primary_email ) {
        return 0;
    }
    my @email = Email::Address->parse($primary_email);
    if ( @email && $email[0]->address eq $primary_email ) {
        if ( $primary_email =~ m/\@nosuchemail.org$/ ) {
            return 0;
        }
        return 1;
    }
    return 0;
}

sub get_primary_address {
    my $self = shift;
    for my $addr ( @{ $self->mail_addresses } ) {
        if ( $addr->smadd_primary_flag ) {
            return $addr;
        }
    }
    return;
}

sub get_primary_phone {
    my $self = shift;
    for my $phone ( @{ $self->phone_numbers || [] } ) {
        if ( $phone->sph_primary_flag ) {
            return $phone;
        }
    }
    return;
}

sub num_involved_activities {

    croak "TODO";

    my $self = shift;
    my $n    = 0;
    for my $cact ( @{ $self->con_activitys } ) {
        if (   $cact->is_response
            or $cact->cact_actm_id == 23
            or $cact->cact_actm_id == 24 )
        {
            $n++;
        }
    }
    return $n;
}

sub count_incoming_activities {

    croak "TODO";

    my $self = shift;
    my $n    = 0;
    for my $cact ( @{ $self->con_activitys } ) {
        if ( $cact->is_incoming ) {
            $n++;
        }
    }
    return $n;
}

sub outgoing_activity_text {

    croak "TODO";

    my $self = shift;
    my @text;
    for my $cact ( @{ $self->con_activitys } ) {
        if ( $cact->is_outgoing ) {
            push @text, ( $cact->cact_action_detail || '' ),
                ( $cact->cact_action_notes || '' );
        }
    }
    return @text;
}

sub last_contacted {
    my $self = shift;

    # look first at cached date
    my $stat = $self->stat;
    if ( $stat && $stat->sstat_contact_dtim ) {
        return $stat->sstat_contact_dtim->epoch;
    }

    # then look at activities
    my $acts = $self->activities_iterator(
        sort_by         => 'sact_dtim DESC',
        require_objects => [qw( activitymaster )],
        query           => [ 'activitymaster.actm_contact_rule_flag' => 1 ],
    );
    my $last = $acts->next;
    if ($last) {
        return $last->sact_dtim->epoch;
    }
    return;
}

sub last_contacted_date {
    my $self  = shift;
    my $epoch = $self->last_contacted or return $EPOCH_YMD;
    my $dt    = $date_parser->parse_date($epoch)
        or croak "can't parse date $epoch";
    return $dt->ymd('');
}

sub last_response {
    my $self = shift;
    my $resp = $self->response_sets_iterator( sort_by => 'srs_date DESC' );
    my $last = $resp->next;
    if ($last) {
        return $last->srs_date->epoch;
    }
    return;
}

sub last_response_date {
    my $self  = shift;
    my $epoch = $self->last_response or return $EPOCH_YMD;
    my $dt    = $date_parser->parse_date($epoch)
        or croak "can't parse date $epoch";
    return $dt->ymd('');
}

sub first_response {
    my $self  = shift;
    my $resp  = $self->response_sets_iterator( sort_by => 'srs_date ASC' );
    my $first = $resp->next;
    if ($first) {
        return $first->srs_date->epoch;
    }
    return;
}

sub last_activity_date {
    my $self = shift;
    my $acts = $self->activities_iterator( sort_by => 'sact_dtim DESC' );
    my $last = $acts->next;
    if ($last) {
        return $last->sact_dtim->ymd('');
    }
    return $EPOCH_YMD;
}

sub last_queried_date {
    my $self = shift;
    my $acts = $self->activities_iterator(
        query   => [ sact_actm_id => [ 13, 29 ] ],
        sort_by => 'sact_dtim DESC',
    );
    my $last = $acts->next;
    if ($last) {
        return $last->sact_dtim->ymd('');
    }
    return $EPOCH_YMD;
}

sub first_response_date {
    my $self  = shift;
    my $epoch = $self->first_response or return $EPOCH_YMD;
    my $dt    = $date_parser->parse_date($epoch)
        or croak "can't parse date $epoch";
    return $dt->ymd('');
}

sub last_export_dtim {
    my $self = shift;
    return 0 unless $self->stat;
    return $self->stat->sstat_export_dtim;
}

sub stem_names {
    my $self = shift;
    my @stems;

    # forwards and backwards, down to a single letter.
    for my $col (qw( src_first_name src_last_name )) {
        my @val = split( m//, $self->$col );
        my @copy = @val;
        while ( pop @val && @val ) {
            push( @stems, join( '', @val ) );
        }

        while ( shift @copy && @copy ) {
            push( @stems, join( '', @copy ) );
        }
    }

    return @stems;

}

=head2 as_xml( I<args> )

Returns Source as XML string, suitable for indexing.

I<args> should contain a Rose::DBx::Object::Indexed::Indexer
object and other objects relevant to the XML structure.
See bin/sources2xml.pl for example usage.

=cut

sub as_xml {
    my $source  = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $source->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');
    my $organizations = delete $args->{organizations}
        || AIR2::SearchUtils::all_organizations_by_id();
    my $fact_values = delete $args->{fact_values}
        || AIR2::SearchUtils::all_fact_values_by_id();
    my $facts = delete $args->{facts}
        || AIR2::SearchUtils::all_facts_by_id();
    my $prefs = delete $args->{pref_values}
        || AIR2::SearchUtils::all_preference_values_by_id();
    my $activity_master = delete $args->{activity_master}
        || AIR2::SearchUtils::get_activity_master();

    # loading each rel one-at-a-time is slower than a 'with' clause in load()
    # for sources with just a couple of responses,
    # but magnitudes faster for sources with many responses.
    $source->load_indexable_rels;

    # turn object into a hash tree
    my $dmp = $indexer->serialize_object($source);

    $dmp->{title} = $source->get_xml_title;

    $debug and dump $dmp;

    # pseudo-tags for filtering
    for my $org ( @{ $dmp->{src_orgs} } ) {

        $org->{org_name}   = $organizations->{ $org->{so_org_id} }->org_name;
        $org->{org_uuid}   = $organizations->{ $org->{so_org_id} }->org_uuid;
        $org->{org_status} = join( '_', $org->{org_name}, $org->{so_status} );

        # create a string that captures: org, status and mod_date
        # so that we can filter on it.
        my $upd = $date_parser->parse_date( $org->{so_upd_dtim} );
        $org->{org_status_date}
            = join( '_', $org->{org_status}, $upd->ymd('') );
        $org->{org_status_year}
            = join( '_', $org->{org_status}, $upd->year() );
        $org->{org_status_month} = join( '_',
            $org->{org_status},
            sprintf( "%s%02d", $upd->year, $upd->month ) );

        if ( $org->{so_home_flag} ) {
            $dmp->{primary_org_name} = $org->{org_name};
            $dmp->{primary_org_uuid} = $org->{org_uuid};
        }

        $org->{org_new_date}
            = join( '_', $org->{org_name}, $org->{so_effective_date} );
        $org->{org_new_date} =~ s/\-//g;
    }

    $dmp->{orgid_statuses} = $source->get_orgid_statuses();

    # pseudo-tags for emails
    for my $email ( @{ $dmp->{emails} } ) {
        if ( $email->{sem_primary_flag} ) {
            $dmp->{primary_email} = $email->{sem_email};
        }
    }

    # pseudo-tags for primary address and phone
    for my $phone ( @{ $dmp->{phone_numbers} } ) {
        if ( defined $phone->{sph_primary_flag}
            and $phone->{sph_primary_flag} )
        {
            $dmp->{primary_phone} = join( ' ',
                grep {defined} $phone->{sph_number},
                $phone->{sph_ext} );
        }

    }

    # pseudo-tags for location
    for my $addr ( @{ $dmp->{mail_addresses} } ) {

        next unless $addr->{smadd_primary_flag};
        $dmp->{primary_city}    = $addr->{smadd_city};
        $dmp->{primary_state}   = $addr->{smadd_state};
        $dmp->{primary_zip}     = $addr->{smadd_zip};
        $dmp->{primary_country} = $addr->{smadd_cntry};
        $dmp->{primary_county}  = $addr->{smadd_county};
        $dmp->{primary_lat}     = $addr->{smadd_lat};
        $dmp->{primary_long}    = $addr->{smadd_long};

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
    }

    # vitas
    for my $vita ( @{ $dmp->{vitas} } ) {
        if ( $vita->{sv_type} eq 'I' ) {
            $vita->{interest} = $vita->{sv_notes};
        }
        elsif ( $vita->{sv_type} eq 'E' ) {
            $vita->{experience}
                = join( "::", $vita->{sv_basis}, $vita->{sv_value} );
            if ( defined $vita->{sv_start_date} ) {
                $vita->{experience_start}
                    = AIR2::SearchUtils::dtim_string_to_ymd(
                    $vita->{sv_start_date} );
            }
            if ( defined $vita->{sv_end_date} ) {
                $vita->{experience_end}
                    = AIR2::SearchUtils::dtim_string_to_ymd(
                    $vita->{sv_end_date} );
            }
        }
    }

    # flatten preferences by field-like name and human value.
    for my $p ( @{ $dmp->{preferences} } ) {
        my $pref = $prefs->{ $p->{sp_ptv_id} };
        my $name = lc( $pref->preference_type->pt_name );
        $name =~ s/\W+/_/g;
        $p->{$name} = $pref->ptv_value;
    }

    # srs are not pre-serialized.
    # pull just inquiry metadata and the actual response text, not questions.
    my @response_sets;
    my $srs_iter = $source->response_sets_iterator;
    while ( my $srs = $srs_iter->next ) {
        push @response_sets, $srs->as_qa_set;

        # add submission tags to source record, redmine #7534
        push @{ $dmp->{tags} }, @{ $srs->get_tags_from_super_cache };

        # who has read and starred this srs
        my $users = $srs->users_iterator;
        while ( my $usrs = $users->next ) {
            if ( $usrs->usrs_read_flag ) {
                push @{ $dmp->{user_reads} }, $usrs->user->user_uuid;
            }
            if ( $usrs->usrs_favorite_flag ) {
                push @{ $dmp->{user_stars} }, $usrs->user->user_uuid;
            }
        }
    }
    $dmp->{response_sets} = \@response_sets;

    # normalize facts
    for my $src_fact ( @{ $dmp->{facts} } ) {

        # could be 0, 1 or 2 FactValues for each SrcFact
        my ( $user_fact_value, $src_fact_value );

        if ( defined $src_fact->{sf_src_fv_id}
            and exists $fact_values->{ $src_fact->{sf_src_fv_id} } )
        {
            $src_fact_value = $fact_values->{ $src_fact->{sf_src_fv_id} };
        }
        if ( defined $src_fact->{sf_fv_id}
            and exists $fact_values->{ $src_fact->{sf_fv_id} } )
        {
            $user_fact_value = $fact_values->{ $src_fact->{sf_fv_id} };
        }

        # analyst-mapped values
        if ($user_fact_value) {
            my $fname = $user_fact_value->fact->fact_identifier;
            $src_fact->{ 'user_' . $fname } = $user_fact_value->fv_value;
            $src_fact->{ 'user_' . $fname . '_id' } = $user_fact_value->fv_id;
            $src_fact->{'user_fact'} = join( '_',
                $user_fact_value->fv_fact_id,
                $user_fact_value->fv_id );
            $src_fact->{$fname} = join( ' ',
                $src_fact->{ 'user_' . $fname },
                $src_fact->{ 'user_' . $fname . '_id' } );
        }

        # source-mapped values
        if ($src_fact_value) {
            my $fname = $src_fact_value->fact->fact_identifier;
            $src_fact->{ 'src_' . $fname } = $src_fact_value->fv_value;
            $src_fact->{ 'src_' . $fname . '_id' } = $src_fact_value->fv_id;
            $src_fact->{'src_fact'} = join( '_',
                $src_fact_value->fv_fact_id,
                $src_fact_value->fv_id );
            $src_fact->{$fname} ||= "";
            $src_fact->{$fname} .= join(
                ' ',
                "",    # create space
                $src_fact->{ 'src_' . $fname },
                $src_fact->{ 'src_' . $fname . '_id' }
            );
        }

        # source-unmapped (raw) values
        if ( defined $src_fact->{sf_src_value}
            and length $src_fact->{sf_src_value} )
        {
            $src_fact->{ $facts->{ $src_fact->{sf_fact_id} }
                    ->fact_identifier } .= ' ' . $src_fact->{sf_src_value};
        }

        $debug and dump($src_fact);

    }

    # strip non-text from annotations
    for my $anno ( @{ $dmp->{annotations} } ) {
        $anno = { srcan_value => $anno->{srcan_value} };
    }

    # concat activity type and date virtual fields
    my @sacts;
SACT: for my $sact ( @{ $dmp->{activities} } ) {

        # delete any profile change activities to reduce noise
        # and prevent "deleted" text from creating false positive
        # search hits. (trac #2388)
        if ( $sact->{sact_actm_id} == $PROFILE_CHANGE_ACTM_ID ) {
            next SACT;
        }

        push @sacts, $sact;

        my $dt = $date_parser->parse_date( $sact->{sact_dtim} );

        $sact->{activity_type_date}
            = sprintf( "%02d%s", $sact->{sact_actm_id}, $dt->ymd('') );

        $sact->{activity_type_year}
            = sprintf( "%02d%s", $sact->{sact_actm_id}, $dt->year() );

        $sact->{activity_type_month} = sprintf( "%02d%s%02d",
            $sact->{sact_actm_id}, $dt->year(), $dt->month() );

        # if this activity was in the "contacted" category
        # create virtual fields
        # NOTE that because these are potentially multiple values
        # in the index, range searches will not work.
        if ( $activity_master->{ $sact->{sact_actm_id} }
            ->actm_contact_rule_flag )
        {
            $sact->{contacted_date} = $dt->ymd('');
            $sact->{contacted_year} = $dt->year();
            $sact->{contacted_month}
                = sprintf( "%04d%02d", $dt->year, $dt->month );
        }
    }
    $dmp->{activities} = \@sacts;

    for my $si ( @{ $dmp->{inquiries} } ) {
        next if $si->{si_status} eq 'P';    # skip in-process records
        my $inq = AIR2::SearchUtils::get_inquiry( $si->{si_inq_id} );
        $si->{inq_sent} = $inq->inq_uuid;
        $si->{inq_sent_date}
            = AIR2::SearchUtils::dtim_string_to_ymd( $si->{si_upd_dtim} );
        for my $org ( @{ $inq->organizations } ) {
            push @{ $si->{inq_org_date} },
                join( '_',
                $org->org_name,
                AIR2::SearchUtils::dtim_string_to_ymd( $si->{si_upd_dtim} ) );
        }
    }

    # more virtual fields
    for my $f (
        qw(
        last_contacted_date
        last_response_date
        last_queried_date
        first_response_date
        last_activity_date
        )
        )
    {
        $dmp->{$f} = $source->$f;
        ( my $by_year       = $f ) =~ s/_date/_year/;
        ( my $by_month      = $f ) =~ s/_date/_month/;
        ( $dmp->{$by_year}  = $dmp->{$f} ) =~ s/^(\d\d\d\d).+$/$1/;
        ( $dmp->{$by_month} = $dmp->{$f} ) =~ s/^(\d\d\d\d\d\d).+$/$1/;
    }
    $dmp->{last_exported_date}
        = $source->last_export_dtim
        ? $source->last_export_dtim->ymd('')
        : $EPOCH_YMD;
    my $created  = $source->src_cre_dtim;
    my $modified = $source->src_upd_dtim;
    $dmp->{src_created_date} = $created->ymd('');
    $dmp->{src_created_year} = $created->year();
    $dmp->{src_created_month}
        = sprintf( "%s%02d", $created->year, $created->month );
    $dmp->{src_modified_date} = $modified->ymd('');
    $dmp->{src_modified_year} = $modified->year();
    $dmp->{src_modified_month}
        = sprintf( "%s%02d", $modified->year, $modified->month );

    push @{ $dmp->{tags} }, @{ $source->get_tags_from_super_cache };

    $dmp->{source_name} = join( ' ',
        grep {defined} $source->src_first_name,
        $source->src_last_name, $source->src_first_name )
        . ' '
        . join( ' ', $source->stem_names );

    # transliterate the name so we can easily search for it
    my $transliterator = Search::Tools::Transliterate->new( ebit => 0 );
    $dmp->{source_trans_name}
        = $transliterator->convert( $dmp->{source_name} );

    $dmp->{valid_email} = $source->has_valid_email;

    # cached stat dates
    my $srcstat = $source->stat();
    if ($srcstat) {
        if ( $srcstat->sstat_bh_signup_dtim ) {
            $dmp->{bh_signup_date} = sprintf( "%s%02d",
                $srcstat->sstat_bh_signup_dtim->year,
                $srcstat->sstat_bh_signup_dtim->month );
        }
        if ( $srcstat->sstat_bh_signup_dtim ) {
            $dmp->{bh_play_date} = sprintf( "%s%02d",
                $srcstat->sstat_bh_play_dtim->year,
                $srcstat->sstat_bh_play_dtim->month );
        }
    }

    # bins, just uuids
    for my $bin ( @{ $source->bins } ) {
        push @{ $dmp->{bins} }, $bin->bin_uuid;
    }
    for my $bin ( @{ $source->response_bins } ) {
        push @{ $dmp->{bins} }, $bin->bin_uuid;
    }

    my $xml = $indexer->to_xml( $dmp, $source, 1 );  # last 1 to strip plurals
    my $root = $indexer->xml_root_element;

    # hack in the authz string
    # and the xinclude namespace support
    my $authz_str = join( ",", @{ $source->get_authz } );
    $xml
        =~ s,^<$root,<$root authz="$authz_str" xmlns:xi="http://www.w3.org/2001/XInclude",;

    return $xml;
}

sub get_orgid_statuses {
    my $self = shift;

    return $self->{__orgid_statuses} if $self->{__orgid_statuses};

    # "available" authz should apply to all implicit orgs.
    # src_orgs are just explicit. see #2266
    my @ois;
    my %src_orgs_with_kids;
    for my $soc ( @{ $self->src_org_cache } ) {
        push @ois, join( '_', $soc->soc_org_id, $soc->soc_status );
        $src_orgs_with_kids{ $soc->soc_org_id } = $soc->soc_status;
    }

    # src_org_cache does not include parents,
    # so ask for those explicitly.
    # added for #6657
    for my $org_id ( keys %src_orgs_with_kids ) {
        my $parents = AIR2::Organization::get_org_parents($org_id);
        my $stat    = $src_orgs_with_kids{$org_id};
    PARENT: for my $parent_org_id (@$parents) {

            # do not override parent status if already set
            next PARENT if exists $src_orgs_with_kids{$parent_org_id};

            push @ois, join( '_', $parent_org_id, $stat );
        }
    }

    $self->{__orgid_statuses} = \@ois;
    return \@ois;
}

sub get_xml_title {
    my $self  = shift;
    my $first = $self->src_first_name || '[first name]';
    my $last  = $self->src_last_name || '[last name]';
    my $name  = join( ' ', $first, $last );
    return sprintf( "%s, %s", $name, $self->src_username );
}

=head2 get_primary_newsroom

Returns Organization object for the SrcOrg m2m record where home_org is
true. If no Organization is flagged as home, returns undef.

=cut

sub get_primary_newsroom {
    my $self = shift;
    my $orgs = $self->find_src_orgs( query => [ so_home_flag => 1 ] );
    for my $so (@$orgs) {
        if ( $so->so_home_flag ) {
            return $so->organization;
        }
    }
    return undef;
}

=head2 get_anchor_newsroom

Returns org_name for the newsroom (Organization) that has had the most
response_sets, or in the event of a tie, the most recent response_set.

If there are no responses, returns the oldest newsrooms org_name.

This may not be the same as get_primary_newsroom.

=cut

sub get_anchor_newsroom {
    my $self = shift;
    my %sum;
    my $srsets = $self->response_sets_iterator;
    while ( my $srs = $srsets->next ) {
        for my $o ( @{ $srs->inquiry->organizations } ) {
            $sum{ $o->org_name }++;
        }
    }
    my $most;
    my %org;
    for my $org_name ( keys %sum ) {
        $most ||= $sum{$org_name};
        if ( $most <= $sum{$org_name} ) {
            $most = $sum{$org_name};
        }
    }
    for my $org_name ( keys %sum ) {
        if ( $sum{$org_name} == $most ) {
            $org{$org_name} = 1;
        }
    }
    if ( !keys %org ) {
        my $sos = $self->find_src_orgs( sort_by => 'so_cre_dtim' );
        return $sos->[0]->organization->org_name;
    }
    if ( scalar keys %org == 1 ) {
        my ($o) = each(%org);
        return $o;
    }

    # find most recent
    $srsets = $self->response_sets_iterator( sort_by => 'srs_date DESC' );
    while ( my $srs = $srsets->next ) {
        for my $o ( @{ $srs->inquiry->organizations } ) {
            if ( exists $org{ $o->org_name } ) {
                return $o->org_name;
            }
        }
    }
    croak "Could not determine anchor newsroom for "
        . $self->src_username
        . " from "
        . dump( \%org );

}

sub _get_fact_mapped {
    my ( $self, $fname ) = @_;

    # in order of preference: fv_id, src_fv_id, src_value
    # always return string (not PK)
    for my $sf ( @{ $self->facts } ) {
        if ( defined $sf->sf_fv_id ) {
            if ( $sf->fact->fact_identifier eq $fname ) {
                return $sf->fact_value->fv_value;
            }
        }
        elsif ( defined $sf->sf_src_fv_id ) {
            if ( $sf->fact->fact_identifier eq $fname ) {
                return $sf->source_fact_value->fv_value;
            }
        }
    }
    return "";
}

sub _get_fact {
    my ( $self, $fname ) = @_;

    # in order of preference: src_fv_id, fv_id, src_value
    # always return string (not PK)
    for my $sf ( @{ $self->facts } ) {
        if ( defined $sf->sf_src_fv_id ) {
            if ( $sf->fact->fact_identifier eq $fname ) {
                return $sf->source_fact_value->fv_value;
            }
        }
        elsif ( defined $sf->sf_fv_id ) {
            if ( $sf->fact->fact_identifier eq $fname ) {
                return $sf->fact_value->fv_value;
            }
        }
        elsif ( defined $sf->sf_src_value ) {
            if ( $sf->fact->fact_identifier eq $fname ) {
                return $sf->sf_src_value;
            }
        }
    }
    return "";
}

sub _get_fact_type {
    my ( $self, $fname, $check_fld ) = @_;

    # only look at the specified check_fld
    for my $sf ( @{ $self->facts } ) {
        if ( $sf->fact->fact_identifier eq $fname ) {
            if ( $check_fld eq 'sf_src_fv_id'
                and defined $sf->sf_src_fv_id )
            {
                return $sf->source_fact_value->fv_value;
            }
            elsif ( $check_fld eq 'sf_fv_id' and defined $sf->sf_fv_id ) {
                return $sf->fact_value->fv_value;
            }
            elsif ( $check_fld eq 'sf_src_value'
                and defined $sf->sf_src_value )
            {
                return $sf->sf_src_value;
            }
        }
    }
    return "";
}

sub get_srcfact {
    my ( $self, $fname ) = @_;
    for my $sf ( @{ $self->facts } ) {
        return $sf if ( $sf->fact->fact_identifier eq $fname );
    }
    return undef;
}

sub get_gender {
    return shift->_get_fact('gender');
}

sub get_ethnicity {
    return shift->_get_fact('ethnicity');
}

sub get_pol_affiliation {
    return shift->_get_fact('political_affiliation');
}

sub get_income {
    return shift->_get_fact('household_income');
}

sub get_religion {
    return shift->_get_fact('religion');
}

sub get_dob {
    return shift->_get_fact('birth_year');
}

sub get_edu_level {
    return shift->_get_fact('education_level');
}

sub get_gender_mapped {
    return shift->_get_fact_mapped('gender');
}

sub get_ethnicity_mapped {
    return shift->_get_fact_mapped('ethnicity');
}

sub get_pol_affiliation_mapped {
    return shift->_get_fact_mapped('political_affiliation');
}

sub get_income_mapped {
    return shift->_get_fact_mapped('household_income');
}

sub get_religion_mapped {
    return shift->_get_fact_mapped('religion');
}

sub get_dob_mapped {
    return shift->_get_fact_mapped('birth_year');
}

sub get_edu_level_mapped {
    return shift->_get_fact_mapped('education_level');
}

sub get_pref_lang {
    my $self = shift;
    return $self->_get_preferences()->{preferred_language};
}

sub _get_preferences {
    my $self  = shift;
    my $prefs = AIR2::SearchUtils::all_preference_values_by_id();
    my %p;
    for my $p ( @{ $self->preferences } ) {
        my $pref = $prefs->{ $p->{sp_ptv_id} };
        my $name = lc( $pref->preference_type->pt_name );
        $name =~ s/\W+/_/g;
        $p{$name} = $pref->ptv_value;
    }
    return \%p;
}

=head2 set_preference( I<pref> )

Preferences should be unique by preference_type for
each source. This method verifies that no other
preference exists for I<pref> type and overwrites
it if it does.

=cut

sub set_preference {
    my $self = shift;
    my $pref = shift or croak "preference required";

    if ( blessed($pref) and $pref->isa('AIR2::SrcPreference') ) {
        my @prefs = @{ $self->preferences };
        my @newprefs;
        my $pref_was_set = 0;
        for my $p (@prefs) {
            if ( $p->preference_type->pt_id == $pref->preference_type->pt_id )
            {
                push @newprefs, $pref;    # overwrite
                $pref_was_set = 1;
            }
            else {
                push @newprefs, $p;
            }
        }
        if ( !$pref_was_set ) {
            push @newprefs, $pref;
        }

        # replace
        $self->preferences( \@newprefs );
    }
    else {
        $self->add_preferences($pref);
    }
}

=head2 avg_query_rate

Returns integer representing the average number of days
between queries sent to this source.

=cut

sub avg_query_rate {
    my $self      = shift;
    my $last_sent = $self->src_cre_dtim->epoch;    # assume nothing earlier
    my $total;
    my $num_spans;
    my $acts = $self->activities_iterator(
        query   => [ sact_actm_id => 13 ],
        sort_by => 'sact_dtim ASC',
    );
    while ( my $sact = $acts->next ) {
        my $since = $sact->sact_dtim->epoch - $last_sent;
        $total += int( $since / 86400 );
        $num_spans++;
        $last_sent = $sact->sact_dtim->epoch;
    }
    return 0 unless $num_spans;
    return int( $total / $num_spans );
}

sub query_activity_count {
    my $self = shift;
    my $acts = $self->activities_iterator( query => [ sact_actm_id => 13 ], );
    my $total = 0;
    while ( my $sact = $acts->next ) {
        $total++;
    }
    return $total;
}

sub last_experience_what {
    my $self  = shift;
    my $vitas = $self->vitas_iterator(
        query   => [ sv_type => 'E' ],
        sort_by => 'sv_start_date DESC',
    );
    my $what = '';
    while ( my $sv = $vitas->next ) {
        $what = $sv->sv_value;
    }
    return $what;
}

sub last_experience_where {
    my $self  = shift;
    my $vitas = $self->vitas_iterator(
        query   => [ sv_type => 'E' ],
        sort_by => 'sv_start_date DESC',
    );
    my $where = '';
    while ( my $sv = $vitas->next ) {
        $where = $sv->sv_basis;
    }
    return $where;
}

sub last_interest {
    my $self  = shift;
    my $vitas = $self->vitas_iterator(
        query   => [ sv_type => 'I' ],
        sort_by => 'sv_cre_dtim DESC',
    );
    my $interest = '';
    while ( my $sv = $vitas->next ) {
        $interest = $sv->sv_basis;
    }
    return $interest;
}

sub save {
    my $self = shift;
    my $ret  = $self->SUPER::save(@_);
    $self->clear_authz_caches();
    AIR2::SrcOrgCache::refresh_cache($self);    # IMPORTANT after save
    $self->set_and_save_src_status();
    return $ret;
}

sub set_and_save_src_status {
    my $self = shift;
    my $stat = $self->set_src_status();
    $self->db->get_write_handle()
        ->dbh->do( "UPDATE source SET src_status=? WHERE src_id=?",
        {}, $stat, $self->src_id );
}

sub set_src_status {
    my $self = shift;

    my $stat = $self->src_status;

    my $primary_email = $self->get_primary_email();
    if ( !$primary_email ) {
        $self->src_status($STATUS_NO_PRIMARY_EMAIL);
        if ((      !defined $self->src_first_name
                or !length $self->src_first_name
            )
            and (  !defined $self->src_last_name
                or !length $self->src_last_name )
            )
        {
            $self->src_status($STATUS_ANONYMOUS);
        }
        return $self->src_status();
    }

    if ( $primary_email->sem_status eq 'U' ) {
        $self->src_status($STATUS_UNSUBSCRIBED);
        return $self->src_status();
    }

    if ( $primary_email->sem_status ne 'G' ) {
        $self->src_status($STATUS_NO_PRIMARY_EMAIL);
        return $self->src_status();
    }

    my $orgs_status = get_authz_status( $self->src_id );

    my $num_orgs      = scalar( keys %$orgs_status );
    my $num_active    = 0;
    my $num_deactive  = 0;
    my $num_opted_out = 0;
    my $num_deleted   = 0;

    for my $oid ( keys %$orgs_status ) {
        my $s = $orgs_status->{$oid};

        if ( $s eq 'A' ) {
            $num_active++;
        }
        elsif ( $s eq 'D' ) {
            $num_deactive++;
        }
        elsif ( $s eq 'F' ) {
            $num_opted_out++;
        }
        elsif ( $s eq 'X' ) {
            $num_deleted++;
        }
        else {
            croak("Unknown so_status: $s (org=$oid)");
        }
    }

    if ( !$num_orgs or $num_deleted == $num_orgs ) {
        $self->src_status($STATUS_NO_ORGS);
        return $self->src_status();
    }

    if ( $num_deactive == $num_orgs ) {
        $self->src_status($STATUS_DEACTIVATED);
        return $self->src_status();
    }

    if ( $num_opted_out == $num_orgs ) {
        $self->src_status($STATUS_OPTED_OUT);
        return $self->src_status();
    }

    if ( !$num_active ) {
        if ( $num_deactive >= $num_opted_out ) {
            $self->src_status($STATUS_DEACTIVATED);
        }
        else {
            $self->src_status($STATUS_OPTED_OUT);
        }
        return $self->src_status();
    }

    if ( $stat eq $STATUS_TEMP_HOLD ) {
        return $stat;
    }

    # either E or A here
    if ( $self->get_number_involved_activities() <= 1 ) {
        $self->src_status($STATUS_ENROLLED);
    }
    else {
        $self->src_status($STATUS_ENGAGED);
    }

    return $self->src_status();

}

sub get_number_involved_activities {
    my $self = shift;
    return $self->activities_count(
        require_objects => ['activitymaster'],
        query           => [ 'activitymaster.actm_type' => [qw( I )], ]
    );
}

=head2 flatten( I<args> )

Returns Source as XML string, suitable for indexing.

=cut

sub flatten {
    my $self = shift;
    my $args = shift;    # or croak "args required";

    # collect some additional data
    my $email = $self->get_primary_email();
    my $phone = $self->get_primary_phone();
    my $addr  = $self->get_primary_address();

    # pretend we know employer/job-title
    my $employer  = '';
    my $title     = '';
    my $job_start = undef;
    for my $vita ( @{ $self->vitas } ) {
        if ( $vita->sv_type eq 'E' && !defined $vita->sv_end_date ) {
            next if ( $job_start && $vita->sv_start_date < $job_start );
            $employer = $vita->sv_basis;
            $title    = $vita->sv_value;
        }
    }

    # flatten the simple stuff!
    my $flat = {

        # source
        src_id             => $self->src_id,
        src_uuid           => $self->src_uuid,
        src_first_name     => $self->src_first_name,
        src_last_name      => $self->src_last_name,
        src_middle_initial => $self->src_middle_initial,
        src_pre_name       => $self->src_pre_name,
        src_post_name      => $self->src_post_name,
        src_status         => $self->src_status,
        src_has_acct       => $self->src_has_acct,

        # primary email
        sem_primary_flag => $email ? $email->sem_primary_flag : undef,
        sem_context      => $email ? $email->sem_context      : undef,
        sem_email        => $email ? $email->sem_email        : undef,
        sem_status       => $email ? $email->sem_status       : undef,

        # primary phone
        sph_primary_flag => $phone ? $phone->sph_primary_flag : undef,
        sph_context      => $phone ? $phone->sph_context      : undef,
        sph_country      => $phone ? $phone->sph_country      : undef,
        sph_number       => $phone ? $phone->sph_number       : undef,
        sph_ext          => $phone ? $phone->sph_ext          : undef,
        sph_status       => $phone ? $phone->sph_status       : undef,

        # primary address
        smadd_primary_flag => $addr ? $addr->smadd_primary_flag : undef,
        smadd_context      => $addr ? $addr->smadd_context      : undef,
        smadd_line_1       => $addr ? $addr->smadd_line_1       : undef,
        smadd_line_2       => $addr ? $addr->smadd_line_2       : undef,
        smadd_city         => $addr ? $addr->smadd_city         : undef,
        smadd_state        => $addr ? $addr->smadd_state        : undef,
        smadd_cntry        => $addr ? $addr->smadd_cntry        : undef,
        smadd_zip          => $addr ? $addr->smadd_zip          : undef,
        smadd_lat          => $addr ? $addr->smadd_lat          : undef,
        smadd_long         => $addr ? $addr->smadd_long         : undef,
        smadd_status       => $addr ? $addr->smadd_status       : undef,

        # job
        employer  => $employer,
        job_title => $title,
    };

    # simple and complex facts
    my @facts
        = qw(gender household_income education_level political_affiliation
        ethnicity religion birth_year source_website lifecycle timezone);
    for my $fact (@facts) {
        $flat->{$fact} = $self->_get_fact($fact);

        # hardcode which complex values to fetch (for efficiency)
        if (   $fact eq 'gender'
            or $fact eq 'ethnicity'
            or $fact eq 'religion' )
        {
            $flat->{ $fact . ":srcval" }
                = $self->_get_fact_type( $fact, 'sf_src_value' );
            $flat->{ $fact . ":srcmap" }
                = $self->_get_fact_type( $fact, 'sf_src_fv_id' );
            $flat->{ $fact . ":usrmap" }
                = $self->_get_fact_type( $fact, 'sf_fv_id' );
        }
        elsif ($fact eq 'birth_year'
            or $fact eq 'source_website'
            or $fact eq 'timezone' )
        {
            $flat->{ $fact . ":srcval" }
                = $self->_get_fact_type( $fact, 'sf_src_value' );
        }
        else {
            $flat->{ $fact . ":srcmap" }
                = $self->_get_fact_type( $fact, 'sf_src_fv_id' );
            $flat->{ $fact . ":usrmap" }
                = $self->_get_fact_type( $fact, 'sf_fv_id' );
        }
    }

    # translate codes into something readable
    my @cm_xlates = qw(src_status src_has_acct sem_context sem_status
        sph_context sph_status smadd_context smadd_status);
    for my $name (@cm_xlates) {
        $flat->{$name} = AIR2::CodeMaster::lookup( $name, $flat->{$name} );
    }

    return $flat;
}

1;

