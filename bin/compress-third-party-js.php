#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AirHtml.php';

// strictly speaking we do not compress (minify)
// we only concatenate since some 3rd party libs are already minified.

$third_party_js_file = AIR2_DOCROOT . '/js/third_party.js';
$buf = "";
foreach (AirHtml::third_party_js() as $jspath) {
    $jsfile = AIR2_DOCROOT . '/' . $jspath;
    $js = file_get_contents($jsfile);
    if (!$js) {
        die("Failed to load $jsfile");
    }
    $buf .= "/* $jspath */\n";
    $buf .= $js;
}

if (!file_put_contents( $third_party_js_file, $buf )) {
    die("Failed to write $third_party_js_file");
}

