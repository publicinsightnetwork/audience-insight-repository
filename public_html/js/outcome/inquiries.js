/***************
 * Outcome Inquiries Panel
 */
AIR2.Outcome.Inquiries = function () {
    var editTemplate,
        maywrite,
        template;

    maywrite = AIR2.Outcome.BASE.authz.may_write;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Title</span></th>' +
            '<th class="fixw center"><span>Submissions</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="inquiry-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.iout_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.inquiryTitle(values,1)]}</td>' +
              '<td class="center">{recv_count}</td>' +
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
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Title</span></th>' +
            '<th class="fixw center"><span>Submissions</span></th>' +
            '<th><span>Added By</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="inquiry-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.iout_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.inquiryTitle(values,1)]}</td>' +
              '<td class="center">{recv_count}</td>' +
              '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
              '<td class="row-ops">' +
                //'<button class="air2-rowedit"></button>' +
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

    // build panel
    AIR2.Outcome.Inquiries = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Queries',
        showTotal: true,
        showHidden: false,
        iconCls: 'air2-icon-inquiry',
        storeData: AIR2.Outcome.INQDATA,
        url: AIR2.Outcome.URL + '/inquiry',
        itemSelector: '.inquiry-row',
        tpl: template,
        modalAdd: 'Add Query',
        editModal: {
            title: 'PINfluence Queries',
            width: 650,
            allowAdd: maywrite ? 'Add Query' : false,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Outcome.URL + '/inquiry',
                multiSort: 'inq_ext_title asc',
                itemSelector: '.inquiry-row',
                tpl: editTemplate,
                // row editor
                allowEdit: maywrite,
                allowDelete: maywrite,
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                editRow: function (dv, node, rec) {
                    var inq, inqEl;

                    inqEl = Ext.fly(node).first('td').next();
                    inqEl.update('').setStyle('padding', '4px');
                    inq = new AIR2.UI.SearchBox({
                        cls: 'air2-magnifier',
                        searchUrl: AIR2.HOMEURL + '/inquiry',
                        pageSize: 10,
                        baseParams: {
                            excl_out: AIR2.Outcome.UUID
                        },
                        valueField: 'inq_uuid',
                        displayField: 'inq_ext_title',
                        listEmptyText:
                            '<div style="padding:4px 8px">' +
                                'No Queries Found' +
                            '</div>',
                        emptyText: 'Search Queries',
                        formatComboListItem: function (v) {
                            return AIR2.Format.inquiryTitle(v);
                        },
                        renderTo: inqEl,
                        width: 200
                    });
                    return [inq];
                },
                saveRow: function (rec, edits) {
                    rec.set('inq_uuid', edits[0].getValue());
                }
            }
        }
    });
    return AIR2.Outcome.Inquiries;
};
