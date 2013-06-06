/***************
 * Organization Inquiries Panel
 */
AIR2.Organization.Inquiries = function () {
    var template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Title</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="inq-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.inq_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.inquiryTitle(values,1)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Queries',
        showTotal: true,
        showAllLink: AIR2.Organization.INQSRCH,
        iconCls: 'air2-icon-inquiry',
        storeData: AIR2.Organization.INQDATA,
        url: AIR2.Organization.URL + '/inquiry',
        itemSelector: '.inq-row',
        tpl: template
    });
};
