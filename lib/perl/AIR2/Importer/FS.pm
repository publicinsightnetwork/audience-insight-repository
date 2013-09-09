package AIR2::Importer::FS;
###########################################################################
#
#   Copyright 2013 American Public Media Group
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
use utf8;    # we have literal utf-8 strings in code
use Scalar::Util qw( blessed );

=pod

=head1 NAME

AIR2::Importer::FS - filesystem importer

=head1 SYNOPSIS

 use AIR2::Importer::FS;
 
 my $importer = AIR2::Importer::FS->new(
    reader  => AIR2::Reader::FS->new( 
        root => AIR2::Config->get_submission_pen(),
    ),
    debug   => 1,
    atomic      => 1,  # default
    max_errors  => 1,  # conservative
 );
 $importer->run();
 print $importer->report;
 printf("%d errors, %d completed, %d skipped\n", 
    $importer->errored, $importer->completed, $importer->skipped );
 
=head1 DESCRIPTION

Crawl filesystem and import submissions from .json files.

=cut

# force mysql master connection
BEGIN {
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
use AIR2::JobQueue;
use JSON;
use Switch;
use File::Copy ();

__PACKAGE__->mk_accessors(
    qw(
        no_import
        strict
        email_notify
        default_org
        test_transaction
        force
        send_confirm_email
        )
);

my %fact_methods = (

    # template name    # method
    occupation     => 'vita',
    education      => 'fact',
    employer       => 'vita',
    prof_title     => 'vita',
    pol_office     => 'vita',
    organization   => 'vita',
    gender         => 'fact',
    income         => 'fact',
    political      => 'fact',
    religion       => 'fact',
    ethnicity      => 'fact',
    industry       => 'vita',
    birth          => 'fact',
    web_presence   => 'fact',
    photo_location => 'media',
    preflang       => 'pref',
);

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
        $self->{debug} = $ENV{AIR2_DEBUG} || 0;
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

sub _get_org {
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

sub find_project {
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

sub find_inquiry {
    my $self     = shift;
    my $inq_uuid = shift or croak "inq_uuid required";
    my $inq      = AIR2::Inquiry->new( inq_uuid => $inq_uuid );
    $inq->load_speculative;
    return $inq;
}

# override to make reporting more granular, delegating it
# to do_import()
sub run {
    my $self     = shift;
    my $reader   = $self->reader;
    my $max_errs = $self->max_errors;
    my $count    = 0;
    $self->start_transaction() if $self->atomic;
    while ( my $file = $reader->next ) {
        next if -d $file;
        $self->debug and warn "read: $file\n";
        $count++ if $self->do_import($file);
    }
    $self->release_tank_locks();
    $self->end_transaction() if $self->atomic;
    return $count;
}

sub get_inq_json {
    my $self = shift;
    my $inq_uuid = shift or croak "inq_uuid required";
    return $self->{_inq}->{$inq_uuid} if exists $self->{_inq}->{$inq_uuid};
    my $path = AIR2::Config->get_app_root->subdir('public_html/querys')
        ->file( $inq_uuid . '.json' );
    if ( !-s $path ) {
        croak "No .json file for $inq_uuid at $path";
    }
    my $buf  = $path->slurp;
    my $json = decode_json($buf);
    $self->{_inq}->{$inq_uuid} = $json;
    return $json;
}

sub do_import {
    my $self  = shift;
    my $thing = shift;
    if ( !-f $thing ) {
        croak "$thing is not a file";
    }

    # skip unless incomplete with expected extension
    if ( $thing !~ m/\.json$/ ) {
        return;
    }

    if ( !blessed($thing) ) {
        $thing = Path::Class::File->new($thing);
    }

    my $lockable = Path::Class::File::Lockable->new("$thing");

    $self->debug and warn "thing=$thing lockable=$lockable\n";

    if ( $lockable->locked() ) {
        my $lock_time = $lockable->lock_time;

        # log the error only periodically to save email flood.
        # we round to the nearest 1 minute window.
        my $locked_for_seconds = ( time() - $lock_time ) % 1800;
        if ( $locked_for_seconds >= 0 and $locked_for_seconds <= 60 ) {
            my $err = "$lockable is already locked";
            carp $err;
            $self->add_error($err);
        }
        return;
    }

    $lockable->lock();
    my $buf = $lockable->slurp;

    $self->debug and warn "buf=$buf";

    # read the json and prep some metadata

    my $srs = decode_json($buf);

    #dump $srs;
    my $srs_mtime = $thing->stat->mtime;
    $srs->{meta}->{mtime} ||= $srs_mtime;
    my $err_file = $thing . '.errs';
    if ( !$srs->{meta}->{query} ) {
        my $inq_uuid = $thing->parent->basename;
        $srs->{meta}->{query} = $inq_uuid;
    }
    if ( !$srs->{meta}->{uuid} ) {
        my $srs_uuid = $thing->basename;
        $srs_uuid =~ s/\.json//;
        $srs->{meta}->{uuid} = $srs_uuid;
    }

    my $inq_json = $self->get_inq_json( $srs->{meta}->{query} );

    # stuff it in the tank
    my $tank = $self->import_srs(
        srs      => $srs,
        inq_json => $inq_json,
        srs_uuid => $srs->{meta}->{uuid},
        err_file => $err_file,
    );

    if ( !$tank or $tank eq '-1' ) {

        # skipped for some reason, unlock and skip
        $lockable->unlock();

        return $tank;

    }

    # unlock and archive
    $lockable->unlock();
    File::Copy::move( "$thing", "$thing.complete" );

    if ( $self->send_confirm_email ) {

        # TODO we get no activity logging here because there is no
        # source id known yet. either scrape the job_queue table
        # via another script or refactor this entirely to fire
        # the confirmation after discriminator has run.

        AIR2::JobQueue->add_job(
            "PERL AIR2_ROOT/bin/send-submission-confirmation-email $thing.complete"
        );
    }

    return $tank;
}

#
# * create tank record for each distinct affected org (based on ask_air2_org or project)
# * put source in the tank
# * put srs in the tank
# * put sr(s) in the tank
#

sub import_srs {
    my $self = shift;
    my %args = @_;

    $self->debug and warn dump \%args;

    my $srs      = delete $args{srs}      or croak "srs required";
    my $inq_json = delete $args{inq_json} or croak "inq_json required";
    my $srs_uuid = delete $args{srs_uuid} or croak "srs_uuid required";
    my $err_file = delete $args{err_file} or croak "err_file required";

    my $inquiry = $self->find_inquiry( $srs->{meta}->{query} );
    my $project = $inquiry->find_a_project();
    my @orgs    = @{ $inquiry->organizations() || [] };

    # normalize submission
    for my $ques_uuid ( keys %$srs ) {
        next if $ques_uuid eq 'meta';
        my $resp = $srs->{$ques_uuid};
        if ( defined $resp
            and ref $resp eq 'ARRAY' )
        {
            $srs->{$ques_uuid}
                = join( '|', grep { defined and length } @$resp );
        }
        if ( defined $resp and ref $resp eq 'HASH' ) {

            # file upload
            # NOTE this will re-run if for any reason
            # the .json file is re-processed.
            # That seems legitimate since it's just going
            # to overwrite a file with a copy of itself.

            # copy file to ultimate destination
            my $upload_dir = AIR2::Config->get_upload_base_dir();
            my $org_name = $orgs[0] ? $orgs[0]->org_name : $project->prj_name;
            my $dest_path = sprintf( '%s/%s/%s.%s',
                $org_name, $inquiry->inq_uuid,
                $srs_uuid, $resp->{file_ext} );

            # create dir if it doesn't exist
            $upload_dir->subdir($org_name)->subdir( $inquiry->inq_uuid )
                ->mkpath( $self->debug, 0775 );

            if ( system("cp $resp->{tmp_name} $upload_dir/$dest_path") ) {
                $self->add_error(
                    "Failed to copy $resp->{tmp_name} to $upload_dir/$dest_path: $!"
                );
            }

            # update response value to destination path
            $self->debug and warn "set $ques_uuid == $dest_path";

            $srs->{$ques_uuid} = $dest_path;
        }
    }

    # wrap this entire set in a single transaction, on the AIR2 side.
    my $db = AIR2::DBManager->new_or_cached()->get_write_handle();
    my $tank;
    my $tsrc_saved = 0;
    my $srs_saved  = 0;
    $db->do_transaction(
        sub {

            # sanity check: does this response have any actual content?
            my $has_content = 0;
            for my $ques_uuid ( keys %$srs ) {
                next if $ques_uuid eq 'meta';
                my $resp = $srs->{$ques_uuid};
                if ( defined $resp
                    and length $resp )
                {
                    $has_content = 1;
                    last;
                }
            }

            my %src_fields;
            my %resp_fields;
            my %fact_fields;
            my $public_question;
            for my $ques ( @{ $inq_json->{questions} } ) {
                my $type = $ques->{ques_type};
                if (   lc($type) eq 'z'
                    or lc($type) eq 's'
                    or lc($type) eq 'y' )
                {
                    $src_fields{ $ques->{ques_uuid} } = $ques;
                }
                elsif ( lc($type) eq 'p' ) {
                    $public_question = $ques;
                }
                elsif ( $ques->{ques_pmap_id} ) {
                    $fact_fields{ $ques->{ques_uuid} } = $ques;
                }
                else {
                    $resp_fields{ $ques->{ques_uuid} } = $ques;
                }
            }
            my $has_src_content = 0;
            for my $src_ques_uuid ( keys %src_fields ) {
                my $resp = $srs->{$src_ques_uuid};
                if ( defined $resp
                    and length $resp )
                {
                    $has_src_content++;
                }
            }

            #warn "1: " . dump $srs;

            # must be missing both to be skipped
            if ( !$has_content && !$has_src_content ) {
                $self->{skipped}->{srs}++;
                $tank = -1;
                return;
            }

            #warn dump $inq_json;

            # must have at least one related project
            if ( !$project ) {
                $self->add_error(
                    "No project for inquiry " . $inquiry->inq_uuid );
                $self->{skipped}->{srs}++;
                $tank = -1;
                return;
            }

            # get the tank and lock it ... if we CANNOT lock the tank, we MUST
            # skip this submission for now, without changing status
            $tank = $self->_get_tank_lock( \@orgs, $project, $inquiry );
            unless ($tank) {
                $self->add_error( "Failed to get tank lock for inquiry "
                        . $inq_json->{query}->{inq_uuid} );
                $self->{skipped}->{srs}++;
                $tank = -1;
                return;
            }

            my %contributor = ();
            for my $ques_uuid ( keys %src_fields ) {
                my $ques     = $src_fields{$ques_uuid};
                my $template = $ques->{ques_template}
                    || $ques->{ques_resp_type};
                my $response = $srs->{$ques_uuid};
                if ( !defined $response or !length $response ) {
                    next;
                }
                $contributor{$template} = $response;
            }

            #warn dump \%contributor;
            #warn "2: " . dump $srs;

            if ( !$contributor{email} ) {

                # in theory this should not happen because
                # email is always required by querymaker
                # but perhaps some Formbuilder query
                # neglected to require an email?

                $self->add_error("No email in submission $srs_uuid");

                # add one of our own
                $contributor{email}
                    = AIR2::Utils->random_str() . '@nosuchemail.org';
            }

            my $phone
                = AIR2::Utils::parse_phone_number( $contributor{ctb_phone}
                    || '' );
            my $zip = AIR2::Utils->str_clean( $contributor{zip} || '' );
            $zip =~ s/\ +//g;
            my $tank_source = AIR2::TankSource->new(
                src_first_name =>
                    AIR2::Utils->str_clean( $contributor{firstname} ),
                src_last_name =>
                    AIR2::Utils->str_clean( $contributor{lastname} ),
                sem_email =>
                    AIR2::Utils->str_clean( lc( $contributor{email} ) ),
                smadd_line_1 =>
                    AIR2::Utils->str_clean( $contributor{street} ),
                smadd_city  => AIR2::Utils->str_clean( $contributor{city} ),
                smadd_state => AIR2::Utils->str_clean( $contributor{state} ),
                smadd_cntry =>
                    AIR2::Utils->str_clean( $contributor{country} ),
                smadd_zip  => $zip,
                sph_number => substr( ( $phone->{number} || '' ), 0, 16 ),
                sph_ext    => $phone->{ext},
            );

            $tank->add_sources($tank_source);
            $tank->save();  # so we can get tsrc_id for its children responses

            #
            # create TankResponseSet

            my $tank_srs = AIR2::TankResponseSet->new(
                trs_tsrc_id => $tank_source->tsrc_id,
                srs_inq_id  => $inquiry->inq_id,
                srs_date    => $srs->{meta}->{mtime},
                srs_uri     => $srs->{meta}->{referer}
                ? substr( $srs->{meta}->{referer}, 0, 65535 )
                : undef,
                srs_type => 'Q',

                # Publishing API approval done after import
                srs_public_flag => 0,

                # delete_flag, translated_flag and export_flag
                # are currently un-used.
                srs_delete_flag      => 0,
                srs_translated_flag  => 0,
                srs_export_flag      => 0,
                srs_fb_approved_flag => undef,                  # n/a
                srs_conf_level       => 'A',
                srs_uuid             => $srs->{meta}->{uuid},
            );

            # create SrcResponse records for each question
            my @src_responses;

            # we set default sr_public_flag value based on
            # presence and answer to the permission question.

            my $public_permission_given = 0;
            if ($public_question) {
                my $answer_to_permission
                    = $srs->{ $public_question->{ques_uuid} };
                if ( defined $answer_to_permission
                    and AIR2::Utils::looks_like_yes($answer_to_permission) )
                {
                    $public_permission_given = 1;
                }

                my $question
                    = $self->_get_question( $public_question->{ques_uuid},
                    $inq_json );
                if ( !$question or !$question->ques_id ) {
                    croak sprintf(
                        "In submission %s failed to find question %s for inquiry %s",
                        $tank_srs->srs_uuid, $public_question->{ques_uuid},
                        $inquiry->inq_uuid
                    );
                }

                push @src_responses,
                    AIR2::TankResponse->new(
                    tr_tsrc_id          => $tank_source->tsrc_id,
                    sr_ques_id          => $question->ques_id,
                    sr_public_flag      => 0,
                    sr_media_asset_flag => 0,
                    sr_orig_value       => $answer_to_permission,
                    sr_mod_value        => undef,
                    sr_status           => 'A',
                    sr_uuid             => AIR2::Utils->str_to_uuid(
                              'sr-'
                            . $tank_srs->srs_uuid
                            . $public_question->{ques_uuid}
                    ),
                    );

            }

        RESP:
            for my $ques_uuid ( ( keys %resp_fields, keys %src_fields ) ) {
                my $response = $srs->{$ques_uuid};

                my $sr_orig_value
                    = AIR2::Utils->str_clean( $response, 65535 );
                my $question = $self->_get_question( $ques_uuid, $inq_json );
                if ( !$question or !$question->ques_id ) {
                    croak
                        sprintf(
                        "In submission %s failed to find question %s for inquiry %s",
                        $tank_srs->srs_uuid, $ques_uuid, $inquiry->inq_uuid );
                }
                my $public_flag
                    = $question->ques_public_flag
                    ? $public_permission_given
                    : 0;

                # contributor fields are never flagged as public by default
                $public_flag = 0 if exists $src_fields{$ques_uuid};

                my $media_flag = 0;
                if ( $question->ques_resp_type eq 'F' ) {
                    $media_flag = 1;
                }
                my $tr = AIR2::TankResponse->new(
                    tr_tsrc_id          => $tank_source->tsrc_id,
                    sr_ques_id          => $question->ques_id,
                    sr_public_flag      => $public_flag,
                    sr_media_asset_flag => $media_flag,
                    sr_orig_value       => $sr_orig_value,
                    sr_mod_value        => undef,
                    sr_status           => 'A',
                    sr_uuid             => AIR2::Utils->str_to_uuid(
                        'sr-' . $tank_srs->srs_uuid . $ques_uuid
                    ),
                );
                push @src_responses, $tr;
            }

            #dump \%fact_fields;

        FACT: for my $ques_uuid ( keys %fact_fields ) {
                my $response = $srs->{$ques_uuid};

                my $sr_orig_value
                    = AIR2::Utils->str_clean( $response, 65535 );
                my $question = $self->_get_question( $ques_uuid, $inq_json );
                if ( !$question or !$question->ques_id ) {
                    croak
                        sprintf(
                        "In submission %s failed to find question %s for inquiry %s",
                        $tank_srs->srs_uuid, $ques_uuid, $inquiry->inq_uuid );
                }
                my $media_flag = 0;
                if ( $question->ques_resp_type eq 'F' ) {
                    $media_flag = 1;
                }
                my $tr = AIR2::TankResponse->new(
                    tr_tsrc_id     => $tank_source->tsrc_id,
                    sr_ques_id     => $question->ques_id,
                    sr_public_flag => (
                          $question->ques_public_flag
                        ? $public_permission_given
                        : 0
                    ),
                    sr_media_asset_flag => $media_flag,
                    sr_orig_value       => $sr_orig_value,
                    sr_mod_value        => undef,
                    sr_status           => 'A',
                    sr_uuid             => AIR2::Utils->str_to_uuid(
                        'sr-' . $tank_srs->srs_uuid . $ques_uuid
                    ),
                );
                push @src_responses, $tr;

                if ( !defined $response or !length $response ) {
                    next FACT;
                }

                if ( $question->ques_template ) {
                    $self->_map_response_to_source( $question->ques_template,
                        $tank_source, $sr_orig_value );
                }

            }

            $tank_srs->add_responses( \@src_responses );

            $tank_source->add_response_sets( [$tank_srs] );

            # must save explicitly because $tank does not cascade
            $tsrc_saved = $tank_source->save();

            # optional test
            croak "test rollback" if $self->test_transaction;

            # record stats
            if ($tsrc_saved) {
                $self->{completed}->{srs}++;
            }
            else {
                $self->{skipped}->{srs}++;
            }

        }
    ) or croak "SRS import failed: ", $db->error;

    return $tank;
}

sub _map_response_to_source {
    my ( $self, $template, $tank_source, $sr_orig_value ) = @_;
    $self->debug
        and warn sprintf( "map %s => '%s'\n", $template, $sr_orig_value );

    my $method = $fact_methods{$template}
        or croak "No method for $template";
    my $to_call = '_add_' . $method;
    $self->$to_call( $tank_source, $sr_orig_value, $template );
}

sub _add_vita {
    my ( $self, $tank_source, $val, $code ) = @_;

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
    my ( $self, $tank_source, $val, $code ) = @_;

    my $tfact = AIR2::TankFact->new();

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
    elsif ( $code eq "political" ) {
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
    elsif ( $code eq "birth" ) {
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
    elsif ( $code eq "ethnicity" ) {
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
    my ( $self, $tank_source, $val, $code ) = @_;
    if ( $code eq 'preflang' ) {
        if ( exists $LOCALE_MAP{$val} ) {
            $val = $LOCALE_MAP{$val};
        }
        my $pref_type
            = AIR2::PreferenceType->new( pt_id => $PREFERRED_LANG_PT_ID )
            ->load;

        #warn "loaded pref_type=" . $pref_type->pt_name;
        for my $ptv ( @{ $pref_type->preference_type_values } ) {

            #warn "ptv=" . $ptv->ptv_value;
            if ($val
                and (  $ptv->ptv_value eq $val
                    or $ptv->ptv_value eq "${val}_US" )
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
    my ( $self, $tank_source, $val, $code ) = @_;

    # TODO TankMediaAsset

}

sub _get_question {
    my ( $self, $ques_uuid, $inq_json ) = @_;
    if ( !exists $self->{_cache}->{questions}->{$ques_uuid} ) {
        my $q = AIR2::Question->new( ques_uuid => $ques_uuid );
        $q->load_speculative;
        if ( !$q->ques_id ) {

            # edge case
            # if inq_json has question, add it to db with
            # ques_status = 'X' and log error
            # but do not croak.
            # this is probably a race condition between
            # publish times and submission times.
            if ($inq_json) {
                my $inq
                    = $self->find_inquiry( $inq_json->{query}->{inq_uuid} );
                if ( $inq and $inq->inq_id ) {
                    for my $ques ( @{ $inq_json->{questions} } ) {
                        if ( $ques->{ques_uuid} eq $ques_uuid ) {
                            my $new_question = AIR2::Question->new(%$ques);
                            $new_question->ques_inq_id( $inq->inq_id );
                            $new_question->ques_status('X');
                            $new_question->save();
                            $q = $new_question;
                            last;
                        }
                    }
                }
            }
        }
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
            query => [ tank_type => 'Q', tank_xuuid => $inq_uuid ]
        )
    };

    # MUST have a lock on the tank
    if ( $tank && !$tank->get_lock() ) {
        $self->{_tanks}->{$inq_uuid} = 0;
        $self->add_error( "Can't get lock for Tank for $inq_uuid: "
                . dump( $tank->as_tree( depth => 0 ) ) );
        return 0;    # no lock! skip it!
    }
    elsif ( !$tank ) {
        $tank = AIR2::Tank->new(
            tank_user_id => $self->user->user_id,
            tank_name    => ( $inq->inq_ext_title || $inq->inq_title ),
            tank_type     => 'Q',                    # Querybuilder
            tank_status   => 'L',                    # create w/lock
            tank_cre_user => $self->user->user_id,
            tank_xuuid    => $inq_uuid,
        );

        #warn dump $tank->as_tree( depth => 0 );
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

    # update (overwrite) tank_orgs
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
            tact_dtim     => undef,                      # set per tank_source
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

sub report {
    my $self = shift;
    my @r;
    for my $c (qw( completed skipped )) {
        for my $t ( sort keys %{ $self->{$c} } ) {
            push @r, "$self->{$c}->{$t} $c $t";
        }
    }
    push @r, $self->has_errors() . " errors";
    push @r, $self->has_warnings() . " warnings";
    push @r, "Error: $_\n" for @{ $self->{errors} };
    push @r, "Warning: $_\n" for @{ $self->{warnings} };
    return join( "\n", @r );
}

1;
