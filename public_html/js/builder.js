Ext.ns('AIR2.Builder');
/***************
 * Query Builder page
 *
 */
AIR2.Builder = function () {
    var app, items;

    // the stores
    AIR2.Builder.INQSTORE = new AIR2.UI.APIStore({
        data: AIR2.Builder.INQDATA,
        url:  AIR2.Builder.INQURL + '.json'
    });
    AIR2.Builder.QUESSTORE = new AIR2.UI.APIStore({
        data: AIR2.Builder.QUESDATA,
        url:  AIR2.Builder.QUESURL + '.json',
        // sorter function to put questions in the right order
        sorter: function (aRec, bRec) {
            var a = aRec.data, b = bRec.data;
            if (a.ques_public_flag !== b.ques_public_flag) {
                return b.ques_public_flag - a.ques_public_flag;
            }
            if (a.ques_dis_seq !== b.ques_dis_seq) {
                return a.ques_dis_seq - b.ques_dis_seq;
            }
            if (aRec.dirty || bRec.dirty && (aRec.dirty !== bRec.dirty)) {
                return bRec.dirty - aRec.dirty;
            }
            return a.ques_cre_dtim - b.ques_cre_dtim;
        },
        // override sort to use our custom sorter
        sort: function () {
            this.data.sort('ASC', AIR2.Builder.QUESSTORE.sorter);
            if (this.snapshot && this.snapshot !== this.data) {
                this.snapshot.sort('ASC', AIR2.Builder.QUESSTORE.sorter);
            }
            this.fireEvent('datachanged', this);
        },
        // fix the display sequence, and sort everything (no saving)
        fixSequence: function () {
            this.sort();

            // fix any overlaps
            var last = null;
            this.each(function (r) {
                if (last !== null && r.get('ques_dis_seq') <= last) {
                    r.set('ques_dis_seq', last + 1);
                }
                last = r.get('ques_dis_seq');
            });
        },
        // check if records are adjacent in this order
        isAdjacentOrdered: function (rec1, rec2) {
            var idx1 = this.indexOf(rec1),
                idx2 = this.indexOf(rec2);
            if (idx1 > -1 && idx2 > -1) {
                return (idx1 + 1) === idx2;
            }
            return false;
        }
    });

    // the panels
    items = [
        AIR2.Builder.Main(),
        AIR2.Builder.Status(),
        AIR2.Builder.Templates()
    ];

    /* create the application */
    app = new AIR2.UI.App({
        id: 'air2-app',
        items: new AIR2.UI.PanelGrid({
            items: items
        })
    });
    app.setLocation({
        iconCls: 'air2-icon-inquiry',
        type: 'Query Builder',
        typeLink: AIR2.HOMEURL + '/search/queries',
        title: AIR2.Builder.INQDATA.radix.inq_ext_title
    });

};
