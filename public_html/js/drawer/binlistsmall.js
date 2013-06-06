Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer BinListSmall Component
 *
 * A dataview to display a small, fixed number of Bins without scrolling.
 *
 * @class AIR2.Drawer.BinListSmall
 * @extends AIR2.UI.DataView
 * @cfg {Object/Array} inlineData
 *   Data radix to load inline, rather than issuing an ajax call.
 * @cfg {Object} inlineParams
 *   Parameters to use with any loaded inlineData, usually {limit:5, self:1}.
 *
 */
AIR2.Drawer.BinListSmall = function (config) {
    var inlineLoad, myParams, storeCfg;

    if (!config) {
        config = {};
    }

    // setup the load params (can't change for the small list)
    myParams = config.inlineParams || {limit: 5, owner_flag: 1};
    inlineLoad = (config.inlineData) ? true : false;

    // if inline-loading, don't delay emptyText
    if (inlineLoad) {
        config.deferEmptyText = false;
    }

    // setup the store
    storeCfg = {
        url: AIR2.HOMEURL + '/bin.json',
        baseParams: myParams,
        listeners: {
            load: function (store, recs, opt) {
                AIR2.Drawer.STATE.setView('sm', myParams); //static
            }
        }
    };
    if (config.inlineData) {
        storeCfg.data = config.inlineData;
    }
    else {
        storeCfg.autoLoad = true;
    }
    config.store = new AIR2.UI.APIStore(storeCfg);

    // call parent constructor
    AIR2.Drawer.BinListSmall.superclass.constructor.call(this, config);
};

AIR2.Drawer.BinListSmall.template = new Ext.XTemplate(
    '<ul>' +
        '<tpl for=".">' +
            '<li class="air2-drawer-bin">' +
                '<h3 class="name air2-corners3 bin-expand" ' +
                '{[this.quickTip(values)]}>' +
                    '{bin_name:ellipsis(32)}' +
                '</h3>' +
                '<div>' +
                    '<span class="count">' +
                        '{[AIR2.Format.binCount(values)]}' +
                    '</span>' +
                    '<span class="last">' +
                        ' | {[AIR2.Format.binLastUse(values)]}' +
                    '</span>' +
                '</div>' +
            '</li>' +
        '</tpl>' +
    '</ul>',
    {
        compiled: true,
        quickTip: function (values) {
            if (values.bin_name.length > 29) {
                return 'ext:qtip="' +
                    values.bin_name + '" ext:qclass="lighter"';
            }
            else {
                return '';
            }
        }
    }
);
Ext.extend(AIR2.Drawer.BinListSmall, AIR2.UI.DataView, {
    width: 280,
    height: 250,
    autoScroll: false,
    cls: 'air2-binlist air2-binlist-small',
    emptyText: '<div class="air2-empty"><h3>No bins found</h3></div>',
    loadingText:
        '<div class="air2-empty">' +
            '<h3 class="air2-wait">Loading...</h3>' +
        '</div>',
    itemSelector: '.air2-drawer-bin',
    tpl: AIR2.Drawer.BinListSmall.template,
    reloadDataView: function () {
        this.fbar.changePage(0);
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
        addcounts.alignTo(target, 'br-br?', [0, -6]);

        // refresh and show add string
        this.refreshNode(this.indexOf(target));
        addcounts.fadeIn({duration: 0.1}).pause(1).fadeOut({remove: true});
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

        // transition
        if (oldview) {
            infoel.scale(
                this.width,
                0,
                {duration: 0.2}
            ).enableDisplayMode().hide();

            tbar.el.setWidth(
                this.width,
                {duration: 0.2}
            ).enableDisplayMode().hide();

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
            tbar.el.enableDisplayMode().hide().setWidth(this.width);
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
