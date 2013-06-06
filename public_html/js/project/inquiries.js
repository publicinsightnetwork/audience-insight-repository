Ext.ns('AIR2.Project');
/***************
 * Project Inquiries Panel
 */
AIR2.Project.Inquiries = function () {
    var addBtnText,
        editTemplate,
        template;

    // add button text
    addBtnText = false;

    if (AIR2.Project.BASE.authz.may_write) {
        addBtnText = 'Add Query';
    }

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Title</span></th>' +
                '<th class="fixw center"><span>Submissions</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="inquiry-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.Inquiry.inq_cre_dtim)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.inquiryTitle(values.Inquiry,1)]}</td>' +
                    '<td class="center">{[this.submLink(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            submLink: function (values) {
                var href;

                if (values.recv_count && values.recv_count > 0) {
                    href = AIR2.HOMEURL + '/reader/query/' + values.inq_uuid;
                    return '<b><a href="' + href + '">' + values.recv_count +
                        '</a></b>';
                }
                return '0';
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>User</span></th>' +
                '<th><span>Title</span></th>' +
                '<th class="fixw center"><span>Submissions</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="inquiry-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.Inquiry.inq_cre_dtim)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.userName(values.Inquiry.CreUser,1,1)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.inquiryTitle(values.Inquiry,1)]}</td>' +
                    '<td class="center">{[this.submLink(values)]}</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            submLink: function (values) {
                var href, params, uuid;

                if (values.recv_count && values.recv_count > 0) {
                    uuid = values.inq_uuid;
                    params = Ext.urlEncode({q: 'inq_uuid=' + uuid});
                    href = AIR2.HOMEURL + '/search/responses?' + params;
                    return '<b><a href="' + href + '">' + values.recv_count +
                        '</a></b>';
                }
                return '0';
            }
        }
    );

    return new AIR2.UI.Panel({
        showAllLink: AIR2.Project.INQSRCH,
        storeData: AIR2.Project.INQDATA,
        url: AIR2.Project.URL + '/inquiry',
        colspan: 2,
        title: 'Queries',
        cls: 'air2-project-inquiry',
        showTotal: true,
        iconCls: 'air2-icon-inquiry',
        itemSelector: '.inquiry-row',
        tpl: template,
        modalAdd: 'Add Query',
        editModal: {
            title: 'Project Queries',
            allowAdd: addBtnText,
            width: 650,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Project.URL + '/inquiry',
                multiSort: 'inq_cre_dtim desc',
                newRowDef: {
                    Inquiry: {
                        CreUser: {
                            user_type: 'S',
                            user_username: ''
                        }
                    }
                },
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                itemSelector: '.inquiry-row',
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var inq, inqEl;

                    inqEl = Ext.fly(node).first('td').next().next();
                    inqEl.update('').setStyle('padding', '4px');
                    inq = new AIR2.UI.SearchBox({
                        cls: 'air2-magnifier',
                        searchUrl: AIR2.HOMEURL + '/inquiry',
                        pageSize: 10,
                        baseParams: {
                            write: true,
                            excl_prj: AIR2.Project.UUID
                        },
                        valueField: 'inq_uuid',
                        displayField: 'inq_ext_title',
                        emptyText: 'Search Queries',
                        listEmptyText:
                            '<div style="padding:4px 8px">' +
                                'No Queries Found' +
                            '</div>',
                        formatComboListItem: function (v) {
                            return v.inq_ext_title;
                        },
                        renderTo: inqEl,
                        width: 280
                    });
                    return [inq];
                },
                saveRow: function (rec, edits) {
                    rec.set('inq_uuid', edits[0].getValue());
                }
            }
        }
    });
};
