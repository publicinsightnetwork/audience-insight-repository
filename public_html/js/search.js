/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

/* AIR2 Search UI */
Ext.ns('AIR2.Search');
Ext.ns('AIR2.Search.State');

Ext.Ajax.timeout = 120000; // default is 30sec. we give it 2 minutes for facets.

Ext.onReady(function () {
    AIR2.Search.BIGSPINNER          = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/shared/large-loading.gif';
    AIR2.Search.LOADING_IMG         = '<img src="' +
        AIR2.Search.BIGSPINNER + '"/>';
    AIR2.Search.BALLSPINNER         = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/shared/loading-balls.gif';
    AIR2.Search.BALLSPINNER_IMG     = '<img src="' +
        AIR2.Search.BALLSPINNER + '"/>';
    AIR2.Search.SPINNER             = AIR2.HOMEURL +
        '/css/img/loading.gif';
    AIR2.Search.SPINNER_IMG         = '<img src="' +
        AIR2.Search.SPINNER + '" align="top" />';
    AIR2.Search.TOGGLEADVSRCH       = 'Hide Advanced';
    AIR2.Search.PLUS_IMG            = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/dd/drop-add.gif';
    AIR2.Search.MINUS_IMG           = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/dd/delete.gif';
    AIR2.Search.DROP_IMG            = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/tree/drop-under.gif';
    AIR2.Search.CHECKED_IMG         = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/menu/checked.gif';
    AIR2.Search.UNCHECKED_IMG       = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/menu/unchecked.gif';
    AIR2.Search.TREE_PLUS_IMG       = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/tree/elbow-plus-nl.gif';
    AIR2.Search.TREE_MINUS_IMG      = AIR2.HOMEURL +
        '/lib/extjs/resources/images/default/tree/elbow-minus-nl.gif';
    AIR2.Search.BULLET_IMG          = AIR2.HOMEURL +
        '/css/img/icons/ui-check-box-uncheck.png';
    AIR2.Search.BULLET_INCLUDE_IMG  = AIR2.HOMEURL +
        '/css/img/icons/tick.png';
    AIR2.Search.BULLET_EXCLUDE_IMG  = AIR2.HOMEURL +
        '/css/img/icons/cross.png';

    AIR2.Search.setupHistory();
});

AIR2.MS_INA_DAY = 86400000;

AIR2.Search.NDaysAgo = function (days, date) {
    var ago, now;

    now = new Date();
    days    = days.replace(/[^0-9]/g, '');
    ago = new Date(now.getTime() - days * AIR2.MS_INA_DAY);
    return ago;
};

AIR2.Search.decodeUrlHash = function (hash) {
    var hashParams, state;

    hashParams = Ext.urlDecode(hash);
    state = {};
    Ext.iterate(hashParams, function (key, val, obj) {
        try {
            state[key] = Ext.decode(val);
        }
        catch (e) {
            state[key] = val;
        }
    });
    return state;
};

AIR2.Search.setupHistory = function () {
    var locHash;

    Ext.History.init();

    AIR2.Search.Facets.CheckOnLoad = {};

    // Handle this change event in order to restore
    // the UI to the appropriate history state
    Ext.History.on('change', function (token) {
        var after, afterIds, before, beforeIds, limit, pgr, start, triggered;

        //Logger("history token: ", token);
        if (token) {
            //Logger("token true");
            if (AIR2.Search.STATE !== token) {
                before = AIR2.Search.decodeUrlHash(AIR2.Search.STATE);
                after  = AIR2.Search.decodeUrlHash(token);
                //Logger("TODO update facet checkboxes and store");
                // Logger("before:"+Ext.encode(before));
                // Logger("after :"+Ext.encode(after));
                // Logger("before", before);
                // Logger("after", after);
                if (Ext.isDefined(after.facets)) {
                    // toggle check on whatever changed
                    beforeIds = AIR2.Search.Facets.getDomIds(before.facets);
                    afterIds  = AIR2.Search.Facets.getDomIds(after.facets);
                    triggered = false;
                    Ext.iterate(beforeIds, function (item, itemBool, obj) {
                        //Logger("before:"+item);
                        if (
                            !Ext.isDefined(afterIds[item]) ||
                            beforeIds[item] !== afterIds[item]
                        ) {
                            // Logger("before "+item+" not present in after
                            // -- must have been clicked");
                            var el = Ext.get(item);
                            if (!el) {
                                //Logger("no el for before ",item);
                                AIR2.Search.Facets.CheckOnLoad[item] = itemBool;
                                return;
                            }
                            AIR2.Search.Facets.updateResults(el.dom);
                            triggered = true;
                        }
                    });
                    if (!triggered) {
                        Ext.iterate(afterIds, function (item, itemBool, array) {
                            //Logger("after:"+item);
                            if (
                                !Ext.isDefined(beforeIds[item]) ||
                                beforeIds[item] !== afterIds[item]
                            ) {
                                // Logger("after "+item+" not present in before
                                // -- must have been clicked");
                                var el = Ext.get(item);
                                if (!el) {
                                    //Logger("no el for after ",item);
                                    AIR2.Search.Facets.CheckOnLoad[item] =
                                        itemBool;
                                    return;
                                }
                                AIR2.Search.Facets.updateResults(el.dom);
                            }
                        });
                    }
                }

                // offset and paging
                if (Ext.isDefined(after.o) || Ext.isDefined(after.p)) {
                    pgr = AIR2.Search.PAGER;
                    if (pgr) {
                        if (after.o && !isNaN(parseInt(after.o, 10))) {
                            start = parseInt(after.o, 10);
                        }
                        else {
                            start = 0;
                        }

                        if (after.p && !isNaN(parseInt(after.p, 10))) {
                            limit = parseInt(after.p, 10);
                        }
                        else {
                            limit = 50;
                        }

                        // only trigger reload on change
                        if (start !== pgr.cursor || limit !== pgr.pageSize) {
                            pgr.doLoad(start, limit);
                        }
                    }
                }
            }
            AIR2.Search.STATE = token;
        }
        else {
            // This is the initial default state.  Necessary if you navigate
            // starting from the page without any existing history token params
            // and go back to the start state.
            //Logger("no history token");
            if (AIR2.Search.STATE) {
                before = AIR2.Search.decodeUrlHash(AIR2.Search.STATE);
                if (Ext.isDefined(before.facets)) {
                    beforeIds = AIR2.Search.Facets.getDomIds(before.facets);
                    Ext.iterate(beforeIds, function (item, itemBool, array) {
                        var el = Ext.get(item);
                        if (!el) {
                            //Logger("no el for "+item);
                            AIR2.Search.Facets.CheckOnLoad[item] = itemBool;
                            return;
                        }
                        //el.dom.checked = false;
                        AIR2.Search.Facets.updateResults(el.dom);
                    });
                }
                AIR2.Search.STATE = null;
            }
        }
    });

    locHash = AIR2.Search.getLocationHash();
    if (locHash && locHash.length) {
        Ext.History.fireEvent('change', locHash);
    }
};

AIR2.Search.getStart = function () {
    var o, hash = AIR2.Search.decodeUrlHash(AIR2.Search.STATE);
    if (Ext.isDefined(hash.o) && !isNaN(parseInt(hash.o, 10))) {
        o = hash.o;
    }
    else if (AIR2.Search.PARAMS.o !== null) {
        o = AIR2.Search.PARAMS.o;
    }
    else {
        o = '0';
    }
    return parseInt(o, 10);
};

AIR2.Search.getPageSize = function () {
    var p, hash = AIR2.Search.decodeUrlHash(AIR2.Search.STATE);
    if (Ext.isDefined(hash.p) && !isNaN(parseInt(hash.p, 10))) {
        p = hash.p;
    }
    else if (AIR2.Search.PARAMS.p !== null) {
        p = AIR2.Search.PARAMS.p;
    }
    else {
        p = '50';
    }

    return parseInt(p, 10);
};

AIR2.Search.getQuery = function () {
    var q, state;

    q = AIR2.Search.PARAMS.q;
    state = AIR2.Search.getState();
    if (state && state.facets && AIR2.Search.State.toQuery(state).length) {
        if (q && q.length) {
            q = '(' + q + ') AND ' + AIR2.Search.State.toQuery(state);
        }
        else {
            q = AIR2.Search.State.toQuery(state);
        }
    }
    //Logger("q=",q);
    return q;
};

AIR2.Search.State.toQuery = function (state) {
    var q, query, qstr;

    q = [];
    if (!Ext.isDefined(state.facets)) {
        return;
    }
    //Logger("facets:",state['facets']);
    Ext.iterate(state.facets, function (field, val, obj) {
        var dialect = new Search.Query.Dialect();
        Ext.iterate(val, function (value, incExl, obj2) {
            //Logger(field, incExl, value);
            var clause = new Search.Query.Clause({
                field : field,
                value : value,
                op    : ((incExl === 'e') ? '!=' : '='),
                quote : value.match(/^\(/) ? '' : '"'
            });
            if (incExl === 'e') {
                dialect.and.push(clause);
            }
            else {
                dialect.or.push(clause);
            }
        });
        q.push(new Search.Query.Clause({
            op: '()',
            field: field,
            value: dialect
        }));
    });
    query = new Search.Query.Dialect({and: q});
    qstr = query.stringify();
    //Logger(qstr);
    return qstr;
};

AIR2.Search.cancel = function () {
    var dv = AIR2.Search.DATAVIEW;
    dv.clearSelections(false, true);
    dv.getTemplateTarget().update(
        '<div class="air2-loading-wrap">' +
         '<span>Search cancelled</span>' +
        '</div>'
    );
    dv.all.clear();
    if (AIR2.Search.Facets.LOADMASK) {
        AIR2.Search.Facets.LOADMASK.hide();
    }
    AIR2.Search.CANCELLED = true;

    // cancel on the map too
    if (AIR2.Search.MAP) {
        dv.mapall.clear();
        AIR2.Search.MAP.slideMapper('removeAll');
        AIR2.Search.MAP.slideMapper('add', {
            html:
                '<div class="air2-loading-wrap">' +
                    '<span>Search cancelled</span>' +
                '</div>'
        });
    }
};

AIR2.SearchPanel = function (cfg) {
    var adv,
        advSearch,
        applyFiltersBtn,
        bodyItems,
        buttons,
        clrFiltersBtn,
        filtersPanel,
        initialParams,
        mapper,
        mayMerge,
        pageSize,
        query,
        queryTitle,
        resultsPanel,
        resultsStore,
        searchPanel,
        siloLinks,
        siloPanel,
        siloPanelOpts,
        silos,
        sortBy,
        speed,
        start,
        state,
        strict,
        tip,
        unmapper;

    if (!Ext.isDefined(cfg.searchUrl)) {
        throw new Ext.Error("searchUrl required");
    }

    if (!Ext.isDefined(cfg.title)) {
        cfg.title = 'Results';
    }

    pageSize = AIR2.Search.getPageSize();
    start = AIR2.Search.getStart();
    query = AIR2.Search.getQuery();
    state = AIR2.Search.getState();
    sortBy = AIR2.Search.getSortedBy();

    initialParams = {};
    Ext.iterate(AIR2.Search.PARAMS, function (k, v, obj) {
        if (v !== null) {
            initialParams[k] = v;
        }
    });

    Ext.apply(initialParams, {
        i: AIR2.Search.IDX,
        q: query,
        s: sortBy,
        start: start,
        limit: pageSize
    });
    resultsStore = new Ext.data.JsonStore({
        autoLoad        : {params: initialParams},
        restful         : true,
        url             : cfg.searchUrl,
        listeners : {
            beforeload : function (thisStore, opts) {
                //Logger(opts);
                if (opts.params.s === "uri") {
                    //Logger('change sort === rank');
                    opts.params.s = ""; // get default
                }
                var advSearchCounter = Ext.get('adv-search-counter');
                if (advSearchCounter) {
                    advSearchCounter.dom.innerHTML =
                        AIR2.Search.BALLSPINNER_IMG;
                }
            },
            load: function (thisStore, recs, opts) {
                AIR2.Search.setTotal(
                    thisStore.getTotalCount(),
                    thisStore.reader.jsonData.unauthz_total
                );
                var advSearchCounter = Ext.get('adv-search-counter');
                if (advSearchCounter) {
                    advSearchCounter.dom.innerHTML = thisStore.getTotalCount();
                }
                //Logger(thisStore);
                AIR2.Search.REQ_QUERY = Ext.decode(
                    thisStore.reader.jsonData.json_query
                );

                // TODO thisStore.reader.jsonData['TODO'];
                AIR2.Search.REQ_BOOL  = 'AND';
            },
            exception: function (proxy, type, action, options, response, args) {
                Logger(
                    "ResultsStore caught exception:",
                    type,
                    action,
                    response,
                    args
                );
                AIR2.Search.showError(response, options);
            }

        }

    });

    queryTitle = AIR2.Search.QUERY;
    if (!queryTitle.length) {
        queryTitle = "All " + cfg.title;
    }

    // TODO add flavor based on current query type (sources, projects, etc)
    advSearch = new AIR2.UI.Panel({
        title: 'Advanced Search',
        id: 'air2-advsearch-panel',
        colspan: 3,
        hidden: cfg.showAdvSearch ? false : true,
        style: 'margin-bottom:10px',
        magicToggle: function () {
            var el, grid;

            //Logger("magicToggle");
            el = this.el;
            grid = this;
            if (this.hidden) {
                this.show();
                el.slideIn('t', {
                    duration: 0.25,
                    callback: this.setupRules
                });
            }
            else {
                el.slideOut('t', {
                    duration: 0.25,
                    callback: function () {
                        grid.hide();
                    }
                });
            }
        },
        setupRules: function () {
            var clause, fPanel, nClauses;

            if (this.hidden) {
                return;
            }

            // if there is not yet a rule (as the first time we show)
            // then add one. the 'afterrender' listener is buggy
            // on the formpanel itself.
            fPanel = Ext.getCmp(AIR2.Search.Advanced.FORMID);
            nClauses = fPanel.getClauses().length;
            if (!nClauses) {
                // because our search is async, this might not be ready at
                // the time this panel is initialized.
                if (AIR2.Search.REQ_QUERY) {
                    // TODO dialect.walk() to add clauses
                    //var dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
                    //dialect.fromJson(AIR2.Search.REQ_QUERY);
                    //Logger(dialect.toString());
                    clause = fPanel.addClause();
                    if (cfg.showAdvSearch) {
                        clause.setValue(AIR2.Search.PARAMS.q);
                    }
                }
                else {
                    clause = fPanel.addClause();
                    if (cfg.showAdvSearch) {
                        clause.setValue(AIR2.Search.PARAMS.q);
                    }
                }
            }
        },
        listeners: {
            afterrender: function () {
                this.setupRules();
            }
        },
        items: [
            AIR2.Search.Advanced.Panel({
                current: queryTitle
            })
        ]
    });

    AIR2.Search.DATAVIEW = new AIR2.UI.DataView({
        cls             : 'air2-search-dv',
        store           : resultsStore,
        tpl             : cfg.resultTpl,
        simpleSelect    : true,
        multiSelect     : true,
        selectedClass   : 'air2-search-result-selected',
        itemSelector    : 'div.air2-search-result',
        // private override
        onBeforeLoad    : function () {
            this.clearSelections(false, true);
            this.getTemplateTarget().update(
                '<div class="air2-loading-wrap">' +
                    '<div class="air2-loading-img">' +
                        '<span>' +
                            '<a href="#" onclick="AIR2.Search.cancel()">' +
                                'Cancel Search' +
                            '</a>' +
                        '</span>' +
                    '</div>' +
                '</div>'
            );
            this.all.clear();
            // initially showing map
            if (AIR2.Search.getMapMode()) {
                AIR2.Search.MAPBOX.initMap();
                AIR2.Search.MAPBOX.el
                    .setStyle('height', 'auto')
                    .setStyle('left', '0%');
                AIR2.Search.DATAVIEW.el
                    .setStyle('height', '0px')
                    .setStyle('left', '105%');
            }
            // show the loader on the map too
            if (AIR2.Search.MAP) {
                this.mapall.clear();
                AIR2.Search.MAP.slideMapper('removeAll');
                AIR2.Search.MAP.slideMapper('add', {
                    html: '<div class="air2-loading-wrap">' +
                        '<div class="air2-loading-img">' +
                            '<span>' +
                                '<a href="#" onclick="AIR2.Search.cancel()">' +
                                    'Cancel Search' +
                                '</a>' +
                            '</span>' +
                        '</div>' +
                    '</div>'
                });
                Ext.select(
                    '.smapp-map',
                    false,
                    AIR2.Search.MAP
                ).mask(
                    'Loading...'
                );
            }
        },
        // private override to support trac #2064 "cancelling" a search
        onDataChanged: function () {
            if (!AIR2.Search.CANCELLED && this.blockRefresh !== true) {
                this.refresh.apply(this, arguments);

                // refresh map data
                if (AIR2.Search.MAP) {
                    AIR2.Search.MAP.slideMapper('removeAll');
                    Ext.each(this.getNodes(), function (node) {
                        AIR2.Search.MAPBOX.addNode(node);
                    });
                    this.mapall = AIR2.Search.MAPBOX.el.select(
                        '.air2-search-result'
                    );
                    Ext.select('.smapp-map', false, AIR2.Search.MAP).unmask();
                    AIR2.Search.MAP.slideMapper('move', 0, false);
                }
            }

            // get checkboxes for elements
            if (this.all) {
                this.checks = this.el.select('.drag-checkbox');
            }
            if (this.mapchecks) {
                this.mapchecks = AIR2.Search.MAPBOX.el.select('.drag-checkbox');
            }
        },
        prepareData     : function (data, num, rec) {
            data.rank = num + AIR2.Search.getStart() + 1;
            return data;
        },
        listeners       : {
            selectionchange : function (thisDv, selections) {
                var c, fly, i, isSelected;
                // show/hide merge button
                if (AIR2.Search.MERGEBTN) {
                    if (selections.length === 2) {
                        AIR2.Search.MERGEBTN.show();
                    }
                    else {
                        AIR2.Search.MERGEBTN.hide();
                    }
                }

                // fix checkboxes
                for (i = 0; i < this.all.elements.length; i++) {
                    isSelected = (
                        selections.indexOf(this.all.elements[i]) >= 0
                    );
                    this.checks.elements[i].checked = isSelected;

                    // optional map updates
                    if (this.mapchecks) {
                        this.mapchecks.elements[i].checked = isSelected;
                    }
                    if (this.mapall) {
                        fly = Ext.fly(this.mapall.elements[i]);
                        c = this.selectedClass;
                        if (isSelected) {
                            fly.addClass(c);
                        }
                        else {
                            fly.removeClass(c);
                        }
                    }
                }
            },
            afterrender: function (dv) {
                // stop default checkbox action (toggle) - list mode ONLY
                dv.ownerCt.el.on('click', function (ev) {
                    var inMapMode = mapper.el.hasClass('air2-btn-blue');
                    if (ev.getTarget('.drag-checkbox') && !inMapMode) {
                        ev.preventDefault();
                    }
                });
            }
        },
        // override for custom checkbox-selecting capability
        doMultiSelection: function (item, index, e) {
            // clicking only "does stuff" within the handle
            if (e.getTarget('.checkbox-handle')) {
                if (e.shiftKey && this.last !== false) {
                    this.selectRange(this.last, index, true); //keep existing
                } else {
                    if (this.isSelected(index)) {
                        this.deselect(index);
                    }
                    else {
                        this.select(index, true); //keep existing
                    }
                }
                e.preventDefault();
            }
        }
    });

    AIR2.Search.CONTROLS = new Ext.Container({
        storeload: function (s, rs) {
            var pg = s.getCount(), all = s.getTotalCount();
            AIR2.Search.CONTROLS.items.each(function (item) {
                if (item.storetotal) {
                    item.storetotal(pg, all);
                }
            });
            AIR2.Search.CONTROLS.doLayout();
        },
        selchange: function (dv, sels) {
            AIR2.Search.CONTROLS.items.each(function (item) {
                if (item.dvnumsel) {
                    item.dvnumsel(sels.length);
                }
            });
            AIR2.Search.CONTROLS.doLayout();
        },
        layout: 'hbox',
        cls: 'tools-ct',
        defaults: {
            margins: '2 10 6 0',
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            disabled: true
        },
        items: [{
            text: 'Drag selected (0)',
            cls: 'drag-sel',
            iconCls: 'air2-icon-drag',
            dvnumsel: function (num) {
                this.setText('Drag selected (' + num + ')');
                this.setDisabled(num < 1);
            }
        }, {
            text: 'Drag all (0)',
            cls: 'drag-all',
            iconCls: 'air2-icon-drag',
            storetotal: function (pg, all) {
                all = Ext.util.Format.number(all, '0,000');
                this.setText('Drag all (' + all + ')');
                this.setDisabled(all < 1);
            }
        }, {
            text: 'Select page (0)',
            storetotal: function (pg, all) {
                this.setText('Select page (' + pg + ')');
                this.setDisabled(pg < 1);
            },
            handler: function () {
                AIR2.Search.DATAVIEW.select(AIR2.Search.DATAVIEW.getNodes());
            }
        }, {
            text: 'Unselect All',
            dvnumsel: function (num) {
                this.setDisabled(num < 1);
            },
            handler: function () {
                AIR2.Search.DATAVIEW.clearSelections();
            }
        }]
    });
    AIR2.Search.DATAVIEW.store.on('load', AIR2.Search.CONTROLS.storeload);
    AIR2.Search.DATAVIEW.on('selectionchange', AIR2.Search.CONTROLS.selchange);

    buttons = ['Sort by:', {
        id: 'air2-search-sort-by',
        xtype: 'air2combo',
        choices: AIR2.Search.SORT_BY_OPTIONS,
        value: AIR2.Search.getSortedBy(),
        width: 200,
        listeners: {
            select: function (cb, rec, idx) {
                this.doLoad(rec.data.value);
            }
        },
        // custom load handler
        doLoad: function (sortBy) {
            // update location hash (careful not to trigger a recursive load)
            var state       = AIR2.Search.getState() || {};
            state.s      = sortBy;
            if (state.facets) {
                state.facets = Ext.encode(state.facets);
            }
            AIR2.Search.setState(state);

            // update the page-size combobox
            Ext.getCmp('air2-search-sort-by').setValue(sortBy);

            // reload the store
            resultsStore.load({
                params: {
                    i:      AIR2.Search.IDX,
                    q:      AIR2.Search.getQuery(),
                    s:      sortBy,
                    start:  AIR2.Search.getStart(),
                    limit:  AIR2.Search.getPageSize()
                }
            });
            Ext.getBody().scrollTo('top', 0);
        }
    }, {
        xtype: 'box',
        cls: 'header-link',
        html: '<a onclick="AIR2.Search.Save()">Save Search</a>'
    }, {
        id: 'air2-search-header-hidden',
        xtype: 'box',
        cls: 'header-hidden',
        hidden: true
    }];

    // helper to set total
    AIR2.Search.setTotal = function (total, unauthzTotal) {
        var box, hid;

        box = Ext.getCmp('air2-search-header-hidden');
        if (unauthzTotal > total) {
            hid = Ext.util.Format.number(unauthzTotal - total, '0,000');
            box.show().update('| ' + hid + ' hidden');
        }
        else {
            box.hide();
        }
    };

    // strict mode checkbox
    if (AIR2.Search.IDX.match(/(sources|responses)/)) {
        strict = {
            xtype: 'checkbox',
            boxLabel: 'Exact match',
            checked: Ext.isDefined(AIR2.Search.STRICT_MODE),
            handler: function (cb, checked) {
                var existingIdx, newIdx, newLocation, newUrl;

                newIdx = AIR2.Search.IDX;
                if (checked) {
                    newIdx = 'strict-' + AIR2.Search.IDX;
                }
                else {
                    newIdx = newIdx.replace(/strict-/, "");
                }

                newLocation = window.location.href;
                existingIdx = new RegExp(AIR2.Search.IDX);
                newUrl = newLocation.replace(existingIdx, newIdx);
                window.location = newUrl;
            }
        };
        buttons.splice(2, 0, strict, '|');
    }

    // TODO for now only sources has advanced search
    if (AIR2.Search.IDX.match(/sources/)) {
        AIR2.Search.AdvancedToggle = function (el) {
            if (advSearch.hidden) {
                Ext.fly(el).update('Basic');
            }
            else {
                Ext.fly(el).update('Advanced');
            }
            advSearch.magicToggle();
        };
        adv = {
            xtype: 'box',
            cls: 'header-link',
            html: '<a onclick="AIR2.Search.AdvancedToggle(this)">Advanced</a>'
        };
        buttons.splice(4, 0, adv, '|');
    }

    // only source categories support mapping
    if (AIR2.Search.IDX.match(/sources/)) {
        speed = 0.4;
        AIR2.Search.showMap = function () {
            AIR2.Search.MAPBOX.initMap();
            if (AIR2.Search.DATAVIEW.last !== false) {
                AIR2.Search.MAP.slideMapper(
                    'move',
                    AIR2.Search.DATAVIEW.last,
                    false
                );
            }
            AIR2.Search.MAPBOX.el
                .setStyle('height', 'auto')
                .animate({ left: {from: -105, to: 0, unit: '%'} }, speed);
            AIR2.Search.DATAVIEW.el
                .setStyle('height', '0px')
                .animate({left: {from: 0, to: 105, unit: '%'} }, speed);
        };
        AIR2.Search.showList = function () {
            AIR2.Search.MAPBOX.el.animate(
                {
                    left: {
                        from: 0,
                        to: -105,
                        unit: '%'
                    }
                },
                speed,
                function (el) {
                    el.setStyle('left', '-4000px');
                }
            );
            AIR2.Search.DATAVIEW.el.animate(
                {
                    left: {
                        from:
                        105,
                        to: 0,
                        unit: '%'
                    }
                },
                speed,
                function (el) {
                    el.setStyle('height', 'auto');
                    AIR2.Search.MAPBOX.el.setStyle('height', '0px');
                });
        };

        // control buttons
        mapper = new AIR2.UI.Button({
            air2type: AIR2.Search.getMapMode() ? 'BLUE' : 'UPLOAD',
            air2size: 'SMALL',
            text: 'Map',
            cls: 'show-map',
            handler: function () {
                if (mapper.el.hasClass('air2-btn-blue')) {
                    return;
                }
                mapper.el.replaceClass('air2-btn-upload', 'air2-btn-blue');
                unmapper.el.replaceClass('air2-btn-blue', 'air2-btn-upload');
                AIR2.Search.showMap();
            }
        });
        unmapper = new AIR2.UI.Button({
            air2type: AIR2.Search.getMapMode() ? 'UPLOAD' : 'BLUE',
            air2size: 'SMALL',
            text: 'List',
            cls: 'hide-map',
            handler: function () {
                if (unmapper.el.hasClass('air2-btn-blue')) {
                    return;
                }
                unmapper.el.replaceClass('air2-btn-upload', 'air2-btn-blue');
                mapper.el.replaceClass('air2-btn-blue', 'air2-btn-upload');
                AIR2.Search.showList();
            }
        });
        buttons.push('->', mapper, unmapper);
    }

    applyFiltersBtn = new AIR2.UI.Button({
        air2size: 'SMALL',
        text: 'Apply Filters',
        air2type: 'BLUE',
        cls: 'apply-filters',
        handler: function () {
            AIR2.Search.Facets.updateLocation();
        }
    });

    // merge sources button
    if (AIR2.Search.IDX.match(/sources/)) {
        // determine if "merge" button should even be visible
        mayMerge = AIR2.Util.Authz.has('ACTION_ORG_SRC_UPDATE');
        if (mayMerge) {
            AIR2.Search.MERGEBTN = new AIR2.UI.Button({
                air2type: 'UPLOAD',
                air2size: 'MEDIUM',
                text: 'Merge Sources',
                cls: 'merge-sources',
                hidden: true,
                handler: function (btn) {
                    var sel = AIR2.Search.DATAVIEW.getSelectedRecords();
                    if (sel.length === 2) {
                        AIR2.Merge.Sources({
                            originEl: btn.el,
                            prime_uuid: sel[0].data.src_uuid,
                            merge_uuid: sel[1].data.src_uuid
                        });
                    }
                }
            });
            AIR2.Search.CONTROLS.add(AIR2.Search.MERGEBTN);
            AIR2.Search.MERGEBTN.enable();
        }
    }

    // setup body items
    bodyItems = [AIR2.Search.DATAVIEW];
    if (
        AIR2.Search.IDX.match(/sources/) ||
        AIR2.Search.IDX.match(/responses/)
    ) {
        bodyItems = [AIR2.Search.CONTROLS, AIR2.Search.DATAVIEW];
    }

    // mapping support
    if (AIR2.Search.IDX.match(/sources/)) {
        AIR2.Search.MAPBOX = new Ext.BoxComponent({
            cls: 'air2-search-map',
            // 1-time init of mapper plugin
            initMap: function () {
                if (AIR2.Search.MAP) {
                    return;
                }
                var box = AIR2.Search.MAPBOX;

                AIR2.Search.MAP = $(box.el.dom).slideMapper({
                    controlType: 'top',
                    height: 260,
                    autoHeight: true,
                    mapPosition: 'top',
                    leafPile: {}
                });
                AIR2.Search.MAP.on('move', function (e, data, idx) {
                    if (!data.marker) {
                        Ext.select(
                            '.smapp-map',
                            false,
                            AIR2.Search.MAP
                        ).mask(
                            'No location'
                        );
                    }
                    else {
                        Ext.select(
                            '.smapp-map',
                            false,
                            AIR2.Search.MAP
                        ).unmask();
                    }
                });
                Ext.each(
                    AIR2.Search.DATAVIEW.getNodes(),
                    function (node) {
                        AIR2.Search.MAPBOX.addNode(node);
                    }
                );
                AIR2.Search.MAP.slideMapper('move', 0);
                AIR2.Search.DATAVIEW.mapall = box.el.select(
                    '.air2-search-result'
                );
                AIR2.Search.DATAVIEW.mapchecks = box.el.select(
                    '.drag-checkbox'
                );

                // set initial selections
                Ext.each(
                    AIR2.Search.DATAVIEW.getSelectedIndexes(),
                    function (selIdx) {
                        var fly = Ext.fly(
                            AIR2.Search.DATAVIEW.mapall.elements[selIdx]
                        );

                        fly.addClass(AIR2.Search.DATAVIEW.selectedClass);
                        AIR2.Search.DATAVIEW.mapchecks.elements[
                            selIdx
                        ].checked = true;
                    }
                );
            },
            // add a dataview node to the map
            addNode: function (node) {
                var cfg, rec;

                rec = AIR2.Search.DATAVIEW.getRecord(node);
                cfg = {
                    html:
                        '<div class="air2-search-result">' +
                            node.innerHTML +
                        '</div>'
                };

                // optional location
                if (rec.data.primary_lat && rec.data.primary_long) {
                    cfg.marker = [rec.data.primary_lat, rec.data.primary_long];
                    cfg.popup = '<b>' + rec.data.title + '</b>';

                    if (rec.data.summary) {
                        cfg.popup += '<br/>';
                        cfg.popup += '<span>' + rec.data.summary + '</span>';
                    }
                    else {
                        cfg.popup += '<br/>';
                        cfg.popup += '<span>' + rec.data.primary_location;
                        cfg.popup += '</span>';
                    }
                }
                AIR2.Search.MAP.slideMapper('add', cfg);
            },
            // setup click listeners
            listeners: {
                afterrender: function (box) {
                    var dv, i;

                    box.el.on('click', function (e) {
                        if (e.getTarget('.checkbox-handle')) {
                            dv = AIR2.Search.DATAVIEW;
                            i = dv.mapall.indexOf(
                                e.getTarget('.air2-search-result')
                            );
                            if (dv.isSelected(i)) {
                                dv.deselect(i);
                            }
                            else {
                                dv.select(i, true);
                            }
                        }
                    });
                }
            }
        });
        bodyItems.push(AIR2.Search.MAPBOX);
    }

    // pager
    AIR2.Search.PAGER = new Ext.PagingToolbar({
        cls: 'air2-search-pager',
        store           : resultsStore,
        displayInfo     : true,
        pageSize        : pageSize,
        prependButtons  : false,
        items: [
            {
                id: 'air2-search-page-size',
                xtype: 'air2combo',
                choices: [[50, 50], [100, 100], [200, 200], [500, 500]],
                value: AIR2.Search.getPageSize(),
                width: 50,
                listeners: {
                    select: function (cb, rec, idx) {
                        AIR2.Search.PAGER.doLoad(0, rec.data.value);
                    }
                }
            }, 'per page'
        ],
        // custom load handler
        doLoad: function (start, limit) {
            var sate;

            if (limit) {
                this.pageSize = limit; // optionally updates limit
            }

            // update location hash (careful not to trigger a recursive load)
            state = AIR2.Search.getState() || {};
            state.o = start;
            state.p = this.pageSize;

            if (state.facets) {
                state.facets = Ext.encode(state.facets);
            }

            AIR2.Search.setState(state);

            // update the page-size combobox
            Ext.getCmp('air2-search-page-size').setValue(this.pageSize);

            // reload the store
            this.store.load({
                params: {
                    i:     AIR2.Search.IDX,
                    q:     AIR2.Search.getQuery(),
                    s:     AIR2.Search.getSortedBy(),
                    start: start,
                    limit: this.pageSize
                }
            });
            Ext.getBody().scrollTo('top', 0);
        }
    });

    resultsPanel = new AIR2.UI.Panel({
        colspan : 2,
        id      : 'air2-search-results',
        items   : bodyItems,
        tools   : buttons,
        fbar    : AIR2.Search.PAGER,
        // drag-and-drop listener
        listeners: {
            render: function (cmp) {
                AIR2.Search.DRAGZONE = new AIR2.Drawer.DragZone(cmp.el, {
                    getDragData: function (e) {
                        var btnEl, c, dataField, ddObj, hdlEl, isAll;

                        hdlEl = e.getTarget('.checkbox-handle');
                        btnEl = e.getTarget('.air2-icon-drag');

                        // return false to disable D&D
                        if (
                            !(
                                hdlEl ||
                                (btnEl && !e.getTarget('.x-item-disabled'))
                            )
                        ) {
                            return false;
                        }

                        // get more specific on the buttons

                        if (btnEl) {
                            btnEl = e.getTarget('.air2-btn');
                            isAll = Ext.fly(btnEl).hasClass('drag-all');
                        }

                        // build D&D object
                        ddObj = {
                            repairXY: Ext.fly(hdlEl ? hdlEl : btnEl).getXY()
                        };
                        dataField = 'uri';
                        switch (AIR2.Search.IDX) {
                        case 'sources':
                        case 'strict-sources':
                        case 'active-sources':
                        case 'strict-active-sources':
                        case 'primary-sources':
                            ddObj.ddBinType = 'S';
                            break;
                        case 'strict-primary-sources':
                            ddObj.ddBinType = 'S';
                            break;
                        case 'responses':
                        case 'fuzzy-responses':
                        case 'strict-responses':
                        case 'active-responses':
                        case 'fuzzy-active-responses':
                        case 'strict-active-responses':
                            ddObj.ddBinType = 'S';
                            ddObj.ddRelType = 'S';
                            dataField = 'srs_uuid';
                            break;
                        default:
                            return false; //disable D&D
                        }

                        // proxy element
                        if (hdlEl) {
                            ddObj.ddel =
                                AIR2.Search.DATAVIEW.getSelectionCount() +
                                ' ' + AIR2.Search.IDX;
                        }
                        else {
                            c = 'air2-btn air2-btn-upload air2-btn-medium ';
                            c += 'x-btn-text-icon';
                            ddObj.ddel = '<div class="' + c + '">';
                            ddObj.ddel += btnEl.innerHTML + '</div>';
                        }

                        // selections
                        if (hdlEl || !isAll) {
                            ddObj.selections = function () {
                                var recs, selections;

                                selections = [];
                                recs =
                                    AIR2.Search.DATAVIEW.getSelectedRecords();
                                Ext.each(recs, function (item, idx, array) {
                                    if (!Ext.isDefined(item.data[dataField])) {
                                        return;
                                    }

                                    // optionally setup related
                                    if (ddObj.ddRelType) {
                                        selections.push({
                                            uuid: item.data[dataField],
                                            type: ddObj.ddBinType,
                                            reltype: ddObj.ddRelType
                                        });
                                    }
                                    else {
                                        selections.push(item.data[dataField]);
                                    }
                                });
                                return selections;
                            };
                        }
                        else {
                            ddObj.selections = {
                                i: AIR2.Search.IDX,
                                q: AIR2.Search.getQuery(),
                                total:
                                    AIR2.Search.DATAVIEW.store.getTotalCount()
                            };
                        }
                        return ddObj;
                    }
                });
            }
        }
    });

    AIR2.Search.FACETS_PANEL = new AIR2.Search.Facets.WrapperPanel({
        facetsUrl: cfg.searchUrl + '&' + Ext.urlEncode({
            f: 1,
            r: 0,
            //i:AIR2.Search.IDX,
            q: AIR2.Search.PARAMS.q
        }),
        facetDefs: cfg.facetDefs,
        idx      : AIR2.Search.IDX
    });

    // the footer monkeybusiness is to preserve the rounded
    // corners on the panel bottom, which seem to disappear
    // in some browsers because the body is modified with
    // the actual facets, after the panel has been rendered.
    clrFiltersBtn = {
        xtype: 'box',
        cls: 'header-link',
        html: '<a onclick="AIR2.Search.Facets.ClearSelections(this)">Clear</a>'
    };
    filtersPanel = new AIR2.UI.Panel({
        colspan : 1,
        title   : 'Filter by',
        tools   : ['->', applyFiltersBtn, '-', clrFiltersBtn],
        id      : 'air2-search-filters',
        iconCls : 'air2-icon-filter',
        style: 'padding-bottom: 10px',
        items   : [
            AIR2.Search.FACETS_PANEL
        ]
    });

    silos = AIR2.Search.siloLinks(cfg);

    siloLinks = new AIR2.UI.Panel({
        colspan : 1,
        //title   : 'Silos',
        cls     : 'air2-search-silos',
        noHeader: true,
        items   : silos
    });

    // support article
    tip = AIR2.Util.Tipper.create(20978291);

    siloPanelOpts = {
        title : 'Category ' + tip,
        colspan: 1,
        id     : 'air2-search-category',
        //cls    : 'air2-search-category',
        items  : [
            siloLinks
        ]
    };
    siloPanel = new AIR2.UI.Panel(siloPanelOpts);

    searchPanel = new AIR2.UI.PanelGrid({
        columnLayout: '12',
        columnWidths: [0.25, 0.75],
        items: [
            siloPanel,
            resultsPanel,
            filtersPanel
        ]
    });

    return [advSearch, searchPanel];
};

AIR2.Search.getSortedBy = function () {
    var s, hash = AIR2.Search.decodeUrlHash(AIR2.Search.STATE);
    if (Ext.isDefined(hash.s)) {
        s = hash.s;
    }
    else if (AIR2.Search.PARAMS.s !== null) {
        s = AIR2.Search.PARAMS.s;
    }
    else {
        s = 'score DESC';
    }
    return s;
};

// for now, assume map mode if query string contains lat/lng
// TODO: better things
AIR2.Search.getMapMode = function () {
    var q = AIR2.Search.getQuery();
    return q && q.match(/latitude[!=]+|longitude[!=]+/);
};

AIR2.Search.Save = function () {
    var name, parts, savedsearch, share, w;

    // get everything following the URL '?', and unescape it
    parts = top.location.href.split('?');
    if (parts.length > 1) {
        savedsearch = unescape(parts[1]);
    }
    else {
        savedsearch = '';
    }

    // form fields
    name = {
        xtype: 'air2remotetext',
        fieldLabel: 'Name',
        name: 'ssearch_name',
        remoteTable: 'savedsearch',
        uniqueErrorText: 'Name already in use',
        autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
        maxLength: 255
    };
    share = {
        xtype: 'air2combo',
        fieldLabel: 'Shared',
        name: 'ssearch_shared_flag',
        choices: [[false, 'No'], [true, 'Yes']],
        value: false
    };

    // create form window
    w = new AIR2.UI.CreateWin({
        title: 'Save Search',
        iconCls: 'air2-icon-savedsearch',
        formItems: [name, share],
        postUrl: AIR2.HOMEURL + '/savedsearch.json',
        postParams: function (f) {
            var p = f.getFieldValues();
            p.ssearch_params = AIR2.Search.IDX + '?' + savedsearch;
            return p;
        },
        postCallback: function (success, data, raw) {
            if (success) {
                w.close();
            }
            else {
                w.close(false);
                var msg = data.message ? data.message : 'Unknown server error';
                AIR2.UI.ErrorMsg(null, 'Server error', msg);
            }
        }
    });
    w.show();
};

AIR2.Search.CATEGORIES = {
    'inquiries'         : 'Queries',
    'sources'           : 'All Sources',
    'active-sources'    : 'Available Sources',
    'primary-sources'   : 'Primary Sources',
    'responses'         : 'Submissions',
    'projects'          : 'Projects',
    'outcomes'          : 'PINfluence'
};
AIR2.Search.STRICTABLE = {
    'responses'         : 'strict-responses',
    'sources'           : 'strict-sources',
    'active-sources'    : 'strict-active-sources',
    'primary-sources'   : 'strict-primary-sources'
};

AIR2.Search.siloLinks = function (cfg) {
    var altCats, altHrefs, altNames, currentTpl, filterTpl, silos, sorter;

    altCats  = AIR2.Search.CATEGORIES;
    altHrefs = {
        'outcomes'          : 'pinfluence',
        'inquiries'         : 'queries' // per #1944
    };

    filterTpl = new Ext.XTemplate(
        '<div class="air2-silolink air2-corners">',
        '<a class="air2-icon {iconCls}" href="{href}">{label}</a>&nbsp;',
        '(<span id="{elId}">', AIR2.Search.BALLSPINNER_IMG, '</span>)',
        '</div>'
    );
    currentTpl = new Ext.XTemplate(
        '<div class="air2-silolink air2-corners-left air2-silolink-current" ' +
            'style="width:500px">' +
            '<a class="air2-icon {iconCls}" href="{href}">' +
                '{label}' +
            '</a>&nbsp;' +
            '(<span id="{elId}">', AIR2.Search.BALLSPINNER_IMG, '</span>)' +
        '</div>'
    );
    filterTpl.compile();
    currentTpl.compile();

    silos = [
        new Ext.Component({
            html: '<div class="air2-silolink-top"></div>'
        })
    ];
    sorter = function (a, b) {
        var aLabel, bLabel;

        aLabel = altCats[a].toLowerCase();
        bLabel = altCats[b].toLowerCase();
        if (aLabel < bLabel) {
            return -1;
        }
        if (aLabel > bLabel) {
            return 1;
        }
        return 0;
    };

    altNames = [];
    Ext.iterate(altCats, function (key, label, obj) {
        altNames.push(key);
    });

    Ext.each(altNames.sort(sorter), function (item, idx, array) {
        var elId,
            href,
            hrkey,
            key,
            label,
            listeners,
            obj,
            remote_idx,
            silo,
            tpl,
            url;

        key = item;
        label = altCats[key];
        tpl = filterTpl;

        if (
            Ext.isDefined(AIR2.Search.STRICT_MODE) &&
            Ext.isDefined(AIR2.Search.STRICTABLE[key])
        ) {
            remote_idx = AIR2.Search.STRICTABLE[key];
        }
        else {
            remote_idx = key;
        }

        url = AIR2.Search.URL + '.json?' +
            Ext.urlEncode({q: AIR2.Search.PARAMS.q, i: remote_idx});
        hrkey = altHrefs[key] ? altHrefs[key] : remote_idx;
        href = AIR2.Search.URL + '/' + hrkey + '?' +
            Ext.urlEncode({q: AIR2.Search.PARAMS.q});
        elId = 'air2-' + remote_idx + '-count';
        listeners = {
            render : function (p) {
                var el = p.getEl();
                el.on('mouseenter', function () {
                    el.toggleClass('air2-silo-over');
                });
                el.on('mouseleave', function () {
                    el.toggleClass('air2-silo-over');
                });
                el.on('click', function () {
                    window.location = el.child('a').dom.href;
                });
                AIR2.Search.getCount({
                    url : url,
                    elId: elId
                });
            }
        };
        if (remote_idx === AIR2.Search.IDX) {
            tpl = currentTpl;

            // setWidth something bigger than parent
            listeners.afterrender = function (p) {
                p.getEl().setWidth(400);
            };

            // TODO include whatever facets were applied to actual search
            //url = cfg.searchUrl+'&c=1';
        }

        silo = new Ext.Component({
            tpl   : tpl,
            data  : {
                href: href,
                elId: elId,
                label: label,
                iconCls: 'air2-icon-' + key
            },
            border: false,
            listeners: listeners
        });

        silos.push(silo);
    });

    return silos;
};

/**********************************************************************
 * @class AIR2.Search.getCount
 *
 * Expects a single "cfg" object as argument, with two values:
 * "url" and "elId". Will fire off a Ajax.request to the "url"
 * and update the element with "elId" with the total count
 * in the response.
 */

AIR2.Search.getCount = function (cfg) {

    var setter = function (json) {
        var el, t;

        if (json && Ext.isDefined(json.total) && cfg.elId) {
            el = Ext.get(cfg.elId);
            if (el) {
                t = Ext.util.Format.number(json.total, '0,000');
                el.dom.innerHTML = t;
            }
        }

    };

    // fetch the query count, optionally updating the DOM
    Ext.Ajax.request({
        url: cfg.url + '&c=1',
        success: function (resp, opts) {
            //Logger(resp);
            var json = Ext.decode(resp.responseText);
            //Logger(cfg, json.total);
            setter(json);
            if (cfg.callback) {
                cfg.callback(json);
            }
        },
        failure: function (resp, opts) {
            //Logger("Count failure: ", resp);
            setter({total: 0});
            if (!AIR2.Search.ErrorInCount) {

                // very common for "no such field" errors
                // to happen because tag defs are not the same across
                // all idx silos.
                if (resp.responseText.match(/no such field/i)) {
                    //Logger(resp.responseText);
                    return;
                }

                if (!cfg.hideErrors) {
                    AIR2.Search.showError(resp, opts);
                }
            }
            AIR2.Search.ErrorInCount = true;
            Ext.get(cfg.elId).dom.innerHTML = '0';
            AIR2.Search.Advanced.COUNT_IN_PROGRESS = false;
            // optionally redirect to help page
            if (cfg.redirectOnError) {
                window.location = cfg.redirectOnError;
            }
        }
    });

};

AIR2.Search.showError = function (response, opts) {
    // because we may have fired several requests for count
    // we only want to show the first error.
    // TODO how to unset this?
    if (AIR2.Search.ErrorInProgress) {
        return;
    }
    AIR2.Search.ErrorInProgress = true;
    if (!response) {
        //Logger("no response object");
        return;
    }
    var resp;
    if (response.status !== '404' && response && response.responseText) {
        try {
            resp = Ext.decode(response.responseText);
        }
        catch (err) {
            resp = { error: "Ext.decode failed: " + err.message };
        }
    }
    else {
        //Logger("XHR error: ", response);
        return; // often from clicking away from a page while XHR in progress.
    }
    //Logger("Error:", resp);
    if (resp.error) {
        AIR2.UI.ErrorMsg(Ext.getBody(), "Search Error", resp.error);
        AIR2.Search.cancel();
    }
    else {
        alert("Unknown server error");
    }
};

AIR2.Search.getLocationHash = function () {
    var hashIdx, urlHash;

    hashIdx = top.location.href.indexOf("#");
    urlHash = hashIdx >= 0 ? top.location.href.substr(hashIdx + 1) : '';
    return urlHash;
};

AIR2.Search.setState = function (state) {
    top.location.hash = Ext.urlEncode(state);
};

AIR2.Search.getState = function () {
    var urlHash = AIR2.Search.getLocationHash();
    if (!urlHash.length) {
        return;
    }
    return AIR2.Search.decodeUrlHash(urlHash);
};

AIR2.Search.cleanQueryForTag = function (str) {
    var clean = str.replace(/[^a-zA-Z0-9\.\ \-\_]\ ?/g, "");
    return clean;
};
