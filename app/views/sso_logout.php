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
 * HTML logout page for PIN SSO
 */

    $logout = $sso_logout . '?nocache='.time().'&back=' . $c->uri_for('');
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
 <head>
  <title>AIR | Logout</title>
  <link rel="stylesheet" type="text/css" href="<?php echo $c->uri_for('css/air2.css') ?>" />
  <link rel="stylesheet" type="text/css" href="<?php echo $c->uri_for('css/air2panel.css') ?>" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="refresh" content="3;<?php echo $logout ?>" />
  
  <style type='text/css'>
   .main {
     margin: 1em;
     padding: 2em;
   }
   .main div {
     padding: 1em;
   }
  </style>
 </head>
 <body>
  <div class="air2-panel main" align="center">
  <h2>AIR | Logout</h2>
   <div>
   You are being logged out of all PIN applications, including:
   </div>
   
   <ul>
    <li>AIR</li>
    <li>Formbuilder</li>
   </ul>
   
   <div>
   If your browser does not redirect automatically within a few seconds,
   <a href="<?php echo $logout ?>">click here</a>.
   </div>
   
   <div style="margin:1em">
   Copyright 2011 American Public Media Group
   </div>
   
  </div>
 </body>
</html>
