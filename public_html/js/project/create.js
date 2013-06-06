Ext.ns('AIR2.Project');
/***************
 * Project creation modal window
 *
 * Opens a modal window to allow creating new projects
 *
 * @function AIR2.Project.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 * @cfg {String}        org_uuid    (def: show picker)
 * @cfg {String}        inq_uuid    (def: no query involved)
 *
 */
AIR2.Project.Create = function (cfg) {
    var cb,
        flds,
        inqfld,
        tip,
        uuid,
        orgPicker,
        w;

    flds = [
        {
            xtype: 'air2remotetext',
            fieldLabel: 'Display Name',
            name: 'prj_display_name',
            remoteTable: 'project',
            autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
            maxLength: 255
        },
        {
            xtype: 'air2remotetext',
            fieldLabel: 'Short Name',
            name: 'prj_name',
            remoteTable: 'project',
            autoCreate: {tag: 'input', type: 'text', maxlength: '32'},
            maxLength: 32,
            maskRe: /[a-z0-9_\-]/
        },
        {
            xtype: 'textarea',
            fieldLabel: 'Summary',
            name: 'prj_desc',
            height: 100,
            maxLength: 4000
        }
    ];

    if (cfg.inq_uuid) {
        inqfld = {
            xtype: 'displayfield',
            fieldLabel: 'Query',
            name: 'inq_uuid',
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/inquiry/' + cfg.inq_uuid +
                             '.json',
                        success: function (resp, opts) {
                            var data, savebtn;

                            data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.inq_ext_title);
                            if (!data.authz.may_write) {
                                fld.ownerCt.items.each(function (item) {
                                    item.setDisabled(item !== fld);
                                });
                                fld.markInvalid('Insufficient query authz');
                                savebtn = w.get(0).bottomToolbar.get(0);
                                savebtn.disable();
                            }
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.inq_uuid;
            }
        };
        flds.splice(0, 0, inqfld);
    }

    if (!cfg.org_uuid) {
        orgPicker = new AIR2.UI.SearchBox({
            xtype: 'air2searchbox',
            id: 'air2-organization-picker',
            name: 'org_uuid',
            cls: 'air2-magnifier',
            fieldLabel: 'Organization',
            searchUrl: AIR2.HOMEURL + '/organization',
            pageSize: 10,
            baseParams: {
                sort: 'org_display_name asc',
                role: 'W'
            },
            valueField: 'org_uuid',
            displayField: 'org_display_name',
            listEmptyText:
                '<div style="padding:4px 8px">' +
                    'No Organizations Found' +
                '</div>',
            emptyText: 'Search Organizations (Writer role)',
            formatComboListItem: function (v) {
                return v.org_display_name;
            }
        });
        if (cfg.org_obj) {
            orgPicker.setValue(cfg.org_obj.org_display_name);
            orgPicker.selectRawValue(
                cfg.org_obj.org_uuid,
                cfg.org_obj.org_display_name
            );
        }
        flds.push(orgPicker);
    }
    else {
        flds.push({
            xtype: 'displayfield',
            fieldLabel: 'Organization',
            name: 'org_uuid',
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/organization/' + cfg.org_uuid +
                            '.json',
                        success: function (resp, opts) {
                            var data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.org_display_name);
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.org_uuid;
            }
        });
    }

    // support article
    tip = AIR2.Util.Tipper.create({id: 20164797, cls: 'lighter', align: 15});

    // create form window
    w = new AIR2.UI.CreateWin(Ext.apply({
        title: 'Create Project ' + tip,
        iconCls: 'air2-icon-project',
        formItems: flds,
        postUrl: AIR2.HOMEURL + '/project.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            if (cfg.callback) {
                cfg.callback(success, data);
                w.close();
            }
            if (success && cfg.redirect) {
                location.href = AIR2.HOMEURL + '/project/' +
                    data.radix.prj_uuid;
            }
        }
    }, cfg));

    // add listener to filter out orgs the user cannot PRJ_CREATE to
    if (!cfg.org_uuid && AIR2.USERINFO.type !== 'S') {
        cb = Ext.getCmp('air2-organization-picker');
        cb.store.on('load', function (thisStore, recs, opts) {
            thisStore.each(function (rec) {
                uuid = rec.get('org_uuid');
                if (!AIR2.Util.Authz.has('ACTION_ORG_PRJ_CREATE', uuid)) {
                    //Logger("filter out non-WRITER for " + uuid);
                    thisStore.remove(rec);
                }
                return true;
            });
        });
    }

    // show the window
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else if (cfg.originEl !== false) {
        w.show();
    }

    return w;
};
