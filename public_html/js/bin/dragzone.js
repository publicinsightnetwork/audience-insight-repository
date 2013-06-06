/***************
 * Bin Page - Bin-contents Custom Dragzone
 */
AIR2.Bin.DragZone = function (el, dv) {
    new AIR2.Drawer.DragZone(el, {
        getDragData: function (e) {
            var btnEl, c, ddObj, hdlEl, isAll;

            hdlEl = e.getTarget('.checkbox-handle');
            btnEl = e.getTarget('.air2-icon-drag');

            // return false to disable D&D
            if (!(hdlEl || (btnEl && !e.getTarget('.x-item-disabled')))) {
                return false;
            }

            // get more specific on the buttons
            if (btnEl) {
                btnEl = e.getTarget('.air2-btn');
                isAll = Ext.fly(btnEl).hasClass('drag-all');
            }

            // build D&D object
            ddObj = {
                repairXY: Ext.fly(hdlEl ? hdlEl : btnEl).getXY(),
                ddBinType: 'S',
                selections: {bin_uuid: AIR2.Bin.UUID}
            };

            // proxy element
            if (hdlEl) {
                ddObj.ddel = dv.getSelectionCount() + ' Sources';
            }
            else {
                c = 'air2-btn air2-btn-upload air2-btn-medium x-btn-text-icon';
                ddObj.ddel = '<div class="' + c + '">' +
                    btnEl.innerHTML + '</div>';
            }

            // include-only selections
            if (hdlEl || !isAll) {
                ddObj.selections.selections = function () {
                    var recs, selections;
                    selections = [];
                    recs = dv.getSelectedRecords();
                    Ext.each(recs, function (item) {
                        selections.push(item.data.src_uuid);
                    });
                    return selections;
                };
            }
            else {
                if (dv.store.baseParams.filter) {
                    ddObj.selections.filter = dv.store.baseParams.filter;
                }
            }
            return ddObj;
        }
    });
};
