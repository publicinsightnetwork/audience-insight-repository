Ext.ns('AIR2.Project');
/***************
 * Project page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.Project = function () {
    var actv, annots, app, orgs, outs, refreshActv, summ, tags;

    annots = new AIR2.UI.AnnotationPanel({
        valueField: 'prjan_value',
        creField: 'prjan_cre_dtim',
        updField: 'prjan_upd_dtim',
        winTitle: 'Project Annotations',
        storeData: AIR2.Project.ANNOTDATA,
        url: AIR2.Project.URL + '/annotation',
        modalAdd: 'Add Annotation'
    });
    tags = new AIR2.UI.TagPanel({
        colspan: 1,
        title: 'Tags',
        iconCls: 'air2-icon-tag',
        storeData: AIR2.Project.TAGDATA,
        url: AIR2.Project.URL + '/tag',
        tagMasterUrl: AIR2.HOMEURL + '/tag',
        allowEdit: AIR2.Project.BASE.authz.may_write
    });

    // link panel refreshes to activity panel
    actv = AIR2.Project.Activity();
    refreshActv = function () {
        actv.reload();
    };
    summ = AIR2.Project.Summary();
    summ.store.on('save', refreshActv);
    orgs = AIR2.Project.Organizations();
    orgs.store.on('load', refreshActv);
    outs = AIR2.Project.Outcomes();
    outs.store.on('load', refreshActv);

    /* create the application */
    app = new AIR2.UI.App({
        items: new AIR2.UI.PanelGrid({
            items: [
                AIR2.Project.Submissions(),
                summ,
                AIR2.Project.Inquiries(),
                annots,
                orgs,
                AIR2.Project.Statistics(),
                outs,
                actv,
                tags
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-project',
        type: 'Project',
        typeLink: AIR2.HOMEURL + '/search/projects',
        title: AIR2.Project.BASE.radix.prj_display_name
    });
};
