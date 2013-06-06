/***********************
 * Prompt for deleting a question
 */
AIR2.Builder.questionDelete = function (dv, node) {
    var controls, prompter, rec;

    rec = dv.getRecord(node);

    // fade out slightly
    prompter = new Ext.BoxComponent({
        renderTo: node,
        cls: 'delete-mask',
        height: Ext.fly(node).getHeight()
    });

    // Delete/cancel control toolbar
    controls = new Ext.Toolbar({
        renderTo: node,
        items: [{
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-delete',
            text: 'Delete',
            handler: function () {

                AIR2.unfocus();
                AIR2.Builder.Main.editMode(false);

                Ext.fly(node).ghost('b', {
                    duration: 0.3,
                    useDisplay: true,
                    callback: function () {
                        AIR2.Builder.QUESSTORE.remove(rec);
                        AIR2.Builder.QUESSTORE.save();

                        // recache stops
                        dv.refresh();
                        AIR2.Builder.PUBLICDV.cacheStops();
                        AIR2.Builder.PRIVATEDV.cacheStops();
                    }
                });
            }
        }, '    ', {
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-cancel-small',
            text: 'Cancel',
            handler: function () {
                AIR2.unfocus();
                AIR2.Builder.Main.editMode(false);
                dv.refresh();
            }
        }]
    });

    // focus (spotlight)
    AIR2.focus(node);

    // lock
    AIR2.Builder.Main.editMode(true);

};
