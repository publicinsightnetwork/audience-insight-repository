/***************
 * Organization Summary Panel
 */
AIR2.Organization.Summary = function () {
    var mayUpdateMaxUsers,
        orgnamefld,
        orgpanel,
        orgpanelTemplate;

    // must be sysadmin to update max users
    mayUpdateMaxUsers = (AIR2.USERINFO.type === 'S');

    // org_name only editable by system
    orgnamefld = {
        xtype: 'displayfield',
        fieldLabel: 'Short Name',
        name: 'org_name'
    };
    if (AIR2.USERINFO.type === 'S') {
        orgnamefld.xtype = 'air2remotetext';
        orgnamefld.remoteTable = 'organization';
        orgnamefld.autoCreate = {tag: 'input', type: 'text', maxlength: '32'};
        orgnamefld.maxLength = 32;
        orgnamefld.maskRe = /[a-z0-9_\-]/;
        orgnamefld.allowBlank = false;
        orgnamefld.msgTarget = 'under';
    }

    orgpanelTemplate = new Ext.XTemplate(
        '<tpl for="."><div class="air2-org-info clearfix">' +
          '<div id="air2-org-info-left">' +
            '<div id="air2-org-info-logo">{[AIR2.Format.orgLogo(values)]}</div>' +
          '</div> ' +
          '<div id="air2-org-info-profile"><h1>{org_display_name}</h1>' +
            '{[this.orgStatus(values)]}' +
            
            '<ul>' +
              '<li>{[AIR2.Format.orgName(values)]} {[this.orgLocation(values)]}</li>' +
              '<li>{[this.orgLinks(values)]}</li>' +
              '<li style="margin-top: 10px;"><b>Summary</b><br />' +
                '{[AIR2.Format.orgSummary(values)]}' +
              '</li>' +
              '<li style="margin-top: 10px;"><b>Description</b><br />' +
                '{[AIR2.Format.orgDescription(values)]}' +
              '</li>' +
              '<li style="margin-top: 10px;"><b>Welcome message</b><br />' +
                '{[this.orgWelcomeMsg(values)]}' +
              '</li>' +
            '</ul>' +

            '<table class="meta">' +
              '<tr>' +
                '<td style="width: 150px;"><b>Short Name</b></td>' +
                '<td>{org_name}</td>' +
              '</tr>' +
              '<tr>' +
                '<td><b>Suppress Welcome message</b></td>' +
                '<td>{[this.orgSuppressWelcome(values)]}</td>' +
              '</tr>' +
              '<tr>' +
                '<td><b>Seats Used</b></td>' +
                '<td>{[this.orgSeats(values)]}</td>' +
              '</tr>' +
              '<tpl if="parent"><tr>' +
                '<td><b>Parent Organization</b></td>' +
                '<td>{[AIR2.Format.orgNameLong(values.parent, true)]}</td>' +
              '</tr></tpl>' +
              '<tr>' +
                '<td><b>Created by</b></td>' +
                '<td>' +
                  '{[AIR2.Format.userName(values.CreUser, true, true)]} on ' +
                  '{[AIR2.Format.date(values.org_cre_dtim)]}' +
                '</td>' +
              '</tr>' +
            '</table>' +
          '</div>' +
        '</div></tpl>',
        {
            compiled: true,
            disableFormats: true,
            orgSeats: function (vals) {
                if (vals.org_max_users < 0) {
                    return vals.active_users + ' of Unlimited';
                }
                else {
                    return vals.active_users + ' of ' + vals.org_max_users;
                }
            },
            orgStatusLink: function (org, org_status) {
                if (org_status === 'Published') {
                    org_status = '<a href="' + AIR2.MYPIN2_URL +
                        '/en/newsroom/' + org.org_name + '">' + org_status +
                        '</a>';
                }
                return org_status;
            },
            orgWebsiteLink: function (vals) {
                var n = 'Website';
                if (vals.org_site_uri) {
                    n = '<a class="external" target="_blank" href="' +
                        vals.org_site_uri + '">' + Website + '</a>';
                }
                return n;
            },
            orgWelcomeMsg: function(values) {
                var t = '(none)';
                if (values.org_welcome_msg) {
                    t = values.org_welcome_msg;
                }
                return t;
            },
            orgSuppressWelcome: function(values) {
                var b = 'false';
                if (values.org_suppress_welcome_email_flag) {
                    b = 'true';
                }
                return b;
            },
            orgLinks: function (values) {
                var links = '';
                if (values.org_site_uri) {
                    links = links + '<a class="external" target="_blank" href="' +
                        values.org_site_uri + '">Website</a>' +
                        '<span style="color: #ddd;"> | </span>';
                }
                //Logger(values.org_status);
                if (values.org_status === 'P' || values.org_status === 'Published') {
                    links += '<a href="' + AIR2.MYPIN2_URL +
                        '/en/newsroom/' + values.org_name + '"> Newsroom Page' + 
                        '</a>' +
                        '<span style="color: #ddd;"> | </span>';
                }
                if (values.org_email) {
                    links += '<a href="mailto:'+values.org_email+'">'+values.org_email+'</a>';
                }
                return links;
            },
            orgLocation: function (vals) {
                var location = [];
                if (vals.org_address) {
                    location.push(vals.org_address);
                }
                if (vals.org_city) {
                    location.push(vals.org_city);
                }
                if (vals.org_state) {
                    location.push(vals.org_state);
                }
                if (vals.org_zip) {
                    location.push(vals.org_zip);
                }
                return location.join(', ');
            },
            orgStatus: function (values) {
                var status = AIR2.Format.codeMaster("org_status", values.org_status);
                var statusString = '<span class="'+status.toLowerCase()+'">';
                statusString = statusString + this.orgStatusLink(values, status) + '</span>';
                return statusString;
            }
        }
    );

    // build panel
    orgpanel = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Organization Profile',
        iconCls: 'air2-icon-organization',
        storeData: AIR2.Organization.BASE,
        url: AIR2.HOMEURL + '/organization',
        itemSelector: '.air2-org-info',
        tpl: orgpanelTemplate,
        listeners: {
            // set faketext in the fileupload fields
            beforeedit: function (form, rs) {
                var ban, f, logo, rec;

                f = form.getForm();
                rec = rs[0];
                if (rec.data.Logo) {
                    logo = f.findField('logo');
                    logo.setRawValue(' ' + rec.data.Logo.img_file_name);
                }
                if (rec.data.Banner) {
                    ban = f.findField('banner');
                    ban.setRawValue(' ' + rec.data.Banner.img_file_name);
                }
            },
            // handle ajax file-upload
            validate: function (panel) {
                var bann, form, logo, setBann, setLogo;

                form = panel.getForm();
                logo = panel.getForm().findField('logo');
                bann = panel.getForm().findField('banner');

                setLogo = logo.getValue() && logo.getValue().charAt(0) !== ' ';
                setBann = bann.getValue() && bann.getValue().charAt(0) !== ' ';

                // set form to just upload the file - callback for other saves
                if (setLogo || setBann) {
                    form.el.set({enctype: 'multipart/form-data'});

                    // disable non-file fields (and unused files)
                    form.items.each(function (f) {
                        var keep =
                            (setLogo && f === logo) ||
                            (setBann && f === bann);
                        if (!keep) {
                            f.disable();
                        }
                    });

                    // ajax-submit file form
                    form.submit({
                        url: AIR2.Organization.URL + '.json',
                        params: {
                            'x-force-content': 'text/html',
                            'x-tunneled-method': 'PUT'
                        },
                        success: function (form, action) {
                            logo.reset();
                            bann.reset();
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });
                            form.items.each(function (f) {
                                if (
                                    mayUpdateMaxUsers ||
                                    f.name !== 'org_max_users'
                                ) {
                                    f.enable();
                                }
                            });

                            // quiet-update images
                            var rec = orgpanel.store.getAt(0);
                            rec.data.Logo = action.result.radix.Logo;
                            rec.data.Banner = action.result.radix.Banner;

                            // unmask, refresh, and fire regular-save
                            panel.el.unmask();
                            orgpanel.getDataView().refresh();
                            orgpanel.endEditInPlace(true);
                        },
                        failure: function (form, action) {
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
                            bann.reset();
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });
                            form.items.each(function (f) {
                                if (
                                    mayUpdateMaxUsers ||
                                    f.name !== 'org_max_users'
                                ) {
                                    f.enable();
                                }
                            });
                            panel.el.unmask();
                        }
                    });

                    // defer any saving until the upload finishes
                    panel.el.mask('Uploading...');
                    return false;
                }
                else {
                    return true;
                }
            }
        },
        allowEdit: AIR2.Organization.BASE.authz.may_manage,
        editInPlace: [{
            xtype: 'container',
            layout: 'column',
            items: [{
                xtype: 'container',
                columnWidth: 0.5,
                layout: 'form',
                style: 'padding-right:10px',
                items: [{
                    xtype: 'fieldset',
                    title: 'Settings',
                    defaults: {msgTarget: 'under'},
                    items: [orgnamefld, {
                        xtype: 'air2remotetext',
                        fieldLabel: 'Name',
                        name: 'org_display_name',
                        remoteTable: 'organization',
                        allowBlank: false,
                        width: 200,
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '128'
                        },
                        maxLength: 128
                    }, {
                        xtype: 'air2combo',
                        fieldLabel: 'Status',
                        name: 'org_status',
                        width: 100,
                        choices: AIR2.Fixtures.CodeMaster.org_status
                    }, {
                        xtype: 'air2combo',
                        fieldLabel: 'Max Users',
                        name: 'org_max_users',
                        disabled: !mayUpdateMaxUsers,
                        width: 100,
                        forceSelection: false,
                        editable: true,
                        choices: AIR2.Organization.ORGMAXLIST
                    }]
                }, {
                    xtype: 'fieldset',
                    title: 'Images',
                    defaults: {msgTarget: 'under'},
                    items: [{
                        xtype: 'fileuploadfield',
                        fieldLabel: 'Logo',
                        name: 'logo',
                        allowBlank: true
                    }, {
                        xtype: 'box',
                        html: 'Please upload a square .jpg or .png file at least 400px by 400px. We will display this image on newsroom, reporter and insight pages.',
                        id: 'logo-instructions'
                    }, {
                        xtype: 'fileuploadfield',
                        fieldLabel: 'Banner',
                        name: 'banner',
                        allowBlank: true
                    }]
                }]
            }, {
                xtype: 'container',
                columnWidth: 0.5,
                layout: 'form',
                items: [{
                    xtype: 'fieldset',
                    title: 'Display',
                    defaults: {msgTarget: 'under', width: 200},
                    items: [{
                        xtype: 'trigger',
                        fieldLabel: 'Hex Color',
                        name: 'org_html_color',
                        onTriggerClick: function (e) {
                            var fld, menu;

                            fld = this;
                            menu = new Ext.menu.ColorMenu({
                                handler: function (cm, color) {
                                    fld.setValue(color);
                                }
                            });
                            menu.show(fld.el, 'tl-bl?');
                        }
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'Website',
                        name: 'org_site_uri',
                        vtype: 'url'
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'Summary',
                        name: 'org_summary',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '255'
                        },
                        maxLength: 255
                    }, {
                        xtype: 'textarea',
                        fieldLabel: 'Description',
                        name: 'org_desc'
                    }, {
                        xtype: 'textarea',
                        fieldLabel: 'Welcome message',
                        name: 'org_welcome_msg'
                    }, {
                        xtype: 'checkbox',
                        name: 'org_suppress_welcome_email_flag',
                        fieldLabel: 'Suppress Welcome Email',
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'Email',
                        name: 'org_email'
                    },{
                        xtype: 'textfield',
                        fieldLabel: 'Street Address',
                        name: 'org_address'
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'City',
                        name: 'org_city'
                    }, {
                        xtype: 'air2combo',
                        fieldLabel: 'State',
                        name: 'org_state',
                        choices: AIR2.Fixtures.States,
                        tpl:
                            '<tpl for=".">' +
                                '<div class="x-combo-list-item">' +
                                    '{display}' +
                                '</div>' +
                            '</tpl>',
                        displayField: 'value',
                        listAlign: ['tr-br?', [16, 0]],
                        listWidth: 120,
                        width: 68,
                        editable: true,
                        typeAhead: true
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'Postal Code',
                        name: 'org_zip'
                    }]
                }]
            }]
        }]
    });
    return orgpanel;
};
