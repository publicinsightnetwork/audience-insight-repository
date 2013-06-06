package AIR2::Importer::BudgetHero;
use strict;
use warnings;

use base 'AIR2::Importer';
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::Utils;
use AIR2::Tank;
use AIR2::TankSource;
use AIR2::TankResponseSet;
use AIR2::TankResponse;
use AIR2::TankFact;
use JSON;
use Switch;
use Email::Valid;
use Path::Class;
use Config::IniFiles;

# additional required runtime params
__PACKAGE__->mk_accessors(qw(csv_filename csv_filedate));

# activity constant
my $ONLINE_ACTION_ACTM_ID = 47;

# required csv columns
my %csv_columns = (
    'First Name'            => 1,
    'Last Name'             => 1,
    'E-Mail Address'        => 1,
    'Gender'                => 1,
    'Date Of Birth'         => 1,
    'Political Affiliation' => 1,
    'Income'                => 1,
    'Address Type'          => 1,
    'State'                 => 1,
    'Zip'                   => 1,
    'Activity Type'         => 1,
    'Activity Domain'       => 1,
    'Activity Date'         => 1,
    'Activity Description'  => 1,
    'Activity Notes'        => 1,
);

# ignore first/last conflicts within a CSV
my %first_last_conflicts;

# db lookups
my $facts;
my $address_types;
my $org_map;

# various mappings
my @ini_mappings;
my $prj_bh_inq_map;

my $air2_dbh;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{atomic} = 1;    #ONLY run atomic

    # reset variables
    @ini_mappings   = ();
    $prj_bh_inq_map = undef;

    # init database
    $air2_dbh
        = AIR2::DBManager->new_or_cached()->get_write_handle()->retain_dbh;
    $self->_init_lookups();
    $self->_init_ini_file();

    # make sense of the CSV file name and date
    $self->{csv_filename} or croak "CSV filename required!";
    unless ( $self->{csv_filename} =~ /^[^\\\/]+\.csv$/i ) {
        croak "Invalid CSV filename";
    }
    $self->{csv_filedate} or croak "CSV filedate required!";
    unless ( length $self->csv_filedate == 8 ) {
        croak "Invalid CSV filedate. Must have format YYYYMMDD.";
    }

    # check that this file hasn't been imported AT ALL
    my $filename = $self->{csv_filename};
    my $rs = $air2_dbh->selectrow_arrayref( "select count(*) from tank where"
            . " tank_type = 'B' and tank_notes = '$filename'" );
    my $n = $rs ? $rs->[0] : 0;
    croak "CSV file '$filename' has already been imported!" if ( $n > 0 );

    # make sure our CSV has valid headers
    my $hdrs = $self->{reader}->get_headers();
    foreach my $key ( keys %csv_columns ) {
        unless ( defined( $hdrs->{$key} ) ) {
            croak "CSV missing column '$key'";
        }
    }
    return $self;
}

sub _init_lookups {
    my $self = shift;

    # fact_identifier => Fact
    my $q = 'select fact_identifier, fact_id, fact_fv_type from fact';
    $facts = $air2_dbh->selectall_hashref( $q, 'fact_identifier' );

    # Fact.values => FactValue
    $q = 'select fv_id, fact_identifier, lower(fv_value) as fv_value from '
        . 'fact_value join fact on (fv_fact_id=fact_id)';
    my $fvals = $air2_dbh->selectall_hashref( $q, 'fv_id' );
    foreach my $fvid ( keys %{$fvals} ) {
        my $factid = $fvals->{$fvid}->{fact_identifier};
        my $fvval  = $fvals->{$fvid}->{fv_value};
        $facts->{$factid}->{fact_values}->{$fvval} = $fvid;
    }

    # smadd_context ... cm_disp_value => cm_code
    $q = "select lower(cm_disp_value) as cm_disp_value, cm_code from "
        . "code_master where cm_field_name = 'smadd_context'";
    $address_types = $air2_dbh->selectall_hashref( $q, 'cm_disp_value' );

    # org_name => organization object
    my %orgs
        = map { lc $_->org_name => $_ } @{ AIR2::Organization->fetch_all };
    $org_map = \%orgs;
}

sub _init_ini_file {
    my $self = shift;

    my $etc    = AIR2::Config->get_app_root()->subdir('etc');
    my $bh_ini = "$etc/budgethero.ini";
    my $cfg    = Config::IniFiles->new( -file => $bh_ini );

    for my $name ( $cfg->Sections ) {
        my $regex = $cfg->val( $name, 'dom_regex' );
        my $orgstr = lc $cfg->val( $name, 'org_names' );
        my @orgs = split( ',', $orgstr );
        my $disp = $cfg->val( $name, 'disp_name' );

        # sanity
        croak "no regex for ini section '$name'"     unless $regex;
        croak "no orgs for ini section '$name'"      unless scalar @orgs > 0;
        croak "no disp_name for ini section '$name'" unless $disp;
        for my $orgname (@orgs) {
            croak "Unknown ini org '$orgname'" unless $org_map->{$orgname};
        }

        # push onto the stack
        push(
            @ini_mappings,
            {   regex => $regex,
                orgs  => \@orgs,
                name  => $name,
                disp  => $disp,
            }
        );
    }
}

sub _match_domain {
    my $self    = shift;
    my $domname = shift;
    for my $section (@ini_mappings) {
        my $regex = $section->{regex};
        if ( $domname =~ /$regex/i ) {
            return $section;
        }
    }
    croak "No matching ini-section found for domain '$domname'";
}

sub _get_tank_for_dom {
    my $self     = shift;
    my $domname  = shift;
    my $filename = $self->{csv_filename};
    my $filedate = $self->{csv_filedate};
    my $userid   = $self->{user}->user_id;

    # find the match ini-file section
    my $section = $self->_match_domain($domname);
    my $s_name  = $section->{name};
    my $s_disp  = $section->{disp};
    my $s_orgs  = $section->{orgs};

    # return existing tank, if we already created it
    if ( $section->{tank} ) {

        #warn "section->tank = $section->{tank}";
        return $section->{tank};
    }

    # create new tank for this section
    my $rec = AIR2::Tank->new(
        tank_uuid     => AIR2::Utils->str_to_uuid( 'budgethero' . $s_name ),
        tank_user_id  => $userid,
        tank_name     => $s_disp,
        tank_notes    => "Consolidated tank for budgethero.ini - $s_name",
        tank_type     => "B",
        tank_status   => "R",
        tank_cre_user => $userid,
        tank_upd_user => $userid,
    );
    $rec->load_speculative;

    # optionally updated the "newest csv imported" date
    if ( !$rec->tank_meta || "last_file_date=$filedate" gt $rec->tank_meta ) {
        $rec->tank_meta("last_file_date=$filedate");
    }

    # return if already exists
    if ( $rec->tank_id and $rec->has_related('activities') ) {
        $rec->save();
        $section->{tank} = $rec;
        return $rec;
    }
    $rec->save();

    # create orgs (including defaults)
    my $first_org_id     = 0;
    my $first_org_prj_id = 0;
    for my $orgname ( @{$s_orgs} ) {
        my $org = $org_map->{$orgname};

        # record first org/prj ids
        $first_org_id     = $org->org_id             unless $first_org_id;
        $first_org_prj_id = $org->org_default_prj_id unless $first_org_prj_id;

        # new tank-org
        my $to_rec = AIR2::TankOrg->new(
            to_tank_id => $rec->tank_id,
            to_org_id  => $org->org_id,
        );
        $to_rec->save();
    }

    # create activity
    my $tact_rec = AIR2::TankActivity->new(
        tact_tank_id => $rec->tank_id,
        tact_actm_id => $ONLINE_ACTION_ACTM_ID,
        tact_prj_id  => $first_org_prj_id,
        tact_dtim    => undef,                    #"$filedate 00:00:00",
        tact_desc     => "{SRC} played Budget Hero game via {XID} website",
        tact_notes    => "$filename",
        tact_xid      => $first_org_id,
        tact_ref_type => "O",
    );
    $tact_rec->save();

    # return
    $section->{tank} = $rec;
    return $rec;
}

sub _make_tank_source {
    my $self = shift;
    my $data = shift or die "data hashref required";

    # must have an email
    my $email = AIR2::Utils->str_clean( lc( $data->{'E-Mail Address'} ) );
    if ( !defined $email || !length $email ) {
        return 0;
    }
    if ( !Email::Valid->address($email) ) {
        $self->add_warning("Invalid email address '$email'");
        return 0;
    }

    # find correct tank to put this source in
    my $dom      = lc AIR2::Utils->str_clean( $data->{'Activity Domain'} );
    my $tank_rec = $self->_get_tank_for_dom($dom);

    # base data
    my $rec = AIR2::TankSource->new(
        tsrc_tank_id  => $tank_rec->tank_id,
        tsrc_cre_user => $tank_rec->tank_cre_user,
        tsrc_upd_user => $tank_rec->tank_upd_user,
        tsrc_tags     => 'budgethero',
        sem_email     => $email,
    );

    # prevent first/last conflicts
    unless ( defined $first_last_conflicts{$email} ) {
        $first_last_conflicts{$email} = { first => 0, last => 0 };
    }
    my $first = AIR2::Utils->str_clean( $data->{'First Name'} );
    if ( !$first_last_conflicts{$email}{first} && $first && length $first ) {
        $rec->src_first_name($first);
        $first_last_conflicts{$email}{first} = 1;
    }
    my $last = AIR2::Utils->str_clean( $data->{'Last Name'} );
    if ( !$first_last_conflicts{$email}{last} && $last && length $last ) {
        $rec->src_last_name($last);
        $first_last_conflicts{$email}{last} = 1;
    }

    # set other data
    my $addtype = AIR2::Utils->str_clean( $data->{'Address Type'} );
    $addtype = lc $addtype if $addtype;
    $addtype = $address_types->{$addtype}->{cm_code};
    my $addstate = AIR2::Utils->str_clean( $data->{'State'} );
    $addstate = undef unless ( length $addstate == 2 );
    my $addzip = AIR2::Utils->str_clean( $data->{'Zip'}, 10 );    #cut to 10

    if ( $addstate || $addzip ) {
        $rec->smadd_context($addtype) if $addtype;
        $rec->smadd_state($addstate)  if $addstate;
        $rec->smadd_zip($addzip)      if $addzip;
    }

    # facts
    my $facts = $self->_make_tank_facts($data);
    $rec->facts($facts);

    # save, and then create submissions (we need the tsrc_id)
    $rec->save();
    $self->_make_tank_submissions( $data, $rec );

    # return tank_source
    return $rec;
}

sub _make_tank_facts {
    my $self = shift;
    my $data = shift or die "data hashref required";
    my @tfacts;

    # gender
    my $gender = AIR2::Utils->str_clean( $data->{'Gender'} );
    if ( defined $gender || length $gender ) {
        my $gender_fact = AIR2::TankFact->new(
            tf_fact_id   => $facts->{gender}->{fact_id},
            sf_src_value => $gender,
        );
        push( @tfacts, $gender_fact );
    }

    # birth year
    my $birth = AIR2::Utils->str_clean( $data->{'Date Of Birth'} );
    if ( defined $birth || length $birth ) {
        my $birth_fact = AIR2::TankFact->new(
            tf_fact_id   => $facts->{birth_year}->{fact_id},
            sf_src_value => $birth,
        );
        push( @tfacts, $birth_fact );
    }

    # political affiliation
    my $poli = AIR2::Utils->str_clean( $data->{'Political Affiliation'} );
    if ( defined $poli && length $poli ) {

        # look for the fv_id
        my $fv_id
            = $facts->{political_affiliation}->{fact_values}->{ lc $poli };
        if ($fv_id) {
            my $poli_fact = AIR2::TankFact->new(
                tf_fact_id   => $facts->{political_affiliation}->{fact_id},
                sf_src_fv_id => $fv_id,
            );
            push( @tfacts, $poli_fact );
        }
        else {
            $self->add_warning("Unmappable political affiliation: '$poli'");
        }
    }

    # household income
    my $income = AIR2::Utils->str_clean( $data->{'Income'} );
    if ( defined $income && length $income ) {

        # remove the commas (per AIR2)
        $income =~ s/,//g;

        # look for the fv_id
        my $fv_id_h
            = $facts->{household_income}->{fact_values}->{ lc $income };
        if ($fv_id_h) {
            my $income_fact = AIR2::TankFact->new(
                tf_fact_id   => $facts->{household_income}->{fact_id},
                sf_src_fv_id => $fv_id_h,
            );
            push( @tfacts, $income_fact );
        }
        else {
            $self->add_warning("Unmappable household income: '$income'");
        }
    }

    # ethnicity (only in budgethero v4 CSV's)
    if ( $data->{'Ethnicity'} ) {
        my $ethnicity = AIR2::Utils->str_clean( $data->{'Ethnicity'} );
        if ( defined $ethnicity && length $ethnicity ) {
            my $ethnicity_fact = AIR2::TankFact->new(
                tf_fact_id   => $facts->{ethnicity}->{fact_id},
                sf_src_value => $ethnicity,
            );
            push( @tfacts, $ethnicity_fact );
        }
    }
    return \@tfacts;
}

sub _make_tank_submissions {
    my $self = shift;
    my $data = shift or die "data hashref required";
    my $tsrc = shift or die "tank_source object required";
    my $tank = $tsrc->tank;

    # does this data have any comments?
    my $comments = AIR2::Utils->str_clean( $data->{'Activity Notes'}, 65535 );
    $comments =~ s/^User Comment: // if ($comments);
    unless ( $comments && length $comments > 0 ) {
        return;
    }

    # get just-in-time budgethero inquiry for this project
    my $prjid = $tank->activities->[0]->tact_prj_id;
    my $inq   = $self->_get_budgethero_inquiry($prjid);

    # create TankResponseSet
    my $trs_rec = AIR2::TankResponseSet->new(
        trs_tsrc_id => $tsrc->tsrc_id,
        srs_inq_id  => $inq->inq_id,
        srs_date    => $data->{'Activity Date'} . " 00:00:00",
        srs_type    => 'C',                                      #comment
        responses   => [
            {   tr_tsrc_id    => $tsrc->tsrc_id,
                sr_ques_id    => $inq->questions->[0]->ques_id,
                sr_orig_value => $comments,
            },
        ],
    );
    $trs_rec->save();
}

sub _get_budgethero_inquiry {
    my $self  = shift;
    my $prjid = shift or die "project id required";
    my $inq   = $prj_bh_inq_map->{$prjid};

    # not cached or created yet
    unless ($inq) {
        my $uuid = AIR2::Utils->str_to_uuid("budgethero-$prjid");
        $inq = AIR2::Inquiry->new(
            inq_uuid      => $uuid,
            inq_title     => 'budget_hero_comments',
            inq_ext_title => 'Budget Hero Comments',
            inq_desc      => 'Query object to hold source comments from the'
                . ' Budget Hero game',
            inq_type          => 'C',                             #comment
            project_inquiries => [ { pinq_prj_id => $prjid } ],
        );

        # check if exists
        $inq->load_speculative;
        unless ( $inq->inq_id ) {
            $inq->questions(
                {   ques_type    => 'T',                          #text
                    ques_value   => 'Comments?',
                    ques_dis_seq => 1,
                }
            );
            $inq->save();
        }
        $prj_bh_inq_map->{$prjid} = $inq;
    }
    return $inq;
}

sub do_import {
    my $self     = shift;
    my $thing    = shift;
    my $tsrc_rec = 0;

    # create the tank source
    eval { $tsrc_rec = $self->_make_tank_source($thing); };

    # catch errors
    if ($@) {
        $self->debug and warn "IMPORT ERROR: $@\n";
        $self->add_error("Import Error: $@");
        return 0;    #error
    }

    # if no record returned, just skip
    return ( $tsrc_rec ? 1 : -1 );
}

sub start_transaction {
    my $self = shift;
    $self->SUPER::start_transaction(@_);

    # mysql transaction
    $air2_dbh->{AutoCommit} = 0;
    $air2_dbh->{RaiseError} = 1;
    return $self;
}

sub end_transaction {
    my $self = shift;
    $self->SUPER::end_transaction(@_);

    # mysql commit
    if ( !$self->dry_run && $self->{errored} == 0 ) {
        $air2_dbh->commit;
    }
    else {
        $air2_dbh->rollback;
    }
    return $self;
}

sub report {
    my $self   = shift;
    my $indent = shift or 0;
    my $rep    = '';

    # indent report
    my $d = ' ' x $indent;

    # commit action
    my $action = 'rolled back';
    $action = 'committed' if ( !$self->dry_run && $self->{errored} == 0 );
    $rep .= $d . "Finished -> changes $action\n";

    # completed/skipped/errors
    my $compl = $self->completed;
    my $skips = $self->skipped;
    my $warns = defined $self->warnings ? scalar @{ $self->warnings } : 0;
    my $errs  = defined $self->errors ? scalar @{ $self->errors } : 0;
    $rep .= $d
        . "$compl completed, $skips skipped, $warns warnings, $errs errors\n";

    # report warnings
    if ($warns) {
        $rep .= "\n" . $d . "WARNINGS:\n";
        for my $warn ( @{ $self->warnings } ) {
            $rep .= $d . "-$warn\n";
        }
    }

    # report errors
    if ($errs) {
        $rep .= "\n" . $d . "ERRORS:\n";
        for my $err ( @{ $self->errors } ) {
            $rep .= $d . "-$err\n";
        }
    }

    return $rep;
}

sub schedule_jobs {
    my $self  = shift;
    my $count = 0;

    # only schedule if we committed changes
    if ( !$self->dry_run && $self->{errored} == 0 ) {

        for my $section (@ini_mappings) {
            my $tank = $section->{tank};

            if ($tank) {
                $count++;
                my $tid = $tank->tank_id;
                my $job = AIR2::JobQueue->new(
                    jq_job => "PERL AIR2_ROOT/bin/run-discriminator $tid", );
                $job->save();

                #don't run... just wait for scheduling
                #my $ret = $job->run();
            }
        }

        # have to commit
        $air2_dbh->commit;
    }

    $self->debug and print "Scheduled $count jobs\n";
}

1;
