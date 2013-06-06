<?php
/*
|---------------------------------------------------------------
| PHP ERROR REPORTING LEVEL
|---------------------------------------------------------------
| By default CI runs with error reporting set to ALL.  For security
| reasons you are encouraged to change this when your site goes live.
| For more info visit:  http://www.php.net/error_reporting
*/
error_reporting( E_ALL | E_STRICT );
ini_set("display_errors", 1);

/*
|---------------------------------------------------------------
| INIT AIR2 APPLICATION
|---------------------------------------------------------------
|
*/
require_once realpath( dirname(__FILE__).'/../app/init.php' );

// reset the error handling after we've checked our config
if (AIR2_ENVIRONMENT == "prod") {
    error_reporting(E_ERROR);
    ini_set("display_errors", 0);
}
//apache_setenv('DOCTRINE_DEBUG', 1);
/*
|---------------------------------------------------------------
| LOAD THE FRONT CONTROLLER
|---------------------------------------------------------------
| And away we go...
*/
try {
    require_once BASEPATH.'codeigniter/CodeIgniter'.EXT;
}
catch (Exception $err) {
    $error =& load_class('Exceptions');
    $error->show_exception($err);
}

/* End of file index.php */
/* Location: .public_html/index.php */
