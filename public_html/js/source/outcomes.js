/***************
 * Source Outcomes Panel
 */
AIR2.Source.Outcomes = function () {
    var editTemplate, p, template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Headline</span></th>' +
                '<th><span>Creator</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="outcome-row">' +
                    '<td>{[AIR2.Format.outcome(values,1,60)]}</td>' +
                    '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    editTemplate = new Ext.XTemplate(
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
                        '<a class="external" target="_blank" ' +
                        'href="{out_url}">' +
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
                    //'<button class="air2-rowedit"></button>' +
                '</div>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatCounts: function (v) {
                if (!v.inq_count && !v.src_count && !v.prj_count) {
                    return '';
                }
                var s = '', p = '';
                if (v.inq_count && v.inq_count > 0) {
                    p = v.inq_count === 1 ? ' Query' : ' Queries';
                    s += (s.length ? ', ' : '') + v.inq_count + p;
                }
                if (v.src_count && v.src_count > 0) {
                    p = v.src_count === 1 ? ' Source' : ' Sources';
                    s += (s.length ? ', ' : '') + v.src_count + p;
                }
                if (v.prj_count && v.prj_count > 0) {
                    p = v.prj_count === 1 ? ' Project' : ' Projects';
                    s += (s.length ? ', ' : '') + v.prj_count + p;
                }
                return '<span class="datewho">' + s + '</span>';
            }
        }
    );

    p = new AIR2.UI.Panel({
        colspan: 1,
        title: 'PINfluence',
        showTotal: true,
        cls: 'air2-source-outcome',
        iconCls: 'air2-icon-outcome',
        tools: ['->', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: 'air2-icon-add',
            tooltip: 'Add PINfluence',
            handler: function () {
                AIR2.Outcome.Create({
                    src_uuid: AIR2.Source.UUID,
                    originEl: this.el,
                    callback: function (success) {
                        if (success) {
                            p.reload();
                        }
                    }
                });
            }
        }],
        storeData: AIR2.Source.OUTDATA,
        url: AIR2.Source.URL + '/outcome',
        itemSelector: '.outcome-row',
        tpl: template,
        editModal: {
            title: 'Source PINfluence',
            allowNew: 'Create PINfluence',
            createNewFn: AIR2.Outcome.Create,
            createNewCfg: {
                src_uuid: AIR2.Source.UUID
            },
            width: 670,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/outcome',
                multiSort: 'out_dtim desc',
                itemSelector: '.outcome-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate
            }
        }
    });
    return p;
};
