AIR2.Inquiry.initStores = function (storeConf) {
    var arrayReader,
        mapping,
        memoryProxy,
        templateRecord,
        vals;

    storeConf = storeConf || {};

    // load stores as namespaced vars
    AIR2.Inquiry.inqStore = new AIR2.UI.APIStore({
        data:   AIR2.Inquiry.BASE,
        url:    AIR2.Inquiry.URL + '.json'
    });

    AIR2.Inquiry.inqStore.on('write', function(){
        // make sure updates to things like the long description
        // are followed with a call to resize the layout in case it
        // pushes content offscreen
        resizeAndReveal = new Ext.util.DelayedTask(function(){
            AIR2.APP.doLayout();
        });

        resizeAndReveal.delay(500);
    });

    AIR2.Inquiry.inqStore.on('load', function(){
        AIR2.APP.doLayout();
    });

    AIR2.Inquiry.orgStore = new AIR2.UI.APIStore({
        data:       AIR2.Inquiry.ORGDATA,
        url:        AIR2.Inquiry.URL + '/organization.json',
        applySort:  function () {
            this.data.sort('ASC', function (a, b) {
                var aval, bval;

                aval = a.data.Organization.org_display_name.toUpperCase();
                bval = b.data.Organization.org_display_name.toUpperCase();

                if (aval > bval) {
                    return 1;
                }
                else {
                    return -1;
                }
            });
        }
    });

    AIR2.Inquiry.prjStore = new AIR2.UI.APIStore({
        data:   AIR2.Inquiry.PROJDATA,
        url:    AIR2.Inquiry.URL + '/project.json',
        applySort:  function () {
            this.data.sort('ASC', function (a, b) {
                var aval, bval;

                aval = a.data.Project.prj_display_name.toUpperCase();
                bval = b.data.Project.prj_display_name.toUpperCase();

                if (aval > bval) {
                    return 1;
                }
                else {
                    return -1;
                }
            });
        }
    });

    AIR2.Inquiry.authorStore = new AIR2.UI.APIStore({
        data:   AIR2.Inquiry.AUTHORDATA,
        url:    AIR2.Inquiry.URL + '/author.json',
        applySort:  function () {
            this.data.sort('ASC', function (a, b) {
                var aval, bval;

                aval = a.data.User.user_last_name.toUpperCase();
                bval = b.data.User.user_last_name.toUpperCase();

                if (aval > bval) {
                    return 1;
                }
                else {
                    return -1;
                }
            });
        }
    });

    AIR2.Inquiry.watcherStore = new AIR2.UI.APIStore({
        data:   AIR2.Inquiry.WATCHERDATA,
        url:    AIR2.Inquiry.URL + '/watcher.json',
        applySort:  function () {
            this.data.sort('ASC', function (a, b) {
                var aval, bval;

                aval = a.data.User.user_last_name.toUpperCase();
                bval = b.data.User.user_last_name.toUpperCase();

                if (aval > bval) {
                    return 1;
                }
                else {
                    return -1;
                }
            });
        }
    });

    mapping = [{ name : 'ques_template', mapping : 1 }];
    vals = [];

    Ext.iterate(AIR2.Inquiry.QUESTPLS, function (key, value, object) {
        value.ques_template = key;

        Ext.iterate(value, function (key, value, object) {
            mapping.push({name : key, mapping : key});
        });

        vals.push(value);
    });

    templateRecord = Ext.data.Record.create(mapping);

    arrayReader = new Ext.data.ArrayReader({}, templateRecord);
    memoryProxy = new Ext.data.MemoryProxy(vals);

    AIR2.Inquiry.templateStore = new Ext.data.Store({
        autoLoad: true,
        proxy:    memoryProxy,
        reader:   arrayReader
    });


    Ext.applyIf(storeConf, {
        data:   AIR2.Inquiry.QUESDATA,
        url:    AIR2.Inquiry.QUESURL + '.json',
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
//                 Logger(r.get('ques_dis_seq'), r.get('ques_value'));

                if (
                    last !== null &&
                    (!r.get('ques_dis_seq') || r.get('ques_dis_seq') <= last)
                ) {
                    r.beginEdit();
                    r.forceSet('ques_dis_seq', last + 1);
                    r.commit(true);
                    r.endEdit();
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

//             if (a.ques_public_flag !== b.ques_public_flag) {
//                 return b.ques_public_flag - a.ques_public_flag;
//             }
            if (a.ques_dis_seq !== b.ques_dis_seq) {
                return a.ques_dis_seq - b.ques_dis_seq;
            }
            if (aRec.dirty || bRec.dirty && (aRec.dirty !== bRec.dirty)) {
                return bRec.dirty - aRec.dirty;
            }
            return a.ques_cre_dtim - b.ques_cre_dtim;
        }
    });

    AIR2.Inquiry.quesStore = new AIR2.UI.APIStore(storeConf);

    AIR2.Inquiry.quesStore.on(
        'beforewrite',
        function (store, action, response, options, arg) {
            AIR2.APP.el.mask('Working...');
        }
    );

    AIR2.Inquiry.quesStore.on(
        'exception',
        function (store, type, action, option, response, arg) {
            // something went wrong bail out and reload the store
            AIR2.Inquiry.quesStore.reload();
            AIR2.Inquiry.templateStore.reload();
            AIR2.APP.el.unmask();
        }
    );

    AIR2.Inquiry.quesStore.on(
        'write',
        function (store, action, result, response, records) {
            var inqRec;
            if (response.success) {
                inqRec = AIR2.Inquiry.inqStore.getAt(0);
                inqRec.beginEdit();
                inqRec.set('inq_stale_flag', true);
                inqRec.commit();
                inqRec.endEdit();
            }
            AIR2.Inquiry.quesStore.reload();
            AIR2.Inquiry.templateStore.reload();
        }
    );

    AIR2.Inquiry.quesStore.on(
        'load',
        function () {
            AIR2.APP.el.unmask();
        }
    );
};

AIR2.Inquiry.createQuestionRecord = function (tplKey) {
    var rec, tpl;

    rec = new AIR2.Inquiry.quesStore.recordType();
    tpl = AIR2.Inquiry.QUESTPLS[tplKey];
    rec.forceSet('ques_template', tplKey);
    // update the record (manually to avoid saving these fields)
    rec.set('ques_type',        tpl.ques_type);
    rec.set(
        'ques_value',
        AIR2.Inquiry.getLocalizedValue(tpl, 'ques_value')
    );
    rec.set('ques_public_flag', tpl.ques_public_flag);
    rec.set('ques_group',       tpl.ques_group);
    rec.set('ques_resp_type',   tpl.ques_resp_type);

    //sometimes these doen't exist
    if (tpl.ques_resp_opts) {
        rec.set('ques_resp_opts',   Ext.encode(tpl.ques_resp_opts));
    }
    if (tpl.ques_choices) {
        rec.set(
            'ques_choices',
            Ext.encode(AIR2.Inquiry.getLocalizedValue(tpl, 'ques_choices'))
        );
    }
    if (tpl.ques_locks) {
        rec.set('ques_locks',       Ext.encode(tpl.ques_locks));
    }

    rec.phantom = true;

    return rec;
};
