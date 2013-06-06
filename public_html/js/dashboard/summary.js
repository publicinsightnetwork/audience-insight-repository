/***************
 * Stats panel
 */
AIR2.Dashboard.Summary = function (data) {
    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Summary',
        cls: 'air2-dashboard-summary',
        iconCls: 'air2-icon-summary',
        showTotal: true,
        showHidden: false,
        storeData: data,
        hidden: true,
        itemSelector: '.stat-row',
        tpl: new Ext.XTemplate(
            '<tpl for=".">' +
             '<span>{org_display_name} ({org_name})</span>' +
            '</tpl>'
        )
    });
};
