/***********************
 * Start editing a question
 */
AIR2.Builder.questionEdit = function (dv, node) {
    var controls, fields, form, rec;
    rec = dv.getRecord(node);

    // save/cancel control toolbar
    controls = new Ext.Toolbar({
        items: [{
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM',
            iconCls: 'air2-icon-disk',
            text: 'Save',
            handler: function () {
                var idx = dv.indexOf(node);
                form.getForm().updateRecord(rec);
                dv.store.save();
                dv.refreshNode(idx);
                AIR2.unfocus();
                AIR2.Builder.Main.editMode(false);

                // recache stops
                AIR2.Builder.PUBLICDV.cacheStops();
                AIR2.Builder.PRIVATEDV.cacheStops();
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
                dv.store.rejectChanges();
                if (rec.phantom) {
                    dv.store.remove(rec);
                    dv.refresh();
                }
                AIR2.unfocus();
                AIR2.Builder.Main.editMode(false);

                // recache stops
                AIR2.Builder.QUESSTORE.sort();
                AIR2.Builder.PUBLICDV.cacheStops();
                AIR2.Builder.PRIVATEDV.cacheStops();
            }
        }]
    });

    // editing fields
    // TODO: add more and customize for each question type
    fields = [{
        xtype: 'textfield',
        fieldLabel: 'Question',
        name: 'ques_value'
    }];

    // edit form
    Ext.fly(node).update('');
    form = new Ext.form.FormPanel({
        items: fields,
        unstyled: true,
        labelWidth: 75,
        defaults: {style: {width: '96%'}},
        renderTo: node,
        bbar: controls
    });
    form.getForm().loadRecord(rec);

    // focus (spotlight)
    AIR2.focus(node);

    // lock
    AIR2.Builder.Main.editMode(true);

};
