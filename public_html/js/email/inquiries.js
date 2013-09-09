/***************
 * Email Inquiries Panel
 */
AIR2.Email.Inquiries = function() {
    var addBtnText, editTemplate, template, mayEdit, showEdit;

    // editing authz/state
    mayEdit = AIR2.Email.BASE.authz.may_write &&
        (AIR2.Email.BASE.radix.email_status == 'D');

    // add button text
    showEdit = true;
    addBtnText = false;
    if (mayEdit) {
        addBtnText = 'Add Query';
    }

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Title</span></th>' +
                '<th class="fixw"><span>Copy&nbsp;Link</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="inquiry-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.Inquiry.inq_cre_dtim)]}' +
                    '</td>' +
                    '<td class="inq-name">{[AIR2.Format.inquiryTitle(values.Inquiry,1)]}</td>' +
                    '<td class="center">' +
                      '<button class="air2-rowdup" air2inquuid="{[values.Inquiry.inq_uuid]}"></button>' +
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
                    href = AIR2.HOMEURL + '/reader/query/' + values.inq_uuid;
                    return '<b><a href="' + href + '">' + values.recv_count +
                        '</a></b>';
                }
                return '0';
            }
        }
    );

    // build panel
    AIR2.Email.Inquiries = new AIR2.UI.Panel({
        storeData: AIR2.Email.INQDATA,
        url: AIR2.Email.URL + '/inquiry',
        colspan: 1,
        title: 'Queries',
        cls: 'air2-email-inquiry',
        showTotal: true,
        iconCls: 'air2-icon-inquiry',
        itemSelector: '.inquiry-row',
        tpl: template,
        modalAdd: 'Add Query',
        setEditable: function (allow) {
            showEdit = allow;

            // show/hide the add button
            AIR2.Email.Inquiries.tools.items.each(function(t) {
                if (t.iconCls == 'air2-icon-add') t.setVisible(allow);
            });

            // show/hide the modal tools add/delete buttons
            cfgTarget = AIR2.Email.Inquiries.editModalConfig || AIR2.Email.Inquiries.editModal;
            cfgTarget.allowAdd = allow ? addBtnText : false;
        },
        editModal: {
            title: 'Email Queries',
            allowAdd: addBtnText,
            width: 650,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Email.URL + '/inquiry',
                multiSort: 'einq_cre_dtim desc',
                newRowDef: {
                    Inquiry: {
                        CreUser: {
                            user_type: 'S',
                            user_username: ''
                        }
                    }
                },
                allowDelete: function () {
                    return (mayEdit && showEdit);
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
                            excl_eml: AIR2.Email.UUID
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
        },
        // listen for copy-link button clicks
        listeners: {
            render: function (pnl) {
                pnl.el.on('click', function (e) {
                    var fld, link, nameEl, t, uuid;

                    if (t = e.getTarget('.air2-rowdup', 10, true)) {
                        uuid = t.getAttribute('air2inquuid');
                        link = AIR2.FORMURL + uuid; // TODO: QBuilder-ify?
                        fld = new Ext.form.TextField({
                            width: 180,
                            style: 'border-style:dashed;background-image:none;',
                            readOnly: true,
                            value: link,
                            selectOnFocus: true,
                            listeners: {
                                blur: function() { pnl.getDataView().refresh(); }
                            }
                        });

                        // render in place of the query title
                        nameEl = t.parent('.inquiry-row').child('.inq-name');
                        nameEl.update('');
                        fld.render(nameEl);
                        fld.focus();
                    }
                });
            }
        }
    });

    return AIR2.Email.Inquiries;
};
