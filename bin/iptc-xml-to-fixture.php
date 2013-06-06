#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
/**
 * iptc-xml-to-fixture.php
 *
 * This utility will create a doctrine fixture (app/fixtures/IptcMaster.yml)
 * by parsing an xml file of IPTC Subject Codes in N1TS format.
 * (http://www.iptc.org/cms/site/index.html?channel=CH0103#descrncd)
 *
 */

$file_name = dirname(__FILE__).'/topicset.iptc-subjectcode.xml';
if (!file_exists($file_name)) {
    echo " > ERROR: \n";
    echo " > Unable to locate subjectcode file: '$file_name'\n";
    echo " > Make sure this file is in place, and try again!\n";
    exit(0);
}

// get the IPTC fixtures
$iptc_master_file = APPPATH.'fixtures/tags/IptcMaster.yml';
$iptc_tag_file = APPPATH.'fixtures/tags/IptcTag.yml';
if (file_exists($iptc_master_file) || file_exists($iptc_tag_file)) {
    echo " > WARNING: This script will overwrite the following files: \n";
    echo " >      $iptc_master_file\n";
    echo " >      $iptc_tag_file\n";
    echo " > Continue? (y/n) : ";
    $continue = trim(strtolower(fgets(STDIN)));
    if ($continue != 'y') exit(0);
}
file_put_contents($iptc_master_file, "IptcMaster:\n"); // open (clear) file
file_put_contents($iptc_tag_file, "TagMaster:\n"); // open (clear) file


// map to reduce file names
$long_name_map = array(
    'computing and information technology' => 'computing and information tech',
    'semiconductors and active components' => 'semiconductors and active compon',
    'oil and gas - downstream activities' => 'oil and gas - downstream actv',
    'oil and gas - upstream activities' => 'oil and gas - upstream actv',
    'electricity production and distribution' => 'electricity production and dist',
    'waste management and pollution control' => 'waste management and pollution',
    'international economic institution' => 'interntl economic institution',
    'annual and special corporate meeting' => 'annual and special corp meeting',
    'quarterly or semiannual financial statement' => 'quarter or semiannual financial',
    'restructuring and recapitalisation' => 'restructure and recapitalisation',
    'regulatory policy and organisation' => 'regulatory policy and org',
    'agricultural research and technology' => 'agricultural research and tech',
    'Major League Baseball - American League' => 'Major League Baseball - AL',
    'Major League Baseball - National League' => 'Major League Baseball - NL',
    'continental championship 1st level' => 'continental championship 1st lvl',
    'continental championship 2nd level' => 'continental championship 2nd lvl',
    'continental championship 3rd level' => 'continental championship 3rd lvl',
    'international military intervention' => 'international military intervent'
);


// Helper functions to create fixtures
function add_iptc_master($code, $name, $id) {
    global $iptc_master_file;

    file_put_contents($iptc_master_file, "  Iptc_".$code.":\n", FILE_APPEND);
    file_put_contents($iptc_master_file, "    iptc_id: ".$id."\n", FILE_APPEND);
    file_put_contents($iptc_master_file, "    iptc_concept_code: '".$code."'\n", FILE_APPEND);
    file_put_contents($iptc_master_file, "    iptc_name: '".$name."'\n", FILE_APPEND);
}
function add_iptc_tag($code, $name, $tm_id, $lvl1, $lvl2) {
    global $iptc_tag_file, $long_name_map;

    // avoid overflow
    if (strlen($name) > 32) {
        if (isset($long_name_map[$name])) {
            $name = $long_name_map[$name];
        } else {
            echo " > ERROR: TAG OVERFLOW! (".strlen($name)."): $name\n";
            echo " > No mapping found!  Exiting!\n";
            exit(1);
        }
    }

    file_put_contents($iptc_tag_file, "  IptcTag_".$code.":\n", FILE_APPEND);
    file_put_contents($iptc_tag_file, "    tm_type: I\n", FILE_APPEND);
    //file_put_contents($iptc_tag_file, "    tm_name: '".$name."'\n", FILE_APPEND); skip name
    file_put_contents($iptc_tag_file, "    tm_iptc_id: ".$tm_id."\n", FILE_APPEND);
}
function endswith($string, $test) {
    $strlen = strlen($string);
    $testlen = strlen($test);
    if ($testlen > $strlen) return false;
    return substr_compare($string, $test, -$testlen) === 0;
}



echo " > Parsing file '$file_name' ...\n";
$doc = new DOMDocument();
$doc->load($file_name);


$count = 0;
$dep = 0;
$maxlen = 0;
$lastcode = 0;
$lvl1 = '';
$lvl2 = '';
$topics = $doc->getElementsByTagName("Topic");

foreach($topics as $topic) {
    $codeEl = $topic->getElementsByTagName('FormalName');
    $code = $codeEl->item(0)->nodeValue;

    // if codes came back out of order, report error!
    if (intval($code) <= $lastcode) {
        echo " > ERROR: IPTC codes were not in order in XML!\n";
        echo " > (Got $code after $lastcode)\n";
        echo " > Unable to process them!  Exiting...\n";
        exit(1);
    }
    $lastcode = intval($code);

    $descEls = $topic->getElementsByTagName('Description');
    foreach($descEls as $descEl) {
        $var = $descEl->getAttribute('Variant');
        if ($var == 'Name') {
            $name = $descEl->nodeValue;
        }
    }

    if ( !endswith($name, '-DEPRECATED') ) {
        // remove/replace invalid characters in name
        $name = preg_replace('/\([^\)]*\)|[^a-zA-Z0-9 _\-\.]/', '', $name); // remove parentheticals and illegal chars
        $name = trim($name);
        $name = preg_replace('/\s\s+/', ' ', $name); // condense double-spaces to 1

        // figure out hierarchy
        if (preg_match('/..000000/', $code)) {
            $lvl1 = $name;
            $fullname = $name;
        } else if (preg_match('/.....000/', $code)) {
            $lvl2 = $name;
            $fullname = $lvl1.' / '.$name;
        } else {
            $fullname = $lvl1.' / '.$lvl2.' / '.$name;
        }

        add_iptc_master($code, $fullname, $count+1);
        add_iptc_tag($code, $name, $count+1, $lvl1, $lvl2);

        $count++;
        $len = strlen($fullname);
        if ($len > $maxlen) $maxlen = $len;
    } else {
        $dep++;
    }
}



echo " > Finished creating fixture files!\n";
echo " > Processed $count topics, skipping $dep deprecated codes.\n";
echo " > Maximum IPTC name length of $maxlen.\n";

?>
