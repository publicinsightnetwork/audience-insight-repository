/***************
 * Upload Importer Window
 *
 * Button to start importing a CSV into the tank, and feedback fields
 *
 * @event validpoll(<isvalid>)
 */
Ext.ns('AIR2.Upload');
AIR2.Upload.Importer = function () {
    var dtimfield,
        evdir,
        evfield,
        evtype,
        formpanel,
        notesfield,
        orgfield,
        panel,
        prjfield,
        status;

    status = new Ext.BoxComponent({
        cls: 'upload-status',
        hideMode: 'visibility',
        hidden: true,
        setMsg: function (str, isWarn, isWork, isSucc) {
            if (!status.rendered) {
                status.on('afterrender', function () {
                    status.setMsg(str, isWarn, isWork, isSucc);
                }, this, {single: true});
            }
            else {
                if (!isWarn) {
                    status.removeClass('warning');
                }
                if (!isWork) {
                    status.removeClass('working');
                }
                if (!isSucc) {
                    status.removeClass('success');
                }
                if (isWarn) {
                    status.addClass('warning');
                }
                if (isWork) {
                    status.addClass('working');
                }
                if (isSucc) {
                    status.addClass('success');
                }
                status.update(str);
                status.show();
            }
        }
    });

    // organization chooser, restricted to WRITER role
    orgfield = new AIR2.UI.SearchBox({
        width: 206,
        cls: 'air2-magnifier',
        fieldLabel: 'Organization',
        searchUrl: AIR2.HOMEURL + '/organization',
        pageSize: 10,
        baseParams: {sort: 'org_display_name asc', role: 'W'},
        valueField: 'org_uuid',
        displayField: 'org_display_name',
        emptyText: 'Search Organizations (Writer role)',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Organizations Found' +
            '</div>',
        allowBlank: false,
        msgTarget: 'side',
        formatComboListItem: function (values) {
            return values.org_display_name;
        }
    });

    // project chooser
    prjfield = new AIR2.UI.SearchBox({
        width: 206,
        cls: 'air2-magnifier',
        fieldLabel: 'Project',
        searchUrl: AIR2.HOMEURL + '/project',
        valueField: 'prj_uuid',
        pageSize: 10,
        displayField: 'prj_display_name',
        emptyText: 'Search Projects',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        allowBlank: false,
        msgTarget: 'side',
        formatComboListItem: function (v) {
            return v.prj_display_name;
        },
        setOrg: function (uuid) {
            prjfield.store.baseParams.org_uuid = uuid;
            prjfield.store.reload();
        }
    });
    orgfield.on('valid', function () {
        if (!orgfield.disabled) {
            prjfield.enable();
        }
    });
    orgfield.on('invalid', function () {
        prjfield.disable();
    });
    orgfield.on('select', function () {
        if (orgfield.getValue() !== orgfield.startValue) {
            prjfield.clearValue();
            prjfield.setOrg(orgfield.getValue());
        }
    });

    // activity choosers
    evtype = new AIR2.UI.ComboBox({
        name: 'evtype',
        value: 'E',
        choices: [
            ['E', 'Email'],
            ['P', 'Phone Call'],
            ['T', 'Text Message'],
            ['I', 'In-person Action'],
            ['O', 'Online Action']
        ],
        flex: 1,
        listeners: {
            select: function (cb, rec) {
                if (rec.data.value === 'I' || rec.data.value === 'O') {
                    evdir.setValue('I').disable();
                }
                else {
                    evdir.enable();
                }
            }
        }
    });
    evdir = new AIR2.UI.ComboBox({
        name: 'evdir',
        value: 'I',
        choices: [['I', 'Incoming'], ['O', 'Outgoing']],
        width: 82
    });
    evfield = new Ext.form.CompositeField({
        fieldLabel: 'Event Type',
        items: [evtype, evdir]
    });
    dtimfield = new Ext.form.DateField({
        fieldLabel: 'Event Date',
        allowBlank: false,
        msgTarget: 'side'
    });
    notesfield = new Ext.form.TextArea({
        hideLabel: true,
        width: 280,
        allowBlank: false,
        emptyText: 'Description of the event',
        msgTarget: 'side'
    });

    formpanel = new Ext.form.FormPanel({
        unstyled: true,
        layout: 'table',
        layoutConfig: { columns: 2 },
        items: [{
            xtype: 'container',
            layout: 'form',
            labelWidth: 75,
            items: [orgfield, prjfield, evfield, dtimfield]
        }, {
            xtype: 'container',
            layout: 'form',
            items: [notesfield]
        }],
        disableAll: function () {
            orgfield.disable();
            prjfield.disable();
            evfield.disable();
            dtimfield.disable();
            notesfield.disable();
        }
    });

    panel = new Ext.Container({
        cls: 'upload-import',
        unstyled: true,
        items: [status, formpanel],
        doSubmit: function (callback) {
            var prjuuid,
                orguuid,
                rec,
                uuid;

            formpanel.stopMonitoring();
            delete panel.validState;
            status.setMsg('Working...', false, true);

            // clear exception listeners
            rec = panel.ownerCt.tankRec;
            if (rec.store.events.exception) {
                rec.store.events.exception.clearListeners();
            }
            rec.store.on(
                'exception',
                function (proxy, type, action, opt, rsp, arg) {
                    var json, msg;

                    json = Ext.decode(rsp.responseText);
                    if (json && json.message) {
                        msg = json.message;
                    }
                    else {
                        msg = 'An unknown error has occured';
                    }
                    status.setMsg(msg, true);
                    formpanel.startMonitoring();
                    callback(false);
                }
            );

            // updates
            rec.set('evtype', evtype.getValue());
            rec.set('evdir', evdir.getValue());
            rec.set('evdtim', dtimfield.getValue());
            rec.set('evdesc', notesfield.getValue());

            // only set org/prj if they've been changed (will be uuid)
            orguuid = orgfield.getValue();
            if (orguuid && orguuid.length === 12 && !orguuid.match(/\s/)) {
                rec.set('org_uuid', orguuid);
            }
            prjuuid = prjfield.getValue();
            if (prjuuid && prjuuid.length === 12 && !prjuuid.match(/\s/)) {
                rec.set('prj_uuid', prjuuid);
            }

            // save!
            uuid = rec.data.tank_uuid;
            this.saveId = rec.store.save();
            if (this.saveId > 0) {
                rec.store.on('save', function () {
                    this.fireSubmit(uuid, callback);
                }, this, {single: true});
            }
            else {
                this.fireSubmit(uuid, callback); //nothing to save
            }
        },
        fireSubmit: function (uuid, callback) {
            status.setMsg('Submitting...', false, true);
            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/csv/' + uuid + '/submit.json',
                method: 'POST',
                callback: function (opts, success, resp) {
                    var data, msg;

                    data = Ext.util.JSON.decode(resp.responseText);
                    if (success && data && data.success) {
                        formpanel.disableAll();
                        status.setMsg(
                            'CSV Import scheduled for background processing',
                            false,
                            false,
                            true
                        );
                        panel.ownerCt.tankRec.store.load();
                        callback(true);
                    }
                    else {
                        if (data && data.message) {
                            msg = data.message;
                        }
                        else {
                            msg = 'Server Error: ' + resp.responseText;
                        }
                        status.setMsg(msg, true);
                        formpanel.startMonitoring();
                        callback(false);
                    }
                }
            });
        }
    });

    panel.on('show', function () {
        var d,
            desc,
            dir,
            dtim,
            meta,
            name,
            orgdisplay,
            prjdisplay,
            rec,
            type;

        rec = panel.ownerCt.tankRec;
        meta = Ext.decode(rec.data.tank_meta);

        // show any error status
        if (meta.submit_success) {
            status.setMsg(meta.submit_message, false, false, true);
            formpanel.disableAll();
        }
        else {
            if (meta.submit_message) {
                status.setMsg(meta.submit_message, true);
            }
            else {
                status.hide();
            }
            formpanel.startMonitoring(); // monitor valid
        }

        // update the fields
        d = rec.data;
        if (d.org_uuid) {
            orgdisplay = d.TankOrg[0].Organization.org_display_name;
            orgfield.selectOrDisplay(d.org_uuid, orgdisplay);
            prjfield.setOrg(d.org_uuid);

            // make sure it isn't the default project
            name = (d.prj_uuid) ? d.TankActivity[0].Project.prj_name : null;
            if (d.prj_uuid && name !== 'sysdefault') {
                prjdisplay = d.TankActivity[0].Project.prj_display_name;
                prjfield.selectOrDisplay(d.prj_uuid, prjdisplay);
            }
            else {
                prjfield.setValue('');
            }
        }
        else {
            orgfield.setValue('');
            prjfield.setValue('');
        }

        type = (rec.data.evtype) ? rec.data.evtype : 'E';
        dir = (rec.data.evdir) ? rec.data.evdir : 'I';
        dtim = (rec.data.evdtim) ? rec.data.evdtim : new Date().clearTime();
        desc = (rec.data.evdesc) ? rec.data.evdesc : null;

        evtype.setValue(type);
        evdir.setValue(dir);
//        var dt = Date.parseDate(tact.tact_dtim, "Y-m-d H:i:s");
//        dtimfield.setValue(dt ? dt : tact.tact_dtim);
        dtimfield.setValue(dtim);
        notesfield.setValue(desc);

        // validate
        formpanel.on('clientvalidation', function (fp, isValid) {
            if (isValid !== panel.validState) {
                panel.fireEvent('validpoll', isValid);
                if (!isValid) {
                    status.setMsg('Please complete activity info', true);
                }
                else {
                    if (Ext.isDefined(panel.validState)) {
                        status.hide();
                    }
                }
                panel.validState = isValid;
            }
        });
    });
    panel.on('hide', function () {
        formpanel.stopMonitoring();
        delete panel.validState;
    });

    return panel;
};
