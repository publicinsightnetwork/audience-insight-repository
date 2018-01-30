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
use Digest::MD5 qw( md5_hex );
use Date::Parse;
use DateTime;
use Scalar::Util qw( blessed );
use JSON;
use IO::String;
use IO::Uncompress::Gunzip;
use Archive::Tar;
use AIR2::Config;
use AIR2::Organization;
use Mail::Chimp3;
use AIR2::UserAgent;
use Time::HiRes ();
use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(
    qw(
        debug
        max_tries
        interval
        api_page_size
        api_batch_min
        api_batch_limit
        )
);

__PACKAGE__->mk_ro_accessors(
    qw(
        org
        api_key
        api
        list_id
        mailing_list
        grouping_id
        list_filter_max
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
    pending          => 'P',
    subscribed       => 'A',
    unsubscribed     => 'U',
    cleaned          => 'B',
    not_in_mailchimp => 'X',
);
my @cached_since_emails;
my %cached_unsub_reasons;
my $DEFAULT_START_TIME = '2001-01-01 01:01:01';

# this is a Mailchimp constant. May only schedule campaigns on the quarter hour.
use constant INCREMENT_DELAY => 15;

# The number of seconds to buffer when comparing timestamps between mailchimp
# and AIR.  Should account for slight differences in server times.
my $TBUFF = 5;

# singleton api (trying to create more produces errors)
my $API_KEY = AIR2::Config::get_constant('AIR2_MAILCHIMP_KEY');
my $LIST_ID = AIR2::Config::get_constant('AIR2_EMAIL_LIST_ID');
my $API_OPT = {
    api_key => $API_KEY,
    agent   => AIR2::UserAgent->new(
        timeout  => 180,
        agent    => 'air2-useragent',
        ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 }
    ),
};
my $API;

# constructor
sub init {
    my $self = shift;
    my %args = @_;
    $args{debug} ||= $ENV{MAILCHIMP_DEBUG} || $ENV{AIR2_DEBUG};
    $args{max_tries}       ||= 10;
    $args{interval}        ||= 5;
    $args{api_batch_min}   ||= 10;
    $args{api_batch_limit} ||= 500;    # determined by Mailchimp

    # >100 slows down total time for large resultsets
    $args{api_page_size} ||= 100;

    # production list size is > 200k
    # 200,000 members at 100/page = 2000 HTTP calls
    # so if total list size is < 2000 then faster to do individually.
    $args{list_filter_max} ||= int( 200_000 / $args{api_page_size} );

    $args{api_key} ||= $API_KEY;
    $args{list_id} ||= $LIST_ID;
    $args{org}     ||= AIR2::Organization->new(
        org_id => AIR2::Config::get_apmpin_org_id() )->load;

    $self->SUPER::init(%args);

    # check
    confess "org required"                       unless ( $self->org );
    confess "unable to find list id"             unless ( $self->list_id );
    confess "unable to find a mailchimp api key" unless ( $self->api_key );

    $self->{api} = $self->init_api();
    $self->init_mailing_list();
}

sub init_api {
    my $self = shift;
    return $API if $API;

    # setup api singleton
    $API = Mail::Chimp3->new($API_OPT) unless ($API);

    # turn on debug opts to stderr
    if ( $ENV{AIR2_DEBUG} || $ENV{MAILCHIMP_DEBUG} ) {
        my $dumper = sub {
            if ( $_[0] =~ m/^[\{\[]/ ) {
                $self->debug_response( decode_json( $_[0] ) );
            }
        };
        $API->agent->add_handler( "request_send",
            sub { shift->dump; return } );
        $API->agent->add_handler( "response_done",
            sub { $_[0]->dump; $dumper->( $_[0]->decoded_content ); return }
        );
    }
    return $API;
}

sub init_mailing_list {
    my $self = shift;

    # cache the mailing list
    my $list = $self->api->list( list_id => $self->list_id );
    if ( !ref $list ) {
        confess $list;
    }
    confess $list->{error} if $list->{error};
    $self->{mailing_list} = $list->{content};
}

sub list_member_count {
    my $self = shift;
    $self->{mailing_list}->{stats}->{member_count} || 0;
}

=head2 campaign( I<campaign_id> )

The only static method in this class.  Looks up a single campaign with a known
ID via the api, and returns it in raw hash form.

=cut

sub campaign {
    my $self       = shift;
    my $id         = shift or confess "campaign_id required";
    my $with_stats = shift;
    my $api        = init_api();
    my $resp       = $api->campaign( campaign_id => $id );
    if ( $resp->{code} eq '404' ) {
        return 0;
    }
    if ( $resp->{error} ) {
        warn dump($resp);
        return 0;
    }
    if ( $resp->{code} eq '200' ) {
        return $resp->{content};
    }
    else {
        return 0;
    }
}

=head2 campaign_ids

Returns list of all campaign ids defined on the list.

=cut

sub campaign_ids {
    my $self = shift;

    # paginate
    my $list_id = $self->list_id;
    my $total = 1;    # start here, then re-set based on first page.
    my @campaigns;
    my $seen     = 0;
    my $attempts = 0;
    while ( $seen < $total ) {
        my %params = (
            list_id => $list_id,
            count   => $self->api_page_size,
            offset  => scalar(@campaigns),
        );
        my $res = $self->api->campaigns(%params)->{content};
        my @c   = @{ $res->{campaigns} };
        push @campaigns, map { $_->{id} } @c;
        $seen += scalar @c;
        $total = $res->{total_items};
        last if $seen == 0;
    }
    return \@campaigns;
}

=head2 subscriber_hash( I<email_address> )

Returns the MD5 hash of the I<email_address>. This is used by Mailchimp
as the unique identifier of the subscriber in URLs.

=cut

sub subscriber_hash {
    my $self = shift;
    my $email_address = shift or confess "email address required";

    return md5_hex( lc($email_address) );
}

sub debug_response {
    my $self = shift;
    my $resp = shift or confess "resp required";

    my @attrs = qw( members new_members updated_members );
    my %copy  = %$resp;

    delete $copy{_links};
    for my $key (@attrs) {
        if ( exists $copy{$key} ) {
            for my $m ( @{ $copy{$key} } ) {
                delete $m->{_links};
            }
        }
    }
    if ( exists $copy{content} ) {
        delete $copy{content}->{_links};
        for my $key (@attrs) {
            next unless exists $copy{content}->{$key};
            for my $m ( @{ $copy{content}->{$key} } ) {
                delete $m->{_links};
            }
        }
    }

    dump( \%copy );
}

=head2 unsubscribe( I<array_of_emails> )

Sets subscriber status to C<unsubscribed> for I<array_of_emails>.

=cut

sub unsubscribe {
    my $self = shift;
    $self->set_members_status( @_, 'unsubscribed' );
}

=head2 delete( I<array_of_emails> )

Removes I<array_of_emails> from the list.

=cut

sub delete {
    my $self = shift;
    my $emails = shift or confess "array ref of emails required";

    if ( scalar(@$emails) < $self->api_batch_min ) {
        my @responses;
        for my $email (@$emails) {

            my $resp = $self->api->delete_member(
                list_id         => $self->list_id,
                subscriber_hash => $self->subscriber_hash($email)
            );
            push @responses, $resp;
        }
        return $self->_build_member_report( \@responses );
    }

    my @ops = ();
    for my $email (@$emails) {
        my $op = {
            operation_id => "DELETE-$email",
            method       => 'DELETE',
            path         => sprintf(
                "/lists/%s/members/%s",
                $self->list_id, $self->subscriber_hash($email)
            ),
        };
        push @ops, $op;
    }

    my $results = $self->wait_for_batch(
        $self->api->add_batch( operations => \@ops ) );
    $self->debug and warn "DELETE report: " . dump($results);
    return $self->_build_member_report($results);
}

=head2 delete_all

Calls B<delete> on every list member.

=cut

sub delete_all {
    my $self    = shift;
    my $members = $self->list_members();
    my @emails  = map { $_->{email_address} } grep { $_->{status} } @$members;
    $self->delete( \@emails ) if @emails;
}

=head2 clean( I<array_of_emails> )

Sets status to C<cleaned> for each of I<array_of_emails>.

=cut

sub clean {
    my $self = shift;
    $self->set_members_status( @_, 'cleaned' );
}

=head2 subscribe( I<array_of_emails> )

Sets status to C<subscribed> for each of I<array_of_emails>.

=cut

sub subscribe {
    my $self = shift;
    $self->set_members_status( @_, 'subscribed' );
}

sub set_members_status {
    my $self   = shift;
    my $emails = shift or confess "array ref of emails required";
    my $status = shift or confess "status required";

    # use special batch endpoint if we are under api_batch_limit
    if ( scalar(@$emails) <= $self->api_batch_limit ) {
        my @members;
        for my $email (@$emails) {
            push @members, { email_address => $email, status => $status };
        }
        my $resp = $self->api->batch_list(
            list_id         => $self->list_id,
            members         => \@members,
            update_existing => \1,
        );
        my $report = $resp;
        if ( $report->{code} eq '200' ) {
            $report->{success_count} = 1;
            $report->{$status}
                = (   $report->{content}->{total_created}
                    + $report->{content}->{total_updated} );
        }
        return $report;
    }

    # build operations
    my @ops = ();
    for my $email (@$emails) {
        my $op = {
            operation_id => "$status-$email",
            method       => 'PUT',
            path         => sprintf(
                "/lists/%s/members/%s",
                $self->list_id, $self->subscriber_hash($email)
            ),
            body => encode_json(
                {   status        => $status,
                    email_address => $email
                }
            ),
        };
        push @ops, $op;
    }

    my $results = $self->wait_for_batch(
        $self->api->add_batch( operations => \@ops ) );
    return $self->_build_member_report($results);
}

sub _build_member_report {
    my $self    = shift;
    my $results = shift;
    my $report  = { results => $results };
    for my $result (@$results) {
        my $code = $result->{status_code} || $result->{code};
        $report->{success_count}++ if $code =~ m/^2/;
        if ( $result->{content}->{status} ) {
            $report->{ $result->{content}->{status} }++;
        }
    }
    return $report;
}

sub wait_for_batch {
    my $self = shift;
    my $batch_resp = shift or confess "batch_resp required";

    my $batch_id = $batch_resp->{content}->{id}
        or confess "no batch id in response " . dump($batch_resp);

    my $max_tries = $self->max_tries;
    my $interval  = $self->interval;
    my $attempts  = 0;
    my $final_resp;
    while ( $attempts++ < $max_tries ) {
        $self->debug
            and warn
            "attempts $attempts max_tries $max_tries sleep $interval";
        sleep($interval);
        my $resp = $self->api->batch( batch_id => $batch_id );
        if ( $resp->{content}->{status} eq 'finished' ) {
            $final_resp = $self->_fetch_batch_response(
                $resp->{content}->{response_body_url} );
            last;
        }
        if ( $resp->{content}->{total_operations}
            > $resp->{content}->{finished_operations} )
        {
            $attempts--;
        }
    }

    return $final_resp;
}

sub _fetch_batch_response {
    my $self      = shift;
    my $uri       = shift;
    my $resp      = $self->api->agent->get($uri);
    my $io_str    = IO::String->new( $resp->decoded_content );
    my $gunzipped = IO::Uncompress::Gunzip->new($io_str);
    my $tar       = Archive::Tar->new;
    my @responses;
    for my $file ( ( $tar->read($gunzipped) ) ) {
        next unless $file->name =~ m/\.json$/;
        push @responses, @{ decode_json( $file->get_content ) };
    }
    for my $response (@responses) {
        $response->{content} = decode_json( $response->{response} );
    }
    return \@responses;
}

=head2 list_members

Returns array ref of member hashes for all members of the list.

=cut

sub list_members {
    my $self     = shift;
    my $callback = shift;
    my $status   = shift;

    my @members;
    my @states = qw( subscribed unsubscribed cleaned );
    @states = ($status) if defined $status;

    for my $state (@states) {
        push @members,
            @{ $self->_fetch_members_by_status( $callback, $state ) };
    }

    return \@members;
}

sub _fetch_members_by_status {
    my ( $self, $callback, $status ) = @_;

    my $list_id = $self->list_id;

    # paginate
    my $total = 1;    # start here, then re-set based on first page.
    my @members;
    my $seen     = 0;
    my $attempts = 0;
    while ( $seen < $total ) {
        my %params = (
            list_id => $list_id,
            count   => $self->api_page_size,
            offset  => scalar(@members),
        );
        $params{status} = $status if $status;

        my $resp    = $self->api->members(%params);
        my $content = $resp->{content};

        $total = $content->{total_items};

        my @segment = @{ $content->{members} };
        $seen += scalar(@segment);

        # sanity check
        last if ( $attempts++ > 1 && $seen == 0 );

        if ($callback) {
            for my $member (@segment) {
                $callback->($member);
            }
        }
        else {
            push @members, @segment;
        }
    }
    return \@members;
}

=head2 push_list( I<options> )

Push changes from src_org_email to mailchimp. Makes no attempt to verify what's
in src_org_email... just blindly throws at Mailchimp.

I<options> may include:

=over

=item B<source>

Single or array of sources to push (will find all src_emails)

=item B<email>

Single or array of emails to push

=item B<all>

True to push ALL changes EVER for this mailing list

=back

=cut

sub push_list {
    my $self   = shift;
    my $opts   = {@_};
    my $soe_it = $self->_get_soe_iterator($opts);

    # sanitized results
    my %results = (
        subscribed => 0,
        cleaned    => 0,
        ignored    => 0,
    );

    # everything that isn't subscribed is an unsub action
    my ( $subs, $unsubs );
    while ( my $soe = $soe_it->next ) {
        my $soe_status = $soe->soe_status;
        my $email      = $soe->email->sem_email;

        if ( $soe_status eq 'A' ) {
            $subs->{$email} = $soe;
        }
        else {
            $unsubs->{$email} = $soe;
        }
    }

    #warn "subs: " . dump($subs);
    #warn "unsubs: " . dump($unsubs);

    # subscribes
    my $sub_iter = natatime( $PAGE_SIZE, keys %$subs );
    while ( my @chunk = $sub_iter->() ) {
        my $resp = $self->subscribe( \@chunk );

        #warn "SUB:" . $self->debug_response($resp);
        $results{subscribed} += $resp->{subscribed} || 0;

        # process individual error codes (we'll ignore some codes)
        confess $resp->{errors} if $resp->{errors};
    }

    # unsubscribes
    my $unsub_iter = natatime( $PAGE_SIZE, keys %$unsubs );
    while ( my @chunk = $unsub_iter->() ) {
        my $resp = $self->delete( \@chunk );

        #warn "UNSUB:" . $self->debug_response($resp);
        my $success = $resp->{success_count} || 0;
        $results{unsubscribed} += $success;

        if ( $success != scalar(@chunk) ) {
            for my $result ( @{ $resp->{results} } ) {
                my $code = $result->{status_code} || $result->{code} || '';
                if ( $code eq '404' ) {
                    $results{ignored}++;
                }
            }
        }
    }

    return \%results;
}

=head2 member( I<email> )

Returns member record for I<email>.

=cut

sub member {
    my $self = shift;
    my $email = shift or confess "email address required";
    $self->api->member(
        list_id         => $self->list_id,
        subscriber_hash => $self->subscriber_hash($email),
    );
}

=head2 member_exists( I<email> )

Returns true if I<email> is on the list (regardless of status).

=cut

sub member_exists {
    my $self  = shift;
    my $email = shift or confess "email address required";
    my $resp  = $self->member($email);
    return $resp->{code} eq '200';
}

=head2 member_subscribed( I<email> )

Returns true if I<email> is on the list with status C<subscribed>.

=cut

sub member_subscribed {
    my $self  = shift;
    my $email = shift or confess "email address required";
    my $resp  = $self->member($email);
    return $resp->{content} && $resp->{content}->{status} eq 'subscribed';
}

=head2 pull_list( I<options> )

Update the src_org_email table from what's in Mailchimp.  Will overwrite
any existing records in the table.

I<options> may include:

=over

=item B<source>

Single or array of sources to pull (will find all src_emails)

=item B<email>

Single or array of emails to pull

=item B<all>

True to get ALL changes EVER for this mailing list

=item B<since>

Pull changes >= timestamp. Pass 1 to default to the latest
C<soe_status_dtim> found for this org. This should be passed as the
SERVER's timezone.

=back

=cut

sub pull_list {
    my $self = shift;
    my $opts = {@_};

    my $debug = $opts->{debug} || $self->debug;

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
                    query => [
                        soe_org_id => $self->org->org_id,
                        soe_type   => 'M'
                    ],
                    sort_by => 'soe_status_dtim DESC',
                )->next;
                my $last
                    = $soe
                    ? '' . $soe->soe_status_dtim
                    : $DEFAULT_START_TIME;

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
        if ( $opts->{all} ) {
            $debug and warn " *pulling ALL list members\n";
        }
        elsif ( $opts->{since} ) {
            $debug
                and warn
                " *pulling list members changed since $opts->{since}\n";
        }

        # need to fetch each status with a separate api call
        for my $status ( keys %$stats ) {
            my $start = 0;
            my $total = 0;

            do {
                my $resp = $self->api->members(
                    list_id => $self->list_id,
                    status  => $status,

                    # 24 hour format in GMT
                    since_last_changed => $opts->{since},
                    offset             => $start,
                    count              => $self->api_page_size,    # limit 15K
                );

                confess $resp unless ref $resp;

                $debug and warn "members:" . $self->debug_response($resp);

                my @members = @{ $resp->{content}->{members} };
                $total = $resp->{content}->{total_items};
                $start += scalar(@members);

                for my $row (@members) {
                    my $email    = lc $row->{email_address};
                    my $gmt_dtim = $row->{last_changed};
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
        my %emails;

        $debug and warn "pull_list scope limited to specific emails";

        # this anon function pointer used for both individual /member calls
        # and as a callback for all list_members.
        my $member_checker = sub {
            my $member = shift;
            my $email  = lc $member->{email_address};
            return unless exists $emails{$email};

            my $gmt_dtim = $member->{last_changed};
            my $status   = $member->{status};
            $stats->{$status}->{$email} = $gmt_dtim || time();
            $emails{$email} = 1;
        };

        # how many records are we expecting?
        my $sem_query = $self->_get_sem_iterator_query($opts);
        my $segment_size
            = ref( $sem_query->[1] ) eq 'ARRAY'
            ? scalar( @{ $sem_query->[1] } )
            : 1;

        # refer to AIR records only.
        my $sem_it = $self->_get_sem_iterator($opts);

        # Optimize the number of API calls made.
        # The math takes into account the total list size,
        # and the number of emails in this segment,
        # and minimizes the number of HTTP calls.
        # This means tests run faster,
        # but in production (where total list size >200k)
        # it is fewer HTTP calls to fetch each email individually
        # since most segments are small (<500 emails).
        $self->init_mailing_list;

        $debug and warn "list_member_count=" . $self->list_member_count;
        $debug and warn "list_filter_max=" . $self->list_filter_max;
        $debug and warn "segment_size=" . $segment_size;

        # first rule: compare total list size to production (list_filter_max)
        my $use_list_filter
            = $self->list_member_count < $self->list_filter_max;

        # second rule: if the segment is bigger than list_filter_max
        # (as with a large production mailing)
        # then it is fewer HTTP calls to fetch the whole list and filter.
        $use_list_filter = 1 if $segment_size > $self->list_filter_max;

        if ($use_list_filter) {
            $debug and warn "use list_member_filter for pull_list";
            $self->_list_member_filter( \%emails, $member_checker, $sem_it );
        }
        else {
            $debug and warn "use fetch_members for pull_list";
            $self->_fetch_members( \%emails, $member_checker, $sem_it );
        }

        # any emails marked 0 are not at mailchimp
        for my $email ( keys %emails ) {
            next if $emails{$email} == 1;
            $stats->{not_in_mailchimp}->{$email} = time();
        }
    }

    $debug and warn dump($stats);

    # now insert/update src_org_email rows in AIR
    for my $status ( keys %$stats ) {
        for my $addr ( keys %{ $stats->{$status} } ) {
            my $updated_at = $stats->{$status}->{$addr};
            if ( $self->_update_soe( $addr, $status, $updated_at ) ) {
                $debug
                    and warn
                    "update_soe OK for $addr [$status] [$updated_at]";
                $results{$status}++;
            }
            else {
                $debug and warn "ignored for $addr [$status] [$updated_at]";
                $results{ignored}++;
            }
        }
    }

    # return the results
    $debug and warn dump \%results;

    return \%results;
}

sub _fetch_members {
    my ( $self, $emails, $member_checker, $sem_it ) = @_;
    while ( my $sem = $sem_it->next ) {
        my $email = lc $sem->sem_email;
        my $resp  = $self->member($email);
        if ( $resp->{code} eq '404' ) {
            $emails->{$email} = 0;
            next;
        }
        my $member = $resp->{content};
        $member_checker->($member);
    }
}

sub _list_member_filter {
    my ( $self, $emails, $member_checker, $sem_it ) = @_;
    while ( my $sem = $sem_it->next ) {
        my $email = lc $sem->sem_email;
        $emails->{$email} = 0;
    }
    $self->list_members($member_checker);
}

=head2 sync_list( I<options> )

The real workhorse.  Reconciles (so_status + sem_status) vs soe_status.  Takes
the same options as pull_list.

I<options> may include:

=over

=item B<source>

Single or array of sources to sync (will find all src_emails)

=item B<email>

Single or array of emails to sync

=item B<all>

True to sync ALL changes EVER for this mailing list

=item B<since>

Pull changes >= timestamp. Pass 1 to default to the latest
soe_status_dtim found for this org. This should be passed as the
SERVER's timezone.

=item B<dry_run>

Don't actually update anything in mailchimp - just pull the
changes to AIR. The return value will be whatever pull_list
returned instead of the usual push_list return value.

=item B<debug>

Debug output

=back

=cut

sub sync_list {
    my $self = shift;
    my $opts = {@_};

    my %timings;
    my $start_time = Time::HiRes::time();

    # pull things
    my $resp = $self->pull_list(%$opts);

    $timings{pull_list}
        = sprintf( "%0.5f", Time::HiRes::time() - $start_time );
    $start_time = Time::HiRes::time();

    # if we specified "since", we need to use the actual pulled emails,
    # since push_list doesn't support that argument
    if ( $opts->{since} && !$opts->{source} ) {
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
                                my $member = $self->member( $sem->sem_email );
                                if ( $member->{code} eq '200' ) {
                                    my $row = $member->{content};
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
                                        $sact->sact_notes( $row->{reason}
                                                || $row->{reason_text} );
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

    $timings{db_sync} = sprintf( "%0.5f", Time::HiRes::time() - $start_time );
    $start_time = Time::HiRes::time();

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

    $timings{push_list}
        = sprintf( "%0.5f", Time::HiRes::time() - $start_time );
    $start_time = Time::HiRes::time();

    # cleanup src_org_emails where the src_org DNE
    map { $_->delete() } @soe_cleanup;

    $timings{cleanup} = sprintf( "%0.5f", Time::HiRes::time() - $start_time );

    $resp->{timings} = \%timings if $opts->{timings};

    # return result of either push or pull
    return $resp;
}

=head2 add_segment(I<name>, I<array_ref_of_emails>)

Creates a new segment with I<name> consisting of members I<array_ref_of_emails>.
If I<array_ref_of_emails> is undef will safely default to an empty array.

=cut

sub add_segment {
    my $self    = shift;
    my $name    = shift or confess "segment name required";
    my $members = shift || [];

    $self->api->add_segment(
        list_id        => $self->list_id,
        name           => $name,
        static_segment => $members,
    );
}

=head2 add_segment_members(I<segment_id>, I<array_ref_of_emails>)

Adds I<array_ref_of_emails> to the segment with I<segment_id>.

=cut

sub add_segment_members {
    my $self       = shift;
    my $segment_id = shift or confess "segment_id required";
    my $emails     = shift or confess "array ref of emails required";

    $self->api->batch_segment(
        list_id        => $self->list_id,
        segment_id     => $segment_id,
        members_to_add => $emails,
    );
}

sub _create_unique_segment {
    my ( $self, $name, $results ) = @_;

    # normalize the segment name (max len 50, so leave room)
    ( my $norm_name = substr( $name, 0, 44 ) ) =~ s/\W+/\-/g;
    $results->{name} = $norm_name;

    # Mailchimp no longer enforces unique names, so we do it ourselves.
    my $resp = $self->api->segments( list_id => $self->list_id );
    my %existing_segments
        = map { $_->{name} => $_->{id} } @{ $resp->{content}->{segments} };
    if ( exists $existing_segments{ $results->{name} } ) {
        $results->{name} .= '-' . AIR2::Utils::random_str();
    }

    $resp = $self->add_segment( $results->{name} );
    $self->debug and warn "add_segment: " . $self->debug_response($resp);

    unless ( $results->{id} = $resp->{content}->{id} ) {
        confess "Failed to create segment: " . dump($resp);
    }
}

=head2 make_segment( I<options> )

Create a static segment containing a certain subset of emails.  Will return
the segment ID, along with any errors that occurred (most often that you have
a source that's unsubscribed from this mailing list).

I<options> may include:

=over

=item B<name>

A unique-ish name for the segment.  If the passed name is already
taken, this method will add random characters to the end in an
attempt to make it unique.

=item B<source>

Source or sources in the segment (will find primary emails)

=item B<email>

Email addresses in the segment

=item B<bcc>

Email addresses to include in the segment, but not the counts.
These should ALWAYS be valid emails.

=back

=cut

sub make_segment {
    my $self = shift;
    my $opts = {@_};
    $opts->{name} or confess "Segment name required";
    if ( !$opts->{source} and !$opts->{email} ) {
        confess "Sources or emails required";
    }

    # sanitized results
    my %results = (
        id        => 0,
        name      => 0,
        added     => 0,
        skipped   => 0,
        skip_list => [],    # refs to sources skipped
    );

    $self->_create_unique_segment( $opts->{name}, \%results );

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
    my $resp;
    while ( my @chunk = $chunk_iter->() ) {
        $resp = $self->add_segment_members( $results{id}, \@chunk );
        $self->debug
            and warn "add_segment_members: " . $self->debug_response($resp);
        $results{added} += $resp->{content}->{total_added};

        # the API docs claim 'errors' is populated with skipped emails,
        # but testing shows otherwise. Do it both ways.
        for my $err ( @{ $resp->{content}->{errors} } ) {
            my $emails_skipped = $err->{email_addresses};
            my $err_msg        = $err->{error};
            for my $email_skipped (@$emails_skipped) {
                $skipped_emails{$email_skipped} = $err_msg;
            }
        }

        my %emails_sent = map { $_ => 1 } @chunk;
        my %emails_added = map { $_->{email_address} => 1 }
            @{ $resp->{content}->{members_added} };
        for my $sent ( keys %emails_sent ) {
            if ( !exists $emails_added{$sent} ) {
                $skipped_emails{$sent} = 1;
            }
        }
    }

    # figure out what we actually processed/skipped
    if ( $opts->{email} ) {
        $results{skip_list}
            = [ map { [ $_, $skipped_emails{$_} ] } keys %skipped_emails ];
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
                    push @{ $results{skip_list} }, [ $src, 1 ];
                }
            }
            else {
                $results{skipped}++;
                push @{ $results{skip_list} }, [ $src, 1 ];
            }
        }
    }

    # add the BCC's (force subscribe them to the list)
    if ( $opts->{bcc} && scalar @{ $opts->{bcc} } > 0 ) {
        for my $addr ( @{ $opts->{bcc} } ) {
            $self->subscribe( [$addr] );
        }
        $self->add_segment_members( $results{id}, $opts->{bcc} );
    }

    # return the results
    return \%results;
}

=head2 create_campaign(I<template>, I<segment_id>)

Create a new campaign.

=cut

sub create_campaign {
    my $self       = shift;
    my $template   = shift or confess 'template required';
    my $segment_id = shift or confess 'segment_id required';

    my %campaign = ();
    $campaign{add} = $self->api->add_campaign(
        type       => 'regular',
        recipients => {
            list_id      => $self->list_id,
            segment_opts => {
                match            => 'all',
                saved_segment_id => $segment_id + 0,
                conditions       => [
                    {   op    => 'static_is',
                        field => 'static_segment',
                        value => $segment_id + 0,
                    }
                ],
            }
        },
        settings => {
            subject_line  => $template->email_subject_line,
            reply_to      => $template->email_from_email,
            from_name     => $template->email_from_name,
            inline_css    => \1,
            generate_text => \1,                              # TODO ??
        },
    );
    if ( $campaign{add}->{code} eq '200' ) {
        $campaign{id} = $campaign{add}->{content}->{id};
        $campaign{count}
            = $campaign{add}->{content}->{recipients}->{recipient_count};
        $campaign{content} = $self->api->set_campaign_content(
            campaign_id => $campaign{id},
            html        => $template->compile_html_body()
        );
    }
    return \%campaign;
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
    $opts->{template} or confess "Email template record required";
    $opts->{segment}  or confess "Segment id required";
    confess 'template must be an AIR2::Email object'
        unless $opts->{template}->isa('AIR2::Email');
    my $stat = $opts->{template}->email_status;
    confess "Email not active" if ( $stat ne 'A' && $stat ne 'Q' );

    $self->create_campaign( $opts->{template}, $opts->{segment} );
}

=head2 send_campaign( I<options> )

Send a campaign - either now, or sometime in the future.

* B<campaign> - ID of the campaign

* B<delay>    - an optional dtim to delay sending until

=cut

sub send_campaign {
    my $self = shift;
    my $opts = {@_};
    $opts->{campaign} or confess "campaign id required";

    # send now, or a bit later on
    if ( $opts->{delay} ) {
        my $epoch = str2time( $opts->{delay} );
        confess "Invalid delay specified: $opts->{delay}" unless $epoch;

        # round up to the nearest interval
        my $interval_seconds = INCREMENT_DELAY * 60;
        if ( my $diff = $epoch % $interval_seconds ) {
            $epoch += $interval_seconds - $diff;
        }
        my $date_utc = DateTime->from_epoch(
            epoch     => $epoch,
            time_zone => $AIR2::Config::TIMEZONE,
        );
        $date_utc->set_time_zone('UTC');
        return $self->api->schedule_campaign(
            campaign_id   => $opts->{campaign},
            schedule_time => $date_utc->strftime("%Y-%m-%d %H:%M:%S"),
        );
    }
    else {
        return $self->api->send_campaign( campaign_id => $opts->{campaign} );
    }
}

#
# PRIVATE METHODS
#

# convert options to a src_org_email iterator
sub _get_soe_iterator {
    my $self = shift;
    my $opts = shift or confess "options required";

    # argument exclusivity
    my %excl = map { $_ => 1 } qw(source email all);
    if ( scalar( grep { $excl{$_} } keys %{$opts} ) != 1 ) {
        confess 'Invalid arguments';
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
sub _get_sem_iterator_query {
    my $self = shift;
    my $opts = shift or confess "options required";

    # argument exclusivity
    my %excl = map { $_ => 1 } qw(source email src_id);
    if ( scalar( grep { $excl{$_} } keys %{$opts} ) != 1 ) {
        confess 'Invalid arguments';
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

    return $query;
}

sub _get_sem_iterator {
    my $self = shift;
    my $opts = shift or confess "options required";

    my $query = $self->_get_sem_iterator_query($opts);

    # get iterator
    return AIR2::SrcEmail->fetch_all_iterator( query => $query );
}

# convert options to a src_org_cache iterator
sub _get_soc_iterator {
    my $self = shift;
    my $opts = shift or confess "options required";

    my %exclusive = map { $_ => 1 } qw(source email all);
    my $exclusive_count = 0;
    for my $opt ( keys %$opts ) {
        $exclusive_count++ if exists $exclusive{$opt};
    }
    confess 'Invalid arguments: ' . dump( [ keys %$opts ] )
        if $exclusive_count > 1;

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
    my $email  = shift or confess "email address required";
    my $status = shift or confess "status required";
    my $dtim   = shift or confess "dtim required for $email ($status)";

    # TODO: optimize these lookups somehow
    my $sem = AIR2::SrcEmail->new( sem_email => $email );
    return 0 unless ( $sem->load_speculative );

    #warn "found $email";

    my $soe = AIR2::SrcOrgEmail->new(
        soe_sem_id => $sem->sem_id,
        soe_org_id => $self->org->org_id,
        soe_type   => 'M',
    );
    my $exists = $soe->load_speculative;
    my $old_status = $exists ? $soe->soe_status : '';

    #warn "old_status:$old_status  status:$status";

    if ( !exists $SOE_STATUS_MAP{$status} ) {
        warn "No mapped status for '$status'";
        return 0;
    }

    # delete from air when DNE in mailchimp
    if ( $SOE_STATUS_MAP{$status} eq 'X' ) {
        return 0 unless $exists;    #ignore
        $soe->delete;
        return ( $old_status eq 'A' ) ? 1 : 0;
    }

    # update status/dtim (convert from UTC)
    $soe->soe_status( $SOE_STATUS_MAP{$status} );

    #warn "soe_status set to " . $soe->soe_status;
    my $epoch = str2time( $dtim, 'UTC' ) || time();
    $soe->soe_status_dtim($epoch);
    $soe->save;

    # return changed
    return $old_status ne $soe->soe_status;
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
    my $sem  = shift or confess "src_email required";
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
