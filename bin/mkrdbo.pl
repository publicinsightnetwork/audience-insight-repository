#!/opt/pij/bin/perl                                                                                            
use strict;
use warnings;
use lib qw( lib/perl );
use Carp;
use AIR2::DBManager;
use AIR2::DB;
use Rose::DB::Object::Loader;

{

    package MyManager;
    @MyManager::ISA = qw( Rose::DB::Object::ConventionManager );
    use Data::Dump qw( dump );

    # APM convention is to prefix table name to all columns
    # that is not RDBO convention. hack around it.

    my %seen = ();

    sub auto_foreign_key_name {
        my $self = shift;
        my ( $fclass, $cname ) = @_;

        #dump \@_;

        my $ret = $self->SUPER::auto_foreign_key_name(@_);

        #dump $ret;

        $ret = lc($fclass);
        $ret =~ s/^\w+:://;

        #warn "$fclass\n";

        if ( $ret eq 'factvalue' ) {

            #dump \@_;

            if ( $cname eq "src_fact_sf_src_fv_id_fact_value_fv_id" ) {
                $ret = 'source_facet_value';

            }
            elsif ( $cname eq "src_fact_sf_fv_id_fact_value_fv_id" ) {
                $ret = 'fact_value';
            }
            else {
                $ret = 'fact_value_unknown';
            }
        }

        if ( $ret eq 'source' ) {

            #dump \@_;

            if ( $cname eq "src_relationship_src_src_id_source_src_id" ) {

                $ret = 'source_2';

            }

        }
        if ( $ret eq 'user' ) {

            #dump \@_;

            if ( $cname =~ m/upd_user/ ) {

                $ret = 'upd_user';

            }
            elsif ( $cname =~ m/cre_user/ ) {

                $ret = 'cre_user';

            }

        }

        return $ret;
    }
}

my $loader = Rose::DB::Object::Loader->new(
    db                 => AIR2::DBManager->new(),
    class_prefix       => 'AIR2',
    base_class         => 'AIR2::DB',
    with_managers      => 0,
    convention_manager => 'MyManager',
);

$loader->make_modules(

    #'module_dir' => 'lib/perl' # move there later

);

system("mv AIR2/* lib/perl/AIR2/");
system("rmdir AIR2");
