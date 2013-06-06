/***************
 * Organization Children Panel
 */
AIR2.Organization.Children = function () {
    var child,
        editTemplate,
        mayCreate,
        p,
        template;

    // allow child creation - hidden for now per #1993
    mayCreate = (AIR2.USERINFO.type === 'S');
    //var mayCreate = AIR2.Organization.BASE.authz.may_manage;

    // create child org button
    child = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-add',
        tooltip: 'New Child Organization',
        hidden: !mayCreate,
        handler: function () {
            AIR2.Organization.Create({
                originEl: p.el,
                parentUUID: AIR2.Organization.UUID,
                callback: function (success, msg) {
                    if (success) {
                        p.reload();
                    }
                }
            });
        }
    });

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th><span>Name</span></th>' +
            '<th style="width:40px"><span>Users</span></th>' +
            //'<th><span>Created</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="org-row">' +
              '<td>{[AIR2.Format.orgNameLong(values,1)]}</td>' +
              '<td>{active_users}</td>' +
              //'<td>{[AIR2.Format.date(values.org_cre_dtim)]}</td>' +
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
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Users</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="org-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.org_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.orgNameLong(values,1)]}</td>' +
              '<td>{usr_count}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    // create panel
    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Child Organizations',
        iconCls: 'air2-icon-organization',
        tools: ['->', child],
        showTotal: true,
        storeData: AIR2.Organization.CHILDDATA,
        url: AIR2.Organization.URL + '/child',
        itemSelector: '.org-row',
        tpl: template,
        editModal: {
            title: 'Child Organizations',
            allowAdd: false,
            width: 550,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/child',
                multiSort: 'org_display_name asc',
                itemSelector: '.org-row',
                tpl: editTemplate
            }
        }
    });
    return p;
};
