/***************
 * Query Activity Panel
 */
AIR2.Inquiry.Annotations = function () {
    var addbtn,
        annotationPanel,
        annotationUrl,
        editConfig,
        editPanel;

    annotationUrl = AIR2.Inquiry.URL + '/annotation';

    annotationPanel = new AIR2.UI.AnnotationPanel({
        valueField: 'inqan_value',
        creField: 'inqan_cre_dtim',
        updField: 'inqan_upd_dtim',
        winTitle: 'Query Annotations',
        storeData: AIR2.Inquiry.ANNOTDATA,
        url: annotationUrl,
        modalAdd: 'Add Annotation',
        collapsible: true
    });

    editConfig = annotationPanel.editModal;

    editConfig.title = 'Annotations';
    editConfig.allowEdit = true;
    editConfig.autoHeight = true;
    editConfig.url = annotationUrl;
    editConfig.items.url = annotationUrl;

    addbtn = {
        xtype: 'air2button',
        air2type: 'NEW2',
        itemId: 'win-btn-add',
        iconCls: 'air2-icon-add-small',
        text: 'New',
        handler: function (button, event) {
            editPanel.items.each(function (item) {
                item.fireEvent('addclicked');
                AIR2.APP.syncSize();
            });
        },
        scope: this
    };

    editConfig.tools = ['->', addbtn];

    editPanel = new AIR2.UI.Panel(editConfig);

    editPanel.on('afterrender', function (panel) {
        var dv, refreshCount, store;

        dv = panel.getDataView();
        store = dv.getStore();

        refreshCount = function (store) {
            var tab, tabIndex;

            tabIndex = AIR2.Inquiry.Cards.items.indexOf(panel);
            tab = AIR2.Inquiry.Tabs.items.itemAt(tabIndex);
            tab.updateTabTotal(tab, store.getCount());
        };

        // update tab count
        store.on('load', refreshCount);
        store.on('write', refreshCount);

        if (AIR2.APP) {
            AIR2.APP.syncSize();
        }
    });

    return editPanel;

};
