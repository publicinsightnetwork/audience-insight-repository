/***************
 * Home Emails Panel
 */
AIR2.Home.Emails = function () {
    var canCreate,
        create,
        tpl;

    canCreate = AIR2.Util.Authz.has('ACTION_EMAIL_CREATE');

    // create email
    create = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-add',
        tooltip: 'Create Email',
        hidden: !canCreate,
        handler: function () {
            AIR2.Email.Create({
                originEl: this.el,
                redirect: true
            });
        }
    });

    tpl = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Created</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>Status</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="email-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.email_cre_dtim)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.emailName(values,1,30)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.emailStatus(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    AIR2.Home.Emails = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Emails',
        cls: 'air2-home-emails',
        iconCls: 'air2-icon-email',
        tools: ['->', create],
        showTotal: true,
        showHidden: false,
        showAllLink: AIR2.HOMEURL + '/email',
        url: AIR2.HOMEURL + '/email',
        storeData: AIR2.Home.EMAILDATA,
        itemSelector: '.email-row',
        tpl: tpl
    });

    return AIR2.Home.Emails;
};
