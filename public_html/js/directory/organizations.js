/***************
 * Directory Organizations Panel
 */
AIR2.Directory.Organizations = function () {
    var template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
          '</tr>' +
          '<tpl for="."><tr class="org-row">' +
            '<td class="date right">' +
                '{[AIR2.Format.date(values.org_cre_dtim)]}' +
            '</td>' +
            '<td>{[AIR2.Format.orgNameLong(values,true)]}</td>' +
          '</tr></tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Newest Organizations',
        cls: 'air2-directory-orgs',
        iconCls: 'air2-icon-organization',
        showTotal: false,
        url: AIR2.HOMEURL + '/organization',
        storeData: AIR2.Directory.ORGNEW,
        itemSelector: '.org-row',
        tpl: template
    });
};
