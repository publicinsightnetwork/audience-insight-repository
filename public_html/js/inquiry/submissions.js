/***************
 * Inquiry Submissions Panel
 */
AIR2.Inquiry.RecentSubmissions = function () {
    var panel, template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Name</span></th>' +
                '<th class="fixw right"><span>Received</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="subm-row">' +
                    '<td>{[this.formatContent(values)]}</td>' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.srs_date)]}' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatContent: function (values) {
                var link, name;
                link = '/submission/' + values.srs_uuid;
                name = AIR2.Format.sourceName(values.Source, false, true);
                return AIR2.Format.createLink(name, link, true);
            }
        }
    );

    // panel
    panel = new AIR2.UI.Panel({
        colspan: 1,
        emptyText: '<div class="air2-panel-empty"><h3>Loading...</h3></div>',
        iconCls: 'air2-icon-response',
        id: 'air2-project-submissions',
        itemSelector: '.subm-row',
        showAllLink: AIR2.Inquiry.SUBMSRCH,
        showTotal: true,
        showHidden: false,
        storeData: AIR2.Inquiry.SUBMDATA,
        title: 'Recent Submissions',
        tpl: template,
        url: AIR2.Inquiry.URL + '/submission'
    });

    return panel;
};
