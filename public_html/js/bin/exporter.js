Ext.ns('AIR2.Bin.Exporter');

/**
 * Lyris-export modal window
 *
 * Show a dialog to export the contents of a Bin to Lyris
 *
 * @function AIR2.Bin.Exporter.toLyris
 * @cfg {String}      binuuid  (required)
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @return {AIR2.UI.Window}
 */
AIR2.Bin.Exporter = function (cfg) {
    if (!cfg.binuuid || !cfg.binuuid.length) {
        alert("INVALID bin uuid for export");
        return false;
    }
    var binfld,
        closebtn,
        countwarn,
        csvopt,
        csvopt2,
        exportbtn,
        inqbox,
        inqstrict,
        isAdmin,
        orgbox,
        prjbox,
        prjstrict,
        pswd,
        stricter,
        typebox,
        w,
        working;

    isAdmin = (AIR2.USERINFO.type === "S");

    // bin display field
    binfld = new Ext.form.DisplayField({
        fieldLabel: 'Bin',
        cls: 'bin-display',
        ctCls: 'bborder',
        html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
        plugins: {
            init: function () {
                var msg;
                Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/bin/' + cfg.binuuid + '.json',
                    callback: function (opts, success, resp) {
                        var data, name, num, subm;
                        data = Ext.util.JSON.decode(resp.responseText);
                        num = (data && data.radix) ? data.radix.src_count : 0;
                        if (success && data.success && num > 0) {
                            name = '<b>' + data.radix.bin_name + '</b>';
                            if (data.radix.subm_count > 0) {
                                subm = data.radix.subm_count;
                                name += '<p>' +
                                    Ext.util.Format.number(num, '0,000') +
                                    ' sources - ' +
                                    Ext.util.Format.number(subm, '0,000') +
                                    ' submissions</p>';
                            }
                            else {
                                name += '<p>' + num + ' sources</p>';
                            }
                            binfld.bin_counts = data.radix.counts;
                            binfld.bin_owner_flag = data.radix.owner_flag;
                            binfld.setValue(name);
                            pswd.enable();
                        }
                        else {
                            binfld.el.enableDisplayMode().hide();

                            if (data && data.message) {
                                msg = data.message;
                            }
                            else {
                                msg = 'Error: Invalid Bin!';
                            }

                            if (data && data.radix && num < 1) {
                                msg = 'No exportable sources in Bin!';
                            }

                            binfld.markInvalid(msg);
                            exportbtn.disable();
                        }
                    }
                });
            }
        },
        getValue: function () {
            return cfg.binuuid;
        },
        getOwner: function () {
            if (this.bin_owner_flag === 0 || !this.bin_owner_flag) {
                return false;
            }
            return true;
        }
    });

    // password validation field
    pswd = new Ext.form.TextField({
        fieldLabel: 'Verify Password',
        inputType: 'password',
        cls: 'air2-lock',
        ctCls: 'bborder',
        allowBlank: false,
        disabled: true,
        onRender: function (ct, position) {
            AIR2.UI.RemoteText.superclass.onRender.call(this, ct, position);
            this.remoteAction = ct.createChild({cls: 'air2-form-remote-wait'});
        },
        unsetActiveError: function (suppressEvent) {
            delete this.activeError;
            if (!this.preventMark) {
                this.fireEvent('valid', this);
            }
        },
        validator: function (value) {
            if (value.length < 1) {
                return 'Please enter your password';
            }

            // fire remote validation if value has changed
            if (value !== this.lastValue) {
                this.preventMark = true; //don't mark until callback
                this.lastValue = value;
                this.remoteIsValid = false;
                this.doRemoteValidation(value);
            }

            return (this.remoteIsValid) ? true : this.remoteMsg;
        },
        doRemoteValidation: function (value) {
            // show remote-wait icon
            this.remoteAction.alignTo(this.el, 'tr-tr', [0, 2]);
            this.remoteAction.show();
            AIR2.Util.Authz.checkPwd(
                AIR2.USERNAME,
                value,
                this.remoteCallback.createDelegate(this)
            );
        },
        remoteCallback: function (success, value) {
            this.remoteAction.hide();
            this.remoteIsValid = success;
            this.remoteMsg = (success) ? '' : 'Invalid Password';
            this.preventMark = false; // now allow marking
            this.validate(); // refire the validation
        },
        listeners: {
            invalid: function (fld) {
                fld.removeClass('air2-okay');
                fld.addClass('air2-lock');
                typebox.disable();
                orgbox.disable();
                prjbox.disable();
                prjstrict.disable();
            },
            valid: function (fld) {
                fld.removeClass('air2-lock');
                fld.addClass('air2-okay');
                if (fld.getValue().length) {
                    typebox.enable();
                }
            }
        }
    });

    // type of export
    typebox = new AIR2.UI.ComboBox({
        fieldLabel: 'Export Type',
        emptyText: 'Select an output...',
        choices: [
            ['csv', 'Sources to CSV File'],
            ['xls', 'Submissions to XLSX File'],
            ['lyris', 'Emails to Lyris']
        ],
        allowBlank: false,
        disabled: true,
        validator: function (value) {
            var attr, href, max, num, own, sup, tot;

            href = 'http://support.publicinsightnetwork.org';
            attr = 'href="' + href + '" class="external" target="_blank"';
            sup = '<a ' + attr + '>Contact support</a> for more information.';
            if (value.match(/lyris/i)) {
                num = binfld.bin_counts.src_export_lyris;
                own = binfld.getOwner();
                max = AIR2.Bin.Exporter.MAX_LYRIS_SIZE;
                if (num > max && !isAdmin) {
                    return 'Bin exceeds the maximum allowed for an export' +
                        ' to Lyris (' + max + ')';
                }
                if (!own && !isAdmin) {
                    return 'Only the owner of a Bin may export to Lyris';
                }
                if (num < 1) {
                    return 'You don\'t have authorization to Lyris-export ' +
                        'any sources in this bin';
                }
            }
            if (value.match(/csv/i)) {
                num = binfld.bin_counts.src_export_csv;
                max = AIR2.Bin.Exporter.MAX_CSV_SIZE;

                if (num > max && !isAdmin) {
                    return 'Bin exceeds the maximum allowed for an export to' +
                        ' CSV (' + max + ')';
                }
                if (num < 1) {
                    return 'You don\'t have authorization to CSV-export any ' +
                        'sources in this bin';
                }
            }
            if (value.match(/xls/i)) {
                num = binfld.bin_counts.subm_read;
                tot = binfld.bin_counts.subm_total;
                max = AIR2.Bin.Exporter.MAX_CSV_SIZE;

                if (num > max && !isAdmin) {
                    return 'Bin exceeds the maximum submissions allowed for ' +
                        'an export to XLS (' + max + ')';
                }
                if (tot < 1) {
                    return 'There aren\'t any submissions in this bin';
                }
                if (num < 1) {
                    return 'You don\'t have authorization to export any ' +
                        'submissions in this bin';
                }
            }
            return true;
        },
        listeners: {
            select: function (cb, rec) {
                var num;
                if (rec.id === 'lyris') {
                    num = binfld.bin_counts.src_export_lyris;
                }
                else {
                    num = binfld.bin_counts.src_export_csv;
                }
                if (num === binfld.bin_counts.src_total) {
                    countwarn.hide();
                }
                else {
                    countwarn.setValue(num + ' exportable sources');
                    countwarn.show();
                }
                if (rec.id === 'lyris') {
                    csvopt.hide();
                    csvopt2.hide();
                    if (cb.activeError) {
                        orgbox.disable();
                    }
                    else {
                        orgbox.enable();
                    }
                }
                else if (rec.id === 'csv') {
                    orgbox.disable().reset();
                    prjbox.disable().reset();
                    prjstrict.disable().reset();
                    inqbox.disable().reset();
                    inqstrict.disable().reset();
                    stricter.disable().reset();
                    csvopt.show();
                    csvopt2.show().setValue(num > 500);
                    csvopt2.setDisabled(num > 500);
                }
                else {
                    orgbox.disable().reset();
                    prjbox.disable().reset();
                    prjstrict.disable().reset();
                    inqbox.disable().reset();
                    inqstrict.disable().reset();
                    stricter.disable().reset();
                    csvopt.hide();
                    csvopt2.hide();
                }
            }
        }
    });

    // warning when not all sources are exportable
    countwarn = new Ext.form.DisplayField({
        ctCls: 'nospace',
        cls: 'air2-icon air2-icon-warning',
        style: 'padding-top:5px; background-position:0 bottom;',
        hidden: true
    });

    // csv export option box
    csvopt = new Ext.form.Checkbox({
        boxLabel: 'Include all mapped demographics',
        ctCls: 'nospace',
        checked: false,
        hidden: true
    });
    csvopt2 = new Ext.form.Checkbox({
        boxLabel: 'Email CSV file',
        ctCls: 'bborder nospace',
        checked: false,
        hidden: true
    });

    // organization picker (lyris-only)
    orgbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Organization',
        cls: 'air2-magnifier',
        ctCls: 'bborder',
        allowBlank: false,
        disabled: true,
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {
            status: 'AP',
            sort: 'org_display_name asc',
            role: 'W'
        },
        valueField: 'org_uuid',
        displayField: 'org_display_name',
        emptyText: 'Search Organizations (Writer role)',
        listEmptyText: '<div style="padding:4px 8px">No Organizations ' +
            'Found</div>',
        formatComboListItem: function (v) {
            return v.org_display_name;
        },
        listeners: {
            select: function (cb, rec) {
                prjbox.enable();
                prjstrict.enable();
            }
        }
    });

    // project picker (lyris-only)
    prjbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Project',
        cls: 'air2-magnifier',
        allowBlank: false,
        disabled: true,
        searchUrl: AIR2.HOMEURL + '/project',
        pageSize: 10,
        baseParams: {
            status: 'AP',
            sort: 'prj_display_name asc'
        },
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        emptyText: 'Search Projects',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        formatComboListItem: function (v) {
            return v.prj_display_name;
        },
        listeners: {
            select: function (cb, rec) {
                inqbox.enable();
                //inqstrict.enable(); -- FORCE STRICT!
                stricter.enable();
            },
            beforequery: function (opts) {
                if (prjstrict.getValue()) {
                    opts.combo.store.baseParams.org_uuid = orgbox.getValue();
                }
                else {
                    delete opts.combo.store.baseParams.org_uuid;
                }
            }
        }
    });
    prjstrict = new Ext.form.Checkbox({
        boxLabel: 'Restrict to Organization',
        ctCls: 'bborder',
        checked: true,
        disabled: true,
        listeners: {
            check: function () {
                prjbox.lastQuery = null; //force re-query
                prjbox.reset();
            }
        }
    });

    // inquiry picker (lyris-only)
    inqbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Query',
        cls: 'air2-magnifier',
        allowBlank: true, // allow export without inquiry
        disabled: true,
        searchUrl: AIR2.HOMEURL + '/inquiry',
        pageSize: 10,
        baseParams: {
            status: 'A',
            sort: 'inq_cre_dtim desc'
        },
        valueField: 'inq_uuid',
        displayField: 'inq_ext_title',
        emptyText: 'Search Queries',
        listEmptyText: '<div style="padding:4px 8px">No Queries Found</div>',
        formatComboListItem: function (v) {
            return v.inq_title;
        },
        listeners: {
            beforequery: function (opts) {
                if (inqstrict.getValue()) {
                    opts.combo.store.baseParams.prj_uuid = prjbox.getValue();
                }
                else {
                    delete opts.combo.store.baseParams.prj_uuid;
                }
            }
        }
    });

    inqstrict = new Ext.form.Checkbox({
        boxLabel: 'Restrict to Project',
        ctCls: 'bborder',
        checked: true,
        disabled: true, //ALWAYS STRICT!!!
        listeners: {
            check: function () {
                inqbox.lastQuery = null; //force re-query
                inqbox.reset();
            }
        }
    });

    // strict 24-hour checking
    stricter = new Ext.form.Checkbox({
        fieldLabel: 'Strict Checking',
        boxLabel: 'Don\'t send email to sources exported in last 24 hours',
        checked: true,
        disabled: true
    });

    // export-working display
    working = new Ext.form.DisplayField({
        cls: 'working',
        ctCls: 'tborder',
        html: '<b>Exporting...</b>'
    });

    // buttons
    exportbtn = new AIR2.UI.Button({
        air2type: 'BLUE',
        air2size: 'MEDIUM',
        text: 'Export',
        handler: function () {
            var binuuid, callback, f;

            f = w.get(0).getForm();
            if (f.isValid()) {
                // disable everything, and show the working text
                exportbtn.disable();
                closebtn.disable();
                f.items.each(function (item) { item.disable(); });
                w.get(0).add(working);
                w.get(0).doLayout();

                // export!
                binuuid = binfld.getValue();
                callback = function (success, msg) {
                    if (success) {
                        working.addClass('air2-icon-check');
                    }
                    else {
                        working.addClass('air2-icon-error');
                    }
                    working.setValue(msg);
                    exportbtn.hide();
                    closebtn.enable().setText('Close');
                };
                if (typebox.getValue() === 'csv') {
                    AIR2.Bin.Exporter.toCSV(
                        binuuid,
                        callback,
                        csvopt.getValue(),
                        csvopt2.getValue()
                    );
                }
                else if (typebox.getValue() === 'xls') {
                    AIR2.Bin.Exporter.toXLS(binuuid, callback);
                }
                else {
                    AIR2.Bin.Exporter.toLyris(
                        binuuid,
                        orgbox.getValue(),
                        prjbox.getValue(),
                        inqbox.getValue(),
                        stricter.getValue(),
                        callback
                    );
                }
            }
        }
    });

    closebtn = new AIR2.UI.Button({
        air2type: 'CANCEL',
        air2size: 'MEDIUM',
        text: 'Cancel',
        handler: function () {w.close(); }
    });

    // create window
    w = new AIR2.UI.Window({
        title: 'Export Bin',
        cls: 'air2-bin-exporter',
        iconCls: 'air2-icon-bin',
        closeAction: 'close',
        width: 380,
        height: 265,
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            labelWidth: 105,
            labelAlign: 'right',
            defaults: {
                width: 240,
                msgTarget: 'under'
            },
            items: [
                binfld,
                pswd,
                typebox,
                countwarn,
                csvopt,
                csvopt2,
                orgbox,
                prjbox,
                prjstrict,
                inqbox,
                inqstrict,
                stricter
            ],
            bbar: [exportbtn, ' ', closebtn]
        }
    });

    // show and return
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }

    return w;
};


/**
 * Export a bin as a CSV.  Since there's really nothing to do, just wait a bit
 * and then show the link
 *
 * @function AIR2.Bin.Exporter.toCSV
 * @cfg {String}    binuuid  (required)
 * @cfg {Function}  callback (required)
 * @cfg {Boolean}   allfacts (optional)
 */
AIR2.Bin.Exporter.toCSV = function (binuuid, callback, allfacts, email) {
    var loc, msg;
    loc = AIR2.HOMEURL + '/bin/' + binuuid + '/exportsource.csv';
    if (allfacts) {
        loc += '?allfacts=1';
    }

    // email or download
    if (email) {
        loc += allfacts ? '&email=1' : '?email=1';
        Ext.Ajax.request({
            url: loc,
            callback: function (opt, success, resp) {
                var msg = '';
                if (resp.status === 202) {
                    msg = 'The results of your CSV export will be emailed to ' +
                        'you shortly';
                    callback(true, msg);
                }
                else {
                    msg = 'There was a problem emailing your CSV file';
                    callback(false, msg);
                }
            }
        });

    }
    else {
        msg = '<a href="' + loc + '">Click to download CSV</a>';
        if (Ext.isIE) {
            msg = '<a href="' + loc +
                '" target="_blank">Click to download CSV</a>';
        }
        callback.defer(1000, this, [true, msg]);
    }
};


/**
 * cf Trac #1841
 */
AIR2.Bin.Exporter.MAX_LYRIS_SIZE = 5000;

/**
 * Similarly, Trac #4458
 */
AIR2.Bin.Exporter.MAX_CSV_SIZE = 2500;


/**
 * Schedule a Lyris export of a bin.
 *
 * @function AIR2.Bin.Exporter.toLyris
 * @cfg {String}    binuuid  (required)
 * @cfg {String}    orguuid  (required)
 * @cfg {String}    prjuuid  (required)
 * @cfg {String}    inquuid
 * @cfg {Boolean}   dostrict
 * @cfg {Function}  callback (required)
 */
AIR2.Bin.Exporter.toLyris = function (
        binuuid,
        orguuid,
        prjuuid,
        inquuid,
        dostrict,
        callback
    ) {

    if (!binuuid || !orguuid || !prjuuid) {
        alert("Invalid call to lyris exporter!");
        return;
    }

    // setup data
    var data = {
        se_type:      'L', //create lyris export
        org_uuid:     orguuid,
        prj_uuid:     prjuuid,
        strict_check: dostrict
        //dry_run:      true,
        //no_export:    true,
    };
    if (inquuid) {
        data.inq_uuid = inquuid;
    }

    // fire!
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/bin/' + binuuid + '/export.json',
        params: {radix: Ext.encode(data)},
        method: 'POST',
        callback: function (opts, success, resp) {
            var data, msg;
            data = Ext.util.JSON.decode(resp.responseText);
            if (success && data.success) {
                msg = 'Your Bin was scheduled for export. You should receive ' +
                    'email shortly.';
                callback(true, msg);
            }
            else {
                if (data && data.message) {
                    msg = data.message;
                }
                else {
                    msg = 'Unknown remote error';
                }
                msg += '<br/>Contact an administrator for help.';
                callback(false, msg);
            }
        }
    });
};


/**
 * Export submissions from a bin to an Excel spreadsheet.  The results will
 * be emailed to the user.
 *
 * @function AIR2.Bin.Exporter.toXLS
 * @cfg {String}    binuuid  (required)
 * @cfg {Function}  callback (required)
 */
AIR2.Bin.Exporter.toXLS = function (binuuid, callback) {
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/bin/' + binuuid + '/exportsub.json',
        method: 'POST',
        callback: function (opt, success, resp) {
            if (resp.status === 202) {
                callback(true, 'The results of your submission export will ' +
                    'be emailed to you shortly');
            }
            else {
                callback(false, 'There was a problem submissions export');
                Logger(resp);
            }
        }
    });
};
