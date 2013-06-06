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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AirTestUtils.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestSource.php';
require_once 'models/TestInquiry.php';
require_once 'models/TestBin.php';
require_once 'models/TestTank.php';
require_once 'models/TestTagMaster.php';
require_once 'AIR2Merge.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// test data
$prime = new TestSource();
$prime->src_username = 'PRIMEUSER1234';
$prime->src_first_name = 'Harold';
$prime->src_last_name = 'Blah';
$prime->src_middle_initial = 'T';
$prime->src_pre_name = null;
$prime->src_post_name = 'Senior';
$prime->src_status = Source::$STATUS_ENROLLED;
$prime->src_has_acct = Source::$ACCT_NO;
$prime->src_channel = Source::$CHANNEL_EVENT;
$prime->save();

$merge = new TestSource();
$merge->src_username = 'MERGEUSER1234';
$merge->src_first_name = 'Steven';
$merge->src_last_name = 'Blah';
$merge->src_middle_initial = 'L';
$merge->src_pre_name = 'Duke';
$merge->src_post_name = 'Junior';
$merge->src_status = Source::$STATUS_ENGAGED;
$merge->src_has_acct = Source::$ACCT_YES;
$merge->src_channel = Source::$CHANNEL_QUERY;
$merge->save();

$u = new TestUser();
$u->save();
define('AIR2_REMOTE_USER_ID', $u->user_id);

$o = new TestOrganization();
$o->add_users(array($u), 4); //MANAGER
$o->save();
$o2 = new TestOrganization();
$o2->save();
$o3 = new TestOrganization();
$o3->save();
$o4 = new TestOrganization();
$o4->save();

$p = new TestProject();
$p->add_orgs(array($o));
$p->save();

$i = new TestInquiry();
$i->add_projects(array($p));
$i->Question[0]->ques_value = 'test question 1';
$i->Question[1]->ques_value = 'test question 2';
$i->save();

$b = new TestBin();
$b->save();
$t = new TestTank();
$t->tank_user_id = $u->user_id;
$t->save();
$tm = new TestTagMaster();
$tm->save();

// fetch facts/fact-values
$facts;
$fact_values;
$q = Doctrine_Query::create()->from('Fact f');
$q->leftJoin('f.FactValue fv');
$rs = $q->fetchArray();
foreach ($rs as $row) {
    $ident = $row['fact_identifier'];
    $facts[$ident] = $row['fact_id'];
    $fact_values[$ident] = array();
    foreach ($row['FactValue'] as $fv) {
        $fact_values[$ident][] = $fv['fv_id'];
    }
}

plan(92);

/**********************
 * Merge someone with a SOURCE account (fail)
 */
$r = AIR2Merge::merge($prime, $merge);
ok( $r !== true, 'merge with acct - failure' );
ok( is_string($r), 'merge with acct - is_string' );
is( count($r), 1, 'merge with acct - returned early' );
ok( preg_match('/source account/i', $r), 'merge with acct - account error' );
$merge->src_has_acct = Source::$ACCT_NO;
$merge->save();

/**********************
 * Merge without opts
 */
$r = AIR2Merge::merge($prime, $merge);
ok( is_array($r), 'merge no-opts - is_array' );
is( count($r), 3, 'merge no-opts - 3 conflicts' );
ok( is_array($r[0]), 'merge no-opts - conflict is array' );
ok( isset($r[0]['Source']), 'merge no-opts - conflict model Source' );
ok( preg_match('/src_first_name/', $r[0]['Source']), 'merge no-opts - first name conflict' );

/**********************
 * Merge with opts (simulate)
 */
$src_opts = array(
    'src_first_name'     => AIR2Merge::OPTMERGE,
    'src_middle_initial' => AIR2Merge::OPTPRIME,
);
$r = AIR2Merge::merge($prime, $merge, array('Source' => $src_opts));
ok( is_array($r), 'merge 2-opts - is array' );
is( count($r), 1, 'merge 2-opts - 1 conflict' );
ok( isset($r[0]['Source']), 'merge 2-opts - conflict model Source' );
ok( preg_match('/src_post_name/', $r[0]['Source']), 'merge 2-opts - post name conflict' );

$src_opts['src_post_name'] = AIR2Merge::OPTMERGE;
$r = AIR2Merge::merge($prime, $merge, array('Source' => $src_opts));
is( $r, true, 'merge 3-opts - success' );

// verify that it was only a simulation
ok( $merge && $merge->exists(), 'simulation - merge exists' );
is( $prime->src_first_name, 'Harold', 'simulation - prime unchanged' );

/**********************
 * Merge for-realz
 */
AIR2Merge::merge($prime, $merge, array('Source' => $src_opts), true);
ok( !$merge || !$merge->exists(), 'realz - merge deleted' );
is( $prime->src_username, 'PRIMEUSER1234', 'realz - prime src_username' );
is( $prime->src_first_name, 'Steven', 'realz - prime src_first_name' );
is( $prime->src_middle_initial, 'T', 'realz - prime src_middle_initial' );
is( $prime->src_pre_name, 'Duke', 'realz - prime src_pre_name' );
is( $prime->src_post_name, 'Junior', 'realz - prime src_post_name' );
//is( $prime->src_status, Source::$STATUS_ENROLLED, 'realz - prime src_status' );
is( $prime->src_has_acct, Source::$ACCT_NO, 'realz - prime src_has_acct' );
is( $prime->src_channel, Source::$CHANNEL_EVENT, 'realz - prime src_channel' );

/**********************
 * SETUP FACTS
 */
$merge = new TestSource();
$merge->src_first_name = $prime->src_first_name;
$merge->save();

// fact prime-only
$prime_gender = new SrcFact();
$prime_gender->sf_src_id = $prime->src_id;
$prime_gender->sf_fact_id = $facts['gender'];
$prime_gender->sf_fv_id = $fact_values['gender'][0];
$prime_gender->sf_src_value = 'testing';
$prime_gender->sf_src_fv_id = $fact_values['gender'][1];
$prime_gender->save();

// fact merge-only
$merge_income = new SrcFact();
$merge_income->sf_src_id = $merge->src_id;
$merge_income->sf_fact_id = $facts['household_income'];
$merge_income->sf_fv_id = $fact_values['household_income'][0];
$merge_income->sf_src_fv_id = $fact_values['household_income'][1];
$merge_income->save();

// fact both --- clean merge
$prime_ethn = new SrcFact();
$prime_ethn->sf_src_id = $prime->src_id;
$prime_ethn->sf_fact_id = $facts['ethnicity'];
$prime_ethn->sf_fv_id = $fact_values['ethnicity'][0];
$prime_ethn->sf_src_value = 'testing';
$prime_ethn->save();
$merge_ethn = new SrcFact();
$merge_ethn->sf_src_id = $merge->src_id;
$merge_ethn->sf_fact_id = $facts['ethnicity'];
$merge_ethn->sf_fv_id = $fact_values['ethnicity'][0];
$merge_ethn->sf_src_fv_id = $fact_values['ethnicity'][1];
$merge_ethn->save();

// fact both --- messy merge
$prime_rel = new SrcFact();
$prime_rel->sf_src_id = $prime->src_id;
$prime_rel->sf_fact_id = $facts['religion'];
$prime_rel->sf_fv_id = $fact_values['religion'][0];
$prime_rel->sf_src_fv_id = $fact_values['religion'][1];
$prime_rel->sf_src_value = 'testing';
$prime_rel->save();
$merge_rel = new SrcFact();
$merge_rel->sf_src_id = $merge->src_id;
$merge_rel->sf_fact_id = $facts['religion'];
$merge_rel->sf_fv_id = $fact_values['religion'][2];
$merge_rel->sf_src_fv_id = $fact_values['religion'][3];
$merge_rel->sf_src_value = 'testing2';
$merge_rel->save();

$gid = $facts['gender'];
$hid = $facts['household_income'];
$eid = $facts['ethnicity'];
$rid = $facts['religion'];

/**********************
 * Merge facts
 */
$opts = array();
$r = AIR2Merge::merge($prime, $merge, $opts);
ok( is_array($r), 'merge facts - is_array' );
$rid = $facts['religion'];
is( count($r), 3, 'merge facts - 3 conflicts' );
foreach ($r as $idx => $confl) {
    ok( is_array($confl), "merge facts $idx - is_array" );
    ok( isset($confl["Fact.$rid"]), "merge facts $idx - on Fact religion" );
    $cols = array('sf_fv_id', 'sf_src_fv_id', 'sf_src_value');
    ok( in_array($confl["Fact.$rid"], $cols), "merge facts $idx - column" );
}

$opts["Fact.$rid"] = AIR2Merge::OPTPRIME;
$r = AIR2Merge::merge($prime, $merge, $opts);
is( $r, true, 'merge facts allopts' );

$opts["Fact.$rid"] = array('sf_fv_id' => AIR2Merge::OPTMERGE);
$r = AIR2Merge::merge($prime, $merge, $opts);
is( count($r), 2, 'merge facts - 2 conflicts' );
foreach ($r as $idx => $confl) {
    ok( is_array($confl), "merge facts $idx - is_array" );
    ok( isset($confl["Fact.$rid"]), "merge facts $idx - on Fact religion" );
    $cols = array('sf_src_fv_id', 'sf_src_value');
    ok( in_array($confl["Fact.$rid"], $cols), "merge facts $idx - column" );
}

$opts["Fact.$rid"]['sf_src_value'] = AIR2Merge::OPTPRIME;
$r = AIR2Merge::merge($prime, $merge, $opts);

is( count($r), 1, 'merge facts - 1 conflict' );
ok( is_array($r[0]), "merge facts 0 - is_array" );
ok( isset($r[0]["Fact.$rid"]), "merge facts 0 - on Fact religion" );
is( $r[0]["Fact.$rid"], 'sf_src_fv_id', "merge facts 0 - column" );

$opts["Fact.$rid"]['sf_src_fv_id'] = AIR2Merge::OPTMERGE;
$r = AIR2Merge::merge($prime, $merge, $opts);
is( $r, true, 'merge facts conflicts resolved' );

/**********************
 * Merge facts for-realz
 */
$r = AIR2Merge::merge($prime, $merge, $opts, true);
is( $r, true, 'facts realz' );
ok( !$merge || !$merge->exists(), 'facts realz - merge deleted' );
$prime->clearRelated();
is( $prime->SrcFact->count(), 4, 'facts realz - 4 SrcFacts' );


/**********************
 * Setup a whole bunch-o'-data
 */
$prime->SrcEmail[0]->sem_email = $prime->src_uuid.'email@test.com';
$prime->SrcEmail[0]->sem_primary_flag = true;
$prime->save();

// basic data
$merge = new TestSource();
$merge->SrcAlias[0]->sa_name = 'aliasname';
$merge->SrcAlias[0]->sa_first_name = 'aliasfirstname';
$merge->SrcAlias[0]->sa_upd_user = 1;
$merge->SrcAnnotation[0]->srcan_value = 'annotationhere';
$eml1 = air2_generate_uuid().'email@test.com';
$eml2 = air2_generate_uuid().'email@test.com';
$merge->SrcEmail[0]->sem_email = $eml1;
$merge->SrcEmail[0]->sem_primary_flag = false;
$merge->SrcEmail[1]->sem_email = $eml2;
$merge->SrcEmail[1]->sem_primary_flag = false;
$merge->SrcMailAddress[0]->smadd_city = 'nowhere';
$merge->SrcPhoneNumber[0]->sph_number = '5555555555';
$merge->SrcUri[0]->suri_primary_flag = true;
$merge->SrcUri[0]->suri_type = 'T';
$merge->SrcUri[0]->suri_value = 'test';
$merge->SrcUri[0]->suri_handle = 'test';
$merge->SrcVita[0]->sv_notes = 'something';
$merge->save();

// inquiry and response
$merge->SrcInquiry[0]->si_inq_id = $i->inq_id;
$merge->SrcResponseSet[0]->srs_inq_id = $i->inq_id;
$merge->SrcResponseSet[0]->srs_date = air2_date();
$merge->SrcResponseSet[0]->SrcResponse[0]->sr_src_id = $merge->src_id;
$merge->SrcResponseSet[0]->SrcResponse[0]->sr_ques_id = $i->Question[0]->ques_id;
$merge->SrcResponseSet[0]->SrcResponse[0]->sr_orig_value = 'blah';
$merge->SrcResponseSet[0]->SrcResponse[1]->sr_src_id = $merge->src_id;
$merge->SrcResponseSet[0]->SrcResponse[1]->sr_ques_id = $i->Question[1]->ques_id;
$merge->SrcResponseSet[0]->SrcResponse[1]->sr_orig_value = 'blah2';
$merge->save();

// SrcActivity, including duplicates
$sact1 = new SrcActivity();
$sact1->sact_actm_id = ActivityMaster::SRCINFO_UPDATED;
$sact1->sact_src_id = $prime->src_id;
$sact1->sact_prj_id = 1;
$sact1->sact_dtim = air2_date();
$sact1->save();
$sact2 = new SrcActivity();
$sact2->sact_actm_id = ActivityMaster::SRCINFO_UPDATED;
$sact2->sact_src_id = $merge->src_id;
$sact2->sact_prj_id = 1;
$sact2->sact_dtim = $sact1->sact_dtim;
$sact2->save();
$sact3 = new SrcActivity();
$sact3->sact_actm_id = ActivityMaster::SRCINFO_UPDATED;
$sact3->sact_src_id = $merge->src_id;
$sact3->sact_prj_id = $p->prj_id;
$sact3->sact_dtim = air2_date();
$sact3->save();

// bin, tags, tank, and trackback
$b->BinSource[]->bsrc_src_id = $merge->src_id;
$b->save();
$tm->Tag[0]->tag_ref_type = Tag::$TYPE_SOURCE;
$tm->Tag[0]->tag_xid = $merge->src_id;
$tm->save();
$t->TankSource[0]->src_id = $merge->src_id;
$t->save();
$tb = new Trackback();
$tb->tb_src_id = $merge->src_id;
$tb->tb_user_id = $u->user_id;
$tb->tb_ip = 1;
$tb->tb_dtim = air2_date();
$tb->save();

// src_orgs
$prime->add_orgs(array($o), SrcOrg::$STATUS_OPTED_OUT);
$prime->add_orgs(array($o2), SrcOrg::$STATUS_DELETED);
$prime->add_orgs(array($o3), SrcOrg::$STATUS_OPTED_IN);
$prime->save();
$merge->add_orgs(array($o), SrcOrg::$STATUS_OPTED_IN);
$merge->add_orgs(array($o2), SrcOrg::$STATUS_EDITORIAL_DEACTV);
$merge->add_orgs(array($o3), SrcOrg::$STATUS_OPTED_OUT);
$merge->add_orgs(array($o4), SrcOrg::$STATUS_DELETED);
$merge->save();

// src_stat
$old_time = air2_date(strtotime('-1 week'));
$mid_time = air2_date(strtotime('-1 day'));
$new_time = air2_date();
$prime->SrcStat->sstat_export_dtim = $old_time;
$prime->SrcStat->sstat_contact_dtim = $mid_time;
$prime->SrcStat->sstat_submit_dtim = $new_time;
$prime->save();
$merge->SrcStat->sstat_export_dtim = $new_time;
$merge->SrcStat->sstat_contact_dtim = $new_time;
$merge->SrcStat->sstat_submit_dtim = $old_time;
$merge->save();

// check some initial values
$sa_id = $merge->SrcAlias[0]->sa_id;
$conn->exec("update src_alias set sa_upd_user = 1 where sa_id = $sa_id");
$merge->SrcAlias[0]->refresh();
isnt( $merge->SrcAlias[0]->sa_upd_user, $u->user_id, 'initial SrcAlias upd_user' );
is( $b->BinSource->count(), 1, 'initial 1 bin source' );
is( $prime->SrcActivity->count(), 1, 'initial 1 prime src_activity' );


/**********************
 * Run merge on a slew of stuff
 */
$opts = array('Source' => AIR2Merge::OPTPRIME);
$r = AIR2Merge::merge($prime, $merge, $opts, true);
is( $r, true, 'alias' );
ok( !$merge || !$merge->exists(), 'slew - merge deleted' );
$prime->clearRelated();

// basic data
is( $prime->SrcAlias->count(), 1, 'slew - 1 SrcAlias' );
is( $prime->SrcAlias[0]->sa_upd_user, $u->user_id, 'slew - 1 SrcAlias' );
is( $prime->SrcAnnotation->count(), 1, 'slew - 1 SrcAnnotation' );
is( $prime->SrcEmail->count(), 3, 'slew - 3 SrcEmail' );
is( $prime->SrcEmail[1]->sem_email, $eml1, 'slew - SrcEmail 1' );
is( $prime->SrcEmail[1]->sem_primary_flag, false, 'slew - SrcEmail 1 primary unset' );
is( $prime->SrcEmail[2]->sem_email, $eml2, 'slew - SrcEmail 2' );
is( $prime->SrcEmail[2]->sem_primary_flag, false, 'slew - SrcEmail 2 primary unset' );
is( $prime->SrcMailAddress->count(), 1, 'slew - 1 mail address' );
is( $prime->SrcMailAddress[0]->smadd_primary_flag, true, 'slew - mail address primary' );
is( $prime->SrcPhoneNumber->count(), 1, 'slew - 1 phone number' );
is( $prime->SrcPhoneNumber[0]->sph_primary_flag, true, 'slew - phone primary' );
is( $prime->SrcUri->count(), 1, 'slew - 1 uri' );
is( $prime->SrcUri[0]->suri_primary_flag, true, 'slew - uri primary' );
is( $prime->SrcVita->count(), 1, 'slew - 1 vita' );

// inquiry and responses
is( $prime->SrcInquiry->count(), 1, 'slew - 1 SrcInquiry' );
is( $prime->SrcResponseSet->count(), 1, 'slew - 1 SrcResponseSet' );
is( $prime->SrcResponse->count(), 2, 'slew - 2 SrcResponse' );

// activity
is( $prime->SrcActivity->count(), 3, 'slew - 3 SrcActivity (includes duplicates now)' );

// bin, tags, tank, and trackback
is( $prime->BinSource->count(), 1, 'slew - 1 BinSource' );
is( $prime->Tags->count(), 1, 'slew - 1 Tag' );
is( $prime->TankSource->count(), 1, 'slew - 1 TankSource' );
is( $prime->Trackback->count(), 1, 'slew - 1 Trackback' );

// src_orgs
is( $prime->SrcOrg->count(), 4, 'slew - 4 orgs' );
is( $prime->SrcOrg[0]->so_org_id, $o->org_id, 'slew - org1' );
is( $prime->SrcOrg[0]->so_status, SrcOrg::$STATUS_OPTED_IN, 'slew - org1 status' );
is( $prime->SrcOrg[1]->so_org_id, $o2->org_id, 'slew - org2' );
is( $prime->SrcOrg[1]->so_status, SrcOrg::$STATUS_EDITORIAL_DEACTV, 'slew - org2 status' );
is( $prime->SrcOrg[2]->so_org_id, $o3->org_id, 'slew - org3' );
is( $prime->SrcOrg[2]->so_status, SrcOrg::$STATUS_OPTED_IN, 'slew - org3 status' );
is( $prime->SrcOrg[3]->so_org_id, $o4->org_id, 'slew - org4' );
is( $prime->SrcOrg[3]->so_status, SrcOrg::$STATUS_DELETED, 'slew - org4 status' );
is( $prime->SrcOrgCache->count(), 3, 'slew - 3 src_org_cache' );

// src_stat
is( $prime->SrcStat->sstat_export_dtim, $new_time, 'slew - src_stat export' );
is( $prime->SrcStat->sstat_contact_dtim, $new_time, 'slew - src_stat contact' );
is( $prime->SrcStat->sstat_submit_dtim, $new_time, 'slew - src_stat submit' );
