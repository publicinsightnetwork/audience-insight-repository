/***************
 * User Networks Panel
 */
AIR2.User.Networks = function () {
    var editTemplate,
        template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Type</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="network-row">' +
                    '<td>' +
                        '<a class="external" target="_blank" ' +
                            'href="{uuri_value}">' +
                            '{[AIR2.Format.codeMaster(' +
                                '"uuri_type",' +
                                'values.uuri_type' +
                            ')]}' +
                        '</a>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    formatSupportLink = function (values) {
    	var total, returnString;

    	total = values.meta.total;
    	returnString = '<span class="air2-user-network-support header-total">' +
		total + ' Total </span> <a class="air2-user-network-support" href="http://support.publicinsightnetwork.org/entries/23170363">' +
    	'Support: Guidelines for adding intro video</a>';
    	return returnString;
    }

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Type</span></th>' +
                '<th><span>Link</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="network-row">' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"uuri_type",' +
                            'values.uuri_type' +
                        ')]}' +
                    '</td>' +
                    '<td>' +
                        '<a class="external" target="_blank" ' +
                        'href="{uuri_value}">' +
                            '{uuri_value}' +
                        '</a>' +
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
            disableFormats: true
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Links',
        showTotal: true,
        iconCls: 'air2-icon-link',
        storeData: AIR2.User.NETDATA,
        url: AIR2.User.URL + '/network',
        itemSelector: '.network-row',
        tpl: template,
        modalAdd: 'Add Link',
        editModal: {
            title: 'User Links ' + formatSupportLink(AIR2.User.NETDATA),
            allowAdd: AIR2.User.BASE.authz.may_write,
            width: 600,
            height: 300,
            showTotal: false,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.User.URL + '/network',
                multiSort: 'uuri_handle asc',
                newRowDef: {},
                allowEdit: AIR2.User.BASE.authz.may_write,
                allowDelete: AIR2.User.BASE.authz.may_write,
                itemSelector: '.network-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        link,
                        linkEl,
                        type,
                        typeEl;

                    edits = [];
                    typeEl = Ext.fly(node).first('td');
                    typeEl.update('');
                    type = new AIR2.UI.ComboBox({
                        allowBlank: false,
                        choices: AIR2.Fixtures.CodeMaster.uuri_type,
                        width: 100,
                        renderTo: typeEl,
                        value: rec.data.uuri_type
                    });
                    edits.push(type);

                    linkEl = typeEl.next().update('');
                    link = new Ext.form.TextField({
                        allowBlank: false,
                        vtype: 'url',
                        width: 320,
                        renderTo: linkEl,
                        value: rec.data.uuri_value
                    });
                    
                    dv.store.on('save', function(rec) {
                    	var totalSpan = Ext.get(Ext.select('span.air2-user-network-support').elements[0]);
                    	if (totalSpan && rec.totalLength) {
                    		totalSpan.dom.innerHTML = rec.data.items.length + ' Total';
                    	}
                    });
                    edits.push(link);
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('uuri_type', edits[0].getValue());
                    rec.set('uuri_value', edits[1].getValue());
                }
            }
        }
    });
};
