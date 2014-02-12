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

package AIR2::DB;
use strict;
use warnings;
use base qw( Rose::DB::Object );
use base qw( Rose::DB::Object::Helpers );
use base qw( Rose::DBx::Object::MoreHelpers );
use base qw( Rose::DBx::Object::Indexed );
use AIR2::DBManager;
use Carp;
use Data::Dump qw( dump );
use AIR2::Utils;
use Scalar::Util qw( blessed );
use Search::Tools::UTF8;

sub init_db {
    my $self = shift;
    my $db   = AIR2::DBManager->new_or_cached();
    return $db;
}

sub _date_as_ymd {
    my ( $self, $col ) = @_;
    my $dtim = $self->$col;
    if ( defined $dtim ) {
        return $dtim->ymd('');
    }
    return '';
}

my @usernames
    = ( $ENV{AIR2_USERNAME}, $ENV{REMOTE_USER}, $ENV{USER}, 'AIR2SYSTEM' );
my $current_user;

sub current_user {
    require AIR2::User;    # defer till run time
    my $class = shift;
    return $current_user if defined $current_user;
    my $user;
    for my $u (@usernames) {
        if ( defined $u ) {
            $user = AIR2::User->new( user_username => $u );
            $user->load_speculative;
            if ( $user->user_id ) {
                $current_user = $user;
                return $user;
            }
        }
    }
    croak "Could not find a current user";
}

sub set_current_user {
    my $class = shift;
    $current_user = shift;
}

sub set_admin_update {
    my $self = shift;
    my $flag = shift || 0;
    $self->{__air2_admin_update} = $flag;
}

sub delete {
    my $self = shift;
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::delete(@_);
}

sub insert {
    my $self = shift;
    $self->apply_defaults(1);
    $self->normalize_text();
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::insert(@_);
}

sub update {
    my $self = shift;
    my %arg  = @_;
    $arg{changes_only} = 1;
    $self->apply_defaults;
    $self->normalize_text();
    $self->db( $self->db->get_write_handle() );
    $self->SUPER::update(%arg);
}

sub save {
    my $self = shift;
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::save(@_);
}

sub normalize_text {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $set_method = $column->mutator_method_name;
        my $get_method = $column->accessor_method_name;

        # skip date columns (strings that shouldn't be normalized)
        next if ( $set_method =~ /_dtim$|_date$/ );

        my $val = $self->$get_method;
        if ( defined $val and length $val and $val =~ /\S/ ) {
            $self->$set_method( to_utf8($val) );
        }
    }
    return $self;
}

sub apply_defaults {
    my $self = shift;
    if ( $self->{__air2_admin_update} ) {
        return $self;    # do not set values
    }
    my $is_new = shift;
    my $now    = DateTime->now()->set_time_zone( AIR2::Config->get_tz() );
    my $user   = $self->current_user;
    for my $column ( $self->meta->columns ) {
        my $name       = $column->name;
        my $set_method = $column->mutator_method_name;
        my $get_method = $column->accessor_method_name;

        # allow to be already set
        if (    defined $self->$get_method
            and length $self->$get_method
            and $self->$get_method =~ /\S/
            and $set_method !~ /_upd_/ )
        {
            next;
        }

        # defaults
        if ( $is_new && $name =~ m/_cre_dtim$/ ) {
            $self->$set_method($now);
        }
        if ( $is_new && $name =~ m/_cre_user$/ ) {
            $self->$set_method( $user->user_id );
        }
        if ( $name =~ m/_upd_dtim$/ ) {
            $self->$set_method($now);
        }
        if ( $name =~ m/_upd_user$/ ) {
            $self->$set_method( $user->user_id );
        }
        if ( $is_new && $name =~ m/_uuid$/ ) {
            $self->$set_method( AIR2::Utils->random_str(12) );
        }
    }
    return $self;
}

sub get_uuid_column {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $name = $column->name;
        if ( $name =~ m/_uuid$/ ) {
            return $name;
        }
    }
    croak "No uuid column defined for $self";
}

sub __get_cre_user_column {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $name   = $column->name;
        my $method = $column->accessor_method_name;
        if ( $name =~ m/_cre_user$/ ) {
            return $method;
        }
    }
    return;
}

sub __set_cre_user_column {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $name   = $column->name;
        my $method = $column->mutator_method_name;
        if ( $name =~ m/_cre_user$/ ) {
            return $method;
        }
    }
    return;
}

sub get_tags {
    my $self     = shift;
    my $ref_type = $self->tag_ref_type;
    my $pk       = $self->primary_key_value;
    my $tags     = AIR2::Tag->fetch_all(
        query => [ tag_ref_type => $ref_type, tag_xid => $pk ] );
    my @tagmasters = map { $_->tagmaster } @$tags;
    return \@tagmasters;
}

# super-mega-cache the tag/tag_master tables, to cut down on the
# ridiculous amount of time it adds to building search indexes
my %tag_name_cache;
my %tag_table_cache;

sub get_tags_from_super_cache {
    my $self = shift;
    my $dbh  = $self->db->retain_dbh;

    # memoize tag names
    unless (%tag_name_cache) {
        my $sel = "select tm_id, tm_name, iptc_name from tag_master "
            . "left join iptc_master on (tm_iptc_id=iptc_id)";
        my $names = $dbh->selectall_arrayref($sel);
        for my $row ( @{$names} ) {
            my $name = $row->[2] || $row->[1];
            $name =~ s,.+/\ *,, if $row->[2];    # redmine #2793
            $tag_name_cache{ $row->[0] } = $name;
        }
    }

    # cache THE ENTIRE tag table
    unless (%tag_table_cache) {
        my $sel = "select tag_ref_type, tag_xid, tag_tm_id from tag";
        my $all = $dbh->selectall_arrayref($sel);
        for my $row ( @{$all} ) {
            push @{ $tag_table_cache{ $row->[0] }->{ $row->[1] } }, $row->[2];
        }
    }

    # get the array of tag strings
    my $tm_ids = $tag_table_cache{ $self->tag_ref_type }
        ->{ $self->primary_key_value };
    my @tag_names = map { $tag_name_cache{$_} } @{$tm_ids};
    return \@tag_names;
}

# memoize fetching of AIR2::User objects,
# esp in case of building search indexes where
# we end up fetching the same objects 1000s of times.
my %user_cache;

sub get_cre_user {
    my $self   = shift;
    my $method = $self->__get_cre_user_column;
    my $fk     = $self->$method;
    if ( exists $user_cache{$fk} ) {
        return $user_cache{$fk};
    }
    $user_cache{$fk} = $self->cre_user;
    return $user_cache{$fk};
}

sub set_cre_user {
    my $self = shift;
    my $user = shift or croak "User required";
    if ( !blessed($user) ) {
        if ( $user =~ m/\D/ ) {
            $user = AIR2::User->new( user_username => $user )->load;
        }
        else {
            $user = AIR2::User->new( user_id => $user )->load;
        }
    }

    # cache for subsequent gets
    my $existing_user_id = $user->user_id;
    if ( !exists $user_cache{$existing_user_id} ) {
        $user_cache{$existing_user_id} = $user;
    }

    my $method = $self->__set_cre_user_column;
    return $self->$method($user);
}

sub get_searchable_rels { [] }

=head2 requires_indexing_ids

Returns array ref of primary key id values representing objects that need indexing.

=cut

sub requires_indexing_ids {
    my $self     = shift;
    my $mod_date = shift or croak "mod_date required";
    my $count    = shift || 0;
    if ( !$mod_date->isa('DateTime') ) {
        croak "mod_date must be a DateTime object";
    }
    my $dt = join( ' ', $mod_date->ymd('-'), $mod_date->hms(':') );

    my $debug = $Rose::DB::Object::Manager::Debug;

    my $this_table_name = $self->meta->table;
    my %ids;

    # use raw sql for speed, avoiding object overhead
    my $dbh = $self->init_db->retain_dbh;

    # look first in this table
    my $pk_name = $self->meta->primary_key_column_names->[0];
    my $upd_dtim;
    for my $col ( $self->meta->columns ) {
        if ( $col->name =~ m/_upd_dtim$/ ) {
            $upd_dtim = $col->name;
            last;
        }
    }
    my ( $sql, $bind ) = Rose::DB::Object::QueryBuilder::build_select(
        dbh          => $dbh,
        tables       => [$this_table_name],
        columns      => { $this_table_name => [ $upd_dtim, $pk_name ] },
        query        => [ $upd_dtim => { ge => $dt } ],
        select       => $pk_name,
        query_is_sql => 1,
    );
    my $sth = $dbh->prepare($sql);
    $sth->execute(@$bind);
    while ( my $r = $sth->fetch ) {
        $ids{ $r->[0] }++;
    }

    # now child tables
RELNAME: for my $rel_name ( @{ $self->get_searchable_rels } ) {

        #$debug = $rel_name =~ m/\./;    # TODO temporary

        next RELNAME if $rel_name =~ m/^SKIP/;

        $debug and warn '=' x 70, $/;

        my $rels = $self->find_relationship($rel_name);
        if ( !$rels ) {
            croak "No such relationship: $rel_name";
        }
        my ( @table_names, @columns, @query_args,
            $col_to_select, @clauses, $last_local_col, $last_fk_name, );

        my $iteration = 0;
    REL: for my $rel (@$rels) {
            my $rel_table;
            my $rel_col;
            my $fk_name;
            my $prev_local_col = $last_local_col;
            my $prev_fk_name   = $last_fk_name;
            $iteration++;
            if ( $rel->type eq 'one to many' ) {
                $rel_table = $rel->class->meta->table;
                my %mapping = %{ $rel->key_columns };
                $debug and warn sprintf( "mapping: %s\n", dump( \%mapping ) );
                ( $last_local_col, $fk_name ) = each %mapping;
                $last_fk_name = $fk_name;
            }
            elsif ( $rel->type eq 'one to one' ) {
                $rel_table = $rel->class->meta->table;
                my %mapping = %{ $rel->column_map };
                $debug and warn sprintf( "mapping: %s\n", dump( \%mapping ) );
                ( $last_local_col, $fk_name ) = each %mapping;
                $last_fk_name = $fk_name;
            }
            else {
                dump $rel->column_map;
                croak $rel->type . " rel type not yet supported: $rel_name";
            }
        COL: for my $col ( @{ $rel->class->meta->column_names } ) {
                if ( $col =~ m/_upd_dtim/i ) {
                    $rel_col = $col;
                    last COL;
                }
            }
            if ( !$rel_col ) {
            COL: for my $col ( @{ $rel->class->meta->column_names } ) {
                    if ( $col =~ m/_cre_dtim/i ) {
                        $rel_col = $col;
                        last COL;
                    }
                }
            }

            next RELNAME if !$rel_col;
            next RELNAME if $rel_table eq $this_table_name;

            # the assumption in doing raw sql fetch here
            # is that for 1000s of results, the object+method access
            # overhead is significant, and we just want the IDs.
            # That assumption is not profiled but seemed reasonable vis-a-vis
            # the difficulty of generating the sql.
            $debug
                and warn dump(
                {   "rel_name"       => $rel_name,
                    "rel_table"      => $rel_table,
                    "rel_col"        => $rel_col,
                    "last_local_col" => $last_local_col,
                    "prev_local_col" => $prev_local_col,
                    "prev_fk_name"   => $prev_fk_name,
                    "fk_name"        => $fk_name,
                }
                );

            $col_to_select = $fk_name unless $col_to_select;
            my @rel_columns = ( $fk_name, $rel_col );
            my $rel_query_args = $rel->query_args;
            if ( !$rel_query_args ) {
                $rel_query_args = [];
            }
            else {
                my %q = @$rel_query_args;
                $debug and dump \%q;
                push @rel_columns, keys %q;
            }

            push @table_names, $rel_table;
            push @columns, $rel_table => \@rel_columns;
            if ( scalar @$rels == 1 or $iteration == scalar(@$rels) ) {
                push @query_args, $rel_col => { ge => $dt };
            }
            push @query_args, @$rel_query_args;

            if ($prev_local_col) {
                push @clauses, "$last_local_col = $fk_name";
            }

            if ($debug) {
                warn "columns: " . dump( \@columns );
                warn "query_args: " . dump( \@query_args );
            }
        }
        my %builder_args = (
            tables  => \@table_names,
            columns => {@columns},
            query   => \@query_args,
            select  => $col_to_select,
            clauses => \@clauses,
        );
        if ($debug) {
            warn "builder_args: " . dump( \%builder_args );
        }
        my ( $sql, $bind ) = Rose::DB::Object::QueryBuilder::build_select(
            dbh => $dbh,
            %builder_args,
            query_is_sql => 1,
        );
        $debug and warn sprintf( "%s %s\n", $sql, dump($bind) );
        my $sth = $dbh->prepare($sql);
        $sth->execute(@$bind);
        my $local_count = 0;
        while ( my $r = $sth->fetch ) {
            $ids{ $r->[0] }++;
            $local_count++;
        }
        $debug and warn "found $local_count $rel_name\n";
    }

    if ($count) { return scalar keys %ids; }
    return [ keys %ids ];
}

sub find_relationship {
    my $self     = shift;
    my $rel_name = shift or croak "rel_name required";
    my $rel      = $self->meta->relationship($rel_name);
    return [$rel] if $rel;

    # dotted notation means we must recurse through
    # each segment to find the ultimate relationship
    my @parts = split( /\./, $rel_name );
    my $class = $self;
    my @rels;
    while (@parts) {
        my $part      = shift @parts;
        my $local_rel = $class->meta->relationship($part);
        if ($local_rel) {
            $class = $local_rel->class;

            #warn "$part => $class";
            push @rels, $local_rel;
        }
    }
    return \@rels;
}

sub flatten_with_dt {
    my $self = shift;
    return $self->as_tree( depth => 0 );
}

1;
