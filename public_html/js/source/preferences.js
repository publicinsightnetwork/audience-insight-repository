/**
 * Preferences panel
 */
AIR2.Source.Preferences = function() {
    // include account-lock in title
    var titleLock = AIR2.Source.LOCK ? ('&nbsp;'+AIR2.Source.LOCK) : '';
    return new AIR2.UI.Panel({
        colspan: 1,
        title: 'Preferences' + titleLock,
        iconCls: 'air2-icon-fact',
        storeData: AIR2.Source.PREFDATA,
        url: AIR2.Source.URL + '/preference',
        showTotal: true,
        itemSelector: '.pref-row',
        tpl: new Ext.XTemplate(
            '<table class="air2-tbl">' +
              // header
              '<tr>' +
                '<th><span>Preference Type</span></th>' +
                '<th><span>Value</span></th>' +
              '</tr>' +
              // rows
              '<tpl for=".">' +
                '<tr class="pref-row">' +
                  '<td><b>{[values.pt_name]}</b></td>' +
                  '<td>{[this.formatLanguage(values.PreferenceTypeValue.ptv_value)]}</td>' +
                '</tr>' +
              '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: true,
                formatLanguage: function (prefTypeValue) {
                    if (prefTypeValue == 'en_US') {
                        return 'English';
                    }
                    else if (prefTypeValue == 'es_US') {
                        return 'Spanish';
                    }
                }
            }
        ),
        modalAdd: 'Add Preference',
        editModal: {
            title: 'Source Preferences' + titleLock,
            allowAdd: AIR2.Source.BASE.authz.unlock_write, //ignore lock
            width: 750,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Source.URL + '/preference',
                multiSort: 'pt_name asc',
                newRowDef: {Preference: ''},
                allowEdit: function(rec) {
                    
                    return AIR2.Source.BASE.authz.may_write;
                },
                allowDelete: AIR2.Source.BASE.authz.may_write,
                itemSelector: '.pref-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: new Ext.XTemplate(
                    '<table class="air2-tbl">' +
                      // header
                      '<tr>' +
                        '<th class="fixw right"><span>Created</span></th>' +
                        '<th><span>Preference Type</span></th>' +
                        '<th><span>Value</span></th>' +
                        '<th class="row-ops"></th>' +
                      '</tr>' +
                      // rows
                      '<tpl for=".">' +
                        '<tr class="pref-row">' +
                          '<td class="date right">{[AIR2.Format.date(values.sp_cre_dtim)]}</td>' +
                          '<td><b>{[values.pt_name]}</b></td>' +
                          '<td>{[this.format(values)]}</td>' +
                          '<td class="row-ops"><button class="air2-rowedit"></button><button class="air2-rowdelete"></button></td>' +
                        '</tr>' +
                      '</tpl>' +
                    '</table>',
                    {
                        compiled: true,
                        disableFormats: true,
                        format: function (values) {
                            if (values.PreferenceTypeValue) {
                                if (values.PreferenceTypeValue.ptv_value == 'en_US') {
                                    return 'English';
                                }
                                else if (values.PreferenceTypeValue.ptv_value == 'es_US') {
                                    return 'Spanish';
                                } else {
                                    return values.PreferenceTypeValue.ptv_value;
                                }
                            }
                            else {
                                return '';
                            }
                        }
                    }
                ),
                editRow: function(dv, node, rec) {
                    var edits = [];
                    if (rec.phantom) {
                        var prefEl = Ext.fly(node).first('td').next();
                        prefEl.update('');
                        var prefType = new AIR2.UI.ComboBox({
                            allowBlank: false,
                            store: new AIR2.UI.APIStore({
                                data: AIR2.Source.PREFSDATA
                            }),
                            valueField: 'pt_uuid',
                            displayField: 'pt_name',
                            listEmptyText: 'No fields remaining',
                            width: 135,
                            renderTo: prefEl,
                            listeners: {
                                select: function(box, rec) {
                                    prefValues.setIdent(rec.data.pt_identifier);
                                    prefValues.enable();
                                }
                            }
                        });
                        edits.push(prefType);
                        rec.store.each(function(ptvrec) {
                            if (!ptvrec.phantom) {
                                var rmv = prefType.store.getById(ptvrec.data.pt_uuid);
                                prefType.store.remove(rmv);
                            }
                        });
                    }
                        var prefValuesEl = Ext.fly(node).first('td').next().next();
                        prefValuesEl.update('').setStyle('padding', '2px');
                        var prefValues = new AIR2.UI.ComboBox({
                            disabled: true,
                            allowBlank: false,
                            width: 150,
                            renderTo: prefValuesEl,
                            setIdent: function(ident) {
                                var fixtureData = AIR2.Fixtures.Preferences[ident];
                                this.store.loadData(fixtureData);
                                this.enable();
                            },
                            value: null
                        });
                        edits.push(prefValues);
                    
                    if (!rec.phantom) {
                        prefValues.setIdent(rec.data.pt_identifier);
                        if (rec.data.PreferenceTypeValue.ptv_uuid) {
                            prefValues.setValue(rec.data.PreferenceTypeValue.ptv_uuid);
                        }
                    }
                    return edits;
                },
                saveRow: function(rec, edits) {
                    var type, pt_uuid, pt_val;
                    if (rec.phantom) {
                        var pt_uuid = edits[0].getValue();
                        var ptv_uuid = edits[1].getValue();
                        rec.set('pt_uuid', pt_uuid);
                        rec.set('ptv_uuid', ptv_uuid);
                    }
                    else {
                        var old_ptv_uuid = rec.data.PreferenceTypeValue.ptv_uuid;
                        var ptv_uuid = edits[0].getValue();
                        rec.set('ptv_uuid', ptv_uuid);
                    }
                }
            }
        }
    });
}