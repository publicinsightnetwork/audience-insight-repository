#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AIR2_DBManager.php';
/**
 * create-tbl.php
 *
 * This utility lets you create single tables from doctrine models.
 *
 */

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

echo "Enter the name of the Doctrine model > ";
$modelname = trim(fgets(STDIN));

if (strlen($modelname) < 1) {
    echo "Error! No model specified!\n";
    exit(1);
}

try {
    $tbl = Doctrine::getTable($modelname);
}
catch (Exception $e) {
    echo "Error!\n".$e->getMessage()."\n";
    exit(1);
}

try {
    $conn->execute('describe '.$tbl->getTableName());
    echo "Table already exists in database!\nDrop table and recreate? (y/n) > ";
    $drop = strtolower(trim(fgets(STDIN)));
    if ($drop == 'y') {
        try {
            $conn->execute('drop table '.$tbl->getTableName());
        }
        catch (Exception $e) {
            echo "Unable to drop table! - ".$e->getMessage()."\n";
            exit(1);
        }
    }
    else {
        exit(0);
    }
}
catch(Exception $e) {
    // table doesn't exist --- good!
}

echo "Creating table ... ";
try {
    Doctrine::createTablesFromArray(array($tbl->getClassnameToReturn()));
    echo "Success!\n";
}
catch (Exception $e) {
    echo "Error!\n".$e->getMessage()."\n";
}


?>
