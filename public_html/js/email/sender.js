Ext.ns('AIR2.Email');
/***************
 * A modal window to send a quick email
 *
 * @function AIR2.Email.Sender
 * @cfg {HTMLElement}   originEl
 * @cfg {String}        title         (required)
 * @cfg {String}        src_uuid      (required - or srs_uuid)
 * @cfg {String}        srs_uuid      (required - or src_uuid)
 * @cfg {String}        internal_name (required)
 * @cfg {String}        type
 * @cfg {String}        subject_line
 * @cfg {String}        body
 *
 */
AIR2.Email.Sender = function (cfg) {
    var fm = Ext.util.Format;

    // defaults
    cfg.type = cfg.type || 'F';
    cfg.subject_line = Ext.isDefined(cfg.subject_line) ? cfg.subject_line : cfg.internal_name;
    cfg.body = cfg.body || ' ';

    // fields
    var flds = [{
        xtype: 'displayfield',
        fieldLabel: 'Internal Name',
        name: 'email_campaign_name',
        cls: 'campaign-name',
        value: fm.ellipsis(cfg.internal_name, 255)
    },{
        xtype: 'air2searchbox',
        name: 'org_uuid',
        width: 240,
        cls: 'air2-magnifier',
        fieldLabel: 'Organization',
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {
            sort: 'org_display_name asc',
            role: 'R', // ANY role in the org (except no-access)
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
        },
        listeners: {
            render: function(cb) {
                cb.selectOrDisplay(
                    AIR2.HOME_ORG.org_uuid,
                    AIR2.HOME_ORG.org_display_name,
                    AIR2.HOME_ORG.org_name.substring(0, 4)
                );
            }
        }
    },{
        xtype: 'combo',
        width: 240,
        autoSelect: true,
        editable: false,
        fieldLabel: 'Type',
        forceSelection: true,
        name: 'email_type',
        store: [
            ['F', 'Follow-up'],
            ['R', 'Reminder'],
            ['T', 'Thank You'],
            ['O', 'Other']
        ],
        triggerAction: 'all',
        value: cfg.type
    },{
        xtype: 'textfield',
        fieldLabel: 'Subject Line',
        name: 'email_subject_line',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255,
        allowBlank: false,
        value: fm.ellipsis(cfg.subject_line, 255)
    },{
        xtype: 'air2ckeditor',
        fieldLabel: 'Main text',
        name: 'email_body',
        allowBlank: false,
        ctCls: 'email-body',
        ckEditorConfig: { height: 100 },
        value: cfg.body
    },{
        xtype: 'air2searchbox',
        fieldLabel: 'Signature',
        name: 'usig_uuid',
        searchUrl: AIR2.HOMEURL + '/user/' + AIR2.USERINFO.uuid + '/signature',
        pageSize: 10,
        baseParams: {sort: 'usig_upd_dtim desc'},
        valueField: 'usig_uuid',
        displayField: 'usig_text_clean',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Signatures Found' +
            '</div>',
        emptyText: 'Search Signatures',
        formatComboListItem: function (v) {
            return AIR2.Format.signature(v, 80);
        },
        hideTrigger: false,
        editable: false,
        listeners: {
            // clean the text before selecting
            beforeselect: function (cb, rec, idx) {
                rec.data.usig_text_clean = AIR2.Format.signature(rec.data, 80);
            },
            // select something on render
            render: function(cb) {
                cb.store.on('load', function (store, rs) {
                    if (rs.length) {
                        rs[0].data.usig_text_clean = AIR2.Format.signature(rs[0].data, 80);
                        this.setValue(rs[0].id);
                    }
                }, cb, {single: true});
                cb.doQuery('', true);
            }
        }
    }];

    // source or submission field
    if (cfg.srs_uuid) {
        flds.push({xtype: 'hidden', name: 'srs_uuid', value: cfg.srs_uuid});
    }
    else {
        flds.push({xtype: 'hidden', name: 'src_uuid', value: cfg.src_uuid});
    }

    // create form window
    w = new AIR2.UI.CreateWin({
        title: cfg.title,
        cls: 'air2-email-sender',
        iconCls: 'air2-icon-email',
        formItems: flds,
        formStyle: 'padding: 0 10px',
        postUrl: AIR2.HOMEURL + '/email.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            var msg;
            if (success) {
                msg = 'Your email has been sent.'
                if (data.message && data.message.length == 12) {
                    var url = AIR2.HOMEURL + '/email/' + data.message;
                    msg += ' To view it, <a href="' + url + '">click here</a>.';
                }
                w.close();
                Ext.Msg.alert('Email Sent', '<br/>' + msg + '<br/>');
            }
            else {
                msg = 'An unknown error occurred while sending your email.  Please contact support.';
                if (data.message) {
                    msg = data.message;
                }
                w.close();
                AIR2.UI.ErrorMsg(null, 'Error sending email', msg);
            }
        },
        saveText: 'Send',
        width: 600,
        labelWidth: 100,
        defaultWidth: 450
    });

    w.on('afterrender', function (window) {
        window.setCustomTotal('All fields are required');
    });

    // show the window
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else if (cfg.originEl !== false) {
        w.show();
    }

    return w;
};
