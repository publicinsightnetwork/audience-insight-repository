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
 * Plugin for GridPanels that adds a column consisting only of checkboxes.
 * Clicking on checkboxes doesn't trigger and 'row selected' events.
 * Checking and unchecking checkboxes triggers 'rowchecked' and 'rowunchecked'
 * events on the grid.
 *
 * @see GridPanel
 * @author sgilbertson
 */
AIR2.UI.CheckableRow = Ext.extend(Object, {
    id: 'checkbox-cell',

    // header: '<input type="checkbox" />',
    header:
        '<div id="check-select">' +
            '<a href="#" id="check-select-drop"><input type="checkbox"></a>' +
            '<ul>' +
                '<li><a href="#">Page <span>(10)</span></a></li>' +
                '<li><a href="#">All <span>(452)</span></a></li>' +
                '<li><a href="#">Insightful <span>(14)</span></a></li>' +
                '<li><a href="#">Thanked <span>(25)</span></a></li>' +
                '<li><a href="#">Not Thanked <span>(427)</span></a></li>' +
                '<li><a href="#">None</a></li>' +
            '</ul>' +
        '</div>',
    menuDisabled: true,

    width: 30,
    dataIndex: '',

    // Initializer.
    init: function (grid) {
        var originalHandleMouseDown;
        // Add ourselves as a column onto the grid.
        grid.getColumnModel().config.unshift(this);

        /*
         * Alter grid such that it won't select an entire row when the user is
         * just clicking on a check box.
         *
         * Also, checking and unchecking checkboxes triggers 'rowchecked' and
         * 'rowunchecked' events.
         */
        grid.addEvents('rowchecked', 'rowunchecked');

        originalHandleMouseDown = grid.getSelectionModel().handleMouseDown;
        grid.getSelectionModel().handleMouseDown = function (grid, row, event) {
            // If targeting the checkbox, stop the show right there.
            if (event.getTarget('div.x-grid3-col-checkbox-cell')) {
                event.stopEvent();
                return false;
            }

            // Otherwise, follow normal mousedown behavior.
            originalHandleMouseDown.apply(this, arguments);
        };

        grid.on('cellclick', function (grid, row, col, event) {
            var checkbox,
                record;

            record = grid.getStore().getAt(row);

            if (col === 0) {
                checkbox = event.getTarget('input');
                if (checkbox.checked) {
                    grid.fireEvent('rowchecked', grid, row, col, record);
                }
                else {
                    grid.fireEvent('rowunchecked', grid, row, col, record);
                }

                event.stopPropagation();
                return false;
            }
        });
    },

    // Rendering function.
    renderer: function () {
        return '<input class=".x-form-check" type="checkbox" />';
    }
});
