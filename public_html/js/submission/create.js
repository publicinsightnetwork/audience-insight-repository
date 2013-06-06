Ext.ns('AIR2.Submission');
/***************
 * Submission creation modal window
 *
 * Opens a modal window to create a manual-entry submission.
 *
 * @cfg {String} src_uuid
 * @cfg {HTMLElement} originEl (optional)
 *     Origin element to animate from
 * @cfg {Boolean} redirect (default false)
 *     True to redirect on success
 * @cfg {Function} callback (optional)
 *     Function to call after ajax request.  Will be passed <true, data> on
 *     success, or <false, message> on failure.
 */
AIR2.Submission.Create = function (cfg) {
    var datefield,
        descbox,
        formitems,
        projectbox,
        srcfield,
        submitForm,
        textbox,
        typebox,
        w;

    formitems = [];

    // need a crazy src-uuid-picker if not provided
    if (!cfg.src_uuid) {
        srcfield = new AIR2.UI.SearchBox({
            fieldLabel: 'Source Email',
            cls: 'air2-magnifier',
            allowBlank: false,
            width: 280,
            msgTarget: 'under',
            searchUrl: AIR2.HOMEURL + '/source',
            valueField: 'src_uuid',
            displayField: 'primary_email',
            emptyText: 'Search Writable Sources',
            listEmptyText:
                '<div style="padding:4px 8px">' +
                    'No Writable Sources Found' +
                '</div>',
            queryParam: 'email',
            minChars: 2,
            pageSize: 10,
            baseParams: {
                sort: 'primary_email asc',
                write: 1
            },
            formatComboListItem: function (v) {
                return v.primary_email;
            }
        });
    }
    else {
        srcfield = new Ext.form.DisplayField({
            fieldLabel: 'Source',
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/source/' + cfg.src_uuid + '.json',
                        success: function (resp, opts) {
                            var data, name;

                            data = Ext.decode(resp.responseText);
                            name = AIR2.Format.sourceFullName(data.radix);
                            fld.setValue('<b>' + name + '</b>');
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.src_uuid;
            }
        });
    }
    formitems.push(srcfield);

    // submission fields
    projectbox = new AIR2.UI.SearchBox({
        name: 'prj_uuid',
        fieldLabel: 'Project',
        cls: 'air2-magnifier',
        allowBlank: false,
        width: 280,
        msgTarget: 'under',
        searchUrl: AIR2.HOMEURL + '/project',
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        emptyText: 'Search Projects',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        pageSize: 10,
        baseParams: {sort: 'prj_display_name asc'},
        formatComboListItem: function (v) {
            return v.prj_display_name;
        }
    });

    datefield = new Ext.form.DateField({
        name: 'srs_date',
        fieldLabel: 'Date',
        value: new Date().clearTime(),
        allowBlank: false,
        msgTarget: 'under',
        width: 100
    });

    typebox = new AIR2.UI.ComboBox({
        name: 'manual_entry_type',
        fieldLabel: 'Type',
        choices: [
            ['E', 'Email'],
            ['P', 'Phone Call'],
            ['T', 'Text Message'],
            ['I', 'In-person Interaction']
        ],
        value: 'E',
        width: 150
    });

    descbox = new Ext.form.TextArea({
        name: 'manual_entry_desc',
        fieldLabel: 'Description',
        emptyText: 'description of the interaction',
        maskRe: /[^\n\r]/,
        allowBlank: false,
        msgTarget: 'under',
        width: 280,
        height: 40
    });

    textbox = new Ext.form.TextArea({
        name: 'manual_entry_text',
        fieldLabel: 'Text',
        emptyText: 'the sources words',
        allowBlank: false,
        msgTarget: 'under',
        width: 280,
        height: 120
    });

    formitems.push(projectbox, datefield, typebox, descbox, textbox);

    // submit function
    submitForm = function () {
        var data,
            el,
            f,
            srcuuid;

        f = w.get(0).getForm();
        el = w.get(0).el;

        // validate and fire the ajax save
        if (f.isValid()) {
            el.mask('Saving');
            srcuuid = srcfield.getValue();
            data = {
                prj_uuid: projectbox.getValue(),
                srs_date: datefield.getValue(),
                manual_entry_type: typebox.getValue(),
                manual_entry_desc: descbox.getValue(),
                manual_entry_text: textbox.getValue()
            };

            // POST (create) submission
            Ext.Ajax.request({
                method: 'POST',
                url: AIR2.HOMEURL + '/source/' + srcuuid + '/submission.json',
                params: {radix: Ext.encode(data)},
                callback: function (opt, success, rsp) {
                    var data, dataUrl, msg, title;

                    // calculate the actual success (including 200's)
                    data = Ext.decode(rsp.responseText);
                    success = (success) ? data.success : false;

                    if (success) {
                        dataUrl = AIR2.HOMEURL + '/submission/';
                        dataUrl += data.radix.srs_uuid;
                        if (cfg.callback) {
                            cfg.callback(true);
                        }
                        if (cfg.redirect) {
                            location.href = dataUrl;
                        }

                        w.close();
                    }
                    else {
                        if (rsp.status == 403) {
                            title = 'Permission Denied';
                        }
                        else {
                            title = 'Error';
                        }

                        msg = (data) ? data.message : 'Unknown server error';
                        if (cfg.callback) {
                            cfg.callback(false, msg);
                        }

                        AIR2.UI.ErrorMsg(el, title, msg);
                        el.unmask();
                    }
                }
            });
        }
    };

    // modal form window
    w = new AIR2.UI.Window({
        title: 'Create Submission',
        iconCls: 'air2-icon-response',
        closeAction: 'close',
        width: 400,
        height: 265,
        padding: '6px 0',
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            style: 'padding: 5px 10px 0',
            labelWidth: 85,
            items: formitems,
            bbar: [
                {
                    xtype: 'air2button',
                    air2type: 'SAVE',
                    air2size: 'MEDIUM',
                    text: 'Save',
                    handler: submitForm
                },
                '  ',
                {
                    xtype: 'air2button',
                    air2type: 'CANCEL',
                    air2size: 'MEDIUM',
                    text: 'Cancel',
                    handler: function () {w.close(); }
                }
            ]
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
