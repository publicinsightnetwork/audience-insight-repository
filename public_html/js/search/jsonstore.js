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

Ext.ns('AIR2.Search.JsonStore');
/***************
 * AIR2 Search JsonStore Component
 *
 * Subclass of Ext.data.JsonStore that knows how to read OpenSearch
 * JSON responses.
 *
 * @class AIR2.Search.JsonStore
 * @extends Ext.data.JsonStore
 * @cfg {Array} choices
 *   An array of value-display string groupings, of the format:
 *   [['value1', 'display1'], ['value2', 'display2], ... etc]
 *
 */

AIR2.Search.JsonStore = function (cfg) {
    if (!cfg) {
        cfg = {};
    }
    if (!cfg.idx) {
        cfg.idx = AIR2.Search.IDX;
    }
    if (!cfg.baseParams) {
        cfg.baseParams = {
            'i' : cfg.idx
        };
    }
    if (!cfg.url) {
        cfg.url = AIR2.Search.URL + '.json';
    }
    if (!cfg.fields) {
        cfg.fields = [
            {name: 'uri'},
            {name: 'title'},
            {name: 'summary'},
            {name: 'mtime', type: 'date', dateFormat: 'timestamp'}
        ];
    }
    if (!cfg.listeners) {
        cfg.listeners = {};
    }
    if (!cfg.listeners.exception) {
        cfg.listeners.exception = function (
            proxy,
            type,
            action,
            options,
            response,
            args
        ) {
            Logger(
                "AIR2.Search.JsonStore caught exception:",
                type,
                action,
                response,
                args
            );
            if (!response) {
                Logger("no response object");
                return;
            }
            var resp;
            if (
                response.status !== '404' &&
                response &&
                response.responseText
            ) {
                try {
                    resp = Ext.decode(response.responseText);
                }
                catch (err) {
                    resp = { error: "Ext.decode failed: " + err.message };
                }
            }
            else {
                resp = { error: "Problem contacting the server." };
            }
            Logger(resp);
            if (this.comboBox) {
                this.comboBox.markInvalid(resp.error);
            }
            else if (resp.error.match(/No such field/)) {
                AIR2.UI.ErrorMsg(Ext.getBody(), "Error", resp.error);
            }

            // this often happens for slow typists so no alert.
            this.isInProcess = false; // allow retries, as when typing.
        };
    }
    if (!cfg.listeners.beforeLoad) {
        cfg.listeners.beforeLoad = function (thisStore, opts) {

            // avoid firing overlapping request, as with fast-fingered users
            if (thisStore.isInProcess) {
                return false;
            }
            thisStore.isInProcess = true;
            return true;
        };
    }
    AIR2.Search.JsonStore.superclass.constructor.call(this, cfg);
};

Ext.extend(AIR2.Search.JsonStore, Ext.data.JsonStore, {
    restful         : true,
    remoteSort      : true
});
