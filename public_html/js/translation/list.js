/***************
 * List/edit panel for AIR2 fact translations
 */
AIR2.Translation.List = function () {
    var basecodes,
        codeFilter,
        dv,
        dvTemplate,
        pnl,
        textFilter,
        typeFilter;

    // primary dataview display
    dvTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            '<tr class="header">' +
                    '<th class="sortable text" air2fld="xm_xlate_from">' +
                            '<span>Text</span>' +
                    '</th>' +
                    '<th class="sortable code" air2fld="fv_value">' +
                            '<span>Code</span>' +
                    '</th>' +
                    '<th class="sortable text" air2fld="xm_cre_dtim">' +
                            '<span>Created On</span>' +
                    '</th>' +
                    '<th class="row-ops"></th>' +
            '</tr>' +
            '<tpl for=".">' +
                    '<tr class="trans-row">' +
                            '<td>{[values.xm_xlate_from]}</td>' +
                            '<td>{[this.getFactVal(values)]}</td>' +
                            '<td>{[AIR2.Format.dateLong(values.xm_cre_dtim)]}</td>' +
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
            getFactVal: function (values) {
                return (values.FactValue) ? values.FactValue.fv_value : '';
            }
        }
    );

    dv = new AIR2.UI.PagingEditor({
        pageSize: 18,
        cls: 'air2-translation',
        url: AIR2.Translation.URL,
        data: AIR2.Translation.DATA,
        baseParams: AIR2.Translation.PARMS,
        plugins: [
            AIR2.UI.PagingEditor.InlineControls,
            AIR2.UI.PagingEditor.HeaderSort
        ],
        allowEdit: AIR2.Translation.AUTHZ.may_write,
        allowDelete: AIR2.Translation.AUTHZ.may_write,
        itemSelector: '.trans-row',
        tpl: dvTemplate,
        editRow: function (dv, node, rec) {
            var code,
                codeEl,
                text,
                textEl;

            textEl = Ext.fly(node).first('td');
            textEl.update('').setStyle('padding', '4px');
            text = new AIR2.UI.RemoteText({
                value: rec.data.xm_xlate_from,
                name: 'xm_xlate_from',
                remoteTable: 'translation',
                uniqueErrorText: 'Translation already exists',
                params: {xm_fact_id: rec.data.xm_fact_id},
                renderTo: textEl,
                allowBlank: false,
                width: 300
            });
            codeEl = textEl.next().update('').setStyle('padding', '4px');
            code = new AIR2.UI.ComboBox({
                value: rec.data.xm_xlate_to_fv_id,
                choices: typeFilter.getCodes(),
                renderTo: codeEl,
                allowBlank: false,
                width: 170
            });
            return [text, code];
        },
        saveRow: function (rec, edits) {
            rec.set('xm_xlate_from', edits[0].getValue());
            rec.set('xm_xlate_to_fv_id', edits[1].getValue());
        }
    });
    AIR2.Translation.DATAVIEW = dv; //global ref

    // page-wide type filtering
    typeFilter = new AIR2.UI.ComboBox({
        value: AIR2.Translation.PARMS.type,
        choices: AIR2.Translation.FACTS,
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('type', rec.data.value);
                dv.store.setBaseParam('code', null); //unset
                dv.store.setBaseParam('q', null); //unset
                dv.pager.changePage(0);

                // update the filters for this type
                codeFilter.reset();
                textFilter.reset();
            }
        },
        getCodes: function () {
            var codeChoices,
                type;

            type = this.getValue();
            codeChoices = [];
            Ext.iterate(AIR2.Fixtures.Facts, function (key, val) {
                if (!type || type === key) {
                    codeChoices = codeChoices.concat(val);
                }
            });
            return codeChoices;
        }
    });
    AIR2.Translation.TYPEBOX = typeFilter; //global ref

    // panel-specific filtering
    basecodes = [['', '(Show All)']];
    codeFilter = new AIR2.UI.ComboBox({
        value: AIR2.Translation.PARMS.code,
        choices: basecodes.concat(typeFilter.getCodes()),
        emptyText: 'by code',
        width: 150,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('code', rec.data.value);
                dv.pager.changePage(0);
            }
        },
        reset: function () {
            this.store.loadData(basecodes.concat(typeFilter.getCodes()));
            AIR2.UI.ComboBox.superclass.reset.call(this);
        }
    });
    textFilter = new Ext.form.TextField({
        width: 230,
        emptyText: 'Filter Text',
        validationDelay: 500,
        validateValue: function (v) {
            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-1, 2]);
                this.clearAction.hide();
                this.remoteAction.show();

                // reload the store
                dv.store.setBaseParam('q', v);
                dv.store.on(
                    'load',
                    function () {
                        this.remoteAction.hide();
                        this.clearAction.show();
                    },
                    this,
                    {single: true}
                );
                dv.pager.changePage(0);
                this.lastValue = v;
            }
        },
        lastValue: '',
        listeners: {
            afterrender: function (p) {
                p.remoteAction = p.el.insertSibling(
                    {cls: 'air2-form-remote-wait'}
                );
                p.clearAction = p.el.insertSibling({cls: 'air2-form-clear'});
                p.clearAction.alignTo(p.el, 'tr-tr', [1, 13]);
                p.clearAction.show();
                p.clearAction.on('click', function () { p.reset(); });
            }
        }
    });

    // create paging panel for dataview
    pnl = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Translations',
        cls: 'air2-translation',
        iconCls: 'air2-icon-translation',
        tools: ['->', '<b>Show:</b>', typeFilter],
        store: dv.store,
        showTotal: true,
        items: [{
            xtype: 'container',
            layout: 'hbox',
            defaults: {margins: '10 10 10 0'},
            items: [
                textFilter,
                {xtype: 'displayfield', html: 'and/or'},
                codeFilter
            ]
        }, dv]
    });

    // total handler
    dv.store.on('load', function () {
        pnl.setTotal(dv.store.getTotalCount());
    });
    pnl.setTotal(dv.store.getTotalCount());

    // return panel
    return pnl;
};
