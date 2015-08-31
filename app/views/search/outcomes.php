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
| AIR2 Outcome (PINfluence) search page
|--------------------------------------------------------------------------
*/
$search_url      = $c->uri_for('search.json');
$response_url    = $c->uri_for('submission');
$outcome_url     = $c->uri_for('outcome');
$source_url      = $c->uri_for('source');
$source_search_url = $c->uri_for('search/sources');
$inq_url         = $c->uri_for('query');
?>
<script type="text/javascript">
    Ext.onReady(function() {
        var app,
            facetDefs,
            resultTpl;


        AIR2.Search.URL     = '<?php echo $c->uri_for("search") ?>';
        AIR2.Search.QUERY   = '<?php echo htmlspecialchars($q, ENT_QUOTES) ?>';
        AIR2.Search.PARAMS  = <?php echo Encoding::json_encode_utf8($params) ?>;
        AIR2.Search.IDX     = 'outcomes';
        AIR2.Search.SORT_BY_OPTIONS = [
            ['score DESC','Score'],
            ['lastmod DESC', 'Last Modified']
        ];
        AIR2.Search.OrgLabels = <?php echo Encoding::json_encode_utf8($org_uuids) ?>;
        AIR2.Search.OrgNames  = <?php echo Encoding::json_encode_utf8($org_names) ?>;
        var resultTpl = new Ext.XTemplate(
           '<tpl for=".">',
            '<div class="air2-search-result air2-outcome">',
                '<div class="s-excerpt">',
                 '<div class="link">',
               '<h3><a class="title" href="<?php echo $outcome_url ?>/{out_uuid}">{title}</a></h3>',
              '</div>',
              '<div class="stats">',
               '<a href="<?php echo $source_search_url ?>?q=out_uuid:{out_uuid}">{[values.src_uuid.length]} source(s)</a>',
               '<span class="published">Published/aired on {[AIR2.Format.date(values.out_dtim)]}</span>',
               '<span class="org">{[AIR2.Format.orgName(AIR2.Search.OrgNames[values.org_id], true)]}</span>',
                 '</div>',
              '<div class="summary">{[values.summary || values.out_teaser]}</div>',
              '<div class="credit">',
               'Created on {[AIR2.Format.date(values.out_cre_dtim)]}',
               ' by {[AIR2.Format.createLink( values.creator_fl, "/user/"+values.creator_uuid, true)]}',
                '</div>',
              '<tpl if="out_url">',
              '<div class="ext-link">',
               '<a href="{out_url}"><i class="icon-external-link"></i>&nbsp;{[values.out_show || values.out_url]}</a>',
              '</div>',
              '</tpl>',
             '</div>',
             '<table>',
              '<tr>',
               '<th>Tags:</th>',
               '<td>',
               '<tpl for="tag"',
                '<span class="tag">',
                 '<a href="<?php echo $c->uri_for("search/pinfluence") ?>?q=',
                 '{[encodeURIComponent("tag=("+AIR2.Search.cleanQueryForTag(values)+")")]}">{.}',
                 '</a>',
                '</span>',
                '{[xindex != xcount ? ", " : "" ]}',
               '</tpl>',
               '</td>',
              '</tr>',
              '<tr>',
               '<th>Projects:</th>',
               '<td>',
               '<tpl for="prj_uuid_title">',
                '<span class="project">',
                '{[AIR2.Format.projectName(this.splitProjectTitle(values), true)]}',
                '</span>',
                '{[xindex != xcount ? ", " : "" ]}',
               '</tpl>',
               '</td>',
              '</tr>',
             '</table>',
            '</div>',
           '</tpl>',
           {
               compiled: true,
               disableFormats: true,
               splitProjectTitle: function(values) {
                   var prj = values.split(':');
                   return { prj_uuid: prj[0], prj_display_name: prj[1] }
               }
           }
        );

        facetDefs = {
            org_uuid : {
                label : 'Organization',
                itemLabels : <?php echo Encoding::json_encode_utf8($org_uuids) ?>
            },
            tag : {
                label : 'Tag'
            },
            inq_uuid_title : {
                label : 'Query'
            },
            prj_uuid_title : {
                label : 'Project',
                itemLabels : <?php echo Encoding::json_encode_utf8($prj_names) ?>
            }
        };

        app = new AIR2.UI.App({
            items: AIR2.SearchPanel({
                title       : 'PINfluence',
                searchUrl   : '<?php echo $search_url ?>?',
                resultTpl   : resultTpl,
                facetDefs   : facetDefs

            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search',
            title: 'PINfluence'
        });

    });
</script>
