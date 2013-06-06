package AIR2::Importer::Formbuilder;
use strict;
use warnings;

# force mysql master connection
BEGIN {
    $ENV{FB_TYPE}         = 'formbuilder';
    $ENV{AIR2_USE_MASTER} = 1;
}

use base 'AIR2::Importer';
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::Utils;
use AIR2::Project;
use AIR2::Inquiry;
use AIR2::Organization;
use AIR2::Source;
use AIR2::SrcActivity;
use AIR2::Tank;
use AIR2::TankSource;
use AIR2::TankResponseSet;
use AIR2::TankResponse;
use AIR2::TankFact;
use AIR2::TranslationMap;
use JSON;
use Switch;
use Formbuilder::CtbAskResponse;

__PACKAGE__->mk_accessors(
    qw(
        no_import
        strict
        email_notify
        default_org
        test_transaction
        force
        )
);

my %fb_qt_externals = (
    occupation      => 'vita',
    education       => 'fact',
    employer        => 'vita',
    prof_title      => 'vita',
    pol_office      => 'vita',
    organization    => 'vita',
    gender          => 'fact',
    income          => 'fact',
    pol_affiliation => 'fact',
    religion        => 'fact',
    race            => 'fact',
    industry        => 'vita',
    birth_year      => 'fact',
    web_presence    => 'fact',
    photo_location  => 'media',
    pref_lang       => 'pref',
);

# ques_type == Z for contributor type
# values map to $QUESTION_TEMPLATES keys
my %ques_types = (
    ctb_email       => 'email',
    ctb_first_name  => 'firstname',
    ctb_last_name   => 'lastname',
    ctb_street_addr => 'street',
    ctb_city        => 'city',
    ctb_st_code     => 'state',
    ctb_zipcode     => 'zip',
    ctb_cntry_code  => 'country',
    ctb_phone       => 'phone',

);

my %ques_types_rev = reverse %ques_types;

# default to String, override specifics
my %ques_type2resp_type = map { $_ => 'S' } ( 'A' .. 'Z', 'a' .. 'z' );
$ques_type2resp_type{'F'} = 'F';

# map languages to locales
my %LOCALE_MAP = (
    'English'       => 'en_US',
    'Spanish'       => 'es_US',
    'Inglés'       => 'en_US',
    'Español'      => 'es_US',
    'no_preference' => 'None',
);

# DB constants
my $PREFERRED_LANG_PT_ID        = $AIR2::PreferenceType::LANG_ID;
my $QUERY_RESPONSE_ACTM_ID      = 4;
my $EN_US_LOCALE                = 52;
my $ES_US_LOCALE                = 72;
my $MEMBERS_CHANGED_ACTM_ID     = 35;
my $PROJECT_ADDED_QUERY_ACTM_ID = 42;
my $QUES_PERMISSION_TO_SHARE_ID = 12;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->{debug} ) {
        $self->{debug} = $ENV{FB_DEBUG} || 0;
    }
    $self->{dry_run} ||= 0;
    $self->{strict} = 1 unless defined $self->{strict};
    $self->{email_notify} or croak "email_notify required";
    $self->{completed} = {};
    $self->{skipped}   = {};

    # cache some data to make it easy to look up
    $self->{_cache}->{orgs}
        = { map { $_->org_uuid => $_ } @{ AIR2::Organization->fetch_all } };
    $self->{_cache}->{users}
        = { map { $_->user_username => $_ } @{ AIR2::User->fetch_all } };
    $self->{_cache}->{projects}
        = { map { $_->prj_name => $_ } @{ AIR2::Project->fetch_all } };
    $self->_cache_facts();

    return $self;
}

sub _cache_facts {
    my $self  = shift;
    my $facts = AIR2::SearchUtils::all_facts_by_id();

    my %table;
    for my $fact_id ( sort { $a <=> $b } keys %$facts ) {
        my $fact = $facts->{$fact_id};
        $table{ $fact->fact_identifier }->{fact_id} = $fact_id;
        for my $fact_value (
            @{ $fact->find_fact_values( sort_by => 'fv_seq ASC' ) } )
        {
            next if $fact_value->fv_status ne 'A';
            my $label = $fact_value->fv_value;
            my $pk    = $fact_value->fv_id;
            $table{ $fact->fact_identifier }->{$label} = $pk;
        }
    }
    $self->{_cache}->{facts} = \%table;
}

sub _get_user_id {
    my $self     = shift;
    my $username = shift;
    if ( !$username or !exists $self->{_cache}->{users}->{$username} ) {
        return 1;    # admin
    }
    return $self->{_cache}->{users}->{$username}->user_id;
}

sub _get_air2_org {
    my $self = shift;
    my $orguuid = shift or croak "orguuid required";
    if ( length($orguuid) != 12 ) {
        my $org = AIR2::Organization->new( org_name => $orguuid );
        $org->load_speculative;
        if ( $org->org_id ) {
            $orguuid = $org->org_uuid;
        }
    }
    if ( !exists $self->{_cache}->{orgs}->{$orguuid} ) {
        croak "No such Organization: $orguuid";
    }
    return $self->{_cache}->{orgs}->{$orguuid};
}

sub find_air2_project {
    my $self = shift;
    my $code = shift or croak "project code required";
    $self->debug and carp "Looking for project $code";
    if ( !exists $self->{_cache}->{projects}->{$code} ) {
        my $p = AIR2::Project->new( prj_name => $code );
        $p->load_speculative();
        if ( $p->prj_id ) {
            $self->{_cache}->{projects}->{$code} = $p;
            return $p;
        }
        if ( length($code) <= 12 ) {
            $p = AIR2::Project->new( prj_uuid => $code );
            $p->load_speculative();
            if ( $p->prj_id ) {
                $self->{_cache}->{projects}->{$code} = $p;
                return $p;
            }
        }

        # always return an object
        $p->prj_uuid(undef);    # un-stick
        return $p;
    }
    return $self->{_cache}->{projects}->{$code};
}

sub find_air2_inquiry {
    my $self = shift;
    my $code = shift or croak "ask code required";
    my $inq  = AIR2::Inquiry->new( inq_uuid => $code );
    $inq->load_speculative;
    return $inq;
}

sub find_air2_question {
    my $self    = shift;
    my $askq_id = shift or croak "askq_id required";
    my $uuid    = $self->_get_ques_uuid($askq_id);
    my $ques    = AIR2::Question->new( ques_uuid => $uuid );
    $ques->load_speculative;
    return $ques;
}

# override to make reporting more granular, delegating it
# to do_import()
sub run {
    my $self     = shift;
    my $reader   = $self->reader;
    my $max_errs = $self->max_errors;
    my $count    = 0;
    $self->start_transaction() if $self->atomic;
    while ( my $thing = $reader->next ) {
        $count++ if $self->do_import($thing);
    }
    $self->release_tank_locks();
    $self->end_transaction() if $self->atomic;
    return $count;
}

sub do_import {
    my $self  = shift;
    my $thing = shift;
    if ( $thing->isa('Formbuilder::Project') ) {
        return $self->import_project($thing);
    }
    elsif ( $thing->isa('Formbuilder::Ask') ) {
        return $self->import_ask($thing);
    }
    elsif ( $thing->isa('Formbuilder::CtbAskResponse') ) {
        return $self->import_car($thing);
    }
    elsif ( $thing->isa('Formbuilder::AskQuestion') ) {
        return $self->import_question( $thing,
            $self->find_air2_inquiry( $thing->ask->ask_code ) );
    }
    else {
        croak "unsupported object type " . ref($thing);
    }

}

sub _get_ques_uuid {
    my ( $self, $id ) = @_;
    return AIR2::Utils->str_to_uuid( $id . "-dbconv" );
}

## cribbed from AIR1Conv
sub import_question {
    my $self = shift;
    my $askq = shift or die "Formbuilder::AskQuestion object required";
    my $inq  = shift or die "AIR2::Inquiry required";

    # if for some reason $inq does not yet exist, we have a FK constraint
    # issue, so try our best to import it and croak if we can't
    if ( !$inq->inq_id ) {
        my $ask_code = $inq->inq_uuid;
        if ( !$ask_code ) {
            croak "Cannot import ask_question "
                . $askq->askq_id
                . " for non-existent Inquiry";
        }
        my $ask = Formbuilder::Ask->new( ask_code => $ask_code )
            ->load_speculative;
        if ( !$ask or !$ask->ask_id ) {
            croak
                "Can't find ask_code $ask_code in Formbuilder, so can't import ask_question "
                . $askq->askq_id;
        }
        $self->import_ask($ask);
        $inq = $self->find_air2_inquiry($ask_code);
        if ( !$inq->inq_id ) {
            croak "Unable to import Ask for ask_question " . $askq->askq_id;
        }
    }

    # find type from qtyp_sdesc
    my $type = 'T';    #text (default)
    switch ( $askq->type->qtyp_sdesc ) {
        case m/textarea/i       { $type = 'A' }
        case m/drop-down list/i { $type = 'O' }
        case m/radio button/i   { $type = 'R' }
        case m/check box/i      { $type = 'C' }
        case m/date/i           { $type = 'D' }
        case m/date and time/i  { $type = 'I' }
        case m/file upload/i    { $type = 'F' }
    }

    my $resp_type = $ques_type2resp_type{$type};

    # map flag to type
    if ( $askq->askq_hidden ) {
        $type = 'H';
    }

    # check for multi-select drop-down lists
    if ( $type eq 'O' && $askq->askq_resp_multiselect ) {
        $type = 'L';
    }

    # get question choices
    my $choices;
    if ( $type eq 'O' || $type eq 'R' || $type eq 'C' || $type eq 'L' ) {
        my @data;
        for my $qv ( @{ $askq->askq_values } ) {
            if ( $qv->askqv_value && length $qv->askqv_value ) {
                my $ch = {
                    value     => AIR2::Utils->str_clean( $qv->askqv_value ),
                    isdefault => $qv->askqv_default_flag eq 'Y',
                };
                push( @data, $ch );
            }
        }
        $choices = encode_json( \@data );
    }

    # response options
    my $resp_opts = {
        'maxlen'  => $askq->askq_resp_max_length,
        'require' => $askq->askq_resp_required ? JSON::true : JSON::false,
        'dir'     => $askq->askq_disp_direction,
    };
    if ( $type eq 'A' ) {
        $resp_opts->{cols} = $askq->askq_disp_cols;
        $resp_opts->{rows} = $askq->askq_disp_rows;
    }

    # get question value
    my $uuid  = $self->_get_ques_uuid( $askq->askq_id );
    my $value = AIR2::Utils->str_clean( $askq->askq_text );
    unless ( defined $value and length $value ) {

        #$value = '(none)';
        #warn "    WARNING: no ques_value for ques_uuid($uuid)\n";
        return -1;    # indicate skipped
    }

    # "public" questions are a new concept in AIR2,
    # but we do have the standard question in FB
    # which we can key off of.
    if (   $askq->askq_qt_id
        && $askq->askq_qt_id == $QUES_PERMISSION_TO_SHARE_ID )
    {
        $type = $type eq 'H' ? 'p' : 'P';
    }

    my %ques_vals = (
        ques_uuid        => $uuid,
        ques_inq_id      => $inq->inq_id,
        ques_dis_seq     => $askq->askq_disp_seq,
        ques_type        => $type,
        ques_resp_type   => $resp_type,
        ques_value       => $value,
        ques_choices     => $choices,
        ques_resp_opts   => encode_json($resp_opts),
        ques_cre_user    => $inq->inq_cre_user,
        ques_upd_user    => $inq->inq_upd_user,
        ques_cre_dtim    => $inq->inq_cre_dtim,
        ques_upd_dtim    => $inq->inq_upd_dtim,
        ques_public_flag => 0,                         # can edit this in AIR
    );
    my $ques = AIR2::Question->new( ques_uuid => $uuid );
    $ques->load_speculative();
    if ( $ques->ques_id ) {

        # if no values have changed, then skip it.
        my $changed = 0;
        my $current = $ques->column_value_pairs;
        for my $k ( keys %ques_vals ) {

            # quote values to force objects to stringify
            if (    defined $ques_vals{$k}
                and defined $current->{$k}
                and "$current->{$k}" eq "$ques_vals{$k}" )
            {
                next;
            }
            $ques->$k( $ques_vals{$k} );
            $changed++;
        }
        if ( !$changed ) {
            return -1;
        }
    }
    else {
        for my $k ( keys %ques_vals ) {
            $ques->$k( $ques_vals{$k} );
        }
    }

    $ques->save() and $self->{completed}->{questions}++;

    return $ques;
}

# This is the important one, and most complicated.
#
# * create tank record for each distinct affected org (based on ask_air2_org or project)
# * check that parent project, ask and questions are all in the db
# * put contributor in the tank
# * put car in the tank
# * put card(s) in the tank
# * update status on car record to reflect its import (see AIR1 for reference)

sub import_car {
    my $self = shift;
    my $car  = shift or croak "FB car object required";
    my $ask  = $car->ask;

    # wrap this entire set in a single transaction, on the AIR2 side.
    my $db = AIR2::DBManager->new_or_cached()->get_write_handle();
    my $tank;
    my $tsrc_saved = 0;
    my $car_saved  = 0;
    $db->do_transaction(
        sub {

            # sanity check: does this response have any actual content?
            my $has_content = 0;
            for my $card ( @{ $car->ctb_ask_response_dtls } ) {
                if ( defined $card->card_value
                    and length $card->card_value )
                {
                    $has_content = 1;
                    last;
                }
            }

            # more sanity: do we have a minimum of these fields?
            my @minf = qw(ctb_email ctb_first_name ctb_last_name ctb_zipcode);
            my $has_min_flds = 1;
            for my $fld_name (@minf) {
                unless ( defined $car->contributor->$fld_name
                    and length $car->contributor->$fld_name )
                {
                    $has_min_flds = 0;
                    last;
                }
            }

            # must be missing both to be skipped
            if ( !$has_content && !$has_min_flds ) {
                $car->car_air_export_status(
                    $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_SKIPPED);
                $car->save;
                $self->{skipped}->{cars}++;
                return -1;
            }

            # find corresponding Inquiry
            my $air2_inq = $self->find_air2_inquiry( $ask->ask_code );
            if ( !$air2_inq->inq_id ) {
                $self->debug
                    and warn "car "
                    . $car->car_id
                    . " did not have parent Inquiry imported already";
                $self->add_warning( "car "
                        . $car->car_id
                        . " did not have parent Inquiry imported already" );
                $self->import_ask($ask);
                $air2_inq = $self->find_air2_inquiry( $ask->ask_code );
                $air2_inq->inq_id
                    or croak "Unable to find parent Inquiry for car "
                    . $car->car_id;
            }

            #warn sprintf( "car import has parent AIR2 inquiry %s [%d]",
            #    $air2_inq->inq_uuid, $air2_inq->inq_id );
            #warn dump( $air2_inq->flatten( max_depth => 1 ) );

            my @orgs = @{ $air2_inq->organizations() };

            # TODO once project authz is figured out, this might be too naive.
            my $project = $air2_inq->projects()->[0];

            if ( !@orgs && $project ) {
                @orgs = @{ $project->organizations() };
            }
            if ( !@orgs ) {
                @orgs = ( $self->default_org );
            }

            # get the tank and lock it ... if we CANNOT lock the tank, we MUST
            # skip this CAR for now, without changing status
            $tank = $self->_get_tank_lock( \@orgs, $project, $air2_inq );
            unless ($tank) {
                $self->{skipped}->{cars}++;
                return -1;
            }

            # make sure the AIR inquiry has questions for contributor fields
            $self->_check_inquiry_for_contributor_questions( $air2_inq,
                $ask );

            # find Contributor
            my $ctb = $car->contributor;
            my $phone
                = AIR2::Utils::parse_phone_number( $ctb->ctb_phone || '' );
            my $tank_source = AIR2::TankSource->new(
                src_first_name =>
                    AIR2::Utils->str_clean( $ctb->ctb_first_name ),
                src_last_name =>
                    AIR2::Utils->str_clean( $ctb->ctb_last_name ),
                sem_email => AIR2::Utils->str_clean( lc( $ctb->ctb_email ) ),
                smadd_line_1 =>
                    AIR2::Utils->str_clean( $ctb->ctb_street_addr ),
                smadd_city  => AIR2::Utils->str_clean( $ctb->ctb_city ),
                smadd_state => AIR2::Utils->str_clean( $ctb->ctb_st_code ),
                smadd_cntry => AIR2::Utils->str_clean( $ctb->ctb_cntry_code ),
                smadd_zip   => AIR2::Utils->str_clean( $ctb->ctb_zipcode ),
                sph_number  => substr( ( $phone->{number} || '' ), 0, 16 ),
                sph_ext     => $phone->{ext},
            );

            $tank->add_sources($tank_source);
            $tank->save();  # so we can get tsrc_id for its children responses

            # create TankResponseSet
            my $approved = 0;
            if ( defined $car->car_approved and $car->car_approved eq 'Y' ) {
                $approved = 1;
            }
            my $tank_srs = AIR2::TankResponseSet->new(
                trs_tsrc_id => $tank_source->tsrc_id,
                srs_inq_id  => $air2_inq->inq_id,
                srs_date    => $car->car_cre_dtim,
                srs_uri     => $car->car_refer_url
                ? substr( $car->car_refer_url, 0, 65535 )
                : undef,
                srs_type => 'F',

                # Publishing API approval done after import
                srs_public_flag => 0,

                # delete_flag, translated_flag and export_flag
                # are currently un-used.
                srs_delete_flag      => 0,
                srs_translated_flag  => 0,
                srs_export_flag      => 0,
                srs_fb_approved_flag => $approved,
                srs_conf_level       => 'A',
                srs_xuuid            => $car->car_id,
                srs_uuid => AIR2::Utils->str_to_uuid( 'car-' . $car->car_id ),
            );

            # 2 loops.
            # first to cache questions and determine public_permission.
            # second to create tank records.
            # public_permission applied to all public questions, so must
            # loop through all first to get that value.
            my @resp;
            my $public_permission_given = 0;
            my %resp2question           = ();
            for my $card ( @{ $car->ctb_ask_response_dtls } ) {
                my $ques = $self->_get_question(
                    $self->_get_ques_uuid( $card->card_askq_id ) );
                if ( !$ques->ques_id ) {
                    $ques = $self->import_question( $card->ask_question,
                        $air2_inq );
                    if ( !ref $ques ) {

                        # only bother warning if it seems legitimate
                        # that the question should be present in AIR
                        my $fb_ques_val = $card->ask_question->askq_text;
                        if ( defined $fb_ques_val and length $fb_ques_val ) {
                            warn "No question found for ask_question "
                                . $card->card_askq_id;
                        }

                        # skip this particular sr_response
                        next;
                    }
                }

                # some questions are mapped directly
                # to AIR schema via question_template
                my $ques_tmpl = $card->ask_question->template;

                # do stars align for public permission granted?
                # if the submission answered YES to standard question,
                # and this particular question was flagged as public,
                # then ok to set initial value of sr_public_flag.
                # AIR user can redact (set == 0) later.
                if (    $ques_tmpl
                    and $ques_tmpl->qt_id == $QUES_PERMISSION_TO_SHARE_ID
                    and defined $card->card_value
                    and $card->card_value =~ m/^(y|yes|si)$/i
                    and $ques->ques_type eq 'P' )
                {
                    $public_permission_given = 1;
                }

                $resp2question{ $card->card_id } = $ques;
            }

            for my $card ( @{ $car->ctb_ask_response_dtls } ) {
                my $ques = $resp2question{ $card->card_id } or next;
                my $sr_orig_value
                    = AIR2::Utils->str_clean( $card->card_value, 65535 );
                my $tr = AIR2::TankResponse->new(
                    tr_tsrc_id     => $tank_source->tsrc_id,
                    sr_ques_id     => $ques->ques_id,
                    sr_public_flag => (
                          $ques->ques_public_flag
                        ? $public_permission_given
                        : 0
                    ),
                    sr_media_asset_flag => 0,
                    sr_orig_value       => $sr_orig_value,
                    sr_mod_value        => undef,
                    sr_status           => 'A',
                    sr_uuid =>
                        AIR2::Utils->str_to_uuid( 'card-' . $card->card_id ),
                );
                push @resp, $tr;

                my $ques_tmpl = $card->ask_question->template;

                if (    $ques_tmpl
                    and $ques_tmpl->qt_external_code
                    and
                    exists $fb_qt_externals{ $ques_tmpl->qt_external_code } )
                {
                    $self->_map_response_to_source(
                        $ques_tmpl->qt_external_code,
                        $tank_source, $car, $card );
                }

            }

            # add contributor fields
            my $contrib_questions
                = $self->{_contrib_question_cache}->{ $air2_inq->inq_id };

            for my $field ( keys %$contrib_questions ) {
                my $ques = $contrib_questions->{$field};
                my $tr   = AIR2::TankResponse->new(
                    tr_tsrc_id => $tank_source->tsrc_id,
                    sr_ques_id => $ques->ques_id,
                    sr_public_flag => 0,              # let user whitelist
                    sr_orig_value  => $ctb->$field,
                    sr_mod_value   => undef,
                    sr_status      => 'A',
                );
                push @resp, $tr;
            }

            $tank_srs->add_responses( \@resp );
            $tank_source->add_response_sets( [$tank_srs] );

            # must save explicitly because $tank does not cascade
            $tsrc_saved = $tank_source->save();

            # update formbuilder as complete.
            # because we are in transaction on AIR2 db,
            # must handle this transaction ourselves.
            my $car_db = $car->db;
            if ( $car_db->begin_work == Rose::DB::Constants::IN_TRANSACTION )
            {
                croak "CAR db handle already in transaction";
            }
            $car->car_air_export_status(
                $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_INPROGRESS);
            $car_saved = $car->save();

            # optional test
            croak "test rollback" if $self->test_transaction;

            my $car_db_committed = $car_db->commit();
            unless ($car_db_committed) {
                croak "CAR commit failed with $car_db_committed ",
                    $car_db->error;
            }

            # record stats
            if ( $tsrc_saved and $car_saved ) {
                $self->{completed}->{cars}++;
            }
            else {
                $self->{skipped}->{cars}++;
            }

        }
    ) or croak "CARD import failed: ", $db->error;

    # created tank_source? update car status (again)
    if ( $tsrc_saved and $car_saved ) {
        my $done = $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_YES;
        $car->car_air_export_status($done);
        $car->save();
    }

    return $tank;
}

sub _check_inquiry_for_contributor_questions {
    my $self    = shift;
    my $inquiry = shift or croak "inquiry required";
    my $ask     = shift or croak "ask required";

    return if $self->{_contrib_question_cache}->{ $inquiry->inq_id };

    my %cached_questions = ();
    my $added            = 0;
    my $inq_questions    = $inquiry->questions;

    if ( grep { $_->ques_type eq 'Z' } @$inq_questions ) {

        #warn "caching contributor questions";

        # already has some? cache them.
        for my $ques (@$inq_questions) {
            my $template = $ques->ques_template or next;
            my $ctb_field = $ques_types_rev{$template};
            $cached_questions{$ctb_field} = $ques;
        }

    }
    else {
        # which contributor fields were displayed on this FB ask?
        my $disp_ctb_fields = $ask->ask_disp_ctb_fields();
        for my $dcf (@$disp_ctb_fields) {

            # we don't care about invisible questions
            next unless $dcf->adcf_shown;

            my $displayed = $dcf->adcf_object;

            #dump( $dcf->as_tree( depth => 0 ) );
            #dump( $displayed->as_tree( depth => 0 ) );

            my $ques = AIR2::Question->new_from_template(
                $ques_types{ $displayed->dcf_name } );
            $ques->ques_dis_seq( $dcf->adcf_disp_seq );
            $ques->ques_inq_id( $inquiry->inq_id );
            $ques->save();

            $cached_questions{ $displayed->dcf_name } = $ques;

            $added++;
        }
    }

    $self->{_contrib_question_cache}->{ $inquiry->inq_id }
        = \%cached_questions;

    #warn "added $added contributor questions: " . dump \%cached_questions;

    return $added;
}

sub _map_response_to_source {
    my ( $self, $qt_external_code, $tank_source, $car, $card ) = @_;
    $self->debug and warn sprintf( "map %s in ask %s for '%s'\n",
        $qt_external_code, $car->car_ask_id,
        ( defined $card->card_value ? $card->card_value : '' ) );

    my $method = $fb_qt_externals{$qt_external_code}
        or croak "No method for $qt_external_code";
    my $to_call = '_add_' . $method;
    $self->$to_call( $tank_source, $card, $qt_external_code );
}

sub _add_vita {
    my ( $self, $tank_source, $card, $code ) = @_;

    my $val = $card->card_value;

    if ( !defined $val or !length $val ) {
        return;
    }

    my $vita = AIR2::TankVita->new( sv_type => 'E' );

    # TODO pair employer with occupation/title
    switch ($code) {
        case "occupation"   { $vita->sv_value($val) }
        case "employer"     { $vita->sv_basis($val) }
        case "prof_title"   { $vita->sv_value($val) }
        case "pol_office"   { $vita->sv_value($val) }
        case "organization" { $vita->sv_basis($val) }
        case "industry"     { $vita->sv_value($val) }
        else                { croak "unknown vita type $code" }
    }

    $tank_source->add_vitas($vita);
}

sub _add_fact {
    my ( $self, $tank_source, $card, $code ) = @_;

    my $tfact = AIR2::TankFact->new();
    my $val   = $card->card_value;

    if ( !defined $val or !length $val ) {
        return;
    }

    my $facts = $self->{_cache}->{facts};

    if ( $code eq "education" ) {
        if ( exists $facts->{'education_level'}->{$val} ) {
            $tfact->tf_fact_id( $facts->{'education_level'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'education_level'}->{$val} );
        }
        else {
            $tfact->tf_fact_id( $facts->{'education_level'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    elsif ( $code eq "pol_affiliation" ) {
        if ( exists $facts->{'political_affiliation'}->{$val} ) {
            $tfact->tf_fact_id(
                $facts->{'political_affiliation'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'political_affiliation'}->{$val} );
        }
        else {
            $tfact->tf_fact_id(
                $facts->{'political_affiliation'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    elsif ( $code eq "religion" ) {
        if ( exists $facts->{'religion'}->{$val} ) {
            $tfact->tf_fact_id( $facts->{'religion'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'religion'}->{$val} );
        }
        else {
            $tfact->tf_fact_id( $facts->{'religion'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    elsif ( $code eq "birth_year" ) {
        $tfact->tf_fact_id( $facts->{'birth_year'}->{fact_id} );
        $tfact->sf_src_value($val);
    }
    elsif ( $code eq "income" ) {

        # trac 1638 means we must normalize away the commas
        $val =~ s/,//g;
        if ( exists $facts->{'household_income'}->{$val} ) {
            $tfact->tf_fact_id( $facts->{'household_income'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'household_income'}->{$val} );
        }
        else {
            $tfact->tf_fact_id( $facts->{'household_income'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    elsif ( $code eq "race" ) {
        if ( exists $facts->{'ethnicity'}->{$val} ) {
            $tfact->tf_fact_id( $facts->{'ethnicity'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'ethnicity'}->{$val} );
        }
        else {
            $tfact->tf_fact_id( $facts->{'ethnicity'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    elsif ( $code eq "gender" ) {
        if ( exists $facts->{'gender'}->{$val} ) {
            $tfact->tf_fact_id( $facts->{'gender'}->{fact_id} );
            $tfact->sf_src_fv_id( $facts->{'gender'}->{$val} );
        }
        else {
            $tfact->tf_fact_id( $facts->{'gender'}->{fact_id} );
            $tfact->sf_src_value($val);
        }
    }
    else {
        croak "unknown fact code $code";
    }

    if ( $tfact->tf_fact_id ) {
        $tfact->sf_fv_id(
            $self->_find_translated_fact( $tfact->tf_fact_id, $val ) );
        $tank_source->add_facts($tfact);
    }

}

sub _find_translated_fact {
    my ( $self, $fact_id, $value ) = @_;
    return AIR2::TranslationMap->find_translation( $fact_id, $value );
}

sub _add_pref {
    my ( $self, $tank_source, $card, $code ) = @_;
    if ( $code eq 'pref_lang' ) {
        my $lang = $card->card_value;
        if ( exists $LOCALE_MAP{$lang} ) {
            $lang = $LOCALE_MAP{$lang};
        }
        my $pref_type
            = AIR2::PreferenceType->new( pt_id => $PREFERRED_LANG_PT_ID )
            ->load;

        #warn "loaded pref_type=" . $pref_type->pt_name;
        for my $ptv ( @{ $pref_type->preference_type_values } ) {

            #warn "ptv=" . $ptv->ptv_value;
            if ($lang
                and (  $ptv->ptv_value eq $lang
                    or $ptv->ptv_value eq "${lang}_US" )
                )
            {
                my $tank_pref = AIR2::TankPreference->new(
                    sp_status => 'A',
                    sp_ptv_id => $ptv->ptv_id,
                );

                #warn "add_preference for source=" . $ptv->ptv_id;
                $tank_source->add_preferences($tank_pref);
            }
        }
    }
}

sub _add_media {
    my ( $self, $tank_source, $card, $code ) = @_;

    # TODO TankMediaAsset

}

sub _get_question {
    my ( $self, $ques_uuid ) = @_;
    if ( !exists $self->{_cache}->{questions}->{$ques_uuid} ) {
        my $q = AIR2::Question->new( ques_uuid => $ques_uuid );
        $q->load_speculative;
        $self->{_cache}->{questions}->{$ques_uuid} = $q;
    }
    return $self->{_cache}->{questions}->{$ques_uuid};
}

sub _get_tank_lock {
    my ( $self, $orgs, $prj, $inq ) = @_;
    my $inq_uuid = AIR2::Utils->str_clean( $inq->inq_uuid );
    return $self->{_tanks}->{$inq_uuid}
        if exists $self->{_tanks}->{$inq_uuid};

    # check for existing tank
    my $tank = pop @{ AIR2::Tank->fetch_all(
            query => [ tank_type => 'F', tank_xuuid => $inq_uuid ]
        )
    };

    # MUST have a lock on the tank
    if ( $tank && !$tank->get_lock() ) {
        $self->{_tanks}->{$inq_uuid} = 0;
        return 0;    # no lock! skip it!
    }
    elsif ( !$tank ) {
        $tank = AIR2::Tank->new(
            tank_user_id => $self->user->user_id,
            tank_name    => ( $inq->inq_ext_title || $inq->inq_title ),
            tank_type     => 'F',                    # Formbuilder
            tank_status   => 'L',                    # create w/lock
            tank_cre_user => $self->user->user_id,
            tank_xuuid    => $inq_uuid,
        );
        $tank->save();
    }

    # update (overwrite) tank meta
    $tank->tank_meta(
        encode_json(
            {   project => $prj->prj_uuid,
                orgs    => join( ',', map { $_->org_uuid } @$orgs ),
                inquiry => $inq_uuid,
            }
        )
    );

    # update (overwrite) tank_orgsu
    my %keep_orgs;
    for my $to ( @{ $tank->orgs } ) {
        $keep_orgs{ $to->to_org_id } = 0;
    }
    for my $org ( @{$orgs} ) {
        unless ( defined $keep_orgs{ $org->org_id } ) {
            my $to = AIR2::TankOrg->new( to_org_id => $org->org_id );
            $tank->add_orgs($to);
        }
        $keep_orgs{ $org->org_id } = 1;
    }
    for my $torg ( @{ $tank->orgs } ) {
        $torg->delete() unless ( $keep_orgs{ $torg->to_org_id } );
    }

    # update (overwrite) tank_activity
    my $has_prj_actv = 0;
    for my $tact ( @{ $tank->activities } ) {
        if ( $tact->tact_prj_id == $prj->prj_id ) {
            $has_prj_actv = 1;
        }
        else {
            $tact->delete();
        }
    }
    unless ($has_prj_actv) {
        my $tact = AIR2::TankActivity->new(
            tact_prj_id   => $prj->prj_id,
            tact_actm_id  => $QUERY_RESPONSE_ACTM_ID,
            tact_dtim     => undef,                       #set per tank_source
            tact_xid      => $inq->inq_id,
            tact_ref_type => 'I',
            tact_desc     => '{SRC} responded to {XID}',
        );
        $tank->add_activities($tact);
    }

    $tank->save();
    $self->{_tanks}->{$inq_uuid} = $tank;
    return $tank;
}

sub get_tanks {
    my $self = shift;
    my @tanks;
    for my $key ( keys %{ $self->{_tanks} } ) {
        my $tank = $self->{_tanks}->{$key};
        push( @tanks, $tank ) if $tank;
    }
    return \@tanks;
}

# release any locks we hold on tanks
sub release_tank_locks {
    my $self = shift;
    for my $tank ( @{ $self->get_tanks() } ) {
        $tank->update_status();
    }
}

sub import_ask {
    my $self = shift;
    my $fb_ask = shift or croak "FB ask object required";

    # find corresponding Inquiry
    my $air2_inq = $self->find_air2_inquiry( $fb_ask->ask_code );

    # unless we force overwrite, ignore if already exists
    if ( !$self->force ) {
        if (    $air2_inq->inq_id
            and $air2_inq->inq_upd_dtim > $fb_ask->ask_last_modify_time )
        {
            $self->debug
                and warn sprintf
                "import_ask %s ignored because already in AIR and inq_upd_dtim %s newer than ask_last_modify_time %s",
                $fb_ask->ask_code, $air2_inq->inq_upd_dtim,
                $fb_ask->ask_last_modify_time;
            return 0;
        }
    }

    $self->debug and warn sprintf( "Import FB %s to AIR2 %s\n",
        $fb_ask->ask_code, ( $air2_inq->inq_id || '(new)' ) );

    # which project is it related to?
    my $fb_project = $fb_ask->project;
    my $air2_project
        = $self->find_air2_project( $fb_ask->ask_air2_project
            || $fb_project->proj_air2_project
            || $fb_project->proj_code );

    # if we do not already have a parent project, import it.
    if ( !$air2_project->prj_id ) {
        $self->debug
            and warn "No parent AIR2 project for "
            . $fb_project->proj_name . "\n";
        $self->import_project($fb_project);
        $air2_project = $self->find_air2_project( $fb_project->proj_code )
            or croak "Unable to find parent Project for ask "
            . $fb_ask->ask_id;
    }
    if ( !$air2_project->prj_id ) {
        croak "Unable to find parent Project in AIR2 for ask "
            . $fb_ask->ask_id;
    }

    my $air2_orgs
        = defined $fb_ask->ask_air2_org
        ? [ $self->_get_air2_org( $fb_ask->ask_air2_org ) ]
        : $air2_project->organizations;

    # based on AIR1Conv

    # cleanup some data
    my $title = AIR2::Utils->str_clean( $fb_ask->ask_title );
    my $ext   = AIR2::Utils->str_clean( $fb_ask->ask_external_title );
    my $desc  = AIR2::Utils->str_clean( $fb_ask->ask_rss_intro );
    $desc = substr( $desc, 0, 255 ) if $desc;
    my $exp  = AIR2::Utils->str_clean( $fb_ask->ask_expiry_msg );
    my $from = $fb_ask->ask_effective_from
        if $fb_ask->ask_effective_from;
    my $to = $fb_ask->ask_expiry_dtim
        if $fb_ask->ask_expiry_dtim;

    my $lang = $EN_US_LOCALE;
    $lang = $ES_US_LOCALE
        if ( $fb_ask->ask_lang && $fb_ask->ask_lang eq 'es' );

    my $ask_status;
    if ( $fb_ask->ask_status eq 'P' ) {
        $ask_status = 'A';
    }
    elsif ( $fb_ask->ask_status eq 'D' ) {
        $ask_status = 'D';
    }

# Don't import 'published, do not import' queries; everything else is 'inactive.'
    elsif ( $fb_ask->ask_status ne 'A' ) {
        $ask_status = 'F';
    }

    # public Inquiries are a new concept in AIR2
    # but we infer that any Ask with the standard Permission
    # question should be flagged as public.
    my $inq_is_public = 0;
    for my $askq ( @{ $fb_ask->ask_questions } ) {
        if ( $self->debug ) { warn $askq->askq_text }
        if (   $askq->askq_qt_id
            && $askq->askq_qt_id == $QUES_PERMISSION_TO_SHARE_ID )
        {
            $inq_is_public = 1;
            last;
        }
    }

    my %inq = (
        inq_uuid          => $fb_ask->ask_code,
        inq_title         => $title,
        inq_ext_title     => $ext,
        inq_publish_dtim  => $from,
        inq_deadline_dtim => undef,
        inq_desc          => $desc,
        inq_public_flag   => $inq_is_public,

        # formbuilder
        inq_type => 'F',

        inq_stale_flag => 0,

        # TODO this is currently ignored/un-used in AIR2
        inq_xid         => $fb_ask->ask_id,
        inq_loc_id      => $lang,
        inq_status      => $ask_status,
        inq_expire_msg  => $exp,
        inq_expire_dtim => $to,
        inq_cre_user    => $self->_get_user_id( $fb_ask->ask_cre_user ),
        inq_upd_user    => $self->_get_user_id( $fb_ask->ask_upd_user ),
        inq_cre_dtim    => $fb_ask->ask_cre_dtim,
        inq_upd_dtim    => $fb_ask->ask_last_modify_time,
        inq_rss_intro   => AIR2::Utils->str_clean( $fb_ask->ask_rss_intro ),
        inq_rss_status  => $fb_ask->ask_rss_flag,
        inq_intro_para  => AIR2::Utils->str_clean( $fb_ask->ask_intro_para ),
        inq_ending_para => AIR2::Utils->str_clean( $fb_ask->ask_ending_para ),
        inq_confirm_msg => AIR2::Utils->str_clean( $fb_ask->ask_thanks_msg ),
        inq_url         => $fb_ask->ask_url,
    );
    for my $col ( keys %inq ) {
        $air2_inq->$col( $inq{$col} );
    }

    # InqOrg record(s) always overwrite
    $air2_inq->organizations($air2_orgs);

    # ProjectInquiry record(s) optionally add
    if ( !grep { $_->prj_id == $air2_project->prj_id }
        @{ $air2_inq->projects || [] } )
    {
        $air2_inq->projects($air2_project);
        $self->debug
            and warn "Assigned project "
            . $air2_project->prj_name
            . " to inquiry "
            . $air2_inq->inq_uuid;
    }

    my $prj_activity = AIR2::ProjectActivity->new(
        pa_prj_id  => $air2_project->prj_id,
        pa_actm_id => $PROJECT_ADDED_QUERY_ACTM_ID,
        pa_desc    => '{USER} added {XID} to project {PROJ}',
        pa_dtim    => time(),
        pa_notes   => 'Assigned Formbuilder '
            . $fb_ask->ask_code
            . ' to AIR project',
        pa_ref_type => 'I',
    );

    if ( $air2_inq->save() ) {
        $self->_check_inquiry_for_contributor_questions( $air2_inq, $fb_ask );
        $prj_activity->pa_xid( $air2_inq->inq_id );
        $prj_activity->save();
        $self->{completed}->{asks}++;
    }
    else {
        $self->{skipped}->{asks}++;
    }
    return $air2_inq;
}

sub import_project {
    my $self = shift;
    my $fb_project = shift or croak "FB project object required";

    #warn sprintf("import Project %s\n", $fb_project->proj_last_modify_time);

    # find the corresponding AIR2 project
    my $air2_proj = $self->find_air2_project( $fb_project->proj_air2_project
            || $fb_project->proj_code );

    # unless we force overwrite, ignore if already exists
    # TODO merge differences based on upd_dtim
    if ( !$self->force and $air2_proj->prj_id ) {
        return 0;
    }

    $self->debug
        and warn sprintf( "Import Project FB %s to AIR2 %s\n",
        $fb_project->proj_code, $air2_proj->prj_name );

    # lifted from AIR1Conv::proj_to_prj()
    my $name = AIR2::Utils->str_clean( $fb_project->proj_code );
    my $disp = AIR2::Utils->str_clean( $fb_project->proj_name );
    my $uuid = AIR2::Utils->str_to_uuid($name);

    # status match-up
    my $status = $fb_project->proj_status;
    $status = 'A' if $status eq 'P';

    # all values overwrite, unless we check.
    $air2_proj->prj_uuid($uuid);
    $air2_proj->prj_name($name);
    $air2_proj->prj_display_name($disp);
    $air2_proj->prj_desc( AIR2::Utils->str_clean( $fb_project->proj_desc ) );
    $air2_proj->prj_status($status);
    $air2_proj->prj_type('I')   unless defined $air2_proj->prj_type();
    $air2_proj->prj_cre_user(1) unless defined $air2_proj->prj_cre_user;
    $air2_proj->prj_upd_user(1) unless defined $air2_proj->prj_upd_user;
    $air2_proj->prj_cre_dtim( $fb_project->proj_cre_dtim );
    $air2_proj->prj_upd_dtim( $fb_project->proj_last_modify_time );
    $air2_proj->add_activities(
        [   {   pa_dtim    => time(),
                pa_desc    => "Imported from Formbuilder",
                pa_actm_id => $MEMBERS_CHANGED_ACTM_ID,
            },
        ]
    );

    if ( $air2_proj->save() ) {
        $self->{completed}->{projects}++;
    }
    else {
        $self->{skipped}->{projects}++;
    }

    # cache it for any child asks
    $self->{_cache}->{projects}->{ $air2_proj->prj_uuid } = $air2_proj;

    return $air2_proj;
}

sub report {
    my $self = shift;
    my @r;
    for my $c (qw( completed skipped )) {
        for my $t ( sort keys %{ $self->{$c} } ) {
            push @r, "$self->{$c}->{$t} $c $t";
        }
    }
    push @r, scalar( @{ $self->{errors} } ) . " errors";
    return join( "\n", @r );
}

1;
