Ext.ns('AIR2.Source');
/***************
 * Source creation modal window
 *
 * Opens a modal window to allow creating new sources
 *
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @cfg {Boolean} redirect (default false) redirect on success
 * @cfg {Function} callback (optional) function passed boolean success
 * @cfg {string} org_uuid (optional) org to add the source to
 */
AIR2.Source.Create = function (cfg) {
    var flds, w, orgPicker;

    // organization picker
    orgPicker = new AIR2.UI.SearchBox({
        name: 'org_uuid',
        width: 375,
        cls: 'air2-magnifier',
        fieldLabel: 'Organization',
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {
            sort: 'org_display_name asc'
        },
        valueField: 'org_uuid',
        displayField: 'org_display_name',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Organizations Found' +
            '</div>',
        emptyText: 'Search Organizations',
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

    // form fields
    flds = [{
        xtype: 'air2remotetext',
        fieldLabel: 'Email Address',
        name: 'sem_email',
        remoteTable: 'srcemail',
        vtype: 'email',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255,
        uniqueErrorText: function (data) {
            var link, msg, src;

            msg = 'Email in use';
            if (data.conflict && data.conflict[this.getName()]) {
                src = data.conflict[this.getName()];
                link = AIR2.Format.sourceName(src, true, true);
                msg += ' by ' + link;
            }
            return msg;
        }
    }, {
        fieldLabel: 'First Name',
        name: 'src_first_name',
        allowBlank: true,
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    }, {
        fieldLabel: 'Last Name',
        name: 'src_last_name',
        allowBlank: true,
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    },
    orgPicker
    ];

    w = new AIR2.UI.Window({
        title: 'Create Source',
        iconCls: 'air2-icon-source',
        closeAction: 'close',
        width: 450,
        height: 365,
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
                width: 290,
                msgTarget: 'under'
            },
            items: flds,
            bbar: [{
                xtype: 'air2button',
                air2type: 'SAVE',
                air2size: 'MEDIUM',
                text: 'Save',
                handler: function () {
                    var f = w.get(0).getForm(), el = w.get(0).el;

                    // validate and fire the ajax save
                    if (f.isValid()) {
                        el.mask('Saving...');
                        Ext.Ajax.request({
                            url: AIR2.HOMEURL + '/source.json',
                            params: {radix: Ext.encode(f.getFieldValues())},
                            callback: function (opt, success, rsp) {
                                var d, resp;

                                if (success) {
                                    el.unmask();
                                    el.mask('Loading new Source...');
                                    d = Ext.decode(rsp.responseText);
                                    if (d.success && d.radix.src_uuid) {
                                        if (cfg.callback) {
                                            cfg.callback(true);
                                        }
                                        if (cfg.redirect) {
                                            location.href = AIR2.HOMEURL +
                                                '/source/' + d.radix.src_uuid;
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
                                        el,
                                        'Permission denied',
                                        'Do you have write permission to the ' +
                                        'selected Organization?'
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
            }, '  ', {
                xtype: 'air2button',
                air2type: 'CANCEL',
                air2size: 'MEDIUM',
                text: 'Cancel',
                handler: function () {w.close(); }
            }]  // end bbar
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
