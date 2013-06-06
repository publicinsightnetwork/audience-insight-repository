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

plan(48);

AIR2_DBManager::init();

// create test users
$usr = new TestUser();
$usr->save();

// Organizations
$parent = new TestOrganization();
$parent->save();
$org = new TestOrganization();
$org->org_parent_id = $parent->org_id;
$org->save();
$child = new TestOrganization();
$child->org_parent_id = $org->org_id;
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->save();
$sibling_child = new TestOrganization();
$sibling_child->org_parent_id = $sibling->org_id;
$sibling_child->save();

// sources
$src = new TestSource();
$src->add_orgs(array($org));
$src->save();
$src_allin = new TestSource();
$src_allin->add_orgs(array($parent));
$src_allin->save();
$src_allin_nosibling = new TestSource();
$src_allin_nosibling->add_orgs(array($parent));
$src_allin_nosibling->add_orgs(array($sibling), SrcOrg::$STATUS_OPTED_OUT);
$src_allin_nosibling->save();
$src_child = new TestSource();
$src_child->add_orgs(array($child));
$src_child->save();
$src_allout_child = new TestSource();
$src_allout_child->add_orgs(array($child));
$src_allout_child->add_orgs(array($parent), SrcOrg::$STATUS_OPTED_OUT);
$src_allout_child->save();


/**********************
 * Test parent-manager
 */
$parent->add_users(array($usr), 4);
$parent->save();
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "parent-manager - src manage");
is( $src_allin->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "parent-manager - src_allin manage");
is( $src_allin_nosibling->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "parent-manager - src_allin_nosibling manage");
is( $src_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "parent-manager - src_child manage");
is( $src_allout_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "parent-manager - src_allout_child manage");

Source::query_may_read($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "parent-manager - query read" );
Source::query_may_write($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "parent-manager - query write" );
Source::query_may_manage($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "parent-manager - query manage" );

/**********************
 * Test org-manager
 */
$usr->UserOrg[0]->delete();
$usr->clear_authz();
$org->add_users(array($usr), 4);
$org->save();
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "org-manager - src manage");
is( $src_allin->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "org-manager - src_allin manage");
is( $src_allin_nosibling->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "org-manager - src_allin_nosibling manage");
is( $src_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "org-manager - src_child manage");
is( $src_allout_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "org-manager - src_allout_child manage");

Source::query_may_read($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "org-manager - query read" );
Source::query_may_write($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "org-manager - query write" );
Source::query_may_manage($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "org-manager - query manage" );

/**********************
 * Test child-manager
 */
$usr->UserOrg[0]->delete();
$usr->clear_authz();
$child->add_users(array($usr), 4);
$child->save();
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "child-manager - src manage");
is( $src_allin->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "child-manager - src_allin manage");
is( $src_allin_nosibling->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "child-manager - src_allin_nosibling manage");
is( $src_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "child-manager - src_child manage");
is( $src_allout_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "child-manager - src_allout_child manage");

Source::query_may_read($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "child-manager - query read" );
Source::query_may_write($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "child-manager - query write" );
Source::query_may_manage($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "child-manager - query manage" );

/**********************
 * Test sibling-manager
 */
$usr->UserOrg[0]->delete();
$usr->clear_authz();
$sibling->add_users(array($usr), 4);
$sibling->save();
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_DENIED, "sibling-manager - src manage");
is( $src_allin->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "sibling-manager - src_allin manage");
is( $src_allin_nosibling->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "sibling-manager - src_allin_nosibling manage");
is( $src_child->user_may_manage($usr), AIR2_AUTHZ_IS_DENIED, "sibling-manager - src_child manage");
is( $src_allout_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "sibling-manager - src_allout_child manage");

Source::query_may_read($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 3, "sibling-manager - query read" );
Source::query_may_write($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 3, "sibling-manager - query write" );
Source::query_may_manage($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 3, "sibling-manager - query manage" );

/**********************
 * Test child-reader, sibling-child-manager
 */
$usr->UserOrg[0]->delete();
$usr->clear_authz();
$sibling_child->add_users(array($usr), 4);
$sibling_child->save();
$child->clearRelated();
$child->refresh();
$child->add_users(array($usr));
$child->save();
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_DENIED, "chread-sibman - src manage");
is( $src->user_may_write($usr), AIR2_AUTHZ_IS_DENIED, "chread-sibman - src write");
is( $src->user_may_read($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src read");
is( $src_allin->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allin manage");
is( $src_allin_nosibling->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allin_nosibling manage");
is( $src_allin_nosibling->user_may_write($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allin_nosibling write");
is( $src_allin_nosibling->user_may_read($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allin_nosibling read");
is( $src_child->user_may_manage($usr), AIR2_AUTHZ_IS_DENIED, "chread-sibman - src_child manage");
is( $src_child->user_may_write($usr), AIR2_AUTHZ_IS_DENIED, "chread-sibman - src_child write");
is( $src_child->user_may_read($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_child read");
is( $src_allout_child->user_may_manage($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allout_child manage");
is( $src_allout_child->user_may_write($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allout_child write");
is( $src_allout_child->user_may_read($usr), AIR2_AUTHZ_IS_ORG, "chread-sibman - src_allout_child read");

Source::query_may_read($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 5, "chread-sibman - query read" );
Source::query_may_write($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 3, "chread-sibman - query write" );
Source::query_may_manage($q = AIR2_Query::create()->from('Source'), $usr);
is( $q->count(), 3, "chread-sibman - query manage" );
