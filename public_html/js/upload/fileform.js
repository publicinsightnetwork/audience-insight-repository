Ext.ns('AIR2.Upload');
/***************
 * AIR2 Upload Form Component
 *
 * FormPanel used to upload a csv file to AIR2
 *
 * @event fileselected(<FileField>, <filename>)
 *
 */
AIR2.Upload.FileForm = function () {
    var masterTpl,
        panel,
        progress,
        simpleTpl,
        status,
        submTpl,
        upfield;

    masterTpl = AIR2.HOMEURL + '/files/csv/upload-template-full.xlt';
    simpleTpl = AIR2.HOMEURL + '/files/csv/upload-template-basic.xlt';
    submTpl   = AIR2.HOMEURL + '/files/csv/upload-template-submission.xlt';

    upfield = new Ext.ux.form.FileUploadField({
        cls: 'upload-file',
        name: 'csvfile',
        hideLabel: true,
        buttonOnly: true,
        buttonCfg: {
            xtype: 'air2button',
            air2type: 'DRAWER',
            air2size: 'MEDIUM',
            text: 'Choose a File'
        },
        setTank: function (rec) {
            if (!upfield.rendered) {
                upfield.on('render', function () {
                    upfield.setTank(rec);
                }, this, {single: true});
            }
            else {
                if (rec) {
                    upfield.enable();
                }
                else {
                    var stat = rec.data.tank_status;
                    upfield.setDisabled(stat !== 'N');
                }
            }
        }
    });
    status = new Ext.BoxComponent({
        cls: 'upload-status',
        html: 'no file chosen',
        setTank: function (rec) {
            var f, stat;

            stat = rec ? rec.data.tank_status : null;
            if (!stat) {
                status.setMsg('no file chosen', true);
            }
            else if (stat === 'N') {
                f = rec.data.tank_name;
                status.setMsg('Retry file "' + f + '"', true);
            }
            else {
                status.setMsg(rec.data.tank_name);
            }
        },
        setMsg: function (str, isWarn) {
            if (!status.rendered) {
                status.on('afterrender', function () {
                    status.setMsg(str, isWarn);
                }, this, {single: true});
            }
            else {
                if (isWarn) {
                    status.addClass('warning');
                }
                else {
                    status.removeClass('warning');
                }
                status.update(str);
            }
        }
    });
    progress = new Ext.ProgressBar({
        cls: 'upload-progress',
        animate: true,
        hidden: true
    });

    // setup panel
    panel = new Ext.form.FormPanel({
        cls: 'upload-form',
        unstyled: true,
        fileUpload: true,
        uploadUrl: AIR2.HOMEURL + '/csv.json',
        uploadMethod: 'POST',
        items: [{
            /* allows ajax-ish file-upload */
            xtype: 'hidden',
            name: 'x-force-content',
            value: 'text/html'
        }, {
            /* allows REST-ful PUT for re-upload */
            xtype: 'hidden',
            name: 'x-tunneled-method',
            value: 'POST'
        }, {
            xtype: 'container',
            cls: 'upload-wrap',
            layout: 'table',
            layoutConfig: { columns: 3 },
            items: [
                upfield,
                status,
                progress
            ]
        }, {
            xtype: 'box',
            cls: 'upload-wrap help',
            html: 'For formatting help, use the ' +
                '<a href="' + masterTpl + '">Master CSV Template</a>' +
                ' or the ' +
                '<a href="' + simpleTpl + '">Simple CSV Template</a>' +
                ' or ' +
                '<a href="' + submTpl + '">Upload Submissions</a>'
        }],
        doUpload: function (callback) {
            progress.show().wait();
            if (Ext.isSafari) {
                // TODO!!!!!!!
                Ext.Ajax.request({ url: AIR2.HOMEURL + "/upload/close" });
            }

            // submit the form
            panel.getForm().submit({
                url: panel.uploadUrl,
                success: function (f, o) {
                    progress.reset(true);

                    // create new record
                    var store = new AIR2.UI.APIStore({
                        url: AIR2.HOMEURL + '/csv.json',
                        autoSave: false,
                        autoLoad: false
                    });
                    store.loadData(o.result);
                    panel.ownerCt.tankRec = store.getAt(0);

                    // callback
                    if (callback) {
                        callback(true);
                    }

                    // unset field value, so onChange will fire next time
                    upfield.lastSelected = upfield.getValue();
                    upfield.fileInput.dom.value = '';
                },
                failure: function (f, o) {
                    progress.reset(true);
                    if (callback) {
                        callback(false);
                    }
                    status.setMsg(o.result.message, true);

                    // unset field value, so onChange will fire next time
                    upfield.fileInput.dom.value = '';
                }
            });
        }
    });

    panel.on('beforeshow', function () {
        panel.tankRec = panel.ownerCt.tankRec;
        status.setTank(panel.tankRec);
        if (panel.tankRec) {
            var uuid = panel.tankRec.data.tank_uuid;
            panel.uploadUrl = AIR2.HOMEURL + '/csv/' + uuid + '.json';
            panel.getForm().setValues({'x-tunneled-method': 'PUT'});
        }
    });

    upfield.on('fileselected', function (fld, name) {
        if (name) {
            status.removeClass('warning');
            status.update(name);
        }
        else {
            // user cancelled --- set to last value
            upfield.setValue(upfield.lastSelected);
        }
        panel.fireEvent('fileselected', fld, name);
    });

    return panel;
};
