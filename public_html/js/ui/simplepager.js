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
/***************
 * AIR2 SimplePager Component
 *
 * A stripped-down version of an Ext.PagingToolbar that only shows a couple
 * buttons.
 *
 * @class AIR2.UI.SimplePager
 * @extends Ext.PagingToolbar
 * @xtype air2simplepager
 * @cfg {Boolean} showFirst     (default: true)
 * @cfg {Boolean} showInfo      (default: true)
 * @cfg {Boolean} showLast      (default: true)
 * @cfg {Boolean} showRefresh   (default: true)
 * @cfg {Boolean} pageInfo      (default: 'Page {0} of {1}')
 *
 */
AIR2.UI.SimplePager = function (cfg) {


    AIR2.UI.SimplePager.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.SimplePager, Ext.PagingToolbar, {
    // defaults
    showFirst:   true,
    showInfo:    true,
    showLast:    true,
    showRefresh: true,
    pageInfo: 'Page {0} of {1}',
    // override, because PagingToolbar doesn't give a good
    // way to extend this
    initComponent : function () {
        var pagingItems, T;

        T = Ext.Toolbar;
        pagingItems = [];

        // create items (will show/hide later)
        this.first = new T.Button({
            tooltip: this.firstText,
            overflowText: this.firstText,
            iconCls: 'x-tbar-page-first',
            disabled: true,
            handler: this.moveFirst,
            scope: this
        });
        this.prev = new T.Button({
            tooltip: this.prevText,
            overflowText: this.prevText,
            iconCls: 'x-tbar-page-prev',
            disabled: true,
            handler: this.movePrevious,
            scope: this
        });
        this.next = new T.Button({
            tooltip: this.nextText,
            overflowText: this.nextText,
            iconCls: 'x-tbar-page-next',
            disabled: true,
            handler: this.moveNext,
            scope: this
        });
        this.last = new T.Button({
            tooltip: this.lastText,
            overflowText: this.lastText,
            iconCls: 'x-tbar-page-last',
            disabled: true,
            handler: this.moveLast,
            scope: this
        });
        this.refresh = new T.Button({
            tooltip: this.refreshText,
            overflowText: this.refreshText,
            iconCls: 'x-tbar-loading',
            handler: this.doRefresh,
            scope: this
        });
        this.inputItem = new T.TextItem({
            text: '1',
            setValue: function (v) {
                this.setText(v);
            }
        });
        this.afterTextItem = new T.TextItem({
            text: String.format(this.afterPageText, 1)
        });

        // order items
        if (this.showFirst) {
            pagingItems.push(this.first);
        }
        pagingItems.push(this.prev, '-');
        if (this.showInfo) {
            pagingItems.push(this.inputItem, this.afterTextItem, '-');
        }
        pagingItems.push(this.next);
        if (this.showLast) {
            pagingItems.push(this.last);
        }
        if (this.showRefresh) {
            pagingItems.push('->', this.refresh);
        }

        // SKIP calling parent, and go straight to grandparent
        this.items = pagingItems;
        Ext.PagingToolbar.superclass.initComponent.call(this);
        this.addEvents('change', 'beforechange');
        this.on('afterlayout', this.onFirstLayout, this, {single: true});
        this.cursor = 0;
        this.bindStore(this.store, true);
    }
});
Ext.reg('air2simplepager', AIR2.UI.SimplePager);
