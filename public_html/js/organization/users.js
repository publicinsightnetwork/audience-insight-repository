/***************
 * Organization Users Panel
 */
AIR2.Organization.Users = function () {
    var editTemplate,
        p,
        template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Title</span></th>' +
            '<th><span>AIR Role</span></th>' +
            '<th class="center"><span>Home Org?</span></th>' +
            '<th><span>Status</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="user-row {[this.rowClass(values)]}">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.uo_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.userName(values.User,1,1)]}</td>' +
              '<td>{[this.formatTitle(values)]}</td>' +
              '<td>{[this.printRole(values)]}</td>' +
              '<td class="center"><tpl if="uo_home_flag">' +
                '<span class="air2-icon air2-icon-check"></span>' +
              '</tpl></td>' +
              '<td>' +
                '{[AIR2.Format.codeMaster(' +
                  '"user_status",' +
                  'values.User.user_status' +
                ')]}' +
              '</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            rowClass: function (values) {
                if (values.User.user_status === 'F') {
                    return 'inactive';
                }
                return '';
            },
            formatTitle: function (values) {
                if (values.uo_user_title && values.uo_user_title.length) {
                    return values.uo_user_title;
                }
                return '<span class="lighter">(none)</span>';
            },
            printRole: function (values) {
                return values.AdminRole.ar_name.replace(/ /g, "&nbsp;");
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Title</span></th>' +
            '<th><span>AIR Role</span></th>' +
            '<th class="home"><span>Home Org?</span></th>' +
            '<th><span>Status</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="user-row {[this.rowClass(values)]}">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.uo_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.userName(values.User,1,1)]}</td>' +
              '<td>{[this.formatTitle(values)]}</td>' +
              '<td>{[this.printRole(values)]}</td>' +
              '<td class="home"><tpl if="uo_home_flag">' +
                '<span class="air2-icon air2-icon-check"></span>' +
              '</tpl></td>' +
              '<td>{[this.formatStatus(values)]}</td>' +
              '<td class="row-ops">' +
                '<button class="air2-rowedit"></button>' +
                '<button class="air2-rowdelete">' +
              '</button></td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            rowClass: function (values) {
                if (values.User && values.User.user_status === 'F') {
                    return 'inactive';
                }
                return '';
            },
            formatTitle: function (values) {
                if (values.uo_user_title && values.uo_user_title.length) {
                    return values.uo_user_title;
                }
                return '<span class="lighter">(none)</span>';
            },
            formatStatus: function (values) {
                if (values.User) {
                    var s = values.User.user_status;
                    return AIR2.Format.codeMaster("user_status", s);
                }
                return '';
            },
            printRole: function (values) {
                if (!values.AdminRole || !values.AdminRole.ar_name) {
                    return '';
                }
                return values.AdminRole.ar_name.replace(/ /g, "&nbsp;");
            }
        }
    );

    p = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Users',
        showTotal: true,
        cls: 'air2-org-users',
        iconCls: 'air2-icon-user',
        storeData: AIR2.Organization.USRDATA,
        url: AIR2.Organization.URL + '/user',
        itemSelector: '.user-row',
        tpl: template,
        tools: ['->', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: 'air2-icon-add',
            tooltip: 'Create User',
            hidden: !AIR2.Organization.BASE.authz.may_manage,
            handler: function () {
                AIR2.User.Create({
                    originEl: this.el,
                    orgUUID: AIR2.Organization.UUID,
                    callback: function (success, msg) {
                        if (success) {
                            p.reload();
                        }
                    }
                });
            }
        }],
        //modalAdd: 'Add User',
        editModal: {
            title: 'Organization Users',
            allowAdd: function () {
                if (AIR2.Organization.BASE.authz.may_manage) {
                    return 'Add User';
                }
                else {
                    return false;
                }
            },
            allowNew: function () {
                if (AIR2.Organization.BASE.authz.may_manage) {
                    return 'New User';
                }
                else {
                    return false;
                }
            },
            createNewFn: AIR2.User.Create,
            createNewCfg: {
                orgUUID: AIR2.Organization.UUID
            },
            width: 700,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/user',
                multiSort: 'user_first_name ASC',
                newRowDef: {
                    AdminRole: '',
                    uo_home_flag: false,
                    uo_title: '',
                    uo_ar_id: 2
                },
                allowEdit: AIR2.Organization.BASE.authz.may_manage,
                allowDelete: AIR2.Organization.BASE.authz.may_manage,
                itemSelector: '.user-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        home,
                        homeEl,
                        rolechoices,
                        role,
                        roleEl,
                        user,
                        userEl;

                    edits = [];
                    roleEl = Ext.fly(node).first('td').next().next().next();
                    roleEl.update('').setStyle('padding', '2px');
                    rolechoices = [];
                    Ext.each(AIR2.Fixtures.AdminRole, function (ar) {
                        if (ar.ar_status === 'A') {
                            rolechoices.push([ar.ar_id, ar.ar_name]);
                        }
                    });
                    role = new AIR2.UI.ComboBox({
                        choices: rolechoices,
                        renderTo: roleEl,
                        value: rec.data.uo_ar_id,
                        width: 75
                    });
                    edits.push(role);

                    homeEl = roleEl.next().update('');
                    home = new Ext.form.Checkbox({
                        checked: rec.data.uo_home_flag,
                        renderTo: homeEl
                    });
                    edits.push(home);

                    if (rec.phantom) {
                        userEl = Ext.fly(node).first('td').next();
                        userEl.update('').setStyle('padding', '0 2px 0 5px');
                        user = new AIR2.UI.SearchBox({
                            cls: 'air2-magnifier',
                            searchUrl: AIR2.HOMEURL + '/user',
                            pageSize: 10,
                            baseParams: {excl_org: AIR2.Organization.UUID},
                            valueField: 'user_uuid',
                            displayField: 'user_username',
                            listEmptyText:
                                '<div style="padding:4px 8px">' +
                                    'No Users Found' +
                                '</div>',
                            emptyText: 'Search Users',
                            formatComboListItem: function (v) {
                                return AIR2.Format.userName(v);
                            },
                            allowBlank: false,
                            renderTo: userEl,
                            width: 160
                        });
                        edits.push(user);
                    }

                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('uo_ar_id', edits[0].getValue());
                    rec.set('uo_home_flag', edits[1].getValue());
                    if (rec.phantom) {
                        rec.set('user_uuid', edits[2].getValue());
                    }
                }
            },
            listeners: {
                show: function (w) {
                    var addBtn, newBtn;

                    newBtn = w.tools.get('win-btn-new');
                    addBtn = w.tools.get('win-btn-add');
                    w.newBtn = newBtn;
                    if (newBtn) {
                        // function to determine disable status
                        newBtn.checkMaxUsers = function () {
                            if (newBtn.tid) {
                                Ext.Ajax.abort(newBtn.tid);
                                delete newBtn.tid;
                            }

                            newBtn.disable();
                            addBtn.disable();
                            newBtn.tid = Ext.Ajax.request({
                                url: AIR2.Organization.URL + '.json',
                                success: function (resp) {
                                    var act, data, max, remain;

                                    data = Ext.decode(resp.responseText);

                                    // disable if not enough orgs
                                    max = parseInt(
                                        data.radix.org_max_users,
                                        10
                                    );
                                    act = parseInt(data.radix.active_users, 10);
                                    remain = max - act;
                                    if (max >= 0 && remain < 1) {
                                        newBtn.setTooltip('Max Users reached!');
                                        addBtn.setTooltip('Max Users reached!');
                                    }
                                    else {
                                        newBtn.setTooltip('');
                                        addBtn.setTooltip('');
                                        newBtn.enable();
                                        addBtn.enable();
                                    }
                                }
                            });
                        };
                        newBtn.checkMaxUsers();
                        w.get(0).store.on('save', newBtn.checkMaxUsers);
                    }
                },
                hide: function (w) {
                    if (w.newBtn) {
                        w.get(0).store.un('save', w.newBtn.checkMaxUsers);
                    }
                }
            }
        }
    });
    return p;
};
