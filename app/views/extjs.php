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
| AIR2 ExtJS View
|--------------------------------------------------------------------------
| Load inline data and kick-off the onReady() js
|
*/
if (!isset($namespace) || strlen($namespace) < 1) {
    return; //nothing to do
}
$ns   = "AIR2.$namespace";
$data = isset($data) ? $data : array();
?>
    <script type="text/javascript">
<?php foreach ($data as $name => $val) { ?>
     <?php echo "$ns.$name" ?> = <?php echo air2_print_var($val) ?>;
<?php } ?>
     Ext.onReady(<?php echo $ns ?>);
    </script>
