Ext.ns('AIR2.UI');
/***************
 * AIR2 PagingPanel Component
 *
 * AIR2 Panel that uses a dataview, but with a paging toolbar at the bottom.  A
 * 'tpl' must be provided in the configuration
 *
 * @class AIR2.UI.PagingPanel
 * @extends AIR2.UI.Panel
 * @xtype air2pagingpanel
 * @cfg {Integer} pageSize (default 20)
 *
 */
AIR2.UI.PagingPanel = function (cfg) {
    var body,
        dv;

    this.pager = new Ext.PagingToolbar({
        displayInfo: true,
        pageSize: (cfg.pageSize) ? cfg.pageSize : 20,
        prependButtons: true
    });
    cfg.fbar = this.pager;

    // call parent constructor
    AIR2.UI.PagingPanel.superclass.constructor.call(this, cfg);

    // make sure limit is used in the first request
    this.store.setBaseParam('limit', this.pageSize);

    // bind the pager to the dataview store
    this.pager.bindStore(this.store);

    // fix the height of the dataview on the initial load, so that it doesn't
    // shrink if you load a smaller page in the future
    body = this.getBody();
    dv = this.getBody().get(0);
    dv.on(
        'afterrender',
        function () {
            var h = dv.el.getHeight();
            dv.el.setStyle('min-height', h + 'px');
        },
        this,
        {single: true}
    );

};
Ext.extend(AIR2.UI.PagingPanel, AIR2.UI.Panel, {
    /**
     * Go to the next page.
     *
     * Hacky, but it seems our build of ExtJS (as of 2012-01-04) doesn't
     * include support for programmatic page navigation.
     */
    nextPage: function () {
        Ext.get(this.el).query('.x-tbar-page-next')[0].click();
    },

    /**
     * Go to the previous page.
     *
     * Hacky, but it seems our build of ExtJS (as of 2012-01-04) doesn't
     * include support for programmatic page navigation.
     */
    previousPage: function () {
        Ext.get(this.el).query('.x-tbar-page-prev')[0].click();
    }
});
Ext.reg('air2pagingpanel', AIR2.UI.PagingPanel);
