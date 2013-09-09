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
        exportbtn,
        formItems,
        isAdmin,
        pswd,
        typebox,
        typechoices,
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
    typechoices = [
        ['csv', 'Sources to CSV File'],
        ['xls', 'Submissions to XLSX File'],
        ['lyris', 'Emails to Lyris']
    ];
    if (AIR2.Util.Authz.has('ACTION_EMAIL_CREATE')) {
        //typechoices.push(['mailchimp', 'Emails to Mailchimp']);
    }
    typebox = new AIR2.UI.ComboBox({
        fieldLabel: 'Export Type',
        emptyText: 'Select an output...',
        choices: typechoices,
        allowBlank: false,
        disabled: true,
        ctCls: 'bborder',
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
            if (value.match(/mailchimp/i)) {
                num = binfld.bin_counts.src_export_lyris;
                own = binfld.getOwner();
                max = AIR2.Bin.Exporter.MAX_LYRIS_SIZE;
                if (num > max && !isAdmin) {
                    return 'Bin exceeds the maximum allowed for an export' +
                        ' to Mailchimp (' + max + ')';
                }
                if (!own && !isAdmin) {
                    return 'Only the owner of a Bin may export to Mailchimp';
                }
                if (num < 1) {
                    return 'You don\'t have authorization to Mailchimp-export ' +
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
                var num, hideFields, showFields, form, afterGenericFields;

                // helpers to show/hide fields
                hideFields = function() {
                    Ext.each(arguments, function(fld) {
                        fld.disable().reset();
                        fld.itemCt.setDisplayed('none');
                    });
                }
                showFields = function() {
                    Ext.each(arguments, function(fld) {
                        fld.show();
                        fld.itemCt.setDisplayed(true);
                    });
                }

                // export count warning
                if (rec.id === 'lyris') {
                    num = binfld.bin_counts.src_export_lyris;
                }
                else if (rec.id === 'mailchimp') {
                    num = binfld.bin_counts.src_export_mailchimp;
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

                // remove export-specific fields
                form = Ext.getCmp('bin-exporter-form');
                afterGenericFields = false;
                form.items.each(function (fld) {
                    if (afterGenericFields) {
                        form.remove(fld);
                    }
                    else if (fld == countwarn) {
                        afterGenericFields = true;
                    }
                });

                // add other export-specific fields
                form.add(AIR2.Bin.Exporter.Fields[rec.id](num, cb.activeError));
                form.doLayout();
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
            var binuuid, callback, f, values;

            f = w.get(0).getForm();
            values = f.getFieldValues();
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
                        values.csvopt,
                        values.csvopt2
                    );
                }
                else if (typebox.getValue() === 'xls') {
                    AIR2.Bin.Exporter.toXLS(binuuid, callback);
                }
                else if (typebox.getValue() === 'mailchimp') {
                    AIR2.Bin.Exporter.toMailchimp(
                        values.email_uuid,
                        binuuid,
                        values.strict,
                        values.timestamp,
                        callback
                    );
                }
                else {
                    AIR2.Bin.Exporter.toLyris(
                        binuuid,
                        values.org_uuid,
                        values.prj_uuid,
                        values.inq_uuid,
                        values.strict,
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

    // initial form items
    formItems = [binfld, pswd, typebox, countwarn];
    formItems.concat(AIR2.Bin.Exporter.Fields.csv(0, true));

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
            id: 'bin-exporter-form',
            xtype: 'form',
            unstyled: true,
            labelWidth: 105,
            labelAlign: 'right',
            defaults: {
                width: 240,
                msgTarget: 'under'
            },
            items: formItems,
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
