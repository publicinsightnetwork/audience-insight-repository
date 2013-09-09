/***************
 * Email stats panel
 *
 * (Only visible after email is sent)
 */
AIR2.Email.Stats = function (org_uuid, title) {
    var template, data, url, status, html;

    template = new Ext.XTemplate(
        '<tpl for="."><table class="air2-tbl">' +
            // single emails
            '<tpl if="this.isSingleEmail(values)">' +
                '<tr>' +
                    '<td><i class="icon-fixed-width icon-envelope"></i> Sent to</td>' +
                    '<td class="right">{[this.srcLink(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
            // replies to submissions
            '<tpl if="this.isReplyEmail(values)">' +
                '<tr>' +
                    '<td><i class="icon-fixed-width icon-circle-arrow-right"></i> In reply to</td>' +
                    '<td class="right">{[this.srsLink(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
            // bin exports
            '<tpl if="!this.isSingleEmail(values)">' +
                '<tr>' +
                    '<td><i class="icon-fixed-width icon-circle-arrow-right"></i> Sources Exported in Bin</td>' +
                    '<td class="fixw right">{num_exported}</td>' +
                    '<td class="fixw right"></td>' +
                '</tr>' +
                '<tr>' +
                    '<td><i class="icon-fixed-width icon-envelope"></i> Emails Sent</td>' +
                    '<td class="fixw right">{num_sent}</td>' +
                    '<td class="fixw"><span class="air2-tipper" ext:qtip="This includes 2 BCC emails, sent to yourself and PIN Support">?</span></td>' +
                '</tr>' +
                // optional stats (only visible when the data shows up)
                '<tpl if="has_num_opened">' +
                    '<tr>' +
                        '<td><i class="icon-fixed-width icon-folder-open"></i> Opens</td>' +
                        '<td class="fixw right">{num_opened}</td>' +
                        '<td class="fixw right">{perc_opened}%</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="has_num_clicked">' +
                    '<tr>' +
                        '<td><i class="icon-fixed-width icon-hand-up"></i> Clicks</td>' +
                        '<td class="fixw right">{num_clicked}</td>' +
                        '<td class="fixw right">{perc_clicked}%</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tpl if="has_num_bounced">' +
                    '<tr>' +
                        '<td><i class="icon-fixed-width icon-exclamation"></i> Bounces</td>' +
                        '<td class="fixw right">{num_bounced}</td>' +
                        '<td class="fixw right">{perc_bounced}%</td>' +
                    '</tr>' +
                '</tpl>' +
            '</tpl>' +
        '</table></tpl>',
        {
            compiled: true,
            disableFormats: true,
            // test if this is a single email, or a bin export
            isSingleEmail: function (v) {
                return v.se_ref_type == 'I' ? false : true;
            },
            // test if this is in reply to a submission
            isReplyEmail: function (v) {
                return (v.se_type == 'M' && v.se_ref_type == 'R');
            },
            srcLink: function (v) {
                return AIR2.Format.sourceName(v.Source || v.SrcResponseSet.Source, true, true);
            },
            srsLink: function (v) {
                if (v.SrcResponseSet) {
                    return AIR2.Format.createLink('Submission&nbsp;&raquo;',
                        '/submission/' + v.SrcResponseSet.srs_uuid, true);
                }
                else {
                    return '<span class="lighter">(Unknown submission)</span>';
                }
            }
        }
    );

    status = AIR2.Email.BASE.radix.email_status;
    if (status != 'D' && status != 'Q') {
        if (AIR2.Email.EXPDATA.success) {
            data = AIR2.Email.EXPDATA;
            url = AIR2.Email.URL + '/export';
        }
        else {
            html = '<table class="air2-tbl" style="width:100%">' +
                    '<tr>' +
                        '<td><i class="icon-fixed-width icon-circle-arrow-right"></i> Sources Exported in Bin</td>' +
                        '<td class="fixw right">0</td>' +
                        '<td class="fixw right"></td>' +
                    '</tr>' +
                    '<tr>' +
                        '<td><i class="icon-fixed-width icon-envelope"></i> Emails Sent</td>' +
                        '<td class="fixw right">0</td>' +
                        '<td class="fixw"><span class="air2-tipper" ext:qtip="Your bin included 0 exportable sources">?</span></td>' +
                    '</tr>' +
                '</table>';
        }
    }

    AIR2.Email.Stats = new AIR2.UI.Panel({
        storeData: data,
        url: url,
        colspan: 1,
        title: 'Statistics',
        hidden: (status != 'D' && status != 'Q') ? false : true,
        cls: 'air2-email-stats',
        iconCls: 'air2-icon-stats',
        showTotal: false,
        showHidden: false,
        itemSelector: '.stats-row',
        tpl: template,
        html: html,
        // json-decode some stuff ahead of time
        prepareData: function(data) {
            var json = Ext.util.JSON.decode(data.se_notes) || {};
            var stat = json.stats || {};

            // counts
            data.num_exported = json.initial_count || 0;
            data.num_sent = json.mailchimp_emails || 0;
            data.num_opened = stat.unique_opens || 0;
            data.num_clicked = stat.unique_clicks || 0;
            data.num_bounced = stat.hard_bounces || 0;

            // percentages
            data.perc_opened = Math.round(data.num_opened / data.num_sent * 100);
            data.perc_clicked = Math.round(data.num_clicked / data.num_sent * 100);
            data.perc_bounced = Math.round(data.num_bounced / data.num_sent * 100);

            // has stuff
            data.has_num_opened = stat.hasOwnProperty('unique_opens');
            data.has_num_clicked = stat.hasOwnProperty('unique_clicks');
            data.has_num_bounced = data.num_bounced > 0;

            return data;
        },
    });

    return AIR2.Email.Stats;

};
