/***************
 * Query Activity Panel
 */
AIR2.Inquiry.Activity = function () {
    var panel, template;

    template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<table class="air2-tbl">' +
            '</table>' +
        '</tpl>',
        {
            compiled: true
        }
    );

    // panel
    panel = new AIR2.UI.Panel({
        allowEdit: false,
        collapsible: true,
        colspan: 2,
        editInPlace: [], //TODO: form elements for editing go here
        emptyText: '<div class="air2-panel-empty"><h3>Loading...</h3></div>',
        iconCls: 'air2-icon-activity',
        id: 'air2-inquiry-activity',
        itemSelector: '.air2-tbl',
        rowspan: 3,
        showTotal: false,
        showHidden: false,
        title: 'Activity',
        tpl: template
    });


    return panel;
};
