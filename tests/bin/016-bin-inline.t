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
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/AirHttpTest.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestProject.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestSource.php";

// set up the connection
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// init browser
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$HTML); // set to json

// helper function to search document for json variables
function get_json_variable($var_name, $document) {
    //get the line with the variable on it
    $found = preg_match("/$var_name = .+/", $document, $line);
    if (!$found) return null;

    //look for some json
    $found = preg_match("/\{.+\}/", $line[0], $matches);
    if (!$found) {
        // return the variable value as a string, removing trailing ";"
        $val = substr($line[0], strlen("$var_name = "));
        return substr($val, 0, strlen($val)-1);
    }

    //decode the result
    $json = json_decode($matches[0], true);
    return $json;
}

// test users/org
$u1 = new TestUser();
$u1->save();
$u2 = new TestUser();
$u2->save();
$o = new TestOrganization();
$o->add_users(array($u1, $u2));
$o->save();
$browser->set_user($u1);

// create some dummy data
$KEYSTR = "018BININLINETEST";
$b1 = new TestBin();
$b1->bin_user_id = $u1->user_id;
$b1->bin_name = "$KEYSTR - 1";
$b1->save();
$b2 = new TestBin();
$b2->bin_user_id = $u1->user_id;
$b2->bin_name = "$KEYSTR - 2";
$b2->save();
$b3 = new TestBin();
$b3->bin_user_id = $u1->user_id;
$b3->bin_name = "$KEYSTR - 3";
$b3->save();

plan(32);

/**********************
 * Setup the BIN cookie to load inline data in the html
 */
$ck_data = array(
    'view' => 'sm',
    'params' => array('limit' => 2, 'owner_flag' => 1),
    'open' => true,
);
$browser->browser->setCookie(AIR2_BIN_STATE_CK, json_encode($ck_data));


/**********************
 * Get the HTML homepage, and check for inline bin data
 */
ok( $resp = $browser->http_get("/"), 'nav to homepage' );
is( $browser->resp_code(), 200, "homepage resp code" );

// check for valid bin data, and counts
$bindata = get_json_variable('BINDATA', $resp);
ok( is_array($bindata), 'homepage bindata is array' );
ok( isset($bindata['radix']), 'homepage bindata has radix' );
is( count($bindata['radix']), 2, 'homepage bindata count = 2' );
$binbase = get_json_variable('BINBASE', $resp);
ok( $binbase === 'false', 'homepage binbase is false' );

// check the metadata
is( $bindata['meta']['sortstr'], 'bin_upd_dtim desc', 'metadata sort' );
$field_found = false;
foreach ($bindata['meta']['fields'] as $idx => $fld) {
    if ($fld == 'bin_upd_dtim') $field_found = true;
}
ok( $field_found, 'metadata bin_upd_dtim field exists' );
is( $bindata['meta']['total'], 3, 'metadata total = 3' );

/**********************
 * Now try the "large" bin view
 */
$b3->bin_user_id = $u2->user_id;
$b3->bin_shared_flag  = true;
$b3->save();

$q = Doctrine_Query::create()->from('Bin a');
Bin::query_may_read($q, $u1, 'a');
$q->andWhereIn('a.bin_id', array($b1->bin_id, $b2->bin_id, $b3->bin_id));
$all_count = $q->count();
$my_count = $q->addWhere('bin_user_id = ?', $u1->user_id)->count();

// alter the cookie
$ck_data['view'] = 'lg';
$ck_data['params'] = array(
    'limit'  => 40,
    'owner'  => 1,
    'sort'   => 'bin_name desc',
    'offset' => 0,
    'q'      => $KEYSTR,
);
$browser->browser->setCookie(AIR2_BIN_STATE_CK, json_encode($ck_data));

// navigate to project search page
ok( $resp = $browser->http_get("/search/projects"), 'nav to project' );
is( $browser->resp_code(), 200, "project resp code" );

// check for valid bin data, and counts
$bindata = get_json_variable('BINDATA', $resp);
ok( is_array($bindata), 'project bindata is array' );
ok( isset($bindata['radix']), 'project bindata has radix' );
is( count($bindata['radix']), $my_count, "project bindata count = $my_count" );
$binbase = get_json_variable('BINBASE', $resp);
ok( $binbase === 'false', 'project binbase is false' );

/**********************
 * Request all public bins as well (set 'self' to 0, or unset it)
 */
unset($ck_data['params']['owner']);
$browser->browser->setCookie(AIR2_BIN_STATE_CK, json_encode($ck_data));

// navigate to source search page
ok( $resp = $browser->http_get("/search/sources"), 'nav to source' );
is( $browser->resp_code(), 200, "source resp code" );

// check for valid bin data, and counts
$bindata = get_json_variable('BINDATA', $resp);
ok( is_array($bindata), 'source bindata is array' );
ok( isset($bindata['radix']), 'source bindata has radix' );
is( count($bindata['radix']), $all_count, "source bindata count = $all_count" );
$binbase = get_json_variable('BINBASE', $resp);
ok( $binbase === 'false', 'source binbase is false' );

/**********************
 * Request single bin (bindata + binbase)
 */
$ck_data['view'] = 'si';
$ck_data['uuid'] = $b1->bin_uuid;
$ck_data['params'] = array(
    'limit'  => 100,
    'sort'   => 'src_last_name asc',
    'offset' => 0,
);
$browser->browser->setCookie(AIR2_BIN_STATE_CK, json_encode($ck_data));

// navigate back to the homepage
ok( $resp = $browser->http_get("/"), 'nav to home2' );
is( $browser->resp_code(), 200, "home2 resp code" );

// check for valid bin data, and counts
$bindata = get_json_variable('BINDATA', $resp);
ok( is_array($bindata), 'home2 bindata is array' );
ok( isset($bindata['radix']), 'home2 bindata has radix' );
is( count($bindata['radix']), 0, "home2 bindata count = 0" );
$field_found = false;
foreach ($bindata['meta']['fields'] as $idx => $fld) {
    if ($fld == 'src_uuid') $field_found = true;
}
ok( $field_found, 'home2 src_uuid field exists' );
is( $bindata['meta']['total'], 0, 'home2 metadata total = 0' );

// check for valid bin base, and counts
$binbase = get_json_variable('BINBASE', $resp);
ok( is_array($binbase), 'home2 binbase is array' );
ok( isset($binbase['radix']), 'home2 binbase has radix' );
is( $binbase['radix']['bin_uuid'], $b1->bin_uuid, 'home2 binbase bas correct uuid' );
$field_found = false;
foreach ($binbase['meta']['fields'] as $idx => $fld) {
    if ($fld == 'bin_upd_dtim') $field_found = true;
}
ok( $field_found, 'home2 binbase has bin_upd_dtim' );
