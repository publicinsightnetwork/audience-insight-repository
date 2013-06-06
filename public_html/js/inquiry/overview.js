/***********************
 * Inquiry Summary Panel
 */
AIR2.Inquiry.Overview = function () {

    AIR2.Inquiry.Overview = new AIR2.UI.PanelGrid({
        autoHeight: true,
        columnLayout: '21',
        items: [
            {
                colspan: 2,
                autoHeight: true,
                id: 'air2-inquiry-overview-main',
                items: [
                    AIR2.Inquiry.Summary(),
                    AIR2.Inquiry.RecentSubmissions(),
                    AIR2.Inquiry.Activity()
                ],
                rowspan: 3,
                xtype: 'container'
            },
            AIR2.Inquiry.Statistics(),
            {
                collapsible: true,
                colspan: 1,
                iconCls: 'air2-icon-tag',
                storeData: AIR2.Inquiry.TAGDATA,
                tagMasterUrl: AIR2.HOMEURL + '/tag',
                title: 'Public Tags',
                url: AIR2.Inquiry.URL + '/tag',
                xtype: 'air2tagpanel'
            },
        ],
        tabTip: 'Query Overview',
        title: 'Overview',
    });
    return AIR2.Inquiry.Overview;
};
