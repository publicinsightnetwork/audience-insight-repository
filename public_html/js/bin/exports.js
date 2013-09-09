/***************
 * Bin Exports panel
 */
AIR2.Bin.Exports = function () {
    var expbin, p;

    // export bin
    expbin = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-upload',
        tooltip: 'Export Bin',
        hidden: !AIR2.Bin.BASE.authz.may_manage,
        handler: function () {
            var w;
            w = AIR2.Bin.Exporter({originEl: p.el, binuuid: AIR2.Bin.UUID});
            w.on('close', function () {
                p.reload();
            });
        }
    });

    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'Exports',
        id: 'air2-bin-exports',
        cls: 'air2-bin-exports',
        iconCls: 'air2-icon-source-upload',
        tools: ['->', expbin],
        showTotal: true,
        showHidden: false,
        storeData: AIR2.Bin.EXPORTS,
        url: AIR2.Bin.URL + '/export.json',
        itemSelector: '.export-row',
        tpl: new Ext.XTemplate(
            '<table class="air2-tbl">' +
              // header
              '<tr>' +
                '<th class="right fixw"><span>Date</span></th>' +
                '<th><span>Type</span></th>' +
              '</tr>' +
              // rows
              '<tpl for=".">' +
                '<tr class="export-row">' +
                  '<td class="date right">{[this.formatDate(values)]}</td>' +
                  '<td>{[this.formatType(values)]}</td>' +
                '</tr>' +
              '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: true,
                formatDate: function (values) {
                    return AIR2.Format.date(values.se_cre_dtim);
                },
                formatType: function (values) {
                    if (values.se_type === 'L') {
                        return 'Lyris';
                    }
                    if (values.se_type === 'C') {
                        return 'CSV';
                    }
                    if (values.se_type === 'X') {
                        return 'XLSX';
                    }
                    if (values.se_type === 'M') {
                        if (values.Email.email_uuid) {
                            return AIR2.Format.createLink(
                                'Mailchimp',
                                '/email/' + values.Email.email_uuid,
                                true
                            );
                        }
                        return 'Mailchimp';
                    }
                    return '<span class="lighter">(Unknown)</span>';
                }
            })
        });

    return p;
};
