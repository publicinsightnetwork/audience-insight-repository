Ext.ns('AIR2.UI');
/***************
 * AIR2 PagingEditor Component
 *
 * A DataView with a paging footer, optionally allowing line-editing.
 *
 * @class AIR2.UI.PagingEditor
 * @extends AIR2.UI.JsonDataView
 * @xtype air2pagingeditor
 *
 * @cfg {String}  url
 * @cfg {String}  sort
 * @cfg {Integer} pageSize
 * @cfg {Boolean} hidePager
 *   true to not display a pager; defaults to false
 * @cfg {Object}  baseParams
 * @cfg {Ext.Template} tpl
 *   Template to render the body with
 * @cfg {Array} plugins
 *   To use editing, you must pass a plugin.  For example, you can pass
 *   "plugins: [AIR2.UI.PagingEditor.InlineControls]" to use the inline edit
 *   controls plugin.
 * @cfg {Boolean|Function} allowEdit   (default: false)
 * @cfg {Boolean|Function} allowDelete (default: false)
 * @cfg {Function} editRow
 *   When a row is edited, this function is passed (dv, node, rec).  It then
 *   must render whatever fields it needs into the node.  Should return an
 *   array of all fields used.  (Passed to saveRow later).
 * @cfg {Function} saveRow
 *   When a row is saved, this function is passed (rec, edits), where edits is
 *   the array of fields that was returned from editRow().  This function then
 *   must update the record somehow, using those fields.
 *
 */
AIR2.UI.PagingEditor = function (cfg) {
    var inlineData,
        txt;

    cfg.baseParams = cfg.baseParams ? cfg.baseParams : {};

    // limit and sort
    cfg.baseParams.limit = cfg.pageSize ? cfg.pageSize : this.pageSize;
    if (cfg.multiSort) {
        cfg.baseParams.sort = cfg.multiSort;
        delete cfg.multiSort;
        delete cfg.sort;
    }
    else if (cfg.sort) {
        cfg.baseParams.sort = cfg.sort;
        delete cfg.sort;
    }

    // combine classes
    cfg.cls = cfg.cls ? cfg.cls + ' ' + this.cls : this.cls;

    // paging footerbar
    this.pager = new Ext.PagingToolbar({
        cls: 'air2-paging-editor-pager',
        displayInfo: true,
        pageSize: cfg.baseParams.limit,
        prependButtons: true
    });

    // bind to owner
    cfg.listeners = cfg.listeners ? cfg.listeners : {};
    cfg.listeners.added = function (cmp, ownerCt) {
        if (ownerCt.isXType('window')) {
            cmp.deferEmptyText = true;
        }
        cmp.bindOwner(ownerCt);
    };

    // determine what emptyText will be from the tpl
    txt = cfg.tpl.apply([]);
    txt += cfg.emptyText ? cfg.emptyText : this.emptyText;
    cfg.emptyText = txt;

    // call parent constructor
    inlineData = (cfg.data) ? true : false;
    AIR2.UI.PagingEditor.superclass.constructor.call(this, cfg);
    this.pager.bindStore(this.store);

    // load listener
    this.store.on('load', function () {
        if (this.el) {
            this.el.addClass('unlocked');
        }
        this.rowAlts();
        this.setTotal();
    }, this);

    // render listener for loading inline-data (no store load call)
    if (inlineData) {
        this.on('afterrender', function () {
            this.rowAlts();
            this.setTotal();
        }, this, {single: true});
    }
};
Ext.extend(AIR2.UI.PagingEditor, AIR2.UI.JsonDataView, {
    cls: 'air2-paging-editor unlocked',
    pageSize: 40, //default
    hidePager: false, //default
    overClass: 'row-over',
    newRowDef: {},
    // bind pager to parent container
    bindOwner: function (ownerCt) {
        // adding --- check for plugin "makeNew"
        ownerCt.on('addclicked', function () {
            Ext.each(this.plugins, function (item) {
                if (item.makeNew) {
                    item.makeNew(this);
                }
            }, this);
        }, this);

        // hiding --- refire the event so plugin can catch
        ownerCt.on('beforehide', function () {
            this.fireEvent('beforehide');
        }, this);

        // load listener
        this.store.on('load', this.setTotal, this);
        if (this.rendered) {
            this.setTotal();
        }

        // handle those funky air2panel parents
        if (!this.hidePager) {
            if (ownerCt.cls && ownerCt.cls.match(/air2-panel-body/)) {
                var pager = this.pager;
                pager.addClass('air2-panel-footer');
                if (ownerCt.ownerCt) {
                    ownerCt.ownerCt.add(pager);
                }
                else {
                    ownerCt.on('added', function (cmp, own) {
                        own.add(pager);
                    });
                }
            }
            else if (ownerCt.rendered) {
                // TODO: render after-the-fact?
                alert('TODO: container already rendered');
            }
            else {
                ownerCt.bbar = this.pager; //unrendered
            }
        }
    },
    // render row-alternate classes
    rowAlts: function () {
        var i, nodes;

        nodes = this.getNodes();
        for (i = 0; i < nodes.length; i++) {
            if (i % 2 !== 0) {
                Ext.fly(nodes[i]).addClass('row-alternate');
            }
            else {
                Ext.fly(nodes[i]).removeClass('row-alternate');
            }
        }
    },
    // generic "masking" of dataview
    mask: function (msg) {
        if (this.ownerCt && this.ownerCt.body) {
            this.ownerCt.body.mask(msg);
        }
        else {
            this.el.mask(msg);
        }
    },
    // generic "unmasking" of dataview
    unmask: function () {
        if (this.ownerCt && this.ownerCt.body) {
            this.ownerCt.body.unmask();
        }
        else {
            this.el.unmask();
        }
    },
    // generic set total
    setTotal: function () {
        var c, u;

        c = this.store.getTotalCount();
        u = this.store.reader.jsonData.meta.unauthz_total;
        if (this.ownerCt && this.ownerCt.setTotal) {
            this.ownerCt.setTotal(c, u);
        }
        if (
            this.ownerCt &&
            this.ownerCt.ownerCt &&
            this.ownerCt.ownerCt.setTotal
        ) {
            this.ownerCt.ownerCt.setTotal(c, u);
        }
    }
});
Ext.reg('air2pagingeditor', AIR2.UI.PagingEditor);
