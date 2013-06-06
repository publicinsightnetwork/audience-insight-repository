Ext.ns('AIR2.Source');
/***************
 * Source page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */

AIR2.Source = function () {
    var actv,
        annots,
        app,
        contact,
        exper,
        facts,
        inter,
        orgs,
        outs,
        refreshActv,
        subm,
        tags;

    // constant for lock-icon
    AIR2.Source.LOCK = false;
    if (AIR2.Source.BASE.radix.src_has_acct === 'Y') {
        AIR2.Source.LOCK =
           '<span class="air2-source-locked" ext:qtip="Account Locked"></span>';
    }

    annots = new AIR2.UI.AnnotationPanel({
        colspan: 2,
        valueField: 'srcan_value',
        creField: 'srcan_cre_dtim',
        updField: 'srcan_upd_dtim',
        winTitle: 'Source Annotations',
        storeData: AIR2.Source.ANNOTDATA,
        url: AIR2.Source.URL + '/annotation',
        modalAdd: 'Add Annotation'
    });
    tags = new AIR2.UI.TagPanel({
        colspan: 1,
        title: 'Tags',
        iconCls: 'air2-icon-tag',
        storeData: AIR2.Source.TAGDATA,
        url: AIR2.Source.URL + '/tag',
        tagMasterUrl: AIR2.HOMEURL + '/tag',
        allowEdit: AIR2.Source.BASE.authz.unlock_write //ignore lock
    });

    // link panel refreshes to activity panel
    actv = AIR2.Source.Activity();
    refreshActv = function () {
        actv.reload();
    };
    contact = AIR2.Source.Contact();
    contact.store.on('load', refreshActv);
    facts = AIR2.Source.Facts();
    facts.store.on('load', refreshActv);
    subm = AIR2.Source.Submissions();
    subm.on('addsubmission', refreshActv);
    exper = AIR2.Source.Experiences();
    exper.store.on('load', refreshActv);
    inter = AIR2.Source.Interests();
    inter.store.on('load', refreshActv);
    orgs = AIR2.Source.Organizations();
    orgs.store.on('load', function () {
        refreshActv();
        contact.reload();
    });
    outs = AIR2.Source.Outcomes();
    var prefs = AIR2.Source.Preferences();

    /* create the application */
    app = new AIR2.UI.App({
        id: 'air2-app',
        items: new AIR2.UI.PanelGrid({
            items: [
                contact,
                facts,
                orgs,
                exper,
                subm,
                inter,
                actv,
                outs,
                annots,
                tags,
                prefs
            ]
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-source',
        type: 'Source',
        typeLink: AIR2.HOMEURL + '/search/active-sources',
        title: AIR2.Format.sourceTitledName(AIR2.Source.BASE.radix),
        ddUUID: AIR2.Source.UUID
    });
};
