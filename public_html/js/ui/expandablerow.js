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
 * Plugin for Ext.grid.GridPanels that provides the ability to 'expand'
 * grid rows in order to display a 'row body.'
 */
AIR2.UI.ExpandableRow = Ext.extend(Object, {
    id: 'expand-cell',
    header: '',
    width: 30,
    dataIndex: '',

    /**
     * Reference to grid.
     *
     * @var Ext.grid.GridPanel
     */
    grid: null,

    init: function (grid) {
        var originalHandleMouseDown;

        // Keep a reference to the grid, so we can access it from other methods.
        this.grid = grid;

        grid.getColumnModel().config.push(this);

        grid.addEvents('rowexpanded', 'rowcollapsed');

        originalHandleMouseDown = grid.getSelectionModel().handleMouseDown;
        grid.getSelectionModel().handleMouseDown = function (grid, row, event) {
            // If targeting the expander, stop the show right there.
            if (event.getTarget('div.x-grid3-col-expand-cell')) {
                event.stopEvent();
                return false;
            }

            // Otherwise, follow normal mousedown behavior.
            originalHandleMouseDown.apply(this, arguments);
        };

        grid.on('cellclick', function (grid, rowIndex, col, event) {
            var record,
                row,
                rowBody;

            record = grid.getStore().getAt(rowIndex);

            row = grid.getView().getRow(rowIndex);

            // Last col === us.
            if (col === grid.getColumnModel().getColumnCount() - 1) {
                rowBody = Ext.fly(row).query('.air2-row-body')[0];

                this.toggleBodyVisibility(grid, rowIndex, rowBody, record);

                event.stopPropagation();
                return false;
            }
        }, this);

        grid.on('rowexpanded', function (grid, row, col, event) {
            Logger('rowexpanded');
        }, this);

        grid.on('rowcollapsed', function (grid, row, col, event) {
            Logger('rowcollapsed');
        }, this);
    },

    /**
     * Toggles the visibility of the row's body.
     *
     * @param Ext.Element rowBody
     */
    toggleBodyVisibility: function (grid, row, rowBody, record) {
        var expanderImg = Ext.fly(
                grid.getView().getRow(row)
            ).query('.air2-expander')[0];

        if (!record.hasOwnProperty('expanded') || !record.expanded) {
            record.expanded = true;

            // Call the user-defined 'load body' function/callback, if it was
            // defined.
            if (grid.getView().hasOwnProperty('loadBody')) {
                grid.getView().loadBody(rowBody, record, grid, row);
            }

            console.log(rowBody);
            Ext.fly(rowBody).removeClass('air2-hidden');
            expanderImg.src = AIR2.UI.ExpandableRow.Constants.EXPANDED_IMAGE;
        }
        else {
            record.expanded = false;

            Ext.fly(rowBody).addClass('air2-hidden');
            expanderImg.src = AIR2.UI.ExpandableRow.Constants.COLLAPSED_IMAGE;
        }
    },

    renderer: function (value, metaData, record, row, col, store) {
        // Initial render.
        return '<img class="air2-expander" src="' +
            AIR2.UI.ExpandableRow.Constants.COLLAPSED_IMAGE + '" />';
    }
});

AIR2.UI.ExpandableRow.Constants = {
    COLLAPSED_IMAGE : AIR2.HOMEURL + '/css/img/toggle-expand-gray.png',
    EXPANDED_IMAGE  : AIR2.HOMEURL + '/css/img/toggle-gray.png'
};
