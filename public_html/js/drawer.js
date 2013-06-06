Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer Component
 *
 * Component to dock in the lower-right hand corner of the screen, sliding open
 * to allow items to be dragged into Bins.
 *
 * @class AIR2.Drawer
 * @extends Ext.Component
 *
 */
AIR2.Drawer = function () {
    var currView, drwr, initOpen, inlineBin, inlineData, inlineParams;

    // get drawer STATE parameters (if any)
    currView = AIR2.Drawer.STATE.get('view');
    if (!currView) {
        currView = 'sm'; //'sm', 'lg', 'si'
    }
    initOpen = AIR2.Drawer.STATE.get('open') || false;
    inlineParams = AIR2.Drawer.STATE.get('params');
    inlineData = AIR2.BINDATA;
    inlineBin = AIR2.BINBASE;

    // call component constructor
    AIR2.Drawer.superclass.constructor.call(this, {});

    // set initial drawer state
    this.dBody = this.el.child('.body');
    if (initOpen) {
        this.dBody.setStyle('margin-bottom', '0px');
        this.el.removeClass('collapsed');
        this.el.addClass('expanded');
    }

    // render/setup drawer controls
    this.controls = new Ext.Toolbar({
        defaults: {
            xtype: 'air2button',
            air2type: 'CLEAR',
            scope: this
        },
        items: [
            '->',
            {
                iconCls: 'air2-icon-bin-dock',
                handler: this.slideShut
            },
            {
                enableToggle: true,
                allowDepress: false,
                toggleGroup: 'air2-drawer-controls',
                iconCls: 'air2-icon-bin-small',
                pressed: currView === 'sm',
                toggleHandler: function (btn, state) {
                    if (state) {
                        this.transitionView('sm');
                    }
                }
            },
            {
                enableToggle: true,
                allowDepress: false,
                toggleGroup: 'air2-drawer-controls',
                iconCls: 'air2-icon-bin-large',
                pressed: currView === 'lg',
                toggleHandler: function (btn, state) {
                    if (state) {
                        this.transitionView('lg');
                    }
                }
            }
        ],
        renderTo: this.el.child('.controls', true),
        clearBtns: function () {
            this.get(2).toggle(false);
            this.get(3).toggle(false);
        }
    });
    this.dTab = this.el.child('.tab');
    this.dTab.on('click', function (e) {
        if (e.getTarget('.tab')) {
            this.isTmpOpen = false; //not a temp opening/shutting
            if (this.el.hasClass('collapsed')) {
                this.slideOpen();
            }
            else if (e.getTarget('.title')) {
                this.slideShut();
            }
        }
    }, this);

    // other elements
    this.dView = this.dBody.child('.view');
    this.dInfo = this.el.child('.info');

    // initialize toolbars
    this.tbar = new AIR2.Drawer.Toolbar({
        inlineParams: inlineParams,
        applyTo: this.dBody.child('.tbar'),
        startNewFn: this.createNew.createDelegate(this),
        deleteFn: this.deleteBin.createDelegate(this)
    });
    this.fbar = new AIR2.Drawer.Footerbar({
        applyTo: this.dBody.child('.fbar'),
        startNewFn: this.createNew.createDelegate(this),
        endNewFn: this.endNew.createDelegate(this)
    });

    // load the initial view
    this.views = {};
    this.transitionView(currView, null, {
        inlineParams: inlineParams,
        inlineData: inlineData,
        inlineBin: inlineBin
    });

    // event listeners
    this.dView.on('click', function (e) {
        var el, rec;
        if (e.getTarget('.bin-expand')) {
            // get the bin record from the current view
            el = e.getTarget(this.views[this.currView].itemSelector);
            rec = this.views[this.currView].getRecord(el);
            this.lastvw = this.currView;
            this.transitionView('si', rec);
        }
    }, this);

    // setup content dropzone
    drwr = this;
    this.dropZone = new Ext.dd.DropZone(this.dBody, {
        ddGroup: 'air2-drawer-ddzone',
        getTargetFromEvent: function (event) {
            var t = event.getTarget('.air2-drawer-bin');
            this.createMode = false;
            if (!t) {
                t = event.getTarget('.air2-drawer-create');
                if (t) {
                    this.createMode = true;
                }
            }
            return t;
        },
        onNodeEnter: function (target, dd, e, data) {
            Ext.fly(target).addClass('hover');
            if (this.createMode) {
                this.hRec = null;
                this.hType = '?';
            }
            else {
                this.hRec = drwr.views[drwr.currView].getBinRecord(target);
                if (this.hRec.get('owner_flag')) {
                    this.hType = this.hRec.get('bin_type');
                }
                else {
                    this.hType = null;
                }
            }
        },
        onNodeOut: function (target, dd, e, data) {
            Ext.fly(target).removeClass('hover');
        },
        onNodeOver: function (target, dd, e, data) {
            if (this.hType === '?' || data.ddBinType === this.hType) {
                return Ext.dd.DropZone.prototype.dropAllowed;
            }
            else {
                return Ext.dd.DropZone.prototype.dropNotAllowed;
            }
        },
        onNodeDrop: function (target, dd, e, data) {
            var addNotes, callback, notebox, r, s, skipNotes;

            if (this.hType !== '?' && data.ddBinType !== this.hType) {
                return false; // invalid drop
            }
            else if (!data.selections) {
                Logger("Error: no selection provided!");
                return false;
            }

            // determine if this drop will trigger a new bin
            if (this.createMode) {
                drwr.createNew(data.ddBinType, data.selections);
            }
            else {
                r = this.hRec;
                s = data.selections;

                callback = function (data, success, counts) {
                    if (success) {
                        drwr.views[drwr.currView].refreshBin(target, counts);
                    }
                    else {
                        AIR2.UI.ErrorMsg(
                            target,
                            'Server Error',
                            'A server error occured!<br/>Unable to add sources',
                            function () {
                                drwr.views[drwr.currView].unmaskBin(target);
                            }
                        );
                    }
                };

                // prompt for notes
                if (r.data.bin_status === 'P') {
                    addNotes = function () {
                        var text = notebox.get(1).getValue();
                        AIR2.Drawer.LASTNOTES = text;
                        drwr.views[drwr.currView].maskBin(target);
                        if (text && text.length > 0) {
                            AIR2.Drawer.API.addItems(r, s, callback, text);
                        }
                        else {
                            AIR2.Drawer.API.addItems(r, s, callback);
                        }
                        notebox.close();
                    };
                    skipNotes = function () {
                        notebox.get(1).setValue('');
                        addNotes();
                    };

                    // modal window
                    notebox = new AIR2.UI.Window({
                        title: 'Add Bin Notes',
                        iconCls: 'air2-icon-list',
                        cls: 'air2-drawer-notes',
                        closeAction: 'destroy',
                        closable: false,
                        width: 220,
                        height: 116,
                        layout: 'vbox',
                        items: [{
                            xtype: 'box',
                            html: 'Attach a note to these bin sources:'
                        }, {
                            xtype: 'textfield',
                            width: 200,
                            value: AIR2.Drawer.LASTNOTES
                        }],
                        keys: [{
                            key: Ext.EventObject.ENTER,
                            handler: addNotes
                        }, {
                            key: Ext.EventObject.ESC,
                            handler: skipNotes
                        }],
                        buttonAlign: 'left',
                        fbar: [
                            {
                                xtype: 'air2button',
                                air2type: 'SAVE',
                                air2size: 'MEDIUM',
                                text: 'Attach',
                                width: 'auto',
                                handler: addNotes
                            },
                            {
                                xtype: 'air2button',
                                air2type: 'CANCEL',
                                air2size: 'MEDIUM',
                                text: 'Skip',
                                width: 'auto',
                                handler: skipNotes
                            }
                        ]
                    });
                    notebox.show();
                    notebox.get(1).focus(false, 10);
                }
                else {
                    drwr.views[drwr.currView].maskBin(target);
                    AIR2.Drawer.API.addItems(r, s, callback);
                }
            }
            return true;
        }
    });
};
Ext.extend(AIR2.Drawer, Ext.Component, {
    id: 'air2-drawer',
    applyTo: 'air2-drawer',
    refreshDDLocation: function () {

        //re-cache the DD-position of the drawer
        //Ext.dd.DragDropMgr.useCache = false; -- very inefficient
        var loc = Ext.dd.DragDropMgr.getLocation(this.dropZone);
        Ext.dd.DragDropMgr.locationCache[this.dropZone.id] = loc;
    },
    slideOpen: function () {
        var h = this.dBody.getHeight();
        this.el.removeClass('collapsed');
        this.dBody.animate({marginBottom: {from: -h, to: 0, unit: 'px'}}, 0.3,
            function () {
                if (!this.isTmpOpen) {
                    AIR2.Drawer.STATE.set('open', true);
                }
                this.el.addClass('expanded');
                this.refreshDDLocation();
            }.createDelegate(this)
        );
    },
    slideShut: function () {
        var h = this.dBody.getHeight();
        this.el.removeClass('expanded');
        this.dBody.animate({marginBottom: {from: 0, to: -h, unit: 'px'}}, 0.3,
            function () {
                AIR2.Drawer.STATE.set('open', false);
                this.el.addClass('collapsed');

                // WAY off the page
                this.dBody.setStyle('margin-bottom', '-9000px');
            }.createDelegate(this)
        );
    },
    tempOpen: function () {
        if (!this.isTmpOpen && this.el.hasClass('collapsed')) {
            this.isTmpOpen = true;
            this.slideOpen();
        }
    },
    tempShut: function () {
        if (this.isTmpOpen && this.el.hasClass('expanded')) {
            this.isTmpOpen = false;
            new Ext.util.DelayedTask(this.slideShut, this).delay(1000);
        }
    },
    transitionView: function (changeTo, binRec, inlineConfig) {
        var config;

        // render the next view (if it doesn't exist yet)
        if (!this.views[changeTo]) {
            config = {
                renderTo: this.dView,
                style: 'visibility: hidden',
                binRec: binRec,
                infoEl: this.dInfo
            };
            if (inlineConfig) {
                config = Ext.apply(config, inlineConfig);
            }

            // create
            if (changeTo === 'sm') {
                this.views.sm = new AIR2.Drawer.BinListSmall(config);
            }
            else if (changeTo === 'lg') {
                this.views.lg = new AIR2.Drawer.BinListLarge(config);
            }
            else {
                this.views.si = new AIR2.Drawer.BinListSingle(config);
            }
        }

        // clear controls for single view
        if (changeTo === 'si') {
            this.controls.clearBtns();
        }

        // bind the pager (and optionally refresh)
        this.tbar.setView(changeTo, this.views[changeTo], inlineConfig);
        this.fbar.setView(changeTo, this.views[changeTo], inlineConfig);

        // change to the view
        if (changeTo !== this.currView) {
            this.views[changeTo].changeTo(
                this.dView,
                this.dInfo,
                this.tbar,
                this.fbar,
                this.views[this.currView],
                binRec
            );
        }

        // set the current view
        this.currView = changeTo;
        this.views[this.currView].el.unselectable();
    },
    createNew: function (type, addRecs, mergeRecs) {
        var dt, formTitle, newRec, old;

        old = this.views[this.currView];

        // create a unique bin name --- use username and timestamp
        dt = new Date();
        newRec = new old.store.recordType({
            bin_name: AIR2.USERNAME + ' ' + dt.format('Y-m-d H:i:s'),
            bin_type: type || 'S',
            bin_shared_flag : false
        });
        formTitle = 'Create New Bin';
        if (mergeRecs && mergeRecs.length > 1) {
            formTitle = 'Create Merged Bin';
        }
        else if (mergeRecs && mergeRecs.length === 1) {
            formTitle = 'Create Duplicate Bin';
        }

        if (!this.createBinForm) {
            this.createBinForm = new Ext.form.FormPanel({
                cls: 'air2-create-new',
                renderTo: this.dView,
                style: 'display:none',
                unstyled: true,
                labelWidth: 75,
                defaults: {msgTarget: 'under'},
                items: [
                    {
                        xtype: 'label',
                        cls: 'create-new-title',
                        html: '<h1>' + formTitle + '</h1>'
                    },
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
                ]
            });
        }
        else {
            this.createBinForm.get(0).update('<h1>' + formTitle + '</h1>');
            this.createBinForm.get(3).setDisabled((type) ? true : false);
        }

        // transition
        old.el.fadeOut({duration: 0.1, useDisplay: true});
        this.dInfo.scale(330, 0, {duration: 0.2}).enableDisplayMode().hide();
        this.tbar.el.setWidth(330, {duration: 0.2}).enableDisplayMode().hide();
        this.fbar.el.show().setWidth(330, {duration: 0.2});
        this.fbar.setNewMode(true);
        this.dView.scale(330, 230, {
            duration: 0.2,
            scope: this,
            callback: function () {
                this.createBinForm.el.fadeIn({duration: 0.1, useDisplay: true});
                this.createBinForm.getForm().loadRecord(newRec);
                this.createBinForm.get(1).focus(true);
            }
        });

        // disable the tab
        this.dTab.setStyle('opacity', 0.6);
        this.controls.disable();

        //setup the references for "endNew" to use
        this.newRec = newRec;
        this.newAdd = addRecs;
        this.newMerge = mergeRecs;
    },
    endNew: function (doSave) {
        if (doSave) {
            var store = this.views[this.currView].store;
            if (!this.createBinForm.getForm().isValid()) {
                return;
            }
            this.createBinForm.getForm().updateRecord(this.newRec);
            this.createBinForm.el.mask('Saving');
            store.insert(0, this.newRec);

            // save the record, and add any selections/merges afterwards
            store.on('save', function () {
                var a, ar, el, m, mr, restore;

                restore = function () {
                    this.endNew(false);
                    this.views[this.currView].reloadDataView();
                }.createDelegate(this);

                if (this.newAdd) {
                    ar = this.newRec;
                    a = this.newAdd;
                    el = this.createBinForm.el;

                    AIR2.Drawer.API.addItems(ar, a, function (data, success) {
                        if (success) {
                            restore();
                        }
                        else {
                            AIR2.UI.ErrorMsg(
                                el,
                                'Server Error',
                                'A server error occured!<br/>' +
                                'Unable to add sources to bin',
                                function () {
                                    restore();
                                }
                            );
                        }
                    });
                }
                else if (this.newMerge) {
                    mr = this.newRec;
                    m = this.newMerge;
                    AIR2.Drawer.API.merge(mr, m, function (data, success) {
                        restore();
                    });
                }
                else {
                    restore();
                }
            }, this, {single: true});
            store.save();
        }
        else {
            //enable controls
            this.dTab.setStyle('opacity', 1);
            this.controls.enable();

            // fix the pager
            this.fbar.setView(this.currView, this.views[this.currView], true);

            // change back to last view
            this.views[this.currView].changeTo(
                this.dView,
                this.dInfo,
                this.tbar,
                this.fbar,
                this.createBinForm
            );
            this.createBinForm.el.unmask();

            //unreference
            this.newRec = false;
            this.newAdd = false;
            this.newMerge = false;
        }
    },
    deleteBin: function (recs) {
        var d, b, msg, r, s;

        r = recs[0];
        s = this.views[this.currView].store;
        b = this.dBody;
        msg = 'Delete bin "' + r.get('bin_name') + '"?';
        d = b.createChild({
            tag: 'div',
            cls: 'delete-prompt air2-corners',
            html: '<div class="dbody">' +
                    '<div class="msg">' +
                        msg +
                    '</div>' +
                    '<div class="buttons">' +
                        '<span class="air2-btn air2-btn-delete ' +
                        'air2-btn-medium">' +
                            '<button class="x-btn-text">Delete</button>' +
                        '</span> ' +
                        '<span class="air2-btn air2-btn-cancel ' +
                        'air2-btn-medium">' +
                            '<button class="x-btn-text">Cancel</button>' +
                        '</span>' +
                    '</div>' +
                '</div>'
        });
        d.on('click', function (e) {
            if (e.getTarget('.air2-btn-delete')) {
                s.remove(r);
                s.save();
                b.unmask();
                d.ghost('b', {remove: true});
            }
            else if (e.getTarget('.air2-btn-cancel')) {
                b.unmask();
                d.slideOut('t', {remove: true});
            }
        });
        b.mask();
        d.slideIn('t');
    }
});
