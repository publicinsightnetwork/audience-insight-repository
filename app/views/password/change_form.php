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
| Change Password page
|--------------------------------------------------------------------------
| HTML password change page for AIR2
*/
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>AIR2 | Password Change</title>
<link rel="stylesheet" type="text/css" href="<?php echo $static_url ?>/css/login.css" />
<script type="text/javascript">
//<![CDATA[
function getFocus() {
  if (document.forms.length > 0) {
    document.forms[0].elements[0].focus();
    document.forms[0].elements[0].select();
  }
}
//]]></script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body onload="getFocus()">
<div align="center">
<h2>Change Your Password</h2>

<?php if (isset($captcha)) :?>
    <form id="reset" name="reset" method="post" action="<?php echo $action;?>">
    <table border="0" cellpadding="5">
        <tr><th>Username:</th><td><input type="text" name="login_name" /></td></tr>
        <tr><th>New Password:</th><td><input type="password" name="login_pass_1" /></td></tr>
        <tr><th>(repeat):</th><td><input type="password" name="login_pass_2" /></td></tr>
        <tr><th></th><td><ul>
            <li>At least 8 characters long</li>
            <li>Must contain a lowercase letter</li>
            <li>Must contain an uppercase letter</li>
            <li>Must contain a number</li>
            <li>Must contain a symbol</li>
        </ul></td></tr>
        <tr><td colspan="2" align="right"><?php echo $captcha;?></td></tr>
        <?php if (isset($errors)): ?>
        <tr><td colspan="2" align="center">
            <p class="errors"><?php echo $errors; ?></p>
        </td></tr>
        <?php endif; ?>
        <tr><td colspan="2" align="center">
            <input type="submit" value="Submit" />
        </td></tr>
    </table>
    </form>
<?php else : ?>
    <table border="0" cellpadding="5">
        <tr><th>Password Successfully Changed!</th></tr>
        <tr><td>You have been sent a confirmation email.</td></tr>
        <tr><td colspan="2" align="center">
            <div id="forgot-password">
                <a href="<?php echo $login_url; ?>">Return to Login</a>
            </div>
        </td></tr>
    </table>
<?php endif; ?>
    <div style="margin:1em">
        Copyright 2011 American Public Media Group
    </div>
</div>
</body>
</html>
