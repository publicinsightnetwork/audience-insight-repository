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
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once 'tank/CSVImporter.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

$u = new TestUser();
$u->save();

$o = new TestOrganization();
$o->add_users(array($u));
$o->save();

$s = new TestSource();
$s->add_orgs(array($o));
$s->save();

$t = new TestTank();
$t->tank_type = Tank::$TYPE_CSV;
$t->set_meta_field('csv_delim', ',');
$t->set_meta_field('csv_encl', '"');
$t->tank_user_id = $u->user_id;
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->save();

$q = 'select fact_id from fact where fact_identifier = ?';
$FACT_GENDER = $conn->fetchOne($q, array('gender'), 0);
$FACT_ETHNIC = $conn->fetchOne($q, array('ethnicity'), 0);
$FACT_RELIG  = $conn->fetchOne($q, array('religion'), 0);

// Helper to create a csv from an assoc-array
function make_csv($data) {
    global $t;

    // set tank status back to new
    $t->refresh(true);
    if (count($t->TankSource)) {
        $t->TankSource[0]->delete();
        $t->clearRelated('TankSource');
    }
    $t->tank_status = Tank::$STATUS_CSV_NEW;
    $t->save();

    // write new csv file
    $path = "/tmp/".$t->tank_uuid.".csv";
    $fp = fopen($path, "w");
    fputcsv($fp, array_keys($data));
    fputcsv($fp, array_values($data));
    fclose($fp);
    $t->copy_file($path);
    unlink($path);
}

// Helper to create a csv from an assoc-array
function get_fact($fact_id) {
    global $s, $t, $conn;
    $q = 'select tsrc_id from tank_source where tsrc_tank_id = ? and src_username = ?';
    $tsrc_id = $conn->fetchOne($q, array($t->tank_id, $s->src_username), 0);
    $q = Doctrine_Query::create()->from('TankFact a');
    $q->leftJoin('a.AnalystFV');
    $q->leftJoin('a.SourceFV');
    $q->where('a.tf_tsrc_id = ?', $tsrc_id);
    $q->andWhere('a.tf_fact_id = ?', $fact_id);
    $sf = $q->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
    if ($sf) {
        $sf['analyst_map'] = $sf['AnalystFV'] ? $sf['AnalystFV']['fv_value'] : '';
        $sf['source_map'] = $sf['SourceFV'] ? $sf['SourceFV']['fv_value'] : '';
    }
    return $sf;
}

// CSV data
$csv = array(
    'Username'              => $s->src_username,
    'Gender'                => '',
    'Gender Src Map'        => '',
    'Gender Src Text'       => '',
    'Ethnicity'             => '',
    'Ethnicity Src Map'     => '',
    'Ethnicity Src Text'    => '',
    'Religion'              => '',
    'Religion Src Map'      => '',
    'Religion Src Text'     => '',
);

plan(28);

/**********************
 * Check column headers
 */
make_csv($csv);
$imp = new CSVImporter($t);
is( $imp->validate_headers(), true, 'import1 - valid headers' );
is( $imp->get_line_count(), 1, 'import1 - line count' );
$n = $imp->import_file();
is( $n, 1, 'import1 - success' );


/**********************
 * Import one Src Text (and check for mapping)
 */
$csv['Gender Src Text'] = 'Mail';
make_csv($csv);
$imp = new CSVImporter($t);
is( $imp->validate_headers(), true, 'import2 - valid headers' );
is( $imp->get_line_count(), 1, 'import2 - line count' );
$n = $imp->import_file();
is( $n, 1, 'import2 - success' );

$fact = get_fact($FACT_GENDER);
is( $fact['sf_src_value'], 'Mail', 'import2 - src_value preserved' );
is( $fact['analyst_map'], 'Male', 'import2 - analyst mapped' );

/**********************
 * Import conflicting translation
 */
$csv['Gender Src Text'] = 'Mail';
$csv['Gender'] = 'Female';
make_csv($csv);
$imp = new CSVImporter($t);
is( $imp->validate_headers(), true, 'import3 - valid headers' );
is( $imp->get_line_count(), 1, 'import3 - line count' );
$n = $imp->import_file();
ok( is_string($n), 'import3 - failure' );
ok( preg_match('/row 2/', $n), 'import3 - row 2 error' );
ok( preg_match('/Gender Src Text/', $n), 'import3 - on src text' );

$fact = get_fact($FACT_GENDER);
ok( !$fact, 'import3 - no fact created' );

/**********************
 * Import with a mapping that DNE
 */
$csv['Gender Src Text'] = 'THISDOESNOTMAPTOANYTHING';
$csv['Gender'] = '';
make_csv($csv);
$imp = new CSVImporter($t);
is( $imp->validate_headers(), true, 'import4 - valid headers' );
is( $imp->get_line_count(), 1, 'import4 - line count' );
$n = $imp->import_file();
is( $n, 1, 'import4 - success' );

$fact = get_fact($FACT_GENDER);
is( $fact['sf_src_value'], $csv['Gender Src Text'], 'import2 - src_value preserved' );
ok( !$fact['analyst_map'], 'import2 - no analyst mapped' );

/**********************
 * Multiple things at once
 */
$csv['Gender Src Text'] = 'person';
$csv['Ethnicity Src Text'] = 'human';
$csv['Religion Src Text'] = 'Jewish';

make_csv($csv);
$imp = new CSVImporter($t);
is( $imp->validate_headers(), true, 'import5 - valid headers' );
is( $imp->get_line_count(), 1, 'import5 - line count' );
$n = $imp->import_file();
is( $n, 1, 'import5 - success' );

$fact = get_fact($FACT_GENDER);
is( $fact['sf_src_value'], 'person', 'import5 - gender src_value' );
is( $fact['analyst_map'], 'Non-mapped identity', 'import5 - gender analyst_map' );

$fact = get_fact($FACT_ETHNIC);
is( $fact['sf_src_value'], 'human', 'import5 - ethn src_value' );
is( $fact['analyst_map'], 'Decline to state', 'import5 - ethn analyst_map' );

$fact = get_fact($FACT_RELIG);
is( $fact['sf_src_value'], 'Jewish', 'import5 - religion src_value' );
is( $fact['analyst_map'], 'Jewish', 'import5 - religion analyst_map' );
