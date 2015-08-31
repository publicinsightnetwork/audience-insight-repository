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

package AIR2::Mailchimp;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use List::MoreUtils qw( natatime );
use Date::Parse;
use DateTime;
use Scalar::Util qw( blessed );
use JSON;
use AIR2::Config;
use AIR2::Organization;
use WWW::Mailchimp;
use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(qw( ));

__PACKAGE__->mk_ro_accessors(
    qw(
        org
        api_key
        api
        list_id
        mailing_list
        grouping_id
        )
);

=head1 NAME

AIR2::Mailchimp - utils for interacting with the Mailchimp API

=head1 SYNOPSIS

 use AIR2::Mailchimp;

 my $chimp = AIR2::Mailchimp->new(
    org => AIR2::Organization->new( org_id => $org_id )->load,
 );

 $result = $chimp->push_list( email => 'test@nosuchemail.org' );

=head1 METHODS

=cut

# some settings
my $PAGE_SIZE = 1000;
my %ERRORS    = (
    List_InvalidOption        => 211,
    List_InvalidUnsubMember   => 212,
    List_InvalidBounceMember  => 213,
    List_AlreadySubscribed    => 214,
    List_NotSubscribed        => 215,
    List_InvalidImport        => 220,
    Email_AlreadySubscribed   => 230,
    Email_AlreadyUnsubscribed => 231,
    Email_NotExists           => 232,
    Email_NotSubscribed       => 233,
    Invalid_Email             => 502,
    RoleBasedOrInvalid_Email  => -99,
);
my %SOE_STATUS_MAP = (
    subscribed       => 'A',
    unsubscribed     => 'U',
    cleaned          => 'B',
    not_in_mailchimp => 'X',
);
my @cached_since_emails;
my %cached_unsub_reasons;

# The number of seconds to buffer when comparing timestamps between mailchimp
# and AIR.  Should account for slight differences in server times.
my $TBUFF = 5;

# singleton api (trying to create more produces errors)
my $API_KEY = AIR2::Config::get_constant('AIR2_MAILCHIMP_KEY');
my $LIST_ID = AIR2::Config::get_constant('AIR2_EMAIL_LIST_ID');
my $API_OPT = {
    apikey        => $API_KEY,
    timeout       => 180,
    output_format => 'json',
    api_version   => 1.3,
};
my $API;

# constructor
sub init {
    my $self = shift;
    my %args = @_;
    $args{api_key} ||= $API_KEY;
    $args{list_id} ||= $LIST_ID;
    $args{org}     ||= AIR2::Organization->new(
        org_id => AIR2::Config::get_apmpin_org_id() )->load;

    $self->SUPER::init(%args);

    # check
    croak "org required"                       unless ( $self->org );
    croak "unable to find list id"             unless ( $self->list_id );
    croak "unable to find a mailchimp api key" unless ( $self->api_key );

    # setup api singleton
    $API = WWW::Mailchimp->new($API_OPT) unless ($API);

    # turn on debug opts to stderr
    if ( $ENV{AIR2_DEBUG} || $ENV{MAILCHIMP_DEBUG} ) {
        my $dumper = sub {
            if ( $_[0] =~ m/^[\{\[]/ ) { dump( decode_json( $_[0] ) ) }
        };
        $API->ua->add_handler( "request_send", sub { shift->dump; return } );
        $API->ua->add_handler( "response_done",
            sub { $_[0]->dump; $dumper->( $_[0]->decoded_content ); return }
        );
    }

    $self->{api} = $API;

    # get the actual mailing list
    my $list = $API->lists( filters => { list_id => $self->{list_id} } );
    if ( !ref $list ) {
        croak $list;
    }
    croak $list->{error} if $list->{error};
    $self->{mailing_list} = $list->{data}->[0];

    return $self;
}

=head2 campaign( I<campaign_id> )

The only static method in this class.  Looks up a single campaign with a known
ID via the api, and returns it in raw hash form.

=cut

sub campaign {
    my $self       = shift;
    my $camp_id    = shift or croak "campaign_id required";
    my $with_stats = shift;
    $API = WWW::Mailchimp->new($API_OPT) unless ($API);
    if ($with_stats) {
        my $resp = $API->campaignStats( cid => $camp_id );
        if ( !ref $resp ) {
            warn "$resp";
            return 0;
        }
        return $resp->{error} ? 0 : $resp;
    }
    else {
        my $resp = $API->campaigns( filters => { campaign_id => $camp_id } );
        if ( !ref $resp ) {
            warn "$resp";
            return 0;
        }
        return $resp->{error} ? 0 : $resp->{data}->[0];
    }
}

=head2 push_list( I<options> )

Push changes from src_org_email to mailchimp. Makes no attempt to verify what's
in src_org_email... just blindly throws at Mailchimp.

* B<source> - Single or array of sources to push (will find all src_emails)

* B<email>  - Single or array of emails to push

* B<all>    - True to push ALL changes EVER for this mailing list

=cut

sub push_list {
    my $self   = shift;
    my $opts   = {@_};
    my $soe_it = $self->_get_soe_iterator($opts);

    # sanitized results
    my %results = (
        subscribed   => 0,
        unsubscribed => 0,
        ignored      => 0,
    );

    # everything that isn't subscribed is an unsub action
    my ( $subs, $unsubs );
    while ( my $soe = $soe_it->next ) {
        if ( $soe->soe_status eq 'A' ) {
            $subs->{ $soe->email->sem_email } = $soe;
        }
        else {
            $unsubs->{ $soe->email->sem_email } = $soe;
        }
    }

    #warn "subs: " . dump($subs);
    #warn "unsubs: " . dump($unsubs);

    # subscribes
    my $sub_iter = natatime( $PAGE_SIZE, keys %{$subs} );
    while ( my @chunk = $sub_iter->() ) {
        @chunk = map { { EMAIL => $_, } } @chunk;
        my $resp = $API->listBatchSubscribe(
            id                => $self->{list_id},
            batch             => \@chunk,
            double_optin      => 0,
            replace_interests => 0,
        );
        if ( !ref $resp ) {
            croak $resp;
        }
        $results{subscribed} += $resp->{add_count};
        $results{subscribed} += $resp->{update_count};

        # process individual error codes (we'll ignore some codes)
        for my $err ( @{ $resp->{errors} } ) {
            if ( $err->{code} == $ERRORS{List_AlreadySubscribed} ) {
                $results{ignored}++;
            }
            elsif ($err->{code} == $ERRORS{List_InvalidImport}
                || $err->{code} == $ERRORS{Invalid_Email}
                || $err->{code} == $ERRORS{RoleBasedOrInvalid_Email} )
            {
                $results{skipped}++;
            }
            elsif ($err->{code} == $ERRORS{List_InvalidUnsubMember}
                || $err->{code} == $ERRORS{List_InvalidBounceMember} )
            {

                # NOTE: unlike batch, single-sub calls can force a re-sub.
                # Since this is always a manual process in AIR, hopefully
                # there will never be a ridiculous number of these.
                my $force_resp = $API->listSubscribe(
                    id                => $self->{list_id},
                    email_address     => $err->{email},
                    double_optin      => 0,
                    update_existing   => 1,
                    replace_interests => 0,
                    send_welcome      => 0,
                );
                if ($force_resp) {
                    $results{subscribed}++;
                }
                else {
                    warn "MailChimp ERROR($err->{code}) : $err->{message}";
                    croak "MailChimp ERROR($err->{code}) : $err->{message}";
                }
            }
            else {
                warn "MailChimp ERROR($err->{code}) : $err->{message}";
                croak "MailChimp ERROR($err->{code}) : $err->{message}";
            }
        }
    }

    # unsubscribes
    my $unsub_iter = natatime( $PAGE_SIZE, keys %{$unsubs} );
    while ( my @chunk = $unsub_iter->() ) {
        my $resp = $API->listBatchUnsubscribe(
            id            => $self->{list_id},
            emails        => \@chunk,
            delete_member => 1,                  # always delete; AIR is SOR
            send_goodbye  => 0,
            send_notify   => 0,
        );
        $results{unsubscribed} += $resp->{success_count};

        # process individual error codes (we'll ignore some codes)
        for my $err ( @{ $resp->{errors} } ) {
            if ( $err->{code} == $ERRORS{Email_NotExists} ) {
                $results{ignored}++;
            }
            elsif ( $err->{code} == $ERRORS{List_NotSubscribed} ) {
                $results{ignored}++;
            }
            else {
                warn "MailChimp ERROR($err->{code}) : $err->{message}";
                croak "MailChimp ERROR($err->{code}) : $err->{message}";
            }
        }
    }

    # return the results
    return \%results;
}

=head2 pull_list( I<options> )

Update the src_org_email table from what's in Mailchimp.  Will overwrite
any existing records in the table.

* B<source> - Single or array of sources to pull (will find all src_emails)

* B<email>  - Single or array of emails to pull

* B<all>    - True to get ALL changes EVER for this mailing list

* B<since>  - Pull changes >= timestamp. Pass 1 to default to the latest
              soe_status_dtim found for this org. This should be passed as the
              SERVER's timezone.

=cut

sub pull_list {
    my $self = shift;
    my $opts = {@_};

    # sanitized results
    my %results = (
        subscribed   => 0,
        unsubscribed => 0,
        ignored      => 0,
    );

    # map status => {email => dtim}
    my $stats = {
        subscribed   => {},
        unsubscribed => {},
        cleaned      => {},
    };

    # format "since" values correctly (utc)
    if ( $opts->{since} ) {
        my $epoch;

        if ( !blessed( $opts->{since} ) ) {

            # lookup the last value
            if ( $opts->{since} == 1 ) {
                my $soe = AIR2::SrcOrgEmail->fetch_all_iterator(
                    query =>
                        [ soe_org_id => $self->org->org_id, soe_type => 'M' ],
                    sort_by => 'soe_status_dtim DESC',
                )->next;
                my $last
                    = $soe
                    ? '' . $soe->soe_status_dtim
                    : "2001-01-01 01:01:01";

                # subtract 1 second, to make sure we get everything
                $epoch = str2time($last) - 1;
            }
            else {
                $epoch = str2time( $opts->{since} );
            }
        }
        else {
            $epoch = $opts->{since}->epoch;
        }

        my $date_utc = DateTime->from_epoch( epoch => $epoch );
        $opts->{since} = $date_utc->strftime("%Y-%m-%d %H:%M:%S");
    }
    @cached_since_emails  = ();    # clear
    %cached_unsub_reasons = ();    # clear

    # different strategy depending on arguments
    if ( $opts->{all} || $opts->{since} ) {

        # debug output
        if ( $opts->{debug} && $opts->{all} ) {
            warn " *pulling ALL list members\n";
        }
        elsif ( $opts->{debug} && $opts->{since} ) {
            warn " *pulling list members changed since $opts->{since}\n";
        }

        # need to fetch each status with a separate api call
        for my $status ( keys %{$stats} ) {
            my $start = 0;
            my $total = 0;

            do {
                my $resp = $API->listMembers(
                    id     => $self->{list_id},
                    status => $status,
                    since  => $opts->{since},     # 24 hour format in GMT
                    start  => $start,
                    limit  => $PAGE_SIZE,         # limit 15K
                );

                if ( !ref $resp ) {
                    croak $resp;
                }

            # $opts->{debug} and warn " FETCHING($self->{list_id}) $status\n";
            # $opts->{debug} and dump $resp;

                $total = $resp->{total};
                $start = $start + $PAGE_SIZE;

                for my $row ( @{ $resp->{data} } ) {
                    my $email    = lc $row->{email};
                    my $gmt_dtim = $row->{timestamp};
                    $stats->{$status}->{$email} = $gmt_dtim;
                    push( @cached_since_emails, $email )
                        if $opts->{since};

                    # save the reason for unsubs - add to src_activity later
                    if ( $status eq 'unsubscribed' ) {
                        if ( $row->{reason} && $row->{reason_text} ) {
                            my $txt = "$row->{reason} - $row->{reason_text}";
                            $cached_unsub_reasons{$email} = $txt;
                        }
                        elsif ( $row->{reason} || $row->{reason_text} ) {
                            my $txt = $row->{reason} || $row->{reason_text};
                            $cached_unsub_reasons{$email} = $txt;
                        }
                    }
                }
            } while ( $start < $total );
        }
    }
    else {
        my @emails;

        # only really care about emails that exist in AIR
        my $sem_it = $self->_get_sem_iterator($opts);
        while ( my $sem = $sem_it->next ) {
            push @emails, lc $sem->sem_email;
        }

        # unfortunately, API only handles 50-at-a-time
        my $chunk_iter = natatime( 50, @emails );
        while ( my @chunk = $chunk_iter->() ) {
            my $resp = $API->listMemberInfo(
                id            => $self->{list_id},
                email_address => \@chunk,
            );

            for my $row ( @{ $resp->{data} } ) {
                if ( $row->{error} ) {
                    my $email = lc $row->{email_address};
                    $stats->{not_in_mailchimp}->{$email} = time();
                }
                else {
                    my $email    = lc $row->{email};
                    my $gmt_dtim = $row->{timestamp};
                    my $status   = $row->{status};
                    $stats->{$status}->{$email} = $gmt_dtim;
                }
            }
        }
    }

    # now insert/update src_org_email rows in AIR
    for my $st ( keys %{$stats} ) {
        for my $addr ( keys %{ $stats->{$st} } ) {
            if ( $self->_update_soe( $addr, $st, $stats->{$st}->{$addr} ) ) {
                if ( $st eq 'subscribed' ) {
                    $results{subscribed}++;
                }
                else {
                    $results{unsubscribed}++;
                }
            }
            else {
                $results{ignored}++;
            }
        }
    }

    # return the results
    $opts->{debug} and dump \%results;
    return \%results;
}

=head2 sync_list( I<options> )

The real workhorse.  Reconciles (so_status + sem_status) vs soe_status.  Takes
the same options as pull_list.

* B<source> - Single or array of sources to sync (will find all src_emails)

* B<email>  - Single or array of emails to sync

* B<all>    - True to sync ALL changes EVER for this mailing list

* B<since>  - Pull changes >= timestamp. Pass 1 to default to the latest
              soe_status_dtim found for this org. This should be passed as the
              SERVER's timezone.

* B<dry_run> - Don't actually update anything in mailchimp - just pull the
               changes to AIR. The return value will be whatever pull_list
               returned instead of the usual push_list return value.


* B<debug>   - Debug output

=cut

sub sync_list {
    my $self = shift;
    my $opts = {@_};

    # pull things
    my $resp = $self->pull_list(@_);

    # if we specified "since", we need to use the actual pulled emails,
    # since push_list doesn't support that argument
    if ( $opts->{since} ) {
        if ( scalar @cached_since_emails > 0 ) {
            $opts->{email} = \@cached_since_emails;
        }
        else {
            $opts->{email} = 'x';    # non-matching string
        }
    }

    # map src_id => src_org_cache
    my %soc_map;
    my %all_src_ids;
    my $soc_it = $self->_get_soc_iterator($opts);
    my $count  = 0;
    while ( my $soc = $soc_it->next ) {
        $soc_map{ $soc->soc_src_id }     = $soc;
        $all_src_ids{ $soc->soc_src_id } = 1;
    }

    # map sem_id => src_org_email
    my %soe_map;
    my $soe_it = $self->_get_soe_iterator($opts);
    while ( my $soe = $soe_it->next ) {
        $soe_map{ $soe->soe_sem_id } = $soe;
        $all_src_ids{ $soe->email->sem_src_id } = 1;
    }

    # sometimes, we need to cleanup src_org_email records (case 2 below)
    my @soe_cleanup;

    # iterate through src_emails (GUARANTEED to exist)
    if ( $opts->{all} ) {
        my @srcids = keys %all_src_ids;
        $opts->{src_id} = ( scalar @srcids ) ? \@srcids : -1;
    }
    my $sem_it = $self->_get_sem_iterator($opts);
    while ( my $sem = $sem_it->next ) {
        my $soe = $soe_map{ $sem->sem_id };
        my $soc = $soc_map{ $sem->sem_src_id };

        # case 0: no soe or soc
        if ( !$soe and !$soc ) {
            warn "No soe and no soc for " . $sem->sem_email;
            next;
        }

        # case 1: no src_org_email (mailchimp doesn't know about it yet)
        elsif ( !$soe && $soc ) {
            my $new_status = 'U';
            if ( $sem->sem_status eq 'G' && $soc->soc_status eq 'A' ) {
                $new_status = 'A';
            }
            $soe = AIR2::SrcOrgEmail->new(
                soe_sem_id      => $sem->sem_id,
                soe_org_id      => $self->org->org_id,
                soe_type        => 'M',
                soe_status      => $new_status,
                soe_status_dtim => time(),
            );
            $soe->save();
        }

        # case 2: src_org_cache non-active
        elsif ( !$soc || $soc->soc_status ne 'A' ) {
            $soe->soe_status('U');    # force unsub
            $soe->soe_status_dtim( time() );
            $soe->save();
            push( @soe_cleanup, $soe ) if !$soc;
        }

        # case 3: handle src_org_email vs src_email conflicts
        else {
            my $dtsem = $sem->sem_upd_dtim->epoch();
            my $dtsoe = $soe->soe_status_dtim->epoch();

            # determine if there is a conflict
            my $sem_st = $sem->sem_status;
            my $soe_st = $soe->soe_status;
            my $is_conflict
                = (    ( $sem_st eq 'G' && $soe_st ne 'A' )
                    || ( $sem_st eq 'B' && $soe_st eq 'A' )
                    || ( $sem_st eq 'C' && $soe_st eq 'A' )
                    || ( $sem_st eq 'U' && $soe_st ne 'U' ) );

            if ($is_conflict) {
                my $air_newer   = $dtsem > ( $dtsoe + $TBUFF );
                my $chimp_newer = $dtsoe > ( $dtsem + $TBUFF );

                # be conservative if it's not apparent which is newer
                unless ( $air_newer || $chimp_newer ) {
                    if ( $soe_st eq 'B' || $soe_st eq 'U' ) {
                        $chimp_newer = 1;
                    }
                    else {
                        $air_newer = 1;
                    }
                }

                # air status changed
                if ($air_newer) {
                    $soe->soe_status( $sem_st eq 'G' ? 'A' : 'U' );
                    $soe->soe_status_dtim($dtsem);
                    $soe->save();
                }

                # mailchimp newer - only care about src_email opt-out
                elsif ( $chimp_newer
                    && ( $soe_st eq 'B' || $soe_st eq 'U' ) )
                {
                    $sem->db->get_write_handle->do_transaction(
                        sub {
                            $sem->sem_status($soe_st);
                            $sem->sem_upd_dtim($dtsoe);
                            $sem->set_admin_update(1);
                            $sem->save();
                            $sem->source->set_and_save_src_status();

                            # log activity on unsub/bounce
                            my $sstr
                                = ( $soe_st eq 'B' )
                                ? 'Bounced'
                                : 'Unsubscribed';
                            my $sact = AIR2::SrcActivity->new(
                                sact_src_id => $sem->sem_src_id,
                                sact_desc =>
                                    "Email provider status changed to $sstr",
                                sact_dtim    => $dtsoe,
                                sact_actm_id => ( $soe_st eq 'B' )
                                ? 24
                                : 22,
                            );

                            # for unsubscribes, try to get the reason
                            if ( $cached_unsub_reasons{ $sem->sem_email } ) {
                                $sact->sact_notes(
                                    $cached_unsub_reasons{ $sem->sem_email }
                                );
                            }
                            elsif ( $soe_st eq 'U' ) {

                              # The only API call that can get the reason text
                              # is listMembers (arggg!), so try to pull since
                              # a timestamp, and hope we get the right one.
                                my $try_since = DateTime->from_epoch(
                                    epoch => ( $dtsoe - 1 ) );
                                my $try_resp = $API->listMembers(
                                    id     => $self->{list_id},
                                    status => 'unsubscribed',
                                    since  => $try_since->strftime(
                                        "%Y-%m-%d %H:%M:%S"),
                                    start => 0,
                                    limit => 20,
                                );
                                unless ( $try_resp->{error} ) {
                                    for my $row ( @{ $try_resp->{data} } ) {
                                        if (lc( $row->{email} ) eq
                                            $sem->sem_email )
                                        {
                                            if (   $row->{reason}
                                                && $row->{reason_text} )
                                            {
                                                $sact->sact_notes(
                                                    "$row->{reason} - $row->{reason_text}"
                                                );
                                            }
                                            elsif ($row->{reason}
                                                || $row->{reason_text} )
                                            {
                                                $sact->sact_notes(
                                                           $row->{reason}
                                                        || $row->{reason_text}
                                                );
                                            }
                                            last;
                                        }
                                    }
                                }
                            }

                            # save activity
                            $sact->save();
                        }
                    );
                }
            }
        }
    }

    # push the changes out
    unless ( $opts->{dry_run} ) {
        if ( $opts->{source} ) {
            $resp = $self->push_list( source => $opts->{source} );
        }
        elsif ( $opts->{email} ) {
            $resp = $self->push_list( email => $opts->{email} );
        }
        else {
            $resp = $self->push_list( all => 1 );
        }
    }

    # cleanup src_org_emails where the src_org DNE
    map { $_->delete() } @soe_cleanup;

    # return result of either push or pull
    return $resp;
}

=head2 make_segment( I<options> )

Create a static segment containing a certain subset of emails.  Will return
the segment ID, along with any errors that occurred (most often that you have
a source that's unsubscribed from this mailing list).

* B<name>   - A unique-ish name for the segment.  If the passed name is already
              taken, this method will add random characters to the end in an
              attempt to make it unique.

* B<source> - Source or sources in the segment (will find primary emails)

* B<email>  - Email addresses in the segment

* B<bcc>    - Email addresses to include in the segment, but not the counts.
              (should ALWAYS be valid emails)

=cut

sub make_segment {
    my $self = shift;
    my $opts = {@_};
    $opts->{name} or croak "Segment name required";
    if ( !$opts->{source} and !$opts->{email} ) {
        croak "Sources or emails required";
    }

    # sanitized results
    my %results = (
        id        => 0,
        name      => 0,
        added     => 0,
        skipped   => 0,
        skip_list => [],    # refs to sources skipped
    );

    # normalize the segment name (max len 50, so leave room)
    ( my $norm_name = substr( $opts->{name}, 0, 44 ) ) =~ s/\W+/\-/g;
    $results{name} = $norm_name;

    # keep attempting to create until we find a unique name
    my $attempts = 1;
    my $resp     = $API->listStaticSegmentAdd(
        id   => $self->{list_id},
        name => $results{name},
    );
    while ( ref $resp && $resp->{error} =~ /must be unique/i ) {
        $results{name} = $norm_name . '-' . $attempts++;
        $resp = $API->listStaticSegmentAdd(
            id   => $self->{list_id},
            name => $results{name},
        );
    }

    # if that didn't work, upchuck
    if ( ref $resp && $resp->{error} ) {
        warn "MailChimp ERROR($resp->{code}) : $resp->{error}";
        croak "MailChimp ERROR($resp->{code}) : $resp->{error}";
    }
    $results{id} = $resp;

    # get list of emails
    my @emails;
    my %srcid_to_email;
    if ( $opts->{email} ) {
        @emails = @{ $opts->{email} };
    }
    else {
        my $sem_it = $self->_get_sem_iterator($opts);

        # grouped by source (find primary if necessary)
        while ( my $sem = $sem_it->next ) {
            if ( $srcid_to_email{ $sem->sem_src_id } ) {
                $srcid_to_email{ $sem->sem_src_id } = lc $sem->sem_email
                    if ( $sem->sem_primary_flag );
            }
            else {
                $srcid_to_email{ $sem->sem_src_id } = lc $sem->sem_email;
            }
        }
        @emails = values %srcid_to_email;
    }

    # add the emails
    my %skipped_emails;
    my $chunk_iter = natatime( $PAGE_SIZE, @emails );
    while ( my @chunk = $chunk_iter->() ) {
        $resp = $API->listStaticSegmentMembersAdd(
            id     => $self->{list_id},
            seg_id => $results{id},
            batch  => \@chunk,
        );
        $results{added} += $resp->{success};
        for my $err ( @{ $resp->{errors} } ) {
            $skipped_emails{ $err->{email} } = 1;
        }
    }

    # figure out what we actually processed/skipped
    if ( $opts->{email} ) {
        @{ $results{skip_list} } = keys %skipped_emails;
        $results{skipped} = scalar keys %skipped_emails;
    }
    else {
        my $is_array = ref $opts->{source} eq 'ARRAY';
        my @all_sources
            = $is_array ? @{ $opts->{source} } : ( $opts->{source} );
        for my $src (@all_sources) {
            if ( my $e = $srcid_to_email{ $src->src_id } ) {
                if ( $skipped_emails{$e} ) {
                    $results{skipped}++;
                    push @{ $results{skip_list} }, $src;
                }
            }
            else {
                $results{skipped}++;
                push @{ $results{skip_list} }, $src;
            }
        }
    }

    # add the BCC's (force subscribe them to the list)
    if ( $opts->{bcc} && scalar @{ $opts->{bcc} } > 0 ) {
        for my $addr ( @{ $opts->{bcc} } ) {
            $API->listSubscribe(
                id                => $self->{list_id},
                email_address     => $addr,
                double_optin      => 0,
                update_existing   => 1,
                replace_interests => 0,
                send_welcome      => 0,
            );
        }
        $API->listStaticSegmentMembersAdd(
            id     => $self->{list_id},
            seg_id => $results{id},
            batch  => $opts->{bcc},
        );
    }

    # return the results
    return \%results;
}

=head2 make_campaign( I<options> )

Create a new campaign from an AIR2 email record.  Does not actually send the
email - just returns the ID so you can schedule it or send it later.

* B<template> - An AIR2 Email record

* B<segment>  - ID of a static segment to send to

=cut

sub make_campaign {
    my $self = shift;
    my $opts = {@_};
    $opts->{template} or croak "Email template record required";
    $opts->{segment}  or croak "Segment id required";
    my $stat = $opts->{template}->email_status;
    croak "Email not active" if ( $stat ne 'A' && $stat ne 'Q' );

    # sanitized results
    my %results = (
        id    => 0,
        count => 0,
    );

    # segmentation
    my $seg = {
        match      => 'all',
        conditions => [
            {   field => 'static_segment',
                op    => 'eq',
                value => $opts->{segment},
            }
        ],
    };

    # create ye ol' campaign
    $results{id} = $API->campaignCreate(
        type    => 'regular',
        options => {
            list_id       => $self->{list_id},
            subject       => $opts->{template}->email_subject_line,
            from_email    => $opts->{template}->email_from_email,
            from_name     => $opts->{template}->email_from_name,
            inline_css    => 1,
            generate_text => 1,
        },
        content      => { html => $opts->{template}->compile_html_body() },
        segment_opts => $seg,
    );
    if ( ref $results{id} eq 'HASH' ) {
        warn "MailChimp ERROR($results{id}->{code}) : $results{id}->{error}";
        croak "MailChimp ERROR($results{id}->{code}) : $results{id}->{error}";
    }

    # test the static segment
    $results{count} = $API->campaignSegmentTest(
        list_id => $self->{list_id},
        options => $seg,
    );

    # return the results
    return \%results;
}

=head2 send_campaign( I<options> )

Send a campaign - either now, or sometime in the future.

* B<campaign> - ID of the campaign

* B<delay>    - an optional dtim to delay sending until

=cut

sub send_campaign {
    my $self = shift;
    my $opts = {@_};
    $opts->{campaign} or croak "Campaign id required";

    # send now, or a bit later on
    if ( $opts->{delay} ) {
        my $epoch = str2time( $opts->{delay} );
        croak "Invalid delay specified: $opts->{delay}" unless $epoch;
        my $date_utc = DateTime->from_epoch(
            epoch     => $epoch,
            time_zone => $AIR2::Config::TIMEZONE,
        );
        $date_utc->set_time_zone('UTC');
        return $API->campaignSchedule(
            cid           => $opts->{campaign},
            schedule_time => $date_utc->strftime("%Y-%m-%d %H:%M:%S"),
        );
    }
    else {
        return $API->campaignSendNow( cid => $opts->{campaign} );
    }
}

#
# PRIVATE METHODS
#

# convert options to a src_org_email iterator
sub _get_soe_iterator {
    my $self = shift;
    my $opts = shift or croak "options required";

    # argument exclusivity
    my %excl = map { $_ => 1 } qw(source email all);
    if ( scalar( grep { $excl{$_} } keys %{$opts} ) != 1 ) {
        croak 'Invalid arguments';
    }

    # build query
    my $query = [ 'soe_org_id' => $self->org->org_id, 'soe_type' => 'M' ];
    if ( $opts->{source} ) {
        if ( ref $opts->{source} eq 'ARRAY' ) {
            my @ids = map { $_->src_id } @{ $opts->{source} };
            push @$query, 'email.sem_src_id' => \@ids;
        }
        else {
            push @$query, 'email.sem_src_id' => $opts->{source}->src_id;
        }
    }
    if ( $opts->{email} ) {
        push @$query, 'email.sem_email' => $opts->{email};
    }

    # get iterator
    return AIR2::SrcOrgEmail->fetch_all_iterator(
        require_objects => [qw(email)],
        query           => $query,
    );
}

# convert options to a src_email iterator
sub _get_sem_iterator {
    my $self = shift;
    my $opts = shift or croak "options required";

    # argument exclusivity
    my %excl = map { $_ => 1 } qw(source email src_id);
    if ( scalar( grep { $excl{$_} } keys %{$opts} ) != 1 ) {
        croak 'Invalid arguments';
    }

    # build query
    my $query = [];
    if ( $opts->{source} ) {
        if ( ref $opts->{source} eq 'ARRAY' ) {
            my @ids = map { $_->src_id } @{ $opts->{source} };
            push @$query, 'sem_src_id' => \@ids;
        }
        else {
            push @$query, 'sem_src_id' => $opts->{source}->src_id;
        }
    }
    if ( $opts->{email} ) {
        push @$query, 'sem_email' => $opts->{email};
    }
    if ( $opts->{src_id} ) {
        push @$query, 'sem_src_id' => $opts->{src_id};
    }

    # get iterator
    return AIR2::SrcEmail->fetch_all_iterator( query => $query );
}

# convert options to a src_org_cache iterator
sub _get_soc_iterator {
    my $self = shift;
    my $opts = shift or croak "options required";

    # argument exclusivity
    my %excl = map { $_ => 1 } qw(source email all);
    if ( scalar( grep { $excl{$_} } keys %{$opts} ) != 1 ) {
        croak 'Invalid arguments';
    }

    # build query
    my $query = [ 'soc_org_id' => $self->org->org_id ];
    if ( $opts->{source} ) {
        if ( ref $opts->{source} eq 'ARRAY' ) {
            my @ids = map { $_->src_id } @{ $opts->{source} };
            push @$query, 'soc_src_id' => \@ids;
        }
        else {
            push @$query, 'soc_src_id' => $opts->{source}->src_id;
        }
    }

    # not sure how to get perl to do this in 1 query, so just do a seperate
    # one for the src_id's right now
    if ( $opts->{email} ) {
        my @ids = map { $_->sem_src_id } @{ AIR2::SrcEmail->fetch_all(
                query => [ sem_email => $opts->{email} ]
            )
        };
        if ( scalar @ids ) {
            push @$query, 'soc_src_id' => \@ids;
        }
        else {
            push @$query, 'soc_src_id' => -1;
        }
    }

    # get iterator
    return AIR2::SrcOrgCache->fetch_all_iterator( query => $query );
}

# find or create a src_org_email record (returns 1 on update)
sub _update_soe {
    my $self   = shift;
    my $email  = shift or croak "email address required";
    my $status = shift or croak "status required";
    my $dtim   = shift or croak "dtim required";

    # TODO: optimize these lookups somehow
    my $sem = AIR2::SrcEmail->new( sem_email => $email );
    return 0 unless ( $sem->load_speculative );

    my $soe = AIR2::SrcOrgEmail->new(
        soe_sem_id => $sem->sem_id,
        soe_org_id => $self->org->org_id,
        soe_type   => 'M',
    );
    my $exists = $soe->load_speculative;
    my $old_status = $exists ? $soe->soe_status : '';

    # delete from air when DNE in mailchimp
    if ( $SOE_STATUS_MAP{$status} eq 'X' ) {
        return 0 unless $exists;    #ignore
        $soe->delete;
        return ( $old_status eq 'A' ) ? 1 : 0;
    }

    # update status/dtim (convert from UTC)
    $soe->soe_status( $SOE_STATUS_MAP{$status} );
    my $epoch = str2time( $dtim, 'UTC' );
    $soe->soe_status_dtim($epoch);
    $soe->save;

    # return changed
    return ( $old_status eq $soe->soe_status ) ? 0 : 1;
}

# helper to find/test for valid states
my @VALID_STATES = qw(
    GAA GDU GFU GXU
    BAB BDB BFB BXB
    UAU UDU UFU UXU
    CAU CDU CFU CXU
);

sub _state_search {
    my $self = shift;
    my $sem  = shift or croak "src_email required";
    my $sorg = shift;
    my $soe  = shift;

    # compute a regex search string
    #  - pass in "." for any argument to wildcard search
    #  - if no src_org record, it counts as an "X"
    #  - if no src_org_email record, it counts as a "U"
    my $sss = ( ref $sem ) ? $sem->sem_status : $sem;
    if ($sorg) {
        $sss .= ( ref $sorg ) ? $sorg->so_status : $sorg;
    }
    else {
        $sss .= 'X';    # default
    }
    if ($soe) {
        $sss .= ( ref $soe ) ? $soe->soe_status : $soe;
    }
    else {
        $sss .= 'U';    # default
    }

    # find it!
    my @state = grep /$sss/, @VALID_STATES;
    return shift @state;
}

1;
