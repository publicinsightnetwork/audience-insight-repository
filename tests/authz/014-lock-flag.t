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
require_once APPPATH.'../tests/models/TestSource.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// some facts
$tbl_fact = Doctrine::getTable('Fact');
$tbl_fact_value = Doctrine::getTable('FactValue');
$fact_income = $tbl_fact->findOneBy('fact_identifier', 'household_income');
$fact_gender = $tbl_fact->findOneBy('fact_identifier', 'gender');
$fact_born   = $tbl_fact->findOneBy('fact_identifier', 'birth_year');
$fv_income_1 = $tbl_fact_value->findOneBy('fv_value', 'Less than $15000');
$fv_income_2 = $tbl_fact_value->findOneBy('fv_value', '$15000-$50000');
$fv_income_3 = $tbl_fact_value->findOneBy('fv_value', '$50001-$100000');
$fv_gender_1 = $tbl_fact_value->findOneBy('fv_value', 'Male');
$fv_gender_2 = $tbl_fact_value->findOneBy('fv_value', 'Female');
$fv_gender_3 = $tbl_fact_value->findOneBy('fv_value', 'Transgender');

/**********************
 * Setup
 */
$u = new TestUser();
$u->save();

$o = new TestOrganization();
$o->add_users(array($u), 3); //WRITER
$o->save();

$src = new TestSource();
$src->src_first_name = 'Harold';
$src->save();

$alias = new SrcAlias();
$alias->Source = $src;
$alias->sa_first_name = 'Reggie';
$alias->save();

$email = new SrcEmail();
$email->Source = $src;
$email->sem_email = air2_generate_uuid().'@test.com';
$email->save();

$address = new SrcMailAddress();
$address->Source = $src;
$address->smadd_city = 'Denver';
$address->save();

$phone = new SrcPhoneNumber();
$phone->Source = $src;
$phone->sph_number = '5555435543';
$phone->save();

$fact_map = new SrcFact();
$fact_map->Source = $src;
$fact_map->Fact = $fact_income;
$fact_map->AnalystFV = $fv_income_1;
$fact_map->SourceFV = $fv_income_2;
$fact_map->save();

$fact_text = new SrcFact();
$fact_text->Source = $src;
$fact_text->Fact = $fact_born;
$fact_text->sf_src_value = '1999';
$fact_text->save();

$fact_both = new SrcFact();
$fact_both->Source = $src;
$fact_both->Fact = $fact_gender;
$fact_both->AnalystFV = $fv_gender_1;
$fact_both->SourceFV = $fv_gender_2;
$fact_both->sf_src_value = 'something';
$fact_both->save();

$vita_air1 = new SrcVita();
$vita_air1->Source = $src;
$vita_air1->sv_type = SrcVita::$TYPE_INTEREST;
$vita_air1->sv_origin = SrcVita::$ORIGIN_AIR1_CONTACT;
$vita_air1->sv_notes = 'interested in baseball';
$vita_air1->save();

$vita_air2 = new SrcVita();
$vita_air2->Source = $src;
$vita_air2->sv_type = SrcVita::$TYPE_EXPERIENCE;
$vita_air2->sv_origin = SrcVita::$ORIGIN_AIR2;
$vita_air2->sv_value = 'lion tamer';
$vita_air2->sv_basis = 'pizza hut';
$vita_air2->save();

$vita_mypin = new SrcVita();
$vita_mypin->Source = $src;
$vita_mypin->sv_type = SrcVita::$TYPE_INTEREST;
$vita_mypin->sv_origin = SrcVita::$ORIGIN_MYPIN;
$vita_mypin->sv_notes = 'interested in mypin';
$vita_mypin->save();

$srcorg = new SrcOrg();
$srcorg->Source = $src;
$srcorg->Organization = $o;
$srcorg->so_status = SrcOrg::$STATUS_OPTED_IN;
$srcorg->save();

$annot = new SrcAnnotation();
$annot->Source = $src;
$annot->srcan_value = 'what a jerk';
$annot->srcan_cre_user = $u->user_id;
$annot->srcan_upd_user = $u->user_id;
$annot->save();


plan(42);

/**********************
 * Initial sanity
 */
is( $src->user_may_write($u),        AIR2_AUTHZ_IS_ORG,     'init - src write' );
is( $alias->user_may_write($u),      AIR2_AUTHZ_IS_ORG,     'init - alias write' );
is( $email->user_may_write($u),      AIR2_AUTHZ_IS_ORG,     'init - email write' );
is( $address->user_may_write($u),    AIR2_AUTHZ_IS_ORG,     'init - address write' );
is( $phone->user_may_write($u),      AIR2_AUTHZ_IS_ORG,     'init - phone write' );
is( $fact_map->user_may_write($u),   AIR2_AUTHZ_IS_ORG,     'init - fact_map write' );
is( $fact_text->user_may_write($u),  AIR2_AUTHZ_IS_ORG,     'init - fact_text write' );
is( $fact_both->user_may_write($u),  AIR2_AUTHZ_IS_ORG,     'init - fact_both write' );
is( $vita_air1->user_may_write($u),  AIR2_AUTHZ_IS_ORG,     'init - vita_air1 write' );
is( $vita_air2->user_may_write($u),  AIR2_AUTHZ_IS_ORG,     'init - vita_air2 write' );
is( $vita_mypin->user_may_write($u), AIR2_AUTHZ_IS_ORG,     'init - vita_mypin write' );
is( $srcorg->user_may_write($u),     AIR2_AUTHZ_IS_ORG,     'init - srcorg write' );
is( $annot->user_may_write($u),      AIR2_AUTHZ_IS_OWNER,   'init - annot write' );


/**********************
 * Lock the Source!
 */
$src->src_has_acct = Source::$ACCT_YES;
$src->save();

// Source
is( $src->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - src read' );
is( $src->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - src write' );

// SrcAlias
is( $alias->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - alias read' );
is( $alias->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - alias write' );

// SrcEmail
is( $email->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - email read' );
is( $email->user_may_write($u), AIR2_AUTHZ_IS_ORG, 'lock - email write' );

// SrcMailAddress
is( $address->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - address read' );
is( $address->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - address write' );

// SrcPhoneNumber
is( $phone->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - phone read' );
is( $phone->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - phone write' );

// Mapped SrcFact
is( $fact_map->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - fact_map read' );
$fact_map->AnalystFV = $fv_income_3;
is( $fact_map->user_may_write($u), AIR2_AUTHZ_IS_ORG,    'lock - fact_map write - AnalystFV' );
$fact_map->refresh();
$fact_map->SourceFV = $fv_income_3;
is( $fact_map->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - fact_map write - SourceFV' );

// Text-only SrcFact
is( $fact_text->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - fact_text read' );
$fact_text->sf_src_value = '1210';
// WARNING: can now write to locked text (only way to change it)
is( $fact_text->user_may_write($u), AIR2_AUTHZ_IS_ORG,    'lock - fact_text write' );

// Multiple value SrcFact
is( $fact_both->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - fact_both read' );
$fact_both->AnalystFV = $fv_gender_3;
is( $fact_both->user_may_write($u), AIR2_AUTHZ_IS_ORG,    'lock - fact_both write - AnalystFV' );
$fact_both->refresh();
$fact_both->SourceFV = $fv_gender_3;
is( $fact_both->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - fact_both write - SourceFV' );
$fact_both->refresh();
$fact_both->sf_src_value = 'else';
is( $fact_both->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - fact_both write' );

// AIR1 Vita
is( $vita_air1->user_may_read($u),  AIR2_AUTHZ_IS_ORG, 'lock - vita_air1 read' );
is( $vita_air1->user_may_write($u), AIR2_AUTHZ_IS_ORG, 'lock - vita_air1 write' );

// AIR2 Vita
is( $vita_air2->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - vita_air2 read' );
is( $vita_air2->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - vita_air2 write' );

// MyPIN Vita
is( $vita_mypin->user_may_read($u),  AIR2_AUTHZ_IS_ORG,    'lock - vita_mypin read' );
is( $vita_mypin->user_may_write($u), AIR2_AUTHZ_IS_DENIED, 'lock - vita_mypin write' );

// SrcOrg
is( $srcorg->user_may_read($u),  AIR2_AUTHZ_IS_ORG, 'lock - srcorg read' );
is( $srcorg->user_may_write($u), AIR2_AUTHZ_IS_ORG, 'lock - srcorg write' );

// SrcAnnotation
is( $annot->user_may_read($u),  AIR2_AUTHZ_IS_ORG,   'lock - annot read' );
is( $annot->user_may_write($u), AIR2_AUTHZ_IS_OWNER, 'lock - annot write' );
