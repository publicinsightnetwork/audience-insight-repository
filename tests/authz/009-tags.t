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
require_once APPPATH.'../tests/models/TestTagMaster.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestInquiry.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestSource.php';

$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_connection();

// Create 3 users (one for each role)
$users = array();
for ($i=0; $i<4; $i++) {
    $users[$i] = new TestUser();
    $users[$i]->user_password = 'Test123$';
    $users[$i]->save();
}

// test org
$org = new TestOrganization();
$org->add_users(array($users[0]), 2); //reader
$org->add_users(array($users[1]), 3); //writer
$org->add_users(array($users[2]), 4); //manager
$org->add_users(array($users[3]), 6); //readerplus
$org->save();

/***********************************
 * setup tagable items
 */
$project = new TestProject();
$project->add_orgs(array($org));
$project->save();
$prj_uuid = $project->prj_uuid;

$inquiry = new TestInquiry();
$inquiry->add_projects(array($project));
$inquiry->save();
$inq_uuid = $inquiry->inq_uuid;

$source = new TestSource();
$source->SrcResponseSet[0]->srs_date = air2_date();
$source->SrcResponseSet[0]->srs_inq_id = $inquiry->inq_id;
$source->add_orgs(array($org));
$source->save();
$src_uuid = $source->src_uuid;

$respset = $source->SrcResponseSet[0];
$source->clearRelated();
$srs_uuid = $respset->srs_uuid;

/***********************************
 * test TagMaster, and tags for each item
 */
$tagmaster = new TestTagMaster();
$tagmaster->save();
$tm_id = $tagmaster->tm_id;
$tagdata = array('radix' => json_encode(array('tm_name' => $tagmaster->tm_name)));

$tagp = new TagProject();
$tagp->tag_tm_id = $tm_id;
$tagp->tag_xid = $project->prj_id;
$tagp->save();
$tagi = new TagInquiry();
$tagi->tag_tm_id = $tm_id;
$tagi->tag_xid = $inquiry->inq_id;
$tagi->save();
$tags = new TagSource();
$tags->tag_tm_id = $tm_id;
$tags->tag_xid = $source->src_id;
$tags->save();
$tagr = new TagProject();
$tagr->tag_tm_id = $tm_id;
$tagr->tag_xid = $respset->srs_id;
$tagr->save();

foreach ($users as $user) {
    //diag('user_may_write=' . $tagi->user_may_write($user));
    //diag('user_may_delete=' . $tagi->user_may_delete($user));
}

plan(73);
/***********************************
 * test tagging by reader $users[0]
 */
$browser->set_user($users[0]);

$browser->http_get("/project/$prj_uuid");
is( $browser->resp_code(), 200, 'reader GET project == 200' );
$browser->http_get("/project/$prj_uuid/tag");
is( $browser->resp_code(), 200, 'reader GET project tags == 200' );
$browser->http_post("/project/$prj_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'reader POST project tags == 403' );
$browser->http_delete("/project/$prj_uuid/tag/$tm_id");
is( $browser->resp_code(), 403, 'reader DELETE project tags == 403' );

$browser->http_get("/inquiry/$inq_uuid");
is( $browser->resp_code(), 200, 'reader GET inquiry == 200' );
$browser->http_get("/inquiry/$inq_uuid/tag");
is( $browser->resp_code(), 200, 'reader GET inquiry tags == 200' );
$browser->http_post("/inquiry/$inq_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'reader POST inquiry tags == 403' );
$browser->http_delete("/inquiry/$inq_uuid/tag/$tm_id");
is( $browser->resp_code(), 403, 'reader DELETE inquiry tags == 403' );

$browser->http_get("/source/$src_uuid");
is( $browser->resp_code(), 200, 'reader GET source == 200' );
$browser->http_get("/source/$src_uuid/tag");
is( $browser->resp_code(), 200, 'reader GET source tags == 200' );
$browser->http_post("/source/$src_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'reader POST source tags == 403' );
$browser->http_delete("/source/$src_uuid/tag/$tm_id");
is( $browser->resp_code(), 403, 'reader DELETE source tags == 403' );

$browser->http_get("/submission/$srs_uuid");
is( $browser->resp_code(), 200, 'reader GET submission == 200' );
$browser->http_get("/submission/$srs_uuid/tag");
is( $browser->resp_code(), 200, 'reader GET submission tags == 200' );
$browser->http_post("/submission/$srs_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'reader POST submission tags == 403' );
$r = $browser->http_get("/submission/$srs_uuid/tag/$tm_id");
is( $browser->resp_code(), 404, 'reader GET submission tag == 404' );


/***********************************
 * test tagging by writer $users[1]
 */
$browser->set_user($users[1]);

ok( $project->user_may_write($users[1]), 'may write project' );
$browser->http_get("/project/$prj_uuid");
is( $browser->resp_code(), 200, 'writer GET project == 200' );
$browser->http_get("/project/$prj_uuid/tag");
is( $browser->resp_code(), 200, 'writer GET project tags == 200' );
$browser->http_post("/project/$prj_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'writer POST project tags == 200' );
$browser->http_delete("/project/$prj_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'writer DELETE project tags == 200' );

ok( $inquiry->user_may_write($users[1]), 'may write inquiry' );
$browser->http_get("/inquiry/$inq_uuid");
is( $browser->resp_code(), 200, 'writer GET inquiry == 200' );
$browser->http_get("/inquiry/$inq_uuid/tag");
is( $browser->resp_code(), 200, 'writer GET inquiry tags == 200' );
$browser->http_post("/inquiry/$inq_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'writer POST inquiry tags == 200' );
$browser->http_delete("/inquiry/$inq_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'writer DELETE inquiry tags == 200' );

ok( $source->user_may_write($users[1]), 'may write source' );
$browser->http_get("/source/$src_uuid");
is( $browser->resp_code(), 200, 'writer GET source == 200' );
$browser->http_get("/source/$src_uuid/tag");
is( $browser->resp_code(), 200, 'writer GET source tags == 200' );
$browser->http_post("/source/$src_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'writer POST source tags == 200' );
$browser->http_delete("/source/$src_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'writer DELETE source tags == 200' );

ok( $respset->user_may_write($users[1]), 'may write respset' );
$browser->http_get("/submission/$srs_uuid");
is( $browser->resp_code(), 200, 'writer GET submission == 200' );
$browser->http_get("/submission/$srs_uuid/tag");
is( $browser->resp_code(), 200, 'writer GET submission tags == 200' );
$browser->http_post("/submission/$srs_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'writer POST submission tags == 200' );
$browser->http_delete("/submission/$srs_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'writer DELETE submission tags == 200' );


/***********************************
 * test tagging by manager $users[2]
 */
$browser->set_user($users[2]);

ok( $project->user_may_write($users[2]), 'may write project' );
$browser->http_get("/project/$prj_uuid");
is( $browser->resp_code(), 200, 'manager GET project == 200' );
$browser->http_get("/project/$prj_uuid/tag");
is( $browser->resp_code(), 200, 'manager GET project tags == 200' );
$browser->http_post("/project/$prj_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'manager POST project tags == 200' );
$browser->http_delete("/project/$prj_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'manager DELETE project tags == 200' );

ok( $inquiry->user_may_write($users[2]), 'may write inquiry' );
$browser->http_get("/inquiry/$inq_uuid");
is( $browser->resp_code(), 200, 'manager GET inquiry == 200' );
$browser->http_get("/inquiry/$inq_uuid/tag");
is( $browser->resp_code(), 200, 'manager GET inquiry tags == 200' );
$browser->http_post("/inquiry/$inq_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'manager POST inquiry tags == 200' );
$browser->http_delete("/inquiry/$inq_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'manager DELETE inquiry tags == 200' );

ok( $source->user_may_write($users[2]), 'may write source' );
$browser->http_get("/source/$src_uuid");
is( $browser->resp_code(), 200, 'manager GET source == 200' );
$browser->http_get("/source/$src_uuid/tag");
is( $browser->resp_code(), 200, 'manager GET source tags == 200' );
$browser->http_post("/source/$src_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'manager POST source tags == 200' );
$browser->http_delete("/source/$src_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'manager DELETE source tags == 200' );

ok( $respset->user_may_write($users[2]), 'may write respset' );
$browser->http_get("/submission/$srs_uuid");
is( $browser->resp_code(), 200, 'manager GET submission == 200' );
$browser->http_get("/submission/$srs_uuid/tag");
is( $browser->resp_code(), 200, 'manager GET submission tags == 200' );
$browser->http_post("/submission/$srs_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'manager POST submission tags == 200' );
$browser->http_delete("/submission/$srs_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'manager DELETE submission tags == 200' );

/***********************************
 * test tagging by readerplus $users[3]
 * (only able to tag sources)
 */
$browser->set_user($users[3]);

$browser->http_get("/project/$prj_uuid");
is( $browser->resp_code(), 200, 'readerplusplus GET project == 200' );
$browser->http_get("/project/$prj_uuid/tag");
is( $browser->resp_code(), 200, 'readerplus GET project tags == 200' );
$browser->http_post("/project/$prj_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'readerplus POST project tags == 403' );
$browser->http_get("/project/$prj_uuid/tag/$tm_id");
is( $browser->resp_code(), 404, 'readerplus GET project tag == 404' );

$browser->http_get("/inquiry/$inq_uuid");
is( $browser->resp_code(), 200, 'readerplus GET inquiry == 200' );
$browser->http_get("/inquiry/$inq_uuid/tag");
is( $browser->resp_code(), 200, 'readerplus GET inquiry tags == 200' );
$browser->http_post("/inquiry/$inq_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'readerplus POST inquiry tags == 403' );
$browser->http_get("/inquiry/$inq_uuid/tag/$tm_id");
is( $browser->resp_code(), 404, 'readerplus GET inquiry tag == 404' );

ok( $source->user_may_write($users[3]), 'may write source' );
$browser->http_get("/source/$src_uuid");
is( $browser->resp_code(), 200, 'readerplus GET source == 200' );
$browser->http_get("/source/$src_uuid/tag");
is( $browser->resp_code(), 200, 'readerplus GET source tags == 200' );
$browser->http_post("/source/$src_uuid/tag", $tagdata);
is( $browser->resp_code(), 200, 'readerplus POST source tags == 200' );
$browser->http_delete("/source/$src_uuid/tag/$tm_id");
is( $browser->resp_code(), 200, 'readerplus DELETE source tags == 200' );

$browser->http_get("/submission/$srs_uuid");
is( $browser->resp_code(), 200, 'readerplus GET submission == 200' );
$browser->http_get("/submission/$srs_uuid/tag");
is( $browser->resp_code(), 200, 'readerplus GET submission tags == 200' );
$browser->http_post("/submission/$srs_uuid/tag", $tagdata);
is( $browser->resp_code(), 403, 'readerplus POST submission tags == 403' );
$browser->http_get("/submission/$srs_uuid/tag/$tm_id");
is( $browser->resp_code(), 404, 'readerplus GET submission tags == 404' );
