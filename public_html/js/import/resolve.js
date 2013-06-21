Ext.ns('AIR2.Import.Resolve');
/***************
 * Import conflict resolver
 *
 * Opens a modal window allowing the resolution of any conflicts on a Source
 * that is being imported.
 *
 * @function AIR2.Import.Resolve
 * @cfg {Integer} tsrc_id
 *     the ID of the tank_source to start resolving
 * @cfg {HTMLElement} originEl (optional)
 *     origin element to animate from
 */
AIR2.Import.Resolve = function (cfg) {
    var closeBtn,
        dv,
        myLoadingText,
        nextBtn,
        refreshBtn,
        resolveConflicts,
        resolveNext,
        statusFld,
        template,
        templateOptions,
        rec,
        loading,
        w;

    if (!cfg.tsrc_id) {
        alert("MUST PROVIDE A TSRC_ID!");
        return false;
    }

    // text when loading
    myLoadingText = 'loading';

    template = '<tpl for=".">' +
        // reset the tab-indexing
        '{[this.resetIdx()]}' +
        '<table class="air2-tbl source-data">' +
            '<tr class="header">' +
                '<th><span>Field</span></th>' +
                '<th><span>Current</span></th>' +
                '<th><span>Conflict</span></th>' +
                '<th class="fixw"><span>Action</span></th>' +
            '</tr>' +
            // section header
            '<tpl for=".">' +
                // regular, displayed rows
                '<tpl if="display">' +
                    '<tr class="section-header">' +
                        '<td>{section}</td>'     +
                        '<td></td>' +
                        '<td></td>' +
                        '<td></td>' +
                    '</tr>' +
                    // section rows
                    '<tpl for="items">' +
                        '<tpl if="display">' +
                            '<tr>' +
                                '<td>{label}</td>' +
                                '<td>{oldval}</td>' +
                                '<td class="{[this.conflictCls(values)]}">' +
                                    '{newval}' +
                                '</td>' +
                                '<td>' +
                                    '<tpl if="conflict">' +
                                        '{[this.showOps(values)]}' +
                                    '</tpl>' +
                                '</td>' +
                            '</tr>' +
                        '</tpl>' +
                    '</tpl>' +
                '</tpl>' +
                '<tpl if="this.fatalError(values)">' +
                    '<tr>' +
                        '<td colspan="4">' +
                            '<div class="tsrc-error-ct">' +
                                '<div class="header">' +
                                    '<b>Fatal Error - </b>' +
                                    'Try refreshing, or contact support' +
                                '</div>' +
                                '<div class="msg">{errors}</div>' +
                            '</div>' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
            '</tpl>' +
        '</table>' +
    '</tpl>';

    templateOptions = {
        compiled: true,
        disableFormats: true,
        resetIdx: function () {
            this.tabIndexing = 2;
            return '';
        },
        conflictCls: function (row) {
            var c = row.conflict() ? 'conflict' : '';
            if (row.lastcon) {
                c += ' stillconflict';
            }

            return c;
        },
        showOps: function (row) {
            var allops, ch, i, ops, s, addOp;

            ops = row.ops();
            if (!ops || ops.length < 1) {
                return '';
            }

            if (row.key === 'src_first_name' ||
                    row.key === 'src_last_name'
            ) {
                addOp = 'Alias';
            }
            else {
                addOp = 'Add';
            }

            allops = {
                I: 'Ignore',
                R: 'Replace',
                A:  addOp,
                P: 'Add as primary'
            };

            // render select statement
            s = '<select name="' + row.key + '" tabindex="' + this.tabIndexing +
                '">';
            this.tabIndexing++;
            s += '<option value=""></option>';
            for (i = 0; i < ops.length; i++) {
                ch = ops.charAt(i);

                if (allops[ch]) {
                    s += '<option value="' + ch + '"';
                    if (row.lastop === ch) {
                        s += ' selected="selected"';
                    }

                    s += '>' + allops[ch] + '</option>';
                }
            }
            s += '</select>';
            return s;
        },
        fatalError: function (row) {
            if (row.fatal) {
                return true;
            }
            else {
                return false;
            }
        }
    };

    // primary dataview display
    dv = new AIR2.UI.JsonDataView({
        cls: 'resolver-dv',
        url: AIR2.HOMEURL + '/tank/' + AIR2.Import.UUID + '/source/' +
            cfg.tsrc_id,
        itemSelector: '.source-data',
        loadingText: false,
        emptyText: false,
        prepareData: function (data) {
            return AIR2.Import.Utils.massageTsrc(data);
        },
        tpl: new Ext.XTemplate(template, templateOptions),
        refresh: function () {
            var hdr, sel, tds, ths;

            AIR2.UI.JsonDataView.superclass.refresh.call(this);

            // fixed header magic!
            hdr = this.el.child('.header');
            if (hdr) {
                // fix width on table data and add top padding
                tds = hdr.next().query('td');
                Ext.each(tds, function (item, idx) {
                    Ext.fly(item).setWidth(Ext.fly(item).getWidth());
                    Ext.fly(item).setStyle('padding-top', '38px');
                });

                // float table headers
                ths = hdr.query('th');
                Ext.each(ths, function (item, idx) {
                    Ext.fly(item).setWidth(Ext.fly(item).getWidth());
                });
                hdr.position('absolute', 100);
            }

            // focus first field
            sel = dv.el.child('select');

            if (sel) {
                sel.focus(10);
            }
        }
    });

    // status display field
    statusFld = new Ext.BoxComponent({
        cls: 'submit-status air2-icon',
        showFailure: function (msg) {
            statusFld.el.replaceClass('air2-icon-check', 'air2-icon-warning');
            statusFld.update(msg);
            statusFld.show();
        }
    });

    // AJAX-submit of resolution
    resolveConflicts = function (successFn) {
        var allselects, el, i, ops, tsrc, val;

        // collect the actions
        ops = {};
        allselects = dv.el.query('select');
        for (i = 0; i < allselects.length; i++) {
            el = allselects[i];
            val = el.options[el.selectedIndex].value;
            if (val) {
                ops[el.name] = val;
            }
            else {
                statusFld.showFailure('Please resolve ALL the conflicts!');
                return;
            }
        }

        // disable stuff
        w.body.mask('resolving');
        refreshBtn.disable();
        closeBtn.disable();
        nextBtn.disable();
        statusFld.hide();

        // submit the form
        tsrc = dv.store.getAt(0);
        tsrc.forceSet('resolve', ops);
        dv.store.save();
    };

    // action buttons
    loading = false;
    resolveNext = false;
    refreshBtn = new AIR2.UI.Button({
        tooltip: 'Refresh Conflicts',
        iconCls: 'air2-icon-refresh',
        air2type: 'UPLOAD',
        air2size: 'SMALL',
        tabIndex: 1,
        handler: function () {
            resolveNext = false;
            var rec = dv.store.getAt(0);
            rec.forceSet('redo', 1);
            dv.store.save();
            w.body.mask('refreshing');
            refreshBtn.disable();
            closeBtn.disable();
            nextBtn.disable();
            statusFld.hide();
        }
    });
    closeBtn = new AIR2.UI.Button({
        text: 'Resolve & Close',
        iconCls: 'air2-icon-check',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        tabIndex: 98,
        handler: function () {
            resolveNext = true;
            resolveConflicts();
        }
    });
    nextBtn = new AIR2.UI.Button({
        text: 'Resolve & Next',
        iconCls: 'air2-icon-check-next',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        tabIndex: 99,
        handler: function () {
            var id, rec;

            rec = dv.store.getAt(0);
            id = rec.data.next_conflict;

            if (id) {
                resolveNext = AIR2.Import.URL + '/source/' + id + '.json';
            }
            else {
                resolveNext = false;
            }

            resolveConflicts();
        }
    });
    dv.store.on('load', function () {
        var rec = dv.store.getAt(0);

        loading = true;
        w.body.mask('refreshing');
        rec.forceSet('redo', 1);
        dv.store.save();
        closeBtn.enable();
        nextBtn.setDisabled(!rec.data.next_conflict);
        refreshBtn.enable();
    });
    dv.store.on('save', function () {
        var rec = dv.store.getAt(0);

        // handle return values
        switch (rec.data.tsrc_status) {
        case 'C':
            w.body.unmask();
            refreshBtn.enable();
            closeBtn.enable();
            nextBtn.setDisabled(!rec.data.next_conflict);
            if(!loading) {
                statusFld.showFailure('Still unresolved conflicts!');
            }
            break;
        case 'E':
            w.body.unmask();
            if(!loading) {
                statusFld.showFailure('Fatal error!');
            }
            refreshBtn.enable();
            break;
        case 'D':
            w.body.mask('success - no conflicts!');
            w.close.defer(500, w);
            break;
        default:
            if (resolveNext === true) {
                w.body.mask('success!');
                w.close.defer(500, w);
            }
            else if (resolveNext) {
                myLoadingText = 'Success!  Loading next...';
                dv.store.proxy.setUrl(resolveNext);
                dv.store.reload();
            }
            else {
                w.body.mask('success - no conflicts!');
                w.close.defer(500, w);
            }
        }

        loading = false;
    });
    if (dv.store.getCount() > 0) {
        rec = dv.store.getAt(0);
        nextBtn.setDisabled(!rec.data.next_conflict);
    }

    // create the modal window
    w = new AIR2.UI.Window({
        title: 'Resolve Conflicts',
        iconCls: 'air2-icon-source',
        cls: 'air2-resolve',
        closeAction: 'close',
        width: 750,
        height: 500,
        items: dv,
        fbar: [closeBtn, nextBtn, statusFld],
        tools: [refreshBtn],
        listeners: {
            afterrender: function () {
                // mask only if the store hasn't finished loading
                if (dv.store.getCount() === 0) {
                    w.body.mask(myLoadingText);
                }

                // handle subsequent masking
                dv.store.on('beforeload', function () {
                    if (dv.store.getCount() > 0) {
                        w.body.mask(myLoadingText);
                    }
                });
            }
        }
    });

    // global function to set "total" text of the window (used by conflicts)
    AIR2.Import.Resolve.winTotal = function (text) {
        w.header.child('.header-total').update(text);
    };

    // show and return the window
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }

    return w;
};
