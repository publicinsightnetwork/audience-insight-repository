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
| Password link expired page
|--------------------------------------------------------------------------
| This page will be shown (instead of an 404) if a password-reset link
| has expired.  We don't actually check if the page ever existed... just return
| this for all 404's.
*/
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>AIR2 | Password Change</title>
<link rel="stylesheet" type="text/css" href="<?php echo $static_url ?>/css/login.css" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>

<div align="center">
    <h2>Link Expired</h2>
    <table border="0" cellpadding="5">
        <tr><th>This change password link has expired!</th></tr>
        <tr><td>Request another one at <a href="<?php echo $reset_url; ?>"><?php echo $reset_url; ?></a></td></tr>
    </table>
    <div style="margin:1em">
        Copyright 2011 American Public Media Group
    </div>
</div>

</body>
</html>
