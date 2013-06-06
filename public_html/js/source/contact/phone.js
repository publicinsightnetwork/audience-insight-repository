Ext.ns('AIR2.Source.Contact');
/***************
 * Source Contact Modal - Phone tab
 */
AIR2.Source.Contact.Phone = function () {
    var template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw center"><span>Primary</span></th>' +
                '<th><span>Type</span></th>' +
                '<th><span>Country</span></th>' +
                '<th><span>Number</span></th>' +
                '<th><span>Ext</span></th>' +
                '<th class="row-ops">' +
                    '<tpl if="' + AIR2.Source.BASE.authz.may_write + '">' +
                        '<button class="air2-rowadd"></button>' +
                    '</tpl>' +
                '</th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="phone-row">' +
                    '<td class="center"><tpl if="sph_primary_flag">' +
                        '<span class="air2-icon air2-icon-check"></span>' +
                    '</tpl></td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"sph_context",' +
                            'values.sph_context' +
                        ')]}' +
                    '</td>' +
                    '<td>{sph_country}</td>' +
                    '<td>{[AIR2.Format.formatPhone(values.sph_number)]}</td>' +
                    '<td>{sph_ext}</td>' +
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

    return new AIR2.UI.PagingEditor({
        title: 'Phone',
        url: AIR2.Source.URL + '/phone',
        multiSort: 'sph_primary_flag desc, sph_cre_dtim desc',
        newRowDef: {sph_primary_flag: false},
        allowEdit: AIR2.Source.BASE.authz.may_write,
        allowDelete: AIR2.Source.BASE.authz.may_write,
        itemSelector: '.phone-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: template,
        editRow: function (dv, node, rec) {
            var cntry,
                cntryEl,
                edits,
                exten,
                extEl,
                num,
                numEl,
                prime,
                primeEl,
                type,
                typeEl;

            // cache dv ref
            rec.dv = dv;
            edits = [];

            // primary
            primeEl = Ext.fly(node).first('td').update('');
            prime = new Ext.form.Checkbox({
                checked: rec.data.sph_primary_flag,
                disabled: rec.data.sph_primary_flag,
                renderTo: primeEl
            });
            edits.push(prime);

            // type
            typeEl = primeEl.next().update('').setStyle('padding', '4px');
            type = new AIR2.UI.ComboBox({
                choices: AIR2.Fixtures.CodeMaster.sph_context,
                value: rec.data.sph_context,
                renderTo: typeEl,
                width: 74
            });
            edits.push(type);

            // country
            cntryEl = typeEl.next().update('').setStyle('padding', '4px');
            cntry = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '3'
                },
                value: rec.data.sph_country,
                renderTo: cntryEl,
                width: 50
            });
            edits.push(cntry);

            // number
            numEl = cntryEl.next().update('').setStyle('padding', '4px');
            num = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '16'
                },
                allowBlank: false,
                value: rec.data.sph_number,
                renderTo: numEl,
                width: 100
            });
            edits.push(num);

            // extension
            extEl = numEl.next().update('').setStyle('padding', '4px');
            exten = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '12'
                },
                value: rec.data.sph_ext,
                renderTo: extEl,
                width: 50
            });
            edits.push(exten);
            return edits;
        },
        saveRow: function (rec, edits) {
            // if saving a primary_flag, need to unset others in UI
            var prime = edits[0].getValue();
            if (!rec.phantom && !rec.data.sph_primary_flag && prime) {
                rec.store.on(
                    'save',
                    function (s) {
                        s.each(function (r) {
                            if (rec.id !== r.id) {
                                r.data.sph_primary_flag = false;
                                rec.dv.refreshNode(rec.dv.indexOf(r));
                            }
                        });
                    },
                    this,
                    {single: true}
                );
            }

            // update record
            rec.set('sph_primary_flag', edits[0].getValue());
            rec.set('sph_context', edits[1].getValue());
            rec.set('sph_country', edits[2].getValue());
            rec.set('sph_number', edits[3].getValue());
            rec.set('sph_ext', edits[4].getValue());
        }
    });
};
