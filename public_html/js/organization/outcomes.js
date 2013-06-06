/***************
 * Organization Outcomes Panel
 */
AIR2.Organization.Outcomes = function () {
    var editTemplate,
        orgObj,
        p,
        template;

    // get an org for creating new
    orgObj = AIR2.Organization.BASE.radix;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Date</span></th>' +
            '<th><span>Headline</span></th>' +
            '<th><span>Creator</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="outcome-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.out_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.outcome(values,1,70)]}</td>' +
              '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    editTemplate =  new Ext.XTemplate(
        '<tpl for=".">' +
          '<div class="outcome-row">' +
            '<h3>' +
              '{[AIR2.Format.outcome(values,"title",60)]}' +
              '<span class="date">' +
                ' - {[AIR2.Format.date(values.out_dtim)]}' +
              '</span>' +
            '</h3>' +
            '<tpl if="out_url">' +
              '<div class="link">' +
                '<a class="external" target="_blank" href="{out_url}">' +
                  '{out_url}' +
                '</a>' +
              '</div>' +
            '</tpl>' +
            '<div class="teaser">{out_teaser}</div>' +
            '<div class="meta">' +
              '{[this.formatCounts(values)]}' +
              '<span class="datewho">Created ' +
                '{[AIR2.Format.date(values.out_cre_dtim)]} by ' +
                '{[AIR2.Format.userName(values.CreUser,1,1)]}' +
              '</span>' +
            '</div>' +
          '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatCounts: function (v) {
                var s = '', p = '';

                if (!v.inq_count && !v.src_count && !v.prj_count) {
                    return '';
                }
                if (v.inq_count && v.inq_count > 0) {
                    if (v.inq_count === 1) {
                        p = ' Query';
                    }
                    else {
                        p = ' Queries';
                    }

                    if (s.length) {
                        s += ', ';
                    }

                    s += v.inq_count + p;
                }
                if (v.src_count && v.src_count > 0) {
                    if (v.src_count === 1) {
                        p =  ' Source';
                    }
                    else {
                        p = ' Sources';
                    }

                    if (s.length) {
                        s +=  ', ';
                    }

                    s += v.src_count + p;
                }
                if (v.prj_count && v.prj_count > 0) {
                    if (v.prj_count === 1) {
                        p = ' Project';
                    }
                    else {
                        p = ' Projects';
                    }

                    if (s.length) {
                        s += ', ';
                    }

                    s += v.prj_count + p;
                }
                return '<span class="datewho">' + s + '</span>';
            }
        }
    );

    p = new AIR2.UI.Panel({
        colspan: 2,
        rowspan: 3,
        title: 'PINfluence',
        showTotal: true,
        cls: 'air2-org-outcome',
        iconCls: 'air2-icon-outcome',
        tools: ['->', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: 'air2-icon-add',
            tooltip: 'Add PINfluence',
            handler: function () {
                AIR2.Outcome.Create({
                    org_obj: orgObj,
                    originEl: this.el,
                    callback: function (success) {
                        if (success) {
                            p.reload();
                        }
                    }
                });
            }
        }],
        storeData: AIR2.Organization.OUTDATA,
        url: AIR2.Organization.URL + '/outcome',
        itemSelector: '.outcome-row',
        tpl: template,
        editModal: {
            title: 'Organization PINfluence',
            allowNew: 'Create PINfluence',
            createNewFn: AIR2.Outcome.Create,
            createNewCfg: { org_obj: orgObj },
            cls: 'air2-outcome', //steal style
            width: 670,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/outcome',
                multiSort: 'out_dtim desc',
                itemSelector: '.outcome-row',
                tpl: editTemplate
            }
        }
    });

    return p;
};
