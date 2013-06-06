Ext.ns('AIR2.Merge');
/***************
 * Merge Sources modal window
 *
 * Opens a modal window to merge 2 sources together
 *
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 * @cfg {string} prime_uuid (optional) uuid of the primary source
 * @cfg {string} merge_uuid (optional)
 */
AIR2.Merge.Sources = function (cfg) {
    var baseurl,
        closeBtn,
        comboActions,
        labels,
        pnl,
        previewBtn,
        remoteFetch,
        statusFld,
        submitBtn,
        swapBtn,
        tip,
        tpl,
        w;

    if (!cfg.prime_uuid && !cfg.merge_uuid) {
        return alert('missing prime or merge uuid!');
    }

    // globally-visible URL/params
    baseurl = AIR2.HOMEURL + '/merge/source/';
    AIR2.Merge.MERGEOPS = {}; //starts empty
    AIR2.Merge.MERGEDATA = {};

    // combobox actions
    comboActions = [];

    // helper function to ajax-preview (or commit) the merge
    remoteFetch = function (commit) {
        var fullurl = baseurl + cfg.prime_uuid + '/' + cfg.merge_uuid;

        Ext.Ajax.request({
            url: fullurl + '.json',
            method: (commit) ? 'POST' : 'GET',
            params: {ops: Ext.encode(AIR2.Merge.MERGEOPS)},
            callback: function (opt, success, rsp) {
                var array,
                    data,
                    factTypes,
                    len,
                    srcColumns,
                    stat;

                stat = rsp.status;
                data = Ext.decode(rsp.responseText);
                AIR2.Merge.MERGEDATA = data;
                //Logger(success, stat, data);

                // Just show message for non-200/400 codes (200's are success,
                // and 400's are resolvable-errors)
                if (stat !== 200 && stat !== 400) {
                    pnl.showError(data.message);
                    return;
                }

                // which "Source" columns, and which "Facts" to display
                srcColumns = [
                    'src_username',
                    'src_first_name',
                    'src_last_name'
                ];

                factTypes = [];

                // loop through 'errors', 'op_prime' and 'op_merge'
                array = [data.errors, data.op_prime, data.op_merge];

                Ext.each(array, function (datatype) {
                    Ext.each(datatype, function (item) {
                        var model, field;

                        Ext.iterate(item, function (key, value) {
                            model = key;
                            field = value;
                            return false; //break
                        });
                        if (model === 'Source' &&
                            srcColumns.indexOf(field) === -1
                        ) {
                            srcColumns.push(field);
                        }
                        else if (model.match(/^Fact\./)) {
                            factTypes.push(model);
                        }
                    });
                });

                // destroy old comboboxes
                Ext.each(comboActions, function (item) {
                    item.destroy();
                });
                comboActions = [];

                // update panel and render comboboxes
                pnl.update({source: srcColumns, fact: factTypes});
                Ext.each(comboActions, function (item) {
                    if (commit && success) {
                        item.destroy(); //no longer needed
                    }
                    else {
                        item.render(item.renderId);
                    }
                });

                // status
                if (data.errors && data.errors.length) {
                    len = data.errors.length;
                    statusFld.showFailure(len + ' merge conflicts');
                }
                else {
                    if (commit) {
                        previewBtn.disable();
                        submitBtn.disable();
                        swapBtn.disable();
                        closeBtn.show();
                        statusFld.showSuccess('Sources successfully merged');
                        w.SUCCESS = cfg.prime_uuid;
                    }
                    else {
                        statusFld.showSuccess('Preview found no conflicts');
                    }
                }

                // unmask
                w.body.unmask();
            }
        });
    };
    remoteFetch(); //initial call

    // render merge table ... ugh!
    labels = {
        src_username: 'Username',
        src_first_name: 'First Name',
        src_last_name: 'Last Name'
    };
    tpl = new Ext.XTemplate(
        '<table class="source-data">' +
          '<tr class="header">' +
            '<td><span>Field</span></td>' +
            '<td><span>Primary Source</span></td>' +
            '<td><span>Merge Source</span></td>' +
            '<td><span>Action</span></td>' +
          '</tr>' +
          // print source info
          '<tr class="section-header">' +
            '<td>Profile</td>' +
            '<td></td>' +
            '<td></td>' +
            '<td></td>' +
          '</tr>' +
          '<tpl for="source">' +
            '<tr>' +
              '<td>{[this.getLabel(values)]}</td>' +
              '{[this.getPrime(values)]}' +
              '{[this.getMerge(values)]}' +
              '<td id="{[this.action("Source", values)]}"></td>' +
            '</tr>' +
          '</tpl>' +
          // print facts
          '<tpl for="fact">' +
            '<tr class="section-header">' +
              '<td>{[this.getFactTitle(values)]}</td>' +
              '<td></td>' +
              '<td></td>' +
              '<td></td>' +
            '</tr>' +
            '<tpl if="this.hasFact(values, \'sf_fv_id\')">' +
              '<tr>' +
                '<td>Analyst Map</td>' +
                '{[this.getPrimeFact(values, "sf_fv_id")]}' +
                '{[this.getMergeFact(values, "sf_fv_id")]}' +
                '<td id="{[this.action(values, "sf_fv_id")]}"></td>' +
              '</tr>' +
            '</tpl>' +
            '<tpl if="this.hasFact(values, \'sf_src_fv_id\')">' +
              '<tr>' +
                '<td>Source Map</td>' +
                '{[this.getPrimeFact(values, "sf_src_fv_id")]}' +
                '{[this.getMergeFact(values, "sf_src_fv_id")]}' +
                '<td id="{[this.action(values, "sf_src_fv_id\")]}"></td>' +
              '</tr>' +
            '</tpl>' +
            '<tpl if="this.hasFact(values, \'sf_src_value\')">' +
              '<tr>' +
                '<td>Source Value</td>' +
                '{[this.getPrimeFact(values, "sf_src_value")]}' +
                '{[this.getMergeFact(values, "sf_src_value")]}' +
                '<td id="{[this.action(values, "sf_src_value")]}"></td>' +
              '</tr>' +
            '</tpl>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            errorCls: function (model, column, isPrime) {
                var cls = '';
                if (AIR2.Merge.MERGEDATA.errors) {
                    Ext.each(AIR2.Merge.MERGEDATA.errors, function (item) {
                        if (item[model] === column) {
                            cls += 'conflict';
                        }
                    });
                }

                // find out if this was chosen
                if (isPrime && AIR2.Merge.MERGEDATA.op_prime) {
                    Ext.each(AIR2.Merge.MERGEDATA.op_prime, function (item) {
                        if (item[model] === column) {
                            cls += ' choice';
                        }
                    });
                }
                if (!isPrime && AIR2.Merge.MERGEDATA.op_merge) {
                    Ext.each(AIR2.Merge.MERGEDATA.op_merge, function (item) {
                        if (item[model] === column) {
                            cls += ' choice';
                        }
                    });
                }
                return cls;
            },
            getLabel: function (column) {
                return (labels[column]) ? labels[column] : column;
            },
            getPrime: function (col) {
                var cls,
                    text;

                text = 'Unknown';
                cls = this.errorCls('Source', col, true);
                if (AIR2.Merge.MERGEDATA.PrimeSource) {
                    text = AIR2.Merge.MERGEDATA.PrimeSource[col];
                }
                return '<td class="' + cls + '">' + text + '</td>';
            },
            getMerge: function (col) {
                var cls,
                    text;

                text = 'Unknown';
                cls = this.errorCls('Source', col, false);
                if (AIR2.Merge.MERGEDATA.MergeSource) {
                    text = AIR2.Merge.MERGEDATA.MergeSource[col];
                }
                return '<td class="' + cls + '">' + text + '</td>';
            },
            getFactTitle: function (model) {
                var fact_id = model.split('.')[1];
                if (AIR2.Merge.MERGEDATA.facts) {
                    return AIR2.Merge.MERGEDATA.facts[fact_id].fact_name;
                }
                return model;
            },
            hasFact: function (model, col) {
                var i,
                    factid,
                    facts;

                factid = model.split('.')[1];
                if (AIR2.Merge.MERGEDATA.PrimeSource) {
                    facts = AIR2.Merge.MERGEDATA.PrimeSource.SrcFact;
                    for (i = 0; i < facts.length; i++) {
                        if (facts[i].sf_fact_id === factid && facts[i][col]) {
                            return true;
                        }
                    }
                }
                if (AIR2.Merge.MERGEDATA.MergeSource) {
                    facts = AIR2.Merge.MERGEDATA.MergeSource.SrcFact;
                    for (i = 0; i < facts.length; i++) {
                        if (facts[i].sf_fact_id === factid && facts[i][col]) {
                            return true;
                        }
                    }
                }
                return false;
            },
            getFactValue: function (facts, factid, col) {
                var fvs,
                    i,
                    ident,
                    j,
                    val;

                for (i = 0; i < facts.length; i++) {
                    if (facts[i].sf_fact_id === factid) {
                        val = facts[i][col];
                        if (!val || val.length === 0) {
                            return '<span class="lighter">(none)</span>';
                        }

                        // find the actual fv_value
                        if (col.match(/_id$/)) {
                            if (AIR2.Merge.MERGEDATA.facts) {
                                ident = AIR2.Merge.MERGEDATA.facts[
                                    factid
                                ].fact_identifier;
                                fvs = AIR2.Fixtures.Facts[ident];
                                for (j = 0; j < fvs.length; j++) {
                                    if (fvs[j][0] === val) {
                                        return fvs[j][1];
                                    }
                                }
                            }
                        }
                        else {
                            return val;
                        }
                    }
                }
                return 'Unknown';
            },
            getPrimeFact: function (model, col) {
                var cls,
                    fact_id,
                    facts,
                    text;

                text = 'Unknown';
                cls = this.errorCls(model, col, true);
                fact_id = model.split('.')[1];
                if (AIR2.Merge.MERGEDATA.PrimeSource) {
                    facts = AIR2.Merge.MERGEDATA.PrimeSource.SrcFact;
                    text = this.getFactValue(facts, fact_id, col);
                }
                return '<td class="' + cls + '">' + text + '</td>';
            },
            getMergeFact: function (model, col) {
                var cls,
                    fact_id,
                    facts,
                    text;

                text = 'Unknown';
                cls = this.errorCls(model, col, false);
                fact_id = model.split('.')[1];
                if (AIR2.Merge.MERGEDATA.MergeSource) {
                    facts = AIR2.Merge.MERGEDATA.MergeSource.SrcFact;
                    text = this.getFactValue(facts, fact_id, col);
                }
                return '<td class="' + cls + '">' + text + '</td>';
            },
            action: function (model, col) {
                var cb,
                    mergeCls,
                    myId,
                    myVal,
                    primeCls;

                primeCls = this.errorCls(model, col, true);
                mergeCls = this.errorCls(model, col, false);
                if (primeCls.length || mergeCls.length) {
                    myId = Ext.id();
                    myVal = '';
                    if (primeCls.match(/choice/)) {
                        myVal = 'P';
                    }
                    else if (mergeCls.match(/choice/)) {
                        myVal = 'M';
                    }

                    cb = new AIR2.UI.ComboBox({
                        choices: [['P', 'Prime'], ['M', 'Merge']],
                        value: myVal,
                        width: 70,
                        renderId: myId,
                        listeners: {
                            select: function (box, rec) {
                                var merge, prime;

                                merge = Ext.get(myId).prev();
                                prime = merge.prev();
                                if (rec.data.value === 'P') {
                                    merge.removeClass('choice');
                                    prime.addClass('choice');
                                }
                                else {
                                    prime.removeClass('choice');
                                    merge.addClass('choice');
                                }

                                // update MERGEDATA
                                if (!AIR2.Merge.MERGEOPS[model]) {
                                    AIR2.Merge.MERGEOPS[model] = {};
                                }
                                AIR2.Merge.MERGEOPS[model][col] =
                                    rec.data.value;
                            }
                        }
                    });
                    comboActions.push(cb);
                    return myId;
                }
                return '';
            }
        }
    );

    // controls and status
    previewBtn = new AIR2.UI.Button({
        text: 'Preview',
        iconCls: 'air2-icon-refresh',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        handler: function () {
            w.body.mask('previewing');
            remoteFetch(false);
        }
    });
    submitBtn = new AIR2.UI.Button({
        text: 'Commit Changes',
        iconCls: 'air2-icon-merge',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        handler: function () {
            w.body.mask('saving');
            remoteFetch(true); //refresh preview
        }
    });
    closeBtn = new AIR2.UI.Button({
        text: 'Close',
        iconCls: 'air2-icon-check',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        hidden: true,
        handler: function () {
            w.close();
        }
    });
    statusFld = new Ext.BoxComponent({
        cls: 'submit-status air2-icon',
        showSuccess: function (msg) {
            statusFld.el.replaceClass('air2-icon-warning', 'air2-icon-check');
            statusFld.update(msg);
            statusFld.show();
        },
        showFailure: function (msg) {
            statusFld.el.replaceClass('air2-icon-check', 'air2-icon-warning');
            statusFld.update(msg);
            statusFld.show();
        }
    });
    swapBtn = new AIR2.UI.Button({
        text: 'Flip Sources',
        iconCls: 'air2-icon-retry',
        air2type: 'BLUE',
        handler: function () {
            var tmp = cfg.prime_uuid;
            cfg.prime_uuid = cfg.merge_uuid;
            cfg.merge_uuid = tmp;
            AIR2.Merge.MERGEOPS = {}; //reset ops
            w.body.mask('loading');
            remoteFetch(false); //refresh preview
        }
    });

    // main display panel
    pnl = new Ext.form.FormPanel({
        unstyled: true,
        tpl: tpl,
        autoScroll: true,
        buttonAlign: 'left',
        buttons: [previewBtn, submitBtn, closeBtn, statusFld],
        showError: function (msg) {
            var cls, str;

            cls = 'air2-icon air2-icon-warning';
            str = '<div class="fatal-error"><span class="' + cls + '">';
            str += msg + '</span></div>';
            pnl.update(str);
            w.body.unmask();
        }
    });

    // support article
    tip = AIR2.Util.Tipper.create({id: 20162358, cls: 'lighter', align: 15});

    // create modal window
    w = new AIR2.UI.Window({
        title: 'Merge Sources ' + tip,
        cls: 'air2-merge',
        iconCls: 'air2-icon-sources',
        closeAction: 'close',
        width: 600,
        height: 430,
        items: [pnl],
        tools: ['->', swapBtn],
        listeners: {
            afterrender: function () {
                var count = 0;
                Ext.iterate(AIR2.Merge.MERGEDATA, function () {
                    count++;
                });
                if (count === 0) {
                    w.body.mask('loading');
                }
            }
        }
    });

    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }

    return w;
};
