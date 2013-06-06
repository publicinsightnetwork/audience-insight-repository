Ext.ns('AIR2.Submission.Responses');

/***************
 * Submission Responses Panel
 */
AIR2.Submission.Responses = function (config) {
    var count,
        defaultConfig,
        e,
        firstButton,
        href,
        inq,
        inqcre,
        inqdtim,
        inqorg,
        inqproj,
        inqTitle,
        lastButton,
        MAX_SHOWN,
        myAnnots,
        nextButton,
        p,
        pager,
        pagerItems,
        pagerPage,
        pagerTotal,
        prevButton,
        printBtn,
        s,
        src,
        srclink,
        subm,
        submcre,
        submdtim,
        submorg,
        submwhen,
        summaryTemplate,
        summaryView,
        thisUser,
        totalUuids,
        viewTemplate;

    myAnnots = {};

    // object for current user
    thisUser = {
        user_username: AIR2.USERINFO.username,
        user_first_name: AIR2.USERINFO.first_name,
        user_last_name: AIR2.USERINFO.last_name,
        user_uuid: AIR2.USERINFO.uuid,
        user_status: AIR2.USERINFO.status,
        user_type: AIR2.USERINFO.type
    };

    AIR2.Submission.Responses.showOriginal = function (el, id) {
        var data_view,
            origRespTpl,
            view_id;

        view_id = 'air2-original-response-' + id;

        //turn el into an Ext.Element
        el = Ext.get(el);

        data_view = Ext.getCmp(view_id);

        if (data_view) {
            data_view.all.slideOut('t', {
                callback: function () {
                    data_view.hide();
                }
            });
            el.update(' Show Original ');
            return;
        }

        // response template
        origRespTpl = new Ext.XTemplate(
            '<tpl for=".">' +
              '<div class="anns clearfix anns-row">' +
                '<div class="submission">' +
                  '<span>{sr_orig_value}</span>' +
                '</div>' +
              '</div>' +
            '</tpl>',
            {
                compiled: true
            }
        );

        data_view = new AIR2.UI.JsonDataView({
            id:           view_id,
            renderTo:     el.findParent('.subm-response'),
            renderEmpty:  true,
            tpl:          origRespTpl,
            cls:          'anns-ct',
            itemSelector: '.anns-row',
            url:          AIR2.Submission.URL + '/response/' + id + '.json',
            baseParams:   {limit: 99, sort: 'sr_cre_dtim asc'},
            onDataChanged: function () {
                this.onAdd(this.store, this.store.getRange(), 0);
                this.all.slideIn('t');
                el.update(' Hide Original ');
            },
            hide: function () {
                this.destroy();
                return 1;
            }
        });

    };

    AIR2.Submission.Responses.togglePublic = function (id, sr_public_flag) {
        var newValue,
            values;

        newValue = '';

        if (sr_public_flag === 'true') {
            newValue = 0;
        }
        else {
            newValue = 1;
        }
        values = [{'key': 'sr_public_flag', 'value': newValue}];
        AIR2.Submission.Responses.updateValues(id, values);
    };

    AIR2.Submission.Responses.updateValues = function (
        id,
        values,
        updateCallback
    ) {
        var responsePanel,
            responseRecord,
            responsesStore;

        if (! AIR2.Submission.Responses.STOREREF) {
            responsePanel = Ext.getCmp('air2-submission-responses');
            AIR2.Submission.Responses.STOREREF = responsePanel.store;
        }

        responsesStore = AIR2.Submission.Responses.STOREREF;

        responseRecord = responsesStore.getById(id);

        Ext.each(values, function (item) {
            responseRecord.set(item.key, item.value);
        });

        if (updateCallback) {
            responsesStore.addListener(
                'update',
                updateCallback,
                this,
                {single: true}
            );

        }

        responsesStore.save();
    };

    AIR2.Submission.Responses.getPublishFlag = function () {
        var publishStatusMetaView,
            record;

        publishStatusMetaView = Ext.getCmp(
            "air2-submission-publish-meta-view"
        );
        if (publishStatusMetaView) {
            record = publishStatusMetaView.store.getAt(0);
            if (record) {
                return record.get('publish_flags');
            }
        }

        return AIR2.Submission.BASE.radix.publish_flags;
    };

    AIR2.Submission.Responses.showEdit = function (el, id) {
        var data_view,
            tpl,
            view_id;

        view_id = 'air2-edit-response-' + id;

        //turn el into an Ext.Element
        el = Ext.get(el);

        data_view = Ext.getCmp(view_id);

        if (data_view) {
            data_view.all.slideOut('t', {
                callback: function () {
                    data_view.hide();
                }
            });
            return data_view;
        }


        if (myAnnots[id]) {
            myAnnots[id].destroy();
            delete myAnnots[id];
        }

        tpl = new Ext.XTemplate(
            '<tpl for=".">' +
                '<div class="anns mod-answer clearfix anns-row">' +
                    '<div class="ann">' +
                        '{sr_mod_value:this.renderWindow}' +
                        '<div class="buttons">' +
                            '<span class="air2-btn air2-btn-friendly ' +
                            'air2-btn-small">' +
                                '<button class="x-btn-text air2-btn resp-save">' +
                                    'Save' +
                                '</button> ' +
                            '</span>' +
                            '<span class="air2-btn air2-btn-friendly ' +
                            'air2-btn-small">' +
                                '<button class="x-btn-text air2-btn resp-cancel">' +
                                    'Cancel' +
                                '</button> ' +
                            '</span>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</tpl>',
            {
                compiled: true,
                getCurrentValue: function (sr_mod_value, values) {
                    if (sr_mod_value) {
                        return sr_mod_value;
                    }
                    return values.sr_orig_value;
                }, 
                renderOptions: function (sr_mod_value, values) {
                    return AIR2.Util.Response.formatOptions(values);
                },

                renderWindow: function(sr_mod_value, values) {
                    if (!values.Question.ques_choices) {
                        var shownValue = this.getCurrentValue(sr_mod_value, values);
                        return '<textarea>'+shownValue+'</textarea>';
                    } else {
                        return this.renderOptions(values.sr_orig_value, values);
                    }

                }
            }
        );

        data_view = new AIR2.UI.JsonDataView({
            id:           view_id,
            renderTo:     el.findParent('.subm-response'),
            renderEmpty:  true,
            tpl:          tpl,
            cls:          'anns-ct',
            itemSelector: '.anns-row',
            url:          AIR2.Submission.URL + '/response/' + id + '.json',
            baseParams:   {limit: 99, sort: 'sr_cre_dtim asc'},
            hide: function () {
                this.destroy();
                return 1;
            },
            // create/edit/delete click handlers
            listeners: {
                Click: function (
                    reponse_data_view,
                    response_index,
                    response_node,
                    event_object
                ) {
                    var elObj,
                        nodeObj,
                        respEl,
                        txt,
                        val,
                        values,
                        record,
                        ques_uuid,
                        ques_type,
                        name,
                        selectString,
                        selected,
                        options,
                        val
                        ;

                    elObj = Ext.get(el);
                    nodeObj = Ext.get(response_node);

                    if (event_object.getTarget('.resp-save')) {
                        respEl = event_object.getTarget('.resp-save', 5, true);

                        if (respEl) {
                            txt = nodeObj.child('textarea');

                            if (txt) {
                                val = txt.getValue();
                            } 
                            else {
                                record = reponse_data_view.store.getById(id);
                                ques_uuid = record.data.Question.ques_uuid;
                                ques_type = record.data.Question.ques_type;
                                if (ques_type == 'R' || ques_type == 'C') {
                                    name = 'group' + ques_uuid;
                                    selectString = 'div.ann input[name='+name+']:checked';
                                    selected = Ext.select(selectString);
                                    selected = selected.elements;
                                    val = '';
                                    Ext.each(selected, function(option, index) {
                                        option = Ext.get(option);
                                        Logger(option.getValue());
                                        if (val != '') {
                                            val += '|';
                                        }
                                        val += option.getValue();
                                    });
                                } 
                                else if (ques_type == 'L' || ques_type == 'O') {
                                    name = 'group' + ques_uuid;
                                    selectString = 'div.ann select[name='+name+'] option';
                                    selected = Ext.select(selectString);
                                    options = selected.elements;
                                    val = '';
                                    Ext.each(options, function(option, index) {
                                        option = Ext.get(option);
                                        if (option.getAttribute('selected')) {
                                            Logger(option.getValue());
                                            if (val != '') {
                                                val += '|';
                                            }
                                            val += option.getValue();
                                        }
                                        
                                    });
                                }
                            }

                            values = [
                            {'key': 'sr_mod_value',
                             'value': val}
                            ];

                            AIR2.Submission.Responses.updateValues(id, values);

                        }
                        reponse_data_view.hide();
                    }
                    else if (event_object.getTarget('.resp-cancel')) {
                        reponse_data_view.hide();
                    }
                }
            }
        });

        return data_view;

    };

    /* function for ajax showing/hiding annotations on individual responses */
    AIR2.Submission.Responses.showAnnotation = function (el, id) {
        var dv,
            dvTemplate,
            parent_el,
            spin_el,
            spinIcon,
            target_el,
            view_id;

        parent_el = Ext.get(el).findParent('div.annotation', 3, 1);

        target_el = parent_el.parent().insertHtml('afterEnd', '<div></div>', 1);

        view_id = 'air2-edit-response-' + id;

        data_view = Ext.getCmp(view_id);

        if (data_view) {
            data_view.hide();
        }


        if (myAnnots[id]) {
            // already open --> close and destroy
            Ext.fly(target_el).fadeOut({concurrent: true}).slideOut('t', {
                duration: 0.2,
                callback: function () {
                    myAnnots[id].destroy();
                    delete myAnnots[id];
                }
            });
        }
        else {
            spin_el = parent_el.next('.spin-icon');
            spinIcon = spin_el.createChild({
                cls: 'air2-form-remote-wait'
            });
            spinIcon.alignTo(spin_el, 'l-r', [-15, 0]).show();
            Ext.fly(target_el).setStyle('display', 'none');

            dvTemplate =  new Ext.XTemplate(
                '<table class="annot-mini-tbl">' +
                    '<tpl for=".">' +
                        '<tr class="annot-mini-row">' +
                            // info (no photo)
                            '<td>' +
                                '<div class="who air2-corners">' +
                                    '<b>' +
                                        '{[AIR2.Format.userName(' +
                                            'values.CreUser,' +
                                            '1,' +
                                            '1' +
                                        ')]}' +
                                    '</b>' +
                                    '{[this.moreInfo(values.CreUser)]}' +
                                '</div>' +
                            '</td>' +
                            // text value
                            '<td class="text">' +
                                '<p>{sran_value}</p>' +
                                '<div class="meta">' +
                                        '{[this.postdate(values)]}' +
                                '</div>' +
                            '</td>' +
                            // edit buttons
                            '<td class="row-ops">' +
                                '<button class="air2-rowedit"></button>' +
                                '<button class="air2-rowdelete"></button>' +
                            '</td>' +
                        '</tr>' +
                    '</tpl>' +
                    // Add area
                    '<tr>' +
                        '<td>' +
                            '<div class="who air2-corners addwho">' +
                                'Add an Annotation' +
                            '</div>' +
                        '</td>' +
                        '<td class="addarea"></td>' +
                        '<td class="row-ops addbutton"></td>' +
                    '</tr>' +
                '</table>',
                {
                    compiled: true,
                    disableFormats: true,
                    moreInfo: function (usr) {
                        var org,
                            str,
                            title;

                        str = '';
                        if (usr.user_type === 'S') {
                            str += '<p>System User</p>';
                        }
                        else {
                            if (usr.UserOrg && usr.UserOrg.length) {
                                title = usr.UserOrg[0].uo_user_title;
                                if (title) {
                                    str += '<p>' + title + '</p>';
                                }

                                org = AIR2.Format.userOrgShort(
                                    usr.UserOrg[0],
                                    1
                                );
                                str += '<div class="room">';
                                str += org;
                                str += '</div>';
                            }
                        }
                        return str;
                    },
                    postdate: function (v) {
                        if (v.sran_upd_dtim > v.sran_cre_dtim) {
                            return 'Updated ' + AIR2.Format.date(
                                v.sran_upd_dtim
                            );
                        }
                        else {
                            return 'Posted ' + AIR2.Format.date(
                                v.sran_cre_dtim
                            );
                        }
                    }
                }
            );

            // not open --> create and open
            dv = new AIR2.UI.PagingEditor({
                renderTo: target_el,
                url: AIR2.Submission.URL + '/response/' + id +
                    '/annotation.json',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                newRowDef: {CreUser: thisUser},
                allowEdit: function (rec) {
                    if (rec.phantom) {
                        return true;
                    }
                    var cre = rec.data.CreUser.user_uuid;
                    return (AIR2.USERINFO.uuid === cre);
                },
                allowDelete: function (rec) {
                    if (rec.phantom) {
                        return true;
                    }
                    var cre = rec.data.CreUser.user_uuid;
                    return (AIR2.USERINFO.uuid === cre);
                },
                itemSelector: '.annot-mini-row',
                tpl: dvTemplate,
                editRow: function (dv, node, rec) {
                    var text,
                        textEl;

                    textEl = Ext.fly(node).first('td.text');
                    textEl.update('').setStyle('padding', '0px 6px');
                    text = new Ext.form.TextArea({
                        grow: true,
                        height: 40,
                        width: '100%',
                        allowBlank: false,
                        renderTo: textEl,
                        value: rec.data.sran_value
                    });
                    return [text];
                },
                saveRow: function (rec, edits) {
                    if (edits && edits.length) {
                        rec.set('sran_value', edits[0].getValue());
                    }
                },
                refresh: function () {
                    var el, rs;

                    // don't do the empty-text thing... just render the tpl
                    this.clearSelections(false, true);
                    el = this.getTemplateTarget();
                    rs = this.store.getRange();
                    el.update('');
                    this.tpl.overwrite(el, this.collectData(rs, 0));
                    this.all.fill(Ext.query(this.itemSelector, el.dom));
                    this.updateIndexes(0);

                    // render the add textarea/button
                    this.cleanupAddStuff();
                    this.un('destroy', this.cleanupAddStuff, this);
                    this.addarea = new Ext.form.TextArea({
                        grow: true,
                        height: 40,
                        width: '100%',
                        renderTo: this.el.child('.addarea')
                    });
                    this.addbtn = new AIR2.UI.Button({
                        air2type: 'ROUND',
                        iconCls: 'air2-icon-disk-small',
                        tooltip: 'Save',
                        renderTo: this.el.child('.addbutton'),
                        scope: this,
                        handler: function () {
                            var rec, val;

                            val = this.addarea.getValue();
                            if (val && val.length > 0) {
                                rec = new this.store.recordType(
                                    Ext.apply({}, this.newRowDef)
                                );
                                rec.set('sran_value', this.addarea.getValue());
                               
                                this.store.insert(0, rec);
                                this.store.save();
                                this.addarea.reset();
                                this.updateTotal();
                            }
                        }
                    });
                    this.on('destroy', this.cleanupAddStuff, this);
                },
                cleanupAddStuff: function () {
                    if (this.addarea) {
                        this.addarea.destroy();
                    }
                    if (this.addbtn) {
                        this.addbtn.destroy();
                    }
                },
                updateTotal: function () {
                    var c, p;

                    p = (this.el) ? this.el.findParent('.annotation'): null;
                    if (p) {
                        c = Ext.util.Format.plural(
                            this.store.getCount(),
                            'Annotation'
                        );
                        Ext.fly(p).first().update(c);
                    }
                },
                listeners: {
                    load: function () {
                        if (spinIcon) {
                            spinIcon.remove();
                        }

                        dv.updateTotal();

                        // scroll into view (if not visible)
                        if (!Ext.fly(target_el).isVisible()) {
                            Ext.fly(target_el).slideIn('t', {duration: 0.2});
                        }
                    }
                }
            });
            myAnnots[id] = dv;
        }
    }; //end showAnnotation function

    // subm count and link/
    subm = AIR2.Submission.BASE.radix;
    inq  = AIR2.Submission.INQDATA.radix;

    count = null;
    if (inq.hasOwnProperty('recv_count')) {
        count = inq.recv_count;
    }

    href = AIR2.HOMEURL + '/reader/query/' + subm.Inquiry.inq_uuid;

    // inquiry data
    inqcre = AIR2.Format.userName(inq.CreUser, true, true);
    inqorg = AIR2.Format.userOrgShort(inq.CreUser.UserOrg[0], true);
    inqdtim = AIR2.Format.date(inq.inq_cre_dtim);
    inqproj = '';
    if (inq.ProjectInquiry.length) {
        inqproj = AIR2.Format.projectName(inq.ProjectInquiry[0].Project, true);
    }

    // subm data
    submcre = AIR2.Format.userName(subm.CreUser, true, true);
    submorg = AIR2.Format.userOrgShort(subm.CreUser.UserOrg[0], true);
    submdtim = AIR2.Format.dateWeek(subm.srs_cre_dtim, true);
    submwhen = AIR2.Format.dateWeek(subm.srs_date, true);

    // source data
    src = AIR2.Submission.SRCDATA.radix;
    src = (src.length) ? src[0] : src;
    srclink = AIR2.Format.sourceFullName(src, true);

    // roll our own pager since the PagingToolbar requires a real Store.
    pagerPage  = 0;
    pagerItems = [];
    totalUuids = AIR2.Submission.ALTSUBMS.length;
    pagerTotal = 0;
    MAX_SHOWN  = 20;

    Ext.each(AIR2.Submission.ALTSUBMS, function (uuid, idx, array) {
        var item,
            uri;

        uri = AIR2.HOMEURL + '/submission/' + uuid;
        item = '<a href="' + uri + '">' + (idx + 1) + '</a>';
        if (uuid === AIR2.Submission.UUID) {
            pagerPage = idx;
            item = '<strong><a href="' + uri + '">' + (idx + 1);
            item += '</a></strong>';
        }
        pagerItems.push(item);
        pagerTotal++;
    });

    // slice out items if more than MAX_SHOWN
    if (totalUuids > MAX_SHOWN) {
        s = Math.ceil(pagerPage - (MAX_SHOWN / 2));
        if (s < 0) {
            s = 0;
        }
        e = s + MAX_SHOWN;

        if (e > totalUuids) {
            e = totalUuids;
        }
        pagerItems = pagerItems.slice(s, e);
        if (e < totalUuids) {
            pagerItems.push('...');
        }
        if (s > 0) {
            pagerItems.unshift('...');
        }
    }

    prevButton = new Ext.Toolbar.Button({
        tooltip: 'Prev',
        overflowText: 'Prev',
        iconCls: 'x-tbar-page-prev',
        disabled: (pagerPage === 0) ? true : false,
        handler: function () {
            window.location = AIR2.HOMEURL + '/submission/' +
                AIR2.Submission.ALTSUBMS[pagerPage - 1];
        }
    });

    firstButton = new Ext.Toolbar.Button({
        tooltip: 'First',
        overflowText: 'First',
        iconCls: 'x-tbar-page-first',
        disabled: (pagerPage === 0) ? true : false,
        handler: function () {
            window.location = AIR2.HOMEURL + '/submission/' +
                AIR2.Submission.ALTSUBMS[0];
        }
    });

    pagerItems.unshift('-');
    pagerItems.unshift(prevButton);
    pagerItems.unshift(firstButton);
    nextButton = new Ext.Toolbar.Button({
        tooltip: 'Next',
        overflowText: 'Next',
        iconCls: 'x-tbar-page-next',
        disabled: (pagerPage === (totalUuids - 1)) ? true : false,
        handler: function () {
            window.location = AIR2.HOMEURL + '/submission/' +
                AIR2.Submission.ALTSUBMS[pagerPage + 1];
        }
    });

    lastButton = new Ext.Toolbar.Button({
        tooltip: 'Last',
        overflowText: 'Last',
        iconCls: 'x-tbar-page-last',
        disabled: (pagerPage === (totalUuids - 1)) ? true : false,
        handler: function () {
            window.location = AIR2.HOMEURL + '/submission/' +
                AIR2.Submission.ALTSUBMS[pagerTotal - 1];
        }
    });

    pagerItems.push('-');
    pagerItems.push(nextButton);
    pagerItems.push(lastButton);

    pagerItems.push('->');
    pagerItems.push(
        'Viewing submission ' + (pagerPage + 1) + ' of ' + pagerTotal
    );
    pager = new Ext.Toolbar({cls: 'air2-pager', items: pagerItems});

    inqTitle = AIR2.Submission.BASE.radix.Inquiry;
    inqTitle = AIR2.Format.inquiryTitle(inqTitle, true, 60);

    summaryTemplate = new Ext.XTemplate(
        // manual-entry header
        '<tpl if="AIR2.Submission.BASE.radix.srs_type === \'E\'">' +
            '<div class="subm-summary-inq air2-icon air2-icon-user">' +
                '<div class="creator">' +
                    'Submission entered by ' + submcre + ' ' + submorg +
                    ' on <b>' + submdtim + '</b></div>' +
            '</div>' +
            '<div class="subm-summary-inq air2-icon air2-icon-project">' +
                '<div class="project">For project ' + inqproj + '</div>' +
            '</div>' +
        '</tpl>' +
        // regular-ol' header
        '<tpl if="AIR2.Submission.BASE.radix.srs_type !== \'E\'">' +
            '<div class="subm-summary-inq">' +
                '<div class="creator">' +
                    'Query published by <strong style="font-weight: bold;">'+ inqcre +'</strong> ' + inqorg +
                    'on <b>' + inqdtim + '</b>' +
                '</div>' +
            '</div>' +
        '</tpl>' +
        '<div class="subm-summary-publish-meta"></div>' +

        // metadata
        '<tpl for=".">' +
                '<ul class="sub-meta {.:this.publishState}">' +
                        '<li>' +
                            '' + srclink + '' +
                            ' <span>|</span> ' +
                            '' + submwhen + '' +
                        '</li>' +
                        '<li>Referring URL: {.:this.refUrl}</li>' +
                        '<li class="publishStatusItem">' +
                            '{.:this.displayPublishState}' +
                            '<tpl if="this.isSpinning">' +
                                '<span class="spinner"><img src="' + AIR2.HOMEURL + '/css/img/loading.gif"/></span>' +
                            '</tpl>' +
                        '</li>' +
                '</ul>' +
        '</tpl>',
        {
            isSpinning: false,
            compiled: true,
            displayPublishState: function (submission_data, values) {
                var display,
                    may_write,
                    publish_state,
                    status,
                    theClass,
                    title;

                // get publish authz
                may_write = false;
                Ext.each(values.Inquiry.InqOrg, function (io) {
                    if (
                        AIR2.Util.Authz.hasAnyId(
                            'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                            [io.iorg_org_id])
                        ) {
                        may_write = true;
                    }
                });

                publish_state = submission_data.publish_flags;

                if (publish_state != AIR2.Reader.CONSTANTS.UNPUBLISHABLE) {
                    display = '<a href="' + AIR2.Submission.URL + '.json';
                    display += '" data-srs_uuid="' + values.srs_uuid;
                    display += '" data-perm_resp="';
                    display += summaryView.tpl.PRIVACYRESPONSE;
                    display += '" data-publish_state="' + publish_state;
                    display += '" class="publishStatus ';
                }
                else {
                    //If it's unpublishable, we don't want to display anything.
                    return '';
                }

                theClass = "";
                status = 'Unpublishable';

                if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.PUBLISHED
                ) {
                    theClass += " published";
                    status = 'Published';
                }
                else if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.PUBLISHABLE
                ) {
                    theClass += " unpublished";
                    status = 'Unpublished';
                }
                else if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH
                ) {
                    theClass = 'nothing-to-publish';
                    status = 'Nothing to publish';
                }
                else if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
                ) {
                    theClass = 'unpublished-private';
                    status = 'Private';
                }

                // undo if no authz
                if (!may_write) {
                    display = '<span';
                    display += theClass + '">' + status + '</span>';
                    return display;
                }

                display += theClass + '"';

                
                display += '>' + status + '</a>';

                return display;
            },
            publishState: function (submission_data) {

                var publish_state = submission_data.publish_flags;

                if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                    return 'published';
                }
                else if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.UNPUBLISHABLE
                ) {
                    return 'unpublishable';
                }
                else {
                    return 'notPublished';
                }
            },
            refUrl: function (submission_data) {
                if (submission_data.srs_uri) {
                    return '<span class="copy-ref-url" title="' +
                        submission_data.srs_uri + '">' +
                        Ext.util.Format.ellipsis(submission_data.srs_uri, 50) +
                        '</span>';
                }

                return "(none)";
            },
            permaLink: function (srs_uuid) {
                if (srs_uuid) {
                    return AIR2.HOMEURL + '/submission/' + srs_uuid;
                }

                return '#';
            },
            receivedBy: function (inquiry_creator) {
                if (inquiry_creator) {
                    return AIR2.Format.userName(inquiry_creator, 1, 1);
                }
                else {
                    return "(none)";
                }
            },
        }
    );

    summaryView = new AIR2.UI.JsonDataView({
        id:           'air2-submission-publish-meta-view',
        renderEmpty:  true,
        tpl:          summaryTemplate,
        itemSelector: '.sub-meta',
        url:          AIR2.Submission.URL + '.json',
        listeners: {
            load: function () {
                var submissionButton = Ext.select('a.publishStatus');
                submissionButton = Ext.get(submissionButton.elements[0]);
                if (submissionButton) {
                    var publish_state = submissionButton.getAttribute('data-publish_state');
                    var title = 'This submission cannot be published because there ';
                    title += 'are no publishable questions.';
                    

                    if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                        title = 'Unpublishing this submission will remove it from ';
                        title += 'the Publish API, making it private.';
                    }
                    else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                        title = 'Publishing this submission will include it in the';
                        title += ' Publish API, making it visible to the public.';
                    }
                    else if (
                        publish_state == AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH
                    ) {
                        title = 'This submission cannot be published because ';
                        title += 'there is nothing to approve. Please select ';
                        title += 'responses to include.';
                    }
                    else if (
                        publish_state == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
                    ) {
                        title = 'Source has not given permission to publish ';
                        title += 'this submission. If you\'ve received ';
                        title += 'permission, click to override.';
                    }

                    submissionButton.tooltip = new Ext.ToolTip({
                        target: submissionButton.id,
                        html: title,
                        showDelay: 2000,
                        baseCls: 'air2-tip'
                    });
                }
            },
            
        }
    });
    AIR2.Submission.publishHandler(summaryView);
    AIR2.Submission.refUrl(summaryView);

    viewTemplate = new Ext.XTemplate(
        // responses
        AIR2.Submission.Responses.SrcResponseTemplate(
            {context: '.', includeAnnotations: true}
        ),
        {
            compiled: true,
            //disableFormats: true
            includeExcludeButton: function (sr_public_flag, values) {
                var includeExcludeButton,
                    may_write,
                    question_public,
                    question_type;

                may_write = false;
                Ext.each(
                    AIR2.Submission.BASE.radix.Inquiry.InqOrg,
                    function (io) {
                        if (
                            AIR2.Util.Authz.hasAnyId(
                                'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                                [io.iorg_org_id]
                            )
                        ) {
                            may_write = true;
                        }
                    }
                );

                question_type   = values.Question.ques_type;
                question_public = values.Question.ques_public_flag;
                if (question_type.toLowerCase() === 'p' || !question_public) {
                    return '';
                }

                // if no authz, no action
                if (!may_write) {
                    if (sr_public_flag) {
                        return '<span class="air2-icon air2-icon-check" ' +
                            'ext:qtip="You do not have permission to change ' +
                            'status.">Included for Publishing</span>';
                    }
                    else {
                        return '<span class="air2-icon air2-icon-prohibited" ' +
                        'ext:qtip="You do not have permission to change ' +
                        'status.">Excluded from Publishing</span>';
                    }
                }

                includeExcludeButton = ' <div ';
                includeExcludeButton += 'class="air2-btn air2-btn-friendly ';
                includeExcludeButton += 'air2-btn-medium x-btn-text-icon">';

                if (sr_public_flag === 1 || sr_public_flag === true) {
                    includeExcludeButton +=
                        '<button ' +
                            'class="x-btn-text air2-icon-check" ' +
                            'onMouseOver=' +
                                '"this.innerHTML=\'Exclude From Publishing\'"' +
                            ' onMouseOut=' +
                                '"this.innerHTML=\'Included For Publishing\'"' +
                            ' onclick=' +
                                '"AIR2.Submission.Responses.togglePublic(\'' +
                                    values.sr_uuid + '\', \'' +
                                    sr_public_flag + '\')"> ' +
                                    'Included for Publishing' +
                        '</button>';
                }
                else {
                    includeExcludeButton += '<button class=' +
                        '"air2-icon x-btn-text air2-icon-prohibited" ' +
                        'onMouseOver=' +
                            '"this.innerHTML=\'Include For Publishing\'" ' +
                        'onMouseOut=' +
                            '"this.innerHTML=\'Excluded From Publishing\'" ' +
                        'onclick=' +
                            '"AIR2.Submission.Responses.togglePublic(\'' +
                                values.sr_uuid + '\',\'' +
                                sr_public_flag + '\'' +
                            ')"> Excluded from Publishing</button>';
                }
                includeExcludeButton += '</div>';

                return includeExcludeButton;
            },
            editButton: function (sr_public_flag, values) {
                var editResponse,
                    is_permission_question,
                    may_write,
                    publish_flag,
                    question_public,
                    question_type;

                // get publish authz
                may_write = false;
                Ext.each(
                    AIR2.Submission.BASE.radix.Inquiry.InqOrg,
                    function (io) {
                        if (
                            AIR2.Util.Authz.hasAnyId(
                                'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                                [io.iorg_org_id]
                            )
                        ) {
                            may_write = true;
                        }
                    }
                );
                if (!may_write) {
                    return '';
                }

                publish_flag = AIR2.Submission.Responses.getPublishFlag();

                if (publish_flag === AIR2.Reader.CONSTANTS.UNPUBLISHABLE) {
                    return '';
                }

                question_type   = values.Question.ques_type;
                question_public = values.Question.ques_public_flag;

                is_permission_question = (question_type.toLowerCase() === 'p');

                //if the question isn't public or the answer isn't public
                //then we can't edit unless it's the permission question
                if (
                    (!question_public || !sr_public_flag) &&
                    !is_permission_question
                ) {
                    return '';
                }

                // can't edit the permission question if the
                // question is published
                if (
                    is_permission_question &&
                    publish_flag === AIR2.Reader.CONSTANTS.PUBLISHED
                ) {
                    return '';
                }

                editResponse = ' <div class="air2-btn air2-btn-friendly ' +
                    'air2-btn-medium x-btn-text-icon">' +
                    '<button class="x-btn-text air2-icon-edit" ' +
                        'onclick="AIR2.Submission.Responses.showEdit(this, \'' +
                        values.sr_uuid +
                    '\')">' +
                        ' Edit Response ' +
                    '</button>' +
                '</div>';

                return editResponse;
            },
            lastUpdatedResponse: function (values) {
                var dateText,
                    userLink;

                userLink = '';
                if (values.sr_mod_value !== null) {
                    dateText = 'Last modified on ' +
                        AIR2.Format.dateWeek(values.sr_upd_dtim, true);
                    userLink += dateText + ' by ' +
                        AIR2.Format.userName(values.UpdUser, true, true);
                }
                return userLink;
            },
            showOriginal: function (sr_mod_value, values) {
                var hideShowOriginal = '';
                if (
                    sr_mod_value &&
                    (
                        values.sr_public_flag === 1 ||
                        values.sr_public_flag === true
                    )
                ) {
                    hideShowOriginal = '';
                }
                else if (sr_mod_value) {
                    hideShowOriginal = 'hidden';
                }
                else {
                    return '';
                }
                return '<div class="air2-btn air2-btn-friendly ' +
                    'air2-btn-medium x-btn-text-icon ' + hideShowOriginal +
                    '">' +
                    '<button class="air2-icon x-btn-text air2-icon-original" ' +
                    'onclick="AIR2.Submission.Responses.showOriginal(this, \'' +
                    values.sr_uuid + '\')"> Show Original </button></div>';

            }
        }
    );

    printBtn = new AIR2.UI.Button({
        air2size: 'MEDIUM',
        air2type: 'FRIENDLY',
        text: 'Print-friendly',
        iconCls: 'air2-icon-printer',
        style: 'float:right',
        handler: function () {
            window.open(AIR2.Submission.URL + '.phtml');
        }
    });


    defaultConfig = {
        id: 'air2-submission-responses',

        colspan: 2,
        rowspan: 3,
        // not sure why this min-height was set but it breaks the
        // "bottom alignment" of the pager on submissions with only
        // 1 or 2 responses.
        //style: 'min-height: 300px',
        title: inqTitle,
        cls: 'air2-submission-response',
        iconCls: 'air2-icon-list',
        storeData: AIR2.Submission.RESPDATA,
        url: AIR2.Submission.URL + '/response.json',
        tools: [
            '->',
            '<span class="count-box air2-corners3">' +
                '<a href="' + href + '">' +
                    '&#171; ' + count + ' Submissions' +
                '</a>' +
            '</span>'
        ],
        itemSelector: '.subm-response',
        items: [printBtn, summaryView],
        fbar: pager,
        tpl: viewTemplate,
        listeners: {
            'beforerender': function (panel) {
                var items,
                    responses,
                    saveCallback;

                items = panel.getBody().items;
                responses = items.removeAt(0);
                items.add(responses);

                //any changes may affect the publish meta data
                saveCallback = function () {
                    summaryView.store.reload();
                };
                panel.store.addListener('save', saveCallback, this);
            }
        }
    };

    // Allow overrides.
    if (config) {
        Ext.apply(defaultConfig, config);
    }

    /* return the panel */
    p = new AIR2.UI.Panel(defaultConfig);

    // find the privacy Question
    p.store.each(function () {
        var question_info = this.get('Question');
        if (question_info.ques_type.toLowerCase() === 'p') {
            summaryView.tpl.PRIVACYRESPONSE = this.get('sr_uuid');
        }
    });

    return p;
};

AIR2.Submission.Responses.SrcResponseTemplate = function (config) {
    var annots = '';

    if (config.includeAnnotations) {
        annots =
        '<div class="annotation">' +
            '<div ' +
                'class="air2-btn air2-btn-friendly air2-btn-medium ' +
                'x-btn-text-icon" >' +
                '<button class=' +
                    '"air2-icon x-btn-text air2-icon-annotation" ' +
                    'onclick="AIR2.Submission.Responses.showAnnotation(' +
                        'this, ' +
                        '\'{sr_uuid}\'' +
                    ')">' +
                    '{[fm.plural(values.annot_count,"Annotation")]}' +
                '</buttton>' +
            '</div>' +
        '</div>';
    }

    return '<ol class="response-list" style="width:615px;">' +
        '<tpl for="' + config.context + '">' +
            '<li class="subm-response {values.sr_uuid}">' +
                '<div class="question">' +
                    '<b>{[values.Question.ques_value]}</b>' +
                '</div>' +
                '<div class="response hyphenate">' +
                '{[AIR2.Util.Response.formatResponse(values)]}' +
                '<p class="last-mod" id="lastUpdate{sr_uuid}">' +
                    '{.:this.lastUpdatedResponse}' +
                '</p>' +
                '</div>' +
                '<div class="clearfix">' +
                    annots +
                    '<div class="spin-icon">' +
                        '&nbsp;' +
                    '</div>' +
                    '<div class="modify-response">' +
                        '{sr_public_flag:this.includeExcludeButton}' +
                        '{sr_public_flag:this.editButton(values)}' +
                        '{sr_mod_value:this.showOriginal(values)}' +
                    '<div>' +
                '</div>' +
            '</li>' +
        '</tpl>' +
    '</ol>';


};
