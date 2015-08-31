#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AirHtml.php';

// strictly speaking we do not compress (minify)
// we only concatenate since some 3rd party libs are already minified.

$third_party_file = AIR2_DOCROOT . '/css/third_party.css';
$buf = "";
foreach (AirHtml::third_party_css() as $path) {
    $file = AIR2_DOCROOT . '/' . $path;
    $css = file_get_contents($file);
    if (!$css) {
        die("Failed to load $file");
    }
    $buf .= "/* $path */\n";
    $buf .= $css;
}

if (!file_put_contents( $third_party_file, $buf )) {
    die("Failed to write $third_party_file");
}

