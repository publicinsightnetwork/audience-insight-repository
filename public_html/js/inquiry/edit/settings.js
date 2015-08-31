/***************
 * Query Settings Panel
 */
AIR2.Inquiry.typeLabels = {
    Q : "Standard", // really Querymaker
    F : "Formbuilder",
    N : "Non-Journalism",
    E : "Manual Entry",
    C : "Comment"
};

AIR2.Inquiry.Settings = function () {
    var dv,
        editItems,
        editWindowConfig,
        expireButton,
        fbarButtons,
        inqRec,
        inqStatus,
        isPublished,
        okToSchedule,
        panel,
        publishButton,
        scheduleButton,
        switchButtonState,
        unscheduleButton,
        deleteButton,
        template,
        viewport;

    deleteButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hidden: true,
        hideParent: false,
        iconCls: 'air2-icon-delete',
        id: 'air2-inquiry-delete-button',
        title: 'Delete the draft query',
        text: 'Delete',
        handler: function (button, event) {
            var inquiryRecord;
            inquiryRecord = AIR2.Inquiry.inqStore.getAt(0);
            Logger(inquiryRecord);
            AIR2.Inquiry.inqStore.remove(inquiryRecord);
            AIR2.Inquiry.inqStore.on('save', function() {
                Ext.getCmp('air2-inquiry-publish-settings').el.mask('Deleting...');
                if (window.history.length > 1) {
                    window.history.back(-1);
                }
                else {
                    location.href = AIR2.HOMEURL;
                }
            });
            AIR2.Inquiry.inqStore.save();
        }
    });

    publishButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hidden: true,
        hideParent: false,
        iconCls: 'air2-icon-check',
        id: 'air2-inquiry-publish-button',
        title: 'Publish Immediately',
        text: 'Publish',
        handler: function (button, event) {
            var inquiryRecord;
            inquiryRecord = AIR2.Inquiry.inqStore.getAt(0);

            inquiryRecord.forceSet('do_publish', true);
            AIR2.Inquiry.inqStore.save();
            Ext.getCmp('air2-inquiry-expire-button').show();
            this.setText('Update');
            deleteButton.hide();
        }
    });

    scheduleButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hidden: true,
        hideParent: false,
        iconCls: 'air2-icon-schedule',
        id: 'air2-inquiry-schedule-button',
        title: 'Schedule Publish',
        text: 'Schedule',
        handler: function (button, event) {
            var inquiryRecord;
            inquiryRecord = AIR2.Inquiry.inqStore.getAt(0);

            inquiryRecord.forceSet('do_schedule', true);
            AIR2.Inquiry.inqStore.save();
            Ext.getCmp('air2-inquiry-publish-button').hide();
            Ext.getCmp('air2-inquiry-unschedule-button').show();
            this.hide();
            deleteButton.hide();
        }
    });

    unscheduleButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hidden: true,
        hideParent: false,
        iconCls: 'air2-icon-unschedule',
        id: 'air2-inquiry-unschedule-button',
        title: 'Cancel Scheduled Publish',
        text: 'Cancel Publish',
        handler: function (button, event) {
            var inquiryRecord;
            inquiryRecord = AIR2.Inquiry.inqStore.getAt(0);

            inquiryRecord.forceSet('do_unschedule', true);
            AIR2.Inquiry.inqStore.save();
            Ext.getCmp('air2-inquiry-publish-button').hide();
            Ext.getCmp('air2-inquiry-schedule-button').show();
            this.hide();
            deleteButton.show();
        }
    });


    expireButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hidden: true,
        hideParent: false,
        iconCls: 'air2-icon-prohibited',
        id: 'air2-inquiry-expire-button',
        title: 'Expire the published query',
        text: 'Expire',
        handler: function (button, event) {
            var inquiryRecord;
            inquiryRecord = AIR2.Inquiry.inqStore.getAt(0);

            inquiryRecord.forceSet('do_expire', true);
            AIR2.Inquiry.inqStore.save();
            Ext.getCmp('air2-inquiry-publish-button').show();
            this.hide();
            deleteButton.hide();
        }
    });

    fbarButtons = [
        '->',
        deleteButton,
        ' ',
        expireButton,
        ' ',
        publishButton,
        ' ',
        unscheduleButton,
        ' ',
        scheduleButton
    ];

    inqRec = AIR2.Inquiry.inqStore.getAt(0);

    okToSchedule = function (inqRec) {
        var publishTime;

        publishTime = inqRec.get('inq_publish_dtim');

        if (publishTime && publishTime > Date.now()) {
            return true;
        }

        return false;
    };

    switchButtonState = function (inqRec) {
        switch (inqRec.get('inq_status')) {
        case AIR2.Inquiry.STATUS_ACTIVE:
        case AIR2.Inquiry.STATUS_DEADLINE:
            deleteButton.hide();
            expireButton.show();
            publishButton.setText('Update');
            publishButton.show();
            scheduleButton.hide();
            unscheduleButton.hide();
            break;
        case AIR2.Inquiry.STATUS_EXPIRED:
            deleteButton.hide();
            expireButton.hide();
            publishButton.show();
            scheduleButton.hide();
            break;
        case AIR2.Inquiry.STATUS_DRAFT:
            deleteButton.show();
            expireButton.hide();
            if (okToSchedule(inqRec)) {
                publishButton.hide();
                scheduleButton.show();
                unscheduleButton.hide();
            }
            else {
                publishButton.show();
                scheduleButton.hide();
                unscheduleButton.hide();
            }
            break;
        case AIR2.Inquiry.STATUS_INACTIVE:
            deleteButton.hide();
            expireButton.hide();
            publishButton.show();
            scheduleButton.hide();
            break;
        case AIR2.Inquiry.STATUS_SCHEDULED:
            deleteButton.hide();
            expireButton.hide();
            publishButton.hide();
            scheduleButton.hide();
            unscheduleButton.show();
            break;
        default:
        }
    };

    switchButtonState(inqRec);

    template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<table class="air2-tbl">' +
                '{.:this.displayAlertBanner}' +
                '<tpl if="values.inq_upd_dtim">' +
                    '<tr>' +
                        '<td class="label right">Last updated:</td>' +
                        '<td class="date left">' +
                            '{[AIR2.Format.dateLong(values.inq_upd_dtim)]}' +
                            '<br />by ' +
                            '{[AIR2.Format.userName(values.UpdUser,1,1)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_cre_dtim">' +
                    '<tr>' +
                        '<td class="label right">Created:</td>' +
                        '<td class="date left">' +
                            '{[AIR2.Format.dateLong(values.inq_cre_dtim)]}' +
                            '<br />by ' +
                            '{[AIR2.Format.userName(values.CreUser,1,1)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tr>' +
                    '<td class="label right">Social Media Logo/Image:</td>' +
                    '<td class="">' +
                        '<div id="air2-inq-logo">' +
                            '{[AIR2.Format.inqLogo(values)]}' +
                        '</div>' +
                    '</td> ' +
                '</tr>' +
                '<tpl if="values.inq_publish_dtim">' +
                    '<tr>' +
                        '<td class="label right">Publish date:</td>' +
                        '<td class="date left">' +
                            '{[AIR2.Format.dateLong(' +
                                'values.inq_publish_dtim' +
                            ')]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_deadline_dtim">' +
                    '<tr>' +
                        '<td class="label right">Deadline date:</td>' +
                        '<td class="date left">' +
                            '{[AIR2.Format.date(values.inq_deadline_dtim)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_deadline_msg">' +
                    '<tr>' +
                        '<td class="label right">Deadline Message:</td>' +
                        '<td class="left">' +
                            '{[this.previewLink(' +
                                '"Preview Deadline Message",' +
                                '"inq_deadline_msg"' +
                            ')]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_expire_dtim">' +
                    '<tr>' +
                        '<td class="label right">Expire date:</td>' +
                        '<td class="date left">' +
                            '{[AIR2.Format.date(values.inq_expire_dtim)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_expire_msg">' +
                    '<tr>' +
                        '<td class="label right">Expire Message:</td>' +
                        '<td class="left">' +
                            '{[this.previewLink(' +
                                '"Preview Expire Message",' +
                                '"inq_expire_msg"' +
                            ')]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_confirm_msg">' +
                    '<tr>' +
                        '<td class="label right">Thank You Message:</td>' +
                        '<td class="left">' +
                            '{[this.previewLink(' +
                                '"Preview Thank You Message",' +
                                '"inq_confirm_msg"' +
                            ')]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tr>' +
                    '<td class="label right">' +
                        'Display on PIN site / RSS feeds:' +
                    '</td>' +
                    '<td class="left">' +
                        '{.:this.formatQueryFeedStatus}' +
                    '</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label right">' +
                        'Type' +
                    '</td>' +
                    '<td class="left">' +
                        '{.:this.formatQueryType}' +
                    '</td>' +
                '</tr>' +
                '<tr>' +
                    '{.:this.publishStatus}' +
                '</tr>' +
                '<tpl if="values.inq_loc_id">' +
                    '<tr>' +
                        '<td class="label right">Localization:</td>' +
                        '<td class="left">' +
                            '{values.Locale.loc_lang} - ' +
                            '{values.Locale.loc_region}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.inq_url">' +
                    '<tr>' +
                        '<td class="label right">Query URL:</td>' +
                        '<td class="left">' +
                            '<a href="{values.inq_url}" target="_blank">' +
                                '{[Ext.util.Format.ellipsis(values.inq_url, 20)]}' +
                            '</a>' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
            '</table>' +
        '</tpl>',
        {
            compiled: true,
            createdByLink: function (values) {
                var userLink = 'Created  by ' +
                    AIR2.Format.userName(values.CreUser, true, true) + ': ' +
                    AIR2.Format.dateWeek(values.inq_cre_dtim, true);

                return userLink;
            },
            displayAlertBanner: function (values) {
                var isPublished, pubFlags;
                pubFlags = AIR2.Inquiry.PUBLISHED_STATUS_FLAGS;

                isPublished = (pubFlags.indexOf(values.inq_status) > -1);

                if (values.inq_stale_flag && isPublished) {
                    publishButton.enable();
                    return '<tr class="notify notify-page">' +
                        '<td colspan="99">' +
                            '<span class="notify-message">' +
                                'There are unpublished changes' +
                            '</span>' +
                        '</td>' +
                    '</tr>';
                }
                else if (isPublished) {
                    publishButton.disable();
                }

                return '';

            },
            formatQueryFeedStatus: function (values) {
                if (values.inq_rss_status == 'Y') {
                    return '<span class="air2-icon air2-icon-check">' +
                            'Included' +
                        '</span>';
                }
                else {
                    return '<span class="air2-icon air2-icon-prohibited">' +
                        'Not Included' +
                    '</span>';
                }
            },
            formatQueryType: function(values) {
                if (AIR2.Util.Authz.isGlobalManager()) {
                    return '<span>' + AIR2.Inquiry.typeLabels[values.inq_type] + '</span>';
                }
                else {
                    return '<span>Standard</span>';
                }
            },
            previewLink: function (display, key) {
                return '<a onclick="AIR2.Inquiry.inquiryPreviewModal(\'' +
                display + '\',\'' + key + '\')"' + '>' + display + '</a>';
            },
            publishStatus: function (values) {
                var status;

                status = '<td class="label right">Publish Status:</td>';
                status += '<td>';

                switch (values.inq_status) {
                case AIR2.Inquiry.STATUS_ACTIVE:
                case AIR2.Inquiry.STATUS_DEADLINE:
                    status += '<span class="air2-icon air2-icon-check">' +
                        'Published' +
                    '</span>';
                    break;
                case AIR2.Inquiry.STATUS_EXPIRED:
                    status += '<span class="air2-icon air2-icon-prohibited">' +
                        'Expired' +
                    '</span>';
                    break;
                case AIR2.Inquiry.STATUS_DRAFT:
                    status += '<span class="air2-icon air2-icon-draft">' +
                        'Draft' +
                    '</span>';
                    break;
                case AIR2.Inquiry.STATUS_INACTIVE:
                    status += '<span class="air2-icon air2-icon-prohibited">' +
                        'Inactive' +
                    '</span>';
                    break;
                case AIR2.Inquiry.STATUS_SCHEDULED:
                    status += '<span class="air2-icon air2-icon-scheduled">' +
                        'Scheduled' +
                    '</span>';
                    break;
                default:
                }

                status += '</td>';
                return status;
            }
        }
    );

    editItems = [
        {
            xtype: 'fieldset',
            title: 'Image',
            defaults: {msgTarget: 'under'},
            items: [{
                xtype: 'fileuploadfield',
                fieldLabel: 'Image',
                name: 'logo',
                allowBlank: true
            }, {
                xtype: 'box',
                html: 'Please upload a square .jpg or .png file at least ' +
                    '400px by 400px. We will display the image on social media for this ' +
                    'query and in RSS feeds.',
                id: 'logo-instructions'
            }]
        },
        {
            fieldLabel: 'Publish Date',
            invalidText: 'Please enter a date and time, or use the picker.',
            msgTarget: 'under',
            name: 'inq_publish_dtim',
            picker: {
                timePicker: {
                    hourIncrement: 1,
                    minIncrement: 15,
                    xtype: 'basetimepicker'
                }
            },
            xtype: 'datetimefield'
        },
        {
            fieldLabel: 'Deadline Date',
            invalidText: 'Please enter a date and time, or use the picker.',
            msgTarget: 'under',
            name: 'inq_deadline_dtim',
            picker: {
                timePicker: {
                    hourIncrement: 1,
                    minIncrement: 15,
                    xtype: 'basetimepicker'
                }
            },
            xtype: 'datetimefield'
        },
        {
            xtype: 'air2ckeditor',
            fieldLabel: 'Deadline Message',
            name: 'inq_deadline_msg',
            style: 'resize:auto;width:96%'
        },
        {
            fieldLabel: 'Expire Date',
            invalidText: 'Please enter a date and time, or use the picker.',
            msgTarget: 'under',
            name: 'inq_expire_dtim',
            picker: {
                timePicker: {
                    hourIncrement: 1,
                    minIncrement: 15,
                    xtype: 'basetimepicker'
                }
            },
            xtype: 'datetimefield'
        },
        {
            xtype: 'air2ckeditor',
            fieldLabel: 'Expire Message',
            name: 'inq_expire_msg',
            style: 'resize:auto;width:96%'
        },
        {
            xtype: 'air2ckeditor',
            fieldLabel: 'Thank You Message',
            name: 'inq_confirm_msg',
            style: 'resize:auto;width:96%'
        },
        // IMPORTANT that this hidden field immediately precedes the checkbox field.
        {
            xtype: 'hidden',
            name: 'inq_rss_status'
        },
        // IMPORTANT that the hidden inq_rss_status precedes checkbox.
        {
            xtype: 'checkbox',
            checked: (
                AIR2.Inquiry.inqStore.getAt(0).get('inq_rss_status') == 'Y'
            ),
            fieldLabel: 'Display on PIN site / RSS feeds',
            handler: function (checkbox, checked) {
                checkbox.originalValue = checked;
                if (checked) {
                    checkbox.previousSibling().setValue('Y'); // TODO previousSibliing is a brittle assumption.
                }
                else {
                    checkbox.previousSibling().setValue('N');
                }
            },
            submitValue: false
        },
        {
            xtype: 'combo',
            autoSelect: true,
            editable: false,
            disabled: !AIR2.Util.Authz.isGlobalManager(),
            fieldLabel: 'Type',
            forceSelection: true,
            name: 'inq_type',
            store: [
                ['Q', 'Standard'],
                ['N', 'Non-Journalism']
            ],  
            triggerAction: 'all',
            value: AIR2.Inquiry.inqStore.getAt(0).get('inq_type')
        },
        {
            xtype: 'combo',
            autoSelect: true,
            editable: false,
            fieldLabel: 'Localization',
            forceSelection: true,
            name: 'loc_key',
            store: [
                ['en_US', 'English - United States'],
                ['es_US', 'Spanish - United States']
            ],
            triggerAction: 'all',
            value: AIR2.Inquiry.inqStore.getAt(0).get('Locale').loc_key
        },
        {
            xtype: 'textfield',
            fieldLabel: 'Query URL',
            msgTarget: 'under',
            name: 'inq_url',
            vtype: 'url'
        }
    ];

    viewport = Ext.getBody().getViewSize();

    editWindowConfig = {
        allowAdd: false,
        formAutoHeight: true,
        height: viewport.height - 60,
        iconCls: 'air2-icon-inquiry',
        id: 'air2-inquiry-edit-publish-settings',
        layout: 'fit',
        layoutConfig: {deferredRender: true},
        listeners: {
            afterrender: function (window) {
                viewport = Ext.getBody().getViewSize();
                window.setHeight(viewport.height - 60);
                window.setWidth(viewport.width - 60);
            },
            show: function (window) {
                viewport = Ext.getBody().getViewSize();
                window.setHeight(viewport.height - 60);
                window.setWidth(viewport.width - 60);
            }
        },
        title: 'Edit Settings',
        width: viewport.width - 60
    };

    // panel
    panel = new AIR2.UI.Panel({
        allowEdit: AIR2.Inquiry.authzOpts.isWriter,
        autoHeight: true,
        colspan: 3,
        editInPlace: editItems,
        editInPlaceUsesModal: editWindowConfig,
        emptyText: '<div class="air2-panel-empty"><h3>Loading...</h3></div>',
        fbar: fbarButtons,
        loaded: true,
        iconCls: 'air2-icon-inquiry',
        id: 'air2-inquiry-publish-settings',
        itemSelector: '.air2-tbl',
        showTotal: false,
        showHidden: false,
        store: AIR2.Inquiry.inqStore,
        title: 'Publishing',
        tpl: template,
        listeners: {
            aftersave: function (form, rs) {
                if (Ext.isArray(rs)) {
                    rs = rs[0];
                }

                switchButtonState(rs);
            },
            // set faketext in the fileupload fields
            beforeedit: function (form, rs) {
                var f, logo, rec;

                f = form.getForm();
                rec = rs[0];
                if (rec.data.Logo) {
                    logo = f.findField('logo');
                    logo.setRawValue(' ' + rec.data.Logo.img_file_name);
                }
            },
            // handle ajax file-upload
            validate: function (inqpanel) {
                var form, logo, setLogo, http_method;

                form = inqpanel.getForm();
                logo = inqpanel.getForm().findField('logo');

                setLogo = logo.getValue() && logo.getValue().charAt(0) !== ' ';

                // set form to just upload the file - callback for other saves
                if (setLogo) {
                    form.el.set({enctype: 'multipart/form-data'});

                    // disable non-file fields (and unused files)
                    form.items.each(function (f) {
                        var keep = (setLogo && f === logo);
                        if (!keep) {
                            f.disable();
                        }
                    });

                    // we must PUT if there is already a logo defined
                    // and POST if this is a new logo
                    http_method = 'POST';
                    if (panel.store.getAt(0).data.Logo) {
                        http_method = 'PUT';
                    }

                    // ajax-submit file form
                    form.submit({
                        url: AIR2.Inquiry.URL + '/logo.json',
                        params: {
                            'x-force-content': 'text/html',
                            'x-tunneled-method': http_method
                        },
                        success: function (form, action) {
                            //Logger('success, logo=', logo);
                        
                            logo.reset();
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });

                            // quiet-update images
                            var rec = panel.store.getAt(0);
                            //Logger('success, rec=', rec);
                            rec.data.Logo = action.result.radix.Logo;

                            // re-enable non-file fields (and unused files)
                            form.items.each(function (f) {
                                var keep = (setLogo && f === logo);
                                if (!keep) {
                                    f.enable();
                                }
                            });

                            // unmask, refresh, and fire regular-save
                            inqpanel.el.unmask();
                            panel.getDataView().refresh();
                            panel.endEditInPlace(true);
                        },
                        failure: function (form, action) {
                        
                            //Logger('failure, rec=', rec);
                        
                            var msg = "Unknown error";
                            if (action.result && action.result.message) {
                                msg = action.result.message;
                            }
                            AIR2.UI.ErrorMsg(
                                form.el,
                                "Error uploading file",
                                msg
                            );

                            // reset and unmask
                            logo.reset();
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });
                            
                            inqpanel.el.unmask();
                        }
                    });

                    // defer any saving until the upload finishes
                    inqpanel.el.mask('Uploading and saving...');
                    return false;
                }
                else {
                    return true;
                }
            }
        }
    });

    dv = panel.getDataView();
    dv.addListener('afterrender', function () {
        this.store.addListener({
            beforesave: function () {
                if (!panel.isediting) {
                    panel.body.el.mask('Updating...');
                }
            },
            update: function () {
                panel.body.el.unmask();
            }
        });
    });

    return panel;
};
