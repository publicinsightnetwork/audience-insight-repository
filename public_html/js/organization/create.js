Ext.ns('AIR2.Organization');
AIR2.Organization.ORGMAXLIST = [
    [-1, 'Unlimited'],
    [0, 0],
    [1, 1],
    [2, 2],
    [3, 3],
    [4, 4],
    [5, 5],
    [6, 6],
    [7, 7],
    [8, 8],
    [9, 9],
    [10, 10],
    [11, 11],
    [12, 12]
];

/***************
 * Organization creation modal window
 *
 * Opens a modal window allowing the creation of new organizations or child
 * organizations.
 *
 * @function AIR2.Organization.Create
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @cfg {Boolean} redirect (default false) redirect on success
 * @cfg {String} parentUUID (optional) uuid of parent org
 * @cfg {Function} callback (optional) function passed boolean success
 *
 */
AIR2.Organization.Create = function (cfg) {
    // parent org display/chooser
    var parentfld,
        w;

    if (cfg.parentUUID) {
        parentfld = new Ext.form.DisplayField({
            fieldLabel: 'Parent Org',
            name: 'org_parent_uuid',
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/organization/' + cfg.parentfld +
                            '.json',
                        success: function (resp, opts) {
                            var data,
                                savebtn;

                            data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.org_display_name);
                            if (!data.authz.may_manage) {
                                fld.ownerCt.items.each(function (item) {
                                    item.setDisabled(item !== fld);
                                });
                                fld.markInvalid('Not manager in organization!');
                                savebtn = w.get(0).bottomToolbar.get(0);
                                savebtn.disable();
                            }
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.parentUUID;
            }
        });
    }
    else {
        parentfld = new AIR2.UI.SearchBox({
            name: 'org_parent_uuid',
            fieldLabel: 'Parent Org',
            cls: 'air2-magnifier',
            allowBlank: false,
            width: 280,
            msgTarget: 'under',
            searchUrl: AIR2.HOMEURL + '/organization',
            pageSize: 10,
            baseParams: {
                sort: 'org_display_name asc',
                role: 'M'
            },
            valueField: 'org_uuid',
            displayField: 'org_display_name',
            emptyText: 'Search Organizations (Manager role)',
            listEmptyText:
                '<div style="padding:4px 8px">' +
                    'No Organizations Found' +
                '</div>',
            formatComboListItem: function (v) {
                return v.org_display_name;
            },
            listeners: {
                render: function (cb) {
                    var top;

                    // SYSTEM users can create top-level orgs
                    if (AIR2.USERINFO.type !== 'S') {
                        cb.store.on('load', function (s) {
                            top = new s.recordType({
                                org_display_name:
                                    '(NONE - Top level Organization)',
                                org_uuid: null
                            });
                            s.insert(0, top);
                        });
                    }
                }
            }
        });
    }

    // create window
    w = new AIR2.UI.Window({
        title: 'Create Organization',
        iconCls: 'air2-icon-organization',
        closeAction: 'close',
        width: 370,
        height: 265,
        padding: '6px 0',
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            style: 'padding: 10px 10px 0',
            labelWidth: 85,
            defaults: {
                xtype: 'textfield',
                allowBlank: false,
                width: 260,
                msgTarget: 'under'
            },
            items: [parentfld, {
                xtype: 'air2remotetext',
                fieldLabel: 'Short Name',
                name: 'org_name',
                remoteTable: 'organization',
                autoCreate: {tag: 'input', type: 'text', maxlength: '32'},
                maxLength: 32
            }, {
                xtype: 'air2remotetext',
                fieldLabel: 'Long Name',
                name: 'org_display_name',
                remoteTable: 'organization',
                autoCreate: {tag: 'input', type: 'text', maxlength: '128'},
                maxLength: 128
            }, {
                xtype: 'air2combo',
                fieldLabel: 'Max Users',
                name: 'org_max_users',
                width: 100,
                value: 0,
                forceSelection: false,
                editable: true,
                choices: AIR2.Organization.ORGMAXLIST
            }],
            bbar: [{
                xtype: 'air2button',
                air2type: 'SAVE',
                air2size: 'MEDIUM',
                text: 'Save',
                handler: function () {
                    var el, f, data;

                    f = w.get(0).getForm();
                    el = w.get(0).el;

                    // validate and fire the ajax save
                    if (f.isValid()) {
                        el.mask('Saving');
                        data = f.getValues();

                        // fix org_parent_uuid, and don't send NULLs
                        data.org_parent_uuid = parentfld.getValue();
                        if (!data.org_parent_uuid) {
                            delete data.org_parent_uuid;
                        }

                        Ext.Ajax.request({
                            url: AIR2.HOMEURL + '/organization.json',
                            params: {radix: Ext.encode(data)},
                            callback: function (opt, success, rsp) {
                                var d,
                                    resp;

                                if (success) {
                                    d = Ext.decode(rsp.responseText);
                                    if (d.success && d.radix.org_uuid) {
                                        if (cfg.callback) {
                                            cfg.callback(true);
                                        }
                                        if (cfg.redirect) {
                                            location.href = AIR2.HOMEURL +
                                                '/organization/' +
                                                d.radix.org_uuid;
                                        }
                                        else {
                                            w.close();
                                        }
                                        return;
                                    }
                                }
                                // failed
                                if (cfg.callback) {
                                    cfg.callback(true, rsp.responseText);
                                }

                                el.unmask();
                                if (rsp.status === 403) {
                                    AIR2.UI.ErrorMsg(
                                        f,
                                        "Permission denied.",
                                        "Do you have write permission?"
                                    );
                                    return;
                                }
                                resp = Ext.decode(rsp.responseText);
                                if (resp && !resp.success && resp.message) {
                                    AIR2.UI.ErrorMsg(f, "Error", resp.message);
                                }
                                else {
                                    Logger(resp);
                                }
                            }
                        });
                    }
                }
            },
            ' ',
            {
                xtype: 'air2button',
                air2type: 'CANCEL',
                air2size: 'MEDIUM',
                text: 'Cancel',
                handler: function () {w.close(); }
            }]
        }
    });
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }

    return w;
};
