Ext.ns('AIR2.Organization');
/***************
 * Organization page
 */
AIR2.Organization = function () {
    /* create the application */
    var app = new AIR2.UI.App({
        columnLayout: '21',
        items: new AIR2.UI.PanelGrid({
            items: [
                AIR2.Organization.Summary(),
                AIR2.Organization.Projects(),

                // disable the stats panel per #1813
                // to re-enable need to shuffle the 2 blocks
                // of code below to preserve ordering
                /*
                AIR2.Dashboard.Stats(
                    AIR2.Organization.ORGDATA.radix.org_uuid,
                    'Stats'
                ),
                AIR2.Organization.Children(),
                AIR2.Organization.Users(),
                AIR2.Organization.Inquiries(),
                AIR2.Organization.Activity(),
                */
                AIR2.Organization.Users(),
                AIR2.Organization.Children(),
                AIR2.Organization.Activity(),
                AIR2.Organization.Inquiries(),
                AIR2.Organization.Outcomes(),
                AIR2.Organization.Sources(),
                AIR2.Organization.SysIds(),
                AIR2.Organization.Networks()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-organization',
        type: 'Organization',
        typeLink: AIR2.HOMEURL + '/directory#organizations',
        title: AIR2.Organization.BASE.radix.org_display_name
    });
};
