#!/usr/bin/env php
<?php
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

require_once 'app/init.php';
require_once APPPATH.'../tests/Test.php';
require_once APPPATH.'../tests/AirHttpTest.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';

define('MY_TEST_PASS', 'fooBar123.');

plan(56);

AIR2_DBManager::init();

// Create 4 users in 3 different orgs.
$users = array();
$count = 0;
while ($count++ < 9) {
    $u = new TestUser();
    $u->user_password = MY_TEST_PASS;
    $u->save();
    $users[] = $u;
}

// test Orgs
$orgs = array();
$count = 0;
while ($count++ < 3) {
    $o = new TestOrganization();
    $o->save();
    $orgs[] = $o;
}
$orgs[0]->add_users(array($users[0]));
$orgs[0]->save();
$orgs[1]->add_users(array($users[2]), 3);  // 3==WRITER
$orgs[1]->add_users(array($users[8]), 6);  // READERPLUS
$orgs[1]->save();
$orgs[2]->add_users(array($users[3]));
$orgs[2]->add_users(array($users[1]), 3);  // WRITER
$orgs[2]->save();

// parent/child/sibling orgs
$parent = new TestOrganization();
$parent->add_users(array($users[4]), 4); //MANAGER
$parent->save();
$orgs[2]->org_parent_id = $parent->org_id;
$orgs[2]->save();
$child = new TestOrganization();
$child->org_parent_id = $orgs[2]->org_id;
$child->add_users(array($users[5]), 4); //MANAGER
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->add_users(array($users[6]), 4); //MANAGER
$sibling->save();

// setup mixed authz user
$parent->add_users(array($users[7]), 3); //WRITER of parent
$parent->save();
$child->add_users(array($users[7]), 4);  // MANAGER of child
$child->save();

$project = new TestProject();
$project->add_orgs( array( $orgs[1], $orgs[2] ) );
$project->save();

// actual tests
is( $project->user_may_read(  $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user cannot read project if not in related Org");
is( $project->user_may_read(  $users[8] ), AIR2_AUTHZ_IS_ORG,
    "readerplus user may read project");
is( $project->user_may_write( $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user cannot create new Project for Org to which they do not belong");
is( $project->user_may_write( $users[2] ), AIR2_AUTHZ_IS_ORG,
    "user may create new Project for Org in which they are a WRITER");
is( $project->user_may_write( $users[3] ), AIR2_AUTHZ_IS_DENIED,
    "user may not create new Project if they are not a WRITER in the assigned Org");
is( $project->user_may_write(  $users[8] ), AIR2_AUTHZ_IS_DENIED,
    "readerplus user may not write project");
is( $project->user_may_manage( $users[2] ), AIR2_AUTHZ_IS_MANAGER,
    "user who is contact for a project may manage it");
is( $project->user_may_manage( $users[3] ), AIR2_AUTHZ_IS_DENIED,
    "users[3] may not manage project where they cannot even write");

// test child org
is($project->user_may_read($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may read child orgs project");
is($project->user_may_write($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may write child orgs project");
is($project->user_may_manage($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may manage child orgs project");

// test parent org
is($project->user_may_read($users[5]), AIR2_AUTHZ_IS_ORG,
    "users[5] may read parent orgs project");
is($project->user_may_write($users[5]), AIR2_AUTHZ_IS_DENIED,
    "users[5] may not write parent orgs project");
is($project->user_may_manage($users[5]), AIR2_AUTHZ_IS_DENIED,
    "users[5] may not manage parent orgs project");

// test sibling org
is($project->user_may_read($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not read sibling orgs project");
is($project->user_may_write($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not write sibling orgs project");
is($project->user_may_manage($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not manage sibling orgs project");

// test mixed org
is($project->user_may_read($users[7]), AIR2_AUTHZ_IS_ORG,
    "users[7] (mixed authz) may read parent orgs project");
is($project->user_may_write($users[7]), AIR2_AUTHZ_IS_ORG,
    "users[7] (mixed authz) may write parent orgs project");
is($project->user_may_manage($users[7]), AIR2_AUTHZ_IS_DENIED,
    "users[7] (mixed authz) may not manage parent orgs project");

// test changing prj_name
$p2 = new TestProject();
$p2->add_orgs(array($orgs[1]));
is( $p2->user_may_write($users[2]), AIR2_AUTHZ_IS_ORG, "prj_name - create new");
$p2->save();
$p2->prj_display_name = 'new display name';
is( $p2->user_may_write($users[2]), AIR2_AUTHZ_IS_ORG, "prj_name - write display");
$p2->prj_name = 'new name';
is( $p2->user_may_write($users[2]), AIR2_AUTHZ_IS_DENIED, "prj_name - write display");
$p2->delete();

// query authz
$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_read($q, $users[0]);
is( $q->count(), 0, "users[0] may view no projects");

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_read($q, $users[2]);
is( $q->count(), 1, "users[2] may see one project");

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_read($q, $users[3]);
is( $q->count(), 1, "users[3] may see 1 project");

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_write($q, $users[2]);
is( $q->count(), 1, "users[2] may write to project they are in");

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_write($q, $users[3]);
is( $q->count(), 0, "users[3] may not write to shared projects"); // TODO rules are not clear on this

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_manage($q, $users[2]);
is( $q->count(), 1, "users[2] may manage projects where they are primary contact");

$q = AIR2_Query::create();
$q->from('Project p');
Project::query_may_manage($q, $users[3]);
is( $q->count(), 0, "users[3] may not manage shared projects");

// query child
$q = AIR2_Query::create()->from('Project p');
Project::query_may_read($q, $users[4]);
is( $q->count(), 1, "users[4] may query-read child orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_write($q, $users[4]);
is( $q->count(), 1, "users[4] may query-write child orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_manage($q, $users[4]);
is( $q->count(), 1, "users[4] may query-manage child orgs project");

// query parent
$q = AIR2_Query::create()->from('Project p');
Project::query_may_read($q, $users[5]);
is( $q->count(), 1, "users[5] may query-read parent orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_write($q, $users[5]);
is( $q->count(), 0, "users[5] may not query-write parent orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_manage($q, $users[5]);
is( $q->count(), 0, "users[5] may not query-manage parent orgs project");

// query siblings
$q = AIR2_Query::create()->from('Project p');
Project::query_may_read($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-read sibling orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_write($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-write sibling orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_manage($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-manage sibling orgs project");

// query mixed org authz
$q = AIR2_Query::create()->from('Project p');
Project::query_may_read($q, $users[7]);
is( $q->count(), 1, "users[7] (mixed authz) may query-read parent orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_write($q, $users[7]);
is( $q->count(), 1, "users[7] (mixed authz) may query-write parent orgs project");
$q = AIR2_Query::create()->from('Project p');
Project::query_may_manage($q, $users[7]);
is( $q->count(), 0, "users[7] (mixed authz) may not query-manage parent orgs project");

// annotations
$anno = new ProjectAnnotation();
$anno->prjan_cre_user = $users[0]->user_id;
$anno->prjan_prj_id   = $project->prj_id;
is( $anno->user_may_read( $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user may not read annotation unless can read parent Project");
is( $anno->user_may_write( $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user may not write new annotation unless they can read Project");

// switch owner
$anno->prjan_cre_user = $users[1]->user_id;
is( $anno->user_may_read( $users[2] ), AIR2_AUTHZ_IS_ORG,
    "user may read annotation if can read parent Project");
is( $anno->user_may_write( $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user may not write annotation if they cannot write Project");
is( $anno->user_may_write( $users[1] ), AIR2_AUTHZ_IS_NEW,
    "user[1] may write to new annotation if they can read the Project");
is( $anno->user_may_write( $users[2] ), AIR2_AUTHZ_IS_NEW,
    "user[2] may write to new annotation if they can read the Project");

// save annotation
$anno->save();
is( $anno->user_may_write( $users[1] ), AIR2_AUTHZ_IS_OWNER,
    "user[1] may update if they own annotation and can write the Project");
is( $anno->user_may_write( $users[2] ), AIR2_AUTHZ_IS_DENIED,
    "user[2] may not update if they don't own annotation");

// html views ONLY can see 403's for resources
$browser = new AirHttpTest();
$browser->set_user($users[0], $users[0]->get_authz());
$resp = $browser->http_get('/project/'.$project->prj_uuid);
is( $browser->resp_code(), 403, "users[0] HTML GET == 403" );

// non-existent still give 404's
$resp = $browser->http_get('/project/DOESNTEXIST');
is( $browser->resp_code(), 404, "users[0] HTML GET fake == 404" );

// other content types see 404's
$browser = new AirHttpTest();
$browser->set_user($users[0], $users[0]->get_authz());
$resp = $browser->http_get('/project/'.$project->prj_uuid.'.json');

//TODO: rframe-api is more honest about what a 403 is (vs 404)
is( $browser->resp_code(), 403, "users[0] JSON GET == 403" );

$browser = new AirHttpTest();
$browser->set_user($users[2], $users[2]->get_authz());
$resp = $browser->http_get('/project/'.$project->prj_uuid);
//diag_dump( $resp );
is( $browser->resp_code(), 200, "users[0] GET == 200" );

// check delete (#1539)
$porgs = $project->ProjectOrg;
ok( $porgs[0]->delete(), "delete one ProjectOrg");

// need a fresh copy
$q = AIR2_Query::create();
$q->from('Project p');
$q->where('p.prj_name = ?', 'authz-unit-test-test123');
$proj_copy = $q->execute();
is( $proj_copy->ProjectOrg->user_may_delete( $users[2] ), AIR2_AUTHZ_IS_DENIED,
    "may not delete the last associated Org from a Project");


// clean up
$project->delete();
