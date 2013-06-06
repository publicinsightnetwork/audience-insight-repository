/***************
 * Stats panel
 */
AIR2.Dashboard.Stats = function (org_uuid, title) {
    var panel, now, template;

    now = new Date();

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>&nbsp;</span></th>' +
                '<th><span>Today</span></th>' +
                '<th><span>' + now.format('F') + '</span></th>' +
                '<th>' +
                    '<span>' +
                        now.add(Date.MONTH, -1).format('F') +
                    '</span>' +
                '</th>' +
                '<th><span>' + now.getFullYear() + '</span></th>' +
                '<th><span>Total</span></th>' +
            '</tr>' +
          // rows
            '<tpl for=".">' +
                '<tr class="stat-row row-alternate">' +
                    '<td class="air2-icon air2-icon-source">' +
                        'Sources (any status)' +
                    '</td>' +
                    '<td>{[this.numerify(values.sources_today)]}</td>' +
                    '<td>{[this.numerify(values.sources_month)]}</td>' +
                    '<td>' +
                        '{[this.numerify(values.sources_prev_month)]}' +
                    '</td>' +
                    '<td>{[this.numerify(values.sources_year)]}</td>' +
                    '<td>{[this.numerify(values.sources_total)]}</td>' +
                '</tr>' +
                '<tr class="stat-row">' +
                    '<td class="air2-icon air2-icon-source">' +
                        'Available Sources' +
                    '</td>' +
                    '<td>' +
                        '{[this.numerify(values.available_sources_today)]}' +
                    '</td>' +
                    '<td>' +
                        '{[this.numerify(values.available_sources_month)]}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.numerify(' +
                                'values.available_sources_prev_month' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[this.numerify(values.available_sources_year)]}' +
                    '</td>' +
                    '<td>' +
                        '{[this.numerify(values.available_sources_total)]}' +
                    '</td>' +
                '</tr>' +
                '<tr class="stat-row row-alternate">' +
                    '<td class="air2-icon air2-icon-primary-sources">' +
                        'Primary Sources (any status)' +
                    '</td>' +
                    '<td>{[this.numerify(values.primary_sources_today)]}</td>' +
                    '<td>{[this.numerify(values.primary_sources_month)]}</td>' +
                    '<td>' +
                        '{[this.numerify(values.primary_sources_prev_month)]}' +
                    '</td>' +
                    '<td>{[this.numerify(values.primary_sources_year)]}</td>' +
                    '<td>' +
                        '{[this.numerify(values.primary_sources_total)]}' +
                    '</td>' +
                '</tr>' +
                '<tr class="stat-row">' +
                    '<td class="air2-icon air2-icon-primary-sources">' +
                        'Available Primary Sources' +
                    '</td>' +
                    '<td>' +
                    '{[' +
                       'this.numerify(values.available_primary_sources_today)' +
                    ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                       'this.numerify(values.available_primary_sources_month)' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.numerify(' +
                                'values.available_primary_sources_prev_month' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                        'this.numerify(values.available_primary_sources_year)' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                       'this.numerify(values.available_primary_sources_total)' +
                        ']}' +
                    '</td>' +
                '</tr>' +
                '<tr class="stat-row row-alternate">' +
                    '<td class="air2-icon air2-icon-source-out">' +
                        'Opted Out' +
                    '</td>' +
                    '<td>{[this.numerify(values.opted_out_today)]}</td>' +
                    '<td>{[this.numerify(values.opted_out_month)]}</td>' +
                    '<td>{[this.numerify(values.opted_out_prev_month)]}</td>' +
                    '<td>{[this.numerify(values.opted_out_year)]}</td>' +
                    '<td>{[this.numerify(values.opted_out_total)]}</td>' +
                '</tr>' +
                '<tr class="stat-row ">' +
                    '<td class="air2-icon air2-icon-source-out">' +
                        'Unsubscribed' +
                    '</td>' +
                    '<td>{[this.numerify(values.unsubscribed_today)]}</td>' +
                    '<td>{[this.numerify(values.unsubscribed_month)]}</td>' +
                    '<td>' +
                        '{[this.numerify(values.unsubscribed_prev_month)]}' +
                    '</td>' +
                    '<td>{[this.numerify(values.unsubscribed_year)]}</td>' +
                    '<td>{[this.numerify(values.unsubscribed_total)]}</td>' +
                '</tr>' +
                '<tr class="stat-row row-alternate">' +
                    '<td class="air2-icon air2-icon-edit-percent">' +
                        'of Sources Queried (any Organization)' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.formatPercentQueried(' +
                                'values.sources_queried_today, ' +
                                'values.sources_total' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.formatPercentQueried(' +
                                'values.sources_queried_month, ' +
                                'values.sources_total' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.formatPercentQueried(' +
                                'values.sources_queried_prev_month, ' +
                                'values.sources_total' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.formatPercentQueried(' +
                                'values.sources_queried_year, ' +
                                'values.sources_total' +
                            ')' +
                        ']}' +
                    '</td>' +
                    '<td>' +
                        '{[' +
                            'this.formatPercentQueried(' +
                                'values.sources_queried_total, ' +
                                'values.sources_total' +
                            ')' +
                        ']}' +
                    '</td>' +
                '</tr>' +
                '<tr class="stat-row ">' +
                    '<td class="air2-icon air2-icon-inquiries">' +
                        'Queries' +
                    '</td>' +
                    '<td>{[this.numerify(values.queries_today)]}</td>' +
                    '<td>{[this.numerify(values.queries_month)]}</td>' +
                    '<td>{[this.numerify(values.queries_prev_month)]}</td>' +
                    '<td>{[this.numerify(values.queries_year)]}</td>' +
                    '<td>{[this.numerify(values.queries_total)]}</td>' +
                '</tr>' +
                '<tr class="stat-row row-alternate">' +
                    '<td class="air2-icon air2-icon-responses">' +
                        'Submissions' +
                    '</td>' +
                    '<td>{[this.numerify(values.submissions_today)]}</td>' +
                    '<td>{[this.numerify(values.submissions_month)]}</td>' +
                    '<td>' +
                        '{[this.numerify(values.submissions_prev_month)]}' +
                    '</td>' +
                    '<td>{[this.numerify(values.submissions_year)]}</td>' +
                    '<td>{[this.numerify(values.submissions_total)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            numerify: function (r) {
                var link, n;
                n = Ext.util.Format.number(r.c, '0,000');
                link = AIR2.HOMEURL + '/search/' + r.i + '?' +
                    Ext.urlEncode({q: r.q});
                return '<a href="' + link + '">' + n + '</a>';
            },
            formatPercentQueried: function (n, d) {
                var link, pct;
                pct = Math.round((n.c / d.c) * 100);
                //Logger(n, d, pct);
                link = AIR2.HOMEURL + '/search/' + n.i + '?' +
                    Ext.urlEncode({q: n.q});
                if (!d || !pct) {
                    return '<a href="' + link + '">&lt;1%</a>';
                }
                return '<a href="' + link + '">' + pct + '%</a>';
            }
        }
    );

    panel = new AIR2.UI.Panel({
        colspan: 2,
        title: title,
        cls: 'air2-dashboard-stats',
        iconCls: 'air2-icon-stats',
        showTotal: false,
        showHidden: false,
        nonapistore: true,
        url: AIR2.HOMEURL + '/dashboard/' + org_uuid,
        itemSelector: '.stat-row',
        tpl: template
    });

    return panel;

};
