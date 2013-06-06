/***************
 * Source response set annotation handler for the reader
 */
AIR2.Reader.srsanHandler = function (dv) {

    // helper to create an annotations window
    var makeWindow = function (url, maywrite) {
        var template, w;

        template = new Ext.XTemplate(
            '<table class="air2-annotation air2-tbl">' +
                '<tpl for=".">' +
                    '<tr class="annot-row">' +
                    // photo and info
                    '<td>' +
                      '<table class="who air2-corners">' +
                        '<tr>' +
                            '<td class="photo">{[AIR2.Format.userPhoto(values.CreUser,50)]}</td>' +
                            '<td class="info">' +
                                '<b>{[AIR2.Format.userName(values.CreUser,1,1)]}</b>' +
                                '{[this.moreInfo(values.CreUser)]}' +
                            '</td>' +
                        '</tr>' +
                      '</table>' +
                    '</td>' +
                    
                    // text value
                    
                    '<td class="text">' +
                      '<p>{srsan_value}</p>' +
                      '<div class="meta">' +
                        '{[this.postdate(values)]}' +
                      '</div>' +
                    '</td>' +

                    // edit buttons

                    '<td class="row-ops">' +
                      '<button class="air2-rowedit"></button>' +
                      '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                    '</tr>' +
                '</tpl>' +
            '</table>',

            {
  
                compiled: true,
                disableFormats: true,
  
                moreInfo: function(usr) {
                    var str = '';

                    if (usr.user_type == 'S') {
                        str += '<p>System User</p>';
                    }
                    else {
                        if (usr.UserOrg && usr.UserOrg.length) {
                            var title = usr.UserOrg[0].uo_user_title;
                            if (title) {
                                str += '<p>'+title+'</p>';
                            }  
                            var org = AIR2.Format.userOrgShort(usr.UserOrg[0],1);
                            str += '<div class="room">'+org+'</div>';
                        }
                    }

                    return str;
                },
  
                postdate: function(v) {
                    if (v.srsan_upd_dtim > v.srsan_cre_dtim)
                        return 'Updated ' + AIR2.Format.dateLong(v.srsan_upd_dtim);
                    else
                        return 'Posted ' + AIR2.Format.dateLong(v.srsan_cre_dtim);
                }
            }
        );

        w = new AIR2.UI.Window({
            title: 'Submission Annotations',
            allowAdd: maywrite,
            items: {
                xtype: 'air2pagingeditor',
                url: url,
                multiSort: 'srsan_cre_dtim desc',
                newRowDef: {CreUser: AIR2.Reader.USER},
                allowEdit: function (rec) {
                    var cre;

                    if (!maywrite) {
                        return false;
                    }
                    if (rec.phantom) {
                        return true;
                    }

                    cre = rec.data.CreUser.user_uuid;
                    return (AIR2.USERINFO.uuid == cre);
                },
                allowDelete: function (rec) {
                    var cre;

                    if (!maywrite) {
                        return false;
                    }

                    if (rec.phantom) {
                        return true;
                    }
                    cre = rec.data.CreUser.user_uuid;
                    return (AIR2.USERINFO.uuid == cre);
                },
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                itemSelector: '.annot-row',
                tpl: template,
                editRow: function (dv, node, rec) {
                    var text, textEl;

                    textEl = Ext.fly(node).first('td.text');
                    textEl.update('').setStyle('padding', '6px 4px');
                    text = new Ext.form.TextArea({
                        grow: false,
                        renderTo: textEl,
                        value: rec.data.srsan_value,
                        height: 75,
                        width: 400
                    });
                    return [text];
                },
                saveRow: function (rec, edits) {
                    rec.set('srsan_value', edits[0].getValue());
                }
            }
        });
        Logger(template);
        return w;
    };

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {

        // expand/add clicked
        dv.el.on('click', function (e) {
            var fireAdd, s, userMayWrite, xpandr;

            xpandr = e.getTarget('a.add-srsan', 5, true);
            if (xpandr) {
                e.preventDefault();
                fireAdd = e.getTarget('span.add') ? true : false;
                userMayWrite = true; //TODO: is this true?

                // create on first run
                if (!xpandr.win) {
                    xpandr.win = makeWindow(
                        xpandr.getAttribute('href'),
                        userMayWrite
                    );
                    xpandr.win.on('hide', function (w) {
                        s = w.items.items[0].store;
                        xpandr.child('.ann-total').update(s.getTotalCount());
                    });
                }

                // allow starting in "add" mode
                xpandr.win.show(xpandr, function (win) {
                    if (fireAdd) {
                        win.fireEvent('addclicked', win);
                    }
                });

            }

        });

    });

};
