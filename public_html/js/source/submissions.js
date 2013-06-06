/**************************
 * Source Submissions Panel
 *
 * @event addsubmission
 */
AIR2.Source.Submissions = function () {
    var pnl, template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
            '<tr>' +
                '<th class="fixw right"><span>Received</span></th>' +
                '<th><span>Query</span></th>' +
                '<th class="fixw"><span>Submission</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="subm-row">' +
                    '<td class="date right air2-dragzone" air2type="S" ' +
                        'air2rel="S" air2uuid="{srs_uuid}" ' +
                        'air2str="Submission on ' +
                        '{[AIR2.Format.date(values.srs_date)]}">' +
                        '{[AIR2.Format.date(values.srs_date)]}' +
                    '</td>' +
                    '<td>{[this.formatInquiry(values)]}</td>' +
                    '<td>{[this.formatContent(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatContent: function (values) {
                var link = '/submission/' + values.srs_uuid;
                return AIR2.Format.createLink(
                    'view&nbsp;submission&nbsp;&raquo;',
                    link,
                    true
                );
            },
            formatInquiry: function (values) {
                if (values.srs_type === 'E') {
                    var str = '<b>' + values.manual_entry_type + ':</b> ';
                    str += Ext.util.Format.ellipsis(
                        values.manual_entry_desc,
                        60
                    );
                    return str;
                }
                else {
                    return AIR2.Format.inquiryTitle(values.Inquiry, 1, 70);
                }
            }
        }
    );

    pnl = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Submissions',
        showTotal: true,
        showAllLink: AIR2.Source.SUBMSRCH,
        iconCls: 'air2-icon-response',
        storeData: AIR2.Source.SUBMDATA,
        url: AIR2.Source.URL + '/submission',
        tools: ['->', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: 'air2-icon-add',
            tooltip: 'New submission',
            hidden: !AIR2.Source.BASE.authz.unlock_write, //ignore lock
            handler: function () {
                var uuid = AIR2.Source.UUID;
                AIR2.Submission.Create({
                    src_uuid: uuid,
                    originEl: this.el,
                    callback: function (success) {
                        if (success) {
                            pnl.reload();
                        }

                        pnl.fireEvent('addsubmission');
                    }
                });
            }
        }],
        itemSelector: '.subm-row',
        tpl: template
    });
    return pnl;
};
