/***************
 * Source Organizations Panel
 */
AIR2.Source.Organizations = function () {
    var editTemplate, p, template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Name</span></th>' +
                '<th style="width:60px"><span>Status</span></th>' +
                '<th class="fixw center"><span>Home</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.so_cre_dtim)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.orgNameLong(values.Organization,1)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"so_status",' +
                            'values.so_status' +
                        ')]}' +
                    '</td>' +
                    '<td class="center"><tpl if="so_home_flag">' +
                        '<span class="air2-icon air2-icon-home" ' +
                            'ext:qtip="Home Organization">' +
                        '</span>' +
                    '</tpl></td>' +
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
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Name</span></th>' +
                '<th style="width:60px"><span>Status</span></th>' +
                '<th class="fixw center"><span>Home</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.so_cre_dtim)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.orgNameLong(values.Organization,1)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"so_status",' +
                            'values.so_status' +
                        ')]}' +
                    '</td>' +
                    '<td class="center"><tpl if="so_home_flag">' +
                        '<span class="air2-icon air2-icon-home" ' +
                            'ext:qtip="Home Organization">' +
                        '</span>' +
                    '</tpl></td>' +
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

    p = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Organizations',
        showTotal: true,
        iconCls: 'air2-icon-organization',
        storeData: AIR2.Source.ORGDATA,
        url: AIR2.Source.URL + '/organization',
        itemSelector: '.org-row',
        tpl: template,
        modalAdd: 'Add Organization',
        editModal: {
            title: 'Source Organizations',
            allowAdd: function () {
                if (AIR2.Source.BASE.authz.unlock_write) {
                    return 'Add Organization';
                }
                else {
                    return false;
                }
            },
            width: 600,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/organization',
                multiSort: 'org_display_name asc',
                newRowDef: {so_status: 'A', so_home_flag: false},
                allowEdit: AIR2.Source.BASE.authz.unlock_write, //ignore lock
                allowDelete: (AIR2.USERINFO.type === "S"),
                itemSelector: '.org-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        home,
                        homeEl,
                        org,
                        orgEl,
                        role,
                        roleEl,
                        srcuuid;

                    // cache dv ref
                    rec.dv = dv;

                    // role
                    edits = [];
                    roleEl = Ext.fly(node).first('td').next().next();
                    roleEl.update('').setStyle('padding', '4px');
                    role = new AIR2.UI.ComboBox({
                        choices: AIR2.Fixtures.CodeMaster.so_status,
                        value: rec.data.so_status,
                        renderTo: roleEl,
                        width: 124
                    });
                    edits.push(role);

                    // home
                    homeEl = roleEl.next().update('');
                    home = new Ext.form.Checkbox({
                        checked: rec.data.so_home_flag,
                        disabled: rec.data.so_home_flag,
                        renderTo: homeEl
                    });
                    edits.push(home);

                    // organization
                    if (rec.phantom) {
                        orgEl = Ext.fly(node).first('td').next();
                        orgEl.update('').setStyle('padding', '4px');
                        srcuuid = AIR2.Source.UUID;
                        org = new AIR2.UI.SearchBox({
                            allowBlank: false,
                            searchUrl: AIR2.HOMEURL + '/organization',
                            pageSize: 10,
                            baseParams: {
                                sort: 'org_display_name',
                                excl_src: srcuuid
                            },
                            valueField: 'org_uuid',
                            displayField: 'org_display_name',
                            formatComboListItem: function (values) {
                                return values.org_display_name;
                            },
                            renderTo: orgEl,
                            width: 200
                        });
                        edits.push(org);
                    }
                    return edits;
                },
                saveRow: function (rec, edits) {
                    // if saving a home_flag, need to unset others in UI
                    var home = edits[1].getValue();
                    if (!rec.phantom && !rec.data.so_home_flag && home) {
                        rec.store.on(
                            'save',
                            function (s) {
                                s.each(function (r) {
                                    if (rec.id !== r.id) {
                                        r.data.so_home_flag = false;
                                        rec.dv.refreshNode(rec.dv.indexOf(r));
                                    }
                                });
                            },
                            this,
                            {single: true}
                        );
                    }

                    // update record
                    rec.set('so_status', edits[0].getValue());
                    rec.set('so_home_flag', edits[1].getValue());
                    if (rec.phantom) {
                        rec.set('org_uuid', edits[2].getValue());
                    }
                }
            }
        }
    });
    return p;
};
