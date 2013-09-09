/***************
 * Email Summary Panel
 *
 * email_campaign_name
 * org_uuid
 * email_type
 * email_status
 *
 */
AIR2.Email.Summary = function() {
    var summaryTemplate, mayEdit,
        archiveButton, cancelButton, discardButton, previewButton, sendButton, unarchiveButton;

    // editing authz/state
    mayEdit = AIR2.Email.BASE.authz.may_write &&
        (AIR2.Email.BASE.radix.email_status == 'D');

    summaryTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="email-row">' +
                '<b>{email_campaign_name}</b>' +
                '<p>Email campaign for {[AIR2.Format.orgName(values.Organization, 1)]}</p>' +
                '{[this.formatBin(values)]}' +
                '<ul class="pill upper">' +
                    '<li>Type</li>' +
                    '{[this.formatType(values)]}' +
                '</ul>' +
                '<ul class="pill upper">' +
                    '<li>Status</li>' +
                    '{[this.formatStatus(values)]}' +
                '</ul>' +
                '<tpl if="this.hasScheduled(values)">' +
                    '<ul class="pill upper">' +
                        '<li>Scheduled for</li>' +
                        '<li class="green">{[AIR2.Format.dateHuman(values.email_schedule_dtim)]}</li>' +
                    '</ul>' +
                '</tpl>' +
                '<tpl if="this.hasFirstExported(values)">' +
                    '<ul class="pill upper">' +
                        '<li>Sent</li>' +
                        '<li class="green">{[AIR2.Format.dateHuman(values.first_exported_dtim)]}</li>' +
                    '</ul>' +
                '</tpl>' +
                '<div class="meta">' +
                    '<ul class="pill">' +
                        '<li>Created by {[AIR2.Format.userName(values.CreUser, 1, 1)]}</li>' +
                        '<li class="norm">on {[AIR2.Format.dateHuman(values.email_cre_dtim)]}</li>' +
                    '</ul>' +
                    '<tpl if="this.hasUpdated(values)">' +
                        '<ul class="pill">' +
                            '<li>Updated by {[AIR2.Format.userName(values.UpdUser, 1, 1)]}</li>' +
                            '<li class="norm">on {[AIR2.Format.dateHuman(values.email_upd_dtim)]}</li>' +
                        '</ul>' +
                    '</tpl>' +
                '</div>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            formatBin: function (v) {
                var name;
                if (v.first_exported_dtim && AIR2.Email.EXPDATA.radix
                    && AIR2.Email.EXPDATA.radix.Bin) {
                    name = AIR2.Format.binName(AIR2.Email.EXPDATA.radix.Bin, 1, 30);
                    return '<p>Sent to bin ' + name + '</p>';
                }
                return '';
            },
            formatType: function (v) {
                var cls = 'red';
                return '<li class="dark">'+AIR2.Format.emailType(v)+'</li>';
            },
            formatStatus: function (v) {
                if (v.email_status == 'A') {
                    return '<li class="green">Sent</li>';
                }
                else if (v.email_status == 'Q') {
                    if (v.email_schedule_dtim) {
                        return '<li class="green">Scheduled</li>';
                    }
                    else {
                        return '<li class="green">Sending</li>';
                    }
                }
                else if (v.email_status == 'D') {
                    return '<li class="dark">Draft</li>';
                }
                else {
                    return '<li class="red">Archived</li>';
                }
            },
            hasUpdated: function (v) {
                return ('' + v.email_cre_dtim) != ('' + v.email_upd_dtim);
            },
            hasScheduled: function (v) {
                return v.email_schedule_dtim && !v.first_exported_dtim;
            },
            hasFirstExported: function (v) {
                return v.first_exported_dtim;
            },
        }
    );

    // fbar buttons (visibility dependent on email_status)
    discardButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-prohibited',
        title: 'Discard this email',
        text: 'Delete Draft',
        handler: function (btn, e) {
            var rec = AIR2.Email.Summary.store.getAt(0);
            AIR2.UI.Prompt(
                null,
                'Really delete?',
                'Delete this draft email?  This operation cannot be undone.',
                function(val) {
                    if (val == 'yes') {
                        var m = new Ext.LoadMask(Ext.getBody(), {msg: 'Deleting...'});
                        AIR2.Email.Summary.store.on('save', function (s) {
                            window.location = AIR2.HOMEURL + '/email';
                        });
                        AIR2.Email.Summary.store.remove(rec);
                        AIR2.Email.Summary.store.save();
                        m.show();
                    }
                }
            );
        }
    });
    archiveButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-prohibited',
        title: 'Archive this email',
        text: 'Archive Email',
        handler: function (btn, e) {
            AIR2.Email.Summary.store.getAt(0).set('email_status', 'F');
            AIR2.Email.Summary.store.save();
            updateButtonVisibility();
        }
    });
    unarchiveButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-email',
        title: 'Unarchive this email',
        text: 'Unarchive Email',
        handler: function (btn, e) {
            AIR2.Email.Summary.store.getAt(0).set('email_status', 'A');
            AIR2.Email.Summary.store.save();
            updateButtonVisibility();
        }
    });
    previewButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-forward',
        title: 'Send a preview email to yourself',
        text: 'Preview',
        handler: function (btn, e) {
            var rec = AIR2.Email.Summary.store.getAt(0);
            var uuid = rec.data.email_uuid;

            AIR2.UI.Prompt(
                null,
                'Send Preview Email',
                'Send a preview email to this address:',
                function(val, addr) {
                    if (val == 'ok') {
                        var lm = new Ext.LoadMask(Ext.getBody(), { msg: 'Sending email...' });
                        lm.show();
                        Ext.Ajax.request({
                            url: AIR2.HOMEURL + '/email/' + uuid + '/export.json',
                            params: {radix: Ext.util.JSON.encode({preview: addr})},
                            method: 'POST',
                            callback: function (opts, success, resp) {
                                var data, msg, name, valuestr, maysend, succ, fail;
                                data = Ext.util.JSON.decode(resp.responseText) || {};
                                lm.hide();
                                if (!success || !data || !data.success) {
                                    var m = 'An unknown error has occurred.  Please contact support';
                                    if (data && data.message) m = data.message;
                                    AIR2.UI.ErrorMsg(null, 'Sorry!', m);
                                }
                            }
                        });
                    }
                },
                AIR2.Email.USEREMAIL
            );
        }
    });
    sendButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-schedule',
        title: 'Send or Schedule this email',
        text: 'Send',
        handler: function (btn, e) {
            var rec = AIR2.Email.Summary.store.getAt(0);
            var w = AIR2.Email.Exporter({originEl: btn.el, email_uuid: rec.get('email_uuid')});
            w.on('close', function () {
                AIR2.Email.Summary.reload(null, null, function() {
                    updateButtonVisibility();
                });
            });
        }
    });
    cancelButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-delete',
        title: 'Cancel a scheduled send',
        text: 'Cancel scheduled send',
        handler: function (btn, e) {
            var rec = AIR2.Email.Summary.store.getAt(0);
            var uuid = rec.data.email_uuid;
            var lm = new Ext.LoadMask(Ext.getBody(), { msg: 'Canceling scheduled email...' }); 
            lm.show();
            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/email/' + uuid + '/export.json',
                params: {radix: Ext.util.JSON.encode({cancel: true})},
                method: 'POST',
                callback: function (opts, success, resp) {
                    var data, msg, name, valuestr, maysend, succ, fail;
                    data = Ext.util.JSON.decode(resp.responseText) || {}; 
                    lm.hide();
                    if (!success || !data || !data.success) {
                        var m = 'An unknown error has occurred.  Please contact support';
                        if (data && data.message) m = data.message;
                        AIR2.UI.ErrorMsg(null, 'Sorry!', m); 
                    }
                    else {
                        AIR2.Email.Summary.reload(null, null, function() {
                            updateButtonVisibility();
                        });
                    }
                }
            }); 
        }   
    });

    // build panel
    AIR2.Email.Summary = new AIR2.UI.Panel({
        storeData: AIR2.Email.BASE,
        url: AIR2.Email.URL,
        colspan: 1,
        title: 'Summary',
        cls: 'air2-email-summary',
        iconCls: 'air2-icon-clipboard',
        itemSelector: '.email-row',
        tpl: summaryTemplate,
        allowEdit: mayEdit,
        setEditable: function (allow) {
            AIR2.Email.Summary.tools.items.last().setVisible(allow);
        },
        editInPlace: [{
            xtype: 'textfield',
            fieldLabel: 'Campaign Name',
            name: 'email_campaign_name',
            autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
            maxLength: 255,
            allowBlank: false,
            msgTarget: 'under'
        },{
            xtype: 'air2searchbox',
            fieldLabel: 'Organization',
            name: 'org_uuid',
            searchUrl: AIR2.HOMEURL + '/organization',
            pageSize: 10,
            baseParams: {
                sort: 'org_display_name asc',
                role: 'W', // writer and up
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
            },
            hideTrigger: false
        },{
            xtype: 'air2combo',
            fieldLabel: 'Type',
            name: 'email_type',
            width: 90,
            choices: [
                ['Q', 'Query'],
                ['F', 'Follow-up'],
                ['R', 'Reminder'],
                ['T', 'Thank You'],
                ['O', 'Other']
            ]
        }],
        fbar: [discardButton, archiveButton, unarchiveButton, cancelButton, '->', previewButton, ' ', sendButton],
        listeners: {
            beforeedit: function (form, rs) {
                // setup org picker
                var cb = form.find('name', 'org_uuid')[0];
                cb.selectOrDisplay(rs[0].data.org_uuid, rs[0].data.org_display_name);
            }
        }
    });

    // button states
    updateButtonVisibility = function() {
        var st = AIR2.Email.Summary.store.getAt(0).get('email_status');
        var scheduled = AIR2.Email.Summary.store.getAt(0).get('email_schedule_dtim');
        discardButton.setVisible(st == 'D');
        archiveButton.setVisible(st == 'A');
        unarchiveButton.setVisible(st == 'F');
        previewButton.setVisible(st == 'D' || st == 'Q');
        sendButton.setVisible(st == 'D');
        cancelButton.setVisible(st == 'Q' && scheduled);

        mayEdit = AIR2.Email.BASE.authz.may_write && (st == 'D');

        // set editable states
        if (AIR2.Email.Summary.tools) {
            AIR2.Email.Summary.setEditable(st == 'D' && mayEdit);
            AIR2.Email.Content.setEditable(st == 'D' && mayEdit);
            AIR2.Email.Inquiries.setEditable(st == 'D' && mayEdit);
        }
    }
    updateButtonVisibility();

    return AIR2.Email.Summary;
};
