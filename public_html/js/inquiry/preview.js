/***********************
 * Inquiry Summary Panel
 */
AIR2.Inquiry.Preview = function () {
    var dragMode,
        editMode,
        editItems,
        inqRadix,
        isFormbuilder,
        panelListeners,
        storeConf,
        tbar,
        tpl,
        uuid;



    storeConf = {
        data:   AIR2.Inquiry.QUESDATA,
        url:    AIR2.Inquiry.URL + '/question.json',
        applySort:  function () {
            this.data.sort('ASC', function (a, b) {
                var aval, bval;

                aval = a.data.ques_dis_seq;
                bval = b.data.ques_dis_seq;

                if (aval > bval) {
                    return 1;
                }
                else {
                    return -1;
                }

            });
        },
        // helper to fix the display sequence of questions
        fixSequence: function (moveRec, newSeq) {
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
        },
        // override sort to use our custom sorter
        sort: function () {
            this.data.sort('ASC', AIR2.Inquiry.quesStore.sorter);
            if (this.snapshot && this.snapshot !== this.data) {
                this.snapshot.sort('ASC', AIR2.Inquiry.quesStore.sorter);
            }
            this.fireEvent('datachanged', this);
        },
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
        }
    };

    // return panel
    AIR2.Inquiry.Preview = new AIR2.UI.Panel({
        cls:            'air2-inquiry-preview',
        colspan:        3,
        dragMode:       false,
        iconCls:        'air2-icon-clipboard',
        id:             'air2-inquiry-preview',
        items: [
//             AIR2.Inquiry.SUMQP,
            {
                bodyCfg: {
                    html: 'Publishable Fields',
                    tag: 'h2'
                },
                border: false,
                xtype: 'panel'
            },
//             {
//                 border: false,
//                 items: [AIR2.Inquiry.PUBQP],
//                 title: 'Publishable Questions',
//                 xtype: 'container'
//             },
            {
                bodyCfg: {
                    html: 'Non-publishable Fields',
                    tag: 'h2'
                },
                border: false,
                xtype: 'panel'
            }//,
//             {
//                 border: false,
//                 items: [AIR2.Inquiry.PRIVQP],
//                 title: 'Private Questions',
//                 xtype: 'container'
//             }
        ],
        title:          'Preview Query'
    });

    return AIR2.Inquiry.Preview;
};
