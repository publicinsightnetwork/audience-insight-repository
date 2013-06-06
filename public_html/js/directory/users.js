/***************
 * Directory Users Panel
 */
AIR2.Directory.Users = function () {
    var template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
            '<th class="fixw"><span>Home</span></td>' +
          '</tr>' +
          '<tpl for="."><tr class="user-row">' +
            '<td class="date right">' +
                '{[AIR2.Format.date(values.user_cre_dtim)]}' +
            '</td>' +
            '<td>{[AIR2.Format.userName(values, true)]}</td>' +
            '<td>{[this.formatHome(values)]}</td>' +
          '</tr></tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatHome: function (src) {
                if (src.org_uuid) {
                    return AIR2.Format.orgName(src, true);
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Newest Users',
        cls: 'air2-directory-users',
        iconCls: 'air2-icon-user',
        showTotal: false,
        url: AIR2.HOMEURL + '/user',
        storeData: AIR2.Directory.USERNEW,
        itemSelector: '.user-row',
        tpl: template
    });
};
