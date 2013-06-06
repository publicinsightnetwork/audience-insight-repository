Ext.ns('AIR2.UI');
/***************
 * AIR2 JsonDataView
 *
 * Dataview that auto-configures itself with an Ext.data.JsonStore
 *
 * @class AIR2.UI.JsonDataView
 * @extends AIR2.UI.DataView
 * @xtype air2jsdv
 * @cfg {Ext.Template} tpl
 *   Template to render in the dataview
 * @cfg {String} itemSelector
 *   A css selector to use with the tpl
 * @cfg {Object/Array} data
 *   Initial json data to load tpl store with, rather than an Ajax load
 * @cfg {String} url
 *   Restful url for the store tpl to use
 * @cfg {Boolean} nonapistore
 *   True to use a store that isn't an AIR2.UI.APIStore
 *
 */
AIR2.UI.JsonDataView = function (config) {
    var prop,
        storeCfg;
    // delete undefined properties
    for (prop in config) {
        if (!Ext.isDefined(config[prop])) {
            delete config[prop];
        }
    }

    // make sure the url ends in ".json"
    if (config.url && config.url.search(/\.json$/) < 0) {
        config.url += '.json';
    }

    // create the json store
    storeCfg = {
        autoSave: false,
        autoDestroy: true,
        restful: true,
        remoteSort: true
    };
    if (config.url && !Ext.isDefined(config.data)) {
        storeCfg.autoLoad = true;
    }
    else {
        storeCfg.autoLoad = false;
    }

    Ext.apply(storeCfg, config);
    if (!storeCfg.listeners) {
        storeCfg.listeners = {};
    }
    if (Ext.isEmpty(storeCfg.data)) {
        delete storeCfg.data; //ignore null data
    }

    if (config.nonapistore) {
        config.store = new Ext.data.JsonStore(storeCfg);
    }
    else if (!config.store) {
        config.store = new AIR2.UI.APIStore(storeCfg);
    }

    this.store = config.store;

    // remove "data" from config (it was used by store, if it existed)
    delete config.data;

    // if tpl wasn't provided, setup a blank dataview
    if (!config.tpl) {
        config.tpl = new Ext.Template('<div class="dataview-empty"></div>');
        config.itemSelector = '.dataview-empty';
        config.style = 'display:none';
    }

    // call parent constructor
    AIR2.UI.JsonDataView.superclass.constructor.call(this, config);
};
Ext.extend(AIR2.UI.JsonDataView, AIR2.UI.DataView, {
    emptyText: '<div class="air2-panel-empty"><h3>(none)</h3></div>',
    deferEmptyText: false,
    trackOver: true,
    renderEmpty: false,
    refresh: function () {
        var el,
            records;

        if (this.renderEmpty) {
            this.clearSelections(false, true);
            el = this.getTemplateTarget();
            el.update("");
            records = this.store.getRange();
            this.tpl.overwrite(el, this.collectData(records, 0));
            this.all.fill(Ext.query(this.itemSelector, el.dom));
            this.updateIndexes(0);

            //call custom event from AIR2.UI.DataView
            this.fireEvent('afterrefresh', this);
        }
        else {
            AIR2.UI.JsonDataView.superclass.refresh.call(this);
        }
    }
});
Ext.reg('air2jsdv', AIR2.UI.JsonDataView);
