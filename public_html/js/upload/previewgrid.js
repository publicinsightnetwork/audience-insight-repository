Ext.ns('AIR2.Upload');
/***************
 * Upload Preview Grid
 *
 * An Ext.grid.GridPanel that previews parsing a csv upload
 *
 * @event afterpreview(<success>, <response>)
 */
AIR2.Upload.PreviewGrid = function () {
    var errors,
        panel,
        pgrid,
        status,
        store;

    errors = new Ext.BoxComponent({
        cls: 'upload-status warning',
        hideMode: 'visibility',
        hidden: true,
        showError: function (str) {
            errors.update(str);
            errors.show();
        },
        hideError: function () {
            errors.hide();
        }
    });
    status = new Ext.BoxComponent({
        cls: 'file-info',
        html: 'File name:',
        setFile: function (name, size) {
            if (!status.rendered) {
                status.on('afterrender', function () {
                    status.setFile(name, size);
                }, this, {single: true});
            }
            else {
                status.update(
                    'File name: <b>' + name + '</b> | File size: <b>' +
                    size + '</b>'
                );
            }
        }
    });

    // setup apistore (don't load fake url)
    store = new AIR2.UI.APIStore({
        url: AIR2.HOMEURL + '/csv/FAKEURL/preview.json',
        autoLoad: false,
        baseParams: {
            limit: 4
        },
        // override for custom error display
        handleAIRException: function (proxy, type, action, opt, rsp, arg) {
            var json, msg;

            msg = 'Encountered a server error';
            json = Ext.decode(rsp.responseText);
            if (json && json.message) {
                msg = json.message;
            }
            errors.showError(msg);
            pgrid.reset();
            panel.fireEvent('afterpreview', false, json);
        },
        listeners: {
            beforeload: function () {
                errors.hideError();
                if (pgrid.loadMask && pgrid.loadMask.show) {
                    pgrid.loadMask.show();
                }
            },
            load: function (s, rs) {
                if (pgrid.loadMask && pgrid.loadMask.hide) {
                    pgrid.loadMask.hide();
                }

                pgrid.reconfigureGrid(s);
                if (s.reader.jsonData.message) {
                    errors.showError(s.reader.jsonData.message);
                    panel.fireEvent('afterpreview', false, rs);
                }
                else {
                    panel.fireEvent('afterpreview', true, rs);
                }
            }
        }
    });

    pgrid = new Ext.grid.GridPanel({
        store: new Ext.data.ArrayStore({autoDestroy: true}),
        columns: [
            {header: 'Column 1'},
            {header: 'Column 2'},
            {header: 'Column 3'},
            {header: 'Column 4'}
        ],
        stripeRows: true,
        enableHdMenu: false,
        disableSelection: true,
        enableColumnHide: false,
        enableColumnMove: false,
        loadMask: true,
        height: 155,
        width: 630,
        reset: function () {
            Logger("RESET");

            this.reconfigure(
                new Ext.data.ArrayStore({autoDestroy: true}),
                new Ext.grid.ColumnModel({
                    columns: [
                        {header: 'Column 1'},
                        {header: 'Column 2'},
                        {header: 'Column 3'},
                        {header: 'Column 4'}
                    ]
                })
            );
        },
        /* load a preview */
        loadPreview: function (uuid, alreadyValid) {
            store.proxy.setUrl(AIR2.HOMEURL + '/csv/' + uuid + '/preview.json');
            store.load();
        },
        /* helper function to define a preview column */
        reconfigureGrid: function (s) {
            var cdefs, invalids;

            cdefs = [];
            this.hasInvalidHeaders = false;
            invalids = s.reader.meta.invalid_headers;
            if (!invalids || !invalids.length) {
                invalids = [];
            }

            // process fields
            s.fields.each(function (item, idx) {
                var h = item.name;
                if (invalids.indexOf(h) > -1) {
                    h = '<b style="color:red;font-style:italic;">' + h + '</b>';
                    this.hasInvalidHeaders = true;
                }
                cdefs.push({header: h, dataIndex: item.name});
            });

            // reconfigure the preview grid
            this.reconfigure(s, new Ext.grid.ColumnModel({columns: cdefs}));
            this.autoSizeColumns(s.getCount(), cdefs.length);
        },
        /* auto-size the columns based on content */
        autoSizeColumns: function (numRows, numCols) {
            var col,
                el,
                hdr,
                row,
                width;

            for (col = 0; col < numCols; col++) {
                width = 0;
                for (row = 0; row < numRows; row++) {
                    el = this.view.getCell(row, col);
                    width = Math.max(
                        width,
                        Ext.fly(el.firstChild).getTextWidth()
                    );
                }

                // check against the header widths
                hdr = this.view.getHeaderCell(col);
                width = Math.max(width, Ext.fly(hdr.firstChild).getTextWidth());

                // check minimum and maximum col width
                width = width + 14; //pad
                width = Math.max(width, 50); //min 50
                width = Math.min(width, 150); //max 150
                this.colModel.setColumnWidth(col, width);
            }
        }
    });

    panel = new Ext.Container({
        cls: 'upload-preview',
        items: [errors, status, pgrid]
    });

    panel.on('show', function () {
        var meta, rec, uuid;

        rec = panel.ownerCt.tankRec;
        uuid = rec.data.tank_uuid;
        meta = Ext.decode(rec.data.tank_meta);
        status.setFile(rec.data.tank_name, meta.file_size);
        pgrid.loadPreview(uuid, meta.valid_header);
    });

    return panel;
};
