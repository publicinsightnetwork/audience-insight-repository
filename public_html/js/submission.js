Ext.ns('AIR2.Submission');
/***************
 * Submission page
 */
AIR2.Submission = function () {
    var annotPanel,
        app,
        dd1,
        fullname,
        locinfo,
        rspPanel,
        src,
        srcPanel,
        srcuuid,
        srsuuid,
        tagPanel;

    annotPanel = new AIR2.UI.AnnotationPanel({
        valueField: 'srsan_value',
        creField: 'srsan_cre_dtim',
        updField: 'srsan_upd_dtim',
        winTitle: 'Submission Annotations',
        storeData: AIR2.Submission.ANNOTDATA,
        url: AIR2.Submission.URL + '/annotation',
        modalAdd: 'Add Annotation'
    });

    tagPanel = new AIR2.UI.TagPanel({
        colspan: 1,
        title: 'Tags',
        iconCls: 'air2-icon-tag',
        storeData: AIR2.Submission.TAGDATA,
        url: AIR2.Submission.URL + '/tag',
        tagMasterUrl: AIR2.HOMEURL + '/tag',
        allowEdit: AIR2.Submission.BASE.authz.may_write
    });

    rspPanel = AIR2.Submission.Responses();

    srcPanel = AIR2.Submission.Source();

    /* create the application */
    app = new AIR2.UI.App({
        columnLayout: '21',
        items: new AIR2.UI.PanelGrid({
            items: [
                rspPanel,
                srcPanel,
                annotPanel,
                tagPanel
            ]
        })
    });

    src = AIR2.Submission.SRCDATA.radix;
    src = (src.length) ? src[0] : src;
    fullname = AIR2.Format.sourceFullName(src, true);
    srcuuid = AIR2.Submission.SRCDATA.radix.src_uuid;
    srsuuid = AIR2.Submission.UUID;
    locinfo = {
        iconCls: 'air2-icon-responses',
        type: 'Submission',
        typeLink: AIR2.HOMEURL + '/search/responses',
        title: fullname
    };

    // enable D&D (even if they cannot READ the source)
    dd1 = srcPanel.el.child('.header-title');
    dd1.addClass('air2-dragzone air2-icon');
    dd1.set({air2type: 'S', air2uuid: srcuuid});
    locinfo.ddUUID = srsuuid;
    locinfo.ddType = 'S';
    locinfo.ddRelType = 'S';
    app.setLocation(locinfo);

    // mark this submission as "read"
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/reader/read/' + srsuuid + '.json'
    });
};
