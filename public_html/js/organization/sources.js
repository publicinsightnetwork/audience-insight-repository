/***************
 * Home Source Panel
 */
AIR2.Organization.Sources = function () {
    var mayAdd,
        source,
        template;

    mayAdd = AIR2.Util.Authz.has(
        'ACTION_ORG_SRC_CREATE',
        AIR2.Organization.UUID
    );

    // create source
    source = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-add',
        tooltip: 'New source',
        hidden: !mayAdd,
        handler: function () {
            AIR2.Source.Create({
                originEl: this.el,
                org_uuid: AIR2.Organization.UUID,
                redirect: true
            });
        }
    });

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Created</span></th>' +
            '<th><span>Name</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="source-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.Source.src_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.sourceName(values.Source,1,1)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    // create panel
    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Sources',
        iconCls: 'air2-icon-source',
        showTotal: true,
        showAllLink: AIR2.Organization.SRCSRCH,
        collapsed: true,
        tools: ['->', source],
        storeData: AIR2.Organization.SRCDATA,
        itemSelector: '.source-row',
        tpl: template
    });
};
