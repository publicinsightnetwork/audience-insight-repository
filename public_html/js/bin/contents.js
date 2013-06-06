/***************
 * Bin Page - Bin-contents Panel
 */
AIR2.Bin.Contents = function () {

    var actionbtn,
        ctrls,
        dv,
        filterbox,
        hidden,
        pager,
        pnl,
        store,
        str,
        submTotal,
        tip,
        total,
        xtpl;

    // content display template
    xtpl = new Ext.XTemplate(
        '<tpl for=".">' +
          '<div class="air2-search-result item-row">' +
            '<table><tr>' +
              // checkbox
              '<td class="checkbox-col">' +
                '<div class="checkbox-handle">' +
                  '<input class="drag-checkbox" type="checkbox"></input>' +
                '</div>' +
              '</td>' +
              // contact info
              '<td>' +
                '<div class="source-contact">' +
                  '<h3>' +
                    '<span>{[this.formatIndex(xindex, values)]}.&nbsp;</span>' +
                    '<span>{[AIR2.Format.sourceName(values,1,0,28)]}</span>' +
                  '</h3>' +
                  '<ul>' +
                    '<li class="r-loc">{[this.formatLocation(values)]}</li>' +
                    '<li class="r-phone">{[this.formatPhone(values)]}</li>' +
                    '<li class="r-mail last">' +
                    '{[this.formatEmail(values)]}</li>' +
                  '</ul>' +
                '</div>' +
              '</td>' +
              // related items
              '<td>' +
                '<div class="r-excerpt">' +
                  // notes
                  '<tpl if="bsrc_notes">' +
                    '<div class="notes air2-icon air2-icon-annotation">' +
                      '<b>Notes:</b> ' +
                      '<span class="air2-bin-notes">' +
                      '{[this.formatNotes(values)]}<span>' +
                    '</div>' +
                  '</tpl>' +
                  // submissions
                  '<tpl if="this.hasSubm(values)"><tpl for="SrcResponseSet">' +
                    '<div class="air2-icon air2-icon-response">' +
                    '{[this.formatSubm(values)]}</div>' +
                    '<p>{[this.getExcerpt(values)]}</p>' +
                  '</tpl></tpl>' +
                '</div>' +
              '</td>' +
            '</tr></table>' +
          '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatIndex: function (num, values) {
                var idx, startAt;
                startAt = 0;
                if (this.store.lastOptions &&
                    this.store.lastOptions.params &&
                    this.store.lastOptions.params.offset) {
                    startAt = this.store.lastOptions.params.offset;
                }

                // careful when num == 1 ... could be an edit-refresh
                if (num === 1) {
                    idx = this.store.indexOfId(values.src_uuid);
                    if (idx >= 0) {
                        num = idx + 1;
                    }
                }
                return startAt + num;
            },
            formatLocation: function (src) {
                var str = '',
                    c = src.primary_addr_city,
                    s = src.primary_addr_state,
                    z = src.primary_addr_zip,
                    n = src.primary_addr_cntry;

                if (c && s) {
                    str += c + ', ' + s;
                }
                else if (s) {
                    str += s;
                }
                else if (z) {
                    str += z;
                }
                else if (n) {
                    str += n;
                }

                return str;
            },
            formatEmail: function (src) {
                var abbr, eml, str = '';
                if (src.primary_email) {
                    eml = src.primary_email;
                    abbr = Ext.util.Format.ellipsis(eml, 25);
                    str += AIR2.Format.createLink(abbr,
                        'mailto:' + eml,
                        true,
                        true);
                }
                return str;
            },
            formatPhone: function (src) {
                return src.primary_phone ? src.primary_phone : '';
            },
            formatNotes: function (v) {
                if (v.bsrc_notes) {
                    return v.bsrc_notes;
                }
                else {
                    return '<span class="lighter">(none)</span>';
                }
            },
            hasSubm: function (v) {
                return (v.SrcResponseSet && v.SrcResponseSet.length);
            },
            formatSubm: function (v) {
                var a, dt, href, q;
                dt = AIR2.Format.date(v.srs_date);
                href = AIR2.HOMEURL + '/submission/' + v.srs_uuid;
                a = '<a href="' + href + '">Submission on ' + dt + '</a>';
                q = AIR2.Format.inquiryTitle(v.Inquiry, true, 50);
                return a + ' to query ' + q;
            },
            getExcerpt: function (v) {
                // look for the first response > 90 chars, or the longest
                var first, longest = '', o = '';
                Ext.each(v.SrcResponse, function (sr) {
                    o = sr.sr_orig_value;
                    if (o) {
                        if (o.length > 90 && !first) {
                            first = o;
                        }
                        Logger("Longest", longest);
                        if (o.length > longest.length) {
                            longest = o;
                        }
                    }
                });
                return Ext.util.Format.ellipsis(first || longest, 80, true);
            }
        }
    );

    // selection controls
    ctrls = new Ext.Container({
        storeload: function (s, rs) {
            var pg = s.getCount(), all = AIR2.Bin.BASE.radix.src_count;
            ctrls.items.each(function (item) {
                if (item.storetotal) {
                    item.storetotal(pg, all);
                }
            });
            ctrls.doLayout();
        },
        selchange: function (dv, sels) {
            ctrls.items.each(function (item) {
                if (item.dvnumsel) {
                    item.dvnumsel(sels.length);
                }
            });
            ctrls.doLayout();
        },
        layout: 'hbox',
        cls: 'tools-ct',
        defaults: {
            margins: '2 10 6 0',
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM'
        },
        items: [
            {
                text: 'Drag selected (0)',
                cls: 'drag-sel',
                iconCls: 'air2-icon-drag',
                disabled: true,
                dvnumsel: function (num) {
                    this.setText('Drag selected (' + num + ')');
                    this.setDisabled(num < 1);
                }
            },
            {
                text: 'Drag all (0)',
                cls: 'drag-all',
                iconCls: 'air2-icon-drag',
                disabled: true,
                storetotal: function (pg, all) {
                    this.setText('Drag all (' + all + ')');
                    this.setDisabled(all < 1);
                }
            },
            {
                text: 'Select page (0)',
                disabled: true,
                storetotal: function (pg, all) {
                    this.setText('Select page (' + pg + ')');
                    this.setDisabled(pg < 1);
                },
                handler: function () {
                    dv.select(dv.getNodes());
                }
            },
            {
                text: 'Unselect All',
                disabled: true,
                dvnumsel: function (num) {
                    this.setDisabled(num < 1);
                },
                handler: function () {
                    dv.clearSelections();
                }
            }
        ]
    });

    // primary dataview display
    store = new AIR2.UI.APIStore({
        url: AIR2.Bin.URL + '/srcsub.json',
        data: AIR2.Bin.SRCDATA,
        listeners: {load: ctrls.storeload}
    });

    xtpl.store = store;

    pager = new Ext.PagingToolbar({
        store: store,
        cls: 'air2-paging-editor-pager',
        displayInfo: true,
        pageSize: 15,
        prependButtons: true
    });

    dv = new AIR2.UI.DataView({
        cls: 'content-dv',
        store: store,
        tpl: xtpl,
        simpleSelect: true,
        multiSelect: true,
        selectedClass: 'air2-search-result-selected',
        itemSelector: '.item-row',
        listeners: {
            selectionchange: function (thisDv, selections) {
                var el, i;

                ctrls.selchange(thisDv, selections); //fix controls

                // fix checkboxes
                for (i = 0; i < this.all.elements.length; i++) {
                    el = this.all.elements[i];
                    Ext.fly(el).child('.drag-checkbox', true).checked =
                        (selections.indexOf(el) >= 0);
                }
            },
            afterrender: function (dv) {
                // stop default checkbox action (toggle)
                dv.getTemplateTarget().on('click', function (ev) {
                    if (ev.getTarget('.drag-checkbox')) {
                        ev.preventDefault();
                    }
                });
            },
            click: function (dv, idx, node, ev) {
                var ned, notesEl, rec;
                notesEl = ev.getTarget('.air2-bin-notes');

                // show editor
                if (notesEl &&
                    idx !== dv.editIdx &&
                    AIR2.Bin.BASE.authz.may_manage) {

                    dv.editIdx = idx;
                    Ext.fly(notesEl).update('');
                    rec = dv.getRecord(node);
                    ned = new Ext.form.TextArea({
                        autoCreate: {
                            tag: 'textarea',
                            autocomplete: 'off',
                            maxlength: '255'
                        },
                        renderTo: notesEl,
                        width: 340,
                        height: 35,
                        value: rec.data.bsrc_notes,
                        endEdit: function () {
                            var ch, el, sid;

                            rec.set('bsrc_notes', ned.getValue());
                            ned.destroy();

                            // optionally save
                            sid = rec.store.save();
                            if (sid > -1) {
                                el = Ext.fly(dv.getNode(idx));
                                ch = el.child('.r-excerpt .air2-bin-notes');
                                ch.update('').addClass('remote');
                            }
                            else {
                                dv.refreshNode(idx);
                            }
                            if (dv.editIdx === idx) {
                                delete dv.editIdx;
                            }
                        }
                    });
                    ned.on('blur', ned.endEdit);
                    ned.focus(false, 10);
                }
            }
        },
        // override for custom checkbox-selecting capability
        doMultiSelection: function (item, index, e) {
            // clicking only "does stuff" within the handle
            if (e.getTarget('.checkbox-handle')) {
                if (e.shiftKey && this.last !== false) {
                    this.selectRange(this.last, index, true); //keep existing
                } else {
                    if (this.isSelected(index)) {
                        this.deselect(index);
                    }
                    else {
                        this.select(index, true); //keep existing
                    }
                }
                e.preventDefault();
            }
        }
    });

    // filters
    filterbox = new Ext.form.TextField({
        width: 160,
        emptyText: 'Filter Contents',
        validationDelay: 500,
        queryParam: 'q',
        validateValue: function (v) {
            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-1, 2]);
                this.remoteAction.show();

                // reload the store
                dv.store.setBaseParam(this.queryParam, v);
                dv.store.on('load', function () {
                    this.remoteAction.hide();
                }, this, {single: true});
                pager.changePage(0);
                this.lastValue = v;
            }
        },
        lastValue: '',
        listeners: {
            render: function (p) {
                p.remoteAction = p.el.insertSibling({
                    cls: 'air2-form-remote-wait'
                });
            }
        }
    });
    ctrls.insert(0, filterbox);

    // actions
    actionbtn = new AIR2.UI.Button({
        text: 'Actions',
        iconCls: 'air2-icon-gear',
        disabled: !AIR2.Bin.BASE.authz.may_manage,
        menuHint: true,
        menu: {
            items: [{
                iconCls: 'air2-icon-tag-plus',
                text: 'Tag All',
                handler: function (b) {
                    AIR2.Bin.Tagger({
                        originEl: b.el,
                        binuuid: AIR2.Bin.UUID
                    });
                },
                // readers cannot tag - #4470
                hidden: !AIR2.Util.Authz.has('ACTION_ORG_SRC_UPDATE')
            }, {
                iconCls: 'air2-icon-annotation',
                text: 'Annotate All',
                handler: function (b) {
                    AIR2.Bin.Annotator({
                        originEl: b.el,
                        binuuid: AIR2.Bin.UUID
                    });
                }
            }, {
                iconCls: 'air2-icon-upload',
                text: 'Export',
                handler: function (b) {
                    var w = AIR2.Bin.Exporter({
                        originEl: b.el,
                        binuuid: AIR2.Bin.UUID
                    });
                    w.on('close', function () {
                        Ext.getCmp('air2-bin-exports').reload();
                    });
                }
            }, {
                iconCls: 'air2-icon-printer',
                text: 'Print-friendly',
                handler: function (b) {
                    var count, m, url;
                    count = AIR2.Bin.BASE.radix.src_count;
                    if (count > 1000) {
                        m = 'Print-friendly view supports up to 1000 ' +
                            'sources and this bin contains ' + count +
                            ' sources.<br/>Please remove some of the sources ' +
                            'from the bin and try again.';
                        AIR2.UI.ErrorMsg(b.el, 'Sorry!', m);
                    }
                    else {
                        url = AIR2.HOMEURL + '/bin/' + AIR2.Bin.UUID + '.phtml';
                        window.open(url, '_blank');
                    }
                }
            }]
        }
    });
    ctrls.add(actionbtn);

    // support article
    tip = AIR2.Util.Tipper.create(20978266);

    // create panel for dataview
    pnl = new AIR2.UI.Panel({
        colspan: 2,
        rowspan: 2,
        title: 'Bin Contents ' + tip,
        cls: 'air2-bin-contents',
        iconCls: 'air2-icon-sources',
        showTotal: true,
        showHidden: true,
        //tools: ['->', filterbox, '   ', actionbtn],
        items: [ctrls, dv],
        fbar: pager,
        listeners: {
            render: function () {
                AIR2.Bin.DragZone(pnl.el, dv);
            }
        }
    });

    // set the static totals
    // show unauthz total
    total = AIR2.Bin.SRCDATA.meta.total;
    hidden = AIR2.Bin.SRCDATA.meta.unauthz_total - total;
    str = Ext.util.Format.number(total, '0,000') + ' Sources';
    if (hidden > 0) {
        str += ' (' + Ext.util.Format.number(hidden, '0,000') + ' hidden)';
    }

    submTotal = AIR2.Bin.BASE.radix.subm_count;
    if (submTotal > 0) {
        str += ' - ' + Ext.util.Format.number(submTotal, '0,000') +
        ' Submissions';
    }
    pnl.setCustomTotal(str);
    return pnl;
};
