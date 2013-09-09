Ext.ns('AIR2.Inquiry');
/***************
 * Query creation modal window
 *
 * Opens a modal window to allow creating new queries
 *
 * @function AIR2.Inquiry.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 *
 */
AIR2.Inquiry.Create = function (cfg) {
    var flds, w, orgPicker, prjPicker;

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
            role: 'W'
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
    orgPicker.on('select', function (box, rec) {
        var prj;

        prjPicker.enable().reset();
        prjPicker.store.removeAll();
        prjPicker.store.baseParams.org_uuid = rec.data.org_uuid;

        // pre-select the default project
        if (rec.data.DefaultProject) {
            prj = rec.data.DefaultProject;
            prjPicker.setValue(prj.prj_display_name);
            prjPicker.selectRawValue(prj.prj_uuid, prj.prj_display_name);
        }
    });
    if (cfg.org_obj) {
        orgPicker.setValue(cfg.org_obj.org_display_name);
        orgPicker.selectRawValue(
            cfg.org_obj.org_uuid,
            cfg.org_obj.org_display_name
        );
    }

    // project picker
    prjPicker = new AIR2.UI.SearchBox({
        disabled: true,
        name: 'prj_uuid',
        width: 375,
        cls: 'air2-magnifier',
        fieldLabel: 'Project',
        searchUrl: AIR2.HOMEURL + '/project',
        pageSize: 10,
        baseParams: {
            sort: 'prj_display_name asc'
        },
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        emptyText: 'Search Projects',
        formatComboListItem: function (v) {
            return v.prj_display_name;
        }
    });
    if (cfg.prj_obj) {
        prjPicker.setValue(cfg.prj_obj.prj_display_name);
        prjPicker.selectRawValue(
            cfg.prj_obj.prj_uuid,
            cfg.prj_obj.prj_display_name
        );
    }
    if (cfg.org_obj || cfg.prj_obj) {
        prjPicker.enable();
    }

    flds = [
        {
            xtype: 'textfield',
            fieldLabel: 'Title',
            name: 'inq_ext_title',
            autoCreate: {tag: 'input', type: 'text', maxlength: '500'},
            listeners: {
                'afterrender': function (field) {
                    field.focus(false, 500);
                }
            },
            maxLength: 500
        },
        {
            xtype: 'textarea',
            fieldLabel: 'Short Description',
            name: 'inq_rss_intro',
            height: 120,
            maxLength: 4000
        },
        {
            xtype: 'combo',
            autoSelect: true,
            editable: false,
            fieldLabel: 'Localization',
            forceSelection: true,
            name: 'loc_key',
            store: [
                ['en_US', 'English United States'],
                ['es_US', 'Spanish United States']
            ],
            triggerAction: 'all',
            value: 'en_US'
        },
        orgPicker,
        prjPicker
    ];

    // create form window
    w = new AIR2.UI.CreateWin(Ext.apply({
        title: 'Create Query',
        iconCls: 'air2-icon-inquiry',
        formItems: flds,
        postUrl: AIR2.HOMEURL + '/inquiry.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            if (cfg.callback) {
                cfg.callback(success, data);
                w.close();
            }
            if (success && cfg.redirect) {
                location.href = AIR2.HOMEURL + '/query/' + data.radix.inq_uuid;
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
