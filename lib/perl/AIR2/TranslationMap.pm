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

package AIR2::TranslationMap;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'translation_map',

    columns => [
        xm_id      => { type => 'serial',  not_null => 1 },
        xm_fact_id => { type => 'integer', default  => '0', not_null => 1 },
        xm_xlate_from => { type => 'varchar', length => 128, not_null => 1 },
        xm_cre_dtim => { type => 'datetime' },
        xm_xlate_to_fv_id =>
            { type => 'integer', default => '0', not_null => 1 },
    ],

    primary_key_columns => ['xm_id'],

    foreign_keys => [
        fact => {
            class       => 'AIR2::Fact',
            key_columns => { xm_fact_id => 'fact_id' },
        },
        fact_value => {
            class       => 'AIR2::FactValue',
            key_columns => { xm_xlate_to_fv_id => 'fv_id' },
        },
    ],
);

# memoize
my %facts_cache;

sub find_translation {
    my $self    = shift;
    my $fact_id = shift or croak "fact_id required";
    my $text    = shift;
    if ( !defined $text or !length $text ) {
        return;
    }
    my $lc_text = lc($text);
    if (    exists $facts_cache{$fact_id}
        and exists $facts_cache{$fact_id}->{$lc_text} )
    {
        return $facts_cache{$fact_id}->{$lc_text};
    }

    my $matches = $self->fetch_all_iterator(
        query => [
            xm_fact_id    => $fact_id,
            xm_xlate_from => $lc_text,
        ]
    );
    my $trans = $matches->next;

    # cache, always storing *something*
    $facts_cache{$fact_id}->{$lc_text}
        = $trans ? $trans->xm_xlate_to_fv_id : undef;
    return $facts_cache{$fact_id}->{$lc_text};
}

1;

