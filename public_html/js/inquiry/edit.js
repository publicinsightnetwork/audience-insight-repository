/***************
 * Query edit tab
 *
 *
 * AIR2.Inquiry.Edit
 *
 */

AIR2.Inquiry.Edit = function () {

    AIR2.Inquiry.Editor = new AIR2.UI.PanelGrid({
        autoHeight: true,
        columnLayout: '21',
        items: [
            AIR2.Inquiry.EditView(),
            AIR2.Inquiry.EditTabView()
        ],
        title: 'Edit Query'
    });

    return AIR2.Inquiry.Editor;

};
