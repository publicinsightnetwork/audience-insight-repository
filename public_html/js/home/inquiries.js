/***************
 * Home Inquiries Panel
 */
AIR2.Home.Inquiries = function () {
    var template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Created</span></th>' +
                '<th><span>Title</span></th>' +
                '<th><span>Organizations</span></th>' +
                '<th class="center"><span>Submissions</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="inquiry-row">' +
                    '<td class="date right">{[this.formatDate(values)]}</td>' +
                    '<td>{[AIR2.Format.inquiryTitle(values,1)]}</td>' +
                    '<td>{[this.formatOrgs(values)]}</td>' +
                    '<td class="center">{[this.submLink(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatDate: function (values) {
                return AIR2.Format.date(values.inq_cre_dtim);
            },
            formatOrgs: function (values) {
                var i, org, remain, str;

                if (values.InqOrg && values.InqOrg.length) {
                    str = '';
                    for (i = 0; i < values.InqOrg.length; i++) {
                        if (i < 2) {
                            org = values.InqOrg[i].Organization;
                            str += AIR2.Format.orgName(org, 1) + ' ';
                        }
                        else {
                            remain = values.InqOrg.length - i;
                            str += '+ ' + remain + ' more';
                            break;
                        }
                    }
                    return str;
                }
                return '<span class="lighter">(none)</span>';
            },
            submLink: function (values) {
                var href;
                if (values.recv_count && values.recv_count > 0) {
                    href = AIR2.HOMEURL + '/reader/query/' + values.inq_uuid;
                    return '<b><a href="' + href + '">' + values.recv_count +
                        '</a></b>';
                }
                return '0';
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 2,
        title: 'Queries',
        cls: 'air2-home-inquiry',
        iconCls: 'air2-icon-inquiry',
        showTotal: true,
        showHidden: false,
        showAllLink: AIR2.HOMEURL + '/search/queries#' +
            Ext.urlEncode({s: 'lastmod DESC'}),
        storeData: AIR2.Home.INQDATA,
        itemSelector: '.inquiry-row',
        tpl: template
    });
};
