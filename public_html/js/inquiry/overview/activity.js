/***************
 * Query Activity Panel
 */
AIR2.Inquiry.Activity = function () {
    var editTemplate,
        template;

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
                        '{[AIR2.Format.date(values.ia_dtim)]}' +
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
                        '{[AIR2.Format.dateLong(values.ia_dtim)]}' +
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

    AIR2.Inquiry.ActivityPanel = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Activity',
        showTotal: true,
        iconCls: 'air2-icon-activity',
        storeData: AIR2.Inquiry.ACTIVDATA,
        url: AIR2.Inquiry.URL + '/activity',
        itemSelector: '.activity-row',
        tpl: template,
        editModal: {
            width: 600,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Inquiry.URL + '/activity',
                multiSort: 'ia_dtim desc',
                itemSelector: '.activity-row',
                tpl: editTemplate
            }
        }
    });
    
    return AIR2.Inquiry.ActivityPanel;
};
