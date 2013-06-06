/***********************
 * Source Activity Panel
 */
AIR2.Source.Activity = function () {
    var template, editTemplate;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          //'<tr>' +
          //  '<th class="fixw right"><span>Date</span></th>' +
          //  '<th><span>Description</span></th>' +
          //'</tr>' +
          // rows
            '<tpl for=".">' +
                '<tr class="activity-row">' +
                    '<td class="fixw date right">' +
                        '{[AIR2.Format.date(values.sact_dtim)]}' +
                    '</td>' +
                    '<td>{[AIR2.Util.Activity.format(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Date</span></th>' +
                '<th><span>Description</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="activity-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.dateLong(values.sact_dtim)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Util.Activity.format(values)]}' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    return new AIR2.UI.Panel({
        colspan: 2,
        rowspan: 1,
        title: 'Activity',
        iconCls: 'air2-icon-activity',
        storeData: AIR2.Source.ACTVDATA,
        url: AIR2.Source.URL + '/activity',
        showTotal: true,
        itemSelector: '.activity-row',
        tpl: template,
        editModal: {
            width: 750,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/activity',
                multiSort: 'sact_dtim desc',
                itemSelector: '.activity-row',
                tpl: editTemplate
            }
        }
    });
};
