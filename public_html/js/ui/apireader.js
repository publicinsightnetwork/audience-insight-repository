Ext.ns('AIR2.UI');
/***************
 * AIR2 APIReader
 *
 * Json DataReader configured to work with AIR2 api
 *
 * @class AIR2.UI.APIReader
 * @extends Ext.data.JsonReader
 * @xtype air2APIReader
 */
AIR2.UI.APIReader = Ext.extend(Ext.data.JsonReader, {
    // intercept to record metadata
    readRecords: function (o) {
        // handle inline-data read errors
        if (!o.success) {
            Logger("ERROR: invalid inline-data --> ", o.message);
        }

        // define our own meta-reader
        if (o.meta) {
            this.onMetaChange(o.meta);
        }

        // handle API changes
        if (o.api) {
            this.onApiChange(o.api);
        }
        return AIR2.UI.APIReader.superclass.readRecords.call(this, o);
    },
    // override to translate AIR-api to Ext-ish
    onMetaChange: function (meta) {
        var extflds,
            i,
            ident,
            name;

        this.meta = meta;
        this.meta.totalProperty = 'total';
        this.meta.successProperty = 'success';
        this.meta.messageProperty = 'message';
        this.meta.idProperty = meta.identifier;
        this.meta.root = 'radix';

        // define record fields
        extflds = this.transformFields(meta.fields);
        this.recordType = Ext.data.Record.create(extflds);

        // meta accessors
        this.getRoot = function (rsp) {
            return rsp.radix;
        };
        this.getTotal = function (rsp) {
            if (Ext.isDefined(rsp.meta.total)) {
                return rsp.meta.total;
            }
            if (Ext.isDefined(rsp.total)) {
                return rsp.total;
            }
            // no total: assume it's a single record
            return 1;
        };
        this.getSuccess = function (rsp) {
            return rsp.success;
        };
        this.getMessage = function (rsp) {
            return rsp.message;
        };
        ident = meta.identifier;
        this.getId = function (rec) {
            return rec[ident];
        };

        // field accessors
        this.ef = [];
        for (i = 0; i < extflds.length; i++) {
            name = extflds[i].name;
            this.ef.push(this.createAccessor(name));
        }
    },
    // change AIR field def to Ext-array
    transformFields: function (flds) {
        var extflds,
            isArray;

        extflds = [];
        isArray = Ext.isArray(flds);
        Ext.iterate(flds, function (key, val) {
            // flip basic arrays
            val = isArray ? key : val;
            key = isArray ? 0 : key;
            if (Ext.isNumber(key) || Ext.isNumber(parseInt(key, 10))) {
                var def = {name: val};
                if (val.match(/_dtim$/) || val.match(/dtim$/)) {
                    def.type = 'date';
                    def.dateFormat = 'Y-m-d H:i:s';
                }
                if (val.match(/_date$/)) {
                    def.type = 'date';
                    def.dateFormat = 'Y-m-d';
                }
                if (val.match(/_id$/)) {
                    def.type = 'int';
                }
                if (val.match(/_seq$/)) {
                    def.type = 'int';
                }
                if (val.match(/_flag$/)) {
                    def.type = 'boolean';
                }
                // TODO: these several STUPID FIELDS break our naming schema
                if (val === 'srs_date') {
                    def.dateFormat = 'Y-m-d H:i:s';
                }
                if (val === 'inq_rss_status') {
                    def.type = 'string';
                }
                extflds.push(def);
            }
            else if (Ext.isString(key)) {
                extflds.push({name: key, type: 'object'});
            }
            else {
                Logger("UNKNOWN FIELD IN META", key, val);
            }
        });
        return extflds;
    },
    // record metadata about the api
    onApiChange: function (api) {
        this.meta.validSorts = [];
        if (Ext.isDefined(api.sorts)) {
            this.meta.validSorts = api.sorts;
        }

        this.meta.insertFields = [];
        if (api.methods.create && api.methods.create.length) {
            this.meta.insertFields = api.methods.create;
        }

        this.meta.updateFields = [];
        if (api.methods.update && api.methods.update.length) {
            this.meta.updateFields = api.methods.update;
        }
    }
});
Ext.reg('air2apireader', AIR2.UI.APIReader);
