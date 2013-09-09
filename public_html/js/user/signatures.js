/***************
 * User Signatures Panel
 */
AIR2.User.Signatures = function () {
    var editTemplate,
        template,
        sanitizeFn;

    sanitizeFn = function(t) {
        var f = Ext.util.Format;

        // ext has a bad html-decoder, so jump through some hoops
        var tmpEl = Ext.get(document.createElement('div'));
        tmpEl.update(f.stripTags(t.replace(/&nbsp;/g, ' ')));
        return f.ellipsis(tmpEl.dom.innerHTML, 40);
    }

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Last Used</span></th>' +
                '<th><span>Text</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="signature-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.usig_upd_dtim)]}' +
                    '</td>' +
                    '<td>{[this.cleanupText(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            cleanupText: function(v) {
                return sanitizeFn(v.usig_text);
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Last Used</span></th>' +
                '<th><span>Emails</span></th>' +
                '<th><span>Text</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="signature-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.usig_upd_dtim)]}' +
                    '</td>' +
                    '<td>{usage_count}</td>' +
                    '<td>{usig_text}</td>' +
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
        title: 'Signatures',
        showTotal: true,
        cls: 'air2-user-signatures',
        iconCls: 'air2-icon-email',
        storeData: AIR2.User.SIGDATA,
        url: AIR2.User.URL + '/signature',
        itemSelector: '.signature-row',
        tpl: template,
        modalAdd: 'New Signature',
        editModal: {
            title: 'User Signatures',
            allowAdd: AIR2.User.BASE.authz.may_write,
            width: 700,
            height: 500,
            showTotal: true,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.User.URL + '/signature',
                multiSort: 'usig_upd_dtim desc',
                newRowDef: {},
                allowEdit: AIR2.User.BASE.authz.may_write,
                allowDelete: function(rec) {
                    return AIR2.User.BASE.authz.may_write && (rec.data.usage_count == 0);
                },
                itemSelector: '.signature-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var text,
                        textEl;

                    textEl = Ext.fly(node).first('td').next().next().update('');
                    text = new AIR2.UI.CKEditor({
                      value: rec.data.usig_text,
                      allowBlank: false,
                      width: 400,
                      renderTo: textEl,
                      CKConfig: { height: 100 }
                    });

                    return [text];
                },
                saveRow: function (rec, edits) {
                    rec.set('usig_text', edits[0].getValue());
                }
            }
        }
    });
};
