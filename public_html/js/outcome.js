Ext.ns('AIR2.Outcome');
/***************
 * Outcome page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.Outcome = function () {
    var app, t, annots, tags;

    annots = new AIR2.UI.AnnotationPanel({
        valueField: 'oa_value',
        creField: 'oa_cre_dtim',
        updField: 'oa_upd_dtim',
        winTitle: 'Outcome Annotations',
        storeData: AIR2.Outcome.ANNOTDATA,
        url: AIR2.Outcome.URL + '/annotation',
        modalAdd: 'Add Annotation'
    });

    tags = new AIR2.UI.TagPanel({
        colspan: 1,
        title: 'Tags',
        iconCls: 'air2-icon-tag',
        storeData: AIR2.Outcome.TAGDATA,
        url: AIR2.Outcome.URL + '/tag',
        tagMasterUrl: AIR2.HOMEURL + '/tag',
        allowEdit: AIR2.Outcome.BASE.authz.may_write
    });

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            columnLayout: '21',
            items: [
                AIR2.Outcome.Summary(),
                AIR2.Outcome.Projects(),
                AIR2.Outcome.Sources(),
                AIR2.Outcome.Inquiries(), 
                annots,
                tags
            ]
        })
    });

    t = Ext.util.Format.ellipsis(
        AIR2.Outcome.BASE.radix.out_headline,
        60,
        true
    );

    app.setLocation({
        iconCls: 'air2-icon-outcome',
        type: 'PINfluence',
        title: t
    });
};
