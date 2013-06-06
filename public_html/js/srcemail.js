Ext.ns('AIR2.SrcEmail');
/***************
 * Manage Source Emails page
 */
AIR2.SrcEmail = function () {
    /* create the application */
    var app = new AIR2.UI.App({
        cls: 'air2-manage-emails',
        items: new AIR2.UI.PanelGrid({
            columnLayout: '3',
            items: [
                AIR2.SrcEmail.List()
                //AIR2.SrcEmail.Stats(),
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-sources',
        type: 'Administration'
    });
};
