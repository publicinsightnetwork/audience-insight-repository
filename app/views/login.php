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

/*
|--------------------------------------------------------------------------
| Login page
|--------------------------------------------------------------------------
| HTML login page for AIR2
*/
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>AIR2 | Login</title>
<link rel="stylesheet" type="text/css" href="<?php echo $static_url ?>/css/login.css" />
<script type="text/javascript">
//<![CDATA[
function getFocus() {
  document.forms[0].elements[0].focus();
  document.forms[0].elements[0].select();
}
//]]></script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body onload="getFocus()">
<header>
    <div class="wrap">
        <a href="http://publicinsightnetwork.org"><img src="<?php echo $static_url ?>/css/img/pin-logo-white.png" /></a>
    </div>
</header>

<div class="wrap panel">
  <h2>AIR2 <?php echo AIR2_VERSION ?></h2>
  <form id="login" name="login" method="post" action="<?php echo $c->uri_for('login', array('admin'=>$admin)) ?>">
   <table border="0" cellpadding="5" style="width:100%">

    <tr><th>Username:</th><td><input type="text" name="username" /></td></tr>
    <tr><th>Password:</th><td><input type="password" name="password" />
    </td></tr>
    <tr><td colspan="2" align="right">
     <div id="forgot-password">
      <a href="password">Forgot password?</a>
     </div>
     <input type="hidden" name="back" value="<?php echo $back ?>" />
     <input type="hidden" name="admin" value="<?php echo $admin ? "1" : "0" ?>" />
    </td></tr>
    <tr><td></td><td>
     <input type="submit" value="Login" />
    </td></tr>
    <?php if (isset($errormsg)): ?>
    <tr><td colspan="2" align="right">
     <p class="errors"><?php echo $errormsg; ?></p>
    </td></tr>
   <?php endif; ?>
  </table>
 </form>
</div>

<div class="wrap" id="copyright">
    &copy; 2013 <a href="http://americanpublicmedia.org/">American Public Media Group</a>
</div>

</body>
</html>
