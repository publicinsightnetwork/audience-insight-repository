Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer API
 *
 * Static API functions for adding, removing, and modifying AIR2 Bins and
 * related data.
 *
 * @function AIR2.Drawer.API.addItems
 * @param {Ext.data.Record} rec
 *   The bin record to add items to.
 * @param {Object/Array/Function/String} items
 *   To add a search, pass an Object of the form {q:, i:, total:}. To add basic
 *   items, pass in an Array of UUID strings, or a single UUID string. To add
 *   related items, pass in an Array of Objects of the form {uuid:, reltype:}.
 *   You may also pass in a function that returns Objects {type:, uuid:}.
 * @param {Function} callback
 *   A function to call after the AJAX call completes. Must accept the
 *   parameters (radix, success).
 *
 * @function AIR2.Drawer.API.removeItems
 * @param {Ext.data.Record} rec
 * @param {Object/Array/Function/String} items
 * @param {Function} callback
 *
 * @function AIR2.Drawer.API.merge
 * @param {Ext.data.Record} rec
 * @param {Array} mergeRecs
 *   Array of Bin Ext.data.Records, whose contents will be merged into rec.
 * @param {Function} callback
 *
 * @function AIR2.Drawer.API.random
 * @param {Ext.data.Record} rec
 * @param {Integer} numToCreate
 * @param {Integer} sizeOfEach
 * @param {Function} callback
 *
 */
AIR2.Drawer.API = (function () {
    var binAjax, binUpdFn, formatItemsFn;

    binAjax = function (uuid, params, callbackFn, scope) {
        if (!callbackFn) {
            callbackFn = function () {}; //empty function
        }
        Ext.Ajax.request({
            method: 'PUT',
            url: AIR2.HOMEURL + '/bin/' + uuid + '.json',
            params: {radix: Ext.util.JSON.encode(params)},
            scope: scope || this,
            callback: function (opts, success, resp) {
                var bulk, counts, data;

                if (success) {
                    data = Ext.util.JSON.decode(resp.responseText);
                    if (data.meta && data.meta.bulk_rs) {
                        bulk = data.meta.bulk_rs;
                    }
                    else {
                        bulk = {};
                    }
                    counts = {
                        insert: bulk.insert,
                        duplicate: bulk.duplicate,
                        invalid: bulk.invalid
                    };
                    callbackFn(data.radix, data.success, counts);
                }
                else {
                    callbackFn('server error!', false);
                }
            }
        });
    };
    binUpdFn = function (data, success, counts, rec, callback) {
        var date;

        if (success) {
            // explicitly modify data to avoid store events
            rec.data.src_count = data.src_count;
            date = Date.parseDate(data.bin_upd_dtim, "Y-m-d H:i:s");
            rec.data.bin_upd_dtim = date;
        }
        if (callback) {
            callback(data, success, counts);
        }
        else {
            Logger('no callback in binUpdFn:', data, success, counts, rec);
        }
    };
    formatItemsFn = function (input) {
        var result;

        // robustly interrogate "input" and format it correctly
        if (Ext.isFunction(input)) {
            return formatItemsFn(input());
        }
        if (!Ext.isArray(input)) {
            return formatItemsFn([input]);
        }

        // return uuids and type (to indicate subm-vs-source)
        result = {type: 'source', uuids: []};
        Ext.each(input, function (item) {
            if (Ext.isString(item)) {
                result.uuids.push(item);
            }
            else {
                result.uuids.push(item.uuid ? item.uuid : item.id);
                if (item.reltype) {
                    result.type = 'submission';
                }
            }
        });
        return result;
    };

    return {
        addItems: function (rec, items, callback, notes) {
            var data, myParams, search, bin_type;

            myParams = {};
            if (Ext.isObject(items)) {
                if (items.i) {
                    search = {q: items.q, i: items.i, total: items.total};
                    if (items.M) {
                        search.M = items.M;
                    }
                    myParams.bulk_addsearch = search;
                }
                else if (items.tank_uuid) {
                    myParams.bulk_addtank = items.tank_uuid;
                }
                else if (items.bin_uuid) {
                    if (items.selections) {
                        myParams.bulk_add = items.selections();
                    }
                    else {
                        myParams.bulk_addbin = items.bin_uuid;
                    }
                }
            }
            else {
                // setup in the format the server expects
                data = formatItemsFn(items);
                bin_type = rec.data.bin_type;

                if (data.type === 'submission') {
                    myParams.bulk_addsub = data.uuids;
                }
                else {
                    myParams.bulk_add = data.uuids;
                }
            }

            // optional added notes
            if (notes && notes.length > 0) {
                myParams.bulk_add_notes = notes;
            }

            // execute, with a callback hook to update src_count/last_use
            binAjax(rec.get('bin_uuid'), myParams,
                binUpdFn.createDelegate(this, [rec, callback], true));
        },
        removeItems: function (rec, items, callback) {
            var data, myParams;

            // setup in the format the server expects
            data     = formatItemsFn(items);
            myParams = {bulk_remove: data.uuids};
            binAjax(rec.get('bin_uuid'), myParams, callback);
        },
        merge: function (rec, mergeRecs, callback) {
            var i, mergeUUIDs, myParams;

            // get the UUIDs from the merge bins
            mergeUUIDs = [];
            for (i = 0; i < mergeRecs.length; i++) {
                mergeUUIDs.push(mergeRecs[i].get('bin_uuid'));
            }
            myParams = {bulk_addbin: mergeUUIDs};
            binAjax(rec.get('bin_uuid'), myParams, callback);
        },
        random: function (rec, numToCreate, sizeOfEach, callback) {
            var myParams, randParams;

            if (numToCreate && numToCreate > 0) {
                randParams = {num: numToCreate};
            }
            else {
                randParams = {num: 1};
            }

            if (sizeOfEach) {
                randParams.size = sizeOfEach;
            }

            myParams = {bulk_random: randParams};
            binAjax(rec.get('bin_uuid'), myParams, callback);
        },
        tag: function (rec, tag, callback) {
            var binuuid, myParams;

            binuuid = Ext.isString(rec) ? rec : rec.get('bin_uuid');
            myParams = {bulk_tag: tag};
            binAjax(binuuid, myParams, callback);
        },
        annotate: function (rec, annotation, callback) {
            var binuuid, myParams;

            binuuid = Ext.isString(rec) ? rec : rec.get('bin_uuid');
            myParams = {bulk_annot: annotation};
            binAjax(binuuid, myParams, callback);
        }
    };
}());
