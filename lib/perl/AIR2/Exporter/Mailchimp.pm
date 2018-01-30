package AIR2::Exporter::Mailchimp;
use strict;
use warnings;
use base 'AIR2::Exporter';
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::Utils;
use lib AIR2::Config::get_app_root() . '/lib/shared/perl';
use Email::Valid;
use AIR2::Mailchimp;
use AIR2::SrcExport;
use AIR2::SrcInquiry;
use AIR2::SrcActivity;
use MySQLImporter;

__PACKAGE__->mk_accessors(
    qw(
        dry_run
        no_export
        no_bcc
        strict
        strict_window
        export_email
        export_bin
        user
        )
);

__PACKAGE__->mk_ro_accessors(
    qw(
        api
        seg_id
        seg_name
        campaign_id
        campaign_count
        bcc_emails
        )
);

my $TMP_CSV             = '/tmp/mailchimp-api-' . getpwuid($<);
my $AIR_HOST            = 'mprweb1';
my $CHECKED_INVALID     = 'I';
my $CHECKED_PIN_STATUS  = 'S';
my $CHECKED_NOSUCHEMAIL = 'N';
my $CHECKED_WHITELIST   = 'W';
my $CHECKED_SEM_STATUS  = 'SS';
my $CHECKED_ORG         = 'O';
my $CHECKED_MC_STATUS   = 'MS';
my $CHECKED_STRICT      = 'T';
my $CHECKED_OK          = 'A';
my $QA_ADDRESS          = 'pij-mail-qa@mpr.org';

# src_activity descriptions and actm_id's (map from an email_type)
my %SACT_DESCS = (
    'Q' => '{USER} emailed {XID} to source {SRC}',
    'F' => '{USER} sent follow-up {XID} to source {SRC}',
    'R' => '{USER} sent reminder {XID} to source {SRC}',
    'T' => '{USER} sent thank-you {XID} to source {SRC}',
    'O' => '{USER} emailed {XID} to source {SRC}',
);
my %ACTM_IDS = (
    'Q' => 13,
    'F' => 29,
    'R' => 29,
    'T' => 17,
    'O' => 29,
);

# setup
sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # options with defaults
    $self->{dry_run}       = 0     unless defined $self->{dry_run};
    $self->{no_export}     = 0     unless defined $self->{no_export};
    $self->{no_bcc}        = 0     unless defined $self->{no_bcc};
    $self->{strict}        = 1     unless defined $self->{strict};
    $self->{strict_window} = 86400 unless defined $self->{strict_window};

    # required params
    $self->{export_email} or croak "email record required";
    $self->{export_bin}   or croak "bin record required";

    # always bcc the sending user and qa on campaigns
    unless ( $self->{no_bcc} ) {
        $self->{bcc_emails}->{$QA_ADDRESS} = 1;
        my $usr_email = $self->{user}->get_primary_email if $self->{user};
        $self->{bcc_emails}->{ $usr_email->uem_address } = 1 if $usr_email;
    }

    # org used only to compare source's orgs against
    $self->{org} = $self->{export_email}->organization;

    $self->{api} ||= AIR2::Mailchimp->new();

    return $self;
}

# ye olde report
sub report {
    my $self   = shift;
    my $report = sprintf(
        "Export to Mailchimp campaign '%s' finished with:\n\n%d errors, %d skipped, %d completed\n",
        ( $self->{campaign_id} || "(not-exported)" ),
        $self->errored, $self->skipped, $self->completed
    );
    if ( $self->{campaign_id} ) {
        $report .= sprintf(
            "seg_id(%s), seg_name(%s)\ncampaign_id(%s), campaign_count(%d)\n",
            $self->{seg_id},      $self->{seg_name},
            $self->{campaign_id}, $self->{campaign_count}
        );
    }

    $report .= "\n";
    if ( @{ $self->errors } ) {
        $report .= join( "\n", map { "ERROR: " . $_ } @{ $self->errors } );
    }
    if ( @{ $self->warnings } ) {
        $report
            .= join( "\n", map { "WARNING: " . $_ } @{ $self->warnings } );
    }
    return $report . "\n";
}

# individual src_email export
sub do_export {
    my $self      = shift;
    my $src_email = shift;
    my $addr      = $src_email->{sem_email};

    if ( $self->debug and $self->debug > 1 ) {
        dump($src_email);
    }

    # do cheapest checks first.
    if ( !$addr ) {
        $self->debug and warn "No sem_email defined\n";
        return -2;
    }
    if ( exists $self->{was_skipped}->{$addr} ) {
        $self->debug and warn "$addr was skipped already\n";
        return -2;
    }
    if ( exists $self->{was_checked}->{$addr}
        and $self->{was_checked}->{$addr} !~ m/^(U)$/ )
    {
        $self->debug
            and warn
            "$addr already checked [$self->{was_checked}->{$addr}]\n";
        return -2;
    }

    # pattern checks
    if ( !Email::Valid->address($addr) ) {
        $self->debug and warn "$addr is not a valid email address\n";
        $self->add_warning("$addr is not a valid email address");
        $self->{was_checked}->{$addr} = $CHECKED_INVALID;
        if ( $src_email->{sem_status} eq "G" ) {
            $self->_flag_bad_email($addr);
        }
        $self->{was_skipped}->{$addr}++;
        return -1;
    }
    if ( $addr =~ m/\@nosuchemail\.org$/ ) {
        $self->debug and warn "$addr is not a real email address\n";
        $self->add_warning("$addr is not a real email address");
        $self->{was_checked}->{$addr} = $CHECKED_NOSUCHEMAIL;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # PIN status
    if ( $src_email->{src_status} !~ m/^[AET]$/ ) {
        $self->debug and warn "$addr is not active in the PIN\n";
        $self->add_warning("$addr is not active in the PIN");
        $self->{was_checked}->{$addr} = $CHECKED_PIN_STATUS;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # if AIR record is flagged as not-good, skip it.
    if ( $src_email->{sem_status} ne "G" ) {
        $self->debug
            and warn
            "$addr has non-good sem_status [$src_email->{sem_status}]\n";
        $self->add_warning(
            "$addr has non-good sem_status [$src_email->{sem_status}]");
        $self->{was_checked}->{$addr} = $CHECKED_SEM_STATUS;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # strict check
    my $epoch = $src_email->{sstat_export_epoch} || 0;
    my $epwin = time() - $self->strict_window;
    if ( $self->strict && ( $epoch > $epwin ) ) {
        my $lt = localtime( $src_email->{sstat_export_epoch} );
        $self->debug
            and warn "$addr failed strict check (last exported $lt)\n";
        $self->add_warning("$addr failed strict check (last exported $lt)");
        $self->{was_checked}->{$addr} = $CHECKED_STRICT;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # ignore org_id mismatches (i.e. source not in org)
    if (  !$src_email->{soc_org_id}
        || $src_email->{soc_org_id} != $self->{org}->org_id )
    {
        $self->debug and warn "$addr soc_org_id mismatch ... skipping\n";
        $self->add_warning("$addr soc_org_id mismatch ... skipping");
        $self->{was_checked}->{$addr} = $CHECKED_ORG;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # last chance - source not active in org
    if ( $src_email->{soc_status} ne 'A' ) {
        my $orgstr = $src_email->{so_name} || '';
        $self->debug and warn "$addr not active in org $orgstr\n";
        $self->add_warning("$addr not active in org $orgstr");
        $self->{was_checked}->{$addr} = $CHECKED_ORG;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # if this is one of the BCC addresses, don't include it twice
    if ( $self->{bcc_emails}->{$addr} ) {
        delete $self->{bcc_emails}->{$addr};
    }

    # finally, whitelist emails non-production environments can send
    unless ( AIR2::Utils::allow_email_export($addr) ) {
        $self->debug
            and warn "$addr cannot be exported in non-prod environment\n";
        $self->add_warning(
            "$addr cannot be exported in non-prod environment");
        $self->{was_checked}->{$addr} = $CHECKED_WHITELIST;
        $self->{was_skipped}->{$addr}++;
        return -1;
    }

    # if we get here, we're ok to export
    $self->{was_checked}->{$addr} = $CHECKED_OK;
    $self->{emails}->{$addr}      = $src_email;
    $self->debug and warn "$addr ok to export\n";
    return 1;
}

# queue src_activity, src_inquiry, src_export INSERTs
sub start_transaction {
    my $self = shift;
    $self->SUPER::start_transaction();

    # state tracking
    $self->{was_checked} = {};

    # because we have "duplicate" records to evaluate, our skipped
    # count is off. So track it ourselves so skipped() is accurate.
    $self->{was_skipped} = {};
}

# run inserts with MySQLImporter
sub end_transaction {
    my $self = shift;

    # set counts
    $self->{errored} = scalar( @{ $self->errors } );
    $self->{skipped} = scalar( keys %{ $self->{was_skipped} } );
    return 1 if $self->dry_run;
    return 1 unless ( scalar keys %{ $self->{emails} } );

    # create mailchimp segment
    my $name = $self->{export_email}->email_campaign_name;
    my @emls = keys %{ $self->{emails} };
    my @bccs = keys %{ $self->{bcc_emails} };
    my $res1 = $self->{api}->sync_list( email => \@emls );
    my $res2 = $self->{api}->make_segment(
        email => \@emls,
        name  => $name,
        bcc   => \@bccs,
    );
    $self->{seg_id}   = $res2->{id};
    $self->{seg_name} = $res2->{name};

    # handle anything mailchimp skipped
    for my $pair ( @{ $res2->{skip_list} } ) {
        my ( $addr, $was_skipped ) = @$pair;
        delete $self->{emails}->{$addr};
        $self->debug and warn "Mailchimp unable to subscribe $addr\n";
        $self->add_error("Mailchimp unable to subscribe $addr\n");
        $self->_flag_bad_email($addr);
        $self->{was_checked}->{$addr} = $CHECKED_MC_STATUS;
        $self->{errored}++;
        $self->{completed}--;
    }

    # create the campaign
    my $res3 = $self->{api}->make_campaign(
        template => $self->{export_email},
        segment  => $self->{seg_id}
    );
    $self->{campaign_id}    = $res3->{id};
    $self->{campaign_count} = $res3->{count};

    # AIR log records
    $self->_create_log_records( $self->{campaign_id}, \@bccs );

    # finally, SEND IT
    unless ( $self->no_export ) {
        my $res4
            = $self->{api}->send_campaign( campaign => $self->{campaign_id} );
        unless ($res4) {
            croak "Unable to send campaign - $self->{campaign_id}\n";
        }
    }

    $self->SUPER::end_transaction();
}

sub _flag_bad_email {
    my $self = shift;
    my $addr = shift or croak "email address required";

    my $sem = AIR2::SrcEmail->new( sem_email => $addr )->load;
    $sem->sem_status('B');
    unless ( $self->dry_run ) {
        $sem->save();
        $sem->source->set_and_save_src_status();
    }
}

sub _create_log_records {
    my ( $self, $camp_id, $bcc_emails ) = @_;
    my $email_type = $self->{export_email}->email_type;

    # 1 src_export record with campaign_id, to reconcile later.
    my $src_export = AIR2::SrcExport->new(
        se_email_id => $self->{export_email}->email_id,
        se_name     => $camp_id,
        se_type     => 'M',
        se_status   => 'Q',
        se_xid      => $self->{export_bin}->bin_id,
        se_ref_type => 'I',
        se_cre_user => $self->user->user_id,
        se_upd_user => $self->user->user_id,
    );
    $src_export->set_meta( 'initial_count',
        $self->{errored} + $self->{skipped} + $self->{completed} );
    $src_export->set_meta( 'export_count', $self->{completed} );
    if ( scalar @{$bcc_emails} ) {
        $src_export->set_meta( 'bcc', join( ',', @{$bcc_emails} ) );
    }
    $src_export->save();

    # source record importers
    mkdir $TMP_CSV;
    my $sact_importer = MySQLImporter->new(
        table_name => 'src_activity',
        columns    => [ sort @{ AIR2::SrcActivity->meta->column_names } ],
        dbh        => $src_export->db->get_write_handle->retain_dbh,
        file_name  => "$TMP_CSV/$camp_id.sact.import",
    );
    my $si_importer = MySQLImporter->new(
        table_name => 'src_inquiry',
        columns    => [ sort @{ AIR2::SrcInquiry->meta->column_names } ],
        dbh        => $src_export->db->get_write_handle->retain_dbh,
        file_name  => "$TMP_CSV/$camp_id.si.import",
    );
    my $now = AIR2::Utils::current_time();

    # process sources
    for my $addr ( sort keys %{ $self->{emails} } ) {
        my $src_email = $self->{emails}->{$addr};

        # 1 src_activity for each email
        my $sact = {
            sact_src_id   => $src_email->{src_id},
            sact_prj_id   => undef,
            sact_actm_id  => $ACTM_IDS{$email_type},
            sact_dtim     => $now,
            sact_desc     => $SACT_DESCS{$email_type},
            sact_notes    => "campaign_id=$camp_id",
            sact_cre_user => $self->user->user_id,
            sact_upd_user => $self->user->user_id,
            sact_cre_dtim => $now,
            sact_upd_dtim => $now,
            sact_xid      => $self->{export_email}->email_id,
            sact_ref_type => 'E',
        };
        for my $k ( @{ $sact_importer->columns } ) {
            $sact_importer->buffer( $sact->{$k} );
        }
        $sact_importer->end_record();

        # for email_type=Q, we also...
        # 1) log src_inquiry records
        # 2) update sstat_export_dtim (this counts as export)
        if ( $self->{export_email}->email_type eq 'Q' ) {

            # 0-or-more src_inquiry per email
            for my $inq ( @{ $self->{export_email}->inquiries } ) {
                my $si = {
                    si_src_id   => $src_email->{src_id},
                    si_inq_id   => $inq->inq_id,
                    si_sent_by  => $camp_id,
                    si_status   => 'P',
                    si_cre_user => $self->user->user_id,
                    si_upd_user => $self->user->user_id,
                    si_cre_dtim => $now,
                    si_upd_dtim => $now,
                };
                for my $k ( @{ $si_importer->columns } ) {
                    $si_importer->buffer( $si->{$k} );
                }
                $si_importer->end_record();
            }

            # update cached export time
            my $stat
                = AIR2::SrcStat->new( sstat_src_id => $src_email->{src_id} );
            $stat->load_speculative();
            $stat->sstat_export_dtim($now);
            $stat->save();
        }
    }

    # load stuff!
    $sact_importer->load();
    $si_importer->load();
}

1;
