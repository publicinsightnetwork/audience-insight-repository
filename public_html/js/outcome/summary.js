/***************
 * Outcome Summary Panel
 */
AIR2.Outcome.Summary = function () {
    var getPublishableToolTip,
        summaryTemplate;

    getPublishableToolTip = function () {
        var toolTip, toolTipText;

        toolTipText = 'Compose a headline (20 words or less) and a ' +
            'description, describing how the PIN sources contributed to ' +
            'reporting/content development. Selecting an organization and a ' +
            'query help determine where this PINfluence will show up on ' +
            'publicinsightnetwork.org';

        toolTip = '<span class="air2-tipper" ext:qtip="' + toolTipText +
            '" hide="user" show="user">?</span>';

        return toolTip;
    };

    summaryTemplate = new Ext.XTemplate(
        '<div class="air2-outcome">' +
            '<tpl for="."><table class="outcome-row">' +
                // section 1
                '<tr>' +
                    '<td class="label">Story Headline</td>' +
                    '<td class="value">{out_headline}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">Content Link</td>' +
                    '<td class="value forcebreak">' +
                        '{[this.printLink(values)]}' +
                    '</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">How the PIN influenced this story</td>' +
                    '<td class="value">{out_teaser}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">Publish/Air/Event Date</td>' +
                    '<td class="value">' +
                        '{[AIR2.Format.date(values.out_dtim)]}' +
                    '</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">Program/Event/Website</td>' +
                    '<td class="value">{out_show:this.unblank}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">Organization</td>' +
                    '<td class="value">' +
                        '{[AIR2.Format.orgName(values.Organization,1)]}' +
                    '</td>' +
                '</tr>' +
                '<tr class="break">' +
                    '<td class="label">Publish?</td>' +
                    '<td class="value">' +
                        '<span class="status ' +
                        '{[this.statusCls(values)]} air2-corners3">' +
                            '{[this.status(values)]}' +
                        '</span>' +
                    '</td>' +
                '</tr>' +
                // section 2
                '<tr>' +
                    '<td class="label">Content Type</td>' +
                    '<td class="value">' +
                        '{[AIR2.Format.codeMaster(' +
                            '"out_type",' +
                            'values.out_type' +
                        ')]}' +
                    '</td>' +
                '</tr>' +
                '<tr class="break">' +
                    '<td class="label">Additional Information</td>' +
                    '<td class="value">' +
                        '{out_internal_teaser:this.unblank}' +
                    '</td>' +
                '</tr>' +
                '<tpl if="this.hasSurvey(values)">' +
                    '<tr>' +
                        '<td class="label">PIN helped to</td>' +
                        '<td class="value">{[this.printSurvey(values)]}</td>' +
                    '</tr>' +
                '</tpl>' +
                // userstamps
                '<tr>' +
                    '<td class="label">Created</td>' +
                    '<td class="value">' +
                        '{[AIR2.Format.date(values.out_cre_dtim)]} by ' +
                        '{[AIR2.Format.userName(values.CreUser,1,1)]}' +
                    '</td>' +
                '</tr>' +
                '<tpl if="this.hasUpd(values)">' +
                    '<tr>' +
                        '<td class="label">Updated</td>' +
                        '<td class="value">' +
                            '{[AIR2.Format.date(values.out_upd_dtim)]} by ' +
                            '{[AIR2.Format.userName(values.UpdUser,1,1)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
            '</table></tpl>' +
        '</div>',
        {
            compiled: true,
            unblank: function (v) {
                if (v && v.length > 0) {
                    return v;
                }
                return '<span class="lighter">(none)</span>';
            },
            printLink: function (v) {
                if (v.out_url) {
                    var s = '<a class="external" target="_blank" href="';
                    s += v.out_url + '">' + v.out_url + '</a>';
                    return s;
                }
                return '<span class="lighter">(none)</span>';
            },
            hasUpd: function (v) {
                return ('' + v.out_cre_dtim !== '' + v.out_upd_dtim);
            },
            statusCls: function (v) {
                if (v.out_status === 'A') {
                    return 'feedyes';
                }
                if (v.out_status === 'N') {
                    return 'feedno';
                }
                return '';
            },
            status: function (v) {
                if (v.out_status === 'A') {
                    return 'Yes (publish to publicinsightnetwork.org and ' +
                        'RSS feed)';
                }
                if (v.out_status === 'N') {
                    return 'No';
                }
                return AIR2.Format.codeMaster('out_status', v.out_status);
            },
            hasSurvey: function (v) {
                var hasCheck = false;
                if (v.out_survey && (json = Ext.decode(v.out_survey))) {
                    Ext.iterate(json, function (text, checked) {
                        if (checked) {
                            hasCheck = true;
                        }
                    });
                }
                return hasCheck;
            },
            printSurvey: function (v) {
                var s = '<ul class="survey">';
                if (v.out_survey && (json = Ext.decode(v.out_survey))) {
                    Ext.iterate(json, function (text, checked) {
                        if (checked) {
                            s += '<li class="checked">' + text + '</li>';
                        }
                    });
                }
                s += '</ul>';
                return s;
            }
        }
    );

    // build panel
    AIR2.Outcome.Summary = new AIR2.UI.Panel({
        storeData: AIR2.Outcome.BASE,
        url: AIR2.Outcome.URL,
        colspan: 2,
        listeners: {
            beforeedit: function (fp, rs) {
                // #9118 - can only delete when 0 sources/projects/inquiries
                var numrel = 0;
                numrel += AIR2.Outcome.Sources.store.getCount();
                numrel += AIR2.Outcome.Projects.store.getCount();
                numrel += AIR2.Outcome.Inquiries.store.getCount();

                // only add the first time
                if (fp.bottomToolbar.items.getCount() > 2) {
                    fp.bottomToolbar.items.get(3).setVisible(numrel === 0);
                    return;
                }
                fp.bottomToolbar.add('->', {
                    xtype: 'air2button',
                    air2type: 'CLEAR',
                    air2size: 'MEDIUM',
                    iconCls: 'air2-icon-remove',
                    text: 'Delete',
                    hidden: (numrel !== 0),
                    handler: function (btn) {
                        var prompt = new AIR2.UI.Window({
                            title: 'Confirm Delete',
                            iconCls: 'air2-icon-alert',
                            cls: 'air2-outcome-delete-prompt',
                            closeAction: 'destroy',
                            closable: false,
                            width: 240,
                            height: 130,
                            bodyStyle: 'padding:5px 10px;color:#666',
                            html:
                                '<b ' +
                                'style="padding-bottom:5px;display:block;">' +
                                    'Delete PINfluence?' +
                                '</b>' +
                                'This operation cannot be undone.',
                            buttonAlign: 'left',
                            fbar: [
                                {
                                    xtype: 'air2button',
                                    air2type: 'DELETE',
                                    air2size: 'MEDIUM',
                                    text: 'Delete',
                                    width: 'auto',
                                    handler: function () {
                                        var r, s;

                                        prompt.mask.remove();
                                        prompt.el.setStyle('z-index', 90);
                                        prompt.container.mask('Deleting...');

                                        // delete and go back
                                        r = rs[0];
                                        s = r.store;
                                        s.on('save', function () {
                                            prompt.container.mask(
                                                'Redirecting...'
                                            );
                                            if (window.history.length > 1) {
                                                window.history.back(-1);
                                            }
                                            else {
                                                location.href = AIR2.HOMEURL;
                                            }
                                        });
                                        s.remove(r);
                                        s.save();
                                    }
                                },
                                {
                                    xtype: 'air2button',
                                    air2type: 'CANCEL',
                                    air2size: 'MEDIUM',
                                    text: 'Cancel',
                                    width: 'auto',
                                    handler: function () {prompt.close(); }
                                }
                            ]
                        });
                        prompt.show(btn.el);
                    }
                });
                fp.bottomToolbar.doLayout();
            }
        },
        title: 'Summary',
        cls: 'air2-outcome',
        iconCls: 'air2-icon-clipboard',
        itemSelector: '.outcome-row',
        tpl: summaryTemplate,
        allowEdit: AIR2.Outcome.BASE.authz.may_write,
        labelWidth: 120,
        editInPlace: [
            {
                xtype: 'fieldset',
                title: 'Publishable Fields ' + getPublishableToolTip() + '',
                width: 635,
                defaults: { msgTarget: 'under' },
                items: [
                    {
                        xtype: 'textfield',
                        fieldLabel: 'Story Headline',
                        allowBlank: false,
                        width: 485,
                        name: 'out_headline',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '255'
                        },
                        maxLength: 255
                    },
                    {
                        xtype: 'air2remotetext',
                        fieldLabel: 'Content Link',
                        name: 'out_url',
                        allowBlank: true,
                        width: 485,
                        remoteTable: 'outcome',
                        vtype: 'url',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '255'
                        },
                        maxLength: 255,
                        uniqueErrorText: function (data) {
                            var h, msg, outuuid;

                            msg = 'PINfluence already exists!';
                            if (data.conflict && data.conflict.out_url) {
                                outuuid = data.conflict.out_url.out_uuid;
                                h = AIR2.HOMEURL + '/outcome/' + outuuid;
                                msg += ' Check it out <a href="' + h;
                                msg += '">here</a>';
                            }
                            return msg;
                        }
                    },
                    {
                        xtype: 'textarea',
                        fieldLabel: 'How the PIN influenced this story',
                        allowBlank: false,
                        width: 485,
                        name: 'out_teaser',
                        grow: true,
                        growMin: 60
                    },
                    {
                        xtype: 'datefield',
                        fieldLabel: 'Publish/Air/Event Date',
                        allowBlank: false,
                        width: 150,
                        name: 'out_dtim'
                    },
                    {
                        xtype: 'textfield',
                        fieldLabel: 'Program/Event/ Website',
                        allowBlank: true,
                        width: 485,
                        name: 'out_show',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '255'
                        },
                        maxLength: 255
                    },
                    {
                        xtype: 'air2searchbox',
                        name: 'org_uuid',
                        width: 485,
                        cls: 'air2-magnifier',
                        fieldLabel: 'Organization',
                        searchUrl: AIR2.HOMEURL + '/organization',
                        pageSize: 10,
                        baseParams: {
                            sort: 'org_display_name asc'
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
                        // custom setvalue to ajax-fetch the actual record
                        setValue: function (v) {
                            var disp;

                            AIR2.UI.SearchBox.superclass.setValue.apply(
                                this,
                                arguments
                            );
                            if (v && !this.findRecord('org_uuid', v)) {
                                disp = AIR2.Outcome.BASE.radix.org_display_name;
                                Ext.form.ComboBox.superclass.setValue.call(
                                    this,
                                    disp
                                ); //temporary
                                this.selectRawValue(v, disp);
                                this.value = v;
                            }
                        }
                    },
                    {
                        xtype: 'air2combo',
                        fieldLabel: 'Status',
                        name: 'out_status',
                        width: 375,
                        choices: [
                            [
                                'A',
                                'Yes, publish to publicinsightnetwork.org ' +
                                'and RSS feed'
                            ],
                            [
                                'N',
                                'No'
                            ]
                        ]
                    }
                ]
            },
            {
                xtype: 'air2combo',
                fieldLabel: 'Content Type',
                name: 'out_type',
                width: 150,
                value: 'S',
                choices: [
                    ['S', 'Story'],
                    ['R', 'Series'],
                    ['E', 'Event'],
                    ['O', 'Other']
                ]
            },
            {
                xtype: 'textarea',
                fieldLabel: 'Additional Information',
                allowBlank: true,
                width: 485,
                name: 'out_internal_teaser',
                grow: true,
                growMin: 60
            },
            {
                xtype: 'checkboxgroup',
                fieldLabel: 'PIN Helped to',
                name: 'out_survey',
                allowBlank: true,
                width: 375,
                columns: 1,
                items: AIR2.Outcome.surveyOptions,
                getValue: function () {
                    var out = {};
                    this.eachItem(function (item) {
                        out[item.boxLabel] = item.checked ? 1 : 0;
                    });
                    return Ext.encode(out);
                },
                setValueForItem: function (val) {
                    var json = Ext.decode(val) || {};
                    this.eachItem(function (item) {
                        if (json[item.boxLabel]) {
                            item.setValue(true);
                        }
                    });
                }
            }
        ]
    });

    return AIR2.Outcome.Summary;
};
