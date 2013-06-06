/***********************
 * Handle edit/delete clicks on regular-ol' dataview-rendered questions
 */
AIR2.Builder.questionClickHandler = function () {

    // add click handler
    AIR2.Builder.Main.on('render', function (cmp) {

        cmp.el.on('click', function (e) {
            var dv, node;

            // editing
            if (e.getTarget('.air2-rowedit')) {
                node = e.getTarget('.ques-row');
                dv   = AIR2.Builder.PUBLICDV;
                if (AIR2.Builder.PUBLICDV.indexOf(node) < 0) {
                    dv = AIR2.Builder.PRIVATEDV;
                }

                // start editor
                AIR2.Builder.questionEdit(dv, node);
            }

            // deleting
            if (e.getTarget('.air2-rowdelete')) {
                node = e.getTarget('.ques-row');
                dv   = AIR2.Builder.PUBLICDV;
                if (AIR2.Builder.PUBLICDV.indexOf(node) < 0) {
                    dv = AIR2.Builder.PRIVATEDV;
                }

                // start deleter
                AIR2.Builder.questionDelete(dv, node);
            }

        });

    });

};
