Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer BinListLarge Component
 *
 * A dataview to display an unlimited number of Bins, using scrolling. Also
 * provides mechanisms for searching/sorting/filtering the list of Bins.
 *
 * @class AIR2.Drawer.BinListLarge
 * @extends AIR2.UI.DataView
 * @cfg {Object/Array} inlineData
 *   Data radix to load inline, rather than issuing an ajax call.
 * @cfg {Object} inlineParams
 *   Parameters to use with any loaded inlineData.
 *
 */
AIR2.Drawer.BinListLarge = function (config) {
    var storeCfg;

    if (!config) {
        config = {};
    }

    // create store to interact with the Bin-URL
    storeCfg = {
        url: AIR2.HOMEURL + '/bin.json',
        listeners: {
            load: function (store, recs, opt) {
                if (opt.params) {
                    AIR2.Drawer.STATE.setView('lg', opt.params);
                }
                else {
                    AIR2.Drawer.STATE.setView('lg', config.inlineParams);
                }
            }
        }
    };

    // params differ based on inline-loading
    if (config.inlineData) {
        storeCfg.data = config.inlineData;
        storeCfg.baseParams = config.inlineParams;
    }
    else {
        storeCfg.baseParams = {
            sort: AIR2.Drawer.Config.SORTFIELDS.lg[0].fld + ' desc'
        };
    }
    this.store = new AIR2.UI.APIStore(storeCfg);

    // call parent constructor
    AIR2.Drawer.BinListLarge.superclass.constructor.call(this, config);

};

AIR2.Drawer.BinListLarge.template = new Ext.XTemplate(
    '<tpl for=".">' +
        '<div class="air2-drawer-bin">' +
            '<h3 class="name air2-corners3 bin-expand" ' +
                '{[this.quickTip(values)]}>' +
                '{bin_name:ellipsis(40)}' +
            '</h3>' +
            '<div>' +
                '<span class="count">' +
                    '{[AIR2.Format.binCount(values)]}' +
                '</span>' +
                '<span class="last">' +
                    ' | {[AIR2.Format.binLastUse(values)]} | ' +
                '</span>' +
                '<span class="owner">' +
                    '{[AIR2.Format.userName(values.User, true)]}' +
                '</span>' +
            '</div>' +
        '</div>' +
    '</tpl>',
    {
        compiled: true,
        quickTip: function (values) {
            if (values.bin_name.length > 51) {
                return 'ext:qtip="' + values.bin_name +
                    '" ext:qclass="lighter"';
            }
            else {
                return '';
            }
        }
    }
);

Ext.extend(AIR2.Drawer.BinListLarge, AIR2.UI.DataView, {
    width: 404,
    binHeight: 47,
    autoScroll: false,
    cls: 'air2-binlist air2-binlist-large',
    emptyText: '<div class="air2-empty"><h3>No bins found</h3></div>',
    loadingText:
        '<div class="air2-empty">' +
            '<h3 class="air2-wait">Loading...</h3>' +
        '</div>',
    itemSelector: '.air2-drawer-bin',
    selectedClass: 'row-selected',
    overClass: 'row-over',
    multiSelect: true,
    tpl: AIR2.Drawer.BinListLarge.template,
    applyFilter: function (value) {
        this.store.setBaseParam('q', value);
        this.reloadDataView();
    },
    getBinRecord: function (target) {
        return this.getRecord(target);
    },
    refreshBin: function (target, counts) {
        var addcounts, c, str;

        // create new element
        str = '';
        c = counts;
        if (c.insert) {
            str += '<div>+' + c.insert + ' added</div>';
        }
        if (c.duplicate) {
            str += '<div>+' + c.duplicate + ' duplicate';
            str += (c.duplicate > 1) ? 's</div>' : '</div>';
        }
        if (c.invalid) {
            str += '<div>+' + c.invalid + ' INVALID</div>';
        }
        addcounts = this.el.createChild({cls: 'add-counts', html: str});

        // align
        addcounts.alignTo(target, 'br-br?', [-6, -6]);

        // refresh and show add string
        this.refreshNode(this.indexOf(target));
        addcounts.fadeIn({duration: 0.1}).pause(1).fadeOut({remove: true});
    },
    reloadDataView: function () {
        this.fbar.changePage(0);
    },
    maskBin: function (target) {
        Ext.fly(target).mask('Adding');
    },
    unmaskBin: function (target) {
        Ext.fly(target).unmask();
    },
    changeTo: function (viewel, infoel, tbar, fbar, oldview) {
        this.fbar = fbar;
        if (oldview) {
            oldview.el.fadeOut({duration: 0.1, useDisplay: true});
        }

        // get the number of elements we'll display
        this.height = this.binHeight * fbar.pageSize;

        // transition
        if (oldview) {
            infoel.scale(
                this.width,
                0,
                {duration: 0.2}
            ).enableDisplayMode().hide();

            tbar.el.show().setWidth(this.width, {duration: 0.2});
            fbar.el.show().setWidth(this.width, {duration: 0.2});
            viewel.scale(this.width, this.height, {
                duration: 0.2,
                scope: this,
                callback: function () {
                    this.el.fadeIn({duration: 0.1, useDisplay: true});
                }
            });
            this.reloadDataView();
        }
        else {
            infoel.enableDisplayMode().hide().setWidth(this.width);
            tbar.el.setWidth(this.width);
            fbar.el.setWidth(this.width);
            viewel.setSize(this.width, this.height);
            this.el.show();
        }
    },
    // customize loading mask
    onBeforeLoad: function () {
        this.clearSelections(false, true);
        this.getTemplateTarget().update(this.loadingText);
        this.all.clear();
    }
});
