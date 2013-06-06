Ext.ns('AIR2.Outcome');
/***************
 * Outcome creation modal window
 *
 * Opens a modal window to allow creating new outcomes
 *
 * @function AIR2.Outcome.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 * @cfg {Object}        prj_obj
 * @cfg {Object}        org_obj
 * @cfg {String}        src_uuid
 * @cfg {String}        inq_uuid
 *
 */
AIR2.Outcome.Create = function (cfg) {
    var flds,
        getPublishableToolTip,
        orgbox,
        pewbox,
        prjbox,
        querybox,
        srccfg,
        w;

    getPublishableToolTip = function () {
        var toolTip, toolTipText;

        toolTipText = 'Compose a headline (20 words or less) and a ' +
            'description, describing how the PIN sources contributed to ' +
            'reporting/content development. Selecting an organization and a ' +
            'query help determine where this PINfluence will show up on ' +
            'publicinsightnetwork.org';
        toolTip = '<span class="air2-tipper" ext:qtip="' +
            toolTipText +
            '" hide="user" show="user">?</span>';

        return toolTip;
    };

    flds = [{
        xtype: 'fieldset',
        title: 'Publishable Fields ' + getPublishableToolTip() + '',
        width: 600,
        defaults: {
            msgTarget: 'under'
        },
        items: [{
            xtype: 'textfield',
            fieldLabel: 'Story Headline',
            allowBlank: false,
            width: 375,
            name: 'out_headline',
            autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
            maxLength: 255
        }, {
            xtype: 'air2remotetext',
            fieldLabel: 'Content Link',
            name: 'out_url',
            allowBlank: true,
            width: 375,
            remoteTable: 'outcome',
            vtype: 'url',
            autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
            maxLength: 255,
            uniqueErrorText: function (data) {
                var h, msg, outuuid;

                msg = 'PINfluence already exists!';
                if (data.conflict && data.conflict.out_url) {
                    outuuid = data.conflict.out_url.out_uuid;
                    h = AIR2.HOMEURL + '/outcome/' + outuuid;
                    msg += ' Check it out <a href="' + h + '">here</a>';
                }
                return msg;
            }
        }, {
            xtype: 'textarea',
            fieldLabel: 'How the PIN influenced this story',
            allowBlank: false,
            width: 375,
            name: 'out_teaser',
            grow: true,
            growMin: 60
        }, {
            xtype: 'datefield',
            fieldLabel: 'Publish/Air/Event Date',
            allowBlank: false,
            width: 100,
            name: 'out_dtim'
        }]
    }, {
        fieldLabel: 'Publish?',
        xtype: 'air2combo',
        name: 'out_status',
        width: 375,
        value: 'A',
        choices: [
            ['A', 'Yes, publish to publicinsightnetwork.org and RSS feed'],
            ['N', 'No']
        ]
    }, {
        xtype: 'air2combo',
        fieldLabel: 'Content Type',
        name: 'out_type',
        width: 100,
        value: 'S',
        choices: [
            ['S', 'Story'],
            ['R', 'Series'],
            ['E', 'Event'],
            ['O', 'Other']
        ]
    }];

    //

    pewbox = {
        xtype: 'textfield',
        fieldLabel: 'Program/Event/Website',
        allowBlank: true,
        width: 375,
        name: 'out_show',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255
    };
    flds[0].items.splice(4, 0, pewbox);
    // organization picker
    orgbox = new AIR2.UI.SearchBox({
        name: 'org_uuid',
        width: 375,
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
        }
    });
    orgbox.on('select', function (box, rec) {
        var prj;

        prjbox.enable().reset();
        prjbox.store.removeAll();
        prjbox.store.baseParams.org_uuid = rec.data.org_uuid;

        // pre-select the default project
        if (rec.data.DefaultProject) {
            prj = rec.data.DefaultProject;
            prjbox.setValue(prj.prj_display_name);
            prjbox.selectRawValue(prj.prj_uuid, prj.prj_display_name);
        }
    });
    flds[0].items.splice(5, 0, orgbox);
    if (cfg.org_obj) {
        orgbox.setValue(cfg.org_obj.org_display_name);
        orgbox.selectRawValue(
            cfg.org_obj.org_uuid,
            cfg.org_obj.org_display_name
        );
    }

    // project picker
    prjbox = new AIR2.UI.SearchBox({
        disabled: true,
        name: 'prj_uuid',
        width: 375,
        cls: 'air2-magnifier',
        fieldLabel: 'Project',
        searchUrl: AIR2.HOMEURL + '/project',
        pageSize: 10,
        baseParams: {
            sort: 'prj_display_name asc'
        },
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        listEmptyText: '<div style="padding:4px 8px">No Projects Found</div>',
        emptyText: 'Search Projects',
        formatComboListItem: function (v) {
            return v.prj_display_name;
        }
    });
    flds[0].items.splice(6, 0, prjbox);
    if (cfg.prj_obj) {
        prjbox.setValue(cfg.prj_obj.prj_display_name);
        prjbox.selectRawValue(
            cfg.prj_obj.prj_uuid,
            cfg.prj_obj.prj_display_name
        );
    }
    if (cfg.org_obj || cfg.prj_obj) {
        prjbox.enable();
    }

    // source picker
    if (cfg.src_uuid) {
        flds.push({
            xtype: 'displayfield',
            fieldLabel: 'Sources',
            name: 'src_uuid',
            width: 375,
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/source/' + cfg.src_uuid + '.json',
                        success: function (resp, opts) {
                            var data, e;

                            data = Ext.decode(resp.responseText);
                            e = data.radix.primary_email;
                            fld.setValue(AIR2.Format.createLink(
                                e,
                                'mailto:' + e,
                                1,
                                1
                            ));
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.src_uuid;
            }
        });
    }
    else {
        srccfg = {
            xtype: 'textarea',
            labelTip: 'List sources’ email addresses, separating multiples ' +
                'with commas',
            allowBlank: true,
            width: 375,
            height: 36,
            invalidClass: '',
            validator: function (value) {
                var em, haseml, i, splits;

                splits = value.split(/[, ]+/);
                haseml = false;
                for (i = 0; i < splits.length; i++) {
                    em = splits[i];
                    em = em.replace(/[\n\r]/);
                    if (em && em.length && !Ext.form.VTypes.email(em)) {
                        return 'Enter a comma-separated list of emails';
                    }
                }
                return true;
            }
        };

        // cited sources
        flds.push(Ext.apply({}, srccfg, {
            name: 'emails_cited',
            fieldLabel: 'Influencing sources named in story'
        }));

        // informing sources
        flds.push(Ext.apply({}, srccfg, {
            name: 'emails',
            fieldLabel: 'Influencing sources not named in story'
        }));
    }

    // source bin
    /*influence =  new AIR2.UI.ComboBox({
        choices: AIR2.Fixtures.CodeMaster.sout_type,
        width: 90,
        allowBlank: true,
        disabled: false,
        listeners: {
            afterrender: function (field) {
                field.allowBlank = true;
            }
        },
    });*/

    influence =  {
        xtype: 'combo',
        autoSelect: true,
        editable: false,
        cls: "influence",
        fieldLabel: 'Bin Influence',
        forceSelection: false,
        name: 'sout_type',
        store: [
            ["I", "Informed"],
            ["C", "Cited"],
            ["F", "Featured"]
        ],
        triggerAction: 'all',
        value: 'I',
        listeners: {
            afterrender: function (field) {
                field.allowBlank = true;
                field.disable();
            }
        },
    },

    binPicker = new AIR2.UI.SearchBox({
        name: 'bin_uuid',
        width: 375,
        allowBlank: true,
        cls: 'air2-magnifier',
        fieldLabel: 'Search bins',
        searchUrl: AIR2.HOMEURL + '/bin',
        forceSelection: false,
        pageSize: 10,
        baseParams: {
            sort: 'bin_name asc',
            type: 'S',
            owner: true
        },  
        valueField: 'bin_uuid',
        displayField: 'bin_name',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Bins Found' +
            '</div>',
        emptyText: 'Search Bins',
        listeners: {
            afterrender: function (field) {
                field.allowBlank = true;
            }
        },
        formatComboListItem: function (v) {
            return v.bin_name;
        }
    }); 

    binPicker.on('select', function (box, rec) {
        var inf = Ext.get(Ext.select('.influence').elements[0]);
        var id = inf.id;
        inf = Ext.getCmp(id);
        inf.enable();
    });

    flds.push(Ext.apply({allowBlank: true}, binPicker,{
        name: 'sources'
    }));

    flds.push(Ext.apply({allowBlank: true}, influence,{
        name: 'sout_type',
        fieldLabel: 'Influence of bin sources'
    }));

    querybox = {};

    // inquiry picker
    if (cfg.inq_uuid) {
        querybox = {
            xtype: 'displayfield',
            fieldLabel: 'Query',
            name: 'inq_uuid',
            width: 375,
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/inquiry/' + cfg.inq_uuid +
                            '.json',
                        success: function (resp, opts) {
                            var data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.inq_ext_title);
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.inq_uuid;
            }
        };
    }
    else {
        querybox = {
            xtype: 'air2searchbox',
            name: 'inq_uuid',
            allowBlank: true,
            width: 375,
            cls: 'air2-magnifier',
            fieldLabel: 'Query',
            searchUrl: AIR2.HOMEURL + '/inquiry',
            pageSize: 10,
            baseParams: {
                sort: 'inq_cre_dtim desc'
            },
            valueField: 'inq_uuid',
            displayField: 'inq_ext_title',
            listEmptyText:
                '<div style="padding:4px 8px">' +
                    'No Queries Found' +
                '</div>',
            emptyText: 'Search Queries',
            formatComboListItem: function (v) {
                return v.inq_ext_title;
            }
        };
    }

    flds[0].items.splice(7, 0, querybox);
    //Additional Information
    flds.push({
        xtype: 'textarea',
        fieldLabel: 'Additional Information',
        allowBlank: true,
        width: 375,
        name: 'out_internal_teaser',
        grow: true,
        growMin: 60
    });

    // survey
    flds.push({
        xtype: 'checkboxgroup',
        fieldLabel: 'PIN Helped to',
        name: 'out_survey',
        allowBlank: true,
        width: 375,
        columns: 1,
        items: [
            {
                boxLabel: 'find authentic voices'
            },
            {
                boxLabel: 'find insight quickly'
            },
            {
                boxLabel: 'get ahead of the news'
            },
            {
                boxLabel: 'identify stories that might have otherwise been ' +
                          'missed'
            },
            {
                boxLabel: 'pursue investigative reporting'
            },
            {
                boxLabel: 'collaborate with another program, project or ' +
                          'newsroom'
            },
            {
                boxLabel: 'define a coverage stream or project'
            },
            {
                boxLabel: 'other'
            }
        ],
        getValue: function () {
            var out = {};
            this.eachItem(function (item) {
                out[item.boxLabel] = item.checked ? 1 : 0;
            });
            return Ext.encode(out);
        }
    });

    // create form window
    w = new AIR2.UI.CreateWin(Ext.apply({
        title: 'Create PINfluence',
        cls: 'air2-outcome-create',
        iconCls: 'air2-icon-outcome',
        labelWidth: 125,
        width: 645,
        height: 550,
        formStyle: 'padding: 10px 0 0 10px',
        formItems: flds,
        postUrl: AIR2.HOMEURL + '/outcome.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            if (cfg.callback) {
                cfg.callback(success, data);
            }
            if (success && !cfg.redirect) {
                w.close();
            }
            if (success && cfg.redirect) {
                w.get(0).el.mask('redirecting');
                location.href = AIR2.HOMEURL + '/outcome/' +
                    data.radix.out_uuid;
            }
        }
    }, cfg));

    // show the window
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else if (cfg.originEl !== false) {
        w.show();
    }


    Ext.util.Observable.capture(w, function ( ) {
        Logger(arguments);
    });

    return w;
};
