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
| AIR2 Search error page
|--------------------------------------------------------------------------
*/
?>
<script type="text/javascript">
    Ext.onReady(function() {

        var app = new AIR2.UI.App({
            items: new AIR2.UI.Panel({
                title: 'Error',
                items: [{html: '<div>Please enter a search query</div>', border: false}]
            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search'
        });

    });
</script>
