/***************
 * Query Org Authorizations Panel
 */
AIR2.Inquiry.Authorizations.Organizations = function () {

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
                '<tr class="org-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(' +
                            'values.iorg_cre_dtim' +
                        ')]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.orgNameLong(' +
                            'values.Organization,' +
                            '1' +
                        ')]}' +
                    '</td>' +
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
    //Logger(AIR2.Inquiry.authzOpts);
    //Logger(AIR2.Inquiry.BASE.authz);

    panel = new AIR2.UI.PagingEditor({
        title: 'Organizations',
        store: AIR2.Inquiry.orgStore,
        multiSort: 'org_display_name asc',
        allowEdit: function(rec) {
            //Logger(rec);
            return AIR2.Inquiry.authzOpts.mayManage(rec.id);
        },
        allowDelete: function (rec) {
            //Logger(rec);
            if (!AIR2.Inquiry.authzOpts.mayManage(rec.id)) {
                return false;
            }
            if (rec.store.getCount() < 2) {
                return false;
            }
            return true;
        },
        itemSelector: '.org-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: editTemplate,
        editRow: function (dv, node, rec) {
            var edits, org, orgEl;

            edits = [];

            // initial load
            if (rec.phantom) {
                orgEl = Ext.fly(node).first('td').next();
                orgEl.update('').setStyle('padding', '2px');
                org = new AIR2.UI.SearchBox({
                    searchUrl: AIR2.HOMEURL + '/organization',
                    pageSize: 10,
                    baseParams: {
                        sort: 'org_display_name',
                        excl_proj: AIR2.Project.UUID
                    },
                    valueField: 'org_uuid',
                    displayField: 'org_display_name',
                    cls: 'air2-magnifier',
                    emptyText: 'Search Organizations',
                    listEmptyText:
                        '<div style="padding:4px 8px">' +
                            'No Organizations Found' +
                        '</div>',
                    formatComboListItem: function (v) {
                        return v.org_display_name;
                    },
                    renderTo: orgEl,
                    width: 185,
                    listeners: {
                        select: function (cb, rec) {
                            // TODO ?
                        }
                    }
                });
                edits.push(org);
            }

            return edits;
        },
        saveRow: function (rec, edits) {
            if (rec.phantom) {
                rec.set('org_uuid', edits[0].getValue());
            }
        }
    });

    return panel;
}
