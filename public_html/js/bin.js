Ext.ns('AIR2.Bin');
/***************
 * Bin page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.Bin = function () {

    /* create the application */
    var app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            columnLayout: '21',
            columnWidths: [0.75, 0.25],
            items: [
                AIR2.Bin.Contents(),
                AIR2.Bin.Summary(),
                AIR2.Bin.Exports()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-bin',
        type: 'Bin',
        title: AIR2.Bin.BASE.radix.bin_name
    });
};
