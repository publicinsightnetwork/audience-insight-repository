/***********************
 * Prompt for deleting a question
 */
AIR2.Inquiry.questionDelete = function (dv, node) {
    var controls, deleteWindow, el, prompter, rec, store, uuid;

    store = dv.getStore();
    uuid = node.getAttribute('data-record-uuid');
    rec = store.getAt(store.find('ques_uuid', uuid));

    el = Ext.get(node);
    el.down('.controls').hide();
    // fade out slightly
    prompter = new Ext.BoxComponent({
        cls: 'delete-mask',
        height: el.getHeight(),
        el: el
    });

    // Delete/cancel control toolbar
    controls = new Ext.Toolbar({
//         renderTo: node,
        items: [{
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-delete',
            text: 'Delete',
            handler: function () {

                deleteWindow.close();

                Ext.fly(node).ghost('b', {
                    duration: 0.3,
                    useDisplay: true,
                    callback: function () {
                        AIR2.Inquiry.quesStore.remove(rec);
                        AIR2.Inquiry.quesStore.save();

                        dv.refresh();
                    }
                });
            }
        },
        '    ',
        {
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-cancel-small',
            text: 'Cancel',
            handler: function () {
                deleteWindow.close();
                dv.refresh();
            }
        }]
    });

    deleteWindow = new AIR2.UI.Window({
        closable: false,
        height: 'auto',
        modal: true,
        items: [prompter, controls],
        title: 'Delete Field',
        width: '560px'
    });

    deleteWindow.show();

};
