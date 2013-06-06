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

Ext.ns('AIR2.UI');

/**
 * Data store for DeferredGrid.
 *
 * @class       AIR2.UI.DeferredGridStore
 * @extends     Ext.data.ArrayStore
 * @see         AIR2.UI.DeferredGridPanel
 */
AIR2.UI.DeferredGridStore = Ext.extend(Ext.data.Store, {
    _data: null,
    _filter: null,
    remoteSort: true,

    clear: function () {
        this._data = null;
    },

    getAt: function (index) {
        // getAt should only ever be called when a user has clicked on a row,
        // etc., so it should be okay to just return what we've already loaded.
        return this._data[index];
    },

    getById: function (id) {
        console.log('getById => ' + id);
    },

    getCount: function () {
        if (!this._data) {
            return 0;
        }

        return this._data.length;
    },

    indexOfId: function (id) {
        return id;
    },

    getRange: function (start, end) {
        return this._data;
    },

    init: function () {
        var new_fields = new Ext.util.MixedCollection();
        new_fields.addAll(this.fields);

        this.fields = new_fields;
    },

    initData: function (num) {
        var emptyData, i;

        // Initialize the data array with 'loading' objects.
        emptyData = {_stub: true};
        this.fields.each(function (field, index, length) {
            emptyData[field.name] = '...';
        });

        this._data = Array(num);
        for (i = 0; i < this._data.length; i++) {
            this._data[i] = new Ext.data.Record(emptyData, i);
        }
    },

    load: function () {
        Logger('load()');
        Logger(this.sortInfo);
    },

    loadData: function (start, end) {
        // Adjust 'end' if it's past the actual end. This allows callers to not
        // worry about this component breaking if it's asked to load 'too many.'
        if (this._data && end > this._data.length - 1) {
            end = this._data.length - 1;
        }

        this._doLoad(start, end);
    },

    setFilter: function (filter) {
        this._filter = filter;
    },

    _doLoad: function (start, end) {
        var already_loaded,
            i,
            need,
            self,
            uri;

        self = this;
        need = end - start;

        // If all visible elements are already loaded, bail.
        already_loaded = 0;
        if (self._data) {
            for (i = start; i < end; i++) {
                if (self._data[i].get('_stub') === false) {
                    already_loaded++;
                }
            }
        }
        if (already_loaded === need) {
            return;
        }

        // Goose the number up a bit, so we can account for a cell being almost
        // totally visible, etc.
        need++;

        if (need === 0) {
            return;
        }

        uri = self.uri + "&offset=" + start + "&limit=" + need;

        // Apply any filtering requested by the user.
        if (self._filter) {
            uri = uri + '&filter=' + self._filter;
        }

        // "Loading" event.
        self.panel.onLoading();

        Ext.Ajax.request({
            url: uri,
            success: function (result, request) {
                var i, json, raw_data;

                json = Ext.util.JSON.decode(result.responseText);

                // Initialize data array with stub data,
                // if this is the first load.
                if (!self._data) {
                    self.initData(json.total);
                }

                for (i = start; i < (start + need); i++) {
                    raw_data = json.radix[(i - start)];

                    // We might have been given an inflated number, in order to
                    // create a buffer. Account for this by bailing if we're at
                    // the end.
                    if (!raw_data) {
                        break;
                    }

                    raw_data._stub = false;

                    self._data[i] = new Ext.data.Record(raw_data, i);
                }

                // Refresh the display.
                self.panel.getView().refresh();

                // "Done loading" event.
                self.panel.onLoadingDone();
            }
        });
    }
});

/**
 * GridPanel that loads from an AIR2 API uri on demand.
 *
 * @class       AIR2.UI.DeferredGridPanel
 * @extends     Ext.grid.GridPanel
 * @xtype       air2deferredgridview
 */
AIR2.UI.DeferredGridPanel = Ext.extend(Ext.grid.GridPanel, {
    min: null,
    max: null,
    _timeout: null,
    _mask: null,
    initComponent: function () {
        // Call parent class initComponent();
        AIR2.UI.DeferredGridPanel.superclass.initComponent.call(this);

        // Initialize data store.
        this.store = new AIR2.UI.DeferredGridStore({
            fields: this.fields,
            idIndex: 0,
            uri: this.uri,
            url: this.uri,
            panel: this,
            remoteSort: true,
            restful: true
        });
        this.getStore().init();

        this.min = -1;
        this.max = -1;

        var self = this;

        /**
         * Event handling.
         */
        this.on('afterrender', function () {
            self._initCss();
            self._handleResize();
        });


        this.on('resize', function () {
            self._handleResize();
        });

        this.on('bodyscroll', function (scroll_left, scroll_top) {
            // Wait to make sure scrolling has ended.
            if (self._timeout !== null) {
                window.clearTimeout(self._timeout);
            }

            self._timeout = window.setTimeout(
                function () {
                    var new_max, new_min;

                    new_min = Math.floor(scroll_top / self.rowHeight);
                    new_max = new_min + self.rowsVisible;

                    // Need to have view updated?
                    if (new_min !== self.min) {
                        self.getStore().loadData(new_min, new_max);
                    }

                    self.min = new_min;
                    self.max = new_max;
                },
                200
            );
        });
    },
    onLoading: function () {
        _mask = new Ext.LoadMask(this.id, {msg: "Loading..."});
        _mask.show();
    },
    onLoadingDone: function () {
        _mask.hide();
    },
    setFilter: function (filter) {
        Logger('called setFilter on grid');
        this.getStore().setFilter(filter);

        this.getStore().clear();
        this.getStore().loadData(0, this.rowsVisible + 200);
    },
    _handleResize: function () {
        var inner = new Ext.Element(this.el.query('.x-grid3-scroller')[0]);
        this.gridInnerHeight = inner.getHeight();
        this.rowsVisible = Math.floor(this.gridInnerHeight / this.rowHeight);

        // Initialize range of visible rows.
        this.min = 0;
        this.max = this.rowsVisible;

        // Tell the store to load the visible rows.
        this.getStore().loadData(
            this.min,

            // Add 200 to the needed number of records, to create a buffer.
            this.max + 200
        );
    },
    _initCss: function () {
        var block = document.createElement('style');
        block.type = 'text/css';
        block.innerHTML = '#' + this.id +
            ' .x-grid3-cell-inner { height: ' + this.rowHeight + 'px; ' +
            ' padding: 3px 3px 3px 6px; border-width: 1px; }';
        document.getElementsByTagName('head')[0].appendChild(block);

        // Add padding and border to row height.
        this.rowHeight = this.rowHeight + 8;
    }
});
Ext.reg('air2deferredgridview', AIR2.UI.DeferredGridPanel);
