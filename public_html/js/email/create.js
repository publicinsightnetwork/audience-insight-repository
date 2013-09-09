Ext.ns('AIR2.Email');
/***************
 * Email creation modal window
 *
 * Opens a modal window to allow creating new emails
 *
 * @function AIR2.Email.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 * @cfg {Object}        org_obj     (def: none)
 * @cfg {Object}        duplicate   (def: none)
 * @cfg {String}        email_type  (def: Q)
 *
 */
AIR2.Email.Create = function (cfg) {
    var flds, w, orgPicker, dupdata;

    // organization picker
    orgPicker = new AIR2.UI.SearchBox({
        name: 'org_uuid',
        width: 375,
        cls: 'air2-magnifier',
        fieldLabel: 'Organization',
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {
            sort: 'org_display_name asc',
            role: 'W', // writer and up
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
    else {
        orgPicker.selectOrDisplay(
            AIR2.HOME_ORG.org_uuid,
            AIR2.HOME_ORG.org_display_name,
            AIR2.HOME_ORG.org_name.substring(0, 4)
        );
    }

    flds = [
        {
            xtype: 'textfield',
            fieldLabel: 'Internal Name',
            name: 'email_campaign_name',
            autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
            listeners: {
                afterrender: function (field) {
                    field.focus(false, 500);
                }
            },
            maxLength: 255
        },
        {
            xtype: 'combo',
            autoSelect: true,
            editable: false,
            fieldLabel: 'Type',
            forceSelection: true,
            name: 'email_type',
            store: [
                ['Q', 'Query'],
                ['F', 'Follow-up'],
                ['R', 'Reminder'],
                ['T', 'Thank You'],
                ['O', 'Other']
            ],
            triggerAction: 'all',
            value: cfg.email_type || 'Q'
        },
        orgPicker
    ];

    // optional "duplicate" mode
    if (cfg.duplicate) {
        dupdata = cfg.duplicate.data || cfg.duplicate;
        flds[1].readOnly = true;
        flds[1].value = dupdata.email_type;
        flds.splice(0, 0, {
            xtype: 'displayfield',
            fieldLabel: 'Duplicate',
            name: 'dup_uuid',
            value: '<b>' + AIR2.Format.emailName(dupdata, 1, 30) + '</b>',
            getValue: function () {
                return dupdata.email_uuid;
            }
        });
    }

    // create form window
    w = new AIR2.UI.CreateWin(Ext.apply({
        title: 'Create Email',
        cls: 'air2-email-create',
        iconCls: 'air2-icon-email',
        formItems: flds,
        postUrl: AIR2.HOMEURL + '/email.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            if (cfg.callback) {
                cfg.callback(success, data);
                w.close();
            }
            if (success && cfg.redirect) {
                location.href = AIR2.HOMEURL + '/email/' + data.radix.email_uuid;
            }
        }
    }, cfg));

    w.on('afterrender', function (window) {
        window.setCustomTotal('All fields are required');
    });

    // show the window
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else if (cfg.originEl !== false) {
        //show if cfg.originEl is undef but not if it's false
        w.show();
    }

    return w;
};
