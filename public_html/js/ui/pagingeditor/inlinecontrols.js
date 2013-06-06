Ext.ns('AIR2.UI.PagingEditor');
/***************
 * Inline Controls plugin
 *
 * Plugin for a PagingEditor which listens to click events on air2-rowedit and
 * air2-rowdelete buttons.
 *
 * @plugin AIR2.UI.PagingEditor.InlineControls
 * @param {AIR2.UI.PagingEditor} pageEditor
 */
AIR2.UI.PagingEditor.InlineControls = {
    // plugin init
    init: function (pageEditor) {
        this.dv = pageEditor;

        // row edit/delete-ability
        pageEditor.on('mouseenter', function (dv, idx, node) {
            var ad,
                ae,
                mayDelete,
                mayEdit,
                rec;

            ae = pageEditor.allowEdit;
            ad = pageEditor.allowDelete;
            rec = pageEditor.getRecord(node);
            mayEdit = Ext.isFunction(ae) ? ae(rec) : ae;
            mayDelete = Ext.isFunction(ad) ? ad(rec) : ad;

            if (mayEdit) {
                Ext.fly(node).removeClass('hide-rowedit');
            }
            else {
                Ext.fly(node).addClass('hide-rowedit');
            }

            if (mayDelete) {
                Ext.fly(node).removeClass('hide-rowdelete');
            }
            else {
                Ext.fly(node).addClass('hide-rowdelete');
            }
        });

        // row click listener
        pageEditor.on(
            'click',
            function (dv, idx, node, ev) {
                var rowdelete,
                    rowedit;

                rowedit = ev.getTarget('.air2-rowedit');
                rowdelete = ev.getTarget('.air2-rowdelete');
                if (rowedit || rowdelete) {
                    if (!dv.el.hasClass('unlocked')) {
                        return; //already locked a row
                    }

                    // show deleter/editor
                    if (rowdelete) {
                        this.makeDeleter(dv, node);
                    }
                    else {
                        this.makeEditor(dv, node);
                    }
                }
            },
            this
        );

        // header click listener
        pageEditor.on(
            'containerclick',
            function (dv, ev) {
                if (ev.getTarget('.air2-rowadd')) {
                    this.makeNew(dv);
                }
            },
            this
        );

        // cleanup editor on hide
        pageEditor.on(
            'beforehide',
            function () {
                if (pageEditor.rowctrl) {
                    this.cleanup(pageEditor);
                }
            },
            this
        );
    },
    // helper to cleanup in a hurry
    cleanup: function (pageEditor) {
        if (!pageEditor.el.hasClass('unlocked')) {
            pageEditor.el.addClass('unlocked');
            var rec = pageEditor.getRecord(pageEditor.rownode);
            if (rec && rec.phantom) {
                pageEditor.store.remove(rec);
            }
            pageEditor.refreshNode(pageEditor.indexOf(pageEditor.rownode));
            pageEditor.rowAlts();
            pageEditor.rowctrl.destroy();
        }
    },
    // create a new row-record
    makeNew: function (dv) {
        if (!dv.el.hasClass('unlocked')) {
            return; //already locked a row
        }

        // make sure the store is loaded first
        if (!dv.store.recordType) {
            dv.store.on(
                'load',
                this.makeNew.createDelegate(this, [dv]),
                this,
                {single: true}
            );
        }
        else {
            var rec = new dv.store.recordType(Ext.apply({}, dv.newRowDef));
            dv.store.insert(0, rec);
            this.makeEditor(dv, dv.getNode(rec));
        }
    },
    // edit a row-record
    makeEditor: function (dv, node) {
        var edits,
            rec;

        rec = dv.getRecord(node);

        // edit form
        edits = [];
        if (Ext.isFunction(dv.editRow)) {
            edits = dv.editRow(dv, node, rec);

            // try to focus the first field
            if (edits.length && edits[0].focus) {
                edits[0].focus(false, true);
            }
        }

        this.makeRowControl(dv, node, {
            air2type: 'ROUND',
            iconCls: 'air2-icon-disk-small',
            tooltip: {text: 'Save', cls: 'lighter'},
            handler: function (b) {
                var isNew,
                    isValid,
                    r;

                // validation
                isValid = true;
                Ext.each(edits, function (item) {
                    if (!item.isValid()) {
                        isValid = false;
                    }
                });
                if (!isValid) {
                    return;
                }

                // update record
                if (Ext.isFunction(dv.saveRow)) {
                    r = dv.saveRow(rec, edits);
                    if (r === false) {
                        return;
                    }
                }

                // save
                if (rec.dirty) {
                    isNew = rec.phantom;
                    if (dv.store.save() < 1) {
                        return;
                    }
                    dv.mask('Saving');
                    dv.store.on('save', function () {
                        dv.unmask();
                        if (isNew) {
                            dv.store.reload();
                        }
                        else {
                            dv.el.addClass('unlocked');
                            dv.rowAlts();
                        }
                    }, this, {single: true});
                }
                else {
                    b.ownerCt.get(1).handler(); //no changes - cancel
                }
            }
        });
    },
    // delete a row-record
    makeDeleter: function (dv, node) {
        var btnCfg, msgText, rec;

        rec = dv.getRecord(node);
        btnCfg = {
            air2type: 'ROUND',
            //iconCls: 'air2-icon-disk-small',
            text: 'Yes',
            cls: 'confirm-delete',
            tooltip: {text: 'Confirm Delete', cls: 'lighter'},
            handler: function (b) {
                b.ownerCt.el.fadeOut({
                    remove: true,
                    callback: function () {
                        dv.store.remove(rec);
                        if (dv.store.save() < 1) {
                            return;
                        }
                        dv.mask('Deleting');
                        dv.store.on(
                            'save',
                            function () {
                                dv.unmask();
                                dv.store.reload();
                            },
                            this,
                            {single: true}
                        );
                    }
                });
            }
        };
        msgText = '<span style="color:#963737">Delete?</span>';
        this.makeRowControl(dv, node, btnCfg, msgText, 'No');
    },
    // helper function to make row edit-delete controls
    makeRowControl: function (dv, node, actionBtn, msgTxt, cancelTxt) {
        var ct, rowEl;

        if (dv.rowctrl) {
            dv.rowctrl.destroy(); //cleanup
        }
        rowEl = Ext.get(node);
        rowEl.addClass('row-selected');
        dv.el.removeClass('unlocked');

        ct = new Ext.Container({
            cls: 'row-controls',
            renderTo: (rowEl.last()) ? rowEl.last() : rowEl,
            defaults: {
                xtype: 'air2button',
                air2size: 'MEDIUM'
            },
            items: [
                actionBtn,
                {
                    air2type: 'ROUND',
                    iconCls: cancelTxt ? null : 'air2-icon-cancel-small',
                    text: cancelTxt ? cancelTxt : null,
                    cls: 'cancel-op',
                    tooltip: {text: 'Cancel', cls: 'lighter'},
                    handler: function () {
                        ct.el.slideOut(
                            'l',
                            {
                                duration: 0.2,
                                callback: function () {
                                    dv.el.addClass('unlocked');
                                    var rec = dv.getRecord(node);
                                    if (rec.phantom) {
                                        dv.store.remove(rec);
                                    }
                                    dv.refreshNode(dv.indexOf(node));
                                    dv.rowAlts();
                                    ct.destroy();
                                }
                            }
                        );
                    }
                }
            ],
            height: rowEl.getHeight()
        });
        ct.el.anchorTo(rowEl, 'l-r', [-1, -1], false, true);
        ct.el.slideIn('l', {
            duration: 0.2,
            callback: function () {
                if (msgTxt) {
                    var box = new Ext.BoxComponent({
                        renderTo: ct.el,
                        style: 'position:absolute',
                        html: msgTxt
                    });
                    box.el.alignTo(ct.el.first(), 'r-l', [-10, 0]);
                    ct.on('destroy', function () {box.destroy(); });
                }
            }
        });
        dv.rowctrl = ct;
        dv.rownode = node;
    }

};
