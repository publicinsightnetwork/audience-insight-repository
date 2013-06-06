/***************
 * Drag handling for the reader
 */
AIR2.Reader.dragHandler = function (dv) {

    // dom-involving stuff
    dv.on('afterrender', function (dv) {

        dv.dragZone = new AIR2.Drawer.DragZone(dv.el, {

            // setup drag proxy element/data
            getDragData: function (e) {
                var count, ddObj, handle, selectedRecs, uuids;

                handle = e.getTarget('.handle');

                if (!handle || dv.getSelectionCount() < 1) {
                    return false;
                }

                // get the count/uuid's
                uuids = [];

                if (dv.allSelected) {
                    count = dv.store.getTotalCount();
                    uuids = {
                        i: 'responses',
                        q: AIR2.Reader.ARGS.q,
                        M: AIR2.Reader.ARGS.M,
                        total: count
                    };
                }
                else {
                    selectedRecs = dv.getSelectedRecords();
                    Ext.each(selectedRecs, function (r) {
                        uuids.push({
                            uuid: r.data.srs_uuid,
                            type: 'S',
                            reltype: 'S'
                        });
                    });
                    count = selectedRecs.length;
                }

                // build d&d object
                ddObj = {
                    repairXY: Ext.fly(handle).getXY(),
                    ddBinType: 'S',
                    ddRelType: 'S',
                    selections: uuids,
                    ddel: Ext.util.Format.plural(count, 'submission')
                };
                return ddObj;
            }

        });

    });
};
