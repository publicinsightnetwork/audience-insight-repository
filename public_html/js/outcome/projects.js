/***************
 * Outcome Projects Panel
 */
AIR2.Outcome.Projects = function () {
    var editTemplate,
        maywrite,
        template;

    maywrite = AIR2.Outcome.BASE.authz.may_write;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Name</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="project-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.pout_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.projectName(values,1)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Organizations</span></th>' +
            '<th><span>Added By</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="project-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.pout_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.projectName(values,1)]}</td>' +
              '<td>{[this.formatOrgs(values)]}</td>' +
              '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
              '<td class="row-ops">' +
                //'<button class="air2-rowedit"></button>' +
                '<button class="air2-rowdelete"></button>' +
              '</td>' +
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
            }
        }
    );

    // build panel
    AIR2.Outcome.Projects = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Projects',
        showTotal: true,
        showHidden: false,
        iconCls: 'air2-icon-project',
        storeData: AIR2.Outcome.PRJDATA,
        url: AIR2.Outcome.URL + '/project',
        itemSelector: '.project-row',
        tpl: template,
        modalAdd: 'Add Project',
        editModal: {
            title: 'PINfluence Projects',
            width: 650,
            allowAdd: maywrite ? 'Add Project' : false,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Outcome.URL + '/project',
                multiSort: 'prj_display_name asc',
                itemSelector: '.project-row',
                tpl: editTemplate,
                // row editor
                allowEdit: maywrite,
                allowDelete: maywrite,
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                editRow: function (dv, node, rec) {
                    var prjEl, proj;

                    prjEl = Ext.fly(node).first('td').next();
                    prjEl.update('').setStyle('padding', '4px');
                    proj = new AIR2.UI.SearchBox({
                        cls: 'air2-magnifier',
                        searchUrl: AIR2.HOMEURL + '/project',
                        pageSize: 10,
                        baseParams: {
                            excl_out: AIR2.Outcome.UUID
                        },
                        valueField: 'prj_uuid',
                        displayField: 'prj_display_name',
                        listEmptyText:
                            '<div style="padding:4px 8px">' +
                                'No Projects Found' +
                            '</div>',
                        emptyText: 'Search Projects',
                        formatComboListItem: function (v) {
                            return AIR2.Format.projectName(v);
                        },
                        renderTo: prjEl,
                        width: 200
                    });
                    return [proj];
                },
                saveRow: function (rec, edits) {
                    rec.set('prj_uuid', edits[0].getValue());
                }
            }
        }
    });
    return AIR2.Outcome.Projects;
};
