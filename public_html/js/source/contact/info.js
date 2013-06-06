Ext.ns('AIR2.Source.Contact');
/***************
 * Source Contact Modal - Source Info tab
 *
 * @class AIR2.Source.Contact.Info
 * @extends Ext.form.FormPanel
 * @xtype air2srcconinfo
 *
 */
AIR2.Source.Contact.Info = function (cfg) {
    var fldtype, moreTemplate;

    cfg = cfg || {};

    // displayfields if non-editable
    fldtype = AIR2.Source.BASE.authz.may_write ? 'textfield' : 'displayfield';

    moreTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<p>' +
                'Created by ' +
                '{[AIR2.Format.userName(values.CreUser, true)]} ' +
                'on {[AIR2.Format.dateLong(values.src_cre_dtim)]}' +
            '</p>' +
            '<p>' +
                'Updated by {[AIR2.Format.userName(values.UpdUser, true)]} ' +
                'on {[AIR2.Format.dateLong(values.src_upd_dtim)]}' +
            '</p>' +
            '{[this.formatLock(values)]}' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatLock: function (values) {
                if (values.src_has_acct === 'Y') {
                    return '<p><span class="air2-source-locked"></span>' +
                        'Profile locked via <a href="' + AIR2.MYPIN2_URL +
                        '/en/admin/index?filter=' + values.src_username +
                        '"><b>SOURCE&#8482;</b> Account</a></p>';
                }
                return '';
            }
        }
    );

    cfg.items = [
        {
            xtype: 'fieldset',
            cls: 'air2-source-infoprimary',
            title: 'Primary',
            layout: 'column',
            items: [
                {
                    xtype: 'container',
                    columnWidth: 0.54,
                    layout: 'form',
                    labelWidth: 76,
                    defaults: {width: 170},
                    items: [
                        {
                            xtype: 'displayfield',
                            fieldLabel: 'Username',
                            name: 'src_username',
                            allowBlank: false
                        },
                        {
                            xtype: fldtype,
                            fieldLabel: 'First Name',
                            name: 'src_first_name'
                        },
                        {
                            xtype: fldtype,
                            fieldLabel: 'Last Name',
                            name: 'src_last_name'
                        },
                        {
                            xtype: fldtype,
                            fieldLabel: 'Middle Initial',
                            name: 'src_middle_initial'
                        }
                    ]
                },
                {
                    xtype: 'container',
                    columnWidth: 0.46,
                    layout: 'form',
                    labelWidth: 70,
                    defaults: {width: 158},
                    items: [
                        {
                            xtype: fldtype,
                            fieldLabel: 'Pre Name',
                            name: 'src_pre_name'
                        },
                        {
                            xtype: fldtype,
                            fieldLabel: 'Post Name',
                            name: 'src_post_name'
                        },
                        {
                            fieldLabel: 'Status',
                            name: 'src_status',
                            xtype: 'displayfield',
                            width: 130,
                            setRawValue: function (v) {
                                var disp;

                                if (this.rendered) {
                                    this.charValue = v;
                                    disp = AIR2.Format.codeMaster(
                                        'src_status',
                                        v
                                    );
                                    this.el.dom.innerHTML = disp;
                                }
                                else {
                                    this.value = v;
                                }
                            },
                            getRawValue: function (v) {
                                return this.charValue;
                            }
                        },
                        {
                            xtype: 'air2button',
                            style: 'padding-left: 76px',
                            air2type: 'SAVE',
                            air2size: 'MEDIUM',
                            text: 'SAVE',
                            hidden: true,
                            scope: this,
                            handler: function () {
                                var f, n, r;

                                f = this.getForm(),
                                r = this.srcRecord;
                                if (f.isValid()) {
                                    f.updateRecord(r);
                                    n = r.store.save();
                                    if (n > -1) {
                                        r.store.on(
                                            'save',
                                            function () {
                                                this.setSrcRecord(r);
                                            },
                                            this,
                                            {
                                                single: true
                                            }
                                        );
                                    }
                                }
                            }
                        }
                    ]
                }
            ]
        },
        {
            xtype: 'fieldset',
            cls: 'air2-source-infomore',
            title: 'More',
            tpl: moreTemplate
        }
    ];

    // call parent constructor
    cfg.monitorValid = AIR2.Source.BASE.authz.may_write;
    AIR2.Source.Contact.Info.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.Source.Contact.Info, Ext.form.FormPanel, {
    plain: true,
    padding: '10px 15px 10px 15px',
    layout: 'form',
    monitorValid: true,
    listeners: {
        clientvalidation: function (form, valid) {
            if (!form.saveBtn) {
                form.saveBtn = form.findByType('air2button')[0];
            }
            if (form.getForm().isDirty()) {
                form.saveBtn.show();
            }
            else {
                form.saveBtn.hide();
            }
        }
    },
    setSrcRecord: function (r) {
        var f = this.getForm();
        this.srcRecord = r;
        f.trackResetOnLoad = true;
        f.loadRecord(r);
        this.get(1).update(r.data);
    }
});
Ext.reg('air2srcconinfo', AIR2.Source.Contact.Info);
