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
| AIR2 Help page
|--------------------------------------------------------------------------
*/
$q = '';
if ($c->input->get_post('q') != FALSE) {
    $q = $c->input->get_post('q');
}
?>
<script type="text/javascript">

    Ext.onReady(function() {

        var query = '<?php echo htmlspecialchars($q) ?>';
        var app = new AIR2.UI.App({
            items: new AIR2.UI.RemotePanel({
                title: 'Search Help',
                url: {
                    url: AIR2.HOMEURL+'/search-help.html',
                    callback: function() {
                        if (query.length) {
                            var qdiv = Ext.get('replace-query');
                            qdiv.dom.innerHTML = 'Your search for <strong>' + query + '</strong> failed. Try again!';
                        }
                    }
                }
            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search'
        });

    });

</script>
