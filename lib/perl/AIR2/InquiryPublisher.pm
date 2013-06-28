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

package AIR2::InquiryPublisher;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Config;
use AIR2::Inquiry;
use AIR2::Question;
use AIR2::State;
use AIR2::Country;
use Carp;
use File::Slurp;
use File::Find;
use JSON;
use Path::Class;
use Template;
use Encode;
use Search::Tools::UTF8;
use Scalar::Util qw( blessed );

umask(0002);    # group-writable

=head2 safe_uuid( I<uuid> )

Returns shell-safe string for I<uuid>.

=cut

sub safe_uuid {
    my $self = shift;
    my $uuid = shift;
    $uuid =~ s/[^\-\.\w]+//g;
    return $uuid;
}

my @default_formats = qw(json html);

=head2 publish( I<inquery_uuid>, [I<formats>] )

Valid formats are:
   json:      output a query as json
   html:      output a query using the default html template

I<inquiry_uuid> may be a string for the column value,
or an AIR2::Inquiry object.

=cut

sub publish {

    my ( $self, $inq_uuid, @formats ) = @_;

    croak('no uuid') unless $inq_uuid;

    @formats = @formats || @default_formats;

    my $inquiry;
    if ( blessed($inq_uuid) and $inq_uuid->isa('AIR2::Inquiry') ) {
        $inquiry  = $inq_uuid;
        $inq_uuid = $inquiry->inq_uuid;
    }
    else {
        $inquiry = AIR2::Inquiry->new( inq_uuid => $inq_uuid )
            ->load( with => qw( questions ) );
    }

    # T type is reserved for testing
    if ( $inquiry->inq_type !~ m/^[FQ]/ and $inquiry->inq_type ne 'T' ) {
        croak(
            "Can't publish inquiry $inq_uuid of type " . $inquiry->inq_type );
    }

    # scrub uuid for sad shell characters
    $inq_uuid = $self->safe_uuid($inq_uuid);

    my $output_dir
        = AIR2::Config::get_app_root()->subdir('public_html/querys');

    foreach my $format (@formats) {

        my $output = $self->get_output( $format, $inquiry );

        my $output_file = $output_dir->file( $inq_uuid . '.' . $format );

        $output_file->remove();    # do not find

        $output_file->spew( iomode => '>:raw', $output );
    }

    $inquiry->inq_stale_flag(0);
    $inquiry->save();

    return 1;
}

=head2 unpublish( I<inquery_uuid>, [I<formats>] )

Valid formats are:
   json:      output a query as json
   html:      output a query using the default html template

I<inquiry_uuid> may be a string for the column value,
or an AIR2::Inquiry object.

=cut

sub unpublish {

    my ( $self, $inq_uuid, @formats ) = @_;

    @formats = @formats || @default_formats;

    croak('no uuid') unless $inq_uuid;

    my $inquiry;
    if ( blessed($inq_uuid) and $inq_uuid->isa('AIR2::Inquiry') ) {
        $inquiry  = $inq_uuid;
        $inq_uuid = $inquiry->inq_uuid;
    }

    # scrub uuid for sad shell characters
    $inq_uuid = $self->safe_uuid($inq_uuid);

    my $output_dir
        = AIR2::Config::get_app_root()->subdir('public_html/querys');

    foreach my $format (@formats) {

        my $output_file = $output_dir->file( $inq_uuid . '.' . $format );
        $output_file->remove();

    }

    return 1;
}

=head2 get_preview( I<inquery_uuid>, [I<format>] )

Valid formats are:
   json:      output a query as json
   html:      output a query using the default html template

<format> defaults to html

I<inquiry_uuid> may be a string for the column value,
or an AIR2::Inquiry object.

Returns a Perl UTF-8 encoded character string.

=cut

sub get_preview {

    my ( $self, $inq_uuid, $format ) = @_;
    croak('no uuid') unless $inq_uuid;

    $format = $format || 'html';

    my $inquiry;
    if ( blessed($inq_uuid) and $inq_uuid->isa('AIR2::Inquiry') ) {
        $inquiry  = $inq_uuid;
        $inq_uuid = $inquiry->inq_uuid;
    }
    else {
        $inquiry = AIR2::Inquiry->new( inq_uuid => $inq_uuid )
            ->load( with => qw( questions ) );
    }

    my $output = $self->get_output( $format, $inquiry );

    # $output is a string of octets
    # turn it back into a Perl utf8 character string
    return to_utf8($output);
}

=head2 get_output( I<format>, I<inquery> )

Valid formats are:
   json:      output a query as json
   html:      output a query using the default html template

Returns a UTF-8 encoded octect string.

=cut

sub get_output {
    my $self   = shift;
    my $format = shift;
    my $inq    = shift;

    my $base_url = AIR2::Config::get_constant('AIR2_BASE_URL');
    $base_url .= '/' unless $base_url =~ m/\/$/;

    my $inq_uuid = $inq->inq_uuid;

    # scrub uuid for sad shell characters
    $inq_uuid = $self->safe_uuid($inq_uuid);

    if ( $format eq 'html' ) {

        my $output = '';
        my $template_dir
            = AIR2::Config::get_app_root()->subdir('templates')->resolve;
        my $public_html
            = AIR2::Config::get_app_root()->subdir('public_html')->resolve;
        my $template = Template->new(
            {   ENCODING     => 'utf8',
                INCLUDE_PATH => [ "$template_dir", "$public_html" ],
            }
        );

        $template->process(
            'inquiry.html.tt',
            {   inquiry   => $inq,
                base_url  => $base_url,
                timestamp => time(),
                states    => AIR2::State->get_all_by_code,
                countries => AIR2::Country->get_all_by_code,
            },
            \$output,
            { binmode => ':utf8' }
        ) or die $template->error();

        # co-erce into a string of bytes (octets)
        return Encode::encode( "UTF-8", to_utf8($output) );
    }

    if ( $format eq 'json' ) {

        my %struct;
        if ( $inq->inq_expire_dtim && $inq->inq_expire_dtim->epoch <= time() )
        {
            $struct{error} = 'Expired at ' . $inq->inq_expire_dtim;
            $struct{msg}
                = $inq->inq_expire_msg || $inq->get_default_expire_msg();
        }
        else {

            my $authors = $inq->get_authors;
            my @authors;
            for my $author (@$authors) {
                my $email = $author->get_primary_email();
                push @authors,
                    {
                    first => $author->user_first_name,
                    last  => $author->user_last_name,
                    email => $email ? $email->uem_address : undef,
                    };
            }

            %struct = (
                action => sprintf( "%sq/%s", $base_url, $inq_uuid ),
                method => 'POST',
                source_url => AIR2::Config::get_constant('AIR2_MYPIN2_URL'),
                authors    => \@authors,
                query      => $inq->as_tree( depth => 0 ),
                questions  => [ map { $_->to_tree() } @{ $inq->questions } ],
                projects   => [
                    map {
                        {   uuid         => $_->prj_uuid,
                            name         => $_->prj_name,
                            display_name => $_->prj_display_name,
                            orgs         => [
                                map { $_->org_name, } @{ $_->organizations }
                            ]
                        }
                    } grep {defined} @{ $inq->projects }
                ],
                orgs => [
                    map {
                        {   uuid         => $_->org_uuid,
                            name         => $_->org_name,
                            display_name => $_->org_display_name,
                            logo         => $_->org_logo_uri,
                            site         => $_->org_site_uri,
                            color        => $_->org_html_color,
                        }
                    } grep {defined} @{ $inq->organizations }
                ],
            );

            # redact some columns for security or simplicity
            delete $struct{query}->{inq_id};
            delete $struct{query}->{inq_cre_user};
            delete $struct{query}->{inq_upd_user};
            delete $struct{query}->{cre_user};
            delete $struct{query}->{questions};
            delete $struct{query}->{authors};
            delete $struct{query}->{watchers};

            $struct{query}->{locale} = $inq->locale->loc_key || 'en_US';

            for my $q ( @{ $struct{questions} } ) {
                delete $q->{ques_id};
                delete $q->{ques_inq_id};
                delete $q->{ques_cre_user};
                delete $q->{ques_upd_user};
            }

        }

        # JSON always returns string of bytes (octets)
        return encode_json( \%struct );
    }

    return 0;
}

1;
