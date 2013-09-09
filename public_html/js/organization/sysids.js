/***************
 * Organization SysIds Panel
 */
AIR2.Organization.SysIds = function () {
    var allTypes, editTemplate, getRemainingTypes, p, template;

    allTypes = [['E', 'Lyris'], ['M', 'Mailchimp']];
    getRemainingTypes = function (store) {
        var all = [];
        Ext.each(allTypes, function (item) {
            if (store.find('osid_type', item[0]) === -1) {
                all.push(item);
            }
        });
        return all;
    };

    template =  new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Type</span></th>' +
            '<th><span>ID</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="sysid-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.osid_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.orgSysIdType(values.osid_type)]}</td>' +
              '<td>{values.osid_xuuid}</td>' +
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
            '<th><span>Type</span></th>' +
            '<th><span>ID</span></th>' +
            '<th class="right"><span>Created</span></th>' +
            '<th><span>User</span></th>' +
            '<th></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="sysid-row">' +
              '<td>{[AIR2.Format.orgSysIdType(values.osid_type)]}</td>' +
              '<td>{values.osid_xuuid}</td>' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.osid_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
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

    // create panel
    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'System Ids',
        showTotal: true,
        collapsed: true,
        iconCls: 'air2-icon-tag',
        storeData: AIR2.Organization.SYSIDDATA,
        url: AIR2.Organization.URL + '/sysid',
        itemSelector: '.sysid-row',
        tpl: template,
        editModal: {
            allowAdd: function () {
                if (AIR2.Organization.BASE.authz.may_manage) {
                    return 'Add Id';
                }
                else {
                    return false;
                }
            },
            width: 600,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/sysid',
                multiSort: 'osid_type asc',
                itemSelector: '.sysid-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                allowEdit: AIR2.Organization.BASE.authz.may_manage,
                allowDelete: AIR2.Organization.BASE.authz.may_manage,
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits, name, uuidEl, type, typeEl;

                    edits = [];
                    uuidEl = Ext.fly(node).first('td').next().update('');
                    name = new Ext.form.TextField({
                        width: 60,
                        allowBlank: false,
                        value: rec.data.osid_xuuid,
                        renderTo: uuidEl
                    });
                    edits.push(name);

                    if (rec.phantom) {
                        // create combobox
                        typeEl = Ext.fly(node).first('td').update('');
                        type = new AIR2.UI.ComboBox({
                            allowBlank: false,
                            choices: getRemainingTypes(dv.store),
                            value: rec.data.osid_type,
                            renderTo: typeEl
                        });
                        edits.push(type);
                    }
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('osid_xuuid', edits[0].getValue());
                    if (rec.phantom) {
                        rec.set('osid_type', edits[1].getValue());
                    }
                }
            },
            listeners: {
                show: function (w) {
                    var addBtn, refreshBtn, s;

                    addBtn = w.tools.get(1);
                    if (addBtn) {
                        s = w.get(0).store;
                        refreshBtn = function () {
                            var remain = getRemainingTypes(s);
                            addBtn.setDisabled(remain.length === 0);
                        };

                        // listeners
                        s.on('load', refreshBtn);
                        s.on('write', refreshBtn);
                        refreshBtn();
                    }
                }
            }
        }
    });

    return p;
};
