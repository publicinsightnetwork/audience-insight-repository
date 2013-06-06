/***************
 * Source response edit handler for the reader
 */

AIR2.Reader.editRespHandler = function (dv) {

    var editTpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="anns clearfix anns-row">' +
                '<div class="ann">' +
                    '{sr_orig_value:this.renderWindow(values)}' +
                    '<button class="resp-save">Save</button> ' +
                    '<button class="resp-cancel">Cancel</button> ' +
                '</div>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            showValue: function (sr_orig_value, values) {
                var showValue = sr_orig_value;
                if (
                    values.sr_mod_value !== null &&
                    values.sr_mod_value !== ''
                ) {
                    showValue = values.sr_mod_value;
                }
                return showValue;
            },

            renderOptions: function (sr_orig_value, values) {
                return AIR2.Util.Response.formatOptions(values);
            },

            renderWindow: function(sr_orig_value, values) {
                if (!values.Question.ques_choices) {
                    var shownValue = this.showValue(sr_orig_value, values);
                    if (shownValue === null) {
                        shownValue = '';
                    }
                    return '<textarea>'+shownValue+'</textarea>';
                } else {
                    return this.renderOptions(sr_orig_value, values);
                }

            }
        }
    );

    // edit template
    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {
        dv.el.on('click', AIR2.Reader.handleClick);
    });
    AIR2.Reader.handleClick = function (e) {
        var xpandr, responseMetaEl, annotations, sr_uuid, showOriginal;

        if (e.getTarget('a.edit')) {
            e.preventDefault();
            xpandr = e.getTarget('a.edit', 5, true);

            // check for already-expanded
            if (xpandr.dv && xpandr.dv.isVisible()) {
                xpandr.dv.hide();
            }
            else {
                sr_uuid = xpandr.getAttribute('data-sr_uuid');

                // hide annotations
                responseMetaEl = Ext.get('response-meta-'+sr_uuid);
                //Logger(responseMetaEl, xpandr);
                annotations = Ext.select('.sran-expand', false, responseMetaEl.dom).elements;
                Ext.each(annotations, function (annotation, index) {
                    annotation = Ext.get(annotation);
                    if(annotation.dv) {
                        annotation.dv.hide();
                    }
                });
                
                // do not hide original -- let Edit and Original display simultaneously
                /*
                showOriginal = Ext.get('response-orig-val-'+sr_uuid);
                if (showOriginal && showOriginal.isVisible()) {
                    showOriginal.setVisibilityMode(Ext.Element.DISPLAY);
                    showOriginal.hide();
                    Ext.get('response-show-original-button-'+sr_uuid).first().dom.innerHTML = 'Show Original';
                }
                */

                // show edit window
                if (!xpandr.dv) {
                    AIR2.Reader.showEditWindow(xpandr);
                } 
                xpandr.dv.show();
            }

        }
    };

    AIR2.Reader.showEditWindow = function (xpandr) {
        var renderTarget, sr_uuid;
        
        sr_uuid = xpandr.getAttribute('data-sr_uuid');
        renderTarget = Ext.get('response-entry-'+sr_uuid);
        //Logger('renderTarget:', renderTarget);
        xpandr.dv = new AIR2.UI.JsonDataView({
            renderTo:     renderTarget,
            renderEmpty:  true,
            tpl:          editTpl,
            cls:          'anns-ct',
            itemSelector: '.anns-row',
            url:          xpandr.getAttribute('href'),
            baseParams:   {limit: 99, sort: 'sr_cre_dtim asc'},

            // create/edit/delete click handlers
            listeners: {
                click: function (xpdv, idx, node, e) {
                    var publishListItem,
                        qa_idx,
                        qa_mod,
                        ques_type,
                        ques_uuid,
                        rec,
                        respEl,
                        responseArea,
                        search_rec,
                        srs_uuid,
                        txt,
                        url,
                        val;

                    if (e.getTarget('.resp-save')) {
                        respEl = e.getTarget('.resp-save', 5, true);
                        if (respEl) {
                            rec = xpdv.store.getAt(idx);
                            ques_type =
                                rec.data.Question.ques_type.toLowerCase();
                            ques_uuid = rec.data.Question.ques_uuid;

                            txt = respEl.prev('textarea');
                            if (txt) {
                                val = txt.getValue();
                                if (val == '') {
                                    val = rec.get('sr_orig_value');
                                }
                            } 
                            else {
                                //Logger('no textarea, ques_type=', ques_type);
                                ques_uuid = rec.data.Question.ques_uuid;
                                var name = 'group' + ques_uuid;
                                if (ques_type == 'r' || ques_type == 'c' || ques_type == 'p') {
                                    var selectString = 'div.ann input[name='+name+']:checked';
                                    //Logger('looking for ', selectString);
                                    var selected = Ext.select(selectString);
                                    selected = selected.elements;
                                    //Logger('selected:', selected);
                                    val = '';
                                    Ext.each(selected, function(option, index) {
                                        option = Ext.get(option);
                                        if (val != '') {
                                            val += '|';
                                        }
                                        val += option.getValue();
                                    });
                                }
                                else if (ques_type == 'l' || ques_type == 'o') {
                                    var selectString = 'div.ann select[name='+name+'] option';
                                    //Logger('looking for ', selectString);
                                    var selected = Ext.select(selectString);
                                    //Logger('selected:', selected);
                                    var options = selected.elements;
                                    val = '';
                                    Ext.each(options, function(option, index) {
                                        option = Ext.get(option);
                                        if (option.getAttribute('selected')) {
                                            if (val != '') {
                                                val += '|';
                                            }
                                            val += option.getValue();
                                        }
                                        
                                    });
                                }
                            }
                            //Logger('found mod val: ', val); 
                            rec.set('sr_mod_value', val);

                            // get search result store and update that too
                            search_rec = AIR2.Reader.DV.store.getById(
                                rec.data.SrcResponseSet.srs_uuid
                            );
                            qa_mod = search_rec.get('qa_mod');
                            qa_idx = 0;
                            Ext.each(search_rec.get('qa'), function (qa, i) {
                                if (qa.sr_uuid == sr_uuid) {
                                    qa_idx = i;
                                    return false; // end loop
                                }
                            });
                            //Logger('update search store:', val, rec, qa_mod, qa_idx, search_rec);
                            qa_mod[qa_idx] = ':' + val;
                            search_rec.set('qa_mod', qa_mod);

                            if (ques_type === 'p') {
                                srs_uuid = rec.data.SrcResponseSet.srs_uuid;
                                url = AIR2.HOMEURL + '/submission/' + srs_uuid;
                                url += '.json';

                                publishListItem = Ext.get(
                                    'srs-publish-state-' + srs_uuid
                                );

                                xpdv.store.addListener('update', function () {
                                    var permissionColumn = Ext.get(
                                        'permission-' + srs_uuid
                                    );
                                    permissionColumn.dom.innerHTML = val;
                                    AIR2.Reader.updatePublicStatus(
                                        url,
                                        publishListItem
                                    );
                                });
                            }

                            xpdv.store.addListener('update', function () {
                                var dateText,
                                    fetchedLink,
                                    lastModifiedDisplay,
                                    userLink,
                                    updatedRecord,
                                    userTargetId,
                                    showOrigLink,
                                    editButtonParent;

                                updatedRecord = xpdv.store.getAt(idx);
                                userTargetId  = Ext.id(
                                    null,
                                    'air2-sr-upd-user'
                                );

                                dateText = 'Last modified on ';
                                dateText += AIR2.Format.dateWeek(
                                    updatedRecord.data.sr_upd_dtim,
                                    true
                                );

                                fetchedLink = AIR2.Util.User.fetchLink(
                                    AIR2.USERINFO.uuid,
                                    true,
                                    true,
                                    userTargetId
                                );

                                if (fetchedLink !== null) {
                                    // we have text now
                                    userLink = dateText + ' by ' + fetchedLink;
                                }
                                else {
                                    // fetchLink() will fill it in using
                                    // userTargetId
                                    userLink = dateText + ' by <span id="';
                                    userLink += userTargetId + '"></span>';
                                }

                                lastModifiedDisplay = Ext.get(
                                    'lastUpdate' + updatedRecord.data.sr_uuid
                                );

                                lastModifiedDisplay.dom.innerHTML = userLink;
                            });

                            xpdv.store.save();
                            
                            responseArea = Ext.get('response-value-'+sr_uuid);
                            
                            //Logger('responseArea:', responseArea);
                            
                            if (!Ext.get('response-show-original-button-'+sr_uuid)) {
                                showOrigLink = AIR2.Reader.makeShowOriginalLink(rec.get('sr_mod_value'), rec.data);
                                
                                // append to edit button
                                editButtonParent = Ext.get('response-edit-button-'+sr_uuid).parent();
                                editButtonParent.insertHtml('beforeEnd', showOrigLink);
                            }

                            if (val === '' || val === null) {
                                val = rec.get('sr_orig_value');
                                //Logger('val is empty, reverting to original value:', val);
                            }

                            // update response area with new value
                            if (responseArea) {
                                var dispVal = AIR2.Util.Response.formatResponse(rec.data);
                                //Logger('update dom with:', responseArea.dom, dispVal);
                                responseArea.dom.innerHTML = dispVal;
                            }
                            else {
                                Logger('FAILed to find responseArea for sr_uuid ', sr_uuid);
                            }
                        }
                        xpdv.refreshNode(idx);
                        xpandr.dv.hide();
                    }
                    else if (e.getTarget('.resp-cancel')) {
                        xpandr.dv.hide();
                    }
                }
            }
        });

    };

    AIR2.Reader.scrollToPermission = function (xpandr) {
        //var top = Ext.fly(xpandr).getTop();
        //Ext.getBody().scrollTo('top', Math.max(top - 200, 0), false);
        // use native javascript method. Ext version does not seem to work.
        xpandr.dom.scrollIntoView();
    };
};

