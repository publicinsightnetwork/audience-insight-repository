/***********************
 * Inquiry Summary Panel
 */
AIR2.Inquiry.Summary = function () {
    var dragMode,
        editMode;

    AIR2.Inquiry.CONTACTDV = AIR2.Inquiry.QuestionDataView(
        AIR2.Inquiry.QuestionDataView.CONTACTMODE
    );

    AIR2.Inquiry.PUBLICDV = AIR2.Inquiry.QuestionDataView(
        AIR2.Inquiry.QuestionDataView.PUBLICMODE
    );
    AIR2.Inquiry.PERMDV = AIR2.Inquiry.QuestionDataView(
        AIR2.Inquiry.QuestionDataView.PERMISSIONMODE
    );
    AIR2.Inquiry.PRIVATEDV = AIR2.Inquiry.QuestionDataView(
        AIR2.Inquiry.QuestionDataView.PRIVATEMODE
    );

    dragMode = function (doDrag) {
        if (doDrag) {
            AIR2.Inquiry.Summary.el.addClass('dragging');
        }
        else {
            AIR2.Inquiry.Summary.el.removeClass('dragging');
        }
    };

    editMode = function (doEdit) {
        if (doEdit) {
            AIR2.Inquiry.Summary.el.addClass('editing');
        }
        else {
            AIR2.Inquiry.Summary.el.removeClass('editing');
        }
    };

    // return panel
    AIR2.Inquiry.Summary = new AIR2.UI.Panel({
        cls:            'air2-inquiry-summary',
        colspan:        2,
        dragMode:       dragMode,
        iconCls:        'air2-icon-clipboard',
        id:             'air2-inquiry-summary',
        items: [
            AIR2.Inquiry.SUMQP,
            AIR2.Inquiry.CONTACTDV,
            AIR2.Inquiry.PUBLICDV,
            AIR2.Inquiry.PERMDV,
            AIR2.Inquiry.PRIVATEDV
        ],
        rowspan:        2,
        title:          'Query',
        width: 600
    });

    return AIR2.Inquiry.Summary;
};
