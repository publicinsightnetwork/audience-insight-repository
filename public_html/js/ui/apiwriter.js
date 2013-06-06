Ext.ns('AIR2.UI');
/***************
 * AIR2 APIWriter
 *
 * Json DataWriter configured to work with AIR2 api
 *
 * @class AIR2.UI.APIWriter
 * @extends Ext.data.JsonWriter
 * @xtype air2apiwriter
 */
AIR2.UI.APIWriter = Ext.extend(Ext.data.JsonWriter, {
    toHash: function (rec, config) {
        var checkFlds,
            count,
            data,
            f,
            i,
            old;

        data = AIR2.UI.APIWriter.superclass.toHash.call(this, rec, config);

        // make sure we're only writing WRITE-able fields
        if (rec.phantom) {
            checkFlds = this.meta.insertFields;
        }
        else {
            checkFlds = this.meta.updateFields;
        }

        if (checkFlds) {
            old = data;
            data = {};
            count = 0;
            for (i = 0; i < checkFlds.length; i++) {
                f = checkFlds[i];
                if (Ext.isDefined(old[f])) {
                    data[f] = old[f];
                    count++;
                }
            }

            // did we write ANYTHING?
            if (count < 1) {
                Logger("No fields to write!", old, checkFlds, data);
            }
        }
        return data;
    }
});
Ext.reg('air2apiwriter', AIR2.UI.APIWriter);
