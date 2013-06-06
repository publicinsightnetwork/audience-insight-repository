/***************
 * Query edit tabs
 *
 *
 * AIR2.Inquiry.EditEditTabView
 *
 */

AIR2.Inquiry.EditTabView = function () {
    var authorizationsPanel,
        fieldsPanel,
        header,
        settingsPanel;

    settingsPanel = AIR2.Inquiry.Settings();
    authorizationsPanel = AIR2.Inquiry.Authorizations();
    fieldsPanel = AIR2.Inquiry.Fields();

    AIR2.Inquiry.EditTabView = new Ext.TabPanel({
        activeTab: 0,
        autoDestroy: false,
        autoHeight: true,
        border: false,
        items: [
            {
                autoHeight: true,
                columnLayout: '3',
                items: [
                    settingsPanel,
                    authorizationsPanel,
                    {
                        collapsible: true,
                        colspan: 3,
                        iconCls: 'air2-icon-tag',
                        storeData: AIR2.Inquiry.TAGDATA,
                        tagMasterUrl: AIR2.HOMEURL + '/tag',
                        title: 'Public Tags',
                        url: AIR2.Inquiry.URL + '/tag',
                        xtype: 'air2tagpanel'
                    }
                ],
                noHeader: true,
                title: 'Settings',
                xtype: 'air2pgrid'
            },
            fieldsPanel
        ],
        layoutOnTabChange: true,
        resizeTabs: true,
        unstyled: true
    });

    header = Ext.get('air2-headerwrap', true);

    AIR2.Inquiry.EditTabView.on(
        'afterrender',
        function () {
            AIR2.Util.Pinner(
                AIR2.Inquiry.EditTabView,
                header,
                header.getHeight()
            );
        }
    );

    return AIR2.Inquiry.EditTabView;

};
