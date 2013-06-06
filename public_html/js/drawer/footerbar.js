Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer Footerbar Component
 *
 * An Ext.Toolbar for use as the bottom toolbar of an AIR2 drawer.
 *
 * @class AIR2.Drawer.Footerbar
 * @extends Ext.PagingToolbar
 * @xtype air2drawerfbar
 * @cfg {Function} startNewFn
 *   Function that toolbar should call to create a new Bin.
 * @cfg {Function} endNewFn
 *   Function that toolbar should call when done creating a new Bin
 *
 */
AIR2.Drawer.Footerbar = function (config) {
    config = config || {};
    config.items = [
        {
            xtype: 'air2button',
            air2type: 'NEW',
            air2size: 'MEDIUM',
            text: '<strong>+</strong> New Bin',
            cls: 'air2-drawer-create',
            handler: function () {
                config.startNewFn();
            }
        },
        {
            xtype: 'air2button',
            air2type: 'SAVE',
            air2size: 'MEDIUM',
            text: 'Save',
            handler: function () {
                config.endNewFn(true);
            },
            hidden: true
        },
        {
            xtype: 'air2button',
            air2type: 'CANCEL',
            air2size: 'MEDIUM',
            text: 'Cancel',
            handler: function () {
                config.endNewFn(false);
            },
            hidden: true
        }
    ];

    // call parent constructor
    AIR2.Drawer.Footerbar.superclass.constructor.call(this, config);
};
Ext.extend(AIR2.Drawer.Footerbar, Ext.PagingToolbar, {
    cls: 'air2-bin-fbar x-toolbar',
    displayInfo: true,
    displayMsg: '{0} - {1} of {2}',
    nextText: false,
    prevText: false,
    refreshText: false,
    viewButtons: {
        sm: [5, 6, 7, 8],
        lg: [0, 1, 2, 3, 4, 5, 6, 7, 8],
        si: [0, 1, 2, 3, 4, 5, 6],
        nw: [9, 10]
    },
    pageSize: 9,
    setNewMode: function (newMode) {
        // show/hide buttons
        var showbtns = this.viewButtons.nw;
        this.items.each(function (itm, idx) {
            itm.setVisible(showbtns.indexOf(idx) > -1);
        });
    },
    setView: function (vwStr, vwObj, inline) {
        this.cursor = 0;
        if (inline && inline.inlineParams && inline.inlineParams.start) {
            this.cursor = inline.inlineParams.start; //inline cursor position
        }
        this.calculatePageSize(vwStr, vwObj, inline);
        this.bindStore(vwObj.store);

        // show/hide buttons
        var showbtns = this.viewButtons[vwStr];
        this.items.each(function (itm, idx) {
            itm.setVisible(showbtns.indexOf(idx) > -1);
        });
    },
    // calculate the pagesize based on which view we're looking at
    calculatePageSize: function (view, vwObj, inline) {
        var availh, rowh;

        // check for pre-set inline limit
        if (inline && inline.inlineParams && inline.inlineParams.limit) {
            this.pageSize = inline.inlineParams.limit;
            return;
        }

        if (view === 'sm') {
            this.pageSize = 5;
        }
        if (view === 'lg') {
            availh = Ext.getBody().getViewSize().height * 0.65;
            rowh = vwObj.binHeight;
            this.pageSize = Math.floor(availh / rowh);
        }
        if (view === 'si') {
            availh = Ext.getBody().getViewSize().height * 0.7 - 100;
            rowh = vwObj.binHeight;
            this.pageSize = Math.floor(availh / rowh);
        }
    },
    // custom init for custom pager
    initComponent: function () {
        // paging items
        this.prev = new Ext.Button({
            tooltip: this.prevText,
            overflowText: this.prevText,
            iconCls: 'x-tbar-page-prev',
            disabled: true,
            handler: this.movePrevious,
            scope: this
        });
        this.displayItem = new Ext.Toolbar.TextItem();
        this.next = new Ext.Button({
            tooltip: this.nextText,
            overflowText: this.nextText,
            iconCls: 'x-tbar-page-next',
            disabled: true,
            handler: this.moveNext,
            scope: this
        });
        this.refresh = new Ext.Button({
            tooltip: this.refreshText,
            overflowText: this.refreshText,
            iconCls: 'x-tbar-loading',
            handler: this.doRefresh,
            scope: this
        });

        // support article - TODO: kill inline style
        this.helpLink = new Ext.BoxComponent({
            html: AIR2.Util.Tipper.create({id: 20978266, cls: 'lighter'})
        });

        // prepend to existing items
        var pgItems = [this.prev, '-', this.displayItem, '-', this.next,
            this.refresh, this.helpLink, '->'];
        this.items = pgItems.concat(this.items);

        // not used!
        this.afterTextItem = new Ext.Toolbar.TextItem();
        this.inputItem = new Ext.form.NumberField();
        this.first = new Ext.form.TextField();
        this.last = new Ext.form.TextField();

        Ext.PagingToolbar.superclass.initComponent.call(this);
        this.addEvents('change', 'beforechange');
        this.on('afterlayout', this.onFirstLayout, this, {single: true});
        this.cursor = 0;
        this.bindStore(this.store, true);
    }
});
Ext.reg('air2drawerfbar', AIR2.Drawer.Footerbar);
