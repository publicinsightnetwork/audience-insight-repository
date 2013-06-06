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
require_once 'AirHttpTest.php';

// init
AIR2_DBManager::init();

// test creating valid/invalid tags
$valid_names = array(
    '01234 5678 910 11abc',
    '012-345_678.910AbcD',
);
$invalid_names = array(
    '01234 5678 910 11abc abcdefghijkl', // length (33 chars)
    'abc , def',
    'abc / def',
    'abc + def',
    'abc ? def',
    ' abc def', // leading whitespace
    'abc  def ', // trailing whitespace
);
$iptc_valid = array(
    '01234 5678 910 11abc',
    '012-345_678.9 / 10AbcD',
);
$iptc_invalid = array(
    'abc , def',
    'abc (def)',
    'abc + def',
    'abc ? def',
    ' abc def', // leading whitespace
    'abc  def ', // trailing whitespace
);


$num_tag_tests = 1 * (count($valid_names) + count($invalid_names)
                     + count($iptc_valid) + count($iptc_invalid));
plan($num_tag_tests + 4);


// delete any stale valid tags
$del = AIR2_Query::create()
    ->delete('TagMaster')
    ->whereIn('tm_name', array_merge($valid_names, $invalid_names))
    ->execute();
// delete any stale valid tags
$del = AIR2_Query::create()
    ->delete('IptcMaster')
    ->whereIn('iptc_name', array_merge($iptc_valid, $iptc_invalid))
    ->execute();

// valid tags
for ($i=0; $i<count($valid_names); $i++) {
    $tm = new TagMaster();
    $tm->tm_type = 'T'; //test
    $tm->tm_name = $valid_names[$i];

    try {
        $tm->save();
        pass("Create valid tag num $i");
        $tm->delete();
    }
    catch (Exception $err) {
        fail("Create valid tag num $i");
    }
}

// invalid tags
for ($i=0; $i<count($invalid_names); $i++) {
    $tm = new TagMaster();
    $tm->tm_type = 'T'; //test
    $tm->tm_name = $invalid_names[$i];

    try {
        $tm->save();
        fail("Create invalid tag num $i");
        $tm->delete();
    }
    catch (Exception $err) {
        pass("Create invalid tag num $i");
    }
}

// duplicate tags
$tm = new TagMaster();
$tm->tm_type = 'T'; //test
$tm->tm_name = $valid_names[0];
$tm->save();
$tm2 = new TagMaster();
$tm2->tm_type = 'T'; //test
$tm2->tm_name = $valid_names[0];
try {
    $tm2->save();
    fail("Create duplicate tag");
    $tm2->delete();
}
catch (Exception $err) {
    pass("Create duplicate tag");
}
$tm->delete();

// case insensitivity
$tm = new TagMaster();
$tm->tm_type = 'T'; //test
$tm->tm_name = $valid_names[0];
$tm->save();
$tm2 = new TagMaster();
$tm2->tm_type = 'T'; //test
$tm2->tm_name = '01234 5678 910 11ABC'; // last 3 letters capitalized
try {
    $tm2->save();
    fail("Create case-insensitive duplicate tag");
    $tm2->delete();
}
catch (Exception $err) {
    pass("Create case-insensitive duplicate tag");
}
$tm->delete();


///////////////////////////////////////////
// IPTC Tags
///////////////////////////////////////////

// valid iptc tags
for ($i=0; $i<count($iptc_valid); $i++) {
    $iptc = new IptcMaster();
    $iptc->iptc_concept_code = 'TEST'; //test
    $iptc->iptc_name = $iptc_valid[$i];

    try {
        $iptc->save();
        pass("Create valid IPTC tag num $i");
        $iptc->delete();
    }
    catch (Exception $err) {
        fail("Create valid IPTC tag num $i");
    }
}

// invalid iptc tags
for ($i=0; $i<count($iptc_invalid); $i++) {
    $iptc = new IptcMaster();
    $iptc->iptc_concept_code = 'TEST'; //test
    $iptc->iptc_name = $iptc_invalid[$i];

    try {
        $iptc->save();
        fail("Create invalid IPTC tag num $i");
        $iptc->delete();
    }
    catch (Exception $err) {
        pass("Create invalid IPTC tag num $i");
    }
}

// duplicate tags
$iptc = new IptcMaster();
$iptc->iptc_concept_code = 'TEST'; //test
$iptc->iptc_name = $iptc_valid[0];
$iptc->save();
$iptc2 = new IptcMaster();
$iptc2->iptc_concept_code = 'TEST'; //test
$iptc2->iptc_name = $iptc_valid[0];
try {
    $iptc2->save();
    fail("Create duplicate IPTC tag");
    $iptc2->delete();
}
catch (Exception $err) {
    pass("Create duplicate IPTC tag");
}

// duplicate IPTC-type TagMaster
$tm = new TagMaster();
$tm->tm_type = 'I'; //IPTC Tag
$tm->tm_iptc_id = $iptc->iptc_id;
$tm->save();
$tm2 = new TagMaster();
$tm2->tm_type = 'I'; //IPTC Tag
$tm2->tm_iptc_id = $iptc->iptc_id;
try {
    $tm2->save();
    fail("Create duplicate TagMaster IPTC-type tag");
    $tm2->delete();
}
catch (Exception $err) {
    pass("Create duplicate TagMaster IPTC-type tag");
}
$tm->delete();
$iptc->delete();




?>
