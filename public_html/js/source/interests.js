/************************
 * Source Interests Panel
 */
AIR2.Source.Interests = function () {
    var editTemplate, template, titleLock;
    // include account-lock in title
    titleLock = AIR2.Source.LOCK ? ('&nbsp;' + AIR2.Source.LOCK) : '';

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Subject</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="interest-row">' +
                    '<td>{[this.formatInterest(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatInterest: function (values) {
                return Ext.util.Format.ellipsis(values.sv_notes, 160);
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Subject</span></th>' +
                '<th class="fixw"><span>Origin</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="interest-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.sv_cre_dtim)]}' +
                    '</td>' +
                    '<td><pre>{sv_notes}</pre></td>' +
                    '<td class="date">{[this.formatOrigin(values)]}</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit"></button>' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatOrigin: function (values) {
                return AIR2.Format.vitaOrigin(values);
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Interests' + titleLock,
        iconCls: 'air2-icon-interest',
        storeData: AIR2.Source.INTDATA,
        url: AIR2.Source.URL + '/interest',
        showTotal: true,
        itemSelector: '.interest-row',
        tpl: template,
        modalAdd: 'Add Interest',
        editModal: {
            title: 'Source Interests' + titleLock,
            allowAdd: AIR2.Source.BASE.authz.may_write, //respect lock
            width: 700,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/interest',
                multiSort: 'sv_cre_dtim desc',
                newRowDef: {sv_type: 'I'},
                allowEdit: function (rec) {
                    // ignore lock for AIR1-origin
                    if (
                        rec.data.sv_origin === 'C' ||
                        rec.data.sv_origin === 'S'
                    ) {
                        return AIR2.Source.BASE.authz.unlock_write;
                    }
                    else {
                        return AIR2.Source.BASE.authz.may_write;
                    }
                },
                allowDelete: function (rec) {
                    // ignore lock for AIR1-origin
                    if (
                        rec.data.sv_origin === 'C' ||
                        rec.data.sv_origin === 'S'
                    ) {
                        return AIR2.Source.BASE.authz.unlock_write;
                    }
                    else {
                        return AIR2.Source.BASE.authz.may_write;
                    }
                },
                itemSelector: '.interest-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var subj, subjEl;
                    // subject
                    subjEl = Ext.fly(node).first('td').next();
                    subjEl.update('').setStyle('padding', '2px 4px');
                    subj = new Ext.form.TextArea({
                        allowBlank: false,
                        value: rec.data.sv_notes,
                        renderTo: subjEl,
                        width: subjEl.getWidth() - 10
                    });
                    return [subj];
                },
                saveRow: function (rec, edits) {
                    rec.set('sv_notes', edits[0].getValue());
                }
            }
        }
    });
};
