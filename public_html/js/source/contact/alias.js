Ext.ns('AIR2.Source.Contact');
/***************
 * Source Contact Modal - Alias tab
 */
AIR2.Source.Contact.Alias = function () {
    var template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right"><span>Type</span></th>' +
                '<th><span>Value</span></th>' +
                '<th><span>Created By</span></th>' +
                '<th class="row-ops">' +
                    '<tpl if="' + AIR2.Source.BASE.authz.may_write + '">' +
                        '<button class="air2-rowadd"></button>' +
                    '</tpl>' +
                '</th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="alias-row">' +
                    '<td class="right">' +
                        '<b>{[this.formatType(values)]}</b>' +
                    '</td>' +
                    '<td>{[this.formatValue(values)]}</td>' +
                    '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit">' +
                        '</button><button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatType: function (v) {
                if (v.sa_first_name) {
                    return 'First Name';
                }
                if (v.sa_last_name) {
                    return 'Last Name';
                }

                return '<span class="lighter">(unknown)</span>';
            },
            formatValue: function (v) {
                if (v.sa_first_name) {
                    return v.sa_first_name;
                }
                if (v.sa_last_name) {
                    return v.sa_last_name;
                }
                return '<span class="lighter">(unknown)</span>';
            }
        }
    );

    return new AIR2.UI.PagingEditor({
        title: 'Alias',
        url: AIR2.Source.URL + '/alias',
        multiSort: 'sa_cre_dtim desc',
        newRowDef: {CreUser: ''},
        allowEdit: AIR2.Source.BASE.authz.may_write,
        allowDelete: AIR2.Source.BASE.authz.may_write,
        itemSelector: '.alias-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: template,
        editRow: function (dv, node, rec) {
            var edits,
                mytype,
                type,
                typeEl,
                value,
                aliasValue,
                valueEl;

            // value
            valueEl = Ext.fly(node).first('td').next().update('');
            aliasValue = this.getAlias(rec.data);
            Logger(aliasValue);
            value = new Ext.form.TextField({
                width: 200,
                autoCreate: {tag: 'input', type: 'text', maxlength: '64'},
                allowBlank: false,
                renderTo: valueEl,
                value: aliasValue
            });
            edits = [value];

            // type (new only)
            if (rec.phantom) {
                typeEl = Ext.fly(node).first('td').update('');
                mytype = rec.data.sa_last_name ? 'last' : 'first';
                type = new AIR2.UI.ComboBox({
                    choices: [['first', 'First Name'], ['last', 'Last Name']],
                    value: mytype,
                    renderTo: typeEl,
                    width: 94
                });
                type.wrap.setStyle('float', 'right');
                edits.push(type);
            }
            return edits;
        },
        getAlias: function (data) {
            if (data.sa_first_name) {
                return data.sa_first_name;
            }
            else {
                return data.sa_last_name;
            }
        },
        saveRow: function (rec, edits) {
            // update record
            var fld = rec.data.sa_last_name ? 'last' : 'first';
            if (edits.length === 2) {
                fld = edits[1].getValue();
            }
            fld = 'sa_' + fld + '_name';
            rec.set(fld, edits[0].getValue());
        }
    });
};
