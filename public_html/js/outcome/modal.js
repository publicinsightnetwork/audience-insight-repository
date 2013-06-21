Ext.ns('AIR2.Outcome');

AIR2.Outcome.Modal = function (cfg) {
    // support article
    var binPicker,
        form,
        influence,
        tip,
        w;

    tip = AIR2.Util.Tipper.create({id: 20978401, cls: 'lighter', align: 15});

    influence =  new AIR2.UI.ComboBox({
        allowBlank: false,
        choices: AIR2.Fixtures.CodeMaster.sout_type,
        fieldLabel: 'Impact',
        width: 90
    });

    binPicker = new AIR2.UI.SearchBox({
        allowBlank: false,
        name: 'bin_uuid',
        width: 375,
        cls: 'air2-magnifier',
        fieldLabel: 'Search bins',
        searchUrl: AIR2.HOMEURL + '/bin',
        pageSize: 10,
        baseParams: {
            sort: 'bin_name asc',
            type: 'S',
            owner: true
        },
        valueField: 'bin_uuid',
        displayField: 'bin_name',
        listEmptyText:
            '<div style="padding:4px 8px">' +
                'No Bins Found' +
            '</div>',
        emptyText: 'Search Bins',
        formatComboListItem: function (v) {
            return v.bin_name;
        }
    });

    // setup panel
    form = new Ext.form.FormPanel({
        items: [influence, binPicker],
        padding: 10
    });


    // the actual modal window
    w = new AIR2.UI.Window({
        title: 'Add Sources via Bin ' + tip,
        closeAction: 'close',
        iconCls: 'air2-icon-upload',
        cls: 'air2-upload-modal',
        width: 650,
        height: 350,
        layout: 'fit',
        layoutConfig: {deferredRender: true},
        items: [form],
        bbar: [{
            xtype: 'air2button',
            air2type: 'SAVE',
            air2size: 'MEDIUM',
            text: 'Save',
            handler: function () {
                var bin_uuid,
                    fieldValues,
                    influence_type,
                    sourcesArray,
                    url;

                if (!form.get(1).isValid() || !form.get(0).isValid()) {
                    AIR2.UI.ErrorMsg(
                        w,
                        'Missing Fields',
                        'Please fill in both fields.'
                    );
                    return;
                }

                influence_type = form.get(0).value;
                bin_uuid = form.get(1).selectedRecord.data.bin_uuid;

                fieldValues = {};

                fieldValues.sources = {
                    'bin_uuid': bin_uuid,
                    'sout_type': influence_type
                };

                w.el.mask('Adding...');

                Ext.Ajax.request({
                    url: AIR2.Outcome.URL + '.json',
                    method: 'PUT',
                    params: {
                        radix: Ext.util.JSON.encode(fieldValues)
                    },
                    success: function (response) {
                        w.el.unmask();
                        w.close();
                    },
                    failure: function (resp, opts) {
                        var msg,
                            text;

                        if (resp.responseText) {
                            text = Ext.decode(resp.responseText);
                        }

                        msg = 'Unable to add the soures from bin: ' +
                            bin_uuid + '.';


                        if (text && text.message) {
                            msg = text.message;
                        }

                        AIR2.UI.ErrorMsg(
                            w,
                            'Update Failed',
                            msg
                        );

                        w.el.unmask();
                    }
                });

            }
        },
        '  ',
        {
            xtype: 'air2button',
            air2type: 'CANCEL',
            air2size: 'MEDIUM',
            text: 'Cancel',
            handler: function () {
                w.close();
            }
        }]  // end bbar
    });

    w.show();

    return w;
};
