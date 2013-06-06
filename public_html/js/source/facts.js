/********************
 * Source Facts Panel
 */

/**
 * Exported functionality for getting the value of a fact (which may be the
 * source's manual entry, or the analyst's entry).
 *
 * @param values
 */
AIR2.Source.factValue = function (values) {
    if (values.AnalystFV) {
        return values.AnalystFV.fv_value;
    }
    if (values.SourceFV) {
        return values.SourceFV.fv_value;
    }
    if (values.sf_src_value) {
        return '<pre>' + values.sf_src_value + '</pre>';
    }
    return '<span class="lighter">(none)</span>';
};

/**
 * Facts panel
 */
AIR2.Source.Facts = function () {
    var editTemplate, template, titleLock;

    // include account-lock in title
    titleLock = AIR2.Source.LOCK ? ('&nbsp;' + AIR2.Source.LOCK) : '';

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Field</span></th>' +
                '<th><span>Value</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="fact-row">' +
                    '<td><b>{[values.Fact.fact_name]}</b></td>' +
                    '<td>{[this.formatFactValue(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatFactValue: function (values) {
                var formattedFactValue = '';
                if (values.Fact.fact_name === 'Household Income') {
                    formattedFactValue = AIR2.Format.householdIncome(
                        values
                    );
                }
                else {
                    formattedFactValue = AIR2.Source.factValue(values);
                }
                return formattedFactValue;
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Created</span></th>' +
                '<th><span>Field</span></th>' +
                '<th><span>Analyst (Selected)</span></th>' +
                '<th><span>Source (Selected)</span></th>' +
                '<th><span>Source (Explanation)</span></th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="fact-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.sf_cre_dtim)]}' +
                    '</td>' +
                    '<td><b>{[values.Fact.fact_name]}</b></td>' +
                    '<td>{[this.formatFV(values)]}</td>' +
                    '<td>{[this.formatSrcFV(values)]}</td>' +
                    '<td>{[this.formatSrc(values)]}</td>' +
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
            formatFV: function (values) {
                var type = values.Fact.fact_fv_type;
                if (type === 'M' || type === 'F') {
                    if (values.AnalystFV) {
                        if (
                            values.Fact.fact_name ===
                            'Household Income'
                        ) {
                            return AIR2.Format.householdIncome(
                                values.AnalystFV.fv_value
                            );
                        }
                        return values.AnalystFV.fv_value;
                    }
                    return '<span class="lighter">(none)</span>';
                }
                return ''; //non-mapped fact
            },
            formatSrcFV: function (values) {
                var type = values.Fact.fact_fv_type;
                if (type === 'M' || type === 'F') {
                    if (values.SourceFV) {
                        if (
                            values.Fact.fact_name ===
                            'Household Income'
                        ) {
                            return AIR2.Format.householdIncome(
                                values.SourceFV.fv_value
                            );
                        }
                        return values.SourceFV.fv_value;
                    }
                    return '<span class="lighter">(none)</span>';
                }
                return ''; //non-mapped fact
            },
            formatSrc: function (values) {
                var type = values.Fact.fact_fv_type;
                if (type === 'M' || type === 'S') {
                    if (values.sf_src_value) {
                        if (
                            values.Fact.fact_name ===
                            'Household Income'
                        ) {
                            return AIR2.Format.householdIncome(
                                values.sf_src_value
                            );
                        }
                        return values.sf_src_value;
                    }
                    return '<span class="lighter">(none)</span>';
                }
                return ''; //non-text fact
            }
        }
    );


    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Demographics' + titleLock,
        iconCls: 'air2-icon-fact',
        storeData: AIR2.Source.FACTDATA,
        url: AIR2.Source.URL + '/fact',
        showTotal: true,
        itemSelector: '.fact-row',
        tpl: template,
        modalAdd: 'Add Demographic',
        editModal: {
            title: 'Source Demographics' + titleLock,
            allowAdd: AIR2.Source.BASE.authz.unlock_write, //ignore lock
            width: 750,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/fact',
                multiSort: 'fact_name asc',
                newRowDef: {Fact: ''},
                allowEdit: function (rec) {
                    if (rec.data.Fact.fact_fv_type === 'S') {
                        // string-only fact ... respect lock flag
                        return AIR2.Source.BASE.authz.may_write;
                    }
                    else {
                        // fact has analyst-map ... ignore lock flag
                        return AIR2.Source.BASE.authz.unlock_write;
                    }
                },
                allowDelete: AIR2.Source.BASE.authz.may_write,
                itemSelector: '.fact-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits = [];

                    var type = rec.data.Fact.fact_fv_type;
                    if (rec.phantom || (type === 'M' || type === 'F')) {
                        var mapEl = Ext.fly(node).first('td').next().next();
                        mapEl.update('').setStyle('padding', '2px');
                        var map = new AIR2.UI.ComboBox({
                            disabled: true,
                            allowBlank: false,
                            width: 150,
                            renderTo: mapEl,
                            setIdent: function (ident) {
                                var fixtureData = AIR2.Fixtures.Facts[ident];
                                Ext.each(fixtureData, function (data, index) {
                                    data[1] = AIR2.Format.householdIncome(
                                        data[1]
                                    );
                                });
                                this.store.loadData(fixtureData);
                                this.enable();
                            },
                            value: null
                        });
                        edits.push(map);
                        if (!rec.phantom) {
                            Logger("Before Set Ident", rec.data);
                            map.setIdent(rec.data.Fact.fact_identifier);
                            if (rec.data.sf_fv_id) map.setValue(
                                rec.data.sf_fv_id
                            );
                        }
                    }
                    if (rec.phantom || type === 'S') {
                        var txtEl = Ext.fly(node).last('td').prev();
                        txtEl.update('').setStyle('padding', '2px');
                        var text = new Ext.form.TextField({
                            disabled: rec.phantom,
                            allowBlank: false,
                            width: 150,
                            value: rec.data.sf_src_value,
                            renderTo: txtEl
                        });
                        edits.push(text);
                    }
                    if (rec.phantom) {
                        var factEl = Ext.fly(node).first('td').next();
                        factEl.update('');
                        var fact = new AIR2.UI.ComboBox({
                            allowBlank: false,
                            store: new AIR2.UI.APIStore({
                                data: AIR2.Source.FLDDATA
                            }),
                            valueField: 'fact_uuid',
                            displayField: 'fact_name',
                            listEmptyText: 'No fields remaining',
                            width: 135,
                            renderTo: factEl,
                            listeners: {
                                select: function (box, rec) {
                                    var type = rec.data.fact_fv_type;
                                    map.reset();
                                    text.reset();
                                    if (type === 'M' || type === 'F') {
                                        map.setIdent(rec.data.fact_identifier);
                                        map.enable();
                                        text.disable();
                                    }
                                    if (type === 'S') {
                                        map.disable();
                                        text.enable();
                                    }
                                }
                            }
                        });
                        edits.push(fact);

                        // remove already-used facts
                        rec.store.each(function (fvrec) {
                            if (!fvrec.phantom) {
                                var rmv = fact.store.getById(
                                    fvrec.data.fact_uuid
                                );
                                fact.store.remove(rmv);
                            }
                        });
                    }

                    return edits;
                },
                saveRow: function (rec, edits) {
                    var type, fv_id, fv_val;
                    if (rec.phantom) {
                        var fuuid = edits[2].getValue();
                        fv_id = edits[0].getValue();
                        fv_val = edits[1].getValue();
                        rec.set('fact_uuid', fuuid);

                        var fact = edits[2].store.getById(fuuid);
                        if (!fact) return false;
                        type = fact.data.fact_fv_type;
                    }
                    else {
                        fv_id = edits[0].getValue();
                        fv_val = edits[0].getValue();
                        type = rec.data.Fact.fact_fv_type;
                    }

                    // set based on fv_type
                    if (type === 'M' || type === 'F') {
                        rec.set('sf_fv_id', fv_id);
                    }
                    if (type === 'S') {
                        rec.set('sf_src_value', fv_val);
                    }
                }
            }
        }
    });
};
