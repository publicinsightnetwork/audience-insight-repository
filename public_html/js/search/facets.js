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

/* AIR2 Search Facet management */
Ext.ns('AIR2.Search');
Ext.ns('AIR2.Search.Facets');

AIR2.Search.Facets.getDomIds = function (facets) {
    var ids = {};
    Ext.iterate(facets, function (field, val, obj) {
        Ext.iterate(val, function (value, one, obj2) {
            value = AIR2.Search.cleanQueryForTag(value);
            var id = field + '-' + value;
            ids[id] = one;
        });
    });
    return ids;
};

AIR2.Search.Facets.ClearSelections = function (btn) {
    var selections = AIR2.Search.Facets.getCheckedImgs();
    //Logger("selections:", selections);
    Ext.each(selections, function (img, idx, arr) {
        AIR2.Search.Facets.deselectFacet(img);
    });

    AIR2.Search.Facets.updateLocation();
};

AIR2.Search.Facets.WrapperPanel = Ext.extend(Ext.Panel, {
    autoHeight: true,
    border: false,
    id: 'air2-search-facets',
    cls: 'air2-corners',
    populate: function (idxName) {
        var el, myMask, panel;

        if (!idxName) {
            idxName = this.idx;
        }
        panel = this;
        el = panel.getResizeEl();
        //Logger('render Facets panel:', el);
        myMask = new Ext.LoadMask(el, {
            msg: 'Fetching facets...'
        });
        AIR2.Search.Facets.LOADMASK = myMask;
        myMask.show();
        //Logger("myMask: ", myMask);
        Ext.Ajax.request({
            url: panel.facetsUrl + '&i=' + idxName,
            success: function (resp, opts) {
                myMask.hide();
                if (AIR2.Search.CANCELLED) {
                    return;
                }
                panel.addFacets(resp, opts);
            },
            failure: function (resp, opts) {
                myMask.hide();
                //Logger("facets failure: ", resp);
                AIR2.Search.showError(resp, opts);
            }
        });
    },
    initComponent : function (cfg) {
        if (!Ext.isDefined(this.facetsUrl)) {
            throw new Ext.Error("facetsUrl not defined");
        }
        if (!Ext.isDefined(this.facetDefs)) {
            throw new Ext.Error("facetDefs not defined");
        }

        this.baseUrl = AIR2.Search.URL + '/' + this.idx + '?';

        // fetch the facets and add them as items.
        this.on('afterrender', function () {
            this.populate();
        });

        this.defaults = { style: 'padding: 2px', border: false };

        AIR2.Search.Facets.WrapperPanel.superclass.initComponent.call(
            this,
            cfg
        );
    },
    addFacets : function (resp, opts) {
        var genericTpl, facetNames, facetOrder, facetPanels, fp, json, sorter;

        fp = this;
        json = Ext.decode(resp.responseText);
        //Logger("addFacets");
        //Logger("facets:", json.facets);
        facetPanels = [];
        genericTpl = new Ext.XTemplate(
            '<div class="air2-facet-pair">' +
                '<input type="hidden" id="{facetId}" name="{facetName}" ' +
                    'value="{facetValue}" class="{checked}" />' +
                '<tpl if="checked==\'i\'">' +
                    '<img class="bullet {checked}" src="' +
                        AIR2.Search.BULLET_INCLUDE_IMG +
                        '" onclick="{onclick}" id="{facetId}-img" />' +
                '</tpl>' +
                '<tpl if="checked==\'e\'">' +
                    '<img class="bullet {checked}" src="' +
                     AIR2.Search.BULLET_EXCLUDE_IMG +
                      '" onclick="{onclick}" id="{facetId}-img" />' +
                '</tpl>' +
                '<tpl if="checked==false">' +
                    '<img class="bullet " src="' +
                        AIR2.Search.BULLET_IMG +
                        '" onclick="{onclick}" id="{facetId}-img" />' +
                '</tpl>' +
                '<label for="{facetId}" class="{facetValue}">' +
                    '<span class="air2-facet-value">{label}</span>' +
                    '<span id="{facetId}-count" class="count">' +
                        '({count})' +
                    '</span>' +
                '</label>' +
            '</div>'
        );

        genericTpl.compile();

        // sort them by facetDefs.label
        facetOrder = [];
        if (Ext.isDefined(fp.facetDefs.sortOrder)) {
            facetOrder = fp.facetDefs.sortOrder;
        }
        else {
            facetNames = [];
            Ext.iterate(fp.facetDefs, function (name, def, obj) {
                facetNames.push(name);
            });
            sorter = function (a, b) {
                var aLabel, bLabel;

                aLabel = fp.getFacetLabel(a).toLowerCase();
                bLabel = fp.getFacetLabel(b).toLowerCase();
                if (aLabel < bLabel) {
                    return -1;
                }
                if (aLabel > bLabel) {
                    return 1;
                }
                return 0;
            };
            facetOrder = facetNames.sort(sorter);
        }

        Ext.each(facetOrder, function (name, idx, array) {
            var facets,
                fid,
                isActive,
                listOfFacets,
                listPanel,
                r,
                sorter,
                tpl;

            if (!Ext.isDefined(json.facets[name])) {
                //Logger("not returned from server, skipping facet", name);
                return true;    // Response does not define this facet
            }
            facets = json.facets[name];
            listOfFacets = [];
            if (facets.length > 1000) { // TODO arbitrary limit
                //Logger("too long ("+facets.length+"), skipping facet", name);
                return true;
            }

            isActive = false;
            if (fp.getFacetRenderer(name)) {
                r = fp.getFacetRenderer(name);
                listOfFacets = r(name, facets, fp, genericTpl);
                isActive = listOfFacets.isActive;
            }
            else {

                // default is sorted by facet label
                sorter = function (a, b) {
                    var aLabel, bLabel;

                    aLabel = fp.getItemLabel(name, a).toLowerCase();
                    bLabel = fp.getItemLabel(name, b).toLowerCase();
                    if (aLabel < bLabel) {
                        return -1;
                    }
                    if (aLabel > bLabel) {
                        return 1;
                    }
                    return 0;
                };

                // sort facts by label
                if (fp.facetDefs[name].fact_identifier) {
                    fid = fp.facetDefs[name].fact_identifier;
                    sorter = function (a, b) {
                        var aIdx, bIdx;

                        aIdx = fp.getFactOrder(name, a, fid);
                        bIdx = fp.getFactOrder(name, b, fid);
                        if (aIdx < bIdx) {
                            return -1;
                        }
                        if (aIdx > bIdx) {
                            return 1;
                        }
                        return 0;
                    };
                }

                // custom facet sorter overrides all
                if (fp.facetDefs[name].sorter) {
                    sorter = fp.facetDefs[name].sorter;
                }

                Ext.each(facets.sort(sorter), function (item, idx, array) {
                    var checkedState, elId;

                    if (item.term === null) {
                        return;
                    }
                    checkedState = false;
                    elId = Ext.util.Format.htmlEncode(name + '-' +
                         AIR2.Search.cleanQueryForTag(item.term));
                    if (AIR2.Search.Facets.CheckOnLoad[elId]) {
                        checkedState = AIR2.Search.Facets.CheckOnLoad[elId];
                        isActive = true;
                    }
                    if (name === 'src_household_income') {
                        item.label = AIR2.Format.householdIncome(item.term);
                    }
                    listOfFacets.push({
                        cls: 'air2-facet-body',
                        tpl: genericTpl,
                        data: {
                            label       : Ext.util.Format.htmlEncode(
                                fp.getItemLabel(name, item)
                            ),
                            count       : Ext.util.Format.number(
                                item.count,
                                '0,000'
                            ),
                            facetName   : Ext.util.Format.htmlEncode(name),
                            facetValue  : Ext.util.Format.htmlEncode(item.term),
                            facetId     : elId,
                            href        : fp.uriFor(name, item.term),
                            checked     : checkedState,
                            onclick     : 'AIR2.Search.Facets.onFacetClick(' +
                                'this,' +
                                'true' +
                            ')'
                        }
                    });
                });
            }

            listPanel = new AIR2.Search.Facets.ListPanel({
                title   : fp.getFacetLabel(name),
                iconCls : 'air2-icon-' + name,
                activeOnLoad : isActive,
                border  : false,
                defaults: { border: false, style: 'padding: 2px' },
                collapsed: true,
                items   : listOfFacets
            });

            facetPanels.push(listPanel);

        });

        fp.removeAll();
        fp.add(facetPanels);
        fp.doLayout();
    },

    getFacetRenderer : function (facetName) {
        if (facetName === "smadd_zip") {
            return AIR2.Search.Facets.ZipTree;
        }
        else if (facetName === "smadd_county") {
            return AIR2.Search.Facets.InitialAlphaTree;
        }
        return null;    // TODO
    },

    getFacetLabel : function (facetName) {
        return this.facetDefs[facetName].label;
    },

    getItemLabel : function (facetName, item) {
        var label, term;

        label = null;
        term  = item.term;
        if (Ext.isDefined(item.label)) {
            label = item.label;
        }
        else if (
            Ext.isDefined(this.facetDefs[facetName].itemLabels) &&
            Ext.isDefined(this.facetDefs[facetName].itemLabels[term])
        ) {
            label = this.facetDefs[facetName].itemLabels[term];
        }
        else {
            label = term;
        }
        if (!Ext.isDefined(label)) {
            //Logger("no label for ",item);
            label = "";
        }
        return label;
    },

    getFactOrder : function (facetName, item, factIdent) {
        var fvals, i, term;

        term = item.term;
        fvals = AIR2.Fixtures.Facts[factIdent];
        for (i = 0; fvals && i < fvals.length; i++) {
            if (term.toLowerCase() === fvals[i][1].toLowerCase()) {
                return i; //index of fact_value
            }
        }
        return 999; //put it last
    },

    // TODO allow for ranges and wildcards
    uriFor : function (facet, term) {
        var filter, params, uri;

        filter = facet + '=(' + term + ')';
        if (Ext.isDefined(AIR2.Search.FILTER) && AIR2.Search.FILTER.length) {
            filter += ' ' + AIR2.Search.FILTER;
        }
        params = Ext.urlEncode({q: AIR2.Search.PARAMS.q, F: filter});
        uri = this.baseUrl + params;
        return uri;
    }
});

AIR2.Search.Facets.InitialAlphaTree = function (name, payload, fp) {
    var alphas, alphaGroups, isActive, nodes, termSorter, tpl, tree;

    nodes = [];
    tpl = new Ext.XTemplate(
        '<div class="air2-facet-pair">' +
            '<input type="hidden" id="{facetId}" name="{facetName}" ' +
                'value="{facetValue}" class="{checked}" />' +
            '<tpl if="checked==\'i\'">' +
                '<img class="bullet {checked}" src="' +
                    AIR2.Search.BULLET_INCLUDE_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<tpl if="checked==\'e\'">' +
                '<img class="bullet {checked}" src="' +
                    AIR2.Search.BULLET_EXCLUDE_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<tpl if="checked==false">' +
                '<img class="bullet " src="' +
                    AIR2.Search.BULLET_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<label for="{facetId}" class="{facetValue}">' +
                ' <span class="air2-facet-value">{label}</span>' +
                ' <span class="count">({count})</span>' +
            '</label>' +
        '</div>'
    );
    tpl.compile();

    isActive = false;  // track whether panel is expanded on page load

    // massage our hashed children nodes into arrays grouped by initial cap.
    //Logger(payload);
    alphaGroups = {};
    alphas = [];
    Ext.each(payload, function (item, idx, array) {
        var ltr = item.term.substr(0, 1).toUpperCase();
        if (!alphaGroups[ltr]) {
            alphaGroups[ltr] = { count: 0, group: [] };
        }
        alphaGroups[ltr].group.push(item);
        alphaGroups[ltr].count += item.count;
    });
    Ext.iterate(alphaGroups, function (key, val, object) {
        alphas.push(key);
    });

    termSorter = function (a, b) {
        var aLabel, bLabel;
        aLabel = a.term.toLowerCase();
        bLabel = b.term.toLowerCase();
        if (aLabel < bLabel) {
            return -1;
        }
        if (aLabel > bLabel) {
            return 1;
        }
        return 0;
    };

    Ext.each(alphas.sort(), function (ltr, idx, arr) {
        var array, children, elId, rec, sorted;

        if (ltr === null) {
            return true;
        }

        array = alphaGroups[ltr].group;
        elId = Ext.util.Format.htmlEncode(name + '-' + ltr);
        rec = {};
        rec.text = tpl.apply({
            checked: -1,
            label: ltr,
            count: alphaGroups[ltr].count
        });
        rec.leaf = false;
        rec.facetPanel = fp;
        sorted = array.sort(termSorter);
        children = [];
        Ext.each(sorted, function (childRec, idx2, sortedArray) {
            var childElId, childHtml, checkedState, isActive2;

            checkedState = false;
            childElId = Ext.util.Format.htmlEncode(name + '-' + childRec.term);
            isActive2 = false;

            if (AIR2.Search.Facets.CheckOnLoad[elId]) {
                checkedState = AIR2.Search.Facets.CheckOnLoad[childElId];
                isActive2 = true;
                isActive = true;
                rec.expanded = true;
                childRec.expanded = true;
            }
            childHtml = tpl.apply({
                label       : childRec.term,
                count       : childRec.count,
                checked     : checkedState,
                facetName   : Ext.util.Format.htmlEncode(name),
                facetValue  : Ext.util.Format.htmlEncode(
                    '(' + childRec.term + ')'
                ),
                facetId     : childElId,
                onclick     : 'AIR2.Search.Facets.onFacetClick(this,true)'
            });
            childRec.text     = childHtml;
            childRec.leaf     = true;
            childRec.facetPanel = fp;
            childRec.facetId    = childElId;
            children.push(childRec);
        });
        rec.children = children;
        nodes.push(rec);
    });

    //Logger(nodes);
    tree = new AIR2.Search.Facets.Tree({
        defaults: { cls: "", border: false, style: 'padding: 2px' },
        root: new Ext.tree.AsyncTreeNode({
            children: nodes,
            expanded: true
        })
    });
    tree.isActive = isActive;

    return tree;
};

AIR2.Search.Facets.ZipTree = function (name, zips, fp) {
    var isActive, nodes, tpl, tree;

    //Logger(zips);
    nodes = [];
    tpl = new Ext.XTemplate(
        '<div class="air2-facet-pair">' +
            '<input type="hidden" id="{facetId}" name="{facetName}" ' +
                'value="{facetValue}" class="{checked}" />' +
            '<tpl if="checked==\'i\'">' +
                '<img class="bullet {checked}" src="' +
                    AIR2.Search.BULLET_INCLUDE_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<tpl if="checked==\'e\'">' +
                '<img class="bullet {checked}" src="' +
                    AIR2.Search.BULLET_EXCLUDE_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<tpl if="checked==false">' +
                '<img class="bullet " src="' +
                    AIR2.Search.BULLET_IMG +
                    '" onclick="{onclick}" id="{facetId}-img" />' +
            '</tpl>' +
            '<label for="{facetId}" class="{facetValue}">' +
                ' <span class="air2-facet-value">{label}</span>' +
                ' <span class="count">({count})</span>' +
            '</label>' +
        '</div>'
    );
    tpl.compile();

    isActive = false;  // track whether panel is expanded on page load

    // massage our hashed children nodes into arrays.
    Ext.each(zips, function (item, idx, array) {
        var children, elId, rec, threes, z1, zip3;

        if (item === null) {
            return true;
        }
        rec = item;
        z1 = idx + 'xxxx';
        elId = Ext.util.Format.htmlEncode(name + '-' + idx);
        rec.text = tpl.apply({ checked: -1, label: z1, count: rec.count });
        rec.leaf = false;
        rec.facetPanel = fp;
        threes = [];
        for (zip3 in rec.threes) {
            threes.push(zip3);
        }
        threes = threes.sort();
        children = [];
        Ext.each(threes, function (item3, idx3, array3) {
            var checkedState3, elId3, fives, html3, isActive3, rec3, z3, zip5;

            if (Ext.isDefined(rec.threes[item3])) {
                rec3 = rec.threes[item3];
                rec3.children = [];
                checkedState3 = false;
                z3 = item3 + 'xx';
                elId3 = Ext.util.Format.htmlEncode(name + '-' + item3);
                isActive3 = false;
                if (AIR2.Search.Facets.CheckOnLoad[elId3]) {
                    checkedState3 = AIR2.Search.Facets.CheckOnLoad[elId3];
                    isActive3 = true;
                    isActive = true;
                    rec.expanded = true;
                }
                html3 = tpl.apply({
                    label       : z3,
                    count       : rec3.count,
                    checked     : checkedState3,
                    facetName   : Ext.util.Format.htmlEncode(name),
                    facetValue  : Ext.util.Format.htmlEncode(
                        '(' + item3 + '*)'
                    ),
                    facetId     : elId3,
                    onclick     : 'AIR2.Search.Facets.onFacetClick(this,true)'
                });
                rec3.text     = html3;
                rec3.leaf     = false;
                rec3.facetPanel = fp;
                rec3.facetId    = elId3;
                rec3.activeOnLoad = isActive3;

                fives = [];
                for (zip5 in rec3.fives) {
                    fives.push(zip5);
                }
                fives = fives.sort();
                Ext.each(fives, function (item5, idx5, array5) {
                    var checkedState5, elId5, html5, isActive5, rec5, z5;
                    if (Ext.isDefined(rec3.fives[item5])) {
                        rec5 = rec3.fives[item5];
                        checkedState5 = false;
                        z5 = item5;
                        elId5 = Ext.util.Format.htmlEncode(name + '-' + z5);
                        isActive5 = false;
                        if (AIR2.Search.Facets.CheckOnLoad[elId5]) {
                            checkedState5 = AIR2.Search.Facets.CheckOnLoad[
                                elId5
                            ];
                            isActive5 = true;
                            isActive = true;
                            rec.expanded = true;
                            rec3.expanded = true;
                        }
                        html5 = tpl.apply({
                            label       : z5,
                            count       : rec5.count,
                            checked     : checkedState5,
                            facetName   : Ext.util.Format.htmlEncode(name),
                            facetValue  : Ext.util.Format.htmlEncode(
                                '(' + item5 + '*)'
                            ),
                            facetId     : elId5,
                            onclick     : 'AIR2.Search.Facets.onFacetClick(' +
                                'this,' +
                                'true' +
                            ')'
                        });
                        rec5.text     = html5;
                        rec5.leaf     = true;
                        rec5.facetPanel = fp;
                        rec5.facetId    = elId5;
                        rec3.children.push(rec5);
                    }
                });
                children.push(rec3);
            }
        });
        rec.children = children;
        nodes.push(rec);
    });

    //Logger(nodes);
    tree = new AIR2.Search.Facets.Tree({
        defaults: { cls: "", border: false, style: 'padding: 2px' },
        root: new Ext.tree.AsyncTreeNode({
            children: nodes,
            expanded: true
        })
    });
    tree.isActive = isActive;

    return tree;
};

AIR2.Search.Facets.Tree = Ext.extend(Ext.tree.TreePanel, {
    autoScroll: true,
    animate: true,
    enableDD: false,
    rootVisible: false,
    frame: false,
    border: false,
    cls: 'air2-facet-panel',
    loader: new Ext.tree.TreeLoader({
        createNode : function (attr) {
            //Logger("createNode called with ", attr);
            if (!Ext.isDefined(attr)) {
                //Logger("attr not defined");
                return false;
            }
            if (attr.count) {
                attr.isFacet = true;
            }
            if (attr.children) {
                if (!Ext.isDefined(attr.cls)) {
                    attr.cls = '';
                }
                attr.cls += ' parent';
            }

            return Ext.tree.TreeLoader.prototype.createNode.call(this, attr);
        }
    }),
    collapsed: false
});

AIR2.Search.Facets.reloadStore = function () {
    var facetPanel, lastOpts, store;

    // fetch the store
    store = AIR2.Search.DATAVIEW.getStore();
    //Logger("store:", store);

    // reload it
    lastOpts = store.lastOptions;
    Ext.apply(lastOpts.params, {
        q:     AIR2.Search.getQuery(),
        start: AIR2.Search.getStart(),
        limit: AIR2.Search.getPageSize(),
        s:     AIR2.Search.getSortedBy()
    });
    facetPanel = Ext.getCmp('air2-search-facets').getEl();
    facetPanel.mask("Applying filters ...");
    lastOpts.callback = function () {
        AIR2.Search.DATAVIEW.refresh();
        facetPanel.unmask();
    };
    store.reload(lastOpts);

};

AIR2.Search.Facets.getChecked = function () {
    var checkboxes, checked, panel;

    panel = Ext.getCmp('air2-search-facets').getEl();
    //Logger("facets wrapper:", panel);
    checkboxes = panel.query('input');
    checked = [];
    Ext.each(checkboxes, function (item, idx, array) {
        var el = Ext.get(item);
        //TODO why was this disabled?
//         if (el.hasClass('x-tree-node-cb')) {
//             //return true; // skip
//         }
        //Logger("checked?", item);
        if (item.checked && item.type !== "hidden") {
            //Logger("item.checked==true");
            checked.push(item);
        }
        else if (
            el.hasClass('i') ||
            el.hasClass('e')
        ) {
            checked.push(item);
        }
        else if (el.hasClass('checked')) {
            //Logger("el.hasClass checked==true");
            checked.push(item);
        }
    });
    //Logger('checked:', checked);
    return checked;
};

AIR2.Search.Facets.getCheckedImgs = function () {
    var checked, el, imgs, panel;

    panel = Ext.getCmp('air2-search-facets').getEl();
    //Logger("facets wrapper:", panel);
    imgs = panel.query('img');
    checked = [];
    Ext.each(imgs, function (item, idx, array) {
        el = Ext.get(item);
        //Logger("checked?", item);
        if (
            el.hasClass('i') ||
            el.hasClass('e')
        ) {
            checked.push(item);
        }
        else if (el.hasClass('checked')) {
            //Logger("el.hasClass checked==true");
            checked.push(item);
        }
    });
    //Logger('checked:', checked);
    return checked;
};

AIR2.Search.Facets.updateLocation = function () {
    var checked, facetState, state;

    // track which facets are checked via url#target
    facetState = {};
    checked = AIR2.Search.Facets.getChecked();
    Ext.each(checked, function (el, idx, array) {
        var cbox, field, value;

        cbox = Ext.get(el);
        //Logger(cbox);
        field = Ext.util.Format.htmlDecode(el.name);
        value = Ext.util.Format.htmlDecode(el.value);
        if (!Ext.isDefined(facetState[field])) {
            facetState[field] = {};
        }
        facetState[field][value] = cbox.hasClass('e') ? 'e' : 'i';
    });

    state = AIR2.Search.getState();

    if (!state) {
        state = {};
    }
    state.facets = Ext.encode(facetState);
    AIR2.Search.setState(state);
};

AIR2.Search.Facets.toggleBulletImg = function (img) {
    var el, inp;

    el = Ext.get(img);
    inp = el.prev();
    //Logger("clicked:",el);

    // has green check, toggle to red X
    if (el.hasClass("i")) {
        inp.replaceClass("i", "e");
        el.replaceClass("i", "e");
        img.src = AIR2.Search.BULLET_EXCLUDE_IMG;
    }

    // has red X, toggle off
    else if (el.hasClass("e")) {
        inp.removeClass("e");
        el.removeClass("e");
        img.src = AIR2.Search.BULLET_IMG;
    }

    // off, toggle green check
    else {
        inp.addClass("i");
        el.addClass("i");
        img.src = AIR2.Search.BULLET_INCLUDE_IMG;
    }
};

AIR2.Search.Facets.deselectFacet = function (img) {
    var el, inp;

    el = Ext.get(img);
    inp = el.prev();
    inp.removeClass("e");
    inp.removeClass("i");
    el.removeClass("e");
    el.removeClass("i");
    img.src = AIR2.Search.BULLET_IMG;
};

AIR2.Search.Facets.onFacetClick = function (domEl) {
    // update UI
    AIR2.Search.Facets.toggleBulletImg(domEl);

    // update results when Apply explicitly clicked
    //AIR2.Search.Facets.updateLocation();
};

AIR2.Search.Facets.updateResults = function (domEl) {
    //Logger("updateResults for ", domEl);
    AIR2.Search.Facets.reloadStore();
};

/**********************************************************************
 * @class AIR2.Search.Facets.ListPanel
 * @extends Ext.Panel
 * @returns {AIR2.Search.Facets.ListPanel} panel object
 *
 * A subclass of Ext.Panel. Each ListPanel should contain
 * an array of AIR2.Search.Facets.Pair objects as its "items."
 */
AIR2.Search.Facets.ListPanel = Ext.extend(Ext.Panel, {

    constructor : function (cfg) {
        var t = cfg.title;
        delete cfg.title;
        cfg.cls = 'air2-facet-panel';
        cfg.header = true;
        cfg.titleCollapse = true;
        cfg.collapsible = true;
        cfg.hideCollapseTool = true;
        cfg.headerCfg = {
            tag: 'div',
            cls: 'air2-facet-title air2-corners',
            html: t
        };
        cfg.iconCls = 'air2-icon-arrow ';
        cfg.headerCssClass = 'air2-facet-header';
        cfg.headerStyle    = 'border:none;padding:3px;';
        AIR2.Search.Facets.ListPanel.superclass.constructor.call(this, cfg);
    },

    getTitleArrow : function () {
        return this.header.child('img');
    },

    hasCheckedFacets : function () {
        var checked, inputs;

        inputs = this.getEl().query('input');
        if (!inputs.length) {
            return 0;
        }
        checked = 0;
        Ext.each(inputs, function (item, idx, array) {
            //Logger(item);
            var el = Ext.get(item);
            if (
                el.hasClass('checked') ||
                el.hasClass("i") ||
                el.hasClass('e')
            ) {
                checked++;
            }
        });
        return checked;
    },


    initComponent : function (cfg) {

        if (!Ext.isDefined(this.items)) {
            throw new Ext.Error("items is not defined");
        }

        this.on('beforecollapse', function (lp) {
            //Logger("collapsed", lp.header.dom.innerHTML);
            var arrow = this.getTitleArrow();
            arrow.addClass('air2-icon-arrow-closed');
            arrow.removeClass('air2-icon-arrow-open');
            arrow.removeClass('air2-icon-arrow-closed-hover');
            arrow.removeClass('air2-icon-arrow-open-hover');

            // if there are any checked boxes, indicate via the title bar
            if (lp.hasCheckedFacets()) {
                lp.header.addClass('air2-facet-title-active');
            }

            return true;
        });

        this.on('beforeexpand', function (lp) {
            //Logger("expand", lp.header.dom.innerHTML);
            var arrow = this.getTitleArrow();
            arrow.removeClass('air2-icon-arrow-closed');
            arrow.addClass('air2-icon-arrow-open');
            arrow.removeClass('air2-icon-arrow-closed-hover');
            arrow.removeClass('air2-icon-arrow-open-hover');
            lp.header.removeClass('air2-facet-title-active');
            return true;
        });

        this.on('afterrender', function (lp) {
            var arrow;

            if (lp.activeOnLoad) {
                //h.addClass('air2-facet-title-active');
                lp.expand();
                // TODO arrow does not toggle??
                arrow = this.getTitleArrow();
                arrow.addClass('air2-icon-arrow-open');
                arrow.removeClass('air2-icon-arrow-closed');
            }
        });

        this.on('render', function (lp) {
            var arrow, h;

            h = lp.header;
            arrow = lp.getTitleArrow();
            h.on('mouseenter', function (ev, el, obj) {
                h.toggleClass('air2-facet-title-hover');
                if (arrow.hasClass('air2-icon-arrow-closed')) {
                    arrow.addClass('air2-icon-arrow-closed-hover');
                }
                else {
                    arrow.addClass('air2-icon-arrow-open-hover');
                }
            });
            h.on('mouseleave', function (ev, el, obj) {
                h.toggleClass('air2-facet-title-hover');
                arrow.removeClass('air2-icon-arrow-closed-hover');
                arrow.removeClass('air2-icon-arrow-open-hover');
            });
        });

        AIR2.Search.Facets.ListPanel.superclass.initComponent.call(this, cfg);
    }

});

