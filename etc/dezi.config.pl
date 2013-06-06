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

my $conf = {
    skip => {},

    base_uri => AIR2::Config::get_constant('AIR2_BASE_URL') . 'search-admin/',

    # engine_config is the default,
    # but shouldn't ever really get used.
    engine_config => { indexer_config => { highlightable_fields => 1, }, },

    # each key must map to a 'path' in MasterServer
    'sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'active-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'primary-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'fuzzy-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'fuzzy-active-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'fuzzy-primary-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_sources')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'strict-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('sources')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'strict-active-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('sources')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'strict-primary-sources' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('sources')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'inquiries' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('inquiries')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
        #debug => 1,
    },
    'projects' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('projects')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'responses' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_responses')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'fuzzy-responses' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('fuzzy_responses')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'strict-responses' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('responses')->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
    'public-responses' => {
        engine_config => {
            indexer_config => {
                highlightable_fields => 1,
                config               => SWISH::Prog::Config->new(
                    AIR2::Config::get_search_config('public_responses')
                        ->stringify
                ),
            },
            searcher_config => { find_relevant_fields => 1, },
        },
    },
};

for my $key ( keys %$conf ) {
    next if $key eq 'skip';
    next if $key eq 'engine_config';
    next if $key eq 'base_uri';

    $conf->{$key}->{base_uri}     = $conf->{base_uri} . $key;
    $conf->{$key}->{stats_logger} = $stats_logger;
    $conf->{$key}->{ui_class}     = 'Dezi::UI';
    $conf->{$key}->{admin_class}  = 'Dezi::Admin';
    $conf->{$key}->{admin}->{base_uri} = $conf->{$key}->{base_uri};
    $conf->{$key}->{admin}->{username} = 'deziadmin';
    $conf->{$key}->{admin}->{password} = 'pinsearcher';
}

#dump $conf;

# final value is eval'd by server
$conf;

