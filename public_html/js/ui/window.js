Ext.ns('AIR2.UI.Window');
/***************
 * AIR2 Window Component
 *
 * An Ext.Window styled in the sleek manner of AIR2
 *
 * @class AIR2.UI.Window
 * @extends Ext.Window
 * @xtype air2window
 * @cfg {Boolean/String} allowAdd
 *   True to put an "add" button in the header of the window. Passing a string
 *   will set the text on that button.
 * @cfg {Boolean/String} allowNew
 *   True to put a "new" button in the header of the window. Passing a string
 *   will set the text on that button.
 * @cfg {Function} createNewFn
 *   Function that can create the "new" thing (DO NOT ACTUALLY CALL IT YET!)
 * @cfg {Object} createNewCfg
 *   Config options that will be passed to the createNewFn when called
 * @cfg {Array} tools
 *   Defines the tools positioned in the upper-right of the panel. Accepts
 *   Ext.Toolbar items, including spacers ' ' and alignment '->'.
 * @cfg {boolean} formAutoHeight
 *   Makes a modal form variable-height
 * @cfg {boolean} tabLayout
 *   Sets up as a tabbed-layout window
 *
 */
AIR2.UI.Window = function (cfg) {
    var addbtn,
        newbtn,
        tools;

    // setup "tools", using an Ext.Toolbar instead of the default handling of
    // Ext.Panel tools.
    tools = (cfg.tools) ? [].concat(cfg.tools) : [' '];
    delete cfg.tools; //prevent default handling of "tools"

    if (Ext.isFunction(cfg.allowNew)) {
        cfg.allowNew = cfg.allowNew();
    }

    if (cfg.allowNew) {
        newbtn = {
            xtype: 'air2button',
            air2type: 'NEW2',
            itemId: 'win-btn-new',
            iconCls: 'air2-icon-clipboard',
            text: Ext.isString(cfg.allowNew) ? cfg.allowNew : 'New',
            handler: function () {
                var bigwin, mknew, newclosed, ncfg;

                bigwin = this;
                bigwin.items.each(function (it) {
                    // find the cleanup plugin
                    if (it.plugins && it.plugins.length) {
                        Ext.each(it.plugins, function (p) {
                            if (p.cleanup) {
                                p.cleanup(it);
                            }
                        });
                    }
                });

                newclosed = function (why) {
                    mknew.un('close', newclosed);
                    if (why === 'save') {
                        bigwin.items.each(function (it) {
                            if (it.pager) {
                                it.pager.changePage(0);
                            }
                            else if (it.store) {
                                it.store.reload();
                            }
                        });
                        mknew.animateTo(
                            bigwin,
                            function () {
                                mknew.destroy();
                            }
                        );
                    }
                    else if (why === 'cancel') {
                        mknew.animateTo(
                            bigwin,
                            function () {
                                mknew.destroy();
                            }
                        );
                    }
                    else {
                        bigwin.hide(false); //close
                    }
                };

                // configure make-new window
                ncfg = cfg.createNewCfg ? cfg.createNewCfg : {};
                Ext.apply(ncfg, {
                    modal: false,
                    originEl: false,
                    callback: function (success, data) {
                        if (success) {
                            newclosed('save');
                        }
                    }
                });
                mknew = this.createNewFn(ncfg);
                mknew.show();

                // override cancel/close functionality
                mknew.cancelbtn.handler = function () {newclosed('cancel'); };
                mknew.on('close', newclosed);

                // create a "transition" element
                this.animateTo(mknew);
            },
            scope: this
        };
        tools = ['->', newbtn].concat(tools);
    }
    if (cfg.allowAdd) {
        if (Ext.isFunction(cfg.allowAdd)) {
            cfg.allowAdd = cfg.allowAdd();
        }
        addbtn = {
            xtype: 'air2button',
            air2type: 'NEW2',
            itemId: 'win-btn-add',
            iconCls: 'air2-icon-add-small',
            text: Ext.isString(cfg.allowAdd) ? cfg.allowAdd : 'New',
            handler: function () {this.fireEvent('addclicked', this); },
            scope: this
        };
        tools = ['->', addbtn].concat(tools); //addbtn goes first
    }

    // don't create the header text element ... we'll do it ourselves
    cfg.headerAsText = false;

    // call parent constructor
    AIR2.UI.Window.superclass.constructor.call(this, cfg);

    if (cfg.tabLayout) {
        this.addClass('tabbed-modal');
    }

    this.on('render', function (w) {
        var el, icon, w1, w2;

        icon = (w.iconCls) ? (w.iconCls + ' icon') : '';
        w.header.addClass('air2-panel-header');
        el = w.header.createChild({
            tag: 'table',
            cls: 'header-table',
            html:
                '<tr>' +
                    '<td class="header-title ' + icon + '">' +
                         cfg.title +
                    '</td>' +
                    '<td class="header-total"></td>' +
                    '<td class="header-tools"></td>' +
                '</tr>'
        });
        if (tools.length > 0) {
            this.tools = new Ext.Toolbar({
                items: tools,
                renderTo: w.header.child('.header-tools')
            });
        }

        if (cfg.tabLayout) {
            w1 = el.child('.header-title').getWidth();
            w2 = el.child('.header-total').getWidth();
            w.get(0).on('render', function (tabpanel) {
                var tabct = tabpanel.el.child('.x-tab-strip');
                tabct.setStyle('padding-left', (w1 + w2 + 10) + 'px');
            });
        }
    });

    // fix autoheight
    if (this.formAutoHeight === true) {
        this.addClass('air2-auto-height');
    }

    // event for add button clicked
    this.addEvents('addclicked');

    this.on('beforeshow', function (win) {
        win.center();
    });
};
Ext.extend(AIR2.UI.Window, Ext.Window, {
    baseCls: 'air2-editwin',
    modal: true,
    draggable: false,
    resizable: false,
    shadow: false,
    closeAction: 'hide', // important -- don't destroy on close
    width: 820,
    height: 440,
    buttonAlign: 'left',
    layout: 'fit',
    showTotal: true,
    setTotal: function (total) {
        if (this.showTotal) {
            if (!this.totalEl) {
                this.totalEl = this.header.child('.header-total');
            }
            this.totalEl.update(total + ' Total');
        }
    },
    setCustomTotal: function (str) {
        if (!this.totalEl) {
            this.totalEl = this.header.child('.header-total');
        }
        this.totalEl.update(str);
    },
    animateTo: function (win, callbk) {
        var animFn, bodyheight, twin;

        twin = new AIR2.UI.Window({
            title: this.title,
            iconCls: this.iconCls,
            width: this.getWidth(),
            height: this.getHeight(),
            x: this.el.getX(),
            y: this.el.getY(),
            // static content
            cls: 'win-transition',
            modal: false
        });
        twin.show();
        this.el.setStyle('visibility', 'hidden');

        // animate
        animFn = function () {
            win.el.setStyle('visibility', 'visible');
            twin.destroy();
            if (callbk) {
                callbk();
            }
        };
        twin.el.animate({
            left:   {to: win.el.getX(), unit: 'px'},
            top:    {to: win.el.getY(), unit: 'px'},
            width:  {to: win.getWidth(), unit: 'px'}
        }, 0.3, animFn);
        bodyheight = win.body.getHeight();
        if (win.footer) {
            bodyheight += win.footer.getHeight();
        }
        twin.body.animate({height: {to: bodyheight, unit: 'px'}}, 0.3);
    }
});
Ext.reg('air2window', AIR2.UI.Window);
