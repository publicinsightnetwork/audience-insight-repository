Ext.ns('AIR2.Outcome');

AIR2.Outcome.Modal = function (cfg) {
	 // support article
    var tip = AIR2.Util.Tipper.create({id: 20978401, cls: 'lighter', align: 15});

    influence =  new AIR2.UI.ComboBox({
        choices: AIR2.Fixtures.CodeMaster.sout_type,
        width: 90,
    });

    Logger("Influence", influence); 

    binPicker = new AIR2.UI.SearchBox({
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

    // the actual modal window
    var w = new AIR2.UI.Window({
        title: 'Add Sources via Bin ' + tip,
        closeAction: 'close',
        iconCls: 'air2-icon-upload',
        cls: 'air2-upload-modal',
        width: 650,
        height: 350,
        layout: 'fit',
        layoutConfig: {deferredRender: true},
        items: [influence, binPicker],
        bbar: [{
            xtype: 'air2button',
            air2type: 'SAVE',
            air2size: 'MEDIUM',
            text: 'Save',
            handler: function() {
                var influence_type = w.get(0).value;
                var bin_uuid = w.get(1).selectedRecord.data.bin_uuid;
                var url = AIR2.HOMEURL + '/bin/' + bin_uuid +'/source.json';
                var sourcesArray = [];
                Ext.Ajax.request({
                    url: url,
                    success: function (response) {
                        var text, data, sources;
                        text = response.responseText;
                        data = Ext.util.JSON.decode(text);
                        if ( data ) {
                            sources = data.radix;
                            Ext.each(sources, function (source, index) {
                                sourcesArray.push(source.src_uuid);
                            });
                            var fieldValues = {};
                            fieldValues.sources = {};
                            fieldValues.sources.sout_type = influence_type;
                            fieldValues.sources.sources = sourcesArray;
                            Logger("fieldValues", fieldValues);
                            Ext.Ajax.request({
                                url: AIR2.Outcome.URL + '.json',
                                method: 'PUT',
                                params: {radix: Ext.util.JSON.encode(fieldValues)},
                                success: function (response) {
                                    w.close();
                                },
                                failure: function (resp, opts) {
                                    Logger("Update Failed", resp);
                                }
                            }); 
                        }
                    },
                    failure: function (resp, opts) {
                        Logger("Failed", resp);
                    }
                });
                         
            }
        },'  ',{
            xtype: 'air2button',
            air2type: 'CANCEL',
            air2size: 'MEDIUM',
            text: 'Cancel',
            handler: function() {w.close();}
        }]  // end bbar
    });

    w.show();
    
    return w;
};
