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

package AIR2::Question;
use strict;
use base qw(AIR2::DB);
use Carp;
use AIR2::Config;
use JSON;
use File::Slurp;
use Search::Tools::UTF8;
use Encode;
use Data::Dump qw( dump );

# question templates
my $QUESTION_TEMPLATES
    = decode_json(
    scalar read_file( AIR2::Config::get_constant('AIR2_QB_TEMPLATES_FILE') )
    );

__PACKAGE__->meta->setup(
    table => 'question',

    columns => [
        ques_id      => { type => 'serial',  not_null => 1 },
        ques_inq_id  => { type => 'integer', default  => '0', not_null => 1 },
        ques_dis_seq => { type => 'integer', default  => 20, not_null => 1 },
        ques_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1,
        },
        ques_value => { type => 'text', length => 65535, not_null => 1, },
        ques_cre_user => { type => 'integer', not_null => 1 },
        ques_upd_user => { type => 'integer' },
        ques_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        ques_upd_dtim => { type => 'datetime' },
        ques_uuid     => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        ques_type => {
            type     => 'character',
            default  => 'T',
            not_null => 1,
            length   => 1,
        },
        ques_choices     => { type => 'text',    length => 65535, },
        ques_pmap_id     => { type => 'integer' },
        ques_locks       => { type => 'varchar', length => 255 },
        ques_public_flag => {
            type     => 'integer',
            default  => '0',
            not_null => 1,
        },
        ques_resp_type => {
            type     => 'character',
            default  => 'S',
            length   => 1,
            not_null => 1
        },
        ques_resp_opts => { type => 'varchar', length => 255 },
        ques_template  => { type => 'varchar', length => 40 },
    ],

    primary_key_columns => ['ques_id'],

    unique_key => ['ques_uuid'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { ques_cre_user => 'user_id' },
        },

        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { ques_inq_id => 'inq_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { ques_upd_user => 'user_id' },
        },
    ],

    relationships => [
        src_responses => {
            class      => 'AIR2::SrcResponse',
            column_map => { ques_id => 'sr_ques_id' },
            type       => 'one to many',
        },

        tank_responses => {
            class      => 'AIR2::TankResponse',
            column_map => { ques_id => 'sr_ques_id' },
            type       => 'one to many',
        },
    ],
);

=head2 json_encoded_columns

Returns array ref of column names that are stored as JSON-encoded strings.

=cut

sub json_encoded_columns {
    return [qw( ques_resp_opts ques_choices ques_locks )];
}

=head2 save

Overrides base method to enforce json_encoded_columns().

=cut

sub save {
    my $self = shift;

    # make sure some columns are json-encoded
    for my $col ( @{ $self->json_encoded_columns } ) {
        if ( defined $self->$col and ref $self->$col ) {
            $self->$col( encode_json( $self->$col ) );
        }
    }
    return $self->SUPER::save(@_);
}

=head2 to_tree

Returns Question object as a hash ref with all JSON-encoded
column values inflated to Perl data structures.

=cut

sub to_tree {
    my $self = shift;

    my $tree = $self->as_tree( depth => 0 );

    for my $col ( @{ $self->json_encoded_columns } ) {
        if (    defined $tree->{$col}
            and length $tree->{$col}
            and lc( $tree->{$col} ) ne 'null' )
        {

            #warn "$tree->{ques_uuid}: $col => $tree->{$col}\n";
            eval {
                $tree->{$col}
                    = decode_json( encode_utf8( to_utf8( $tree->{$col} ) ) );
            };
            if ($@) {
                warn sprintf(
                    "Failed to decode JSON for question %s column %s value %s\n",
                    $self->ques_uuid, $col, $tree->{$col} );
            }
        }
    }

    return $tree;
}

=head2 new_from_template( I<template_name>[, I<locale>] )

Construct a new Question object based on I<template_name>.
Returns same as new() with many columns set according
to values in C<AIR2_QB_TEMPLATES_FILE>.

Optional I<locale> will pick a ques_value that matches.
Default is B<en_US>.

=cut

sub new_from_template {
    my $class  = shift;
    my $key    = shift or croak "template name required";
    my $locale = shift || 'en_US';

    if ( !exists $QUESTION_TEMPLATES->{$key} ) {
        die "No such template: $key";
    }
    my %t = %{ $QUESTION_TEMPLATES->{$key} };
    $t{ques_template} = $key;
    for ( keys %t ) {
        delete $t{$_} unless m/^ques_/;
        next if !defined $t{$_};

        #warn "$_ => $t{$_} " . ref( $t{$_} );
        if ( ref $t{$_} eq 'JSON::XS::Boolean' ) {
            $t{$_} = 0 if $t{$_} eq '0';
            $t{$_} = 1 if $t{$_} eq '1';
        }

        if ( $_ eq 'ques_value' and ref $t{$_} ) {
            $t{$_} = $t{$_}->{$locale};
        }

        $t{$_} = encode_json( $t{$_} ) if ref $t{$_};
    }

    #dump \%t;

    return $class->new(%t);
}

1;

