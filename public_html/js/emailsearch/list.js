/***************
 * EmailSearch Mail List Panel
 */
AIR2.EmailSearch.List = function() {
    var xtpl, dv, store, pager;

    // initial parameters
    AIR2.EmailSearch.PARAMS = AIR2.EmailSearch.BASE.meta.query;

    // create the template based on shown/hidden columns
    makeTemplate = function () {
        AIR2.Email.MENUFN = {};
        var hdrs = '', flds = '', cols = AIR2.Email.getVisible();
        Ext.each(cols, function (def) {
            var c = def.cls;
            if (def.sortable) {
                hdrs += '<th class="sortable ' + c + '" ';
                hdrs += 'air2fld="' + def.field + '" ';
                if (def.sortable == 'asc') {
                    hdrs += 'air2dir="desc" ';
                }
                else {
                    hdrs += 'air2dir="asc" ';
                }
                hdrs += '>';
            }
            else {
                hdrs += '<th class="' + c + '">';
            }
            hdrs += '<span>' + def.header + '</span></th>';
            if (Ext.isFunction(def.format)) {
                AIR2.Email.MENUFN[def.field] = def.format;
                flds += '<td class="' + c + '">{[AIR2.Email.MENUFN.';
                flds += def.field + '(values)]}</td>';
            }
            else {
                flds += '<td class="' + c + '">' + def.format + '</td>';
            }
        });

        // optional "duplicate email" buttons
        if (AIR2.Util.Authz.has('ACTION_EMAIL_CREATE')) {
            hdrs += '<th class="fixw right"><span>Duplicate</span></th>';
            flds += '<td class="row-ops"><button class="air2-rowdup"></button></span>';
        }

        return new Ext.XTemplate(
            '<table class="air2-tbl">' +
                // header
                '<tr class="header">' + hdrs + '</tr>' +
                // rows
                '<tpl for=".">' +
                    '<tr class="email-row {[this.rowClasses(values, xindex)]}">' +
                         flds + // configurable fields
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.length==0">' +
                    '<tr><td colspan="99" class="none-found">' +
                        '<h1>No Emails Found</h1>' +
                    '</td></tr>' +
                '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: false,
                rowClasses: function (v, idx) {
                    return (idx % 2 === 0) ? 'row-alt' : '';
                }
            }
        );
    };
    dv = new AIR2.UI.PagingEditor({
        pageSize: 15,
        url: AIR2.EmailSearch.URL,
        data: AIR2.EmailSearch.BASE,
        baseParams: AIR2.EmailSearch.PARAMS,
        plugins: [AIR2.UI.PagingEditor.HeaderSort],
        itemSelector: '.email-row',
        tpl: makeTemplate(),
        listeners: {
            click: function (dv, idx, node, e) {
                var t;
                if (t = e.getTarget('.air2-rowdup')) {
                    AIR2.Email.Create({
                        duplicate: dv.getRecord(node),
                        originEl: t,
                        redirect: true
                    });
                }
            }
        }
    });

    // setup combo-box filtering tools
    mineFilter = new Ext.form.Checkbox({
        boxLabel: 'Only mine',
        checked: AIR2.EmailSearch.PARAMS.mine,
        listeners: {
            check: function (cb, checked) {
                dv.store.setBaseParam('mine', checked ? 1 : 0);
                dv.mask();
                dv.pager.changePage(0);
            }
        }
    });
    statusFilter = new AIR2.UI.ComboBox({
        value: AIR2.EmailSearch.PARAMS.status,
        choices: [
            ['AQD', 'All'],
            ['D',   'Draft'],
            ['Q',   'Scheduled'],
            ['A',   'Sent'],
            ['F',   'Archived']
        ],
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('status', rec.data.value);
                dv.mask();
                dv.pager.changePage(0);
            }
        }
    });
    typeFilter = new AIR2.UI.ComboBox({
        value: AIR2.EmailSearch.PARAMS.type,
        choices: [
            ['',  'All'],
            ['Q', 'Query'],
            ['F', 'Follow Up'],
            ['R', 'Reminder'],
            ['T', 'Thank You'],
            ['O', 'Other']
        ],
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('type', rec.data.value);
                dv.mask();
                dv.pager.changePage(0);
            }
        }
    });

    // text filter box
    textFilter = new Ext.form.TextField({
        width: 230,
        margins: '10 100 10 0',
        cls: 'email-text-filter',
        emptyText: 'Filter Emails',
        validationDelay: 500,
        queryParam: 'q',
        validateValue: function (v) {
            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-3, 4]);
                this.remoteAction.show();
                dv.store.setBaseParam(this.queryParam, v);
                dv.store.on('load', function() {
                    this.remoteAction.hide();
                }, this, {single: true});
                dv.mask();
                dv.pager.changePage(0);
                this.lastValue = v;
            }
        },
        value: AIR2.EmailSearch.PARAMS.q,
        lastValue: AIR2.EmailSearch.PARAMS.q,
        listeners: {
            render: function (p) {
                p.remoteAction = p.el.insertSibling({
                    cls: 'air2-form-remote-wait'
                });
            }
        }
    });

    // column display picker
    var columnPicker = new AIR2.UI.Button({
        text: 'Columns',
        iconCls: 'air2-icon-list',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        margins: '10 10 10 0',
        menu: {
            defaultOffsets: [3, -3],//[5, -6],
            showSeparator: false,
            shadow: false
        }
    });
    Ext.iterate(AIR2.Email.MENU, function (fld, label) {
        columnPicker.menu.addMenuItem({
            name: fld,
            text: label,
            coldef: AIR2.Email.COLUMNS[fld],
            checked: AIR2.Email.isVisible(fld),
            hideOnClick: false,
            checkHandler: function (cb, checked) {
                AIR2.Email.setVisible(cb.name, checked);
                dv.tpl = makeTemplate();
                dv.refresh();
            }
        });
    });

    // "NEW" button
    newEmailBtn = new AIR2.UI.Button({
        text: 'New Email',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        iconCls: 'air2-icon-add',
        margins: '10 10 10 0',
        handler: function () {
            AIR2.Email.Create({
                originEl: newEmailBtn.el,
                redirect: true
            });
        },
        hidden: !AIR2.Util.Authz.has('ACTION_EMAIL_CREATE')
    });

    // build panel
    AIR2.EmailSearch.List = new AIR2.UI.Panel({
        colspan: 3,
        rowspan: 1,
        showTotal: true,
        showHidden: true,
        title: 'Search Emails',
        cls: 'air2-email-search',
        iconCls: 'air2-icon-magnifier',
        store: store,
        tools: ['->', '<b>Show:</b>', mineFilter, '  ', statusFilter, '  ', typeFilter],
        items: [{
            xtype: 'container',
            layout: 'hbox',
            cls: 'search-tools',
            items: [textFilter, columnPicker, newEmailBtn]
        }, dv]
    });

    return AIR2.EmailSearch.List;
};
