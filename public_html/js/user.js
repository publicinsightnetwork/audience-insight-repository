Ext.ns('AIR2.User');
/***************
 * User page
 */
AIR2.User = function () {
    var app, orgs, summary;

    // link summary-saves
    summary = AIR2.User.Summary();
    orgs = AIR2.User.Organizations();
    summary.store.on('save', function () {orgs.reload(); });

    /* create the application */
    app = new AIR2.UI.App({
        columnLayout: '111',
        items: new AIR2.UI.PanelGrid({
            items: [
                summary,
                orgs,
                AIR2.User.Activity(),
                AIR2.User.Networks()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-user',
        type: 'User',
        typeLink: AIR2.HOMEURL + '/directory#users',
        title: AIR2.Format.userName(AIR2.User.BASE.radix, false, true)
    });
};
