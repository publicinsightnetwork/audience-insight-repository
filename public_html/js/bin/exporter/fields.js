Ext.ns('AIR2.Bin.Exporter.Fields');

/**
 * CSV export
 */
AIR2.Bin.Exporter.Fields.csv = function (num, err) {
    var csvopt, csvopt2;

    // csv export option box
    csvopt = new Ext.form.Checkbox({
        boxLabel: 'Include all mapped demographics',
        name: 'csvopt',
        ctCls: 'nospace',
        checked: false,
        disabled: err ? true : false
    });
    csvopt2 = new Ext.form.Checkbox({
        boxLabel: 'Email CSV file',
        name: 'csvopt2',
        ctCls: 'nospace',
        checked: (num > 500),
        disabled: err ? true : (num > 500)
    });

    return [csvopt, csvopt2];
}

/**
 * XLS export
 */
AIR2.Bin.Exporter.Fields.xls = function (num, err) {
    return [];
}

/**
 * Mailchimp export
 */
AIR2.Bin.Exporter.Fields.mailchimp = function (num, err) {
    var emailbox, emailmsg, stricter, datefld, timefld, schedule, sendnow;

    // email picker
    emailbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Email',
        name: 'email_uuid',
        cls: 'air2-magnifier',
        allowBlank: false,
        disabled: err ? true : false,
        searchUrl: AIR2.HOMEURL + '/email',
        pageSize: 10,
        baseParams: {
            status: 'D',
            mine: true,
            sort: 'email_campaign_name asc'
        },
        valueField: 'email_uuid',
        displayField: 'email_campaign_name',
        emptyText: 'Search Emails',
        listEmptyText: '<div style="padding:4px 8px">No Emails Found</div>',
        formatComboListItem: function (v) {
            return v.email_campaign_name;
        },
        // remotely validate an email's exportability
        doRemoteValidation: function (uuid) {
            // abort any previous requests
            if (this.ajaxId) {
                Ext.Ajax.abort(this.ajaxId);
                this.ajaxId = false;
            }

            // don't try to remote-validate a blank value
            if (uuid === '') {
                this.remoteIsValid = true;
                this.remoteMsg = '';
                this.preventMark = false; // now allow marking
                this.validate(); // refire the validation
                return;
            }

            // fire the remote request
            emailmsg.setMsg(false);
            this.ajaxId = Ext.Ajax.request({
                url: AIR2.HOMEURL + '/email/' + uuid + '.json',
                scope: this,
                callback: function (opts, success, resp) {
                    var data, msg, maysend;
                    data = Ext.util.JSON.decode(resp.responseText) || {};

                    // display user_may_send validation results
                    if (!success || !data.authz || !data.authz.may_send) {
                        this.remoteIsValid = false;
                        this.remoteMsg = data.message || 'An unknown error has occurred!';
                    }
                    else {
                        maysend = data.authz.may_send;
                        if (!maysend.success) {
                            msg = 'Not ready to send:';
                            Ext.each(maysend.tests, function(line) {
                                if (!line[1]) msg += '<br/>* ' + line[0];
                            });
                            this.remoteIsValid = false;
                            this.remoteMsg = msg;
                        }
                        else {
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
                            this.remoteIsValid = true;
                            this.remoteMsg = '';
                        }
                    }
                    this.ajaxId = false;
                    this.preventMark = false; // now allow marking
                    this.validate(); // refire the validation
                }
            });
        },
        // remote validation
        validator: function (value) {
            if (!this.selectedRecord) return;
            value = this.selectedRecord.id;
            var original = this.originalValue;
            if (!Ext.isDefined(original) && value.length > 0) {
                this.originalValue = value;
                original = value;
            }
            if (value === original) {
                return true;
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
        listeners: {
            select: function (cb, rec) {
                stricter.enable();
                sendnow.enable();
            }
        }
    });

    // email is valid indicator
    emailmsg = new Ext.form.DisplayField({
        ctCls: 'nospace',
        cls: 'air2-icon air2-icon-check',
        style: 'padding-top:5px; background-position:0 bottom; display:none;',
        setMsg: function (msg, check) {
            if (msg) {
                this.setValue(msg);
                this.el.removeClass(check ? 'air2-icon-warning' : 'air2-icon-check');
                this.el.addClass(check ? 'air2-icon-check' : 'air2-icon-warning');
                this.el.show();
            }
            else {
                this.el.hide();
            }
        }
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
        fieldLabel: 'Schedule',
        name: 'timestamp',
        items: [datefld, timefld],
        onFieldMarkInvalid: function(fld, msg) {
            this.fieldErrors.replace(fld, {field: fld.fieldLabel, error: msg});
            fld.el.addClass(fld.invalidClass);
        },
        getValue: function () {
            if (sendnow.getValue()) {
                return null;
            }
            else {
                var timestamp = datefld.getValue().format('Y-m-d');
                timestamp += Date.parseDate(timefld.getValue(),
                    timefld.format).format(' H:i:s');
                return timestamp;
            }
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

    // strict 24-hour checking
    stricter = new Ext.form.Checkbox({
        fieldLabel: 'Strict Checking',
        boxLabel: 'Don\'t send email to sources exported in last 24 hours',
        name: 'strict',
        checked: true,
        disabled: true
    });

    return [emailbox, emailmsg, schedule, sendnow, stricter];
}

