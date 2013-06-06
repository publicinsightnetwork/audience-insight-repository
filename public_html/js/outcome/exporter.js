Ext.ns('AIR2.Outcome.Exporter');

/**
 * Outcome-export modal window
 *
 * Show a dialog to export outcomes to CSV
 *
 * @function AIR2.Outcome.Exporter
 * @cfg {Boolean}     require_org
 * @cfg {String}      org_uuid
 * @cfg {String}      prj_uuid
 * @cfg {String}      inq_uuid
 * @cfg {String}      start_date
 * @cfg {String}      end_date
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @return {AIR2.UI.Window}
 */
AIR2.Outcome.Exporter = function (cfg) {
    var buildOpts,
        closebtn,
        countdisp,
        countOnBlank,
        dateend,
        dates,
        datestart,
        emailopt,
        exportbtn,
        inqbox,
        normopt,
        orgbox,
        prjbox,
        pswd,
        rowsopt,
        sourceopt,
        w,
        working;

    // password validation field
    pswd = new Ext.form.TextField({
        fieldLabel: 'Verify Password',
        inputType: 'password',
        cls: 'air2-lock',
        allowBlank: false,
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
            },
            valid: function (fld) {
                fld.removeClass('air2-lock');
                fld.addClass('air2-okay');
            }
        }
    });

    // organization picker (optional)
    orgbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Organization',
        cls: 'air2-magnifier',
        allowBlank: !cfg.require_org,
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {sort: 'org_display_name asc', role: 'W'},
        valueField: 'org_uuid',
        displayField: 'org_display_name',
        emptyText: 'Search Organizations',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Organizations Found' +
            '</div>',
        formatComboListItem: function (v) {
            return v.org_display_name;
        }
    });

    // project picker (optional)
    prjbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Project',
        cls: 'air2-magnifier',
        allowBlank: true,
        searchUrl: AIR2.HOMEURL + '/project',
        pageSize: 10,
        baseParams: {sort: 'prj_display_name asc'},
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        emptyText: 'Search Projects',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        formatComboListItem: function (v) {
            return v.prj_display_name;
        }
    });

    // inquiry picker (optional)
    inqbox = new AIR2.UI.SearchBox({
        fieldLabel: 'Query',
        cls: 'air2-magnifier',
        allowBlank: true,
        searchUrl: AIR2.HOMEURL + '/inquiry',
        pageSize: 10,
        baseParams: {sort: 'inq_ext_title asc'},
        valueField: 'inq_uuid',
        displayField: 'inq_ext_title',
        emptyText: 'Search Queries',
        listEmptyText: '<div style="padding:4px 8px">No Queries Found</div>',
        formatComboListItem: function (v) {
            return v.inq_ext_title;
        }
    });

    // date range (optional)
    datestart = new Ext.form.DateField({name: 'Start'});
    dateend = new Ext.form.DateField({name: 'End'});
    dates = new Ext.form.CompositeField({
        fieldLabel: 'Date Range',
        items: [
            datestart,
            {xtype: 'box', style: 'line-height:22px', html: ' to '},
            dateend
        ]
    });

    // options
    emailopt = new Ext.form.Checkbox({
        boxLabel: 'Email results to me',
        ctCls: 'nospace',
        checked: true,
        disabled: true
    });

    normopt = new Ext.form.Radio({
        name: 'rowopts',
        boxLabel: 'One row per PINfluence entry',
        checked: true,
        style: 'margin-left:2px'
    });

    sourceopt = new Ext.form.Radio({
        name: 'rowopts',
        boxLabel: 'One row per source',
        ctCls: 'nospace',
        style: 'margin-left:2px'
    });

    rowsopt = new Ext.form.RadioGroup({
        columns: 1,
        items: [normopt, sourceopt]
    });

    // helper to build current options-array
    buildOpts = function () {
        var opts = {};
        if (orgbox.getValue()) {
            opts.org_uuid = orgbox.getValue();
        }
        if (prjbox.getValue()) {
            opts.prj_uuid = prjbox.getValue();
        }
        if (inqbox.getValue()) {
            opts.inq_uuid = inqbox.getValue();
        }
        if (datestart.getValue()) {
            opts.start_date = datestart.getValue();
        }
        if (dateend.getValue()) {
            opts.end_date = dateend.getValue();
        }
        if (emailopt.getValue()) {
            opts.email = true;
        }
        if (sourceopt.getValue()) {
            opts.sources = true;
        }

        return opts;
    };

    // count number to-be-exported
    countdisp = new Ext.form.DisplayField({
        html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
        style: 'padding-bottom: 3px',
        calculate: function () {
            var opts = buildOpts();
            opts.count = 1;
            delete opts.email;
            delete opts.sources;

            // only query if changed
            if (Ext.encode(opts) !== Ext.encode(countdisp.opts)) {
                if (countdisp.remoteId) {
                    Ext.Ajax.abort(countdisp.remoteId);
                }
                countdisp.setValue(countdisp.initialConfig.html);
                countdisp.opts = opts;

                countdisp.remoteId = Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/outcomeexport.json',
                    method: 'GET',
                    params: opts,
                    success: function (resp, opts) {
                        var data, val;

                        countdisp.remoteId = null;
                        data = Ext.decode(resp.responseText);
                        val = '<b>Unable to count matches</b>';
                        if (
                            data &&
                            data.meta &&
                            Ext.isDefined(data.meta.total)
                        ) {
                            val = '<b>' + data.meta.total +
                                ' matching PINfluence(s)</b>';
                        }
                        countdisp.setValue(val);
                    },
                    failure: function () {
                        countdisp.setValue('<b>Unable to count matches</b>');
                    }
                });
            }
        }
    });
    countOnBlank = function (val) {
        if (val === '' || val === null) {
            countdisp.calculate();
        }

        return true;
    };

    // recount events
    countdisp.calculate();
    orgbox.on('select', countdisp.calculate);
    orgbox.validator = countOnBlank;
    prjbox.on('select', countdisp.calculate);
    prjbox.validator = countOnBlank;
    inqbox.on('select', countdisp.calculate);
    inqbox.validator = countOnBlank;
    datestart.on('select', countdisp.calculate);
    dateend.on('select', countdisp.calculate);
    datestart.validator = countOnBlank;
    dateend.validator = countOnBlank;

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
        text: 'Generate',
        handler: function () {
            var callback, f;

            f = w.get(0).getForm();
            if (f.isValid()) {
                // disable everything, and show the working text
                exportbtn.disable();
                closebtn.disable();
                f.items.each(function (item) { item.disable(); });
                w.get(0).add(working);
                w.get(0).doLayout();

                // export!
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
                AIR2.Outcome.Exporter.toCSV(callback, buildOpts());
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
        title: 'Export PINfluence report',
        cls: 'air2-bin-exporter',
        iconCls: 'air2-icon-outcome',
        closeAction: 'close',
        width: 380,
        height: 265,
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            labelWidth: 105,
            labelAlign: 'right',
            defaults: {width: 240, msgTarget: 'under'},
            items: [pswd, {
                xtype: 'fieldset',
                title: 'Optional Filters',
                width: 360,
                bodyStyle: 'margin-left:-11px',
                defaults: {width: 228, msgTarget: 'under'},
                items: [orgbox, prjbox, inqbox, dates]
            }, countdisp, emailopt, rowsopt],
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
 * Export an outcome as a CSV.
 *
 * @function AIR2.Outcome.Exporter.toCSV
 * @cfg {Function}  callback (required)
 * @cfg {Boolean}   allfacts (optional)
 */
AIR2.Outcome.Exporter.toCSV = function (callback, params) {
    var first, loc, msg;

    // email or download
    if (params.email) {
        Ext.Ajax.request({
            method: 'GET',
            params: params,
            url: AIR2.HOMEURL + '/outcomeexport.csv',
            callback: function (opt, success, resp) {
                if (resp.status === 202) {
                    callback(
                        true,
                        'The results of your CSV export will be emailed to ' +
                        'you shortly'
                    );
                }
                else {
                    callback(
                        false,
                        'There was a problem emailing your CSV file'
                    );
                }
            }
        });

    }
    else {
        // TODO: get this to work correctly
        loc = AIR2.HOMEURL + '/outcomeexport.csv';
        first = false;
        Ext.iterate(params, function (key, val) {
            if (!first) {
                first = true;
                loc += '?' + key + '=' + val;
            }
            else {
                loc += '&' + key + '=' + val;
            }
        });
        msg = '<a href="' + loc + '">Click to download CSV</a>';
        if (Ext.isIE) {
            msg = '<a href="' + loc + '" target="_blank">' +
                'Click to download CSV' +
            '</a>';
        }
        callback.defer(1000, this, [true, msg]);
    }
};
