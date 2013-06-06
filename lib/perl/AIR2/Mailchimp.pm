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

use AIR2::Config;
use WWW::Mailchimp;
use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(
    qw(
      org
      )
);

__PACKAGE__->mk_ro_accessors(
    qw(
      api_key
      api
      org_sys_id
      list_id
      mailing_list
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
my $PAGE_SIZE = 10000;
my %ERRORS    = (
    List_InvalidUnsubMember   => 212,
    List_InvalidBounceMember  => 213,
    List_AlreadySubscribed    => 214,
    List_NotSubscribed        => 215,
    Email_AlreadySubscribed   => 230,
    Email_AlreadyUnsubscribed => 231,
    Email_NotExists           => 232,
    Email_NotSubscribed       => 233,
);

# singleton api (trying to create more produces errors)
my $API_KEY = AIR2::Config::get_constant('AIR2_MAILCHIMP_KEY');
my $API;

# constructor
sub init {
    my $self = shift;

    $self->SUPER::init(@_);
    $self->{api_key} = $API_KEY;

    # check
    croak "org required"                       unless ( $self->org );
    croak "unable to find a mailchimp api key" unless ( $self->api_key );

    # setup api singleton
    $API = WWW::Mailchimp->new( apikey => $API_KEY ) unless ($API);
    $self->{api} = $API;

    # get mailing list
    my $mailchimp_ids = $self->org->find_org_sys_id( { osid_type => 'M' } );
    $self->{org_sys_id} = shift @{$mailchimp_ids};
    if ( scalar @{$mailchimp_ids} > 0 ) {
        croak
          "too many mailchimp org_sys_ids for org_id=${\$self->org->org_id}";
    }
    unless ( $self->{org_sys_id} ) {
        croak "no mailchimp org_sys_id for org_id=${\$self->org->org_id}";
    }
    $self->{list_id} = $self->{org_sys_id}->osid_xuuid;

    # lookup the actual mailing list
    my $list = $API->lists( filters => { list_id => $self->{list_id} } );
    croak $list->{error} if $list->{error};
    $self->{mailing_list} = $list->{data}->[0];

    return $self;
}

=head2 push_list( I<options> )

Push changes from src_org_email to mailchimp. Makes no attempt to verify what's
in src_org_email... just blindly throws at Mailchimp.

* B<source> - Single or array of sources to push (will find all src_emails)

* B<email>  - Single or array of emails to push

* B<all>    - True to push ALL changes EVER for this mailing list

* B<delete> - True to delete unsubscribe emails from Mailchimp

=cut

sub push_list {
    my $self   = shift;
    my $opts   = {@_};
    my $delete = $opts->{delete} ? 1 : 0;
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

    # subscribes
    my $sub_iter = natatime( $PAGE_SIZE, keys %{$subs} );
    while ( my @chunk = $sub_iter->() ) {
        @chunk = map { { EMAIL => $_, EMAIL_TYPE => 'html' } } @chunk;

        my $resp = $API->listBatchSubscribe(
            id                => $self->{list_id},
            batch             => \@chunk,
            double_optin      => 0,
            # update_existing   => $force,
            replace_interests => 0,
        );
        $results{subscribed} += $resp->{add_count};
        $results{subscribed} += $resp->{update_count};

        # process individual error codes (we'll ignore some codes)
        for my $err ( @{ $resp->{errors} } ) {
            if ( $err->{code} == $ERRORS{List_AlreadySubscribed} ) {
                $results{ignored}++;
            }
            else {
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
            delete_member => $delete,
            send_goodbye  => 0,
            send_notify   => 0,
        );
        $results{unsubscribed} += $resp->{success_count};

        # process individual error codes (we'll ignore some codes)
        for my $err ( @{ $resp->{errors} } ) {
            if ( $err->{code} == $ERRORS{Email_NotExists} ) {
                $results{ignored}++;
            }
            else {
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

* B<since>  - Pull changes >= timestamp

=cut

sub pull_list {
    my $self   = shift;
    my $opts   = {@_};

    # map status => {email => dtim}
    my $stats = {
        subscribed   => {},
        unsubscribed => {},
        cleaned      => {},
    };

    # different strategy depending on arguments
    if ( $opts->{all} || $opts->{since} ) {

        # need to fetch each status with a separate api call
        for my $status ( keys %{ $stats } ) {
            my $start = 0;
            my $total = 0;

            do {
                my $resp = $API->listMembers(
                    id     => $self->{list_id},
                    status => $status,
                    since  => $opts->{since}, # 24 hour format in GMT
                    start  => $start,
                    limit  => $PAGE_SIZE, # limit 15K
                );

                $total = $resp->{total};
                $start = $start + $PAGE_SIZE;

                for my $row ( @{ $resp->{data} } ) {
                    my $email    = lc $row->{email};
                    my $gmt_dtim = $row->{timestamp};
                    $stats->{$status}->{$email} = $gmt_dtim;
                }
            }
            while ( $start < $total );
        }
    }
    else {

        # only really care about emails that exist in AIR
        my $sem_it = $self->_get_sem_iterator($opts);

        # unfortunately, API only handles 50-at-a-time
        my $chunk_iter = natatime( 50, $sem_it );
        while ( my @chunk = $chunk_iter->() ) {
            my %chunk = map { lc($_) => 1 } @chunk;
            my $resp = $API->listMemberInfo(
                id            => $self->{list_id},
                email_address => \@chunk,
            );

            for my $row ( @{ $resp->{data} } ) {
                my $email    = lc $row->{email};
                my $gmt_dtim = $row->{timestamp};
                my $status   = $row->{status};
                $stats->{$status}->{$email} = $gmt_dtim;
                delete $chunk{$email};
            }

            # emails not found on the mailchimp side
            for my $email ( keys %chunk ) {
                $stats->{not_in_mailchimp}->{$email} = time();
            }
        }
    }

    # now insert/update src_org_email rows in AIR
    # TODO
    #   - perl models ->load() ?
    #   - raw sql?
    #   - mysql importer?
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
    my %excl = map { $_ => 1 } qw(source email);
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

    # get iterator
    return AIR2::SrcEmail->fetch_all_iterator(query => $query);
}

1;
