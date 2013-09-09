/***************
 * Outcome Sources Panel
 */
AIR2.Outcome.Sources = function () {
    var maywrite,
        sourceEditTemplate,
        sourceTemplate,
        upload;

    maywrite = AIR2.Outcome.BASE.authz.may_write;

    upload = new AIR2.UI.Button({
        air2type: 'CLEAR',
        iconCls: 'air2-icon-upload',
        tooltip: 'Add Sources via Bin',
        handler: function () {
            var w = AIR2.Outcome.Modal();
            w.on('close', function () {
                AIR2.Outcome.Sources.reload();
            });
        }
    });

    // formatters
    AIR2.Outcome.fmtPhone = function (v) {
        if (v.SrcPhoneNumber && v.SrcPhoneNumber.length) {
            return AIR2.Format.sourcePhone(v.SrcPhoneNumber[0]);
        }
        return '<span class="lighter">(none)</span>';
    };

    AIR2.Outcome.fmtLocation = function (v) {
        var s, sm;
        if (v.SrcMailAddress && v.SrcMailAddress.length) {
            sm = v.SrcMailAddress[0];
            if (sm.smadd_city || sm.smadd_state || sm.smadd_zip) {
                s = sm.smadd_city ? sm.smadd_city + ' ' : '';
                s += sm.smadd_state ? sm.smadd_state + ' ' : '';
                s += sm.smadd_zip ? sm.smadd_zip + ' ' : '';
                return s;
            }
        }
        return '<span class="lighter">(none)</span>';
    };

    AIR2.Outcome.fmtHome = function (v) {
        if (v.SrcOrg && v.SrcOrg.length) {
            return AIR2.Format.orgName(v.SrcOrg[0].Organization, true);
        }
        return '<span class="lighter">(none)</span>';
    };

    sourceTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th class="fixw"><span>Impact</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Location</span></th>' +
            '<th><span>Home</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="source-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.sout_cre_dtim)]}' +
              '</td>' +
              '<td class="date">' +
                '{[AIR2.Format.codeMaster("sout_type", values.sout_type)]}' +
              '</td>' +
              '<td>{[AIR2.Format.sourceName(values,1,1)]}</td>' +
              '<td>{[AIR2.Outcome.fmtLocation(values)]}</td>' +
              '<td>{[AIR2.Outcome.fmtHome(values)]}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    sourceEditTemplate =  new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<thead>' +
            '<tr>' +
              '<th class="fixw right"><span>Added</span></th>' +
              '<th class="fixw"><span>Impact</span></th>' +
              '<th><span>Name</span></th>' +
              '<th><span>Phone</span></th>' +
              '<th><span>Location</span></th>' +
              '<th><span>Home</span></th>' +
              '<th><span>Added By</span></th>' +
              '<th class="row-ops"></th>' +
            '</tr>' +
          '</thead>' +
          // rows
          '<tpl for=".">' +
            '<tbody class="source-row">' +
              '<tr>' +// class="source-row">' +
                '<td class="date right">' +
                  '{[AIR2.Format.date(values.sout_cre_dtim)]}' +
                '</td>' +
                '<td class="date">' +
                  '{[AIR2.Format.codeMaster("sout_type", values.sout_type)]}' +
                '</td>' +
                '<td>{[AIR2.Format.sourceName(values,1,1)]}</td>' +
                '<td>{[AIR2.Outcome.fmtPhone(values)]}</td>' +
                '<td>{[AIR2.Outcome.fmtLocation(values)]}</td>' +
                '<td>{[AIR2.Outcome.fmtHome(values)]}</td>' +
                '<td>{[AIR2.Format.userName(values.CreUser,1,1)]}</td>' +
                '<td class="row-ops">' +
                  '<button class="air2-rowedit"></button>' +
                  '<button class="air2-rowdelete"></button>' +
                '</td>' +
              '</tr>' +
            '</tbody>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            notesCls: function (v) {
                return v.sout_notes ? '' : 'empty';
            }
        }
    );

    // build panel
    AIR2.Outcome.Sources = new AIR2.UI.Panel({
        colspan: 2,
        title: 'Sources',
        showTotal: true,
        showHidden: false,
        iconCls: 'air2-icon-sources',
        cls: 'air2-src-outcome',
        storeData: AIR2.Outcome.SRCDATA,
        url: AIR2.Outcome.URL + '/source',
        itemSelector: '.source-row',
        tpl: sourceTemplate,
        tools: maywrite ? ['->', upload] : false,
        modalAdd: 'Add Source',
        editModal: {
            title: 'PINfluence Sources',
            width: 800,
            allowAdd: maywrite ? 'Add Source' : false,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Outcome.URL + '/source',
                multiSort: 'src_first_name asc',
                newRowDef: {src_username: ''},
                itemSelector: '.source-row',
                tpl: sourceEditTemplate,
                // row editor
                allowEdit: maywrite,
                allowDelete: maywrite,
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                editRow: function (dv, node, rec) {
                    var edits, sem, semEl, type, typeEl;

                    typeEl = Ext.fly(node).first('tr').first('td').next();
                    typeEl.update('').setStyle('padding', '4px');
                    type = new AIR2.UI.ComboBox({
                        choices: AIR2.Fixtures.CodeMaster.sout_type,
                        value: rec.data.sout_type || 'I',
                        renderTo: typeEl,
                        width: 76
                    });
                    edits = [type];

                    if (rec.phantom) {
                        semEl = typeEl.next();
                        semEl.update('').setStyle('padding', '4px');
                        sem = new AIR2.UI.SearchBox({
                            cls: 'air2-magnifier',
                            minChars: 2,
                            pageSize: 10,
                            searchUrl: AIR2.HOMEURL + '/source',
                            queryParam: 'email',
                            baseParams: {
                                sort: 'primary_email asc',
                                excl_out: AIR2.Outcome.UUID
                            },
                            valueField: 'src_uuid',
                            displayField: 'primary_email',
                            emptyText: 'Search Source Emails',
                            listEmptyText:
                                '<div style="padding:4px 8px">' +
                                    'No Sources Found' +
                                '</div>',
                            formatComboListItem: function (v) {
                                return v.primary_email;
                            },
                            renderTo: semEl,
                            width: 200
                        });
                        edits.push(sem);
                    }
                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('sout_type', edits[0].getValue());
                    if (rec.phantom) {
                        rec.set('src_uuid', edits[1].getValue());
                    }
                }
            }
        }
    });
    return AIR2.Outcome.Sources;
};
