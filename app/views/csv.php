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

/**
 * CSV Output
 *
 * Prints data as a csv file.  The $csv variable must be set, and contain the
 * key $csv['radix'].  The radix must contain some data, or an Exception will
 * be thrown.
 *
 * @cfg array $radix data to print
 * @cfg array $header (optional) headers for csv
 * @cfg string $filename (optional) filename for download
 *
 * @author rcavis
 * @package default
 */
if (!isset($csv)) {
    throw new Exception('csv var not defined');
}
if (!isset($csv['radix']) || count($csv['radix']) < 1) {
    throw new Exception('radix not defined');
}
$csv_lines = array();

// make radix an array
if (air2_is_assoc_array($csv['radix'])) {
    $csv['radix'] = array($csv['radix']);
}

// if there is a 'header' key, use that, otherwise array keys
if (isset($csv['header'])) {
    $csv_lines[] = $csv['header'];
}
else {
    // add every key that doesn't point at an array
    $csv_lines[0] = array();
    foreach ($csv['radix'][0] as $key => $val) {
        if (!is_array($val)) $csv_lines[0][] = $key;
    }
}
$width = count($csv_lines[0]);

// get the radix data
foreach ($csv['radix'] as $idx => $object) {
    foreach ($object as $key => $val) {
        if (is_array($val)) unset($object[$key]);
    }
    if (count($object) != $width) {
        throw new Exception("Invalid width on line $idx!");
    }
    $csv_lines[] = array_values($object);
}

// CSV-specific headers
$fname = '';
if (isset($csv['filename'])) {
    $fname = '; filename='.$csv['filename'];
}
elseif (isset($csv['meta']) && isset($csv['meta']['group_name'])) {
    $n = str_replace(' ', '-', $csv['meta']['group_name']);
    $fname = "; filename=$n.csv";
}
header("Content-Disposition: attachment$fname");
//header("Pragma: no-cache"); <-- breaks IE
header("Expires: 0");

// set outstream to echo
$outstream = fopen('php://output', 'w');
foreach ($csv_lines as $line) {
    fputcsv($outstream, $line, ',', '"');
}
fclose($outstream);
