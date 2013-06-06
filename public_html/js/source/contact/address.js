Ext.ns('AIR2.Source.Contact');
/***************
 * Source Contact Modal - Address tab
 */
AIR2.Source.Contact.Address = function () {
    var template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw center"><span>Primary</span></th>' +
                '<th><span>Type</span></th>' +
                '<th><span>Street</span></th>' +
                '<th><span>City, State, Postal Code</span></th>' +
                '<th><span>County</span></th>' +
                '<th><span>Country</span></th>' +
                '<th class="row-ops">' +
                    '<tpl if="' + AIR2.Source.BASE.authz.may_write + '">' +
                        '<button class="air2-rowadd"></button>' +
                    '</tpl>' +
                '</th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="address-row">' +
                    '<td class="center"><tpl if="smadd_primary_flag">' +
                        '<span class="air2-icon air2-icon-check"></span>' +
                    '</tpl></td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"smadd_context",values.smadd_context' +
                        ')]}' +
                    '</td>' +
                    '<td>{[this.formatStreet(values)]}</td>' +
                    '<td>{[this.formatCity(values)]}</td>' +
                    '<td>{[this.formatCounty(values)]}</td>' +
                    '<td>{[this.formatCountry(values)]}</td>' +
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
            formatStreet: function (values) {
                var str;

                if (values.smadd_line_1) {
                    str = values.smadd_line_1;
                    if (values.smadd_line_2) {
                        str += '<br/>' + values.smadd_line_2;
                    }
                    return str;
                }
                if (values.smadd_line_2) {
                    return values.smadd_line_2;
                }
                return '<span class="lighter">(none)</span>';
            },
            formatCity: function (values) {
                var str = '';
                if (values.smadd_city) {
                    str += values.smadd_city;
                }
                if (values.smadd_state) {
                    str += str.length ? ', ' : '';
                    str += values.smadd_state;
                }
                if (values.smadd_zip) {
                    str += str.length ? ' ' : '';
                    str += values.smadd_zip;
                }
                return str.length ? str : '<span class="lighter">(none)</span>';
            },
            formatCounty: function (values) {
                if (values.smadd_county) {
                    return values.smadd_county;
                }
                return '<span class="lighter">(none)</span>';
            },
            formatCountry: function (values) {
                if (values.smadd_cntry) {
                    return values.smadd_cntry;
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    return new AIR2.UI.PagingEditor({
        title: 'Address',
        url: AIR2.Source.URL + '/address',
        multiSort: 'smadd_primary_flag desc, smadd_cre_dtim desc',
        newRowDef: {smadd_primary_flag: false},
        allowEdit: AIR2.Source.BASE.authz.may_write,
        allowDelete: AIR2.Source.BASE.authz.may_write,
        itemSelector: '.address-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: template,
        editRow: function (dv, node, rec) {
            var city,
                cityEl,
                cntry,
                cntryEl,
                div,
                div2,
                edits,
                prime,
                primeEl,
                state,
                str1,
                str2,
                strEl,
                type,
                typeEl,
                zip;

            // cache dv ref
            rec.dv = dv;
            edits = [];

            // primary
            primeEl = Ext.fly(node).first('td').update('');
            prime = new Ext.form.Checkbox({
                checked: rec.data.smadd_primary_flag,
                disabled: rec.data.smadd_primary_flag,
                renderTo: primeEl
            });
            edits.push(prime);

            // type
            typeEl = primeEl.next().update('').setStyle('padding', '4px');
            type = new AIR2.UI.ComboBox({
                choices: AIR2.Fixtures.CodeMaster.smadd_context,
                value: rec.data.smadd_context,
                renderTo: typeEl,
                width: 74
            });
            edits.push(type);

            // street1 and street2
            div = '<div style="padding:3px"></div>';
            strEl = typeEl.next().update(div + div).setStyle('padding', '2px');
            str1 = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '128'
                },
                emptyText: 'Line 1',
                value: rec.data.smadd_line_1,
                renderTo: strEl.first(),
                width: 110
            });
            str2 = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '128'
                },
                emptyText: 'Line 2',
                value: rec.data.smadd_line_2,
                renderTo: strEl.last(),
                width: 110
            });
            edits.push(str1, str2);

            // city, state, zip
            div2 = '<div style="padding:3px"><span style="float:left">';
            div2 += '</span><span style="padding-left:4px"></span></div>';
            cityEl = strEl.next().update(div + div2).setStyle('padding', '2px');
            city = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '128'
                },
                emptyText: 'City',
                value: rec.data.smadd_city,
                renderTo: cityEl.first(),
                width: 130
            });
            state = new AIR2.UI.ComboBox({
                emptyText: 'State',
                choices: AIR2.Fixtures.States,
                tpl:
                    '<tpl for=".">' +
                        '<div class="x-combo-list-item">' +
                            '{display}' +
                        '</div>' +
                    '</tpl>',
                displayField: 'value',
                listAlign: ['tr-br?', [16, 0]],
                listWidth: 120,
                value: rec.data.smadd_state,
                renderTo: cityEl.last().first(),
                width: 68,
                editable: true,
                typeAhead: true
            });
            zip = new Ext.form.TextField({
                autoCreate: {
                    tag: 'input',
                    type: 'text',
                    autocomplete: 'off',
                    maxlength: '10'
                },
                emptyText: 'Postal Code',
                value: rec.data.smadd_zip,
                renderTo: cityEl.last().last(),
                width: 58
            });
            edits.push(city, state, zip);

            // country
            cntryEl = cityEl.next().next().update('').setStyle(
                'padding',
                '2px'
            );
            cntry = new AIR2.UI.ComboBox({
                emptyText: 'Country',
                choices: AIR2.Fixtures.Countries,
                tpl:
                    '<tpl for=".">' +
                        '<div class="x-combo-list-item">' +
                            '{display}' +
                        '</div>' +
                    '</tpl>',
                displayField: 'value',
                listAlign: ['tr-br?', [16, 0]],
                listWidth: 120,
                value: rec.data.smadd_cntry,
                renderTo: cntryEl,
                width: 72
            });
            edits.push(cntry);
            return edits;
        },
        saveRow: function (rec, edits) {
            var allBlank, prime;

            // don't allow saving a completely blank record
            allBlank = true;
            Ext.each(edits, function (item) {
                if (item.getValue()) {
                    allBlank = false;
                }
            });
            if (allBlank) {
                return false; //breaks save
            }

            // if saving a primary_flag, need to unset others in UI
            prime = edits[0].getValue();
            if (!rec.phantom && !rec.data.smadd_primary_flag && prime) {
                rec.store.on('save', function (s) {
                    s.each(function (r) {
                        if (rec.id !== r.id) {
                            r.data.smadd_primary_flag = false;
                            rec.dv.refreshNode(rec.dv.indexOf(r));
                        }
                    });
                }, this, {single: true});
            }

            // update record
            rec.set('smadd_primary_flag', edits[0].getValue());
            rec.set('smadd_context', edits[1].getValue());
            rec.set('smadd_line_1', edits[2].getValue());
            rec.set('smadd_line_2', edits[3].getValue());
            rec.set('smadd_city', edits[4].getValue());
            rec.set('smadd_state', edits[5].getValue());
            rec.set('smadd_zip', edits[6].getValue());
            rec.set('smadd_cntry', edits[7].getValue());
        }
    });
};
