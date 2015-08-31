Ext.ns('AIR2.Email.Exporter');

/**
 * Email sender/scheduler modal
 *
 * Show a dialog to send an email to a bin
 *
 * @function AIR2.Email.Exporter
 * @cfg {String}      email_uuid  (required)
 * @cfg {HTMLElement} originEl    (optional) origin element to animate from
 * @return {AIR2.UI.Window}
 */
AIR2.Email.Exporter = function (cfg) {
    if (!cfg.email_uuid || !cfg.email_uuid.length) {
        alert("INVALID email uuid for export");
        return false;
    }
    var emailfld, emailmsg, pswd, binfld, binmsg, stricter, datefld, timefld,
        schedule, scheduleTip, sendnow, working, exportbtn, closebtn, w;

    scheduleTip = AIR2.Util.Tipper.create('92462006');

    // email display field
    emailfld = new Ext.form.DisplayField({
        fieldLabel: 'Email',
        cls: 'email-display',
        ctCls: '',
        html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
        plugins: {
            init: function () {
                var msg;
                Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/email/' + cfg.email_uuid + '.json',
                    callback: function (opts, success, resp) {
                        var data, msg, maysend;
                        data = Ext.util.JSON.decode(resp.responseText) || {};

                        // display user_may_send validation results
                        if (!success || !data.authz || !data.authz.may_send) {
                            emailfld.el.enableDisplayMode().hide();
                            msg = data.message || 'An unknown error has occurred!';
                            emailfld.markInvalid(msg);
                            exportbtn.disable();
                        }
                        else {
                            emailfld.setValue('<b>' + data.radix.email_campaign_name + '</b>');
                            maysend = data.authz.may_send;
                            if (maysend.success) {
                                if (maysend.warning_count > 0) {
                                    msg  = 'Warning:';
                                    Ext.each(maysend.tests, function(line) {
                                        if (line[1] == -1) msg += ' ' + line[0];
                                    });
                                    emailmsg.setMsg(msg, false);
                                }
                                else {
                                    emailmsg.setMsg('Validation Passed', true);
                                }
                                pswd.enable();
                                pswd.focus();
                            }
                            else {
                                msg  = 'Not ready to send:';
                                Ext.each(maysend.tests, function(line) {
                                    if (!line[1]) msg += '<br/>* ' + line[0];
                                });
                                emailfld.markInvalid(msg);
                                exportbtn.disable();
                            }
                        }
                    }
                });
            }
        },
        getValue: function () {
            return cfg.email_uuid;
        }
    });

    // email is valid indicator
    emailmsg = new Ext.form.DisplayField({
        ctCls: 'nospace bborder',
        cls: 'air2-icon air2-icon-check',
        style: 'padding-top:5px; background-position:0 bottom; display:none;',
        setMsg: function (msg, check) {
            this.setValue(msg);
            this.el.removeClass(check ? 'air2-icon-warning' : 'air2-icon-check');
            this.el.addClass(check ? 'air2-icon-check' : 'air2-icon-warning');
            this.el.show();
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
                binfld.disable();
                stricter.disable();
                sendnow.disable();
            },
            valid: function (fld) {
                fld.removeClass('air2-lock');
                fld.addClass('air2-okay');
                if (fld.getValue().length) {
                    binfld.enable();
                    stricter.enable();
                    sendnow.enable();
                    binfld.focus();
                }
            }
        }
    });

    // bin picker
    binfld = new AIR2.UI.SearchBox({
        fieldLabel: 'Export Bin',
        cls: 'air2-magnifier',
        ctCls: '',
        allowBlank: false,
        disabled: true,
        searchUrl: AIR2.HOMEURL + '/bin',
        pageSize: 10,
        baseParams: {
            //owner: true,
            status: 'AP',
            sort: 'bin_upd_dtim desc',
        },
        valueField: 'bin_uuid',
        displayField: 'bin_name',
        emptyText: 'Search Bins',
        listEmptyText: '<div style="padding:4px 8px">No Bins Found</div>',
        formatComboListItem: function (v) {
            var lbl = (v.src_count == 1) ? ' Source' : ' Sources';
            return v.bin_name + ' <span class="lighter">(' + v.src_count + lbl + ')</span>';
        },
        // bins must be remotely validated
        onRender: function (ct, position) {
            AIR2.UI.SearchBox.superclass.onRender.call(this, ct, position);
            this.remoteAction = ct.createChild({cls: 'air2-form-remote-wait'});
        },
        unsetActiveError: function (suppressEvent) {
            delete this.activeError;
            if (!this.preventMark) {
                this.fireEvent('valid', this);
            }
        },
        validator: function (value) {
            if (!this.selectedRecord) return;
            value = this.selectedRecord.id;
            if (value && value !== this.lastValue) {
                this.preventMark = true; //don't mark until callback
                this.lastValue = value;
                this.remoteIsValid = false;
                this.doRemoteValidation(value);
            }
            return (this.remoteIsValid) ? true : this.remoteMsg;
        },
        doRemoteValidation: function (value) {
            binmsg.setCounts(false);
            this.remoteAction.alignTo(this.el, 'tr-tr', [0, 2]);
            this.remoteAction.show();
            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/bin/' + value + '.json?email_uuid=' + cfg.email_uuid,
                callback: this.remoteCallback.createDelegate(this)
            });
        },
        remoteCallback: function (opts, success, resp) {
            var data, num;

            this.remoteAction.hide();
            data = Ext.util.JSON.decode(resp.responseText);
            num = (data && data.radix) ? data.radix.counts.src_export_mailchimp : 0;
            if (success && data.success && num > 0) {
                this.remoteIsValid = true;
                this.remoteMsg = '';
                binmsg.setCounts(data.radix.counts);
            }
            else {
                this.remoteIsValid = false;
                this.remoteMsg = data.message || 'Error: Invalid Bin!';
                if (data && data.radix && num < 1) {
                    this.remoteMsg = 'No exportable sources in Bin!';
                }
                binmsg.setCounts(false);
            }
            this.preventMark = false; // now allow marking
            this.validate(); // refire the validation
        }
    });

    // show number exportable in bin
    binmsg = new Ext.form.DisplayField({
        ctCls: 'nospace',
        cls: 'air2-icon air2-icon-check',
        style: 'padding-top:5px; background-position:0 bottom; display:none;',
        hide: true,
        setCounts: function (counts) {
            var exp, tot;

            if (counts) {
                exp = Ext.util.Format.number(counts.src_export_mailchimp, '0,000');
                tot = Ext.util.Format.number(counts.src_total, '0,000');
                if (counts.src_export_mailchimp == counts.src_total) {
                    this.el.removeClass('air2-icon-warning').addClass('air2-icon-check');
                    this.setValue(exp + ' exportable sources');
                }
                else {
                    this.el.removeClass('air2-icon-check').addClass('air2-icon-warning');
                    this.setValue(exp + ' exportable sources (of ' + tot + ')');
                }
                this.el.show();
            }
            else {
                this.el.enableDisplayMode().hide();
            }
        }
    });

    // strict 24-hour checking
    stricter = new Ext.form.Checkbox({
        fieldLabel: 'Strict Checking',
        boxLabel: 'Don\'t send to sources exported in last 24 hours',
        checked: true,
        disabled: true
    });

    // scheduling
    datefld = new Ext.form.DateField({
        fieldLabel: 'Date',
        allowBlank: false,
        width: 100,
        disabled: true
    });
    timefld = new Ext.form.TimeField({
        fieldLabel: 'Time',
        allowBlank: false,
        width: 100,
        disabled: true
    });
    schedule = new Ext.form.CompositeField({
        fieldLabel: 'Schedule  ' + scheduleTip,
        items: [datefld, timefld],
        onFieldMarkInvalid: function(fld, msg) {
            this.fieldErrors.replace(fld, {field: fld.fieldLabel, error: msg});
            fld.el.addClass(fld.invalidClass);
        }
    });
    sendnow = new Ext.form.Checkbox({
        fieldLabel: '',
        boxLabel: 'Send Now',
        ctCls: 'nospace',
        checked: true,
        disabled: true,
        listeners: {
            check: function (cb, checked) {
                datefld.setDisabled(checked);
                timefld.setDisabled(checked);
                if (checked) {
                    datefld.clearInvalid();
                    timefld.clearInvalid();
                    schedule.clearInvalid();
                }
                else {
                    var d = new Date();
                    datefld.setValue(d.add(Date.DAY, 1));
                    timefld.setValue(d);
                    datefld.focus();
                }
            }
        }
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
        text: 'Send',
        handler: function () {
            var callback, f, timestamp;

            f = w.get(0).getForm();
            if (f.isValid()) {
                // disable everything, and show the working text
                exportbtn.disable();
                closebtn.disable();
                f.items.each(function (item) { item.disable(); });
                w.get(0).add(working);
                w.get(0).doLayout();

                // manually compile the date
                if (!sendnow.getValue()) {
                    timestamp = datefld.getValue().format('Y-m-d');
                    var timeDate = Date.parseDate(timefld.getValue(), timefld.format);
                    timestamp += timeDate.format('TH:i:s');
                    timestamp += timeDate.getGMTOffset(); // make sure we include timezone.
                }

                // callback function
                callback = function (success, msg) {
                    working.addClass(success ? 'air2-icon-check' : 'air2-icon-error');
                    working.setValue(msg);
                    exportbtn.hide();
                    closebtn.enable().setText('Close');
                };

                // export!
                AIR2.Bin.Exporter.toMailchimp(
                    emailfld.getValue(),
                    binfld.getValue(),
                    stricter.getValue(),
                    timestamp,
                    callback
                );
            }
        }
    });
    closebtn = new AIR2.UI.Button({
        air2type: 'CANCEL',
        air2size: 'MEDIUM',
        text: 'Cancel',
        handler: function () { w.close(); }
    });

    // create window
    w = new AIR2.UI.Window({
        title: 'Send Email',
        cls: 'air2-email-exporter',
        iconCls: 'air2-icon-email',
        closeAction: 'close',
        width: 430,
        height: 265,
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            labelWidth: 105,
            labelAlign: 'right',
            defaults: {
                width: 300,
                msgTarget: 'under'
            },
            items: [emailfld, emailmsg, pswd, binfld, binmsg, stricter,
                schedule, sendnow],
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
