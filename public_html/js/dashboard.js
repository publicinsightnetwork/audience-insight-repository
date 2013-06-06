Ext.ns('AIR2.Dashboard');
/***************
 * Dashboard (reporting)
 */
AIR2.Dashboard = function () {
    var app, items;

    items = [];
    Ext.each(AIR2.Dashboard.ORGDATA, function (orgdata) {
        var disp, uuid;

        uuid = orgdata.radix.org_uuid;
        disp = orgdata.radix.org_display_name;

        items.push(AIR2.Dashboard.Stats(uuid, disp));
        items.push(AIR2.Dashboard.Summary(orgdata));
    });

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            items: items
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-dashboard',
        type: 'Dashboard'
    });
};
