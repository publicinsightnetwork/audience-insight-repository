Ext.ns('AIR2.Background.QueueWin');
/**
 * Background-Queue Window
 *
 * Opens a modal window that shows what's in the background queue.
 *
 * @class AIR2.Background.QueueWin
 * @extends AIR2.UI.Window
 * @xtype air2queuewin
 */
AIR2.Background.QueueWin = function (cfg) {
    var pger, statusFilter, textFilter;

    cfg = cfg || {};
    cfg.title = this.title;

    pger = new AIR2.UI.PagingEditor({
        url: AIR2.HOMEURL + '/background',
        pageSize: 20,
        multiSort: 'jq_cre_dtim desc',
        itemSelector: '.bg-row',
        tpl: new Ext.XTemplate(
            '<table class="air2-tbl">' +
              // header
              '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Owner</span></th>' +
                '<th><span>Job</span></th>' +
                '<th class="fixw"><span>Status</span></th>' +
              '</tr>' +
              // rows
              '<tpl for=".">' +
                '<tr class="bg-row">' +
                  '<td class="date right">' +
                  '{[AIR2.Format.dateMachine(values.jq_cre_dtim)]}' +
                  '</td>' +
                  '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
                  '<td class="job">{[this.job(values)]}</td>' +
                  '<td class="status">{[this.status(values)]}</td>' +
                '</tr>' +
              '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: false,
                status: function (v) {
                    var cfg, c, s;
                    cfg = {
                        Q: ['Queued', ''],
                        R: ['Running', 'air2-icon-working'],
                        C: ['Complete', 'air2-icon-check'],
                        E: ['Errors!', 'air2-icon-working-error'],
                        U: ['Unknown', '']
                    };
                    c = cfg[v.jq_status] || cfg.U;

                    if (v.jq_status === 'E') {
                        s = '<a class="air2-icon show-errors ' + c[1];
                        s += '">' + c[0] + '</a>';
                        return s;
                    }
                    return '<span class="air2-icon ' + c[1] + '">' + c[0] +
                     '</span>';
                },
                job: function (v) {
                    if (v.jq_job) {
                        return Ext.util.Format.ellipsis(v.jq_job, 120, true);
                    }
                    return '<span class="lighter">(none)</span>';
                }
            })
        });

    // filters
    statusFilter = new AIR2.UI.ComboBox({
        value: '',
        choices: [
            ['QR', 'Incomplete'],
            ['C', 'Complete'],
            ['E', 'Errors'],
            ['', 'All']
        ],
        width: 90,
        listeners: {
            select: function (fld, rec, idx) {
                pger.store.setBaseParam('status', rec.data.value);
                pger.pager.changePage(0);
            }
        }
    });

    textFilter = new Ext.form.TextField({
        width: 230,
        emptyText: 'Filter',
        validationDelay: 500,
        queryParam: 'q',
        validateValue: function (v) {
            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-1, 2]);
                this.remoteAction.show();
                pger.store.setBaseParam('q', v);
                pger.store.on('load', function () {
                    this.remoteAction.hide();
                }, this, {single: true});
                pger.pager.changePage(0);
                this.lastValue = v;
            }
        },
        lastValue: '',
        listeners: {
            render: function (p) {
                p.remoteAction = p.el.insertSibling({
                    cls: 'air2-form-remote-wait'
                });
            }
        }
    });

    cfg.tools = [statusFilter, ' ', textFilter];

    // error-shower (lots of text to show)
    pger.on('click', function (dv, idx, node, ev) {
        var el, rec;
        el = ev.getTarget('.show-errors');
        if (el) {
            rec = dv.getRecord(node);
            Ext.Msg.show({
                animEl: el,
                buttons: Ext.Msg.OK,
                cls: 'air2-corners air2-bg-queue-error',
                closable: false,
                icon: Ext.Msg.ERROR,
                title: 'Background Errors',
                msg: '<pre>' + rec.data.jq_error_msg + '</pre>' ||
                 '<span class="lighter">(none)</span>',
                width: 700,
                height: 400
            });
        }
    });

    // call parent constructor
    cfg.items = pger;
    AIR2.Background.QueueWin.superclass.constructor.call(this, cfg);
};

Ext.extend(AIR2.Background.QueueWin, AIR2.UI.Window, {
    title: 'Background Queue',
    cls: 'air2-bg-queue',
    iconCls: 'air2-icon-filter',
    closeAction: 'close',
    width: 750,
    height: 500,
    padding: '6px 0'
});
Ext.reg('air2queuewin', AIR2.Background.QueueWin);
