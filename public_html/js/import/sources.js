/***************
 * Import Sources Panel
 *
 * @event resolved
 *     fires when a conflict has been resolved, and store counts update
 */
AIR2.Import.Sources = function () {
    var cons,
    dv,
    dvTemplate,
    pnl,
    statusFilter;

    // setup combo-box filtering tools
    statusFilter = new AIR2.UI.ComboBox({
        value: '',
        choices: [
            ['', 'All'],
            ['C', 'Conflicts'],
            ['E', 'Errors'],
            ['D', 'Complete']
        ],
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('status', rec.data.value);
                dv.pager.changePage(0);
            }
        }
    });

    dvTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            '<tr class="header">' +
                '<th class="fixw right"]}>' +
                    '<span>Date</span>' +
                '</th>' +
                '<th class="sortable" air2fld="src_username">' +
                    '<span>Email/Username</span>' +
                '</th>' +
                '<th class="sortable" air2fld="src_first_name"]}>' +
                    '<span>First</span>' +
                '</th>' +
                '<th class="sortable" air2fld="src_last_name"]}>' +
                    '<span>Last</span>' +
                '</th>' +
                '<th class="sortable" air2fld="status_sort"]}>' +
                    '<span>Status</span>' +
                '</th>' +
            '</tr>' +
            '<tpl for=".">' +
                '<tr class="tsrc-row {[this.rowClass(values, xindex)]}">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.dateYmd(values.tsrc_cre_dtim)]}' +
                    '</td>' +
                    '<td class="forcebreak">{[this.formatName(values)]}</td>' +
                    '<td class="forcebreak">{[this.formatFirst(values)]}</td>' +
                    '<td class="forcebreak">{[this.formatLast(values)]}</td>' +
                    '<td>{[this.formatStatus(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            rowClass: function (values, idx) {
                var cls, st;

                st = values.tsrc_status;

                if (st === 'E' || st === 'C') {
                    cls = ' row-error';
                }
                else {
                    cls  = '';
                }

                return cls;
            },
            formatName: function (values) {
                if (values.Source) {
                    return AIR2.Format.sourceUsername(values.Source, true);
                }
                else if (values.src_username) {
                    return values.src_username;
                }
                else if (values.sem_email) {
                    return values.sem_email;
                }
                else {
                    return '<span class="lighter">(none)</span>';
                }
            },
            formatFirst: function (values) {
                if (values.src_first_name) {
                    return values.src_first_name;
                }
                return '<span class="lighter">(none)</span>';
            },
            formatLast: function (values) {
                if (values.src_last_name) {
                    return values.src_last_name;
                }
                return '<span class="lighter">(none)</span>';
            },
            formatStatus: function (values) {
                var s = AIR2.Format.tsrcStatus(values.tsrc_status);
                if (values.tsrc_status === 'C') {
                    s = '<a class="resolve-action">' + s + '</a>';
                }
                if (values.tsrc_status === 'E') {
                    s = '<a class="error-action">' + s + '</a>';
                }
                return s;
            }
        }
    );

    dv = new AIR2.UI.PagingEditor({
        pageSize: 25,
        url: AIR2.Import.URL + '/source',
        data: AIR2.Import.TSRCDATA,
        plugins: [AIR2.UI.PagingEditor.HeaderSort],
        itemSelector: '.tsrc-row',
        tpl: dvTemplate
    });

    // create paging panel for dataview
    pnl = new AIR2.UI.Panel({
        colspan: 2,
        rowspan: 2,
        title: 'Import Sources',
        cls: 'air2-import',
        showTotal: false,
        iconCls: 'air2-icon-source-upload',
        tools: ['->', '<b>Show:</b>', statusFilter],
        items: [dv]
    });

    // resolve listener
    pnl.getBody().get(0).on('click', function (dv, idx, node, event) {
        var el, el2, rec, w;

        el = event.getTarget('.resolve-action');
        el2 = event.getTarget('.error-action');

        if (el) {
            rec = dv.getRecord(node);
            w = AIR2.Import.Resolve({
                tsrc_id: rec.data.tsrc_id,
                originEl: node
            });
            w.on('hide', function () {
                pnl.fireEvent('resolved');
                rec.store.reload();
            });
        }
        else if (el2) {
            rec = dv.getRecord(node);
            AIR2.UI.ErrorMsg(node, 'Fatal Import Error', rec.data.tsrc_errors);
        }
    });

    // custom store total
    cons = AIR2.Import.BASE.radix.count_conflict;

    if (cons === 1) {
        cons += ' Conflict';
    }
    else {
        cons += ' Conflicts';
    }

    pnl.setCustomTotal(dv.store.getTotalCount() + ' Sources | ' + cons);

    // return paging panel
    return pnl;
};
