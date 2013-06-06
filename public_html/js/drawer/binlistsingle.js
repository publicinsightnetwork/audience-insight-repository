Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer BinListSingle Component
 *
 * A dataview for displaying the contents of a single Bin. Also allows editing
 * Bin metadata.
 *
 * @class AIR2.Drawer.BinListSingle
 * @extends AIR2.UI.DataView
 * @cfg {Object/Array} inlineData
 *   Data radix to load inline, rather than issuing an ajax call.
 * @cfg {Object} inlineParams
 *   Parameters to use with any loaded inlineData, usually {limit:5, self:1}.
 * @cfg {Object} inlineBin
 *   The Bin to load inline (inlineData contains Bin-contents)
 * @cfg {Ext.data.Record} binRec
 *   If not loading inline, you must provide the record for the Bin to view.
 * @cfg {HTMLElement} infoEl
 *   The element above the drawer header, into which this view will render Bin
 *   metadata and editing components.
 *
 */
AIR2.Drawer.BinListSingle = function (config) {
    var flds, self, sorts, template;

    if (!config) {
        config = {};
    }
    self = this;

    template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="air2-drawer-bin">' +
                '<div class="top">' +
                    '<span class="title">' +
                        '<a class="air2-binlink" href="' +
                        AIR2.HOMEURL +
                        '/bin/{bin_uuid}">' +
                            '{bin_name} &raquo;' +
                        '</a>' +
                    '</span>' +
                    '<span class="buttons"></span>' +
                '</div>' +
                '<div class="about air2-corners3">' +
                    '<div class="meta">' +
                        'Created by ' +
                        '{[AIR2.Format.userName(values.User, true)]} ' +
                        'on {[AIR2.Format.date(values.bin_cre_dtim)]}' +
                        '{[this.formatShared(values)]}' +
                    '</div>' +
                    '<div class="desc">' +
                        '{[this.formatDesc(values.bin_desc)]}' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            formatDesc: function (desc) {
                if (desc && desc.length > 0) {
                    return desc;
                }
                else {
                    return '<i>(No Description Given)</i>';
                }
            },
            formatShared: function (values) {
                if (values.bin_shared_flag) {
                    return (
                        '<span class="air2-corners3 sharing public">' +
                            'Shared' +
                        '</span>'
                    );
                }
                else {
                    return (
                        '<span class="air2-corners3 sharing">' +
                            'Not Shared' +
                        '</span>'
                    );
                }
            }
        }
    );

    // create the bin info header
    this.infoEl = config.infoEl;
    this.infoBar = new AIR2.UI.DataView({
        cls: 'air2-bin-infobar',
        width: config.infoWidth,
        renderTo: config.infoEl,
        itemSelector: '.air2-drawer-bin',
        tpl: template,
        refresh: function () {
            AIR2.UI.DataView.superclass.refresh.call(this);
            this.showButtons();
        },
        onUpdate: function (ds, record) {
            AIR2.UI.DataView.superclass.onUpdate.call(this, ds, record);
            this.showButtons();
        },
        showButtons: function () {
            var btns, r;

            r = (this.store.getCount() === 1) ? this.store.getAt(0) : null;
            if (r && r.data.owner_flag) {
                btns = this.el.child('.buttons', true);
                new AIR2.UI.Button({
                    air2type: 'DRAWER',
                    iconCls: 'air2-icon-editzone',
                    text: 'Edit',
                    renderTo: btns,
                    handler: function () {
                        self.startEdit();
                    },
                    scope: self
                });
                new AIR2.UI.Button({
                    air2type: 'DRAWER',
                    iconCls: 'air2-icon-delete',
                    text: 'Delete',
                    renderTo: btns,
                    handler: function () {
                        self.deleteBin();
                    },
                    scope: self
                });
            }
        }
    });
    this.infoBar.dv = this;

    // make sure drawer closes when we go to a bin page
    this.infoBar.el.on('click', function (ev) {
        if (ev.getTarget('a.air2-binlink')) {
            AIR2.Drawer.STATE.set('open', false);
            AIR2.Drawer.STATE.setView('sm');
        }
    });

    // check for a valid bin record
    if (config.binRec) {
        this.bindBin(config.binRec);
    }
    else if (config.inlineBin) {
        //skip infobar animation ONCE
        this.skipAnimation = true;
        this.hasSkippedEmptyText = true;
        this.bindBin(config.inlineBin, config.inlineData, config.inlineParams);
    }
    else {
        AIR2.UI.ErrorMsg(null, 'Error', 'Invalid single bin specified');
        return;
    }
    delete config.binRec;
    delete config.inlineBin;

    this.showInfo();

    // call parent constructor
    AIR2.Drawer.BinListSingle.superclass.constructor.call(this, config);

    // sort listeners
    sorts = ['th.name', 'th.email', 'th.location'];
    flds = ['src_last_name', 'primary_email', 'primary_addr_city'];
    this.el.on('click', function (ev) {
        var el, i;

        for (i = 0; i < sorts.length; i++) {
            el = ev.getTarget(sorts[i], 3, true);
            if (el) {
                if (el.hasClass('desc')) {
                    el.radioClass(['desc', 'asc']);
                    el.removeClass('desc');
                    this.store.baseParams.sort = flds[i] + ' ' + 'desc';
                }
                else {
                    el.radioClass(['desc', 'asc']);
                    el.removeClass('asc');
                    this.store.baseParams.sort = flds[i] + ' ' + 'asc';
                }
                this.reloadDataView();
            }
        }
    }, this);
};

Ext.extend(AIR2.Drawer.BinListSingle, AIR2.UI.DataView, {
    width: 530,
    binHeight: 24,
    autoScroll: false,
    cls: 'air2-binlist air2-binlist-single air2-drawer-bin',
    emptyText: '<div class="air2-empty"><h3>No Sources</h3></div>',
    loadingText:
        '<div class="air2-empty">' +
            '<h3 class="air2-wait">Loading...</h3>' +
        '</div>',
    selectedClass: 'row-selected',
    overClass: 'row-over',
    itemSelector: '.item-row',
    multiSelect: true,
    setTemplateType: function (type) {
        if (type === 'S' || type === 'U') {
            this.tpl = new Ext.XTemplate(
                '<table class="source-item">' +
                    '<tr class="header">' +
                        '<th class="index"> </th>' +
                        '<th class="name {[this.sortName()]}">' +
                            '<span>Name</span>' +
                        '</th>' +
                        '<th class="email {[this.sortEmail()]}">' +
                            '<span>Email</span>' +
                        '</th>' +
                        '<th class="location {[this.sortLocation()]}">' +
                            '<span>Location</span>' +
                        '</th>' +
                    '</tr>' +
                    '<tpl for=".">' +
                        '<tr class="item-row">' +
                            '<td class="index">' +
                                '{[this.formatIndex(xindex)]}.' +
                            '</td>' +
                            '<td class="name">' +
                                '{[AIR2.Format.sourceName(values,1,0,28)]}' +
                            '</td>' +
                            '<td class="email">' +
                                '{[this.formatEmail(values)]}' +
                            '</td>' +
                            '<td class="location">' +
                                '{[this.formatLocation(values)]}' +
                            '</td>' +
                            //'<tpl for="BinRelated">' +
                            //  '{[this.printRelated(values)]}' +
                            //'</tpl>' +
                        '</tr>' +
                    '</tpl>' +
                '</table>',
                {
                    compiled: true,
                    disableFormats: true,
                    formatIndex: function (num) {
                        var startAt = 0;
                        if (this.dv.store.lastOptions &&
                            this.dv.store.lastOptions.params &&
                            this.dv.store.lastOptions.params.offset) {

                            startAt = this.dv.store.lastOptions.params.offset;
                        }
                        else if (this.dv.store.baseParams &&
                                 this.dv.store.baseParams.offset) {
                            startAt = this.dv.store.baseParams.offset;
                        }
                        return startAt + num;
                    },
                    formatLocation: function (src) {
                        var c, n, s, str, z;

                        str = '';
                        c = src.primary_addr_city;
                        s = src.primary_addr_state;
                        z = src.primary_addr_zip;
                        n = src.primary_addr_cntry;

                        if (c && s) {
                            str += c + ', ' + s;
                        }
                        else if (s) {
                            str += s;
                        }
                        else if (z) {
                            str += z;
                        }
                        else if (n) {
                            str += n;
                        }
                        return str;
                    },
                    formatEmail: function (src) {
                        var abbr, eml, str;

                        str = '';
                        if (src.primary_email) {
                            eml = src.primary_email;
                            abbr = Ext.util.Format.ellipsis(eml, 25);
                            str += AIR2.Format.createLink(
                                        abbr,
                                        'mailto:' + eml,
                                        true,
                                        true
                                    );
                        }
                        return str;
                    },
                    getSort: function (fld) {
                        var reAsc, reDesc, s;

                        s = this.dv.store.baseParams.sort;
                        if (s && s.length) {
                            s = s.split(',', 1).pop();
                            reAsc  = new RegExp(fld + ' desc', 'i');
                            reDesc = new RegExp(fld + ' asc', 'i');
                            if (s.match(reAsc)) {
                                return 'asc';
                            }
                            else if (s.match(reDesc)) {
                                return 'desc';
                            }
                        }
                        return '';
                    },
                    sortName: function () {
                        return this.getSort('src_last_name');
                    },
                    sortEmail: function () {
                        return this.getSort('primary_email');
                    },
                    sortLocation: function () {
                        return this.getSort('primary_addr_city');
                    }
                }
            );
            this.tpl.dv = this;
        }
        else {

            this.tpl = new Ext.XTemplate(
                '<div><h3>' +
                    'No template defined for bin type="'+type+'"' +
                '</h3></div>',
                {
                    compiled: true,
                    disableFormats: true
                }
            );
        }
    },
    reloadDataView: function () {
        this.fbar.changePage(0);
    },
    bindBin: function (data, inlinedata, inlineparams) {
        var binstore, store, newUrl, uuid;

        // get loadable data from records
        if (data.store) {
            data = {
                success: true,
                radix:   data.data,
                meta:    data.store.reader.meta
            };
        }
        uuid = data.radix.bin_uuid;
        if (uuid === this.uuid) {
            return;
        }

        // create new store
        binstore = new AIR2.UI.APIStore({
            data: data,
            url: AIR2.HOMEURL + '/bin.json'
        });
        this.binRecord = binstore.getAt(0);
        this.uuid = binstore.getAt(0).id;
        this.infoBar.bindStore(binstore);

        // update the bin_source template
        if (this.binRecord.data.bin_type !== this.tplType) {
            this.tplType = this.binRecord.data.bin_type;
            this.setTemplateType(this.tplType);
        }

        // update the bin_source store
        if (!this.store) {
            store = new AIR2.UI.APIStore({
                url: AIR2.HOMEURL + '/bin/' + uuid + '/source.json',
                autoLoad: false, //always let pager load
                listeners: {
                    load: function (st, rcs, opt) {
                        if (opt && opt.params) {
                            AIR2.Drawer.STATE.setView(
                                'si',
                                opt.params,
                                this.uuid
                            );
                        }
                    },
                    scope: this
                }
            });

            if (inlinedata) {
                store.loadData(inlinedata);
            }
            if (inlineparams) {
                store.baseParams = inlineparams;
            }

            // bind store
            if (this.rendered) {
                this.bindStore(store);
            }
            else {
                this.store = store;
            }
        }
        else {
            // update the store url
            newUrl = AIR2.HOMEURL + '/bin/' + uuid + '/source.json';
            this.store.proxy.setUrl(newUrl, true);
        }
    },
    applyFilter: function (value, noMask) {
        this.store.setBaseParam('q', value);
        this.reloadDataView();
    },
    getBinRecord: function (target) {
        return this.binRecord;
    },
    refreshBin: function (target) {
        var fld;

        this.store.on('load', function () {
            this.el.unmask();
        }, this, {single: true});
        fld = Ext.getCmp('air2-drawer').tbar.get(1);
        fld.reset();
        this.applyFilter('', true);
    },
    maskBin: function (target) {
        this.el.mask('Adding');
    },
    unmaskBin: function (target) {
        this.el.unmask();
    },
    showInfo: function () {
        var b;

        this.infoBar.refresh();
        b = this.infoBar;
        if (this.skipAnimation) {
            this.skipAnimation = false;
            this.infoEl.setHeight(b.el.getComputedHeight());
            b.el.show();
        }
        else {
            this.infoEl.setHeight(
                b.el.getComputedHeight(),
                {
                    duration: 0.2,
                    callback: function () {
                        b.el.fadeIn();
                    }
                }
            );
        }
    },
    startEdit: function () {
        var b, el, f, r;

        if (!this.editForm) {
            this.editForm = new Ext.form.FormPanel({
                cls: 'air2-bin-edit',
                renderTo: this.infoEl,
                style: 'display:none',
                unstyled: true,
                labelWidth: 75,
                items: [
                    {
                        xtype: 'air2remotetext',
                        fieldLabel: 'Bin Name',
                        name: 'bin_name',
                        width: '96%',
                        allowBlank: false,
                        remoteTable: 'bin',
                        autoCreate: {
                            tag: 'input',
                            type: 'text',
                            maxlength: '128'
                        },
                        maxLength: 128
                    },
                    {
                        xtype: 'textarea',
                        fieldLabel: 'Description',
                        name: 'bin_desc',
                        width: '96%',
                        maxLength: 256
                    },
                    {
                        xtype: 'air2combo',
                        fieldLabel: 'Shared',
                        name: 'bin_shared_flag',
                        choices: [[false, 'No'], [true, 'Yes']],
                        width: 100
                    }
                ],
                bbar: [
                    '->',
                    {
                        xtype: 'air2button',
                        air2type: 'SAVE',
                        air2size: 'MEDIUM',
                        text: 'Save',
                        scope: this,
                        handler: function () {this.endEdit(true); }
                    },
                    '   ',
                    {
                        xtype: 'air2button',
                        air2type: 'CANCEL',
                        air2size: 'MEDIUM',
                        text: 'Cancel',
                        scope: this,
                        handler: function () {this.endEdit(false); }
                    }
                ]
            });
        }

        f = this.editForm;
        r = this.binRecord;
        b = this.infoBar;
        el = this.infoEl;

        f.get(0).originalValue = r.get('bin_name');
        f.getForm().loadRecord(r);
        f.el.unmask();
        f.el.show({duration: 0.2});
        b.el.slideOut('t', {duration: 0.2, useDisplay: true});
        el.setHeight(f.el.getComputedHeight(), {duration: 0.2});
    },
    endEdit: function (save) {
        var b, el, f, r, s, sid;

        f = this.editForm;
        r = this.binRecord;
        b = this.infoBar;
        el = this.infoEl;
        s = r.store;

        if (save) {
            if (!f.getForm().isValid()) {
                return;
            }
            f.getForm().updateRecord(r);

            sid = s.save();
            if (sid !== -1) {
                f.el.mask('Saving');
                s.on(
                    'save',
                    function () {
                        this.endEdit(false);
                    },
                    this,
                    {
                        single: true
                    }
                );
                return;
            }
        }

        // hide editor
        b.el.slideIn('t', {duration: 0.3});
        f.el.hide({duration: 0.2});
        el.setHeight(b.el.getComputedHeight(), {duration: 0.2});
    },
    deleteBin: function () {
        var el, rec;

        if (!this.deleteConfirm) {
            rec = this.binRecord;
            el = this.infoBar.el.createChild({
                cls: 'delete-confirm air2-corners3',
                html: 'Really delete?<br/>' +
                    '<a class="yes">Delete</a>' +
                    '<a class="no">Cancel</a>'
            });
            el.on('click', function (ev) {
                if (ev.getTarget('a.yes')) {
                    el.fadeOut({remove: true, callback: function () {
                        var s = rec.store;
                        s.remove(rec);
                        s.save();
                        s.on(
                            'save',
                            function () {
                                Ext.getCmp('air2-drawer').transitionView('lg');
                            },
                            this,
                            {
                                single: true
                            }
                        );
                    }});
                }
                else if (ev.getTarget('a.no')) {
                    el.slideOut('t', {duration: 0.2, remove: true});
                }
            }, this);
            el.alignTo(this.infoBar.el.child('.buttons', true), 't-b');
            el.slideIn('t', {duration: 0.2});
        }
    },
    changeTo: function (viewel, infoel, tbar, fbar, oldview, binRec) {
        this.fbar = fbar;
        if (oldview) {
            oldview.el.fadeOut({duration: 0.1, useDisplay: true});
        }

        // get the number of elements we'll display (add 1 for headers)
        this.height = this.binHeight * (fbar.pageSize + 1);

        // transition
        if (oldview) {
            infoel.show().setWidth(this.width, {duration: 0.2});
            tbar.el.show().setWidth(this.width, {duration: 0.2});
            fbar.el.show().setWidth(this.width, {duration: 0.2});
            viewel.scale(this.width, this.height, {
                duration: 0.2,
                scope: this,
                callback: function () {
                    this.el.fadeIn({duration: 0.1, useDisplay: true});
                }
            });

            // change bin contents
            this.hasSkippedEmptyText = false;
            this.bindBin(binRec);
            this.refreshBin();
            this.showInfo();
        }
        else {
            infoel.setWidth(this.width);
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
