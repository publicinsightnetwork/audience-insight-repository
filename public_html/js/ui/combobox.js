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
 * AIR2 ComboBox Component
 *
 * A stripped-down version of the Ext.form.ComboBox, providing a very simple
 * way to display an array of items.
 *
 * @class AIR2.UI.ComboBox
 * @extends Ext.form.ComboBox
 * @xtype air2combo
 * @cfg {Array} choices
 *   An array of value-display string groupings, of the format:
 *   [['value1', 'display1'], ['value2', 'display2], ... etc]
 *
 */
AIR2.UI.ComboBox = function (cfg) {
    if (!cfg) {
        cfg = {};
    }
    if (!cfg.choices) {
        cfg.choices = [['', ['testdisplay']]];
    }
    if (!cfg.store) {
        cfg.store = new Ext.data.ArrayStore({
            id: 0,
            fields: ['value', 'display'],
            data: cfg.choices
        });
    }

    AIR2.UI.ComboBox.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.ComboBox, Ext.form.ComboBox, {
    mode: 'local',
    valueField: 'value',
    displayField: 'display',
    triggerAction: 'all',
    forceSelection: true,
    editable: false
});
Ext.reg('air2combo', AIR2.UI.ComboBox);
