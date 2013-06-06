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
$response_url    = $c->uri_for('submission');   // TODO
$source_url      = $c->uri_for('source');
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
        AIR2.Search.IDX     = 'responses';
        AIR2.Search.SORT_BY_OPTIONS = [
            ['Score DESC','Score'],
            ['lastmod DESC', 'Last Modified']
        ];
        <?php if (preg_match('/^strict-/', $search_idx)) { ?>
        AIR2.Search.STRICT_MODE = true;
        <?php } ?>

        var resultTpl = new Ext.XTemplate(
           '<tpl for=".">',
            '<div class="air2-search-result">',
             '<table>',
              '<tr>',
               '<td class="checkbox-col">',
                '<div class="checkbox-handle">',
                 '<input class="drag-checkbox" type="checkbox"></input>',
                '</div>',
               '</td>',
               '<td>',
                '<div class="s-excerpt">',
                 '<div class="link">',
                  '<h3><a class="title" href="<?php echo $source_url ?>/{src_uuid}">{title}</a></h3>',
                 '</div>',
                 '<div><strong><a target="air2-submission" href="<?php echo $response_url ?>/{uri}">View submission</a></strong>',
                 '&nbsp;to&nbsp;<strong><a href="<?php echo $inq_url ?>/{inq_uuid}">{[values.inq_title||values.inq_ext_title]}</a></strong>',
                 '&nbsp;<span class="r-date"> - {[AIR2.Format.dateYmdLong(values.srs_ts)]}</span></div>',
                 '<div class="summary">{summary}</div>',
                '</div>',
               '</td>',
              '</tr>',
             '</table>',
            '</div>',
           '</tpl>'
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
                label : 'Inquiry'
            },

            srs_ts   : {
                label : 'Responses by Date'
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
