/***********************
 * Query Builder main panel
 */
AIR2.Builder.Main = function () {

    // dataviews
    AIR2.Builder.INQDV = new AIR2.UI.JsonDataView({
        store: AIR2.Builder.INQSTORE,
        itemSelector: '.inq-row',
        tpl: new Ext.XTemplate(
            '<tpl for=".">' +
              '<div class="inq-row">' +
                '<h1 class="title">{inq_ext_title}</h1>' +
                // optional data
                '<tpl if="inq_desc">' +
                  '<p class="desc">{inq_desc}</p>' +
                '</tpl>' +
                '<tpl if="inq_intro_para">' +
                  '<p class="intro">{inq_intro_para}</p>' +
                '</tpl>' +
              '</div>' +
            '</tpl>',
            {compiled: true, disableFormats: true}
        )
    });
    AIR2.Builder.PUBLICDV = AIR2.Builder.QuestionDataView(true);
    AIR2.Builder.PRIVATEDV = AIR2.Builder.QuestionDataView(false);

    // create panel
    AIR2.Builder.Main = new AIR2.UI.Panel({
        colspan:    2,
        rowspan:    5,
        title:      'Builder',
        cls:        'air2-builder-main',
        iconCls:    'air2-icon-clipboard',
        items:      [
            AIR2.Builder.INQDV,
            AIR2.Builder.PUBLICDV,
            AIR2.Builder.PRIVATEDV
        ],
        editMode:   function (doEdit) {
            if (doEdit) {
                this.el.addClass('editing');
            }
            else {
                this.el.removeClass('editing');
            }
        },
        dragMode:   function (doDrag) {
            if (doDrag) {
                this.el.addClass('dragging');
            }
            else {
                this.el.removeClass('dragging');
            }
        }
    });

    // question event handlers
    AIR2.Builder.questionDragHandler();
    AIR2.Builder.questionClickHandler();

    // check if a question record CAN be public
    var canBePublic = function (rec) {
        var l = Ext.decode(rec.data.ques_locks);
        return !(l && l.length && l.indexOf('ques_public_flag') > -1);
    };

    // add drop zones
    AIR2.Builder.Main.on('render', function (cmp) {
        cmp.dropzone = new Ext.dd.DropZone(cmp.el, {
            getTargetFromEvent: function (e) {
                var t = AIR2.Builder.PUBLICDV.getHoverTarget(e.getXY()[1]);
                if (t) {
                    return t;
                }
                else {
                    t = AIR2.Builder.PRIVATEDV.getHoverTarget(e.getXY()[1]);
                    if (t) {
                        return t;
                    }
                }
            },
            onNodeEnter: function (target, dd, e, data) {
                var cls, dom;
                if (!target['public'] || canBePublic(data.quesRecord)) {
                    if (target.before) {
                        cls = 'drag-before';
                        dom = target.before;
                    }
                    else {
                        cls = 'drag-after';
                        dom = target.after;
                    }

                    if (data.group) {
                        cls = [cls, data.group];
                    }

                    Ext.fly(dom).addClass(cls);
                }
            },
            onNodeOut: function (target, dd, e, data) {
                var dom = target.before ? target.before : target.after,
                    cls = [
                        'drag-before',
                        'drag-after',
                        'generic',
                        'contact',
                        'demographic'
                    ];
                Ext.fly(dom).removeClass(cls);
            },
            onNodeOver: function (target, dd, e, data) {
                if (!target['public'] || canBePublic(data.quesRecord)) {
                    return Ext.dd.DropZone.prototype.dropAllowed;
                }
                return Ext.dd.DropZone.prototype.dropNotAllowed;
            },
            onNodeDrop: function (target, dd, e, data) {
                var adjacent, rec, seq;

                if (!target['public'] || canBePublic(data.quesRecord)) {
                    data.quesRecord.set('ques_public_flag', target['public']);

                    // set the ques_dis_seq
                    if (target.empty) {
                        if (target['public']) {
                            seq = 1;
                        }
                        else {
                            seq = 100;
                        }
                        data.quesRecord.set('ques_dis_seq', seq);
                    }
                    else if (target.before) {
                        rec = target.dv.getRecord(target.before);
                        seq = rec.get('ques_dis_seq');
                        adjacent = AIR2.Builder.QUESSTORE.isAdjacentOrdered(
                            data.quesRecord,
                            rec
                        );
                        if (!adjacent) {
                            data.quesRecord.set('ques_dis_seq', seq);
                        }
                    }
                    else if (target.after) {
                        rec = target.dv.getRecord(target.after);
                        seq = rec.get('ques_dis_seq');
                        adjacent = AIR2.Builder.QUESSTORE.isAdjacentOrdered(
                            rec,
                            data.quesRecord
                        );
                        if (!adjacent) {
                            data.quesRecord.set('ques_dis_seq', seq + 1);
                        }
                    }

                    // add new records, and fix the sequence of store records
                    if (data.quesRecord.phantom) {
                        AIR2.Builder.QUESSTORE.add(data.quesRecord);
                    }
                    AIR2.Builder.QUESSTORE.fixSequence();

                    // recache stops and start editing the field
                    AIR2.Builder.PUBLICDV.cacheStops();
                    AIR2.Builder.PRIVATEDV.cacheStops();
                    AIR2.Builder.Main.dragMode(false);
                    if (data.quesRecord.dirty) {
                        AIR2.Builder.questionEdit(
                            target.dv,
                            target.dv.getNode(data.quesRecord)
                        );
                    }
                    return true;
                }
            }
        });
    });

    return AIR2.Builder.Main;
};
