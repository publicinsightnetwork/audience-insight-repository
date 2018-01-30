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

package AIR2::SearchUtils;
use strict;
use warnings;
use AIR2::Utils;
use AIR2::Config;
use AIR2::DBManager;
use AIR2::StaleRecord;
use Carp;
use Data::Dump qw( dump );
use Encode;
use Search::Tools::UTF8;
use Search::Tools::XML;
use File::Slurp;
use Path::Class;
use Rose::DateTime::Parser;
use Rose::DB::Object::Manager;
use Path::Class::File::Lockable;
use Unix::PID::Tiny;
use File::Copy;
use Compress::Zlib;
use MIME::Base64;
use Module::Load ();

=head1 NAME

AIR2::SearchUtils - utility functions for AIR2 search

=head1 SYNOPSIS

 my $last_mod_file = AIR2::SearchUtils::get_lockfile_on_xml_dir($dir);

 my $pk_hash = AIR2::SearchUtils::get_pks_to_index(
    lock_file   => $lock_file,
    class       => 'AIR2::SrcResponseSet',
    column      => 'srs_id',
    mod_since   => $mod_since,
    quiet       => $quiet,
    debug       => $debug,
    pk_filelist => $pk_filelist,
    argv        => \@ARGV,
 );

 my $path = AIR2::SearchUtils::xml_path_for( $pk, $base_dir );

 my $ok = AIR2::SearchUtils::write_xml( $pk, $base_dir, $xml_str, $pretty );

 my $question = AIR2::SearchUtils::get_question($ques_id);

 my $source = AIR2::SearchUtils::get_source($src_id);

 my $sources = AIR2::SearchUtils::get_source_org_matrix();

 my $ymd = AIR2::SearchUtils::dtim_string_to_ymd($dtim);

 # create a _date (ymd) field for each _dtim field
 AIR2::SearchUtils::date_ify( $hash );

=cut

sub get_lockfile_on_xml_dir {
    my $base_dir = shift or croak "base_dir required";
    my $hostname = AIR2::Config::get_hostname();

    my $last_mod_file = Path::Class::File::Lockable->new( $base_dir,
        'last_modified.' . $hostname );

    # lock the last_mod_file to prevent concurrent runs
    if ( $last_mod_file->locked ) {

        # if the lock is old but no process is running
        my $pidnum = $last_mod_file->lock_pid;
        my $pid    = Unix::PID::Tiny->new;
        if ( !$pid->is_pid_running($pidnum) ) {
            AIR2::Utils::logger(
                "Found old lock file but no PID running for $pidnum\n");
            AIR2::Utils::logger("Removing lock file...\n");
            $last_mod_file->unlock;
        }
        else {
            AIR2::Utils::logger("$0 is currently locked\n");
            exit 0;    # TODO is this an error or not?
        }
    }
    $last_mod_file->lock;

    return $last_mod_file;
}

sub get_pks_to_index {
    my %args          = @_;
    my $class         = delete $args{class} or croak "class required";
    my $column        = delete $args{column} or croak "column required";
    my $lock_file     = delete $args{lock_file} or croak "lock_file required";
    my $mod_since     = delete $args{mod_since};
    my $argv          = delete $args{argv};
    my $pk_filelist   = delete $args{pk_filelist};
    my $quiet         = delete $args{quiet} || 0;
    my $debug         = delete $args{debug} || 0;
    my $offset        = delete $args{offset};
    my $limit         = delete $args{limit};
    my $dry_run       = delete $args{dry_run};
    my $sql_all       = delete $args{sql_all};
    my $sql_all_count = delete $args{sql_all_count};

    my $mod_dt;
    if ($mod_since) {
        my $date_parser = Rose::DateTime::Parser->new(
            time_zone => $AIR2::Config::TIMEZONE );
        $mod_dt = $date_parser->parse_date($mod_since);
        if ( !defined $mod_dt ) {
            my $stat = [ stat($mod_since) ];
            if ( !defined $stat->[9] ) {
                croak
                    "mod_since [$mod_since] is not a valid date string or file name\n";
            }
            $mod_dt = $date_parser->parse_date( $stat->[9] )
                or croak "Can't parse date from $mod_since";
        }
    }

    my $ids            = [];
    my $total_expected = 0;
    if (@$argv) {
        push @$ids, @$argv;
        $total_expected = scalar(@$ids);
    }
    elsif ($mod_dt) {
        $quiet or AIR2::Utils::logger("modified since: $mod_dt\n");
        $ids            = $class->requires_indexing_ids($mod_dt);
        $total_expected = scalar(@$ids);
    }
    elsif ($pk_filelist) {
        my @buf = read_file($pk_filelist);
        $ids = [ grep {m/^\w+$/} map { chomp; $_; } @buf ];
        $total_expected = scalar(@$ids);
    }

    $debug and warn dump $ids;

    #$debug and exit;
    $Rose::DB::Object::Manager::Debug = $debug;
    $Rose::DB::Object::Debug          = $debug;

    # without respect to mod time
    if ( !@$argv && !$mod_dt && !$pk_filelist ) {
        my $query = [];
        if (@$ids) {
            $query = [ $column => $ids ];
        }

        # optimize for when we are fetching everything, to avoid
        # the object overhead.
        if ( !@$ids ) {

            my $dbh   = $class->init_db->retain_dbh;
            my $table = $class->meta->table;
            my $count_sql
                = $sql_all_count
                ? $sql_all_count
                : qq/SELECT count($column) FROM $table/;
            my $sql = $sql_all ? $sql_all : qq/SELECT $column FROM $table/;
            my $sth = $dbh->prepare($count_sql);
            $sth->execute;
            $total_expected = $sth->fetch->[0];
            $sth            = $dbh->prepare($sql);
            $sth->execute;

            while ( my $row = $sth->fetch ) {
                push @$ids, $row->[0];
            }

        }
        else {
            $total_expected = Rose::DB::Object::Manager->get_objects_count(
                object_class => $class,
                query        => $query,
            );

            # (re)set $ids since we might be acting on *all* responses
            my $objs = $class->fetch_all_iterator(
                query  => $query,
                select => $column,
            );
            $ids = [];
            while ( my $o = $objs->next ) {
                push @$ids, $o->$column;
            }

        }
    }

    # include those explicitly marked stale
    my $stale_records
        = get_stale_records_for_type( get_stale_type_for_class($class) );
    my %id_hash = map { $_ => 1 } @$ids;
    my @uniq_stale = grep { !exists $id_hash{$_} } @$stale_records;
    push @$ids, @uniq_stale;
    $total_expected += scalar @uniq_stale;

    if ( $total_expected != scalar(@$ids) ) {
        $lock_file->unlock;
        AIR2::Utils::logger(
            "Expected $total_expected but have " . scalar(@$ids) . " ids\n" );
        exit 1;
    }

    if ( defined $offset or defined $limit ) {
        $offset = 1 unless defined $offset;

        # sort ids to make it easier to slice
        my @sorted = sort { $a <=> $b } @$ids;

        # get the range
        my @slice;
        my $slice_count = 0;
        for my $id (@sorted) {
            next if ( $id < $offset );
            last if $limit and $slice_count >= $limit;
            push @slice, $id;
            $slice_count++;
        }
        $ids            = \@slice;
        $total_expected = scalar(@slice);
    }
    if ( !$dry_run ) {
        if ($total_expected) {

            # mark that we're changing something, *before* we change it,
            # so that we can just check this file to see if something has
            # changed.
            $lock_file->touch();

            # sleep for 1 second so that whatever
            # we modify is newer than the last_mod file
            sleep(1);
        }
        else {
            unless ($quiet) {
                AIR2::Utils::logger("No $class to serialize.\n");
            }
            $lock_file->unlock;
            exit;
        }
    }

    unless ($quiet) {
        AIR2::Utils::logger("Serializing $total_expected $class...\n");
    }

    return { ids => $ids, total_expected => $total_expected };
}

=head2 get_stale_records_for_type( I<type> )

Returns array of PK ints for I<type> from the stale_record table.

=cut

sub get_stale_records_for_type {
    my $type = shift or confess "type required";
    my $stale = [];
    my $recs = AIR2::StaleRecord->fetch_all( query => [ str_type => $type ] );
    for my $r (@$recs) {
        push @$stale, $r->str_xid;
    }
    return $stale;
}

sub xml_path_for {
    my $pk       = shift;
    my $base_dir = shift;

    # make sure $pk is file-name-ready,
    # since it might be a 12-char fixed width string
    $pk =~ s/\ +$//;
    $pk =~ s/\W/_/g;

    my ( $first, $second ) = ( $pk =~ m/^(.)(.)?/ );
    my $path = $base_dir->subdir($first);
    if ( defined $second ) {
        $path = $path->subdir($second);
    }
    $path = $path->file( $pk . '.xml' );
    return $path;
}

my $pretty_xml = 'xmllint --format ';

sub write_xml_file {
    my %args     = @_;
    my $pk       = delete $args{pk} or croak "pk required";
    my $base_dir = delete $args{base} or croak "base_dir required";
    my $xml      = delete $args{xml} or croak "xml required";
    my $pretty   = delete $args{pretty};
    my $debug    = delete $args{debug};
    $pretty = 1 unless defined $pretty;
    my $compress = delete $args{compress};
    $compress = 1 unless defined $compress;

    # make sure $pk is file-name-ready,
    # since it might be a 12-char fixed width string
    $pk =~ s/\ +$//;
    $pk =~ s/\W/_/g;

    # make sure utf8 flag is on, convert latin1, etc.
    $xml = to_utf8($xml);

    if ( !$xml or !is_valid_utf8($xml) ) {
        croak "to_utf8() failed for $base_dir / $pk";
    }

    # write the file, segmenting a little so that we don't
    # overwhelm a single directory with files.
    my $dir = xml_path_for( $pk, $base_dir )->dir;
    $dir->mkpath;

    # write temp file
    my $file = $dir->file( $pk . '.xml' );
    $debug and warn "XML file=$file\n";

    # clean up any previous file(s)
    if ( -s "$file" ) {
        unlink("$file") or croak "failed to unlink $file: $!";
    }
    if ( -s "$file.gz" ) {
        unlink("$file.gz") or croak "failed to unlink $file.gz: $!";
    }

    if ( !$pretty ) {
        if ( !$compress ) {
            return write_file( "$file", Encode::encode( "UTF-8", $xml ) )
                ? "$file"
                : 0;
        }
        return write_file(
            "$file.gz",
            Compress::Zlib::memGzip(
                Search::Tools::XML->tidy( Encode::encode( "UTF-8", $xml ) )
            )
        ) ? "$file.gz" : 0;
    }

    my $tmp = $file . '.tmp';
    write_file( "$tmp", Encode::encode( "UTF-8", $xml ) );

    # pretty it up and rename
    # TODO use xmllint --compress instead of separate call to gzip?
    if ($compress) {
        my $format = "$pretty_xml $tmp > $file && rm $tmp && gzip $file";

        #warn "$format\n";
        system($format)
            and warn "$format failed: $!";

        return "$file.gz";
    }
    else {
        my $format = "$pretty_xml $tmp > $file && rm $tmp";
        system($format) and warn "$format failed: $!";
        return "$file";
    }
}

my %inquiries;

sub get_inquiry {
    my $inq_id = shift;
    if ( exists $inquiries{$inq_id} ) {
        return $inquiries{$inq_id};
    }
    $inquiries{$inq_id} = AIR2::Inquiry->new( inq_id => $inq_id )->load;
    return $inquiries{$inq_id};
}

my %questions;    # memoize

sub get_question {
    my $ques_id = shift;
    if ( exists $questions{$ques_id} ) {
        return $questions{$ques_id};
    }

    # assumes AIR2::Question loaded by caller
    my $ques = AIR2::Question->new( ques_id => $ques_id )->load;
    $ques->inquiry;    # cache parent inquiry too
    $questions{$ques_id} = $ques;
    return $ques;
}

my %sources;           # memoize

sub get_source {
    my $src_id = shift;
    if ( exists $sources{$src_id} ) {
        return $sources{$src_id};
    }

    # assumes AIR2::Source use'd by caller
    my $src = AIR2::Source->new( src_id => $src_id )->load;
    $sources{$src_id} = $src;
    return $src;
}

my $facts;
my $fact_values;

sub find_sf_by_name {
    my ( $source, $fname ) = @_;
    unless ( $facts && $fact_values ) {
        $facts       = all_facts_by_id();
        $fact_values = all_fact_values_by_id();
    }

    my $fact_id;
    for my $fid ( keys %{$facts} ) {
        if ( $facts->{$fid}->fact_identifier eq $fname ) {
            $fact_id = $fid;
            last;
        }
    }
    croak "unknown fact $fname" unless $fact_id;

    # preference: src_fv_id, fv_id, src_value - return string or object
    for my $sf ( @{ $source->facts } ) {
        if ( $sf->sf_fact_id == $fact_id ) {
            if ( defined $sf->sf_src_fv_id ) {
                return $fact_values->{ $sf->sf_src_fv_id };
            }
            elsif ( defined $sf->sf_fv_id ) {
                return $fact_values->{ $sf->sf_fv_id };
            }
            elsif ( defined $sf->sf_src_value ) {
                return $sf->sf_src_value;
            }
        }
    }
    return "";
}

sub get_source_fact {
    my ( $source, $fname ) = @_;
    my $val = find_sf_by_name( $source, $fname );
    if ( ref($val) ) {
        return $val->fv_value;
    }
    else {
        return $val;
    }
}

sub get_source_fact_and_seq {
    my ( $source, $fname ) = @_;
    my $val = find_sf_by_name( $source, $fname );
    if ( ref($val) ) {
        return [ $val->fv_value, $val->fv_seq ];
    }
    else {
        return [ $val, 999 ];
    }
}

sub get_source_org_matrix {

    # do sql manually to avoid object overhead
    my %sources = ();
    my $dbh     = AIR2::Source->init_db->retain_dbh;
    my $sth
        = $dbh->prepare(
        qq/SELECT src_id,src_uuid,src_first_name,src_last_name,src_username FROM source/
        );
    $sth->execute;
    while ( my $src = $sth->fetch ) {
        $sources{ $src->[0] } = {
            first_name    => $src->[2],
            last_name     => $src->[3],
            uuid          => $src->[1],
            organizations => [],
            name          => join( ', ',
                ( $src->[3] || '[last name]' ),
                ( $src->[2] || '[first name]' ) ),
            username => $src->[4],
        };
    }

    $sth
        = $dbh->prepare(
        qq/SELECT so_src_id,so_org_id,so_upd_dtim FROM src_org WHERE so_status="A"/
        );
    $sth->execute;
    while ( my $r = $sth->fetch ) {
        push(
            @{ $sources{ $r->[0] }->{organizations} },
            [ $r->[1], $r->[2] ]
        );
    }

    return \%sources;

}

sub get_source_id_uuid_matrix {
    my %sources = ();
    my $dbh     = AIR2::Source->init_db->retain_dbh;
    my $sth     = $dbh->prepare(qq/SELECT src_id,src_uuid FROM source/);
    $sth->execute;
    while ( my $pair = $sth->fetch ) {
        $sources{ $pair->[0] } = $pair->[1];
    }
    return \%sources;
}

sub get_source_with_authz {
    my $src = shift or croak "src or src_id required";
    if ( !ref $src ) {
        $src = get_source($src);
    }
    return {
        first_name => $src->src_first_name(),
        last_name  => $src->src_last_name(),
        name       => $src->get_name(),
        username   => $src->src_username(),
        uuid       => $src->src_uuid(),
        authz      => $src->get_authz(),
    };
}

sub get_all_sources_with_authz {
    my $sources = get_source_org_matrix();

    # create authz array based on orgs and their parents/children
    my $orgs = all_organizations_by_id();
    for my $org_id ( keys %$orgs ) {
        my @ids;
        $orgs->{$org_id}->collect_related_org_ids( \@ids );
        $orgs->{tree}->{$org_id} = \@ids;
    }

    for my $src_id ( keys %$sources ) {
        my @org_ids;
        for my $pair ( @{ $sources->{$src_id}->{organizations} } ) {
            push @org_ids, $pair->[0];
            push @org_ids, @{ $orgs->{tree}->{ $pair->[0] } };
        }
        my %uniq = map { $_ => $_ } @org_ids;
        $sources->{$src_id}->{authz} = [ sort { $a <=> $b } keys %uniq ];
    }
    return $sources;
}

my %users;    # memoize

sub get_user {
    my $user_id = shift;
    if ( exists $users{$user_id} ) {
        return $users{$user_id};
    }
    my $user = AIR2::User->new( user_id => $user_id )->load;
    $users{$user_id} = $user;
    return $user;
}

sub dtim_string_to_ymd {
    my $dtim = shift;
    $dtim =~ s/^(\d+)-(\d+)-(\d+)T?.+/$1$2$3/;
    return $dtim;
}

sub dtim_to_ymd_hms {
    my $dtim = shift;
    return join( ' ', $dtim->ymd('-'), $dtim->hms(':') );
}

sub date_ify {
    my $hash = shift;
    for my $key ( sort keys %$hash ) {
        if ( $key =~ m/_dtim$/ ) {
            my $dtim = $hash->{$key} or next;
            my $new_key = $key;
            $new_key =~ s/_dtim/_date/;
            $hash->{$new_key} = dtim_string_to_ymd($dtim);
        }
    }
    return $hash;
}

sub pack_authz {
    return AIR2::Utils::pack_authz(@_);
}

sub unpack_authz {
    return AIR2::Utils::unpack_authz(@_);
}

sub all_organizations_by_id {
    return { map { $_->org_id => $_ } @{ AIR2::Organization->fetch_all } };
}

sub all_facts_by_id {
    return { map { $_->fact_id => $_ } @{ AIR2::Fact->fetch_all } };
}

sub all_fact_values_map {
    my $facts = all_facts_by_id();
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
    return \%table;
}

sub all_preferences_by_id {
    return { map { $_->pt_id => $_ } @{ AIR2::PreferenceType->fetch_all } };
}

sub all_fact_values_by_id {
    return { map { $_->fv_id => $_ } @{ AIR2::FactValue->fetch_all } };
}

sub all_preference_values_by_id {
    return { map { $_->ptv_id => $_ }
            @{ AIR2::PreferenceTypeValue->fetch_all } };
}

sub all_projects_by_id {
    return { map { $_->prj_id => $_ } @{ AIR2::Project->fetch_all } };
}

sub all_projects_as_hashes_by_id {
    my $projs = AIR2::Project->fetch_all;
    my %p;
    for my $proj (@$projs) {
        $p{ $proj->prj_id } = $proj->column_value_pairs;
        $p{ $proj->prj_id }->{prj_upd_dtim} .= "";
        $p{ $proj->prj_id }->{prj_cre_dtim} .= "";
        $p{ $proj->prj_id }->{org_uuids} = $proj->get_org_uuids;
        $p{ $proj->prj_id }->{org_names} = $proj->get_org_names;
        $p{ $proj->prj_id }->{org_ids}   = $proj->get_org_ids;
    }
    return \%p;
}

my %stale_types = (
    'source'           => [ 'S', 'AIR2::Source' ],
    'sources'          => [ 'S', 'AIR2::Source' ],
    'inquiry'          => [ 'I', 'AIR2::Inquiry' ],
    'inquiries'        => [ 'I', 'AIR2::Inquiry' ],
    'outcome'          => [ 'O', 'AIR2::Outcome' ],
    'outcomes'         => [ 'O', 'AIR2::Outcome' ],
    'src_response_set' => [ 'R', 'AIR2::SrcResponseSet' ],
    'responses'        => [ 'R', 'AIR2::SrcResponseSet' ],
    'project'          => [ 'P', 'AIR2::Project' ],
    'projects'         => [ 'P', 'AIR2::Project' ],
    'public_response'  => [ 'A', 'AIR2::PublicSrcResponseSet' ],
    'public_responses' => [ 'A', 'AIR2::PublicSrcResponseSet' ],
);

sub get_stale_type_map {
    return \%stale_types;
}

sub get_stale_type_for_class {
    my $class = shift or confess "class name required";
    for my $nick ( keys %stale_types ) {
        my ( $type, $class_name ) = @{ $stale_types{$nick} };
        if ( $class eq $class_name ) {
            return $type;
        }
    }
    return undef;
}

sub touch_stale {
    my $obj = shift or croak "RDBO object required";

    # look up by class since some classes share a table
    my $class      = $obj->meta->class;
    my $stale_type = get_stale_type_for_class($class);
    if ( !$stale_type ) {
        $class =~ s/AIR2Test::/AIR2::/;
        $stale_type = get_stale_type_for_class($class);
    }

    confess "No stale type for $obj ($class)" unless $stale_type;

    my $stale_record = AIR2::StaleRecord->new(
        str_type => $stale_type,
        str_xid  => $obj->primary_key_value,
    );

    # if update, assume small race condition ok.
    return $stale_record->insert_or_update_on_duplicate_key();
}

sub touch_watcher_cache {
    croak "watcher cache should refresh itself";
}

sub get_activity_master {
    my $am = AIR2::ActivityMaster->fetch_all_iterator;
    my %actm;
    while ( my $act = $am->next ) {
        $actm{ $act->actm_id } = $act;
    }
    return \%actm;
}

sub get_pool_offsets {
    my %args = @_;
    my $dbh  = delete $args{dbh}
        || AIR2::DBManager->new_or_cached->retain_dbh();
    my $n_pools = delete $args{n_pools} or croak "n_pools required";
    my $column  = delete $args{column}  or croak "column required";
    my $table   = delete $args{table}   or croak "table required";
    my $debug = delete $args{debug} || 0;

    # get total number of rows so we can calculate pool size
    my $sql = qq(select count($column) from $table);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my $total_rows = $sth->fetch->[0];
    my $pool_size  = int( $total_rows / $n_pools );
    my $pointer    = 0;
    my $i          = 0;
    my @offsets;

    while ( $i < $n_pools ) {
        my $try_offset = $i * $pool_size;
        my $sql
            = qq(select $column from $table order by $column asc limit $pool_size offset $try_offset);
        $debug and warn $sql;
        my $sth = $dbh->prepare($sql);
        $sth->execute();
        my $first = $sth->fetch;
        if ( !$first ) {
            warn "No result for $sql";
            next;
        }
        my $offset = $first->[0];
        $sth->finish();    # don't care about the rest
        push @offsets, $offset;
        $i++;
    }

    return {
        total   => $total_rows,
        limit   => $pool_size,
        offsets => \@offsets,
    };
}

my %class_type_map = (
    'sources'          => 'AIR2::Source',
    'responses'        => 'AIR2::SrcResponseSet',
    'public_responses' => 'AIR2::PublicSrcResponseSet',
    'inquiries'        => 'AIR2::Inquiry',
    'outcomes'         => 'AIR2::Outcome',
    'projects'         => 'AIR2::Project',
);

sub class_for_type {
    my $type = pop(@_);
    if ( !$type ) { croak "type required"; }
    if ( !exists $class_type_map{$type} ) {
        croak "No class for type $type";
    }
    return $class_type_map{$type};
}

1;
