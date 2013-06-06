/***************
 * Source response annotation handler for the reader
 */
AIR2.Reader.sranHandler = function (dv) {

    // sran template
    var sranTpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="anns clearfix anns-row ' +
            '<tpl if="values.hidden">hide</tpl>">' +
                '<div class="ann-author">{CreUser:air.userPhoto(0,0,1)}</div>' +
                '<div class="ann">' +
                    '<h4>' +
                        '{CreUser:air.userName(1,1)} ' +
                        '<span>{CreUser:air.userOrgLong(0)}</span>' +
                    '</h4>' +
                    '<p>{sran_value:nl2br}</p>' +
                    '<tpl if="values.sran_cre_dtim">' +
                        '<div class="ann-posted">' +
                            'Posted {sran_cre_dtim:air.datePost} ' +
                            '<tpl if="mayedit">' +
                                '<button class="ann-edit">Edit</button> ' +
                                '<button class="ann-save">Save</button> ' +
                                '<button class="ann-cancel">Cancel</button> ' +
                            '</tpl>' +
                            '<tpl if="maydelete">' +
                                '<button class="ann-delete">Delete</button>' +
                            '</tpl>' +
                        '</div>' +
                    '</tpl>' +
                '</div>' +
            '</div>' +
        '</tpl>' +
        // add annotation
        '<div class="anns clearfix">' +
            '<div class="ann-author">' +
                '{AIR2.Reader.USER:air.userPhoto(0,0,1)}' +
            '</div>' +
            '<div class="ann">' +
                '<h4>' +
                    '{AIR2.Reader.USER:air.userName(1,1)} ' +
                    '<span>{AIR2.Reader.USER.org_display_name}</span>' +
                '</h4>' +
                '<textarea></textarea>' +
                '<button class="ann-post">Post</button>' +
            '</div>' +
        '</div>',
        {
            compiled: true
        }
    );

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {

        // expand/add clicked
        dv.el.on('click', function (e) {
            if (e.getTarget('a.sran-expand')) {
                e.preventDefault();
                var xpandr = e.getTarget('a.sran-expand', 5, true);

                // check for already-expanded
                if (xpandr.dv && xpandr.dv.isVisible()) {
                    xpandr.dv.hide();
                }
                else {
                    var parent = xpandr.parent().parent();
                    var edits = Ext.select('.edit', false, parent.dom).elements;
                    Ext.each(edits, function (edit, index) {
                        edit = Ext.get(edit);
                        if (edit.dv) {
                            edit.dv.hide();
                        }
                    });
                    var showOriginal = Ext.select('.orig', false, parent.dom).elements[0];
                    showOriginal = Ext.get(showOriginal);
                    if(showOriginal && showOriginal.dv) {
                        showOriginal.dv.hide();
                        showOriginal.first().dom.innerHTML = 'Show Original';
                    }
                    if (!xpandr.dv) {
                        xpandr.dv = new AIR2.UI.JsonDataView({
                            renderTo:     xpandr.parent().parent().parent(),
                            renderEmpty:  true,
                            tpl:          sranTpl,
                            cls:          'anns-ct',
                            itemSelector: '.anns-row',
                            sort:         'sran_cre_dtim desc',
                            sortInfo: {
                                field: 'sran_cre_dtim',
                                direction: 'DESC' 
                            },
                            url:          xpandr.getAttribute('href'),
                            baseParams:   {
                                limit: 99,
                                sort: 'sran_cre_dtim desc'
                            },
                            // create a new response annotation
                            addAnnotation: function (xpdv, val) {
                                Logger("Add annotation");
                                var rec = new xpdv.store.recordType({
                                    CreUser: AIR2.Reader.USER,
                                    sran_value: val
                                });
                                foo = xpdv.store;

                                xpdv.store.insert(0, rec);
                                xpdv.store.save();

                                
                                
                            },
                            // change the annotations count
                            changeCount: function (num) {
                                var c, cEl;

                                cEl = xpandr.child('.sran-count');
                                c = parseInt(cEl.dom.innerHTML, 10);
                                if (num === '++') {
                                    cEl.dom.innerHTML = (c + 1);
                                }
                                else if (num === '--') {
                                    cEl.dom.innerHTML = (c - 1);
                                }
                                else {
                                    cEl.dom.innerHTML = num;
                                }
                            },
                            // indicate when a node should be rendered hidden
                            collectData: function (recs, sIdx) {
                                var data, i, usr;

                                data =
                            AIR2.UI.JsonDataView.superclass.collectData.call(
                                        this,
                                        recs,
                                        sIdx
                                    );
                                usr = AIR2.USERINFO.uuid;
                                for (i = 0; i < data.length; i++) {
                                    data[i].hidden = (
                                        recs[i].phantom ||
                                        recs.length > 1
                                    );

                                    if (recs[i].phantom) {
                                        data[i].phantom = true;
                                    }
                                    else {
                                        data[i].phantom = false;
                                    }

                                    if (recs[i].stale) {
                                        data[i].stale = true;
                                    }
                                    else {
                                        data[i].stale = false;
                                    }

                                    data[i].mayedit = (
                                        recs[i].phantom ||
                                        recs[i].data.CreUser.user_uuid == usr
                                    );

                                    data[i].maydelete = (
                                        !recs[i].phantom &&
                                        recs[i].data.CreUser.user_uuid == usr
                                    );
                                }
                                return data;
                            },
                            // show a spinner when remote-loading annotations
                            onBeforeLoad: function () {
                                var c, superClass;

                                superClass = AIR2.UI.JsonDataView.superclass;
                                superClass.onBeforeLoad.call(this);

                                c = parseInt(
                                    xpandr.child('.sran-count').dom.innerHTML
                                );

                                if (c > 0) {
                                    xpandr.next('.spinner').show();
                                }
                            },
                            // hide spinner and slide in loaded annotations
                            onDataChanged: function () {
                                xpandr.next('.spinner').hide();
                                this.onAdd(
                                    this.store,
                                    this.store.getRange(),
                                    0
                                );
                                this.all.slideIn('t');
                            },
                            // animate in when a new annotation is added
                            onAdd: function (ds, records, index) {
                                AIR2.UI.JsonDataView.superclass.onAdd.call(
                                    this,
                                    ds,
                                    records,
                                    index
                                );

                            },
                            // animate out when an annotation is removed
                            onRemove: function (ds, record, index) {
                                if (index === 0) {
                                    this.all.item(index).next().setStyle(
                                        'margin-top',
                                        '10px'
                                    );
                                }
                                this.all.item(index).slideOut(
                                    't',
                                    {remove: true}
                                );

                                this.all.removeElement(index);
                                this.updateIndexes(index);
                            },
                            // create/edit/delete click handlers
                            listeners: {
                                click: function (xpdv, idx, node, e) {
                                    var rec, row, val;

                                    if (e.getTarget('.ann-edit')) {
                                        rec = xpdv.store.getAt(idx);
                                        row = Ext.fly(node).addClass('editing');
                                        row.textFld = new Ext.form.TextArea({
                                            grow: false,
                                            height: 30,
                                            width: '100%',
                                            allowBlank: false,
                                            renderTo: row.child('p').update(''),
                                            value: rec.data.sran_value
                                        });
                                        dv.addClass('edit-lock');
                                    }
                                    else if (e.getTarget('.ann-delete')) {
                                        rec = xpdv.store.getAt(idx);
                                        xpdv.store.remove(rec);
                                        xpdv.store.save();
                                        xpdv.changeCount('--');
                                    }
                                    else if (e.getTarget('.ann-save')) {
                                        val = Ext.fly(node).textFld.getValue();
                                        if (val && val.length) {
                                            rec = xpdv.store.getAt(idx);
                                            rec.set('sran_value', val);
                                            xpdv.store.save();
                                        }
                                        xpdv.refreshNode(idx);
                                        dv.removeClass('edit-lock');
                                    }
                                    else if (e.getTarget('.ann-cancel')) {
                                        xpdv.refreshNode(idx);
                                        dv.removeClass('edit-lock');
                                    }
                                },
                                containerclick: function (xpdv, e) {
                                    var postEl, txt;
                                    postEl = e.getTarget('.ann-post', 5, true);
                                    if (postEl) {
                                        e.preventDefault();
                                        txt = postEl.prev('textarea');
                                        if (txt.getValue()) {
                                            xpdv.addAnnotation(
                                                xpdv,
                                                txt.getValue()
                                            );
                                            txt.dom.value = '';
                                            xpdv.changeCount('++');
                                        }
                                    }
                                }
                            }
                        });
                    }
                    xpandr.dv.show();

                    // focus textarea
                    if (e.getTarget('.sran-add')) {
                        xpandr.dv.el.child('textarea').focus(10);
                    }

                }
            }
        });

    });

};
