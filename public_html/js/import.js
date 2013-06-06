Ext.ns('AIR2.Import');
/***************
 * Import page
 *
 * Starting page for the Discriminator UI.  Lists a single tank record, and all
 * of it's tank_sources.
 */
AIR2.Import = function () {
    var app, sources, summary;

    // link panels together, to refresh counts (when something is resolved)
    sources = AIR2.Import.Sources();
    summary = AIR2.Import.Summary();

    sources.on('resolved',
        function () {
            summary.store.on('load',
                function (s, rs) {
                    var confl, rec, total;

                    rec = rs[0];
                    total = rec.data.count_total;
                    confl = rec.data.count_conflict;
                    if (confl === 1) {
                        confl += ' Conflict';
                    }
                    else {
                        confl += ' Conflicts';
                    }
                    sources.setCustomTotal(total + ' Sources | ' + confl);
                },
                this,
                {single: true}
            );
            summary.reload();
        }
    );

    /* create the application */
    app = new AIR2.UI.App({
        id: 'air2-app',
        items: new AIR2.UI.PanelGrid({
            items: [
                sources,
                summary,
                AIR2.Import.Activity()
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-import',
        type: 'Import',
        title: AIR2.Import.BASE.radix.tank_name
    });
};
