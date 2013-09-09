/***************
 * Home Projects Panel
 */
AIR2.Home.Projects = function () {
    var template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Created</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>Organizations</span></th>' +
                '<th class="fixw center"><span>Queries</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="project-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.prj_cre_dtim)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.projectName(values,1)]}</td>' +
                    '<td>{[this.formatOrgs(values)]}</td>' +
                    '<td class="center">{[this.queryCount(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatOrgs: function (values) {
                var i, org, remain, str;

                if (values.ProjectOrg && values.ProjectOrg.length) {
                    str = '';
                    for (i = 0; i < values.ProjectOrg.length; i++) {
                        if (i < 2) {
                            org = values.ProjectOrg[i].Organization;
                            str += AIR2.Format.orgName(org, 1) + ' ';
                        }
                        else {
                            remain = values.ProjectOrg.length - i;
                            str += '+ ' + remain + ' more';
                            break;
                        }
                    }
                    return str;
                }
                return '<span class="lighter">(none)</span>';
            },
            queryCount: function (values) {
                var href, params, uuid;

                if (values.inquiry_count && values.inquiry_count > 0) {
                    uuid = values.prj_uuid;
                    params = Ext.urlEncode({q: 'prj_uuid=' + uuid});
                    href = AIR2.HOMEURL + '/search/queries?' + params;
                    return '<b><a href="' + href + '">' +
                        values.inquiry_count + '</a></b>';
                }
                return '0';
            }
        }
    );

    AIR2.Home.Projects = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Projects',
        cls: 'air2-home-project',
        iconCls: 'air2-icon-project',
        showTotal: true,
        showHidden: false,
        showAllLink: AIR2.HOMEURL + '/search/projects',
        storeData: AIR2.Home.PROJDATA,
        itemSelector: '.project-row',
        tpl: template
    });
    return AIR2.Home.Projects;
};
