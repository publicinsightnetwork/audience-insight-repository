Ext.ns('AIR2.Preference');
/***************
 * Outcome creation modal window
 *
 * Opens a modal window to allow creating new outcomes
 *
 * @function AIR2.Outcome.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 * @cfg {Object}        prj_obj
 * @cfg {Object}        org_obj
 * @cfg {String}        src_uuid
 * @cfg {String}        inq_uuid
 *
 */
AIR2.Preference.Create = function(cfg) {

    // form fields
    var flds = [{
        xtype: 'air2remotetext',
        fieldLabel: 'Email Address',
        name: 'sem_email',
        remoteTable: 'srcemail',
        vtype: 'email',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255,
        uniqueErrorText: function(data) {
            var msg = 'Email in use';
            if (data.conflict && data.conflict[this.getName()]) {
                var src = data.conflict[this.getName()];
                var link = AIR2.Format.sourceName(src, true, true);
                msg += ' by ' + link;
            }
            return msg;
        }
    },{
        fieldLabel: 'First Name',
        name: 'src_first_name',
        allowBlank: true,
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    },{
        fieldLabel: 'Last Name',
        name: 'src_last_name',
        allowBlank: true,
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    // hide src_channel per #2318
    //},{
    //    fieldLabel: 'Channel',
    //    xtype: 'air2combo',
    //    name: 'src_channel',
    //    choices: AIR2.Fixtures.CodeMaster.src_channel,
    //    value: 'O'
    }];

    // add either an org-picker, or a static display field
    if (!cfg.org_uuid) {
        flds.push({
            xtype: 'air2searchbox',
            name: 'org_uuid',
            cls: 'air2-magnifier',
            fieldLabel: 'Home Org',
            searchUrl: AIR2.HOMEURL+'/organization',
            valueField: 'org_uuid',
            displayField: 'org_display_name',
            emptyText: 'Search Organizations (Writable)',
            listEmptyText: '<div style="padding:4px 8px">No Organizations Found</div>',
            pageSize: 10,
            baseParams: {
                sort: 'org_display_name asc',
                role: 'F' //only freemium role and higher
            },
            formatComboListItem: function(v) {
                return v.org_display_name;
            }
        });
    }
    else {
        flds.push({
            xtype: 'displayfield',
            fieldLabel: 'Organization',
            name: 'org_uuid',
            html: '<img src="'+AIR2.HOMEURL+'/css/img/loading.gif"></src>',
            plugins: {
                init: function(fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/organization/'+cfg.org_uuid+'.json',
                        success: function(resp, opts) {
                            var data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.org_display_name);
                        }
                    });
                }
            },
            getValue: function() {
                return cfg.org_uuid;
            }
        });
    }

    var w = new AIR2.UI.Window({
        title: 'Create Source',
        iconCls: 'air2-icon-source',
        closeAction: 'close',
        width: 400,
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
                width: 290,
                msgTarget: 'under'
            },
            items: flds,
            bbar: [{
                xtype: 'air2button',
                air2type: 'SAVE',
                air2size: 'MEDIUM',
                text: 'Save',
                handler: function() {
                    var f = w.get(0).getForm(), el = w.get(0).el;

                    // validate and fire the ajax save
                    if (f.isValid()) {
                        el.mask('Saving...');
                        Ext.Ajax.request({
                            url: AIR2.HOMEURL + '/source.json',
                            params: {radix: Ext.encode(f.getFieldValues())},
                            callback: function(opt, success, rsp) {
                                if (success) {
                                    el.unmask();
                                    el.mask('Loading new Source...');
                                    var d = Ext.decode(rsp.responseText);
                                    if (d.success && d.radix.src_uuid) {
                                        if (cfg.callback) cfg.callback(true);
                                        if (cfg.redirect) {
                                            location.href = AIR2.HOMEURL + '/source/' + d.radix.src_uuid;
                                        }
                                        else {
                                            w.close();
                                        }
                                        return;
                                    }
                                }
                                // failed
                                if (cfg.callback) cfg.callback(true, rsp.responseText);
                                el.unmask();
                                if (rsp.status == 403) {
                                    AIR2.UI.ErrorMsg(el, 'Permission denied', 'Do you have write permission to the selected Organization?');
                                    return;
                                }
                                var resp = Ext.decode(rsp.responseText);
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
            },'  ',{
                xtype: 'air2button',
                air2type: 'CANCEL',
                air2size: 'MEDIUM',
                text: 'Cancel',
                handler: function() {w.close();}
            }]  // end bbar
        }
    });

    if (cfg.originEl) w.show(cfg.originEl);
    else w.show();
    return w;
}
