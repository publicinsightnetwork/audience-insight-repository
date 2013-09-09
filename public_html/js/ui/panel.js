Ext.ns('AIR2.UI');
/***************
 * AIR2 Panel Component
 *
 * Panel styled to capture that sleek AIR2 look, and enable easy definitions
 * of dataviews, edit windows, and edit-in-place panels
 *
 * @class AIR2.UI.Panel
 * @extends Ext.Container
 * @xtype air2panel
 * @cfg {Integer} colspan
 * @cfg {Integer} rowspan
 * @cfg {String} title
 * @cfg {String} iconCls
 * @cfg {Boolean} noHeader (default false)
 * @cfg {Boolean} collapsible (default false)
 * @cfg {Boolean} collapsed (default false)
 * @cfg {Boolean} modalAdd (default false)
 * @cfg {Array} tools
 *   Defines the tools positioned in the upper-right of the panel. Accepts
 *   Ext.Toolbar items, including spacers ' ' and alignment '->'.
 * @cfg {Array/Ext.Toolbar} fbar
 *   Defines a toolbar at the bottom of the panel.
 * @cfg {Ext.Template} tpl
 *   Template to render to the body of the panel, as a DataView.
 * @cfg {String} itemSelector
 *   A css selector to use with the tpl
 * @cfg {Boolean} showTotal
 *   Show the total number of items in the tpl
 * @cfg {Boolean} showHidden
 *   Show the number of hidden (unauthz) items in the tpl
 * @cfg {Object/Array} storeData
 *   Initial data to load tpl store with, rather than an Ajax load
 * @cfg {String} url
 *   Restful url for the store tpl to use
 * @cfg {Boolean} allowEdit
 *   Pass 'false' to hide editInPlace button.  Defaults to true.
 * @cfg {Array} editInPlace
 *   Array of form items to configure an Ext.FormPanel for in-place editing
 * @cfg {Object} editInPlaceUsesModal (default false)
 *   Places inline editor in a modal view.
 * @cfg {Object} editModal
 *   Configuration options to create an Ext.UI.Window when panel is maximized
 * @cfg {Boolean} nonapistore
 *   True to use a store that isn't an AIR2.UI.APIStore
 * @event beforeedit(formpanel, records)
 * @event validate(formpanel)
 * @event beforesave(formpanel, records)
 * @event aftersave(formpanel, records)
 * @event afteredit(formpanel, records)
 *
 */
AIR2.UI.Panel = function (config) {
    var addTip,
        al,
        allowAdd,
        cpy,
        dataView,
        dvcfg,
        editClass,
        editTip,
        emCls,
        hide,
        htools,
        i,
        myCls;

    // combine classes, if any were passed in
    myCls = this.cls;
    if (config.cls) {
        myCls += ' ' + config.cls;
    }
    if (config.editModal) {
        emCls = myCls;
        if (config.editModal.cls) {
            emCls = emCls + ' ' + config.editModal.cls;
        }
        config.editModal.cls = emCls;
    }
    if (config.collapsed) {
        config.collapsible = true;
        myCls += ' ' + 'air2-panel-collapsed';
    }
    if (config.collapsible) {
        myCls += ' ' + 'air2-panel-collapsible';
    }
    config.cls = myCls;

    // create header tools
    htools = (config.tools) ? [].concat(config.tools) : [];
    if (config.editInPlace || config.editModal) {
        // search for the right-align in tools
        al = false;
        for (i = 0; i < htools.length; i++) {
            if (htools[i] == '->') {
                al = true;
            }
        }
        if (!al) {
            htools.push('->');
        }

        if (Ext.isString(config.modalAdd)) {
            addTip = config.modalAdd;
        }
        else {
            addTip = 'Add';
        }

        // push the "add modal item" button
        hide = config.editInPlace && (!config.allowEdit);
        if (config.editModal && config.modalAdd) {
            allowAdd = config.editModal.allowAdd;
            if (allowAdd && !hide) {
                htools.push(' ', {
                    xtype: 'air2button',
                    air2type: 'CLEAR',
                    iconCls: 'air2-icon-add',
                    tooltip: addTip,
                    handler: function () {
                        this.startEditModal(true);
                    },
                    scope: this
                });
            }
        }

        if (config.editInPlace) {
            editTip = 'Edit';
            editClass = 'air2-icon-edit';
        }
        else {
            editTip = 'Maximize';
            editClass = 'air2-icon-modal';
        }

        // push the edit/maximize tool
        htools.push(' ', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: editClass,
            tooltip: editTip,
            hidden: hide,
            handler: function () {
                if (this.editInPlace) {
                    this.startEditInPlace();
                }
                else if (this.editModal) {
                    this.startEditModal();
                }
            },
            scope: this
        });
    }

    // create header, unless we do not want one
    if (config.noHeader) {
        this.header = new Ext.BoxComponent({
            cls: 'air2-panel-header',
            hidden: true
        });
    }
    else {
        this.header = new Ext.BoxComponent({
            cls: 'air2-panel-header',
            html:
                '<table class="header-table">' +
                    '<tr>' +
                        '<td class="header-title ' +
                           (config.iconCls ? 'icon ' + config.iconCls : '') +
                            '">' +
                            (config.title ? config.title : ' ') +
                        '</td>' +
                        '<td class="header-total">' +
                            (config.total ? config.total : '') +
                        '</td>' +
                        '<td class="header-tools"> </td>' +
                    '</tr>' +
                '</table>',
            listeners: {
                afterrender: function (box) {
                    box.afterrendered = true;
                    this.ownerCt.tools = new Ext.Toolbar({
                        items: htools,
                        renderTo: box.el.child('.header-tools')
                    });

                    // click listener for collapsed header
                    if (config.collapsible) {
                        var pnl = box.ownerCt;
                        box.el.on('click', function (ev) {
                            if (!ev.getTarget('a')) {
                                if (pnl.collapsed) {
                                    pnl.body.el.slideIn(
                                        't',
                                        {useDisplay: true})
                                    ;
                                    pnl.collapsed = false;
                                    pnl.removeClass('air2-panel-collapsed');
                                }
                                else {
                                    pnl.body.el.slideOut(
                                        't',
                                        {useDisplay: true}
                                    );
                                    pnl.collapsed = true;
                                    pnl.addClass('air2-panel-collapsed');
                                }
                            }
                        });
                    }
                }
            },
            setTotal: function (total, unauthz_total) {
                var all,
                    hidden,
                    str;

                if (this.afterrendered) {
                    str = Ext.util.Format.number(total, '0,000') + ' Total';
                    all = this.ownerCt.showAllLink;
                    if (all) {
                        str = '<a href="' + all + '">' + str;
                        str += '&nbsp;&#187;</a>';
                    }

                    // show unauthz total
                    if (
                        Ext.isDefined(unauthz_total) &&
                        (config.showHidden !== false)
                    ) {
                        hidden = unauthz_total - total;
                        if (hidden > 0) {
                            hidden = Ext.util.Format.number(hidden, '0,000');
                            str += ' (' + hidden + ' hidden)';
                        }
                    }
                    this.el.child('.header-total').update(str);
                }
                else {
                    this.on(
                        'afterrender',
                        function () {
                            this.setTotal(total, unauthz_total);
                        },
                        this
                    );
                }
            },
            setCustomTotal: function (str) {
                if (this.afterrendered) {
                    this.el.child('.header-total').update(str);
                }
                else {
                    this.on(
                        'afterrender',
                        function () {
                            this.setCustomTotal(str);
                        },
                        this
                    );
                }
            }
        });
    }

    // create editform
    this.editform = new Ext.BoxComponent({cls: 'air2-panel-editform'});

    // create body
    this.body = new Ext.Container({cls: 'air2-panel-body'});
    if (config.html) {
        this.body.add({xtype: 'box', html: config.html});
        delete config.html;
    }
    if (config.tpl) {
        // default dataview config
        dvcfg = {
            cls: 'air2-panel-dataview',
            tpl: config.tpl,
            listeners: {
                load: function (store) {
                    if (config.showTotal) {
                        var total, unauthz;

                        total = store.getTotalCount();
                        unauthz = store.reader.jsonData.meta.unauthz_total;
                        if (Ext.isDefined(unauthz) && total !== unauthz) {
                            this.setTotal(total, unauthz);
                        }
                        else {
                            this.setTotal(total);
                        }
                    }
                    this.store = store; // cache reference to store

                    // Note that data has been loaded.
                    this.loaded = true;
                },
                scope: this
            }
        };

        // copy other config values
        cpy = 'nonapistore,url,storeData,baseParams,store,itemSelector,';
        cpy += 'emptyText,deferEmptyText,autoLoad,prepareData';
        Ext.copyTo(dvcfg, config, cpy);
        if (dvcfg.storeData) {
            dvcfg.data = dvcfg.storeData; //alias
        }
        dataView = new AIR2.UI.JsonDataView(dvcfg);
        this.body.add(dataView);

        delete config.url;
        delete config.tpl;
    }
    if (config.items) {
        this.body.add(config.items);
        delete config.items;
    }

    // create footer (optional)
    if (config.fbar) {
        if (config.fbar.isXType && config.fbar.isXType('toolbar')) {
            config.fbar.addClass('air2-panel-footer');
            this.footer = config.fbar;
        }
        else {
            this.footer = new Ext.Toolbar({
                cls: 'air2-panel-footer',
                items: config.fbar
            });
        }
    }

    // call parent constructor
    config.items = [this.header];

    if (! this.editInPlaceUsesModal) {
        config.items.push(this.editform);
    }

    config.items.push(this.body);

    if (this.footer) {
        config.items.push(this.footer);
    }
    AIR2.UI.Panel.superclass.constructor.call(this, config);

    // add custom events
    this.addEvents('beforeedit');
    this.addEvents('afteredit');
    this.addEvents('beforesave');
    this.addEvents('aftersave');
    this.addEvents('validate');
};
Ext.extend(AIR2.UI.Panel, Ext.Container, {
    cls: 'air2-panel',
    showTotal: true,

    // Should we abort an existing, unfinished request
    // when making a new request? Default: false.
    autoAbort: false,

    // Returns undefined if not found.
    getCurrentUrl: function () {
        var url;
        this.getBody().items.each(function (item) {
            if (
                item.store &&
                item.store.hasOwnProperty('url') &&
                item.store.url !== AIR2.Util.URI.INVALID_URI
            ) {
                url = item.store.url;
            }
        });

        return url;
    },
    startEditModal: function (startadd) {
        if (!this.loaded) {
            Ext.Msg.alert(
                'No Record',
                'There is no valid record currently loaded.'
            );
            return;
        }

        // If we haven't created an editModal yet, back up the config first.
        if (!this.editModal.show) {
            this.editModalConfig = this.editModal;
        }

        /*
         * Create editModal window. Note that this is dynamic; if the data in
         * the panel has been reload()ed, this will pick up the new URI.
         */
        if (!this.editModalConfig.iconCls) {
            this.editModalConfig.iconCls = this.iconCls;
        }
        if (!this.editModalConfig.title) {
            this.editModalConfig.title = this.title;
        }
        this.editModalConfig.url = this.getCurrentUrl();
        this.editModalConfig.items.url = this.getCurrentUrl();

        this.editModal = new AIR2.UI.Window(this.editModalConfig);

        // When hiding editModal, reload panel, so we pick up any changes.
        this.editModal.on('hide', function () {
            this.reload();
        }, this);

        // Should we start in 'add a new entry' mode?
        if (startadd) {
            this.editModal.show(this.el, function (win) {
                win.fireEvent('addclicked', win);
            });
        }
        else {
            this.editModal.show(this.el);
        }
    },
    startEditInPlace: function () {
        var body, panel, record;

        // if we're already editing, cancel the edit!
        if (this.isediting) {
            return this.endEditInPlace(false);
        }

        // create edit panel, if we haven't already
        if (!this.editInPlacePanel) {
            this.editInPlacePanel = new Ext.form.FormPanel({
                cls: 'air2-panel-editinplace air2-panel-body',
                items: this.editInPlace,
                unstyled: true,
                hidden: true,
                labelWidth: this.labelWidth ? this.labelWidth : 75,
                defaults: {style: {width: '96%'}},
                applyTo: this.getEditForm().el,
                bbar: [{
                    xtype: 'air2button',
                    air2type: 'SAVE',
                    air2size: 'MEDIUM',
                    text: 'Save',
                    scope: this,
                    handler: function () {this.endEditInPlace(true); }
                }, {
                    xtype: 'air2button',
                    air2type: 'CANCEL',
                    air2size: 'MEDIUM',
                    text: 'Cancel',
                    style: 'margin-left:4px',
                    scope: this,
                    handler: function () {this.endEditInPlace(false); }
                }]
            });
        }
        this.isediting = true;

        // get EVERY record in EVERY dataview
        body = this.getBody();
        record = [];
        body.items.each(function (item, index, length) {
            if (item.store) {
                if (item.store.getCount() === 0) {
                    item.store.add(new item.store.recordType());
                }
                record = record.concat(item.store.getRange());
            }
        });
        this.inPlaceRecs = record;

        // reset the panel
        panel = this.editInPlacePanel;
        panel.getForm().reset();
        if (record.length === 1) {
            panel.getForm().loadRecord(record[0]);
        }

        // fire beforeedit, and show the form (hiding the dataviews)
        if (this.fireEvent('beforeedit', panel, record)) {
            this.showEditInPlace(body, panel);
        }
    },
    showEditInPlace: function (body, editPanel) {
        var firstFld = editPanel.getForm().items.get(0);

        if (this.editInPlaceUsesModal) {
            editPanel.show();

            // very close to startEditModal
            if (!this.editModal || !this.editModal.show) {
                this.editModalConfig = this.editInPlaceUsesModal;

                if (!this.editModalConfig.iconCls) {
                    this.editModalConfig.iconCls = this.iconCls;
                }
                if (!this.editModalConfig.title) {
                    this.editModalConfig.title = this.title;
                }

                this.editModal = new AIR2.UI.Window(this.editModalConfig);

                this.editModal.add(this.getEditForm());

                this.editModal.on('hide', function () {
                    this.isediting = false;
                }, this);

            }

            editPanel.show();
            this.editModal.show(this.el);
        }
        else {
            body.hide();
            editPanel.show();
            editPanel.getForm().isValid();
        }

        // get the first REAL field in the form, and focus it
        if (firstFld.isXType('compositefield')) {
            firstFld = firstFld.items.get(0);
        }
        firstFld.focus(true); //focus first field
    },
    endEditInPlace: function (doSave) {
        var i, n, p, pan, r, reqs, saveCallback, stores;

        p = this.editInPlacePanel;
        r = this.inPlaceRecs;
        stores = [];
        if (doSave) {
            // default and custom form validation
            if (!p.getForm().isValid()) {
                return;
            }
            if (!this.fireEvent('validate', p)) {
                return;
            }

            // create a list of every distinct store
            for (i = 0; i < r.length; i++) {
                if (r[i].store && stores.indexOf(r[i].store) < 0) {
                    stores.push(r[i].store);
                }
            }

            // begin editing recs
            for (i = 0; i < r.length; i++) {
                r[i].beginEdit();
            }

            // update record
            if (r.length === 1) {
                p.getForm().updateRecord(r[0]);
            }
            this.fireEvent('beforesave', p, r);

            // end editing record
            for (i = 0; i < r.length; i++) {
                r[i].endEdit();
            }

            // find any stores that were added during 'beforesave'
            for (i = 0; i < r.length; i++) {
                if (r[i].store && stores.indexOf(r[i].store) < 0) {
                    stores.push(r[i].store);
                }
            }

            // save any recs that have been modified
            reqs = [];
            pan = this;

            saveCallback = function (store, rs) {
                reqs.remove(rs);
                if (reqs.length < 1) {
                    if (pan.fireEvent('aftersave', p, r)) {
                        p.el.unmask();
                        pan.endEditInPlace(false);
                    }
                }
            };

            for (i = 0; i < stores.length; i++) {
                // set the callback
                stores[i].on('save', saveCallback, this, {single: true});

                // save, and record the save sid number
                n = stores[i].save();
                if (n > 0) {
                    reqs.push(n);
                }
            }

            // check if we fired any save events
            if (reqs.length > 0) {
                p.el.mask('Saving...');
                return; // avoid exiting until callback
            }
            else {
                this.endEditInPlace(false); // end edit NOW
            }
        }
        else {
            // process after-edit
            if (this.fireEvent('afteredit', p, r)) {
                this.isediting = false;

                if (this.editInPlaceUsesModal) {
                    p.hide();
                    this.editModal.hide();
                }
                else {
                    p.hide();
                    this.getBody().show();
                }
            }

            // prune cancelled new-recs
            Ext.each(r, function (rec) {
                if (rec.phantom && rec.store) {
                    rec.store.remove(rec);
                }
            });
        }
    },
    setTotal: function (total, unauthz_total) {
        if (!this.showTotal) {
            return; // don't display
        }
        this.airTotal = total;
        this.header.setTotal(total, unauthz_total);
    },
    setCustomTotal: function (str) {
        this.header.setCustomTotal(str);
    },
    reload: function (url_override, loadingMsg, completeCallback) {
        var doneLoadingFn,
            loadingFn,
            self,
            store;

        self = this;
        store = null;

        loadingFn = function () {
            self.loadingMask = new Ext.LoadMask(
                self.getEl(),
                {msg: loadingMsg, removeMask: true}
            );
            self.loadingMask.show();
        };
        doneLoadingFn = function () {
            self.loadingMask.hide();
            store.un('beforeload', loadingFn);
            store.un('load', doneLoadingFn);
        };

        this.getBody().items.each(function (item) {
            if (item.store) {
                // If the caller wants to abort old, unfinished requests
                // when making a new call, do that.
                if (self.autoAbort) {
                    item.store.proxy.destroy();
                }

                // Allow overriding URI.
                if (url_override) {
                    item.store.proxy.setUrl(
                        // New URI.
                        url_override,

                        // Make this new URI permanent
                        // -- otherwise various ajax calls will
                        // use the old URI.
                        true
                    );

                    item.store.url = url_override;
                }
                // Make sure the proxy has the current URI.
                else {
                    item.store.proxy.setUrl(
                        // New URI.
                        item.store.url,

                        // Make this new URI permanent
                        // -- otherwise various ajax calls will
                        // use the old URI.
                        true
                    );
                }

                // Display loading message if requested to.
                if (loadingMsg) {
                    Logger('weeeee!');
                    store = item.store;
                    store.on('beforeload', loadingFn);
                    store.on('load', doneLoadingFn);
                }

                if (completeCallback) {
                    var loadListener = function (store, records, options) {
                        item.store.removeListener('load', loadListener);

                        completeCallback(store, records, options);
                    };

                    item.store.addListener('load', loadListener);
                }

                item.store.reload();
            }
        });
    },

    // getters for the panel components
    getHeader: function () {
        return this.header;
    },
    getTools: function () {
        return this.tools;
    },
    getEditForm: function () {
        return this.editform;
    },
    getBody: function () {
        return this.body;
    },
    getDataView: function () {
        var dv = null;

        this.getBody().items.each(function (item) {
            if (item.isXType && item.isXType('dataview')) {
                dv = item;
            }
        });
        return dv;
    },
    getFooter: function () {
        return this.footer;
    }
});
Ext.reg('air2panel', AIR2.UI.Panel);
