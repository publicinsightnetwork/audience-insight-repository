/* Export a Bin in various formats */
Ext.ns('AIR2.Drawer');
AIR2.Drawer.Exporter = {
    // cf Trac #1841
    MAX_LYRIS_SIZE: AIR2.MAX_EMAIL_EXPORT,
    /* require authn, with dire warnings, and then prompt for output format */
    show: function (drawer) {

        //Logger('export:', drawer);
        AIR2.Auth.requirePassword(function () {
            AIR2.Drawer.Exporter.formatPicker(drawer);
        });
    },
    formatHandler: function (drawer, picker, ev) {
        var v = picker.getValue();
        Logger("picked", v);
        if (v === 'lyris') {

            //Logger(drawer);
            if (drawer.get('src_count') > AIR2.Drawer.Exporter.MAX_LYRIS_SIZE) {
                AIR2.UI.ErrorMsg(
                    picker,
                    "Maximum size exceeded",
                    "You may not export more then " +
                    AIR2.Drawer.Exporter.MAX_LYRIS_SIZE +
                    " items to Lyris at a time"
                );
                return;
            }
            AIR2.Drawer.Exporter.lyrisSelectors(true);
        }
        else {
            AIR2.Drawer.Exporter.lyrisSelectors(false);
        }


    },
    lyrisSelectors: function (show) {
        var form, inqPicker, orgPicker, prjPicker;

        form = Ext.getCmp('air2-drawer-exporter-form');
        orgPicker = Ext.getCmp('air2-drawer-exporter-orgpicker');
        prjPicker = Ext.getCmp('air2-drawer-exporter-prjpicker');
        inqPicker = Ext.getCmp('air2-drawer-exporter-inqpicker');

        if (!show) {
            if (orgPicker) {
                form.remove(orgPicker);
            }
            if (prjPicker) {
                form.remove(prjPicker);
            }
            if (inqPicker) {
                form.remove(inqPicker);
                form.remove(form.get(1));   // checkboxes
                //form.remove(form.get(1));   // checkboxes
                //form.remove(form.get(1));   // checkboxes
            }
        }
        else {
            if (orgPicker) {
                return; // already visible
            }
            form.insert(1, AIR2.Drawer.Exporter.OrgPicker());
            form.doLayout();
            Ext.QuickTips.init(); // each picker has a tooltip
            Ext.QuickTips.register({
                title: 'Select an Organization',
                target: 'air2-drawer-exporter-orgpicker-tt',
                anchor: 'right',
                text: 'Your Export will create a new segment on the Lyris ' +
                    'mailing list for this Organization.'
            });
        }
    },
    pickerTpl: function (name) {
        return new Ext.XTemplate(
            '<tpl for=".">' +
                '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item">' +
                    '{[values["' + name + '"]]}' +
                '</div>' +
            '</tpl>'
        );
    },
    OrgPicker: function () {
        var orgUrl, p, s;

        orgUrl = AIR2.HOMEURL + '/organization';
        s = new Ext.data.JsonStore({
            url: orgUrl + '.json?role=writer&sort=org_display_name',
            storeId: 'air2-drawer-exporter-orgstore',
            restful: true,
            remoteSort: true
        });
        p = new AIR2.UI.ComboBox({
            id: 'air2-drawer-exporter-orgpicker',
            store: s,
            mode: 'remote',
            width: 350,
            allowBlank: false,
            listClass:      'picker-box',
            itemSelector:   'div.picker-item',
            selectedClass:  'picker-item-selected',
            triggerAction: 'all',
            selectOnFocus: true,
            emptyText: 'Select an Organization...',
            forceSelection: true,
            fieldLabel: '<span id="air2-drawer-exporter-orgpicker-tt">' +
                    'Organization' +
                '</span>',
            valueField: 'org_uuid',
            displayField: 'org_display_name',
            name: 'org_uuid',
            tpl: AIR2.Drawer.Exporter.pickerTpl('org_display_name'),
            listeners: {
                'select': function (picker) {
                    var form, prjPicker, v;

                    v = picker.getValue();
                    Logger(v);
                    // add or reset PrjPicker
                    form = Ext.getCmp('air2-drawer-exporter-form');
                    if (form.get(2)) {
                        prjPicker = form.get(2);
                        prjPicker.resetOrg(v);
                        // inquiry too
                        if (form.get(3)) {
                            form.get(3).reset();
                        }
                    }
                    else {
                        prjPicker = AIR2.Drawer.Exporter.PrjPicker(v);
                        form.insert(2, prjPicker);
                        form.doLayout();
                        Ext.QuickTips.register({
                            title: 'Select a Project',
                            target: 'air2-drawer-exporter-prjpicker-tt',
                            anchor: 'right',
                            text: 'Exported Sources will receive Activity ' +
                                'records associated with this Project.'
                        });
                    }
                }
            }
        });
        return p;
    },
    PrjPicker: function (org_uuid) {
        var p, resetter, s;

        s = new Ext.data.JsonStore({
            url: AIR2.HOMEURL + '/project.json?sort=prj_display_name&status=A',
            storeId: 'air2-drawer-exporter-prjstore',
            restful: true,
            remoteSort: true
        });
        resetter = function (new_org_uuid) {
            Logger('new org_uuid=', new_org_uuid);
            //Logger(s);
            s.proxy.setUrl(AIR2.HOMEURL +
                '/project.json?sort=prj_display_name&status=A');
            s.reload();
        };
        p = new AIR2.UI.ComboBox({
            resetOrg: function (org_uuid) {
                this.reset();
                resetter(org_uuid);
            },
            id: 'air2-drawer-exporter-prjpicker',
            store: s,
            mode: 'remote',
            width: 350,
            allowBlank: false,
            listClass:      'picker-box',
            itemSelector:   'div.picker-item',
            selectedClass:  'picker-item-selected',
            triggerAction: 'all',
            selectOnFocus: true,
            emptyText: 'Select a Project...',
            forceSelection: true,
            fieldLabel: '<span id="air2-drawer-exporter-prjpicker-tt">' +
                    'Project' +
                '</span>',
            valueField: 'prj_uuid',
            displayField: 'prj_display_name',
            name: 'prj_uuid',
            tpl: AIR2.Drawer.Exporter.pickerTpl('prj_display_name'),
            listeners: {
                'select': function (picker) {
                    var checkboxes, form, inqPicker, v;

                    v = picker.getValue();
                    Logger(v);

                    // add or reset InqPicker
                    form = Ext.getCmp('air2-drawer-exporter-form');
                    if (form.get(3)) {
                        inqPicker = form.get(3);
                        inqPicker.resetPrj(v);
                    }
                    else {
                        inqPicker = AIR2.Drawer.Exporter.InqPicker(v);
                        form.insert(3, inqPicker);

                        // add strict checking option
                        if (form.get(4)) {
                            return;
                        }
                        checkboxes = [
                            {
                                id: 'air2-drawer-exporter-strict',
                                name: 'strict_check',
                                xtype: 'checkbox',
                                checked: true,   // on by default
                                fieldLabel: '<span ' +
                                    'id="air2-drawer-exporter-strict-tt">' +
                                        'Strict' +
                                    '</span>'
                            }
                        ];
                        form.add(checkboxes);
                        form.doLayout();

                        Ext.QuickTips.register({
                            title: 'Enable strict checking',
                            target: 'air2-drawer-exporter-strict-tt',
                            anchor: 'right',
                            text: 'If checked, will skip Sources who have ' +
                            'been exported to Lyris within the last 24 hours.'
                        });
                        Ext.QuickTips.register({
                            title: 'Select a Query',
                            target: 'air2-drawer-exporter-inqpicker-tt',
                            anchor: 'right',
                            text: 'After sending your e-mail via Lyris, ' +
                            'exported Sources will be automatically ' +
                            'associated with this Query.'
                        });
                    }
                }
            }
        });
        return p;
    },
    InqPicker: function (prj_uuid) {
        var s, resetter, p;

        s = new Ext.data.JsonStore({
            url: AIR2.HOMEURL + '/project/' + prj_uuid +
            '/inquiries.json?sort=inq_cre_dtim&dir=DESC',
            storeId: 'air2-drawer-exporter-inqstore',
            restful: true,
            remoteSort: true
        });
        resetter = function (new_prj_uuid) {
            //Logger('new prj_uuid=', new_prj_uuid);
            s.proxy.setUrl(AIR2.HOMEURL + '/project/' + new_prj_uuid  +
                '/inquiries.json?sort=inq_cre_dtim&dir=DESC');
            s.reload();
        };
        p = new AIR2.UI.ComboBox({
            resetPrj: function (prj_uuid) {
                this.reset();
                resetter(prj_uuid);
            },
            id: 'air2-drawer-exporter-inqpicker',
            store: s,
            mode: 'remote',
            width: 350,
            allowBlank: true,
            pageSize: 50,  // must page because there might be 1000s...
            listClass:      'picker-box',
            itemSelector:   'div.picker-item',
            selectedClass:  'picker-item-selected',
            triggerAction: 'all',
            selectOnFocus: true,
            emptyText: 'Select a Query...',
            forceSelection: true,
            fieldLabel: '<span id="air2-drawer-exporter-inqpicker-tt">' +
                    'Query' +
                '</span>',
            valueField: 'Inquiry:inq_uuid',
            displayField: 'Inquiry:inq_ext_title',
            name: 'inq_uuid',
            tpl: new Ext.XTemplate(
                '<tpl for=".">' +
                    '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item">' +
                        '{[values["Inquiry:inq_ext_title"]]} ' +
                        '<span class="air2-user">' +
                            '({[values["CreUser"]["user_username"]]})' +
                        '</span>' +
                    '</div>' +
                '</tpl>'
            ),
            listeners: {
                'select': function (picker) {
                    var v = picker.getValue();
                    //Logger(v);
                }
            }
        });
        return p;
    },
    formatPicker: function (drawer) {
        var closeBtn, form, picker, submitBtn;

        picker = new AIR2.UI.ComboBox({
            emptyText: 'Select an output...',
            width : 200,
            store : [
                ['csv',   'CSV'],
                ['lyris', 'Lyris']
                //['email', 'Email'],
                //['word',  'Word']
            ],
            //cls   : 'adv-search-ops',
            border: false,
            forceSelection: true,
            triggerAction: 'all',
            selectOnFocus: true,
            fieldLabel: 'Output',
            listeners : {
                'select' : function (picker, ev) {
                    AIR2.Drawer.Exporter.formatHandler(drawer, picker, ev);
                }
            }
        });
        submitBtn = new AIR2.UI.Button({
            air2type: 'BLUE',
            air2size: 'MEDIUM',
            text: 'Export',
            handler: function () {
                var format = picker.getValue();
                if (Ext.isDefined(AIR2.Drawer.Exporter[format])) {
                    submitBtn.disable();
                    closeBtn.disable();
                    AIR2.Drawer.Exporter[format](drawer, form);
                }
                else {
                    alert("That format is not yet available.");
                }
            }
        });
        closeBtn = new AIR2.UI.Button({
            air2type: 'CANCEL',
            air2size: 'MEDIUM',
            text: 'Cancel',
            handler: function () { AIR2.Drawer.Exporter.Window.close(); }
        });

        form = new Ext.form.FormPanel({
            id: 'air2-drawer-exporter-form',
            layout: 'form',
            style: 'padding: 8px',
            labelWidth: 80,
            width: 500,
            border: false,
            frame: false,
            labelAlign: 'right',
            items : [
                picker
            ],
            buttons: [
                submitBtn,
                closeBtn
            ],
            showCloseBtn: function () {
                submitBtn.hide();
                closeBtn.setText('Close').enable();
                form.items.each(function (item) {
                    if (item.disable) {
                        item.disable();
                    }
                });
            }
        });

        AIR2.Drawer.Exporter.Window = new AIR2.UI.Window({
            title : 'Export',
            modal : true,
            items : [form],
            width : 500,
            height: 300
        });
        AIR2.Drawer.Exporter.Window.show();
    },
    // redirect to download
    csv: function (drawer, formpanel) {
        var el, loc, uuid;

        uuid = drawer.get('bin_uuid');
        loc = AIR2.HOMEURL + '/bin/' + uuid + '/exportsource.csv?limit=0';
        if (Ext.isIE) {
            el = formpanel.el.createChild({
                html: '<a href="' + loc + '">Click to download CSV</a>',
                style: 'position:absolute; font-size:14px; font-weight:bold'
            });
            el.alignTo(formpanel.el, 'c-c');
        }
        else {
            location.href = loc;
        }

        //AIR2.Drawer.Exporter.Window.close();  // TODO decide
        formpanel.showCloseBtn();
    },
    lyris: function (drawer, formpanel) {
        var form, basicForm, mask, url, values;

        url = AIR2.HOMEURL + '/bin/' + drawer.get('bin_uuid') +
            '/export-lyris.json';
        form = Ext.getCmp('air2-drawer-exporter-form');
        basicForm = form.getForm();
        if (!basicForm.isValid()) {
            AIR2.UI.ErrorMsg(
                basicForm,
                'Invalid', 'Check that all form values are selected.'
            );
            formpanel.buttons[0].enable();
            formpanel.buttons[1].enable();
            return;
        }
        values = basicForm.getFieldValues();
        Logger(values);
        // do not user basicForm.submit() because it fails to send 'values'
        mask = new Ext.LoadMask(
            form.getEl(),
            {msg: 'Sending export request...'}
        );
        mask.show();
        Ext.Ajax.request({
            url: url,
            params: values,
            method: 'POST',
            success: function (f, action) {
                Logger(action);
                mask.hide();
                Ext.Msg.alert(
                    'Success',
                    'Your Bin was scheduled for export. You should receive ' +
                    'email shortly.'
                );
                formpanel.showCloseBtn();
            },
            failure: function (f, action) {
                Logger(action);
                mask.hide();
                AIR2.UI.ErrorMsg(
                    basicForm,
                    'Export Error',
                    'There was a problem exporting your Bin. Contact an ' +
                    'administrator for help.'
                );
                formpanel.buttons[0].enable();
                formpanel.buttons[1].enable();
            }
        });
    }
};


