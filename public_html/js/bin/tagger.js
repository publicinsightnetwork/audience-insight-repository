Ext.ns('AIR2.Bin.Tagger');

/**
 * Apply a tag to every source in a bin
 *
 * @function AIR2.Bin.Tagger
 * @cfg {String}      binuuid  (required)
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @return {AIR2.UI.Window}
 */
AIR2.Bin.Tagger = function (cfg) {
    var binfld, closebtn, tagbtn, tagfld, working, w;

    if (!cfg.binuuid || !cfg.binuuid.length) {
        alert("INVALID bin uuid for export");
        return false;
    }

    // bin display field
    binfld = new Ext.form.DisplayField({
        fieldLabel: 'Bin',
        cls: 'bin-display',
        ctCls: 'bborder',
        html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"></src>',
        plugins: {
            init: function () {
                Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/bin/' + cfg.binuuid + '.json',
                    callback: function (opts, success, resp) {
                        var data, msg, name, write;

                        data = Ext.util.JSON.decode(resp.responseText);
                        write = (data && data.authz) ? data.authz.may_write : 0;

                        if (success &&
                            data.success &&
                            data.radix.counts.src_read > 0 &&
                            write) {

                            name = '<b>' + data.radix.bin_name + '</b>' +
                                '<br/>(' + data.radix.src_count + ' sources)';
                            binfld.setValue(name);
                            tagbtn.enable();
                        }
                        else {
                            binfld.el.enableDisplayMode().hide();
                            if (data && data.message) {
                                msg = data.message;
                            }
                            else {
                                msg = 'Error: Invalid Bin!';
                            }
                            if (!write) {
                                msg = 'You don\'t have permission to write ';
                                msg += 'to this bin!';
                            }
                            else if (data &&
                                     data.radix &&
                                     data.radix.src_count < 1) {
                                msg = 'Error: Empty Bin!';
                            }
                            tagbtn.disable();
                        }
                    }
                });
            }
        },
        getValue: function () {
            return cfg.binuuid;
        }
    });

    // annotation field
    tagfld = new AIR2.UI.SearchBox({
        fieldLabel: 'Tag to apply',
        cls: 'air2-magnifier',
        autoCreate: {
            tag: 'input',
            type: 'text',
            autocomplete: 'off',
            maxlength: '32'
        },
        maskRe: /[a-zA-Z0-9 _\-\.]/,
        allowBlank: false,
        forceSelection: false,
        width: 220,
        searchUrl: AIR2.HOMEURL + '/tag',
        formatComboListItem: function (values) {
            var name, usage = '';

            name = AIR2.Format.tagName(values);
            name = name.replace(this.queryRegExp, '<b>' +
                this.queryString + '</b>');
            if (values.usage) {
                usage = " (" + values.usage + ")";
            }

            return name + usage;
        },
        formatToolTip: function (values) {
            var n;
            if (values.tm_type === 'I') {
                if (values.IptcMaster) {
                    n =  values.IptcMaster.iptc_name;
                }
                else {
                    n = values.iptc_master;
                }

                return 'ext:qtip="' + n + '"';
            }
            return '';
        },
        onSelect: function (rec, idx) {
            if (this.fireEvent('beforeselect', this, rec, idx) !== false) {
                this.setValue(AIR2.Format.tagName(rec.data));
                this.collapse();
                this.fireEvent('select', this, rec, idx);
                this.tagId   = rec.data.tm_id;
                this.tagName = AIR2.Format.tagName(rec.data);
            }
        },
        listeners: {
            beforequery: function (queryevent) {
                queryevent.query = this.getRawValue();
                this.tpl.queryString = queryevent.query;
                this.tpl.queryRegExp = new RegExp(queryevent.query, 'i');
            }
        }
    });

    // working display
    working = new Ext.form.DisplayField({
        cls: 'working',
        ctCls: 'tborder',
        html: '<b>Working...</b>'
    });

    // buttons
    tagbtn = new AIR2.UI.Button({
        air2type: 'BLUE',
        air2size: 'MEDIUM',
        text: 'Tag All',
        handler: function () {
            var binuuid, callback, f, val;

            f = w.get(0).getForm();
            if (f.isValid()) {
                // disable everything, and show the working text
                tagbtn.disable();
                closebtn.disable();
                f.items.each(function (item) {item.disable(); });
                if (!working.rendered) {
                    w.get(0).add(working);
                    w.get(0).doLayout();
                }

                // tag!
                binuuid = binfld.getValue();
                callback = function (radix, success, counts) {
                    var msg;

                    if (success) {
                        working.addClass('air2-icon-check');
                    }
                    else {
                        working.addClass('air2-icon-error');
                    }
                    msg = 'An error has occured';
                    if (success) {
                        msg = 'Tagged ' + counts.insert + ' sources (' +
                            counts.duplicate + ' duplicates)';
                    }
                    working.setValue(msg);

                    tagfld.enable().reset();
                    tagbtn.enable();
                    closebtn.enable();
                };

                // get value - string or tm_id
                val = tagfld.getValue();
                if (val === tagfld.tagName) {
                    AIR2.Drawer.API.tag(
                        binuuid,
                        {
                            tm_id: tagfld.tagId
                        },
                        callback
                    );
                }
                else {
                    AIR2.Drawer.API.tag(binuuid, val, callback);
                }
            }
        }
    });

    closebtn = new AIR2.UI.Button({
        air2type: 'CANCEL',
        air2size: 'MEDIUM',
        text: 'Close',
        handler: function () {w.close(); }
    });

    // create window
    w = new AIR2.UI.Window({
        title: 'Tag Bin Sources',
        cls: 'air2-bin-annotator', //steal style
        iconCls: 'air2-icon-tagadd',
        closeAction: 'close',
        width: 350,
        height: 265,
        formAutoHeight: true,
        items: {
            xtype: 'form',
            unstyled: true,
            labelWidth: 75,
            labelAlign: 'right',
            defaults: {
                width: 240,
                msgTarget: 'under'
            },
            items: [binfld, tagfld],
            bbar: [tagbtn, ' ', closebtn]
        }
    });

    // show and return
    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }

    return w;
};
