/***********************
 * Query Builder status/settings panel
 */
AIR2.Builder.Status = function () {

    // return panel
    AIR2.Builder.Status = new AIR2.UI.Panel({
        colspan:    1,
        title:      'Publish Settings',
        cls:        'air2-builder-status',
        iconCls:    'air2-icon-printer',
        html:       'hello<br/>world<br/>!<br/>.<br/>'
    });
    return AIR2.Builder.Status;
};
