Ext.ns('AIR2.SrcEmail');
/***************
 * SrcEmail Row Controls plugin
 *
 * Plugin for a PagingEditor specific to SrcEmail management
 *
 * @plugin AIR2.SrcEmail.RowControls
 * @param {AIR2.UI.PagingEditor} pageEditor
 */
AIR2.SrcEmail.RowControls = {
    // instead of deleting, confirm bad email
    makeDeleter: function (dv, node) {
        var rec = dv.getRecord(node);
        rec.set('sem_status', 'C'); //confirmed bad
        dv.store.save();
        dv.el.addClass('unlocked');
    },
    // add some extra buttons to editor (hidden)
    makeEditor: function (dv, node) {
        AIR2.UI.PagingEditor.InlineControls.makeEditor(dv, node);
        dv.rowctrl.insert(1, {
            xtype: 'air2button',
            air2type: 'ROUND',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-merge',
            tooltip: 'Merge',
            cls: 'merge-op',
            hidden: true,
            handler: function () {
                // sanity!
                if (this.uuid1 && this.uuid2 && this.uuid1 !== this.uuid2) {
                    // merge the email we're looking at INTO the other source
                    var w = AIR2.Merge.Sources({
                        prime_uuid: this.uuid2,
                        merge_uuid: this.uuid1,
                        originEl: node
                    });
                    w.on('close', function () {
                        if (w.SUCCESS) {
                            // confirm the record as bad
                            var sem_uuid = dv.getRecord(node).data.sem_uuid;
                            AIR2.SrcEmail.List.MERGED[sem_uuid] = true;
                            AIR2.SrcEmail.RowControls.makeDeleter(dv, node);
                        }
                    }, this);
                }
            }
        });
        dv.rowctrl.insert(2, {
            xtype: 'air2button',
            air2type: 'ROUND',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-delete',
            tooltip: 'Confirm Bad',
            cls: 'confirm-op',
            hidden: true,
            handler: function () {
                AIR2.SrcEmail.RowControls.makeDeleter(dv, node);
            }
        });
        dv.rowctrl.doLayout();
    },
    // change the allowed operations
    setEditMode: function (dv, mode, uuid1, uuid2) {
        if (!dv.rowctrl || !dv.rowctrl.items.getCount()) {
            return;
        }

        dv.rowctrl.get(0).setVisible(mode !== 'MERGE' && mode !== 'CONFIRM');
        dv.rowctrl.get(1).setVisible(mode === 'MERGE');
        dv.rowctrl.get(2).setVisible(mode === 'CONFIRM');
        dv.rowctrl.setHeight(Ext.fly(dv.rownode).getHeight());

        // record uuid's for the merge
        dv.rowctrl.get(1).uuid1 = uuid1;
        dv.rowctrl.get(1).uuid2 = uuid2;
    }
};
Ext.applyIf(AIR2.SrcEmail.RowControls, AIR2.UI.PagingEditor.InlineControls);
