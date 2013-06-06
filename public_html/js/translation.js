Ext.ns('AIR2.Translation');
/***************
 * Manage Translations page
 */
AIR2.Translation = function () {
    /* create the application */
    var app = new AIR2.UI.App({
        columnLayout: '21',
        items: new AIR2.UI.PanelGrid({
            items: [
                AIR2.Translation.List(),
                AIR2.Translation.NewPanel()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-translation',
        type: 'Manage Translations'
    });
};
