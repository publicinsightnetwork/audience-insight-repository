/***************
 * Project Submissions Panel
 */
AIR2.Project.Submissions = function () {
    var template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Received</span></th>' +
                '<th><span>Source</span></th>' +
                '<th><span>Query</span></th>' +
                '<th class="fixw"><span>Submission</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="subm-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.srs_date)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.sourceName(values.Source,1,1)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.inquiryTitle(' +
                            'values.Inquiry,' +
                            '1,' +
                            '48' +
                        ')]}' +
                    '</td>' +
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
            }
        }
    );

    return new AIR2.UI.Panel({
        showAllLink: AIR2.Project.SUBMSRCH,
        storeData: AIR2.Project.SUBMDATA,
        url: AIR2.Project.URL + '/submission',
        colspan: 2,
        title: 'Recent Submissions',
        showTotal: true,
        cls: 'air2-project-submissions',
        iconCls: 'air2-icon-response',
        itemSelector: '.subm-row',
        tpl: template
    });
};
