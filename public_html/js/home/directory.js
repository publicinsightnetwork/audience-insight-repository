/***************
 * Home Directory Panel
 */
AIR2.Home.Directory = function () {
    var dir, orgdir, usrdir, template;
    // directory links
    dir = AIR2.HOMEURL + '/directory';
    usrdir = '<a href="' + dir + '#user">' + AIR2.Home.USRCOUNT +
        '&nbsp;Users</a>';
    orgdir = '<a href="' + dir + '#organization">' + AIR2.Home.ORGCOUNT +
    '&nbsp;Organizations</a>';

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Name</span></th>' +
                '<th><span>Title</span></th>' +
                '<th><span>Organization</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="directory-row">' +
                    '<td>{[AIR2.Format.userName(values,1,1)]}</td>' +
                    '<td>{[this.formatTitle(values)]}</td>' +
                    '<td>{[this.formatOrg(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatTitle: function (values) {
                if (values.uo_user_title) {
                    if (values.uo_user_title &&
                        values.uo_user_title.length
                    ) {
                        return values.uo_user_title;
                    }
                }
                return '<span class="lighter">(none)</span>';
            },
            formatOrg: function (values) {
                if (values.org_uuid) {
                    var org = AIR2.Format.orgName(values, 1);
                    return org;
                }
                return '';
            }
        }
    );

    // build panel
    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Directory',
        iconCls: 'air2-icon-directory',
        showTotal: false,
        total: usrdir + ' | ' + orgdir,
        showHidden: false,
        showAllLink: AIR2.HOMEURL + '/directory',
        storeData: AIR2.Home.USERDATA,
        itemSelector: '.directory-row',
        tpl: template
    });
};
