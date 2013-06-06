Ext.ns('AIR2.Directory');
/***************
 * Directory page
 */
AIR2.Directory = function () {
    /* create the application */
    var app = new AIR2.UI.App({
        columnLayout: '21',
        items: new AIR2.UI.PanelGrid({
            items: [
                AIR2.Directory.Directory(),
                AIR2.Directory.Users(),
                AIR2.Directory.Organizations()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-directory',
        type: 'Directory'
    });
};
