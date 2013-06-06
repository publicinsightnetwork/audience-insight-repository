/***************
 * Query PINfluence Panel
 */
AIR2.Inquiry.Outcomes = function () {
    var addButton,
        editModal,
        editTemplate,
        editTemplateOptions,
        outcomePanel,
        panelTemplate,
        viewItem;

    editTemplate = '<tpl for=".">' +
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
                //'<button class="air2-rowedit"></button>' +
            '</div>' +
        '</div>' +
    '</tpl>';

    editTemplateOptions = {
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
                    p = ' Source';
                }
                else {
                    p = ' Sources';
                }

                s += (s.length ? ', ' : '') + v.src_count + p;
            }
            if (v.prj_count && v.prj_count > 0) {
                if (v.prj_count === 1) {
                    p =  ' Project';
                }
                else {
                    p = ' Projects';
                }
                s += (s.length ? ', ' : '') + v.prj_count + p;
            }
            return '<span class="datewho">' + s + '</span>';
        }
    };

    editModal = {
        title: 'Query PINfluence',
        allowNew: 'Create PINfluence',
        createNewFn: AIR2.Outcome.Create,
        createNewCfg: {
            inq_uuid: AIR2.Inquiry.UUID
        },
        width: 670,
        height: 500,
        items: {
            xtype: 'air2pagingeditor',
            url: AIR2.Inquiry.URL + '/outcome',
            multiSort: 'out_dtim desc',
            itemSelector: '.outcome-row',
            plugins: [AIR2.UI.PagingEditor.InlineControls],
            tpl: new Ext.XTemplate(editTemplate, editTemplateOptions)
        }
    };

    panelTemplate =  new Ext.XTemplate(
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

    addButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        iconCls: 'air2-icon-outcome',
        title: 'Add PINfluence',
        text: 'Add PINfluence',
        handler: function (button, event) {
            AIR2.Outcome.Create({
                src_uuid: AIR2.Source.UUID,
                originEl: this.el,
                callback: function (success) {
                    if (success) {
                        outcomePanel.reload();
                    }
                }
            });
        }
    });

    viewItem = new Ext.Toolbar.TextItem({
        html:
            '<a href="' + AIR2.Inquiry.OUTSRCH + '" ' +
            'qtip="View all PINfluence">View all</a>'
    });

    outcomePanel = new AIR2.UI.Panel({
        airTotal: AIR2.Inquiry.OUTDATA.radix.length,
        cls: 'air2-inquiry-outcome',
        collapsible: false,
        colspan: 1,
        editModal: editModal,
        fbar: [addButton, '->', viewItem],
        iconCls: 'air2-icon-outcome',
        itemSelector: '.outcome-row',
        showAllLink: AIR2.Inquiry.OUTSRCH,
        showTotal: true,
        storeData: AIR2.Inquiry.OUTDATA,
        title: 'PINfluence',
        tpl: panelTemplate,
        url: AIR2.Inquiry.URL + '/outcome'
    });

    outcomePanel.on('afterrender', function (panel) {
        var store;

        store = panel.store;

        // update tab count
        store.on('load', function (store, action, result, res, rs) {
            var tab, tabIndex;
            tabIndex = AIR2.Inquiry.Cards.items.indexOf(panel);
            tab = AIR2.Inquiry.Tabs.items.itemAt(tabIndex);
            tab.updateTabTotal(tab, store.getCount());
            if (AIR2.APP) {
                AIR2.APP.syncSize();
            }
        });

        if (AIR2.APP) {
            AIR2.APP.syncSize();
        }
    });


    return outcomePanel;
};
