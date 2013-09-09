Ext.ns('AIR2.EmailSearch');
/***************
 * ye Email Search/Index/List/Directory page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.EmailSearch = function () {
    var app, t;

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            columnLayout: '3',
            items: [
                AIR2.EmailSearch.List(),
            ]
        })
    });

    app.setLocation({
        iconCls: 'air2-icon-email',
        type: 'Emails',
        title: 'Search'
    });
};
