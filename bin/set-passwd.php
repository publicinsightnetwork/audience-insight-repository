#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AIR2_DBManager.php';
require_once 'PINPassword.php';

/**
 * set-passwd.php
 *
 * This utility will reset the password for an AIR2 user, or create a new
 * user and set their password.
 *
 * @package default
 */


AIR2_DBManager::init();

echo "Enter the username of an AIR2 User:\n > ";
$username = trim(fgets(STDIN));

if (strlen($username) < 1) {
    echo "Error! No username specified!\n";
    exit(0);
}

$user = Doctrine::getTable('User')->findOneBy('user_username', $username);

if ( !$user ) {
    $user = new User();
    $user->user_username = $username;
    $user->user_first_name = '[First]';
    $user->user_last_name = '[Last]';
    $user->user_cre_dtim = air2_date();
    $user->user_cre_user = 1; // system user
    $user->user_uuid = air2_generate_uuid();
    $user->user_type = 'A'; // system type
    $user->user_status = 'A'; // active

    echo "AIR2 User '$username' not found!\n";
    echo "Enter new password to create User. (Blank to cancel)\n > ";
} else {
    echo "Enter new password:\n > ";
}

$userpass = trim(fgets(STDIN));

$pinpass = new PINPassword(array(
        'username' => $username,
        'phrase'   => $userpass,
    ));
if (!$pinpass->validate()) {
    die( "Password " . $pinpass->get_error() . "\n" );
}

if (strlen($userpass) > 0) {
    $user->user_password = $userpass;
    $user->save();
    echo "Password changed for user " . $user->user_username . " uuid " . $user->user_uuid . "\n";
} else {
    echo "No password specified --- all changes cancelled\n";
}

?>
