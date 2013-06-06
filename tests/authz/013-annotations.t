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
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestSource.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';

plan(60);
AIR2_DBManager::init();

// create test users
$usr = new TestUser();
$usr->save();
$manager = new TestUser();
$manager->save();
$writer = new TestUser();
$writer->save();
$noaccess = new TestUser();
$noaccess->save();


// test organization
$org = new TestOrganization();
$org->add_users(array($usr), 2);     //reader
$org->add_users(array($manager), 4); //manager
$org->add_users(array($writer), 3);  //writer
$org->save();


// annotate-able stuff
$src = new TestSource();
$src->add_orgs(array($org));
$src->save();

$prj = new TestProject();
$prj->add_orgs(array($org));
$prj->save();

$inq = new TestInquiry();
$inq->add_projects(array($prj));
$inq->save();

$ques = new Question();
$ques->ques_inq_id = $inq->inq_id;
$ques->ques_value = "test question";
$ques->save();

$srs = new SrcResponseSet();
$srs->srs_date = air2_date();
$srs->srs_src_id = $src->src_id;
$srs->srs_inq_id = $inq->inq_id;
$srs->save();

$sr = new SrcResponse();
$sr->sr_src_id = $src->src_id;
$sr->sr_srs_id = $srs->srs_id;
$sr->sr_ques_id = $ques->ques_id;
$sr->save();


// helper function to test annotating capabilities
function test_annotating($annot_rec, $str) {
    global $usr, $manager, $writer, $noaccess;

    is( $annot_rec->user_may_write($usr), AIR2_AUTHZ_IS_NEW, "$str - reader create" );
    is( $annot_rec->user_may_write($writer), AIR2_AUTHZ_IS_NEW, "$str - writer create" );
    is( $annot_rec->user_may_write($manager), AIR2_AUTHZ_IS_NEW, "$str - manager create" );
    is( $annot_rec->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "$str - noaccess create" );

    $annot_rec["{$str}_cre_user"] = $usr->user_id;
    $annot_rec->save();

    is( $annot_rec->user_may_write($usr), AIR2_AUTHZ_IS_OWNER, "$str - owned - reader write" );
    is( $annot_rec->user_may_manage($usr), AIR2_AUTHZ_IS_OWNER, "$str - owned - reader manage" );
    is( $annot_rec->user_may_write($writer), AIR2_AUTHZ_IS_DENIED, "$str - owned - writer write" );
    is( $annot_rec->user_may_manage($writer), AIR2_AUTHZ_IS_DENIED, "$str - owned - writer manage" );
    is( $annot_rec->user_may_write($manager), AIR2_AUTHZ_IS_MANAGER, "$str - owned - manager write" );
    is( $annot_rec->user_may_manage($manager), AIR2_AUTHZ_IS_MANAGER, "$str - owned - manager manage" );
    is( $annot_rec->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "$str - owned - noaccess write" );
    is( $annot_rec->user_may_manage($noaccess), AIR2_AUTHZ_IS_DENIED, "$str - owned - noaccess manage" );
}


/**********************
 * SrcAnnotation
 */
$srcan = new SrcAnnotation();
$srcan->srcan_src_id = $src->src_id;
$srcan->srcan_value = 'blah';
test_annotating($srcan, 'srcan');

/**********************
 * ProjectAnnotation
 */
$prjan = new ProjectAnnotation();
$prjan->prjan_prj_id = $prj->prj_id;
$prjan->prjan_value = 'blah';
test_annotating($prjan, 'prjan');

/**********************
 * InquiryAnnotation
 */
$inqan = new InquiryAnnotation();
$inqan->inqan_inq_id = $inq->inq_id;
$inqan->inqan_value = 'blah';
test_annotating($inqan, 'inqan');

/**********************
 * SrsAnnotation
 */
$srsan = new SrsAnnotation();
$srsan->srsan_srs_id = $srs->srs_id;
$srsan->srsan_value = 'blah';
test_annotating($srsan, 'srsan');

/**********************
 * SrAnnotation
 */
$sran = new SrAnnotation();
$sran->sran_sr_id = $sr->sr_id;
$sran->sran_value = 'blah';
test_annotating($sran, 'sran');
