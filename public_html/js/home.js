Ext.ns('AIR2.Home');
/***************
 * Home page
 */
AIR2.Home = function () {
    var app, items;

    // setup panels
    items = [
        AIR2.Home.Directory(),
        AIR2.Home.Imports(),
        AIR2.Home.Inquiries(),
        AIR2.Home.SavedSearches()
    ];

    // are there alerts?
    if (AIR2.Home.ALERTDATA.radix.length > 0) {
        items.splice(0, 0, AIR2.Home.Alerts());
        items.splice(2, 0, AIR2.Home.Projects());
    }
    else {
        items.splice(0, 0, AIR2.Home.Projects());
        items[0].rowspan = 2;
    }

    // can user create emails?
    if (AIR2.Util.Authz.has('ACTION_EMAIL_CREATE')) {
        items.splice(1, 0, AIR2.Home.Emails());
        items[0].rowspan++;
    }

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            items: items
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-home',
        type: 'Home'
    });
};
