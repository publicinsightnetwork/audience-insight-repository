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
 * AIR2 SearchBox Component
 *
 * A combo box configured to auto-populate from a queryable url as one types
 * in it.
 *
 * @class AIR2.UI.SearchBox
 * @extends Ext.form.ComboBox
 * @xtype air2searchbox
 * @cfg {String} searchUrl
 *   A url to apply the search to, use the "q" query paramater.
 * @cfg {Function} formatComboListItem
 *   Function to format a data object returned from the searchUrl as a user
 *   viewable string
 * @cfg {Function} formatToolTip
 *   Optional function to show a tooltip for search result items
 * @cfg {Object} baseParams
 *   Optional base parameters for the search query
 * @cfg {String} valueField
 * @cfg {String} displayField
 *
 */
AIR2.UI.SearchBox = function (config) {
    var combostore, dispfld;

    combostore = new AIR2.UI.APIStore({
        autoLoad    : false,
        autoSave    : false, // we handle this ourselves.
        autoDestroy : true,
        restful     : true,  // use GET where appropriate
        remoteSort  : true,
        url: config.searchUrl + '.json',
        baseParams: (config.baseParams) ? config.baseParams : undefined,
        stateful: false
    });

    if (!config.formatComboListItem) {
        dispfld = config.displayField;
        config.formatComboListItem = function (v) {
            return v[dispfld];
        };
    }

    // call parent constructor, merging default options
    AIR2.UI.SearchBox.superclass.constructor.call(this, Ext.apply({
        store: combostore,
        minChars: 1,
        queryParam: 'q',
        mode: 'remote',
        triggerAction: 'all',
        autoSelect: true,
        forceSelection: true,
        hideTrigger: true,
        shadow: false,
        allowBlank: false,
        ctCls: 'air2-searchbox',
        tpl: new Ext.XTemplate(
            '<ul><tpl for=".">' +
              '<li class="x-combo-list-item" {[this.getToolTip(values)]}>' +
                '<span>{[this.formatName(values)]}' +
              '</span></li>' +
            '</tpl></ul>', {
            compiled: true,
            disableFormats: true,
            formatName: config.formatComboListItem,
            getToolTip: config.formatToolTip || function () {}
        })
    }, config));

    // event handlers
    this.on('select', function (combo, record, index) {
        this.selectedRecord = record;
    }, this);
};
Ext.extend(AIR2.UI.SearchBox, Ext.form.ComboBox, {
    getSelectedRecord: function () {
        if (this.selectedRecord) {
            return this.selectedRecord;
        }
        else {
            return false;
        }
    },
    selectRawValue: function (val, shortQuery) {
        this.store.on('load', function () {
            this.setValue(val);
        }, this, {single: true});
        if (!shortQuery) {
            shortQuery = '';
        }
        this.doQuery(shortQuery, true);
    },
    selectOrDisplay: function (val, disp, shortQuery) {
        // check if we've loaded the store yet
        if (!this.store.fields) {
            this.setValue(disp); //temporary
            this.selectRawValue(val, shortQuery);
        }
        else {
            this.setValue(val);
        }
    },
    getParams: function (q) {
        return (this.pageSize) ? {offset: 0, limit: this.pageSize} : {};
    },
    initList: function () {
        var hadlist, oldpgsz;

        hadlist = this.list ? true : false;
        oldpgsz = this.pageSize;

        delete this.pageSize; //make sure parent doesn't create pager
        AIR2.UI.SearchBox.superclass.initList.call(this);

        // create simple pager
        if (!hadlist && oldpgsz) {
            this.footer = this.list.createChild({cls: 'x-combo-list-ft'});
            this.pageTb = new AIR2.UI.SimplePager({
                store:      this.store,
                pageSize:   oldpgsz,
                renderTo:   this.footer,
                showLast:   false
            });
            this.assetHeight += this.footer.getHeight();
            this.pageSize = oldpgsz;
        }
    }
});
Ext.reg('air2searchbox', AIR2.UI.SearchBox);
