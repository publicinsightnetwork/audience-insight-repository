/***************
 * Home Imports Panel
 */
AIR2.Home.Imports = function () {
    var canUpload,
        editTemplate,
        editTemplateOptions,
        p,
        pTemplate,
        pTemplateOptions,
        tip,
        tipLight,
        upload;

    canUpload = AIR2.Util.Authz.has('ACTION_IMPORT_CSV');

    // upload csv
    upload = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-upload',
        tooltip: 'Upload CSV',
        hidden: !canUpload,
        handler: function () {
            var w = AIR2.Upload.Modal({originEl: this.el});
            w.on('close', function () {
                p.reload();
            });
        }
    });

    pTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
            '<th class="right fixw"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
            '<th class="fixw"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="import-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.tank_cre_dtim)]}' +
                    '</td>' +
                    '<td class="forcewrap">' +
                        '{[AIR2.Format.tankName(values,true)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.tankStatus(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Created</span></th>' +
                '<th><span>File Name</span></th>' +
                '<th><span>Uploaded By</span></th>' +
                '<th><span>Organizations</span></th>' +
                '<th class="fixw"><span>Status</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="import-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.dateLong(values.tank_cre_dtim)]}' +
                    '</td>' +
                    '<td class="forcewrap" style="max-width:200px">' +
                        '{[AIR2.Format.tankName(values,true)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.userName(values.User,1,1)]}</td>' +
                    '<td>{[this.formatOrgs(values)]}</td>' +
                    '<td style="white-space:nowrap;">' +
                        '{[AIR2.Format.tankStatus(values,0,1)]}' +
                    '</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit"></button>' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatOrgs: function(values) {
                if (values.TankOrg && values.TankOrg.length) {
                    var str = '';
                    for (var i=0; i<values.TankOrg.length; i++) {
                        if (i < 2) {
                            var org = values.TankOrg[i].Organization;
                            str += AIR2.Format.orgName(org, 1) + ' ';
                        }
                        else {
                            var remain = values.TankOrg.length - i;
                            str += '+ '+remain+' more';
                            break;
                        }
                    }
                    return str;
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    // support article
    tip = AIR2.Util.Tipper.create(20978401);
    tipLight = AIR2.Util.Tipper.create({
        id: 20978401,
        cls: 'lighter',
        align: 15
    });

    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'CSV Imports ' + tip,
        cls: 'air2-home-import',
        iconCls: 'air2-icon-upload',
        tools: ['->', upload],
        showTotal: true,
        showHidden: false,
        url: AIR2.HOMEURL + '/tank',
        baseParams: { type: 'C' },
        storeData: AIR2.Home.IMPDATA,
        itemSelector: '.import-row',
        tpl: pTemplate,
        editModal: {
            title: 'CSV Imports ' + tipLight,
            allowAdd: false,
            width: 900,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.HOMEURL + '/tank',
                baseParams: { type: 'C' },
                multiSort: 'tank_cre_dtim desc, tank_name asc',
                itemSelector: '.import-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                allowDelete: function(rec) {
                    var me, st;
                    st = rec.data.tank_status;
                    me = AIR2.USERINFO.uuid;
                    if ((st == 'N') && rec.data.User.user_uuid == me) {
                        return true;
                    }
                    return false;
                },
                tpl: editTemplate
            }
        }
    });

    return p;
};
