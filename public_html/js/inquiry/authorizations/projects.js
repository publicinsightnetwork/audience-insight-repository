/***************
 * Query Project Authorizations Panel
 */
AIR2.Inquiry.Authorizations.Projects = function () {

    var editTemplate,
        panel;

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Name</span></th>' +
            '<th class="row-ops">' +
              '<tpl if="' + AIR2.Inquiry.authzOpts.isWriter + '">' +
                '<button class="air2-rowadd"></button>' +
              '</tpl>' +
            '</th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="project-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.pinq_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.projectName(values.Project,1)]}</td>' +
              '<td class="row-ops">' +
                '<button class="air2-rowedit"></button>' +
                '<button class="air2-rowdelete"></button>' +
              '</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    panel = new AIR2.UI.PagingEditor({
        title: 'Projects',
        url: AIR2.Inquiry.URL + '/project',
        multiSort: 'prj_display_name asc',
        newRowDef: {Project: {prj_cre_dtim: ''}},
        itemSelector: '.project-row',
        allowEdit: true,
        allowDelete: function (rec) {
            if (!AIR2.Inquiry.BASE.authz.may_manage) {
                return false;
            }
            if (rec.store.getCount() < 2) {
                return false;
            }
            return true;
        },
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: editTemplate,
        editRow: function (dv, node, rec) {
            var edits,
                prjEl,
                proj;

            edits = [];
            if (rec.phantom) {
                prjEl = Ext.fly(node).first('td').next();
                prjEl.update('').setStyle('padding', '4px');
                proj = new AIR2.UI.SearchBox({
                    cls: 'air2-magnifier',
                    searchUrl: AIR2.HOMEURL + '/project',
                    pageSize: 10,
                    baseParams: {
                        manage: 1,
                        excl_org: AIR2.Organization.UUID
                    },
                    valueField: 'prj_uuid',
                    displayField: 'prj_display_name',
                    listEmptyText:
                        '<div style="padding:4px 8px">' +
                            'No Projects Found' +
                        '</div>',
                    emptyText: 'Search Manageable Projects',
                    formatComboListItem: function (v) {
                        return AIR2.Format.projectName(v);
                    },

                    renderTo: prjEl,
                    width: 200
                });
                edits.push(proj);
            }

            return edits;
        },
        saveRow: function (rec, edits) {
            if (rec.phantom) {
                rec.set('prj_uuid', edits[0].getValue());
            }
            rec.set('inq_uuid', AIR2.Inquiry.UUID);
        }
    });

    return panel;

}
