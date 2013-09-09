# Perl syntax
use strict;
use AIR2::Config;
use SWISH::Prog::Config;
use Dezi::Stats;
use Dezi::Admin;
use AIR2::DBManager;
use Data::Dump qw( dump );

$ENV{AIR2_USE_MASTER} = 1;
my $db           = AIR2::DBManager->new_or_cached();
my $stats_logger = Dezi::Stats->new(
    type     => 'DBI',
    dsn      => $db->dsn,
    username => $db->username,
    password => $db->password,
    quote    => 1,               # since we use mysql
);

# each key must map to a 'path' in MasterServer
my %path2config = (
    'sources'                => 'fuzzy_sources',
    'active-sources'         => 'fuzzy_sources',
    'primary-sources'        => 'fuzzy_sources',
    'fuzzy-sources'          => 'fuzzy_sources',
    'fuzzy-active-sources'   => 'fuzzy_sources',
    'fuzzy-primary-sources'  => 'fuzzy_sources',
    'strict-sources'         => 'sources',
    'strict-active-sources'  => 'sources',
    'strict-primary-sources' => 'sources',
    'inquiries'              => 'inquiries',
    'projects'               => 'projects',
    'responses'              => 'fuzzy_responses',
    'fuzzy-responses'        => 'fuzzy_responses',
    'strict-responses'       => 'responses',
    'public-responses'       => 'public_responses',
);

# basic config
my $conf = {
    skip => {},

    base_uri => AIR2::Config::get_constant('AIR2_BASE_URL') . 'search-admin/',

    # engine_config is the default,
    # but shouldn't ever really get used.
    engine_config => { indexer_config => { highlightable_fields => 1, }, },

};

# fill out with path-specifics
for my $path ( keys %path2config ) {
    my $config = $path2config{$path};
    $conf->{$path}->{engine_config} = {
        indexer_config => {
            config => SWISH::Prog::Config->new(
                AIR2::Config::get_search_config($config)->stringify
            ),
            highlightable_fields => 1,
        },
        searcher_config => {
            find_relevant_fields => 1,
            qp_config            => {
                dialect          => 'Lucy',
                null_term        => 'NULL',
                croak_on_error   => 1,
                query_class_opts => { debug => $ENV{DEZI_DEBUG} },
            },
        },
    };
    $conf->{$path}->{base_uri}     = $conf->{base_uri} . $path;
    $conf->{$path}->{stats_logger} = $stats_logger;
    $conf->{$path}->{ui_class}     = 'Dezi::UI';
    $conf->{$path}->{admin_class}  = 'Dezi::Admin';
    $conf->{$path}->{admin}        = {
        base_uri => $conf->{$path}->{base_uri},
        username => 'deziadmin',
        password => 'pinsearcher',
    };

}

#dump $conf;

# final value is eval'd by server
$conf;

