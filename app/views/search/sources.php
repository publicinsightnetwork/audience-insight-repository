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
| AIR2 Source search page
|--------------------------------------------------------------------------
*/
$search_url = $c->uri_for('search.json');
$source_url = $c->uri_for('source');
$inquiry_url = $c->uri_for('query');
$submission_url = $c->uri_for('submission');
$show_adv_search = $c->input->get('adv') ? 'true' : 'false';
$inquiry_titles_json = $c->uri_for('js/cache/inquiry-titles.js');
?>

<script type="text/javascript" src="<?php echo $inquiry_titles_json ?>"></script>
<script type="text/javascript">
    Ext.onReady(function() {

        AIR2.Search.URL     = '<?php echo $c->uri_for("search") ?>';
        AIR2.Search.QUERY   = '<?php echo htmlspecialchars($q, ENT_QUOTES) ?>';
        AIR2.Search.PARAMS  = <?php echo Encoding::json_encode_utf8($params) ?>;
        AIR2.Search.IDX     = '<?php echo $search_idx ?>';
        AIR2.Search.SORT_BY_OPTIONS = [
            ['score DESC','Score'],
            //['lastmod DESC', 'Last Modified (newest first)'],
            //['lastmod ASC', 'Last Modified (oldest first)'],
            ['last_queried_date DESC', 'Last Queried (newest first)'],
            ['last_queried_date ASC',  'Last Queried (oldest first)'],
            ['last_response_date DESC', 'Last Responded (newest first)'],
            ['last_response_date ASC',  'Last Responded (oldest first)'],
            ['primary_city ASC', 'City (A-Z)'],
            ['primary_city DESC', 'City (Z-A)'],
            ['primary_state ASC', 'State (A-Z)'],
            ['primary_state DESC', 'State (Z-A)'],
            ['primary_zip ASC', 'Postal Code (0-9)'],
            ['primary_zip DESC', 'Postal Code (9-0)'],
            ['primary_county ASC', 'County (A-Z)'],
            ['primary_county DESC', 'County (Z-A)']

        ];
        AIR2.Search.OrgLabels = <?php echo Encoding::json_encode_utf8($org_uuids) ?>;
        AIR2.Search.OrgNames  = <?php echo Encoding::json_encode_utf8($org_names) ?>;
        <?php if (preg_match('/^strict-/', $search_idx)) { ?>
        AIR2.Search.STRICT_MODE = true;
        <?php } ?>

        var submissions_tip = AIR2.Util.Tipper.create({id:'21998162', cls:'lighter', align:15});
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
             '<div class="source-contact">',
              '<h3>',
               '<span>{rank}.</span> <a href="<?php echo $source_url ?>/{uri}">{title}</a>',
              '</h3>',
              '<ul>',
               '<li class="r-loc">{primary_location}</li>',
               '<li class="r-phone">{primary_phone}</li>',
               '<li class="r-mail last"><a href="mailto:{primary_email}">{primary_email_html}</a></li>', // TODO air2 mta?
              '</ul>',
             '</div>', // source-contact
             '</td>',
             '<td>',
             '<div class="r-excerpt">',
              '<tpl for="qa_excerpts">',
               '<div class="r-snip {[xindex > 1 ? "r-snip-more" : "" ]}">',
                '<div class="qa-info">',
                '<tpl if="this.hasAuthzForSubmission(values.authz_org_ids)">',
                 '<strong><a target="air2-submission" href="<?php echo $submission_url ?>/{[values.srs_uuid]}">View submission</a></strong>',
                '</tpl>',
                '<tpl if="!this.hasAuthzForSubmission(values.authz_org_ids)">',
                 '<strong class="lighter">Submission protected</strong>&nbsp;',
                 '{[this.getSubmissionsTip()]}',
                '</tpl>',
                 '&nbsp;',
                 '<tpl if="values.owner_org_ids">',
                  '<tpl for="owner_org_ids">',
                   '&nbsp;{[AIR2.Format.orgName(AIR2.Search.OrgNames[values], 1)]}',
                  '</tpl>',
                 '</tpl>',
                 '<tpl if="this.hasAuthzForSubmission(values.authz_org_ids)">',
                  '&nbsp;<strong><a href="<?php echo $inquiry_url ?>{[values.inq_uuid]}">',
                  '{[this.getInquiryTitle(values.inq_uuid, true)]}</a></strong>',
                 '</tpl>',
                 '<tpl if="!this.hasAuthzForSubmission(values.authz_org_ids)">',
                  '&nbsp;<strong class="lighter">{[this.getInquiryTitle(values.inq_uuid, false)]}</strong>',
                 '</tpl>',
                '</div>',
                '<span class="snip">{[values.response]}<span class="r-date">- {[AIR2.Format.date(values.date)]}</span></span>',
               '</div>',
              '</tpl>',
              '{[(values.qa_excerpts && values.qa_excerpts.length) ? "<br/>" : "" ]}',
              '<tpl for="excerpts">',
               '<div class="r-snip {[xindex > 1 ? "r-snip-more" : "" ]}">',
                '<strong>{[AIR2.Fixtures.FieldLabels[values.field]||values.field]}</strong>&nbsp;&#187;&nbsp;',
                '<strong><a href="<?php echo $source_url ?>/{parent.uri}">View profile</a></strong><br/>',
                '<span class="snip">{snip}</span>',
               '</div>',
              '</tpl>',
              '<div class="r-activity">',
               '<span class="r-last">Last Queried: {[AIR2.Format.dateYmd(values.last_queried_date)]}</span>',
               '<span class="r-last">Last Submission: {[AIR2.Format.dateYmd(values.last_response_date)]}</span>',
              '</div>',
             '</div>', // r-excerpt
             '</td>',
             '</tr>',
             '</table>',
            '</div>',  // air2-search-result
           '</tpl>',
           {
               compiled: true,
               disableFormats: true,
               getInquiryTitle: function(inq_uuid, doLink) {
                   var inq = {inq_uuid:inq_uuid, inq_ext_title:AIR2.CACHE.Inquiries[inq_uuid]};
                   if (!inq['inq_ext_title']) {
                       inq['inq_ext_title'] = inq_uuid;
                   }
                   return AIR2.Format.inquiryTitle(inq, doLink);
               },
               hasAuthzForSubmission: function(org_ids) {
                   return AIR2.Util.Authz.hasAnyId('ACTION_ORG_READ', org_ids);
               },
               getSubmissionsTip: function() {
                   return submissions_tip;
               }
           }
        );
        resultTpl.compile();

        var stateLabels = {};
        var cntryLabels = {};
        Ext.each(AIR2.Fixtures.States, function(item,idx,states) {
            stateLabels[item[0]] = item[1];
        });
        Ext.each(AIR2.Fixtures.Countries, function(item,idx,cntrys) {
            cntryLabels[item[0]] = item[1];
        });

        var facetDefs = {
            user_gender : {
                label : AIR2.Fixtures.FieldLabels['user_gender'],
                fact_identifier : 'gender'
            },
            smadd_cntry : {
                label : AIR2.Fixtures.FieldLabels['country'],
                itemLabels: cntryLabels
            },
            smadd_state : {
                label : AIR2.Fixtures.FieldLabels['state'],
                itemLabels: stateLabels
            },
            smadd_county : {
                label : AIR2.Fixtures.FieldLabels['county']
            },
            smadd_zip : {
                label : AIR2.Fixtures.FieldLabels['smadd_zip']
            },
            src_household_income : {
                label : AIR2.Fixtures.FieldLabels['src_household_income'],
                fact_identifier : 'household_income'
            },
            src_education_level : {
                label : AIR2.Fixtures.FieldLabels['src_education_level'],
                fact_identifier : 'education_level'
            },
            src_political_affiliation : {
                label : AIR2.Fixtures.FieldLabels['src_political_affiliation'],
                fact_identifier : 'political_affiliation'
            },
            org_uuid : {
                label : 'Organization',
                itemLabels : AIR2.Search.OrgLabels
            },
            user_religion : {
                label : AIR2.Fixtures.FieldLabels['user_religion'],
                fact_identifier : 'religion'
            },
            last_queried_date : {
                label : 'Last Queried',
                sorter : function(a,b) {
                    if (b.term < a.term) { return -1 }
                    if (b.term > a.term) { return 1  }
                    return 0;
                }
            },
            last_response_date : {
                label : 'Last Response',
                sorter : function(a,b) {
                    if (b.term < a.term) { return -1 }
                    if (b.term > a.term) { return 1  }
                    return 0;
                }
            },
            user_ethnicity : {
                label : AIR2.Fixtures.FieldLabels['user_ethnicity'],
                fact_identifier : 'ethnicity'
            },
            birth_year : {
                label : 'Age'
            },
            tag : {
                label : 'Tag'
            },
            prj_uuid : {
                label : 'Project',
                itemLabels : <?php echo Encoding::json_encode_utf8($prj_names) ?>
            }


        };

        var app = new AIR2.UI.App({
            items: AIR2.SearchPanel({
                title           : '<?php echo $search_label ?>',
                searchUrl       : '<?php echo $search_url ?>?',
                resultTpl       : resultTpl,
                showAdvSearch   : <?php echo $show_adv_search ?>,
                facetDefs       : facetDefs
            })
        });
        app.setLocation({
            iconCls: 'air2-icon-savedsearch',
            type: 'Search',
            title: 'Sources'
        });

    });
</script>
