/***************
 * Bin Summary Panel
 */
AIR2.Bin.Summary = function () {
    var panelConfig, panel, templateConfig, template;

    templateConfig = {
        compiled: true,
        disableFormats: true,
        formatDesc: function (desc) {
            if (desc && desc.length > 0) {
                return desc;
            }
            else {
                return '<i>(No Description Given)</i>';
            }
        },
        formatShared: function (flag) {
            if (flag) {
                return '<li class="green">Yes</li>';
            }
            else {
                return '<li class="red">No</li>';
            }
        },
        formatNotes: function (stat) {
            if (stat === 'P') {
                return '<li class="green">Enabled</li>';
            }
            else {
                return '<li class="red">Disabled</li>';
            }
        }
    };

    template = new Ext.XTemplate(
        '<tpl for=".">' +
          '<div class="air2-bin-summary">' +
            '<h2 class="title">{bin_name}</h2>' +
            '<p class="desc">{[this.formatDesc(values.bin_desc)]}</p>' +
            // pill-style
            '<ul><li>Shared</li>' +
            '{[this.formatShared(values.bin_shared_flag)]}</ul>' +
            '<ul>' +
                '<li>Notes</li>' +
                '{[this.formatNotes(values.bin_status)]}' +
            '</ul>' +
            // format owner
            '<div class="meta">' +
                'Created by {[AIR2.Format.userName(values.User,1,1)]} ' +
                'on {[AIR2.Format.date(values.bin_cre_dtim)]}' +
            '</div>' +
            // last updated
            '<div class="meta">Last updated on ' +
              '{[AIR2.Format.date(values.bin_upd_dtim)]}</div>' +
          '</div>' +
        '</tpl>',
        templateConfig
    );

    // build panel
    panelConfig = {
        storeData: AIR2.Bin.BASE,
        url: AIR2.Bin.URL,
        colspan: 1,
        title: 'Summary',
        iconCls: 'air2-icon-clipboard',
        itemSelector: '.air2-bin-summary',
        tpl: template,
        listeners: {
            aftersave: function (form, rs) {
                Ext.getCmp('air2-app').setLocation({
                    title: rs[0].get('bin_name')
                });
            }
        },
        allowEdit: AIR2.Bin.BASE.authz.may_manage,
        labelWidth: 60,
        editInPlace: [
            {
                xtype: 'air2remotetext',
                fieldLabel: 'Bin Name',
                name: 'bin_name',
                width: '96%',
                allowBlank: false,
                remoteTable: 'bin',
                autoCreate: {tag: 'input', type: 'text', maxlength: '128'},
                maxLength: 128,
                msgTarget: 'under'
            },
            {
                xtype: 'textarea',
                fieldLabel: 'Summary',
                name: 'bin_desc',
                height: 100,
                maxLength: 4000
            },
            {
                xtype: 'air2combo',
                fieldLabel: 'Shared',
                name: 'bin_shared_flag',
                choices: [[false, 'No'], [true, 'Yes']],
                width: 100
            },
            {
                xtype: 'air2combo',
                fieldLabel: 'Notes',
                tooltip: '',
                name: 'bin_status',
                choices: [['A', 'Disabled'], ['P', 'Enabled']],
                width: 100
            }
        ]
    };

    panel = new AIR2.UI.Panel(panelConfig);

    return panel;
};
