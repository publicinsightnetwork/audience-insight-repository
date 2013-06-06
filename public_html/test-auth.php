<html>
 <head>
  <title>AIR2 auth check</title>
 </head>
 <body>
  <pre>
<?php

    require_once realpath( dirname(__FILE__).'/../app/init.php' );
    require_once 'AirUser.php';
    $air_user = new AirUser();
    printf("username=%s\n", $air_user->get_username());
    print_r( $air_user->get_authz() );

?>
  </pre>
 </body>
</html>
