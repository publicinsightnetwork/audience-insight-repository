Ext.ns('AIR2.UI');
/***************
 * AIR2 APIStore
 *
 * Json-store configured to work with AIR2 api
 *
 * @class AIR2.UI.APIStore
 * @extends Ext.data.Store
 * @xtype air2apistore
 */
AIR2.UI.APIStore = Ext.extend(Ext.data.Store, {
    restful: true,
    autoSave: false,
    constructor: function (config) {
        // If the caller doesn't want to load a URI at the beginning, we need
        // to alter the url, so that a proxy still gets created.
        if (!config.url && config.autoLoad === false) {
            config.url = AIR2.Util.URI.INVALID_URI;
        }

        AIR2.UI.APIStore.superclass.constructor.call(this, Ext.apply(config, {
            reader: new AIR2.UI.APIReader(config),
            writer: new AIR2.UI.APIWriter({encode: true, writeAllFields: false})
        }));

        // add a listener for API exceptions
        this.on('exception', this.handleAIRException, this);

        // be smart about including record ID's in update/destroy URL's
        if (this.proxy) {
            this.proxy.buildUrl = function (action, record) {
                var apiurl,
                    m,
                    re;

                if (this.api && (action === 'update' || action === 'destroy')) {
                    apiurl = this.api[action].url;

                    // make sure api doesn't include id twice
                    re = new RegExp(
                        '(/' + record.id + ')(\\.json|\\.xml|\\.html)$'
                    );
                    m = apiurl.match(re);

                    // remove the id from the api url
                    if (m) {
                        this.api[action].url = apiurl.replace(re, m[2]);
                    }
                }
                return Ext.data.HttpProxy.superclass.buildUrl.call(
                    this,
                    action,
                    record
                );
            };
        }
    },
    // reject changes and throw some sort of error message
    handleAIRException: function (proxy, type, action, opt, rsp, arg) {
        var json, msg, title;

        this.rejectChanges();

        // don't alert cancelled read requests on page change
        if (
            action === 'read' &&
            rsp.status === 0 &&
            rsp.statusText === 'communication failure'
        ) {
            return;
        }

        // show the error
        title = rsp.status + ' - ' + rsp.statusText;
        msg = 'An unknown error has occured';
        json = Ext.decode(rsp.responseText);
        if (json) {
            msg = json.message;
        }
        AIR2.UI.ErrorMsg(null, title, msg);
    },
    // handle sort/paging data ourselves (ALL remotely applied)
    onMetaChange: function (meta) {
        if (Ext.isDefined(meta.offset)) {
            this.setBaseParam('offset', meta.offset);
        }
        if (Ext.isDefined(meta.limit)) {
            this.setBaseParam('limit', meta.limit);
        }

        if (Ext.isDefined(meta.sort)) {
            this.mysort = meta.sort;

            // use the string version, if it exists
            if (meta.sortstr) {
                this.setBaseParam('sort', meta.sortstr);
            }
        }
        AIR2.UI.APIStore.superclass.onMetaChange.call(this, meta);
    },
    // combine any of the ol' single-sort-style params
    load: function (opt) {
        var comb, ret, si;

        si = this.sortInfo;
        if (this.sortInfo && this.remoteSort) {
            comb = this.sortInfo.field + ' ' + this.sortInfo.direction;

            if (!opt) {
                opt = {};
            }

            opt.params = opt.hasOwnProperty('params') ? opt.params : {};
            opt.params.sort = comb;

            this.sortInfo = false; //make superclass ignore
        }
        ret = AIR2.UI.APIStore.superclass.load.call(this, opt);
        this.sortInfo = si;
        return ret;
    },
    paramNames: {
        start: 'offset',
        limit: 'limit'
    },
    // avoid overlapping actions on this RESTful store
    remoteActions: {},
    execute: function (action, rs, o, b) {
        if (action === 'read') {
            return AIR2.UI.APIStore.superclass.execute.call(
                this,
                action,
                rs,
                o,
                b
            );
        }

        // unique write actions
        var actid = 'do' + action + rs.id;
        if (!this.remoteActions[actid]) {
            this.remoteActions[actid] = true;
            return AIR2.UI.APIStore.superclass.execute.call(
            this,
                action,
                rs,
                o,
                b
            );
        }
    },
    createCallback: function (action, rs, b) {
        var actid, acts, cbfn;

        if (action === 'read') {
            return AIR2.UI.APIStore.superclass.createCallback.call(
                this,
                action,
                rs,
                b
            );
        }

        actid = 'do' + action + rs.id;
        acts = this.remoteActions;
        cbfn = AIR2.UI.APIStore.superclass.createCallback.call(
            this,
            action,
            rs,
            b
        );
        return cbfn.createInterceptor(function () {
            delete acts[actid];
        });
    }
});
Ext.reg('air2apistore', AIR2.UI.APIStore);
