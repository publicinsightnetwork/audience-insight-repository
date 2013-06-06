Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer Toolbar Component
 *
 * An Ext.Toolbar for use as the top toolbar of an AIR2 drawer.
 *
 * @class AIR2.Drawer.Toolbar
 * @extends Ext.Toolbar
 * @cfg {Function} startNewFn
 *   Function that toolbar should call to create a new Bin.
 * @cfg {Function} deleteFn
 *   Function that toolbar should call to delete a Bin.
 *
 */
AIR2.Drawer.Toolbar = function (config) {
    this.startNewFn = config.startNewFn;
    this.deleteFn = config.deleteFn;

    // create the "filter" menu
    this.filterMenu = new Ext.menu.Menu({
        cls: 'air2-drawer-filters',
        showSeparator: false,
        defaults: {
            clickHideDelay: 750,
            checkHandler: this.filterClicked.createDelegate(this)
        }
    });

    // create the "sort by" menu
    this.sortMenu = new Ext.menu.Menu({
        cls: 'air2-drawer-filters',
        showSeparator: false,
        defaults: {clickHideDelay: 750},
        listeners: {
            itemclick: this.sortClicked.createDelegate(this)
        }
    });

    // create the "random output" menu
    var randMenu = new Ext.menu.Menu({
        items: {
            xtype: 'form',
            plain: true,
            labelWidth: 90,
            border: false,
            buttonAlign: 'center',
            title: '<b class="menu-title">Random Output</b>',
            padding: '4px 0 0 0',
            items: [{
                id: 'bin-random-number',
                xtype: 'spinnerfield',
                fieldLabel: 'Number of Bins',
                minValue: 1,
                value: 2,
                width: 54,
                scope: this,
                enableKeyEvents: true,
                listeners: {
                    validspin: function (fld, newVal) {
                        var size = Ext.getCmp('bin-random-size').getValue();
                        return randMenu.isRandomValid(newVal, size);
                    },
                    keydown: function (fld, ev) {
                        fld.preDownVal = fld.getValue();
                    },
                    keyup: function (fld, ev) {
                        var newVal, size;

                        newVal = fld.getValue();
                        size = Ext.getCmp('bin-random-size').getValue();
                        if (!randMenu.isRandomValid(newVal, size)) {
                            fld.setValue(fld.preDownVal);
                        }
                    }
                }
            }, {
                id: 'bin-random-size',
                xtype: 'numberfield',
                fieldLabel: 'Size of each Bin',
                emptyText: 'auto',
                width: 54,
                allowDecimals: false,
                minValue: 1,
                enableKeyEvents: true,
                listeners: {
                    keyup: function (fld, ev) {
                        var newVal, number;

                        newVal = fld.getValue();
                        number = Ext.getCmp('bin-random-number').getValue();
                        if (!randMenu.isRandomValid(number, newVal)) {
                            fld.setValue(fld.lastValid);
                        }
                        else if (Ext.isNumber(newVal) && (newVal < 1)) {
                            fld.setValue(fld.lastValid);
                        }
                        else {
                            fld.lastValid = newVal;
                        }
                    }
                }
            }, {
                xtype: 'container',
                layout: 'hbox',
                items: [{
                    xtype: 'air2button',
                    text: 'Create',
                    air2type: 'BLUE',
                    handler: function (b) {
                        var f, num, size;

                        f = this.randMenu.get(0);
                        if (f.getForm().isValid()) {
                            num = f.get(0).getValue();
                            size = f.get(1).getValue();
                            this.randomClicked(num, size);
                            f.ownerCt.hide(true); //hide menu
                        }
                    }.createDelegate(this)
                }, {
                    xtype: 'air2button',
                    text: 'Cancel',
                    air2type: 'CANCEL',
                    style: 'padding-left:4px',
                    handler: function (b) {
                        this.randMenu.hide();
                    }.createDelegate(this)
                }]
            }]
        },
        listeners: {
            show: function () {
                var r, total;

                r = this.view.getSelectedRecords()[0];
                total = r.get('src_count');
                randMenu.binCount = total;
            },
            scope: this
        },
        isRandomValid: function (number, size) {
            if (number && size) {
                return (number * size <= this.binCount);
            }
            else if (number) {
                return (number <= this.binCount);
            }
            else {
                return (size <= this.binCount);
            }
        }
    });
    this.randMenu = randMenu;

    config.defaults = {
        cls: 'air2-drawer-btn',
        scope: this
    };
    config.items = [
        '-',
        {
            xtype: 'air2textfilter',
            maskRe: null,
            listeners: {
                filterchange: function (field, value) {
                    if (this.view.applyFilter) {
                        this.view.applyFilter(value);
                    }
                    else {
                        this.view.ownerCt.applyFilter(value);
                    }
                },
                scope: this
            },
            setView: function (vw, dview) {
                this.emptyText = (vw === 'si') ? 'Filter Bin' : 'Search Title';
                this.reset();

                // set any search strings
                var p = dview.store.baseParams;
                if (p.q && p.q.length > 0) {
                    this.setValue(p.q);
                }
            }
        },
        '-',
        {
            iconCls: 'air2-icon-merge',
            tooltip: {text: 'Merge Bins', cls: 'below lighter'},
            handler: this.mergeClicked,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            },
            setBinStatus: function (count, sameType, mayManage) {
                this.setDisabled(!sameType || count < 2);
            }
        },
        {
            iconCls: 'air2-icon-duplicate',
            tooltip: {text: 'Duplicate Bin', cls: 'below lighter'},
            handler: this.mergeClicked,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            },
            setBinStatus: function (count, sameType, mayManage) {
                this.setDisabled(count !== 1);
            }
        },
        {
            iconCls: 'air2-icon-delete',
            tooltip: {text: 'Delete Bin', cls: 'below lighter'},
            handler: this.deleteClicked,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            },
            setBinStatus: function (count, sameType, mayManage) {
                this.setDisabled(!mayManage || count !== 1);
            }
        },
        {
            iconCls: 'air2-icon-random',
            tooltip: {text: 'Random Output', cls: 'below lighter'},
            menuAlign: 't-b?',
            menu: this.randMenu,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            },
            setBinStatus: function (count, sameType, mayManage, binCount) {
                this.setDisabled(count !== 1 || binCount < 2);
            }
        },
        {
            xtype: 'box',
            setTotal: function (s) {
                var total, totalStr, unauthz;

                total = s.getTotalCount();
                totalStr = total + ' Total';

                // add unauthz count
                if (s.reader.jsonData) {
                    unauthz = s.reader.jsonData.meta.unauthz_total;
                }
                else {
                    unauthz = null;
                }
                if (Ext.isDefined(unauthz) && unauthz !== total) {
                    totalStr += ' (' + (unauthz - total) + ' hidden)';
                }
                this.update(totalStr);
            },
            setView: function (vw, dview) {
                // update the total-listener
                this.setVisible(vw === 'si');
                if (vw === 'si') {
                    this.cachestore = dview.store;
                    this.setTotal(dview.store);
                    dview.store.on('load', this.setTotal, this);
                }
                else if (this.cachestore) {
                    this.cachestore.un('load', this.setTotal, this);
                }
            }
        },
        '->',
        {
            text: 'Filters',
            menuAlign: 'tr-br?',
            menu: this.filterMenu,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            }
        },
        {
            text: 'Sort',
            menuAlign: 'tr-br?',
            menu: this.sortMenu,
            setView: function (vw) {
                this.setVisible(vw === 'lg');
            }
        },
        {
            xtype: 'air2button',
            air2type: 'DRAWER',
            iconCls: 'air2-icon-remove-sel',
            text: 'Remove Selected',
            handler: this.removeClicked,
            setView: function (vw) {
                this.setVisible(vw === 'si');
            },
            setBinStatus: function (count, sameType, mayManage) {
                this.setDisabled(!mayManage || count < 1);
            }
        },
        {
            xtype: 'air2button',
            air2type: 'BLUE',
            iconCls: 'air2-icon-upload',
            text: 'Export',
            handler: this.exportClicked,
            setView: function (vw) {
                this.setVisible(vw === 'si');
            }
        }
    ];

    // call parent constructor
    AIR2.Drawer.Toolbar.superclass.constructor.call(this, config);

};
Ext.extend(AIR2.Drawer.Toolbar, Ext.Toolbar, {
    cls: 'air2-bin-tbar',
    setView: function (vwStr, vwObj) {
        //un-listen to the previous view
        if (this.view) {
            this.view.un('selectionchange', this.selChange, this);
        }

        this.view = vwObj;
        this.viewstr = vwStr;
        this.view.on('selectionchange', this.selChange, this);

        this.changeToolbar(vwStr, this.view);
        this.selChange(this.view, []);
        this.changeFilterMenu(vwStr);
        this.changeSortMenu(vwStr);
    },
    selChange: function (dv, sel) {
        var binCount, count, d1, d2, i, mayManage, recs, same, t1, t2;
        count = sel.length;
        same = true;
        recs = dv.getSelectedRecords();
        for (i = 0; i < recs.length - 1; i++) {
            d1 = recs[i].data;
            d2 = recs[i + 1].data;
            t1 = 'S';
            t2 = 'S';
            if (t1 !== t2) {
                same = false;
                break;
            }
        }
        mayManage = (AIR2.USERINFO.type === 'S');
        if (recs.length === 1 && recs[0].data.owner_flag) {
            mayManage = true;
        }
        if (dv.ownerCt && dv.ownerCt.binRecord &&
            dv.ownerCt.binRecord.data.owner_flag) {

            mayManage = true;
        }
        if (dv.binRecord && dv.binRecord.data.owner_flag) {
            mayManage = true;
        }
        binCount = null;
        if (recs.length === 1) {
            binCount = recs[0].data.src_count;
        }

        // update enable/disable of items
        this.items.each(function (item) {
            if (item.setBinStatus) {
                item.setBinStatus(count, same, mayManage, binCount);
            }
        });
    },
    changeToolbar: function (newType, dview) {
        this.items.each(function (item) {
            if (item.setView) {
                item.setView(newType, dview);
            }
        });
    },
    changeFilterMenu: function (newType) {
        var p;
        this.filterMenu.removeAll(true);
        if (newType === 'lg') {
            this.filterMenu.add(AIR2.Drawer.Config.FILTERS.lg);
        }

        // determine the filters from the store
        p = this.view.store.baseParams;
        this.filterMenu.items.each(function (it) {
            if (it.param) {
                it.setChecked((p[it.param] === 1), true);
            }
        });
    },
    changeSortMenu: function (newType) {
        var d, f, parts, s;

        this.sortMenu.removeAll(true);

        if (newType === 'lg') {
            this.sortMenu.add(AIR2.Drawer.Config.SORTFIELDS.lg);
        }

        // determine the sorting order from the store
        s = this.view.store.baseParams.sort;
        f = false;
        d = false;

        if (s && s.length) {
            s = s.split(',', 1).pop();
            if (s && s.length) {
                parts = s.split(' ');
                if (parts.length === 2) {
                    f = parts[0];
                    d = parts[1];
                }
            }
        }

        this.sortMenu.items.each(function (it) {
            if (it.fld === f) {
                if ((d === 'asc' && !it.flip) || (d === 'desc' && it.flip)) {
                    it.setIconClass('air2-icon-sort-asc');
                    it.state = 'ASC';
                } else {
                    it.setIconClass('air2-icon-sort-desc');
                    it.state = 'DESC';
                }
            }
        });
    },
    filterClicked: function (item, checked) {
        var items, t;

        if (item.param) {
            if (checked) {
                this.view.store.baseParams[item.param] = 1;
            }
            else {
                delete this.view.store.baseParams[item.param];
            }
        }
        else if (item.typeCode) {
            t = '';
            items = item.parentMenu.items;
            item.parentMenu.items.each(function (it) {
                if (it.checked) {
                    t += it.typeCode;
                }
            });
            if (t.length) {
                this.view.store.baseParams.type = t;
            }
            else {
                delete this.view.store.baseParams.type;
            }
        }
        this.view.reloadDataView();
    },
    sortClicked: function (item, e) {
        this.sortMenu.items.each(function (it) {
            if (it === item) {
                if (it.state === 'DESC') {
                    it.state = 'ASC';
                    it.setIconClass('air2-icon-sort-asc');
                }
                else {
                    it.state = 'DESC';
                    it.setIconClass('air2-icon-sort-desc');
                }
                var f = it.fld, d = it.state.toLowerCase();

                //allow flipping the sort direction
                if (it.flip && d === 'asc') {
                    d = 'desc';
                }
                else if (it.flip && d === 'desc') {
                    d = 'asc';
                }

                this.view.store.baseParams.sort = f + ' ' + d;
                this.view.reloadDataView();
            }
            else {
                it.state = null;
                it.setIconClass('');
            }
        }, this);
    },
    mergeClicked: function () {
        var i, sel, type;

        if (this.view.getSelectionCount() > 0) {
            sel = this.view.getSelectedRecords();

            // double-check that all bin types match
            type = sel[0].get('bin_type');
            for (i = 0; i < sel.length; i++) {
                type = (sel[i].get('bin_type') === type) ? type : null;
            }
            if (type) {
                this.startNewFn(type, null, sel);
            }
        }
    },
    deleteClicked: function () {
        var sel = this.view.getSelectedRecords();
        this.deleteFn(sel);
    },
    randomClicked: function (num, size) {
        var l, r, v;

        v = this.view;
        if (v.getSelectionCount() === 1) {
            l = this.view.el;
            r = v.getSelectedRecords()[0];
            l.mask("Generating Random Bins");
            AIR2.Drawer.API.random(r, num, size, function (data, success) {
                l.unmask();
                if (success) {
                    v.reloadDataView();
                }
            });
        }
    },
    removeClicked: function () {
        var isAll, l, r, owner, sel, v;

        v = this.view;
        if (v.getSelectionCount() > 0) {
            owner = v;
            l = owner.el;
            r = owner.binRecord;
            sel = v.getSelectedRecords();

            isAll = (sel.length === v.getStore().getCount());
            l.mask('Removing Items');
            AIR2.Drawer.API.removeItems(r, sel, function (data, success) {
                var pgdata, last;

                if (success) {
                    v.store.on('load', function () {
                        l.unmask();
                    }, this, {single: true});

                    // try to stay on the same page
                    if (v.fbar && v.fbar.doRefresh) {
                        pgdata = v.fbar.getPageData();
                        if (isAll && pgdata.activePage === pgdata.pages) {
                            last = Math.max(0, pgdata.activePage - 1);
                            v.fbar.changePage(last);
                        }
                        else {
                            v.fbar.doRefresh();
                        }
                    }
                    else {
                        v.reloadDataView(true);
                    }
                }
                else {
                    l.unmask();
                }
            });
        }
    },
    exportClicked: function () {
        var b = this.view.binRecord.data.bin_uuid;
        AIR2.Bin.Exporter({originEl: this.el, binuuid: b});
    }
});
Ext.reg('air2drawertbar', AIR2.Drawer.Toolbar);
