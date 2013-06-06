Ext.ns('AIR2.User');
/***************
 * User creation modal window
 *
 * Opens a modal window allowing the creation of new users.
 *
 * @function AIR2.User.Create
 * @cfg {HTMLElement}   originEl
 * @cfg {Boolean}       redirect    (def: false)
 * @cfg {Function}      callback
 * @cfg {String}        orgUUID     (def: show picker)
 *
 */
AIR2.User.Create = function (cfg) {
    var email,
        flds,
        fname,
        lname,
        orgbox,
        parms,
        rolebox,
        rolechoices,
        tip,
        type,
        uname,
        w;

    uname = {
        xtype: 'air2remotetext',
        fieldLabel: 'Username',
        name: 'user_username',
        remoteTable: 'user',
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    };

    fname = {
        fieldLabel: 'First Name',
        name: 'user_first_name',
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    };

    lname = {
        fieldLabel: 'Last Name',
        name: 'user_last_name',
        autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
        maxLength: 64
    };

    email = {
        xtype: 'air2remotetext',
        fieldLabel: 'Email',
        name: 'uem_address',
        vtype: 'email',
        remoteTable: 'useremail',
        uniqueErrorText: 'Email already in use',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255
    };

    type = {
        xtype: 'air2combo',
        fieldLabel: 'User Type',
        name: 'user_type',
        width: 80,
        choices: [['A', 'AIR User'], ['S', 'System User']],
        value: 'A'
    };

    // actual fields depend on sys-vs-regular user

    if (AIR2.USERINFO.type === 'S') {
        flds = [uname, email, fname, lname, type];
    }
    else {
        email.fieldLabel = 'Username/Email';
        cfg.labelWidth = 100;
        cfg.width = 330;
        flds = [email, fname, lname];
    }

    // org-chooser
    if (cfg.orgUUID) {
        orgbox = new Ext.form.DisplayField({
            fieldLabel: 'Home',
            name: 'org_uuid',
            html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
            plugins: {
                init: function (fld) {
                    Ext.Ajax.request({
                        url: AIR2.HOMEURL + '/organization/' + cfg.orgUUID +
                            '.json',
                        success: function (resp, opts) {
                            var data,
                                max,
                                remain,
                                savebtn;

                            data = Ext.decode(resp.responseText);
                            fld.setValue(data.radix.org_display_name);

                            // disable if not enough orgs
                            max    = parseInt(data.radix.org_max_users, 10);
                            remain = max - parseInt(
                                data.radix.active_users,
                                10
                            );
                            if (max >= 0 && remain < 1) {
                                fld.ownerCt.items.each(function (item) {
                                    item.setDisabled(item !== fld);
                                });
                                fld.markInvalid('Max Users reached!');
                                savebtn = w.get(0).bottomToolbar.get(0);
                                savebtn.disable();
                            }
                        }
                    });
                }
            },
            getValue: function () {
                return cfg.orgUUID;
            }
        });
    }
    else {
        parms = {sort: 'org_display_name asc'};
        if (AIR2.USERINFO.type !== 'S') {
            parms.role = 'M'; // manager role
        }
        orgbox = new AIR2.UI.SearchBox({
            fieldLabel: 'Home Org',
            name: 'org_uuid',
            cls: 'air2-magnifier',
            allowBlank: false,
            width: 280,
            msgTarget: 'under',
            searchUrl: AIR2.HOMEURL + '/organization',
            pageSize: 10,
            baseParams: parms,
            valueField: 'org_uuid',
            displayField: 'org_display_name',
            emptyText: 'Search Orgs (Manager role)',
            listEmptyText:
                '<div style="padding:4px 8px">' +
                    'No Organizations Found' +
                '</div>',
            formatComboListItem: function (values) {
                return values.org_display_name;
            },
            getErrors: function () {
                var act,
                    errs,
                    max,
                    rec,
                    remain;

                errs = AIR2.UI.SearchBox.superclass.getErrors.call(this);
                if (errs.length) {
                    return errs;
                }
                else if (AIR2.USERINFO.type !== 'S') {
                    // determine if more users can be added
                    rec = this.store.getAt(this.selectedIndex);
                    max = parseInt(rec.data.org_max_users, 10);
                    act = parseInt(rec.data.active_users, 10);
                    remain = max - act;
                    if (max >= 0 && remain < 1) {
                        return ['Max Users reached!'];
                    }
                }
                return errs;
            }
        });
    }
    flds.push(orgbox);

    // role-chooser
    rolechoices = [];
    Ext.each(AIR2.Fixtures.AdminRole, function (ar) {
        if (ar.ar_status === 'A') {
            rolechoices.push([ar.ar_code, ar.ar_name]);
        }
    });
    rolebox = new AIR2.UI.ComboBox({
        fieldLabel: 'Role',
        name: 'ar_code',
        width: 80,
        choices: rolechoices,
        value: 'R'
    });
    flds.push(rolebox);

    // support article
    tip = AIR2.Util.Tipper.create({id: 20502042, cls: 'lighter', align: 15});

    // create form window
    w = new AIR2.UI.CreateWin(Ext.apply({
        title: 'Create User ' + tip,
        iconCls: 'air2-icon-user',
        formItems: flds,
        postUrl: AIR2.HOMEURL + '/user.json',
        postParams: function (f) {
            return f.getFieldValues();
        },
        postCallback: function (success, data, raw) {
            if (cfg.callback) {
                cfg.callback(success, data);
                w.close();
            }
            if (success && cfg.redirect) {
                location.href = AIR2.HOMEURL + '/user/' + data.radix.user_uuid;
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
    return w;
};
