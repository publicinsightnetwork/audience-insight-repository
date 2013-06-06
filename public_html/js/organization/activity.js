/***************
 * Organization Activity Panel
 */
AIR2.Organization.Activity = function () {
    var template, editTemplate;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          //'<tr>' +
            //'<th><span>Description</span></th>' +
            //'<th style="width:40px"><span>Date</span></th>' +
          //'</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="activity-row">' +
              '<td>{[AIR2.Util.Activity.formatOrg(values)]}</td>' +
              '<td class="date">{[AIR2.Format.dateLong(values.dtim)]}</td>' +
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
            '<th><span>Description</span></th>' +
            '<th style="width:40px"><span>Date</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="activity-row">' +
              '<td>{[AIR2.Util.Activity.formatOrg(values)]}</td>' +
              '<td class="date">{[AIR2.Format.dateLong(values.dtim)]}</td>' +
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
        title: 'Recent Activity',
        showTotal: true,
        iconCls: 'air2-icon-activity',
        storeData: AIR2.Organization.ACTVDATA,
        url: AIR2.Organization.URL + '/activity',
        itemSelector: '.activity-row',
        tpl: template,
        editModal: {
            allowAdd: false,
            width: 600,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/activity',
                // no sorting... applied by server
                itemSelector: '.activity-row',
                tpl: editTemplate
            }
        }
    });
};
