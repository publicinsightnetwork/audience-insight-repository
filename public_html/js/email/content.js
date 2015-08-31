/***************
 * Email Content Panel
 *
 * email_from_name
 * email_from_email
 * email_subject_line
 * Logo
 * email_headline
 * email_body
 * UserSignature
 *
 */
AIR2.Email.Content = function() {
    var contentTemplate, mayEdit, dupbutton;

    // editing authz/state
    mayEdit = AIR2.Email.BASE.authz.may_write &&
        (AIR2.Email.BASE.radix.email_status == 'D');

    contentTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
          '<div class="content-row">' +
            // name/email and subject_line
            '<div class="eml-subject">' +
              '<div class="from">' +
                '<span class="label">From:</span>' +
                '<span class="name">{email_from_name}</span>' +
                '<span class="addr">&lt;{email_from_email}&gt;</span>' +
              '</div>' +
              '<div class="subj">' +
                '<span class="label">Subject:</span>' +
                '<span class="line">{email_subject_line}</span>' +
              '</div>' +
            '</div>' +
            // email content
            '<div class="eml-content">' +
             '<table>' +
              '<tr>' +
               '<td>' +
              '<tpl if="Logo">' +
                '<div class="logo">' +
                  '{[AIR2.Format.emailLogo(values)]}' +
                '</div>' +
              '</tpl>' +
              '</td>' +
              '<td>' +
              '<div class="headline">' +
                '<h2>{email_headline}</h2>' +
              '</div>' +
              '</td>' +
             '</tr>' +
            '</table>' +
              '<div class="body">' +
                '{email_body}' +
              '</div>' +
              '<div class="signature">' +
                '{usig_text}' +
              '</div>' +
            '</div>' +
          '</div>' +
        '</tpl>',
        {
            compiled: true
        }
    );

    // user-signature choices
    var usigRawText = {};
    var usigChoices = [[null, 'New Signature']];
    var usigStore = new AIR2.UI.APIStore({data: AIR2.Email.SIGDATA});
    var sanitize = function(t) {
        var f = Ext.util.Format;

        // ext has a bad html-decoder, so jump through some hoops
        var tmpEl = Ext.get(document.createElement('div'));
        tmpEl.update(f.stripTags(t.replace(/&nbsp;/g, ' ')));
        return f.ellipsis(tmpEl.dom.innerHTML, 40);
    }
    usigStore.each(function(rec) {
        usigRawText[rec.get('usig_uuid')] = rec.get('usig_text');
        usigChoices.push([rec.get('usig_uuid'), sanitize(rec.get('usig_text'))]);
    });

    var existingSig = [AIR2.Email.BASE.radix.usig_uuid,AIR2.Email.BASE.radix.usig_text];
    if (existingSig[0] && !usigStore.getById(existingSig[0])) {
        //Logger('current email sig not assigned to current user');
        usigChoices.push([existingSig[0], sanitize(existingSig[1])]);
        usigRawText[existingSig[0]] = existingSig[1];
    }

    // duplicate the email content
    dupbutton = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-duplicate',
        text: 'Duplicate',
        handler: function () {
            AIR2.Email.Create({
                duplicate: AIR2.Email.Content.store.getAt(0),
                originEl: dupbutton.el,
                redirect: true
            });
        }
    });

    // build panel
    AIR2.Email.Content = new AIR2.UI.Panel({
        storeData: AIR2.Email.BASE,
        url: AIR2.Email.URL,
        colspan: 2,
        rowspan: 3,
        title: 'Contents',
        cls: 'air2-email-content',
        iconCls: 'air2-icon-email',
        itemSelector: '.content-row',
        tpl: contentTemplate,
        allowEdit: mayEdit,
        setEditable: function (allow) {
            AIR2.Email.Content.tools.items.last().setVisible(allow);
        },
        tools: [dupbutton],
        labelWidth: 90,
        editInPlace: [{
            xtype: 'fieldset',
            title: 'Subject',
            defaults: {msgTarget: 'under'},
            items: [{
                xtype: 'compositefield',
                fieldLabel: 'From',
                buildCombinedErrorMessage: function(errs) {
                    var msg = [];
                    Ext.each(errs, function(item,idx,all) {
                        if (item.field == 'email_from_name') {
                            item.field = 'Name';
                        }
                        else if (item.field == 'email_from_email') {
                            item.field = 'Email';
                        }
                        msg.push(item.field + ': ' + item.error);
                    });
                    return msg.join("<br/>");
                },
                items: [{
                    xtype: 'textfield',
                    fieldLabel: 'Name',
                    emptyText: 'Your Name',
                    name: 'email_from_name',
                    width: 180,
                    allowBlank: false,
                    autoCreate: {
                        tag: 'input',
                        type: 'text',
                        maxlength: '255'
                    },
                    disabled: false
                },{
                    xtype: 'displayfield',
                    cls: 'email-left-arrow',
                    value: '<'
                },{
                    xtype: 'textfield',
                    fieldLabel: 'Email',
                    emptyText: 'youremail@yourdomain',
                    name: 'email_from_email',
                    cls: 'email-from-email',
                    vtype: 'email',
                    width: 180,
                    allowBlank: false,
                    autoCreate: {
                        tag: 'input',
                        type: 'text',
                        maxlength: '255'
                    },
                    disabled: false
                },{
                    xtype: 'displayfield',
                    cls: 'email-right-arrow',
                    value: '>'
                }]
            },{
                xtype: 'textfield',
                fieldLabel: 'Subject Line',
                emptyText: 'The subject line for your email',
                name: 'email_subject_line',
                width: 387,
                allowBlank: false,
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    maxlength: '255'
                }
            }]
        },{
            xtype: 'fieldset',
            title: 'Body',
            defaults: {msgTarget: 'under'},
            items: [{
                xtype: 'fileuploadfield',
                fieldLabel: 'Logo',
                name: 'logo',
                width: 160,
                allowBlank: true
            },{
                xtype: 'box',
                html: 'Please upload a square .jpg or .png file at least 400px by 400px.',
                cls: 'logo-instructions'
            },{
                xtype: 'textfield',
                fieldLabel: 'Headline',
                emptyText: 'Your headline here',
                name: 'email_headline',
                width: 387,
                allowBlank: false,
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    maxlength: '255'
                }
            },{
                xtype: 'air2ckeditor',
                fieldLabel: 'Main text',
                emptyText: 'Stylized text for the main part of your email',
                name: 'email_body',
                width: 387
            }],
        },{
            xtype: 'fieldset',
            title: 'Signature',
            defaults: {msgTarget: 'under'},
            items: [{
                id: 'email-sig-picker',
                xtype: 'air2combo',
                fieldLabel: 'Signature',
                name: 'usig_uuid',
                width: 200,
                choices: usigChoices,
                listeners: {
                    select: function (fld, rec, idx) {
                        if (rec.data.value) {
                            var raw = usigRawText[rec.data.value];
                            var editor = Ext.getCmp('email-sig-editor');
                            editor.setValue(raw);
                            editor.setEditorValue(raw);
                            editor.ckEditorInstance.setReadOnly(false);
                        }
                        else {
                            Ext.getCmp('email-sig-editor').setValue('New signature text here');
                        }
                    }
                }
            },{
                id: 'email-sig-editor',
                xtype: 'air2ckeditor',
                fieldLabel: '',
                name: 'usig_text',
                ckEditorConfig: { height: 100 }
            }]
        }],
        listeners: {
            // set faketext in the fileupload fields
            beforeedit: function (form, rs) {
                // disable sending while editing
                AIR2.Email.Summary.getEl().mask('Editing in progress');

                if (rs[0].data.Logo) {
                    logo = form.getForm().findField('logo');
                    logo.setRawValue(' ' + rs[0].data.Logo.img_file_name);
                }

                // no idea why, but need to wait for CK to render to setValue
                setTimeout(function() {
                    var sid = rs[0].data.usig_uuid;
                        Ext.getCmp('email-sig-editor').setValue(usigRawText[sid]);
                    Ext.getCmp('email-sig-editor').setEditorValue(usigRawText[sid]);
                }, 500);
            },
            // update signature combobox with new signatures
            aftersave: function (panel, rs) {
                var sid = rs[0].data.usig_uuid;
                if (!Ext.getCmp('email-sig-picker').store.getById(sid)) {
                    usigRawText[sid] = rs[0].data.usig_text;
                    usigChoices.splice(1, 0, [sid, sanitize(rs[0].data.usig_text)]);
                    Ext.getCmp('email-sig-picker').store.loadData(usigChoices);
                }
                AIR2.Email.Summary.getEl().unmask();
            },
            afteredit: function(panel) {
                AIR2.Email.Summary.getEl().unmask();
            },
            // handle ajax file-upload
            validate: function (panel) {
                var bann, form, logo, setBann, setLogo;

                form = panel.getForm();
                logo = panel.getForm().findField('logo');

                setLogo = logo.getValue() && logo.getValue().charAt(0) !== ' ';

                // set form to just upload the file - callback for other saves
                if (setLogo) {
                    form.el.set({enctype: 'multipart/form-data'});

                    // disable non-file fields (and unused files)
                    form.items.each(function (f) {
                        if (!(f === logo)) f.disable();
                    });

                    // ajax-submit file form
                    form.submit({
                        url: AIR2.Email.URL + '.json',
                        params: {
                            'x-force-content': 'text/html',
                            'x-tunneled-method': 'PUT'
                        },
                        success: function (form, action) {
                            logo.reset();
                            form.el.set({enctype: 'application/x-www-form-urlencoded'});
                            form.items.each(function (f) { f.enable(); });

                            // quiet-update images
                            var rec = AIR2.Email.Content.store.getAt(0);
                            rec.data.Logo = action.result.radix.Logo;

                            // unmask, refresh, and fire regular-save
                            panel.el.unmask();
                            AIR2.Email.Content.refresh();
                            AIR2.Email.Content.endEditInPlace(true);
                        },
                        failure: function (form, action) {
                            var msg = "Unknown error";
                            if (action.result && action.result.message) {
                                msg = action.result.message;
                            }
                            AIR2.UI.ErrorMsg(form.el, "Error uploading file", msg);

                            // reset and unmask
                            logo.reset();
                            form.el.set({enctype: 'application/x-www-form-urlencoded'});
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
    });

    return AIR2.Email.Content;
};
