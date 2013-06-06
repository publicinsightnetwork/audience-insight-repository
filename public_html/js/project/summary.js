/***************
 * Project Summary Panel
 */
AIR2.Project.Summary = function () {
    var prjnamefld, template;

    template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="air2-project-summary">' +
                '<b>{prj_display_name}</b>' +
                '<p>{prj_desc}</p>' +
                '<ul class="air2-project-status">' +
                    '<li>Status</li>' +
                    '{[this.formatStatus(values.prj_status)]}' +
                '</ul>' +
                '<div class="dates">' +
                    '<span class="meta">' +
                        'Created by {[' +
                            'AIR2.Format.userName(values.CreUser, true)' +
                        ']} ' +
                        'on {[AIR2.Format.date(values.prj_cre_dtim)]}' +
                    '</span>' +
                '</div>' +
                '{[this.formatUpdated(values)]}' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatShared: function (isShared) {
                if (isShared) {
                    return '<li class="green">Yes</li>';
                }
                else {
                    return '<li class="red">No</li>';
                }
            },
            formatStatus: function (status) {
                if (status === 'A') {
                    return '<li class="green">Active</li>';
                }
                else {
                    return '<li class="red">Inactive</li>';
                }
            },
            formatUpdated: function (values) {
                var str = '<div class="dates"><span class="meta">';

                if (!values.UpdUser || !values.prj_upd_dtim) {
                    return '';
                }

                str += 'Last updated by ';
                str += AIR2.Format.userName(values.UpdUser, true);
                str += ' on ' + AIR2.Format.date(values.prj_upd_dtim);
                str += '</span></div>';
                return str;
            }
        }
    );

    // prj_name only editable by system
    prjnamefld = {
        xtype: 'displayfield',
        fieldLabel: 'Short Name',
        name: 'prj_name'
    };

    if (AIR2.USERINFO.type === 'S') {
        prjnamefld.xtype = 'air2remotetext';
        prjnamefld.remoteTable = 'project';
        prjnamefld.autoCreate = {tag: 'input', type: 'text', maxlength: '32'};
        prjnamefld.maxLength = 32;
        prjnamefld.maskRe = /[a-z0-9_\-]/;
        prjnamefld.allowBlank = false;
        prjnamefld.msgTarget = 'under';
    }

    // build panel
    return new AIR2.UI.Panel({
        storeData: AIR2.Project.BASE,
        url: AIR2.HOMEURL + '/project',
        colspan: 1,
        title: 'Summary',
        iconCls: 'air2-icon-clipboard',
        itemSelector: '.air2-project-summary',
        tpl: template,
        allowEdit: AIR2.Project.BASE.authz.may_manage,
        editInPlace: [
            {
                xtype: 'air2remotetext',
                fieldLabel: 'Display Name',
                name: 'prj_display_name',
                remoteTable: 'project',
                autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
                maxLength: 255,
                allowBlank: false,
                msgTarget: 'under'
            },
            prjnamefld,
            {
                xtype: 'textarea',
                fieldLabel: 'Summary',
                name: 'prj_desc',
                height: 100,
                maxLength: 4000
            },
            {
                xtype: 'air2combo',
                fieldLabel: 'Status',
                name: 'prj_status',
                width: 90,
                choices: [['A', 'Active'], ['F', 'Inactive']]
            }
        ] //end editInPlace
    });
};
