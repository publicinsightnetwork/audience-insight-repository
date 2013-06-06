/***************
 * Organization Networks Panel
 */
AIR2.Organization.Networks = function () {
    var editTemplate,
        template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th><span>Type</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="network-row">' +
              '<td>' +
                '<a class="external" target="_blank" href="{ouri_value}">' +
                  '{[AIR2.Format.codeMaster("ouri_type",values.ouri_type)]}' +
                '</a>' +
              '</td>' +
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
            '<th><span>Type</span></th>' +
            '<th><span>Link</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="network-row">' +
              '<td>' +
                '{[AIR2.Format.codeMaster("ouri_type",values.ouri_type)]}' +
              '</td>' +
              '<td>' +
                '<a class="external" target="_blank" href="{ouri_value}">' +
                  '{ouri_value}' +
                '</a>' +
              '</td>' +
              '<td class="row-ops">' +
                '<button class="air2-rowedit"></button>' +
                '<button class="air2-rowdelete"></button>' +
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
        colspan: 1,
        title: 'Links',
        showTotal: true,
        collapsed: true,
        iconCls: 'air2-icon-link',
        storeData: AIR2.Organization.NETDATA,
        url: AIR2.Organization.URL + '/network',
        itemSelector: '.network-row',
        tpl: template,
        modalAdd: 'Add Link',
        editModal: {
            title: 'Organization Links',
            allowAdd: AIR2.Organization.BASE.authz.may_write,
            width: 600,
            height: 300,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/network',
                multiSort: 'ouri_handle asc',
                newRowDef: {},
                allowEdit: AIR2.Organization.BASE.authz.may_write,
                allowDelete: AIR2.Organization.BASE.authz.may_write,
                itemSelector: '.network-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        link,
                        linkEl,
                        type,
                        typeEl;

                    edits = [];
                    typeEl = Ext.fly(node).first('td');
                    typeEl.update('');
                    type = new AIR2.UI.ComboBox({
                        allowBlank: false,
                        choices: AIR2.Fixtures.CodeMaster.ouri_type,
                        width: 100,
                        renderTo: typeEl,
                        value: rec.data.ouri_type
                    });
                    edits.push(type);

                    linkEl = typeEl.next().update('');
                    link = new Ext.form.TextField({
                        allowBlank: false,
                        vtype: 'url',
                        width: 320,
                        renderTo: linkEl,
                        value: rec.data.ouri_value
                    });
                    edits.push(link);
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('ouri_type', edits[0].getValue());
                    rec.set('ouri_value', edits[1].getValue());
                }
            }
        }
    });
};
