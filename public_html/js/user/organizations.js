/***************
 * User Organizations Panel
 */
AIR2.User.Organizations = function () {
    var editTemplate,
        isAdmin,
        isManager,
        isOwner,
        managerEdit,
        ownerEdit,
        p,
        pTemplate,
        tip,
        tipLight;

    isAdmin = (AIR2.USERINFO.type === "S");
    isOwner = (AIR2.USERINFO.uuid === AIR2.User.UUID);

    // MANAGER role in any organization? show the button
    isManager = AIR2.Util.Authz.has('ACTION_ORG_USR_UPDATE');

    // helper to determine if a user may edit
    managerEdit = function (org_uuid) {
        return AIR2.Util.Authz.has('ACTION_ORG_USR_UPDATE', org_uuid);
    };

    ownerEdit = function (org_uuid) {
        // TODO: explicit action for this case
        return isOwner && AIR2.Util.Authz.has(
            'ACTION_ORG_PRJ_BE_CONTACT',
            org_uuid
        );
    };

    // support article
    tip = AIR2.Util.Tipper.create(20502042);
    tipLight = AIR2.Util.Tipper.create({
        id: 20502042,
        cls: 'lighter',
        align: 15
    });

    pTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw center"><span>Home</span></th>' +
                '<th><span>Name</span></th>' +
                '<th class="fixw"><span>Role</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td class="center"><tpl if="uo_home_flag">' +
                        '<span class="air2-icon air2-icon-home" ' +
                        'ext:qtip="Home Organization"></span>' +
                    '</tpl></td>' +
                    '<td>' +
                        '<tpl if="uo_home_flag><b></tpl>' +
                        '{[AIR2.Format.orgNameLong(' +
                            'values.Organization,' +
                            '1,' +
                            '35' +
                        ')]}' +
                        '<tpl if="uo_home_flag></b></tpl>' +
                    '</td>' +
                    '<td>' +
                        '<span class="role air2-corners2">' +
                            '{[this.printRole(values)]}' +
                        '</span>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            printRole: function (values) {
                return values.AdminRole.ar_name.replace(/ /g, "&nbsp;");
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Added</span></th>' +
                '<th class="fixw center"><span>Home</span></th>' +
                '<th class="fixw center"><span>Alerts</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>Role</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.uo_cre_dtim)]}' +
                    '</td>' +
                    '<td class="center"><tpl if="uo_home_flag==1">' +
                        '<span class="air2-icon air2-icon-home" ' +
                        'ext:qtip="Home Organization"></span>' +
                    '</tpl></td>' +
                    '<td class="center"><tpl if="uo_notify_flag">' +
                        '<span class="air2-icon air2-icon-notify" ' +
                        'ext:qtip="Notifications On"></span>' +
                    '</tpl></td>' +
                    '<td>' +
                        '<tpl if="uo_home_flag><b></tpl>' +
                        '{[AIR2.Format.orgNameLong(values.Organization,1)]}' +
                        '<tpl if="uo_home_flag></b></tpl>' +
                    '</td>' +
                    '<td>' +
                        '<span class="role air2-corners2">' +
                            '{[this.printRole(values)]}' +
                        '</span>' +
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
            disableFormats: true,
            printRole: function (values) {
                if (!values.AdminRole || !values.AdminRole.ar_name) {
                    return '';
                }
                return values.AdminRole.ar_name.replace(/ /g, "&nbsp;");
            }
        }
    );

    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Organizations ' + tip,
        showTotal: true,
        cls: 'air2-user-organization',
        iconCls: 'air2-icon-organization',
        storeData: AIR2.User.ORGDATA,
        url: AIR2.User.URL + '/organization',
        itemSelector: '.org-row',
        tpl: pTemplate,
        modalAdd: 'Add Organization',
        editModal: {
            title: 'User Organizations ' + tipLight,
            allowAdd: isManager ? 'Add Organization' : false,
            width: 600,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.User.URL + '/organization',
                multiSort: 'org_display_name asc',
                newRowDef: {
                    uo_home_flag: false,
                    uo_notify_flag: false,
                    uo_status: 'A',
                    uo_ar_id: 2,
                    AdminRole: ''
                },
                allowEdit: function (rec) {
                    var uuid = rec.data.org_uuid;
                    return (managerEdit(uuid) || ownerEdit(uuid));
                },
                allowDelete: function (rec) {
                    var uuid = rec.data.org_uuid;
                    return managerEdit(uuid);
                },
                itemSelector: '.org-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        notEl,
                        notify,
                        org,
                        orgEl,
                        role,
                        rolechoices,
                        roleEl;

                    edits = [];
                    notEl = Ext.fly(node).first('td').next().next();
                    notEl.update('');
                    notify = new Ext.form.Checkbox({
                        checked: rec.data.uo_notify_flag,
                        renderTo: notEl
                    });
                    edits.push(notify);

                    // new record or manager to edit role
                    if (
                        (rec.phantom && isManager) ||
                        managerEdit(rec.data.org_uuid)
                    ) {
                        roleEl = notEl.next().next();
                        roleEl.update('').setStyle('padding', '2px');

                        // only show active roles
                        rolechoices = [];
                        Ext.each(AIR2.Fixtures.AdminRole, function (ar) {
                            if (ar.ar_status === 'A') {
                                rolechoices.push([ar.ar_id, ar.ar_name]);
                            }
                        });
                        role = new AIR2.UI.ComboBox({
                            autoSelect: true,
                            choices: rolechoices,
                            renderTo: roleEl,
                            value: rec.data.uo_ar_id,
                            width: 95
                        });
                        edits.push(role);
                    }

                    // new record to edit org
                    if (rec.phantom && isManager) {
                        orgEl = notEl.next();
                        orgEl.update('').setStyle('padding', '2px');
                        org = new AIR2.UI.SearchBox({
                            searchUrl: AIR2.HOMEURL + '/organization',
                            pageSize: 10,
                            baseParams: {
                                sort: 'org_display_name',
                                excl_user: AIR2.User.UUID,
                                manage: 1 //only get manageable orgs
                            },
                            valueField: 'org_uuid',
                            displayField: 'org_display_name',
                            formatComboListItem: function (values) {
                                return values.org_display_name;
                            },
                            getErrors: function () {
                                var act,
                                    errs,
                                    max,
                                    rec,
                                    remain;

                                errs =
                                    AIR2.UI.SearchBox.superclass.getErrors.call(
                                        this
                                    );
                                if (errs.length) {
                                    return errs;
                                }
                                else if (this.selectedIndex >= 0) {
                                    // determine if more users can be added
                                    rec = this.store.getAt(this.selectedIndex);
                                    max = parseInt(rec.data.org_max_users, 10);
                                    act = parseInt(rec.data.active_users, 10);
                                    remain = max - act;
                                    if (max >= 0 && remain < 1) {
                                        return ['Max Users reached!'];
                                    }
                                }
                                return errs;
                            },
                            renderTo: orgEl
                        });
                        edits.push(org);
                    }
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('uo_notify_flag', edits[0].getValue());
                    if (edits.length > 1) {
                        rec.set('uo_ar_id', edits[1].getValue());
                    }
                    if (edits.length > 2) {
                        rec.set('org_uuid', edits[2].getValue());
                    }
                }
            }
        }
    });
    return p;
};
