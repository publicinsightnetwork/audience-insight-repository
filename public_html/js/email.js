Ext.ns('AIR2.Email');
/***************
 * Email page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.Email = function () {
    var app, t;

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            columnLayout: '21',
            items: [
                AIR2.Email.Content(),
                AIR2.Email.Summary(),
                AIR2.Email.Stats(),
                AIR2.Email.Inquiries()
            ]
        })
    });

    t = Ext.util.Format.ellipsis(
        AIR2.Email.BASE.radix.email_campaign_name,
        60,
        true
    );

    app.setLocation({
        iconCls: 'air2-icon-email',
        type: 'Email',
        typeLink: AIR2.HOMEURL + '/email',
        title: t
    });
};
