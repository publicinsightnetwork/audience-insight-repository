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

package AIR2::Project;
use strict;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );
use AIR2::SearchUtils;
use JSON;
use Search::Tools::UTF8;
use Encode;

__PACKAGE__->meta->setup(
    table => 'project',

    columns => [
        prj_id   => { type => 'serial', not_null => 1 },
        prj_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        prj_name => {
            type     => 'varchar',
            length   => 32,
            not_null => 1
        },
        prj_display_name => {
            type     => 'varchar',
            length   => 255,
            not_null => 1
        },
        prj_desc   => { type => 'text', length => 65535 },
        prj_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        prj_type => {
            type     => 'character',
            default  => 'I',
            length   => 1,
            not_null => 1
        },
        prj_cre_user => { type => 'integer', not_null => 1 },
        prj_upd_user => { type => 'integer' },
        prj_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        prj_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['prj_id'],

    unique_keys => [ ['prj_uuid'], ['prj_name'], ['prj_display_name'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { prj_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { prj_upd_user => 'user_id' },
        },
    ],

    relationships => [

        activities => {
            class      => 'AIR2::ProjectActivity',
            column_map => { prj_id => 'pa_prj_id' },
            type       => 'one to many',
        },

        annotations => {
            class      => 'AIR2::ProjectAnnotation',
            column_map => { prj_id => 'prjan_prj_id' },
            type       => 'one to many',
        },

        project_inquiries => {
            class      => 'AIR2::ProjectInquiry',
            column_map => { prj_id => 'pinq_prj_id' },
            type       => 'one to many',
        },

        project_messages => {
            class      => 'AIR2::ProjectMessage',
            column_map => { prj_id => 'pm_pj_id' },
            type       => 'one to many',
        },

        project_orgs => {
            class      => 'AIR2::ProjectOrg',
            column_map => { prj_id => 'porg_prj_id' },
            type       => 'one to many',
        },

        organizations => {
            map_class => 'AIR2::ProjectOrg',
            map_from  => 'project',
            map_to    => 'organization',
            type      => 'many to many',
        },

        inquiries => {
            map_class => 'AIR2::ProjectInquiry',
            map_from  => 'project',
            map_to    => 'inquiry',
            type      => 'many to many',
        },

        tags => {
            class      => 'AIR2::Tag',
            column_map => { prj_id => 'tag_xid' },
            query_args => [ tag_ref_type => tag_ref_type() ],
            type       => 'one to many',
        },
    ],
);

sub tag_ref_type {'P'}

sub init_indexer {
    my $self = shift;
    return $self->SUPER::init_indexer(
        prune => {

        },
        max_depth        => 3,           # get m2m foreign objs
        xml_root_element => 'project',
        force_load       => 0,
        @_
    );
}

my @indexables = qw(
    activities
    annotations
    project_inquiries
    project_orgs
);

my @searchables = (
    @indexables, qw(
        tags
        )
);

sub get_searchable_rels { return [@searchables] }

sub load_indexable_rels {
    my $self = shift;

    for my $rel (@indexables) {
        $self->$rel;

        # indexer depth == 1 but we load some deeper manually
        if ( $rel eq 'project_inquiries' ) {
            for my $pinq ( @{ $self->$rel } ) {
                $pinq->inquiry->questions;
            }
        }
        elsif ( $rel eq 'project_orgs' ) {
            for my $porg ( @{ $self->$rel } ) {
                $porg->organization;
                $porg->user;
            }
        }
    }
}

# memoize
my %org_names;
my %org_uuids;
my %org_ids;
my $owner_org;

# we assume the owner org is the home org
# for the contact user for the oldest related org.
sub get_owner_org {
    my $self = shift;
    return $owner_org if $owner_org;
    my $oldest;
    for my $po ( @{ $self->project_orgs } ) {
        $oldest ||= $po;
        if (   $po->porg_cre_dtim < $oldest->porg_cre_dtim
            && $po->user->get_home_org->org_id == $po->porg_org_id )
        {
            $oldest = $po;
        }
    }
    return $oldest ? $oldest->organization : undef;
}

sub get_org_names {
    my $self = shift;
    if ( exists $org_names{ $self->prj_id } ) {
        return $org_names{ $self->prj_id };
    }
    my %names;
    for my $po ( @{ $self->project_orgs } ) {
        $names{ $po->get_org_name }++;
    }
    $org_names{ $self->prj_id } = [ keys %names ];
    return $org_names{ $self->prj_id };
}

sub get_org_uuids {
    my $self = shift;
    if ( exists $org_uuids{ $self->prj_id } ) {
        return $org_uuids{ $self->prj_id };
    }
    my %uuids;
    for my $po ( @{ $self->project_orgs } ) {
        $uuids{ $po->get_org_uuid }++;
    }
    $org_uuids{ $self->prj_id } = [ keys %uuids ];
    return $org_uuids{ $self->prj_id };
}

sub get_org_ids {
    my $self = shift;
    if ( exists $org_ids{ $self->prj_id } ) {
        return $org_ids{ $self->prj_id };
    }
    my %ids;
    for my $po ( @{ $self->project_orgs } ) {
        $ids{ $po->porg_org_id }++;
    }
    $org_ids{ $self->prj_id } = [ keys %ids ];
    return $org_ids{ $self->prj_id };
}

my %authz;

sub get_authz {
    my $self = shift;
    if ( exists $authz{ $self->prj_id } ) {
        return $authz{ $self->prj_id };
    }
    my @ids;
    for my $po ( @{ $self->project_orgs } ) {
        if ( $po->porg_status ne 'A' ) {
            next;
        }
        $po->organization->collect_related_org_ids( \@ids );
    }
    my %uniq = map { $_ => $_ } @ids;
    $authz{ $self->prj_id } = [ sort { $a <=> $b } keys %uniq ];
    return $authz{ $self->prj_id };
}

=head2 as_xml( I<args> )

Returns Project as XML string, suitable for indexing.

I<args> should contain a Rose::DBx::Object::Indexed::Indexer
object and other objects relevant to the XML structure.
See bin/projects2xml.pl for example usage.

Note that Project XML does not include SrcResponseSets
but does include Inquiries. This is both because
projects search should not include responses, and because
the sheer size of the XML files for some projects
(e.g. APMG) is prohibitive. So there are no xincludes
here, but instead the Inquiry objects are loaded
via load_indexable_rels().

=cut

sub as_xml {
    my $proj    = shift;
    my $args    = shift or croak "args required";
    my $debug   = delete $args->{debug} || 0;
    my $indexer = delete $args->{indexer}
        || $proj->init_indexer( debug => $debug, );
    my $base_dir = delete $args->{base_dir}
        || Path::Class::dir('no/such/dir');

    $proj->load_indexable_rels();

    my $dmp = $indexer->serialize_object($proj);

    $dmp->{tags} = [ map { $_->get_name } @{ $proj->get_tags } ];
    $dmp->{prj_uuid_name} = join( ':', $proj->prj_uuid, $proj->prj_name );
    $dmp->{prj_uuid_title}
        = join( ':', $proj->prj_uuid, $proj->prj_display_name );

    $dmp->{author}      = $proj->get_cre_user->get_name;
    $dmp->{author_fl}   = $proj->get_cre_user->get_name_first_last;
    $dmp->{author_uuid} = $proj->get_cre_user->user_uuid;

    # virtual field common to other indexes
    for my $pinq ( @{ $dmp->{project_inquiries} } ) {
        $pinq->{inq_uuid_title} = join( ':',
            $pinq->{inquiry}->{inq_uuid},
            ( $pinq->{inquiry}->{inq_ext_title} || '' ) );

        for my $q ( @{ $pinq->{inquiry}->{questions} } ) {

            # decode json fields
            for my $json_field ( @{ AIR2::Question->json_encoded_columns } ) {

                if ( $q->{$json_field} and lc( $q->{$json_field} ) ne 'null' )
                {
                    my $decoded_field = $json_field . '_values';
                    eval {
                        $q->{$json_field} = to_utf8( $q->{$json_field} );
                        $q->{$decoded_field}
                            = decode_json( encode_utf8( $q->{$json_field} ) );
                    };
                    if ($@) {
                        warn
                            "error parsing json in Inquiry $pinq->{inquiry}->{inq_id}: $@";
                    }

                    # boolean values are objects, which we must stringify
                    if ( ref $q->{$decoded_field} eq 'ARRAY' ) {
                        for my $qcv ( @{ $q->{$decoded_field} } ) {
                            if ( ref $qcv eq 'HASH' ) {
                                for my $key (qw( isdefault ischecked )) {
                                    if ( exists $qcv->{$key} ) {
                                        $qcv->{$key} .= "";
                                    }
                                }
                            }
                        }
                    }
                    elsif ( ref $q->{$decoded_field} eq 'HASH' ) {
                        for my $qcv_key ( keys %{ $q->{$decoded_field} } ) {
                            next
                                unless ref $q->{$decoded_field}->{$qcv_key}
                                eq 'JSON::XS::Boolean';
                            $q->{$decoded_field}->{$qcv_key} .= '';
                        }
                    }
                }

            }    # END json fields
        }    # END questions
    }

    for my $porg ( @{ $dmp->{project_orgs} } ) {
        if ( $porg->{user} ) {
            $porg->{owner_org_uuid} = $porg->{organization}->{org_uuid};
        }
    }

    # strip out the non-text from annotations
    for my $anno ( @{ $dmp->{annotations} } ) {
        $anno = { prjan_value => $anno->{prjan_value} };
    }

    $debug and dump $dmp;

    my $xml = $indexer->to_xml( $dmp, $proj, 1 );    # last 1 to strip plurals

    # hack in the authz string
    my $authz_str = join( ",", @{ $proj->get_authz } );
    my $root = $indexer->xml_root_element;
    $xml =~ s,^<$root,<$root authz="$authz_str",;

    return $xml;
}

=head2 get_manual_entry_inquiry

Gets (or creates, if DNE) the manual-input inquiry associated with this
particular project.  This is used to manually enter source responses for things
like emails and phone calls.

=cut

sub get_manual_entry_inquiry {
    my $proj = shift;

    # check for existing
    my $uuid = AIR2::Utils->str_to_uuid( 'me-' . $proj->prj_name );
    my $inq_rec = AIR2::Inquiry->new( inq_uuid => $uuid );
    $inq_rec->load_speculative;

    # create if DNE
    unless ( $inq_rec->inq_id ) {
        $inq_rec = AIR2::Inquiry->make_manual_entry();
        $inq_rec->inq_uuid($uuid);
        $inq_rec->save();
        my $pi = AIR2::ProjectInquiry->new(
            pinq_prj_id => $proj->prj_id,
            pinq_inq_id => $inq_rec->inq_id,
        );
        $pi->save();
        for my $porg ( @{ $proj->project_orgs } ) {
            next unless $porg->porg_status eq 'A';
            my $inqorg = AIR2::InqOrg->new(
                iorg_inq_id => $inq_rec->inq_id,
                iorg_org_id => $porg->porg_org_id,
            );
            $inqorg->save();
        }
    }

    return $inq_rec;
}

sub save {
    my $self = shift;
    my $ret  = $self->SUPER::save(@_);
    if ( -s $self->get_rss_cache_path() ) {
        unlink( $self->get_rss_cache_path() );
    }
    if ( -s get_combined_rss_cache_path() ) {
        unlink( get_combined_rss_cache_path() );
    }
    return $ret;
}

sub get_rss_cache_path {
    my $self = shift;
    my $root = AIR2::Config::get_rss_cache_dir();
    if ( !-d $root->subdir('project') ) {
        $root->subdir('project')->mkpath(1);
    }
    return sprintf( "%s/project/%s.rss", $root, $self->prj_name );
}

sub get_combined_rss_cache_path {
    my $root = AIR2::Config::get_rss_cache_dir();
    return sprintf( "%s/project.rss", $root );
}

sub get_rss_feed {
    my $self = shift;
    my $limit = shift || 100;

    # TODO sql here for all eligible inquires for $self
    # optional $limit

}

1;

