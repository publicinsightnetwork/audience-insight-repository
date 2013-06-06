Ext.ns('AIR2.Bin.Annotator');

/**
 * Apply an annotation to every source in a bin
 *
 * @function AIR2.Bin.Annotator
 * @cfg {String}      binuuid  (required)
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @return {AIR2.UI.Window}
 */
AIR2.Bin.Annotator = function (cfg) {
    if (!cfg.binuuid || !cfg.binuuid.length) {
        alert("INVALID bin uuid for annotating");
        return false;
    }

    var annotbtn, annottxt, binfld, closebtn, w, working;

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

                        if (data && data.authz) {
                            write = data.authz.may_write;
                        }
                        else {
                            write = 0;
                        }

                        if (success &&
                            data.success &&
                            data.radix.counts.src_update > 0 &&
                            write) {

                            name = '<b>' + data.radix.bin_name + '</b>' +
                                '<br/>(' + data.radix.counts.src_update +
                                ' writeable sources)';

                            binfld.setValue(name);
                            annotbtn.enable();
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
                                msg = 'You don\'t have permission to write ' +
                                'to this bin!';
                            }
                            else if (data &&
                                     data.radix &&
                                     data.radix.src_count < 1) {

                                msg = 'Error: Empty Bin!';
                            }
                            else if (data &&
                                     data.radix &&
                                    data.radix.counts.src_update < 1) {
                                msg = 'You don\'t have permission to write ' +
                                'to any sources in this bin!';
                            }

                            annotbtn.disable();
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
    annottxt = new Ext.form.TextArea({
        fieldLabel: 'Annotation',
        allowBlank: false
    });

    // working display
    working = new Ext.form.DisplayField({
        cls: 'working',
        ctCls: 'tborder',
        html: '<b>Working...</b>'
    });

    // buttons
    annotbtn = new AIR2.UI.Button({
        air2type: 'BLUE',
        air2size: 'MEDIUM',
        text: 'Annotate All',
        handler: function () {
            var binuuid, callback, f;

            f = w.get(0).getForm();

            if (f.isValid()) {
                // disable everything, and show the working text
                annotbtn.disable();
                closebtn.disable();
                f.items.each(function (item) {item.disable(); });
                w.get(0).add(working);
                w.get(0).doLayout();

                // annotate!
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
                        msg = 'Annotated ' + counts.insert + ' sources';
                    }
                    working.setValue(msg);
                    annotbtn.hide();
                    closebtn.enable().setText('Close');
                };
                AIR2.Drawer.API.annotate(binuuid,
                                         annottxt.getValue(),
                                         callback);
            }
        }
    });
    closebtn = new AIR2.UI.Button({
        air2type: 'CANCEL',
        air2size: 'MEDIUM',
        text: 'Cancel',
        handler: function () {w.close(); }
    });

    // create window
    w = new AIR2.UI.Window({
        title: 'Annotate Bin Sources',
        cls: 'air2-bin-annotator', //steal style
        iconCls: 'air2-icon-annotation',
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
            items: [binfld, annottxt],
            bbar: [annotbtn, ' ', closebtn]
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
