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
require_once APPPATH.'../tests/models/TestBin.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestSource.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';

plan(63);
AIR2_DBManager::init();

// query helpers
function query_bsrc($bin, $user, $authz='read') {
    $q = Doctrine_Query::create()->from('BinSource bs');
    $q->andWhere('bs.bsrc_bin_id = ?', $bin->bin_id);
    if ($authz == 'read') {
        BinSource::query_may_read($q, $user);
    }
    else {
        BinSource::query_may_write($q, $user);
    }
    return $q->execute();
}
function query_bsrs($bin, $user, $authz='read') {
    $q = Doctrine_Query::create()->from('BinSrcResponseSet bs');
    $q->andWhere('bs.bsrs_bin_id = ?', $bin->bin_id);
    if ($authz == 'read') {
        BinSrcResponseSet::query_may_read($q, $user);
    }
    else {
        BinSrcResponseSet::query_may_write($q, $user);
    }
    return $q->execute();
}

// test user
$u = new TestUser();
$u->save();

// test organizations
$o1 = new TestOrganization();
$o1->add_users(array($u), 2); //reader
$o1->save();
$o2_na = new TestOrganization();
$o2_na->save();

// test projects
$p1 = new TestProject();
$p1->add_orgs(array($o1));
$p1->save();
$p2_na = new TestProject();
$p2_na->add_orgs(array($o2_na));
$p2_na->save();

// test inquiries
$i1 = new TestInquiry();
$i1->add_projects(array($p1));
$i1->save();
$i2_na = new TestInquiry();
$i2_na->add_projects(array($p2_na));
$i2_na->save();

// test sources
$s1 = new TestSource();
$s1->add_orgs(array($o1));
$s1->save();
$s2 = new TestSource();
$s2->add_orgs(array($o1));
$s2->save();
$s3_na = new TestSource();
$s3_na->add_orgs(array($o2_na));
$s3_na->save();
$s4_na = new TestSource();
$s4_na->add_orgs(array($o2_na));
$s4_na->save();
$s5_na = new TestSource();
$s5_na->add_orgs(array($o2_na));
$s5_na->save();

// test responses
$r1 = new SrcResponseSet();
$r1->Source = $s1;
$r1->Inquiry = $i1;
$r1->srs_date = air2_date();
$r1->save();
$r2_na = new SrcResponseSet();
$r2_na->Source = $s1;
$r2_na->Inquiry = $i2_na;
$r2_na->srs_date = air2_date();
$r2_na->save();
$r3 = new SrcResponseSet();
$r3->Source = $s3_na;
$r3->Inquiry = $i1;
$r3->srs_date = air2_date();
$r3->save();
$r4_na = new SrcResponseSet();
$r4_na->Source = $s4_na;
$r4_na->Inquiry = $i2_na;
$r4_na->srs_date = air2_date();
$r4_na->save();


/**********************
 * Verify authz assumptions about the test data so far
 */
ok( $p1->user_may_read($u),     "verify - p1 read" );
ok( !$p2_na->user_may_read($u), "verify - p2 read n/a" );
ok( $i1->user_may_read($u),     "verify - i1 read" );
ok( !$i2_na->user_may_read($u), "verify - i2 read n/a" );
ok( $s1->user_may_read($u),     "verify - s1 read" );
ok( $s2->user_may_read($u),     "verify - s2 read" );
ok( !$s3_na->user_may_read($u), "verify - s3 read n/a" );
ok( !$s4_na->user_may_read($u), "verify - s4 read n/a" );
ok( !$s5_na->user_may_read($u), "verify - s5 read n/a" );

ok( $r1->user_may_read($u),     "verify - r1 read" );
ok( !$r2_na->user_may_read($u), "verify - r2 read n/a" );
ok( $r3->user_may_read($u),     "verify - r3 read" );
ok( !$r4_na->user_may_read($u), "verify - r4 read n/a" );


/**********************
 * Add this stuff to a bin
 */
$bin = new TestBin();
$bin->User = $u;
$bin->BinSource[0]->bsrc_src_id = $s1->src_id;
$bin->BinSource[1]->bsrc_src_id = $s2->src_id;
$bin->BinSource[2]->bsrc_src_id = $s3_na->src_id;
$bin->BinSource[3]->bsrc_src_id = $s4_na->src_id;
$bin->BinSource[4]->bsrc_src_id = $s5_na->src_id;
$bin->BinSrcResponseSet[0]->bsrs_srs_id = $r1->srs_id;
$bin->BinSrcResponseSet[0]->bsrs_inq_id = $r1->srs_inq_id;
$bin->BinSrcResponseSet[0]->bsrs_src_id = $r1->srs_src_id;
$bin->BinSrcResponseSet[1]->bsrs_srs_id = $r2_na->srs_id;
$bin->BinSrcResponseSet[1]->bsrs_inq_id = $r2_na->srs_inq_id;
$bin->BinSrcResponseSet[1]->bsrs_src_id = $r2_na->srs_src_id;
$bin->BinSrcResponseSet[2]->bsrs_srs_id = $r3->srs_id;
$bin->BinSrcResponseSet[2]->bsrs_inq_id = $r3->srs_inq_id;
$bin->BinSrcResponseSet[2]->bsrs_src_id = $r3->srs_src_id;
$bin->BinSrcResponseSet[3]->bsrs_srs_id = $r4_na->srs_id;
$bin->BinSrcResponseSet[3]->bsrs_inq_id = $r4_na->srs_inq_id;
$bin->BinSrcResponseSet[3]->bsrs_src_id = $r4_na->srs_src_id;
$bin->save();

// shortcuts
$bsrc1 = $bin->BinSource[0];
$bsrc1_r1 = $bin->BinSrcResponseSet[0];
$bsrc1_r2 = $bin->BinSrcResponseSet[1];
$bsrc2 = $bin->BinSource[1];
$bsrc3 = $bin->BinSource[2];
$bsrc3_r1 = $bin->BinSrcResponseSet[2];
$bsrc4 = $bin->BinSource[3];
$bsrc4_r1 = $bin->BinSrcResponseSet[3];
$bsrc5 = $bin->BinSource[4];


/**********************
 * Test authz-as-owner
 */
is( $bin->user_may_read($u),   AIR2_AUTHZ_IS_OWNER, "bin owner - read" );
is( $bin->user_may_write($u),  AIR2_AUTHZ_IS_OWNER, "bin owner - write" );
is( $bin->user_may_manage($u), AIR2_AUTHZ_IS_OWNER, "bin owner - manage" );

is( $bsrc1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,     "bsrc1 owner - read" );
is( $bsrc2->user_may_read($u),  AIR2_AUTHZ_IS_ORG,     "bsrc2 owner - read" );
is( $bsrc3->user_may_read($u),  AIR2_AUTHZ_IS_PROJECT, "bsrc3 owner - read" );
is( $bsrc4->user_may_read($u),  AIR2_AUTHZ_IS_DENIED,  "bsrc4 owner - read n/a" );
is( $bsrc5->user_may_read($u),  AIR2_AUTHZ_IS_DENIED,  "bsrc5 owner - read n/a" );
is( $bsrc1->user_may_write($u), AIR2_AUTHZ_IS_OWNER,   "bsrc1 owner - write" );
is( $bsrc2->user_may_write($u), AIR2_AUTHZ_IS_OWNER,   "bsrc2 owner - write" );
is( $bsrc3->user_may_write($u), AIR2_AUTHZ_IS_OWNER,   "bsrc3 owner - write" );
is( $bsrc4->user_may_write($u), AIR2_AUTHZ_IS_OWNER,   "bsrc4 owner - write" );
is( $bsrc5->user_may_write($u), AIR2_AUTHZ_IS_OWNER,   "bsrc5 owner - write" );

is( $bsrc1_r1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    "bsrc1 r1 owner - read" );
is( $bsrc1_r2->user_may_read($u),  AIR2_AUTHZ_IS_DENIED, "bsrc1 r2 owner - read n/a" );
is( $bsrc3_r1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    "bsrc1 r1 owner - read" );
is( $bsrc4_r1->user_may_read($u),  AIR2_AUTHZ_IS_DENIED, "bsrc1 r1 owner - read n/a" );
is( $bsrc1_r1->user_may_write($u), AIR2_AUTHZ_IS_OWNER,  "bsrc1 r1 owner - write" );
is( $bsrc1_r2->user_may_write($u), AIR2_AUTHZ_IS_OWNER,  "bsrc1 r2 owner - write" );
is( $bsrc3_r1->user_may_write($u), AIR2_AUTHZ_IS_OWNER,  "bsrc1 r1 owner - write" );
is( $bsrc4_r1->user_may_write($u), AIR2_AUTHZ_IS_OWNER,  "bsrc1 r1 owner - write" );

is( count(query_bsrc($bin, $u)),          3, "query bsrc owner - read count" );
is( count(query_bsrc($bin, $u, 'write')), 5, "query bsrc owner - write count" );
is( count(query_bsrs($bin, $u)),          2, "query bsrs owner - read count" );
is( count(query_bsrs($bin, $u, 'write')), 4, "query bsrs owner - write count" );


/**********************
 * Test authz-as-sharer
 */
$bin->bin_user_id = 1;
$bin->bin_shared_flag = true;
$bin->save();
$bin->refresh(true);

is( $bin->user_may_read($u),   AIR2_AUTHZ_IS_PUBLIC, "bin sharer - read" );
is( $bin->user_may_write($u),  AIR2_AUTHZ_IS_DENIED, "bin sharer - write" );
is( $bin->user_may_manage($u), AIR2_AUTHZ_IS_DENIED, "bin sharer - manage" );

is( $bsrc1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,     "bsrc1 sharer - read" );
is( $bsrc2->user_may_read($u),  AIR2_AUTHZ_IS_ORG,     "bsrc2 sharer - read" );
is( $bsrc3->user_may_read($u),  AIR2_AUTHZ_IS_PROJECT, "bsrc3 sharer - read" );
is( $bsrc4->user_may_read($u),  AIR2_AUTHZ_IS_DENIED,  "bsrc4 sharer - read n/a" );
is( $bsrc5->user_may_read($u),  AIR2_AUTHZ_IS_DENIED,  "bsrc5 sharer - read n/a" );
is( $bsrc1->user_may_write($u), AIR2_AUTHZ_IS_DENIED,  "bsrc1 sharer - write n/a" );
is( $bsrc2->user_may_write($u), AIR2_AUTHZ_IS_DENIED,  "bsrc2 sharer - write n/a" );
is( $bsrc3->user_may_write($u), AIR2_AUTHZ_IS_DENIED,  "bsrc3 sharer - write n/a" );
is( $bsrc4->user_may_write($u), AIR2_AUTHZ_IS_DENIED,  "bsrc4 sharer - write n/a" );
is( $bsrc5->user_may_write($u), AIR2_AUTHZ_IS_DENIED,  "bsrc5 sharer - write n/a" );

is( $bsrc1_r1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    "bsrc1 r1 sharer - read" );
is( $bsrc1_r2->user_may_read($u),  AIR2_AUTHZ_IS_DENIED, "bsrc1 r2 sharer - read n/a" );
is( $bsrc3_r1->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    "bsrc1 r1 sharer - read" );
is( $bsrc4_r1->user_may_read($u),  AIR2_AUTHZ_IS_DENIED, "bsrc1 r1 sharer - read n/a" );
is( $bsrc1_r1->user_may_write($u), AIR2_AUTHZ_IS_DENIED, "bsrc1 r1 sharer - write n/a" );
is( $bsrc1_r2->user_may_write($u), AIR2_AUTHZ_IS_DENIED, "bsrc1 r2 sharer - write n/a" );
is( $bsrc3_r1->user_may_write($u), AIR2_AUTHZ_IS_DENIED, "bsrc1 r1 sharer - write n/a" );
is( $bsrc4_r1->user_may_write($u), AIR2_AUTHZ_IS_DENIED, "bsrc1 r1 sharer - write n/a" );

is( count(query_bsrc($bin, $u)),          3, "query bsrc sharer - read count" );
is( count(query_bsrc($bin, $u, 'write')), 0, "query bsrc sharer - write count" );
is( count(query_bsrs($bin, $u)),          2, "query bsrs sharer - read count" );
is( count(query_bsrs($bin, $u, 'write')), 0, "query bsrs sharer - write count" );
