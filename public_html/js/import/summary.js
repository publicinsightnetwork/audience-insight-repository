/***************
 * Import Summary Panel
 */
AIR2.Import.Summary = function () {
    var mayUpload,
        owner,
        panel,
        template,
        tools;

    // toolbar items
    tools = [];
    if (AIR2.Import.BASE.radix.tank_type === 'C') {
        mayUpload = false;
        owner = AIR2.Import.BASE.radix.User.user_uuid;
        if (AIR2.USERINFO.type === 'S' || AIR2.USERINFO.uuid === owner) {
            mayUpload = true;
        }
        tools = ['->', {
            xtype: 'air2button',
            air2type: 'CLEAR',
            iconCls: 'air2-icon-upload',
            hidden: !mayUpload,
            tooltip: 'Upload Window',
            handler: function () {
                var s, w;

                s = new AIR2.UI.APIStore({
                    url: AIR2.HOMEURL + '/csv.json',
                    data: AIR2.Import.CSVDATA
                });
                w = AIR2.Upload.Modal({
                    originEl: this.el,
                    tankRec: s.getAt(0)
                });
                w.on('close', function () {
                    panel.reload();
                });
            }
        }];
    }

    template = new Ext.XTemplate(
        '<tpl for="."><div class="summary">' +
            '<b class="title">{[AIR2.Format.tankName(values)]}</b>' +
            '<p class="notes">{tank_notes}</p>' +
            '<table class="air2-tbl">' +
                '<tr>' +
                    '<td class="label">Status</td>' +
                    '<td class="value">' +
                        '<b>{[AIR2.Format.tankStatus(values, 0, 1)]}</b>' +
                    '</td>' +
                '</tr>' +
                // if complete, allow Drag & Drop
                '<tpl if="tank_status === \'R\'">' +
                    '<tr>' +
                        '<td class="label"></td>' +
                        '<td class="value air2-dragzone" air2type="S" ' +
                        'air2tank="{tank_uuid}">' +
                            'Click here to drag to bin' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tr>' +
                    '<td class="label">Sources</td>' +
                    '<td class="value">{count_total}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label">Conflicts</td>' +
                    '<td class="value">{count_conflict}</td>' +
                '</tr>' +
                '<tpl if="count_error"><tr>' +
                    '<td class="label">Errors</td>' +
                    '<td class="value">{count_error}</td>' +
                    '</tr>' +
                '</tpl>' +
                '<tr>' +
                    '<td class="label">Imported by</td>' +
                    '<td class="value">' +
                        '{[AIR2.Format.userName(values.User,true)]}' +
                    '</td>' +
                '</tr>' +
                // CSV-upload specific
                '<tpl if="tank_type === \'C\'">' +
                    '<tr>' +
                        '<td class="label">Uploaded on</td>' +
                        '<td class="value">' +
                            '{[AIR2.Format.date(values.tank_cre_dtim)]}' +
                        '</td>' +
                    '</tr>' +
                    '<tr>' +
                        '<td class="label">File Size</td>' +
                        '<td class="value">' +
                            '{[this.formatFileSize(values)]}' +
                        '</td>' +
                    '</tr>' +
                    '<tr>' +
                        '<td class="label">File Link</td>' +
                        '<td class="value">' +
                            '<a href="{[this.fileLink()]}">Download CSV</a>' +
                        '</td>' +
                    '</tr>' +
                    '<tr>' +
                        '<td class="label">Upload Message</td>' +
                        '<td class="value">' +
                            '{[this.formatFileMsg(values)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
                // Formbuilder import specific
                '<tpl if="tank_type === \'F\'">' +
                    '<tr>' +
                        '<td class="label">Imported on</td>' +
                        '<td class="value">' +
                            '{[AIR2.Format.date(values.tank_cre_dtim)]}' +
                        '</td>' +
                    '</tr>' +
                '</tpl>' +
            '</table>' +
        '</div></tpl>',
        {
            compiled: true,
            disableFormats: true,
            formatFileSize: function (values) {
                var meta = Ext.decode(values.tank_meta);
                if (meta.file_size) {
                    return meta.file_size;
                }
                return 'Unknown';
            },
            formatFileMsg: function (values) {
                var meta = Ext.decode(values.tank_meta);
                if (meta.submit_message) {
                    return meta.submit_message;
                }
                return 'Unknown';
            },
            fileLink: function () {
                return AIR2.Import.URL + '/file';
            }
        }
    );


    // panel
    panel = new AIR2.UI.Panel({
        title: 'Summary',
        cls: 'air2-import-summary',
        iconCls: 'air2-icon-clipboard',
        colspan: 1,
        storeData: AIR2.Import.BASE,
        url: AIR2.Import.URL,
        itemSelector: '.summary',
        tools: tools,
        tpl: template
    });

    return panel;
};
