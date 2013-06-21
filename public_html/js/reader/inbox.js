/***************
 * Inbox panel (the only panel) for submissions reader
 */
AIR2.Reader.Inbox = function () {
    var collapse,
        columnPicker,
        expand,
        filter,
        filterCount,
        filterWrap,
        hbox,
        isStrict,
        makeTemplate,
        pnl,
        pnlHtml,
        pnlTools,
        starfilter,
        tip,
        title;

    AIR2.Reader.INITARGS = Ext.apply({}, AIR2.Reader.ARGS); //copy
    //Logger('initial search - ', AIR2.Reader.SEARCH);
    //Logger('initial args - ', AIR2.Reader.INITARGS);

    // create (and compile) a new Ext.XTemplate based on the
    // current column hide/show settings
    makeTemplate = function () {
        AIR2.Reader.MENUFN = {};
        var hdrs = '', flds = '', cols = AIR2.Reader.getVisible();
        Ext.each(cols, function (def) {
            var c = def.cls;
            hdrs += '<th class="' + c;
            if (def.sortable) {
                hdrs += ' sortable';
            }
            hdrs += '" air2fld="' + def.field + '">';
            hdrs += def.header + '</th>';
            if (Ext.isFunction(def.format)) {
                AIR2.Reader.MENUFN[def.field] = def.format;
                flds += '<td class="' + c + '">{[AIR2.Reader.MENUFN.';
                flds += def.field + '(values)]}</td>';
            }
            else {
                flds += '<td class="' + c + '">' + def.format + '</td>';
            }
        });
        return new Ext.XTemplate(
            '<table class="reader-table">' +
                // header
                '<tr class="header">' +
                    '<th class="handle"></th>' +
                    '<th class="checker">' +
                        '<a><input type="checkbox" class="checker-box"/></a>' +
                    '</th>' +
                     hdrs + // configurable fields
                '</tr>' +
                // selection notify
                '<tr class="notify notify-page hide">' +
                    '<td colspan="99">' +
                        '<b>10 submissions</b> selected <span>|</span> ' +
                        '<a href="#">Select all 240</a>' +
                    '</td>' +
                '</tr>' +
                '<tr class="notify notify-all hide">' +
                    '<td colspan="99">' +
                        'All <b>999 submissions</b> selected <span>|</span> ' +
                        '<a href="#">Clear selection</a>' +
                    '</td>' +
                '</tr>' +
                // rows
                '<tpl for=".">' +
                    '<tr data-srs_uuid="{srs_uuid}" class="srs-row {[this.rowClasses(values, xindex)]}">' +
                        '<td class="handle"></td>' +
                        '<td class="checker">' +
                            '<input type="checkbox" class="checker-box"/>' +
                        '</td>' +
                         flds + // configurable fields
                    '</tr>' +
                '</tpl>' +
                '<tpl if="values.length==0">' +
                    '<tr><td colspan="99" class="none-found">' +
                        '<h1>No Submissions Found</h1>' +
                    '</td></tr>' +
                '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: false,
                rowClasses: function (v, idx) {
                    var c = '';

                    if (idx % 2 === 0) {
                        c = 'row-alt';
                    }

                    if (!v.live_read) {
                        c += ' row-unread';
                    }

                    return c;
                }
            }
        );
    };

    // support article
    tip = AIR2.Util.Tipper.create(20825306);

    // primary dataview display
    AIR2.Reader.DV = new AIR2.UI.JsonDataView({
        nonapistore: true, //search format is old
        renderEmpty: true,
        data: AIR2.Reader.SEARCH,
        baseParams: AIR2.Reader.ARGS,
        paramNames: {start: 'o', limit: 'p'},
        url: AIR2.HOMEURL + '/search',
        itemSelector: '.srs-row',
        multiSelect: true,
        selectedClass: 'row-checked',
        overClass: 'row-over',
        tpl: makeTemplate()
    });

    // error handler
    AIR2.Reader.DV.store.on(
        'exception',
        function (proxy, type, action, opt, rsp, arg) {
            var msg, pos, title;

            msg = 'An unknown error has occurred';
            title = 'Remote error';

            if (rsp && rsp.responseText) {
                msg = rsp.responseText;
            }
            if (rsp && rsp.statusText) {
                title = rsp.statusText;
            }
            if (msg.match(/^No such field:/)) {
                pos = msg.indexOf(' at ');
                if (pos) {
                    msg = msg.substr(0, pos);
                }

                title = 'Syntax error';
            }

            // ignore filter errors
            if (filter.getValue() !== '') {
                filter.remoteAction.addClass('air2-form-clear');
                filterCount.update('Invalid filter');
            }
            else {
                AIR2.UI.ErrorMsg(null, title, msg, function () {
                    filter.setValue('');
                });
            }
        }
    );

    // event handlers
    AIR2.Reader.checkHandler(AIR2.Reader.DV);
    AIR2.Reader.starHandler(AIR2.Reader.DV);
    AIR2.Reader.dragHandler(AIR2.Reader.DV);
    AIR2.Reader.sortHandler(AIR2.Reader.DV);
    AIR2.Reader.publicHandler(AIR2.Reader.DV);
    AIR2.Reader.expandHandler(AIR2.Reader.DV);
    AIR2.Reader.sranHandler(AIR2.Reader.DV);
    AIR2.Reader.exclHandler(AIR2.Reader.DV);
    AIR2.Reader.srsanHandler(AIR2.Reader.DV);
    AIR2.Reader.editRespHandler(AIR2.Reader.DV);
    AIR2.Reader.showOrigHandler(AIR2.Reader.DV);
    AIR2.Reader.publishHandler(AIR2.Reader.DV);
    AIR2.Reader.tagHandler(AIR2.Reader.DV);
    AIR2.Reader.refUrl(AIR2.Reader.DV);


    // pager
    AIR2.Reader.DV.pager = new Ext.PagingToolbar({
        store: AIR2.Reader.DV.store,
        pageSize: AIR2.Reader.ARGS.p,
        displayInfo: true,
        rebuildQuery: function () {
            var newq, s;

            newq = AIR2.Reader.INITARGS.q;

            // cancel any current requests
            s = AIR2.Reader.DV.store;
            if (s.proxy.activeRequest.read) {
                Ext.Ajax.abort(s.proxy.getConnection().transId);
            }

            // get extra query parameters
            newq = filter.addToQuery(newq);
            newq = starfilter.addToQuery(newq);
            AIR2.Reader.ARGS.q = newq;
            AIR2.Reader.ARGS.M = 'filter_fields';  // redmine #5007

            // reload the store
            s.baseParams = AIR2.Reader.ARGS;
            AIR2.Reader.DV.pager.changePage(0);
        }
    });

    // load mask
    AIR2.Reader.DV.store.on('beforeload', function () {
        AIR2.Reader.DV.el.mask('loading...');
    });
    AIR2.Reader.DV.store.on('load', function () {
        AIR2.Reader.DV.el.unmask();
    });

    // column display picker
    columnPicker = new AIR2.UI.Button({
        text: 'Columns',
        iconCls: 'air2-icon-list',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        menu: {
            cls: 'air2-reader-columns',
            defaultOffsets: [5, -6],
            showSeparator: false,
            shadow: false
        }
    });
    Ext.each(AIR2.Reader.MENU, function (section) {
        var smenu = new Ext.menu.Menu({
            cls: 'air2-reader-columns',
            defaultOffsets: [3, -3],
            showSeparator: false,
            shadow: false
        });
        columnPicker.menu.addMenuItem({
            text: section.section,
            iconCls: section.iconCls,
            menu: smenu
        });
        Ext.iterate(section.items, function (fld, label) {
            smenu.addMenuItem({
                name: fld,
                text: label,
                coldef: AIR2.Reader.COLUMNS[fld],
                checked: AIR2.Reader.isVisible(fld),
                hideOnClick: false,
                checkHandler: function (cb, checked) {
                    AIR2.Reader.setVisible(cb.name, checked);
                    AIR2.Reader.DV.tpl = makeTemplate();
                    AIR2.Reader.DV.refresh();
                }
            });
        });
    });

    // tools
    filter = new Ext.form.TextField({
        width: 230,
        emptyText: 'Search within submissions',
        validationDelay: 1000,
        queryParam: 'q',
        addToQuery: function (qstr) {
            if (this.getValue() !== '') {
                if (qstr !== '') {
                    return '(' + qstr + ') AND (' + this.getValue() + ')';
                }
                else {
                    return '(' + this.getValue() + ')';
                }
            }
            return qstr;
        },
        onStoreBeforeLoad: function (s) {
            this.remoteAction.removeClass('air2-form-clear');
            this.remoteAction.show();
            filterCount.update('');
        },
        onStoreLoad: function (s, rs) {
            var hasFilter, label;

            hasFilter = (filter.getValue() !== '' || starfilter.pressed);
            if (hasFilter) {
                if (filter.getValue() !== '') {
                    filter.remoteAction.addClass('air2-form-clear');
                }
                else {
                    filter.remoteAction.hide();
                }

                if (s.getCount() === 1) {
                    label = ' Submission';
                }
                else {
                    label = ' Submissions';
                }

                filterCount.update(s.getTotalCount() + label);
            }
            else {
                filter.remoteAction.hide();
                filterCount.update('');
            }
        },
        validateValue: function (v) {
            if (v !== this.lastValue && (v === '' || v.length > 2)) {
                AIR2.Reader.DV.pager.rebuildQuery();
                this.lastValue = v;
            }
        },
        lastValue: '',
        listeners: {
            afterrender: function (p) {
                p.remoteAction = p.el.insertSibling({
                    cls: 'air2-form-remote-wait'
                });

                p.remoteAction.alignTo(p.el, 'tr-tr', [-7, 4]);
                p.remoteAction.on('click', function (el) {
                    if (p.remoteAction.hasClass('air2-form-clear')) {
                        p.setValue('');
                    }
                });
                p.el.addKeyMap([
                    { key: 37, fn: function (key, e) {e.stopPropagation(); } },
                    { key: 39, fn: function (key, e) {e.stopPropagation(); } }
                ]);

                // store load listener
                AIR2.Reader.DV.store.on('load', filter.onStoreLoad, filter);
                AIR2.Reader.DV.store.on(
                    'beforeload',
                    filter.onStoreBeforeLoad,
                    filter
                );
            }
        }
    });
    filterWrap = new Ext.Container({cls: 'filter-wrap', items: filter});
    filterCount = new Ext.BoxComponent({cls: 'filter-count', html: ''});
    expand = new AIR2.UI.Button({
        text: 'Expand All',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        handler: function () { AIR2.Reader.expandAll(); }
    });
    collapse = new AIR2.UI.Button({
        text: 'Collapse All',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        handler: function () { AIR2.Reader.collapseAll(); }
    });
    starfilter = new AIR2.UI.Button({
        text: '<input type="checkbox" /> Insightful',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        enableToggle: true,
        addToQuery: function (qstr) {
            if (starfilter.pressed) {
                if (qstr !== '') {
                    return '(' + qstr + ') AND (user_star=' +
                        AIR2.USERINFO.uuid + ')';
                }
                else {
                    return '(user_star=' + AIR2.USERINFO.uuid + ')';
                }
            }
            return qstr;
        },
        toggleHandler: function (btn, state) {
            var val;

            val = '<input type="checkbox" ';

            if (state) {
                val += 'checked';
            }

            val += '/> Insightful';

            this.setText(val);
            AIR2.Reader.DV.pager.rebuildQuery();
        }
    });
    printFriendly = new AIR2.UI.Button({
        text: '<i class="icon-print"></i> Print Selected',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        handler: function (b) {
        var dateStamp = new Date();
        var binName = AIR2.Reader.INITARGS.q + dateStamp;
        var params = {};
        var count, all_selected, selected_uuids, selected_rows;

        AIR2.APP.el.mask('Loading items to print...');

        params['bin_name'] = binName;
        params['bin_type'] = 'S';

        all_selected = Ext.get(Ext.select('.notify-all').elements[0]);
        all_selected = !all_selected.hasClass('hide');
        selected_rows = Ext.select('.srs-row.row-checked').elements;
        count = selected_rows.length;
        all_count = AIR2.Reader.DV.store.getTotalCount();
        Logger("Count", count);
        if (all_selected && all_count > 1000) {
            m = 'Print-friendly view supports up to 1000 ' +
                'submissions and you selected ' + count +
                ' submissions.<br/>Please deselect some of ' +
                'the submissions  and try again.';
            AIR2.UI.ErrorMsg(b.el, 'Sorry!', m);
            AIR2.APP.el.unmask();
        }
        else if (count == 0) {
            m = 'Print-friendly view requires at least one submission.' +
            'Please select a submission and try again.';
            AIR2.UI.ErrorMsg(b.el, 'Sorry!', m);
            AIR2.APP.el.unmask();
        }
        else {
            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/bin.json',
                params: {radix: Ext.encode(params)},
                callback: function (opts, success, resp) {
                    var data, bin_uuid, params, store, record, selected_uuids;
                    data = Ext.util.JSON.decode(resp.responseText);
                    store = new AIR2.UI.APIStore({
                        url: AIR2.Bin.URL + '/srcsub.json',
                        data: data
                    });
                    record = store.getAt(0);
                    bin_uuid = data.radix.bin_uuid;
                    selected_uuids = [];
                    params = {}
                    if(!all_selected) {
                        params.uuids = [];
                        Ext.each(selected_rows, function(row, index) {
                            row = Ext.get(row);
                            var srs_uuid = row.getAttribute("data-srs_uuid");
                            params.uuids.push(srs_uuid);

                        });
                    }
                    else {
                        params.uuids = {
                            i: 'responses',
                            q: AIR2.Reader.ARGS.q,
                            M: AIR2.Reader.ARGS.M,
                            total: count
                        };
                    }

                if (Ext.isArray(params.uuids)) {
                   params.uuids.push({reltype: "submission"});
                }

                AIR2.Drawer.API.addItems(record, params.uuids, function() {
                    AIR2.APP.el.unmask();
                    window.open(AIR2.HOMEURL + '/bin/' +bin_uuid+'.phtml');
                });

                },
                failure: function(response, opts) {
                  Logger('server-side failure with status code ' + response);
               }
            });
        }
    }
    });


    hbox = new Ext.Container({
        layout: 'hbox',
        cls: 'reader-tools',
        width: 1000,
        items: [
            filterWrap,
            filterCount,
            columnPicker,
            expand,
            collapse,
            starfilter,
            printFriendly
        ]
    });

    // different title for query-view
    title = 'Search Submissions';
    if (AIR2.Reader.INQUIRY) {
        title = AIR2.Format.inquiryTitle(AIR2.Reader.INQUIRY.radix, true, 200);
    }

    // strict search
    isStrict = window.location.href.match(/strict-(responses|query)/);
    pnlHtml = '<input type="checkbox" ';

    if (isStrict) {
        pnlHtml += 'checked';
    }

    pnlHtml += ' onclick="AIR2.Reader.toggleStrict()" ';
    pnlHtml += 'id="air2-reader-header-check" />';
    pnlHtml += '<label for="air2-reader-header-check" ';
    pnlHtml += 'onclick="AIR2.Reader.toggleStrict()"> Exact match</label>';

    pnlTools = [{
        xtype: 'box',
        cls: 'header-check',
        html: pnlHtml
    }];

    // helper to redirect between urls
    AIR2.Reader.toggleStrict = function () {
        var curr = window.location.href;
        if (curr.match(/strict-(responses|query)/)) {
            window.location = curr.replace(/strict-(responses|query)/, '$1');
        }
        else {
            window.location = curr.replace(/(responses|query)/, 'strict-$1');
        }
    };

    // must set for saved-searches to work
    AIR2.Search.IDX = isStrict ? 'strict-responses' : 'responses';

    // search tools for non-query-view
    if (!AIR2.Reader.INQUIRY) {
        pnlTools.push('|');
        pnlTools.push({
            xtype: 'box',
            cls: 'header-link',
            html: '<a onclick="AIR2.Search.Save()">Save Search</a>'
        });
    }

    // create paging panel for dataview
    pnl = new AIR2.UI.Panel({
        colspan: 3,
        title: title + ' ' + tip,
        tools: pnlTools,
        cls: 'air2-reader',
        iconCls: 'air2-icon-responses',
        items: [hbox, AIR2.Reader.DV],
        fbar: AIR2.Reader.DV.pager
    });

    pnl.setTotal(AIR2.Reader.DV.store.getTotalCount());
    AIR2.Reader.Inbox = pnl;

    return pnl;
};
