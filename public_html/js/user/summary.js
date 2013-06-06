/***************
 * User Summary Panel
 */
AIR2.User.Summary = function () {
    var canManageOrg,
        isAdmin,
        isManager,
        isOwner,
        send_email_btn,
        url_name,
        user_status,
        useremail,
        userPanel,
        userPanelTemplate;

    isAdmin = (AIR2.USERINFO.type === "S");
    isManager = AIR2.User.BASE.authz.may_manage;
    isOwner = (AIR2.USERINFO.uuid === AIR2.User.UUID);
    canManageOrg = function (uuid) {
        return AIR2.Util.Authz.has('ACTION_ORG_USR_UPDATE', uuid);
    };

    useremail = AIR2.User.BASE.radix.uem_address;
    send_email_btn = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-email',
        tooltip: 'Send Password Email',
        hidden: !(isAdmin || isManager || isOwner) || !useremail,
        handler: function () {
            var rec, uem;

            rec = userPanel.store.getAt(0);
            uem = rec.data.uem_address ? rec.data.uem_address : '';
            Ext.Msg.show({
                title: 'Send Password Email',
                iconCls: 'air2-icon-email',
                animEl: send_email_btn.el,
                closable: false,
                msg: 'Send email to ' + uem + '?',
                buttons: Ext.Msg.OKCANCEL,
                fn: function (bid) {
                    if (bid === 'ok') {
                        AIR2.Auth.sendUserPassword(uem);
                    }
                }
            });
        }
    });

    userPanelTemplate = new Ext.XTemplate(
        '<tpl for="."><table class="air2-user-info"><tr>' +
            '<td class="photo" valign="top">' +
                '{[AIR2.Format.userPhoto(values)]}' +
            '</td>' +
            '<td class="info">' +
                '<ul>' +
                    '<li>{[this.formatUserName(values)]}</li>' +
                    '<tpl if="user_type === \'S\'">' +
                        '<li>System User</li>' +
                    '</tpl>' +
                    '<li class="employer">' +
                        '{[this.formatHome(values)]}' +
                    '</li>' +
                    '<li class="email">' +
                        '{[this.formatEmail(values)]}' +
                    '</li>' +
                    '<li class="phone">' +
                        '{[this.formatPhone(values)]}' +
                    '</li>' +
                    '<tpl if="user_summary">' +
                        '<li class="summary"><b>Short Bio</b> <span style="color: #bbb;">(255 characters)</span><br />{user_summary}</li>' +
                    '</tpl>' +
                    '<tpl if="user_desc">' +
                        '<li class="desc"><b>Long Bio</b><br />{user_desc}</li>' +
                    '</tpl>' +
                     '<tpl if="user_login_dtim">' +
                         '<li class="login_date">' +
                             '<b>Last Login: </b>' +
                             '{[AIR2.Format.dateLong(values.user_login_dtim)]}' +
                         '</li>' +
                     '</tpl>' +
                '</ul>' +
            '</td>' +
        '</tr></table></tpl>',
        {
            compiled: true,
            disableFormats: true,
            mayEdit: AIR2.User.BASE.authz.may_write,
            formatUserName: function (values) {
                var user_name, user_status;

                user_name = AIR2.Format.userName(values, false, true);

                user_status = AIR2.Format.codeMaster(
                    'user_status',
                    values.user_status
                );
                if (user_status === 'Published' || user_status.toLowerCase() === 'p') {
                    url_name = AIR2.Format.urlify(
                        AIR2.Format.userName(values, false, true)
                    );
                    user_status = '<a href="' + AIR2.MYPIN2_URL + '/en/people/';
                    user_status += values.user_uuid + '/' + url_name + '">Published</a>';
                }

                return '<b>' + user_name + '</b> ' + user_status;

            },
            formatHome: function (values) {
                if (values.org_uuid) {
                    var str = 'at ' + AIR2.Format.orgNameLong(values, true);
                    if (values.uo_user_title) {
                        str = '<b>' + values.uo_user_title + '</b> ' + str;
                    }
                    return str;
                }
                return '<b class="lighter">(no home organization)</b>';
            },
            formatEmail: function (values) {
                var href, str;
                if (values.uem_address) {
                    str = AIR2.Format.userEmail(values, true);
                    if (AIR2.User.BASE.authz.may_write) {
                        href = AIR2.User.PWDURL;
                        str += ' (<a class="change-password external" ';
                        str += 'target="_blank"';
                        str += ' href="' + href + '">change password</a>)';
                    }
                    return str;
                }
                return '<b class="lighter">(no email)</b>';
            },
            formatPhone: function (values) {
                if (values.uph_number) {
                    return AIR2.Format.userPhone(values);
                }
                return '<b class="lighter">(no phone)</b>';
            }
        }
    );

    userPanel = new AIR2.UI.Panel({
        storeData: AIR2.User.BASE,
        url: AIR2.HOMEURL + '/user',
        colspan: 2,
        title: "User Profile",
        tools: ['->', send_email_btn],
        iconCls: 'air2-icon-user',
        itemSelector: '.air2-user-info',
        tpl: userPanelTemplate,
        listeners: {
            beforeedit: function (form, rs) {
                var avat, cb, currentOrg, f, isManager, rec, title, u;

                f = form.getForm();
                rec = rs[0];

                // disable org/title fields
                cb = form.find('name', 'org_uuid')[0];
                cb.selectOrDisplay(
                    rec.data.org_uuid,
                    rec.data.org_display_name
                );
                title = form.find('name', 'uo_user_title')[0];

                // load org combobox store
                currentOrg = rec.data.org_uuid;
                cb.store.load({callback: function () {
                    // for non-owners/admins, only show mayManage
                    if (!isOwner && !isAdmin) {
                        cb.store.each(function (r) {
                            u = r.data.org_uuid;
                            if (u !== currentOrg && !canManageOrg(u)) {
                                cb.store.remove(r);
                            }
                        });
                    }

                    // enable/disable home picker
                    if (currentOrg) {
                        isManager = AIR2.Util.Authz.has(
                            'ACTION_ORG_USR_UPDATE',
                            currentOrg
                        );
                        if (isOwner || isAdmin || isManager) {
                            cb.enable();
                            title.enable();
                        }
                    }
                    else {
                        if (cb.store.getCount() > 0) {
                            cb.enable();
                            title.enable();
                        }
                    }
                }});

                // set faketext in the fileupload field
                if (rec.data.Avatar) {
                    avat = f.findField('avatar');
                    avat.setRawValue(' ' + rec.data.Avatar.img_file_name);
                }
            },
            aftersave: function (panel, rs) {
                Ext.getCmp('air2-app').setLocation({
                    title: AIR2.Format.userName(rs[0].data, false, true)
                });
                this.title = rs[0].data;
                userPanel.getDataView().refresh();
                userPanel.endEditInPlace(true);
            },
            validate: function (panel) {
                var avat, form;

                form = panel.getForm();
                avat = panel.getForm().findField('avatar');
                if (avat.getValue() && avat.getValue().charAt(0) !== ' ') {
                    // set form to just upload the file
                    form.el.set({enctype: 'multipart/form-data'});
                    form.items.each(function (f) {
                        if (f !== avat) {
                            f.disable();
                        }
                    });

                    form.submit({
                        url: AIR2.User.URL + '.json',
                        params: {
                            'x-force-content': 'text/html',
                            'x-tunneled-method': 'PUT'
                        },
                        success: function (form, action) {
                            avat.reset(); // reset form
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });
                            form.items.each(function (f) { f.enable(); });

                            // quiet-update avatar
                            var rec = userPanel.store.getAt(0);
                            rec.data.Avatar = action.result.radix.Avatar;

                            // unmask, refresh, and fire regular-save
                            panel.el.unmask();
                            userPanel.getDataView().refresh();
                            userPanel.endEditInPlace(true);
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
                            avat.reset();
                            form.el.set({
                                enctype: 'application/x-www-form-urlencoded'
                            });
                            form.items.each(function (f) { f.enable(); });
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
        allowEdit: AIR2.User.BASE.authz.may_write,
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
                    title: 'User Profile',
                    defaults: {
                        msgTarget: 'under',
                        xtype: 'textfield'
                    },
                    items: [{
                        xtype: 'air2remotetext',
                        fieldLabel: 'Login Name',
                        name: 'user_username',
                        allowBlank: false,
                        // TODO nuance for New user?
                        disabled: isAdmin ? false : true,
                        remoteTable: 'user',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '64'
                        },
                        maxLength: 64
                    }, {
                        fieldLabel: 'First Name',
                        name: 'user_first_name',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '64'
                        },
                        maxLength: 64
                    }, {
                        fieldLabel: 'Last Name',
                        name: 'user_last_name',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '64'
                        },
                        maxLength: 64
                    }, {
                        xtype: 'air2combo',
                        fieldLabel: 'Type',
                        name: 'user_type',
                        width: 100,
                        disabled: isAdmin ? false : true,
                        choices: [['S', 'System User'], ['A', 'AIR User']]
                    }, {
                        xtype: 'air2combo',
                        fieldLabel: 'Status',
                        name: 'user_status',
                        width: 100,
                        disabled: isManager ? false : true,
                        choices: AIR2.Fixtures.CodeMaster.user_status
                    }]
                }, {
                    xtype: 'fieldset',
                    title: 'Contact Information',
                    defaults: {msgTarget: 'under'},
                    items: [{
                        xtype: 'air2remotetext',
                        fieldLabel: 'Email',
                        name: 'uem_address',
                        allowBlank: false,
                        vtype: 'email',
                        emptyText: 'None Provided',
                        remoteTable: 'useremail',
                        uniqueErrorText: 'Email already in use',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '255'
                        },
                        maxLength: 255
                    }, {
                        xtype: 'compositefield',
                        fieldLabel: 'Phone',
                        id: 'phonecomp',
                        name: 'uph_number',
                        validateOnBlur: true,
                        defaults: {
                            listeners: {
                                change: function () {
                                    Ext.getCmp('phonecomp').validateValue();
                                }
                            }
                        },
                        setValue: function (v) {
                            var s = v ? v.split('-') : '';
                            s = (s.length === 3) ? s : [null, null, null];
                            this.items.get(1).setValue(s[0]);
                            this.items.get(3).setValue(s[1]);
                            this.items.get(4).setValue(s[2]);
                        },
                        getValue: function () {
                            var i, s;

                            i = this.items;
                            s = [
                                i.get(1).getValue(),
                                i.get(3).getValue(),
                                i.get(4).getValue()
                            ];
                            if (s.join('').length > 0) {
                                return s.join('-');
                            }
                            return '';
                        },
                        validateValue: function () {
                            var p = this.getValue();
                            if (p.length === 12 || p.length === 0) {
                                this.clearInvalid();
                                return true;
                            }
                            else {
                                this.markInvalid('Invalid phone number');
                                return false;
                            }
                        },
                        items: [
                            {xtype: 'displayfield', value: '('},
                            {
                                xtype: 'textfield',
                                name: 'phone1',
                                width: 29,
                                autoCreate: {
                                    tag: 'input',
                                    type: 'text',
                                    maxlength: '3'
                                }
                            },
                            {xtype: 'displayfield', value: ')'},
                            {
                                xtype: 'textfield',
                                name: 'phone2',
                                width: 29,
                                margins: '0 5 0 0',
                                autoCreate: {
                                    tag: 'input',
                                    type: 'text',
                                    maxlength: '3'
                                }
                            },
                            {
                                xtype: 'textfield',
                                name: 'phone3',
                                width: 48,
                                autoCreate: {
                                    tag: 'input',
                                    type: 'text',
                                    maxlength: '4'
                                }
                            },
                            {
                                xtype: 'displayfield',
                                value: 'ext',
                                margins: '3 5 0 5'
                            },
                            {xtype: 'textfield', name: 'uph_ext', width: 29}
                        ]
                    }]
                }, {
                    xtype: 'fieldset',
                    title: 'Images',
                    items: [{
                        xtype: 'fileuploadfield',
                        fieldLabel: 'Avatar',
                        name: 'avatar',
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
                    style: 'margin:0',
                    items: [{
                        xtype: 'air2searchbox',
                        fieldLabel: 'Home Org',
                        name: 'org_uuid',
                        disabled: true,
                        searchUrl: AIR2.User.URL + '/organization',
                        valueField: 'org_uuid',
                        displayField: 'org_display_name',
                        width: 250,
                        hideTrigger: false
                    }, {
                        xtype: 'textfield',
                        fieldLabel: 'Job Title',
                        name: 'uo_user_title',
                        disabled: true,
                        emptyText: 'not set',
                        width: 250,
                        maxLength: 255
                    }, {
                        xtype: 'textarea',
                        fieldLabel: 'Short Bio',
                        name: 'user_summary',
                        width: 250,
                        height: 90,
                        maxLength: 255
                    }, {
                        xtype: 'textarea',
                        fieldLabel: 'Full Bio',
                        name: 'user_desc',
                        width: 250,
                        height: 148
                    }]
                }]
            }]
        }]
    });
    return userPanel;
};
