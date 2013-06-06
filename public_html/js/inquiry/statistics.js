/***********************
 * Inquiry Stats Panel
 */
AIR2.Inquiry.Statistics = function () {
    var template = new Ext.XTemplate(
        '<tpl for=".">' +
          '<div class="stats-row">' +
            '<div class="stat">' +
              '<h1>{[this.submLink(values)]}</h1>' +
              '<p>submissions</p>' +
            '</div>' +
            '<div class="stat">' +
              '<h1>{sent_count}</h1>' +
              '<p>e-mails sent</p>' +
            '</div>' +
          '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            submLink: function (values) {
                var href;

                if (values.recv_count && values.recv_count > 0) {
                    href = AIR2.HOMEURL + '/reader/query/' + values.inq_uuid;
                    return '<a href="' + href + '">' + values.recv_count +
                        '</a>';
                }
                return '0';
            }
        }
    );

    AIR2.Inquiry.Statistics = new AIR2.UI.Panel({
        collapsible: true,
        colspan: 1,
        title: 'Statistics',
        cls: 'air2-inquiry-stats',
        iconCls: 'air2-icon-stats',
        itemSelector: '.stats-row',
        storeData: AIR2.Inquiry.STATSDATA,
        tpl: template
    });

    return AIR2.Inquiry.Statistics;
};
