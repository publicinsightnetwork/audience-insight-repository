/***************
 * Project Statistics Panel
 */
AIR2.Project.Statistics = function () {
    var template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<ul class="air2-project-source">' +
                '<li>' +
                    '<h2>' +
                        '<a href="' + AIR2.Project.SUBMSRCH + '">' +
                            '{SubmissionCount} Submissions' +
                        '</a>' +
                    '</h2>' +
                    '<span>' +
                        '{[this.formatResponseRate(' +
                            'values.SubmissionRate' +
                        ')]}' +
                    '</span>' +
                '</li>' +
                '<li>' +
                    '<h2>' +
                        '<a href="' + AIR2.Project.SRCSRCH + '">' +
                            '{SourceCount} Sources' +
                        '</a>' +
                    '</h2>' +
                    '<span>' +
                        '{[this.formatSourceRate(values.SourceRate)]}' +
                    '</span>' +
                '</li>' +
            '</ul>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatResponseRate: function (rate) {
                var pct;

                if (isNaN(rate)) {
                    return 'Response Rate Not Available';
                }
                pct = Math.round(rate * 1000) / 10;
                return pct + '% Response Rate';
            },
            formatSourceRate: function (rate) {
                var pct;
                if (isNaN(rate)) {
                    return 'Rate Not Available';
                }
                pct = Math.round(rate * 1000) / 10;
                return pct + '% of the PIN';
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Statistics',
        iconCls: 'air2-icon-stats',
        storeData: AIR2.Project.STATSDATA,
        itemSelector: '.air2-project-source',
        tpl: template
    });
};
