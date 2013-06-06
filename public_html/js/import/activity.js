/***************
 * Import Activity/Project Panel
 */
AIR2.Import.Activity = function () {
    var template, templateOptions;

    template = '<tpl for=".">' +
        '<table class="activity air2-tbl">' +
            // no orgs
            '<tpl if="values.TankOrg.length == 0">' +
                '<tr>' +
                    '<td class="label">Organizations</td>' +
                    '<td class="value">' +
                        '<span class="lighter">(none)</span>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
            // tank_orgs
            '<tpl for="TankOrg">' +
                '<tr>' +
                    '<td class="label">' +
                        '<tpl if="xindex == 1">Organizations</tpl>' +
                    '</td>' +
                    '<td class="value">{[this.formatOrg(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
            // no activity
            '<tpl if="values.TankActivity.length == 0">' +
                '<tr>' +
                    '<td class="label">Activities</td>' +
                    '<td class="value">' +
                        '<span class="lighter">(none)</span>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
            // tank_activity
            '<tpl for="TankActivity">' +
                '<tr>' +
                    '<td class="label">' +
                        '<tpl if="xindex == 1">Activities</tpl>' +
                    '</td>' +
                    '<td class="value">{[this.formatActivity(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>' +
    '</tpl>';

    templateOptions = {
        compiled: true,
        disableFormats: true,
        formatOrg: function (values) {
            var org, stat;

            org = AIR2.Format.orgNameLong(values.Organization, true);
            stat = AIR2.Format.codeMaster('so_status', values.to_so_status);

            return org + ' - ' + stat;
        },
        formatActivity: function (values) {
            var str = '<b>' + values.ActivityMaster.actm_name + '</b>';
            str += '<p>' + AIR2.Format.date(values.tact_dtim) + '</p>';
            str += '<p>' + AIR2.Format.projectName(values.Project, 1) + '</p>';
            return str;
        }
    };


    return new AIR2.UI.Panel({
        title: 'Import Activity',
        cls: 'air2-import-activity',
        iconCls: 'air2-icon-activity',
        colspan: 1,
        storeData: AIR2.Import.BASE,
        url: AIR2.HOMEURL + '/tank',
        itemSelector: '.activity',
        tpl: new Ext.XTemplate(template, templateOptions)
    });
};
