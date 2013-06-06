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
| AIR2 Inquiry search page
|--------------------------------------------------------------------------
*/
$search_url = $c->uri_for('search.json');
$inquiry_url = $c->uri_for('query');
?>
<script type="text/javascript">
    Ext.onReady(function() {

        AIR2.Search.URL     = '<?php echo $c->uri_for("search") ?>';
        AIR2.Search.QUERY   = '<?php echo htmlspecialchars($q, ENT_QUOTES) ?>';
        AIR2.Search.PARAMS  = <?php echo Encoding::json_encode_utf8($params) ?>;
        AIR2.Search.IDX     = 'inquiries';
        AIR2.Search.ORGS    = <?php echo Encoding::json_encode_utf8($all_orgs) ?>;
        AIR2.Search.SORT_BY_OPTIONS = [
            ['score DESC','Score'],
            ['lastmod DESC', 'Updated (newest first)'],
            ['lastmod ASC',  'Updated (oldest first)'],
            ['inq_cre_dtim DESC', 'Created (newest first)'],
            ['inq_cre_dtim ASC',  'Created (oldest first)'],
            ['inq_publish_date DESC', 'Published (newest first)'],
            ['inq_publish_date ASC',  'Published (oldest first)'],
            ['inq_title_sort ASC',     'Title (A-Z)'],
            ['inq_title_sort DESC',    'Title (Z-A)'],

        ];

        var resultTpl = new Ext.XTemplate(
           '<tpl for=".">',
            '<div class="air2-search-result2">',
             '<h3><em class="air2-search-rank">{rank}</em><a class="air2-search-title" href="<?php echo $inquiry_url ?>/{uri}">{title}</a></h3> ',
             '<div class="air2-search-inq-owner">',
             '<tpl for="owner_org_uuid">',
              '{[AIR2.Format.orgName(AIR2.Search.ORGS[values], true)]}',
             '</tpl>',
             '</div>',
             '<tpl if="response_sets_count">',
              '<a class="air2-search-child-count" href="<?php echo $c->uri_for("reader") ?>/query/{values.inq_uuid}">{response_sets_count} submissions</a>',
             '</tpl>',
             '<tpl if="!response_sets_count">',
              '<span class="air2-search-child-count">0 submissions</span>',
             '</tpl>',
             '<ul>',
              '<li class="air2-search-excerpt"><div>{summary}</div></li>',
              '<li><strong>Tags:</strong> ',
              '<tpl for="tag"',
               '<span class="tag">',
                '<a href="<?php echo $c->uri_for("search") ?>/queries/?q=',
                '{[encodeURIComponent("tag=("+AIR2.Search.cleanQueryForTag(values)+")")]}">{.}',
                '</a>',
               '</span>',
               '{[xindex != xcount ? ", " : "" ]}',
              '</tpl>',
              '</li>',
              '<li><strong>Projects:</strong> ',
              '<tpl for="prj_display_name">',
               '<span class="project">',
               '{[AIR2.Format.projectName( { prj_display_name:values, prj_uuid:parent.prj_uuid[xindex-1] }, true)]}',
               '</span>',
               '{[xindex != xcount ? ", " : "" ]}',
              '</tpl>',
              '</li>',
              '<li class="air2-search-created">Created: {[AIR2.Format.dateHuman(values.inq_cre_dtim)]} by ',
               '{[AIR2.Format.createLink( values.creator_fl, "/user/"+values.creator_uuid, true)]}',
               '<br/>Authors: ',
              '<tpl for="author_fl">',
               '{[AIR2.Format.createLink( values, "/user/"+parent.author_uuid[xindex-1], true)]}',
               '{[xindex != xcount ? ", " : "" ]}',
              '</tpl>',
               '<br/>Watchers: ',
              '<tpl for="watcher_fl">',
               '{[AIR2.Format.createLink( values, "/user/"+parent.watcher_uuid[xindex-1], true)]}',
               '{[xindex != xcount ? ", " : "" ]}',
              '</tpl>',
               '<br/>Updated: {[AIR2.Format.dateHuman(values.inq_upd_dtim)]}',
               '<br/>Published: {[AIR2.Format.date(values.inq_publish_date)]}',
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
            },

            prj_uuid_title : {
                label : 'Project',
                itemLabels : <?php echo Encoding::json_encode_utf8($prj_names) ?>
            },

            status : {
                label: 'Status'
            },

            inq_type : {
                label : 'Type',
                itemLabels : {"Q":"QueryMaker", "F":"Formbuilder", "M":"Manual Submission"}
            },

            inq_publish_date : {
                label : 'Published Date'
            },

            srs_ts   : {
                label : 'Responses by Date'
            },

            author   : {
                label : 'Author'
            },

            watcher : {
                label : "Watcher"
            },

            creator : {
                label : "Creator"
            }

        };

        var app = new AIR2.UI.App({
            items: AIR2.SearchPanel({
                title       : 'Queries',
                searchUrl   : '<?php echo $search_url ?>?',
                resultTpl   : resultTpl,
                facetDefs   : facetDefs
            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search',
            title: 'Queries'
        });

    });
</script>
