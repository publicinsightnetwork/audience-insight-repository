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
| AIR2 Project search page
|--------------------------------------------------------------------------
*/
$search_url = $c->uri_for('search.json');
$project_url = $c->uri_for('project');
?>
<script type="text/javascript">
    Ext.onReady(function() {

        AIR2.Search.URL     = '<?php echo $c->uri_for("search") ?>';
        AIR2.Search.QUERY   = '<?php echo htmlspecialchars($q, ENT_QUOTES) ?>';
        AIR2.Search.PARAMS  = <?php echo Encoding::json_encode_utf8($params) ?>;
        AIR2.Search.IDX     = 'projects';
        AIR2.Search.ORGS    = <?php echo Encoding::json_encode_utf8($all_orgs) ?>;
        AIR2.Search.SORT_BY_OPTIONS = [
            ['score DESC','Score']
        ];

        var resultTpl = new Ext.XTemplate(
           '<tpl for=".">',
            '<div class="air2-search-result2">',
             '<h3><em class="air2-search-rank">{rank}</em><a class="air2-search-title" href="<?php echo $project_url ?>/{uri}">{title}</a></h3> ',
             '<a class="air2-search-child-count" href="<?php echo $c->uri_for("search") ?>/queries/?q={["prj_uuid%3d"+values.uri]}">{project_inquiries_count} queries</a>',
             '<ul>',
              '<li class="air2-search-excerpt"><div>{summary}</div></li>',
              '<li><strong>Organizations:</strong> ',
              '<tpl for="org_uuid">',
               '{[AIR2.Format.orgName(AIR2.Search.ORGS[values], true)]}',
              '</tpl>',
              '</li>',
              '<li><strong>Tags:</strong> ',
              '<tpl for="tag"',
               '<span class="tag">',
                '<a href="<?php echo $c->uri_for("search") ?>/projects/?q=',
                '{[encodeURIComponent("tag=("+AIR2.Search.cleanQueryForTag(values)+")")]}">{.}',
                '</a>',
               '</span>',
               '{[xindex != xcount ? ", " : "" ]}',
              '</tpl>',
              '</li>',
              '<li class="air2-search-created">Created {[AIR2.Format.dateHuman(values.prj_cre_dtim)]} by ',
               '{[AIR2.Format.createLink(values.author_fl, "/user/"+values.author_uuid, true)]}',
              '</li>',
             '</ul>',
            '</div>',
           '</tpl>'
        );

        var facetDefs = {

            org_uuid : {
                label : 'Organization',
                itemLabels : <?php echo Encoding::json_encode_utf8($org_uuids) ?>
            },

            tag : {
                label : 'Tag'
            }


        };

        var app = new AIR2.UI.App({
            items: AIR2.SearchPanel({
                title       : 'Projects',
                searchUrl   : '<?php echo $search_url ?>?',
                resultTpl   : resultTpl,
                facetDefs   : facetDefs

            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search',
            title: 'Projects'
        });

    });
</script>
