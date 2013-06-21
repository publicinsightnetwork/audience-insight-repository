/**************************
 * Source Experiences Panel
 */
AIR2.Source.Experiences = function () {
    var editTemplate,
        template,
        titleLock;

    // include account-lock in title
    titleLock = AIR2.Source.LOCK ? ('&nbsp;' + AIR2.Source.LOCK) : '';

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th><span>What</span></th>' +
            '<th><span>Where</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="subm-row">' +
              '<td>{[this.formatValue(values)]}</td>' +
              '<td>{[this.formatBasis(values)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatValue: function (values) {
                if (values.sv_value) {
                    return Ext.util.Format.ellipsis(values.sv_value, 100);
                }
                return '<span class="lighter">(Unknown)</span>';
            },
            formatBasis: function (values) {
                if (values.sv_basis) {
                    return Ext.util.Format.ellipsis(values.sv_basis, 60);
                }
                return '<span class="lighter">(Unknown)</span>';
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>When</span></th>' +
            '<th><span>What</span></th>' +
            '<th><span>Where</span></th>' +
            '<th class="fixw"><span>Origin</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="exp-row">' +
              '<td class="date right">{[this.formatWhen(values)]}</td>' +
              '<td>{[this.formatValue(values)]}</td>' +
              '<td>{[this.formatBasis(values)]}</td>' +
              '<td class="date">{[this.formatOrigin(values)]}</td>' +
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
            formatWhen: function (values) {
                if (values.sv_start_date) {
                    var str = AIR2.Format.dateYear(values.sv_start_date);
                    Logger("Loading End Date", values.sv_end_date);
                    if (values.sv_end_date) {
                        str += ' to ' + AIR2.Format.dateYear(values.sv_end_date);
                    }
                    else {
                        str += ' to Present';
                    }
                    return str;
                }
                return '<span class="lighter">(unknown)</span>';
            },
            formatValue: function (values) {
                if (values.sv_value) {
                    return values.sv_value;
                }
                return '<span class="lighter">(Unknown)</span>';
            },
            formatBasis: function (values) {
                if (values.sv_basis) {
                    return values.sv_basis;
                }
                return '<span class="lighter">(Unknown)</span>';
            },
            formatOrigin: function (values) {
                return AIR2.Format.vitaOrigin(values);
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Experiences' + titleLock,
        iconCls: 'air2-icon-credential',
        storeData: AIR2.Source.EXPDATA,
        url: AIR2.Source.URL + '/experience',
        showTotal: true,
        itemSelector: '.exp-row',
        tpl: template,
        modalAdd: 'Add Experience',
        editModal: {
            title: 'Source Experiences' + titleLock,
            allowAdd: AIR2.Source.BASE.authz.may_write, //respect lock
            width: 750,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/experience',
                multiSort: 'sv_cre_dtim desc',
                newRowDef: {sv_type: 'E'},
                allowEdit: function (rec) {
                    // ignore lock for AIR1-origin
                    if (
                        rec.data.sv_origin === 'C' ||
                        rec.data.sv_origin === 'S'
                    ) {
                        return AIR2.Source.BASE.authz.unlock_write;
                    }
                    else {
                        return AIR2.Source.BASE.authz.may_write;
                    }
                },
                allowDelete: function (rec) {
                    // ignore lock for AIR1-origin
                    if (
                        rec.data.sv_origin === 'C' ||
                        rec.data.sv_origin === 'S'
                    ) {
                        return AIR2.Source.BASE.authz.unlock_write;
                    }
                    else {
                        return AIR2.Source.BASE.authz.may_write;
                    }
                },
                itemSelector: '.exp-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        currentYear,
                        year,
                        choices,
                        end,
                        start,
                        what,
                        whatEl,
                        whenEl,
                        where,
                        whereEl;

                    // when
                    edits = [];
                    whenEl = Ext.fly(node).first('td');
                    whenEl.update('<span></span> to <span></span>');
                    whenEl.setStyle('padding', '2px 4px');

                    currentYear = new Date().getFullYear();
                    choices = [];
                    for (var i = 0; i < 6; i++) { 
                        year = currentYear - i;
                        choices.push([year, year]);
                    }

                    start = new AIR2.UI.ComboBox({
                        value: AIR2.Format.dateYear(rec.data.sv_start_date),
                        choices: choices,
                        width: 90,
                        renderTo: whenEl.first()
                    }); 
                    edits.push(start);
                    choices.unshift(['', 'Present']);
                    end = new AIR2.UI.ComboBox({
                        value: AIR2.Format.dateYear(rec.data.sv_end_date),
                        choices: choices,
                        renderTo: whenEl.last(),
                        width: 90
                    });
                    edits.push(end);

                    // what
                    whatEl = whenEl.next().update('').setStyle(
                        'padding',
                        '2px 4px'
                    );
                    what = new Ext.form.TextArea({
                        allowBlank: false,
                        value: rec.data.sv_value,
                        renderTo: whatEl,
                        width: 200
                    });
                    edits.push(what);

                    // where
                    whereEl = whatEl.next().update('').setStyle(
                        'padding',
                        '2px 4px'
                    );
                    where = new Ext.form.TextField({
                        allowBlank: true,
                        value: rec.data.sv_basis,
                        renderTo: whereEl,
                        width: 200
                    });
                    edits.push(where);
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('sv_start_date', Date.parseDate(edits[0].getValue(), "Y"));
                    if(edits[1].getValue() != '') {
                        rec.set('sv_end_date', Date.parseDate(edits[1].getValue(), "Y"));
                    } 
                    else {
                        rec.set('sv_end_date', '');  
                    }
                    rec.set('sv_value', edits[2].getValue());
                    rec.set('sv_basis', edits[3].getValue());
                }
            }
        }
    });
};

