#!/usr/bin/env perl
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

use strict;
use warnings;
use Test::More tests => 6;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::SrcActivity;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Inquiry;

my $debug         = $ENV{PERL_DEBUG} || 0;
my $TEST_USERNAME = 'ima-test-user';
my $TEST_PROJECT  = 'ima-test-project';

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

###################################
##           source
###################################

ok( my $source = AIR2Test::Source->new(
        src_username => $TEST_USERNAME,
        debug        => $debug
    ),
    "new source"
);
ok( $source->add_emails(
        [ { sem_email => $TEST_USERNAME . '@nosuchemail.org' } ]
    ),
    "add email address"
);

# use load_or_insert in case we aborted on earlier run and left data behind
ok( $source->load_or_insert(), "save source" );

# add a bunch of activities of different kinds and make sure our convenience methods work
$source->add_activities(
    [   {   sact_dtim    => '2010-01-01 00:00:00',
            sact_actm_id => 13,                      # Sent Query (counts as queried)
        },
        {   sact_dtim    => '2010-02-01 00:00:00',
            sact_actm_id => 29,                      # Sent Email (counts as queried)
        },
        {   sact_dtim    => '2010-03-01 00:00:00',
            sact_actm_id => 40,                      # CSV export
        },

    ]
);
$source->save;

is( $source->last_contacted_date, '20100201', "last_contacted_date" );
is( $source->last_queried_date,   '20100201', "last_queried_date" );
is( $source->last_activity_date,  '20100301', "last_activity_date" );
