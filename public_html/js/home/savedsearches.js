/***************
 * Home Saved Searches Panel
 */
AIR2.Home.SavedSearches = function () {
    var editTemplate, template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Name</span></th>' +
                '<th class="right fixw"><span>Shared</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="ss-row">' +
                    '<td>{[this.formatLink(values)]}</td>' +
                    '<td class="right">' +
                        '{[AIR2.Format.bool(values.ssearch_shared_flag)]}' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatLink: function (values) {
                var href = AIR2.HOMEURL + '/savedsearch/' + values.ssearch_uuid;
                return '<a href="' + href + '">' + values.ssearch_name + '</a>';
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Created</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>Owner</span></th>' +
                '<th><span>Shared</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="ss-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.ssearch_cre_dtim)]}' +
                    '</td>' +
                    '<td>{[this.formatLink(values)]}</td>' +
                    '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
                    '<td>' +
                        '{[AIR2.Format.bool(values.ssearch_shared_flag)]}' +
                    '</td>' +
                    '<td class="row-ops">' +
                    '<button class="air2-rowedit"></button>' +
                    '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatLink: function (values) {
                var href = AIR2.HOMEURL + '/savedsearch/' +
                    values.ssearch_uuid;
                return '<a href="' + href + '">' +
                    values.ssearch_name + '</a>';
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Saved Searches',
        cls: 'air2-home-ss',
        iconCls: 'air2-icon-savedsearch',
        showTotal: true,
        showHidden: false,
        storeData: AIR2.Home.SSDATA,
        itemSelector: '.ss-row',
        url: AIR2.HOMEURL + '/savedsearch',
        tpl: template,
        editModal: {
            allowAdd: false,
            width: 650,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.HOMEURL + '/savedsearch',
                multiSort: 'ssearch_cre_dtim desc',
                itemSelector: '.ss-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                allowEdit: function (rec) {
                    var cre = '';

                    if (rec.data.CreUser) {
                        cre = rec.data.CreUser.user_uuid;
                    }

                    return (cre === AIR2.USERINFO.uuid);
                },
                allowDelete: function (rec) {
                    var cre = '';

                    if (rec.data.CreUser) {
                        cre = rec.data.CreUser.user_uuid;
                    }

                    return (cre === AIR2.USERINFO.uuid);
                },
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits, name, nameEl, share, shareEl;

                    edits = [];
                    nameEl = Ext.fly(node).first('td').next();
                    nameEl.update('').setStyle('padding', '2px 4px');
                    name = new Ext.form.TextField({
                        width: nameEl.getWidth() - 20,
                        maxLength: 255,
                        value: rec.data.ssearch_name,
                        renderTo: nameEl
                    });
                    edits.push(name);

                    shareEl = nameEl.next().next().update('');
                    share = new Ext.form.Checkbox({
                        checked: rec.data.ssearch_shared_flag,
                        renderTo: shareEl
                    });
                    edits.push(share);

                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('ssearch_name', edits[0].getValue());
                    rec.set('ssearch_shared_flag', edits[1].getValue());
                }
            }
        }
    });
};
