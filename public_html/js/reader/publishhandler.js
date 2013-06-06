/***************
 * Source response annotation handler for the reader
 */
AIR2.Reader.publishHandler = function (dv) {

    var publishTpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="anns clearfix pub-row">' +
                '<p>' +
                    'Source has not given permission to publish this ' +
                    'submission. If you have received permission, click ' +
                    '\'Yes\' to override.' +
                '</p>' +
                '<button class="pub-save">Yes</button> ' +
                '<button class="pub-cancel">No</button> ' +
            '</div>' +
        '</tpl>',
        {
            compiled: true
        }
    );

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {

        // expand/add clicked
        dv.el.on('click', function (e) {
            var clickListener,
                link,
                list,
                parentListItem,
                permissionColumn,
                permissionQuestion,
                permissionQuestionLink,
                perm_resp,
                publicColumn,
                publish_state,
                rec,
                srs_uuid,
                url,
                xpandr;
                
            if (e.getTarget('a.publishStatus')) {
                e.preventDefault();
                
                xpandr = Ext.Element.get(e.getTarget('a.publishStatus'));
                xpandr.mask('<img src="' + AIR2.HOMEURL + '/css/img/loading.gif"/>');
                
                url = xpandr.getAttribute('href');
                publish_state = xpandr.getAttribute('data-publish_state');
                srs_uuid = xpandr.getAttribute('data-srs_uuid');
                rec = dv.store.getById(srs_uuid);
                parentListItem = xpandr.parent();
                list = parentListItem.parent();
                link = parentListItem.first();
                permissionQuestion = list.parent().child('a.permission');
                permissionQuestionLink = Ext.Element.get(permissionQuestion);

                publicColumn = Ext.get('publish-state-' + srs_uuid);
                permissionColumn = Ext.get('permission-' + srs_uuid);

                if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                    rec.data.srs_public_flag = 0;
                    xpandr.inFlight = true; // so mouseover/mouseout know to ignore
                    Ext.Ajax.request({
                        url: url,
                        method: 'PUT',
                        params: {
                            radix: Ext.util.JSON.encode({
                                srs_public_flag: 0
                            })
                        },
                        success: function (resp, ajax, opts) {
                            
                            Logger('is un-published');
                            
                            var qtip, r;
                            r = Ext.decode(resp.responseText);
                            rec.data.publish_state = r.radix.publish_flags;
                            
                            // TODO what is this for?
                            //list.removeClass('published');
                            //list.addClass('notPublished');

                            if (xpandr.tooltip.body) {
                                xpandr.tooltip.body.dom.innerHTML = AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE;
                            }
                            else {
                                Logger('no tooltip.body on xpandr:', xpandr);
                            }
                            
                            xpandr.dom.innerHTML = "Unpublished";
                            xpandr.isPublished = false;

                            if (xpandr.hasClass('published')) {
                                //Logger('unpublished has class published');
                                xpandr.toggleClass('published');
                            }
                            if (!xpandr.hasClass('unpublished')) {
                                //Logger('unpublished not yet set');
                                xpandr.addClass('unpublished');
                            }
                            
                            link.dom.setAttribute(
                                'data-publish_state',
                                r.radix.publish_flags
                            );

                            if (permissionQuestionLink) {
                                permissionQuestionLink.toggleClass('hidden');
                                permissionQuestionLink.toggleClass('rollover');
                            }
                            if (publicColumn) {
                                publicColumn.toggleClass("air2-icon-check");
                                publicColumn.toggleClass("air2-icon-uncheck");
                                publicColumn.set({'ext:qtip': qtip});
                            }
                            xpandr.unmask();
                            xpandr.inFlight = false;
                            
                        },

                        // rollback on failure
                        failure: function (resp, ajax, opts) {
                            Logger(resp);
                            Logger('failed to PUT change to srs_public_flag');
                            rec.data.srs_public_flag = 1;
                            xpandr.unmask();
                            xpandr.inFlight = false;
                        }
                    });
                }
                else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                    rec.data.srs_public_flag = 1;
                    xpandr.inFlight = true; // so mouseover/mouseout know to ignore
                    Ext.Ajax.request({
                        url: url,
                        method: 'PUT',
                        params: {
                            radix: Ext.util.JSON.encode({
                                srs_public_flag: 1
                            })
                        },
                        success: function (resp, ajax, opts) {
                            
                            Logger('is published');
                            
                            var qtip, r;

                            r = Ext.decode(resp.responseText);
                            rec.data.publish_state = r.radix.publish_flags;
                            
                            // TODO what is this for?
                            //list.removeClass('notPublished');
                            //list.addClass('published');
                            
                            qtip = AIR2.Reader.CONSTANTS.PUBLISHED_TITLE;
                                                       
                            //xpandr.tooltip.body.dom.innerHTML = AIR2.Reader.CONSTANTS.PUBLISHED_TITLE;
                            
                            xpandr.dom.innerHTML = "Published";
                            xpandr.isPublished = true;

                            if (!xpandr.hasClass('published')) {
                                xpandr.addClass('published');
                            }
                            if (xpandr.hasClass('unpublished')) {
                                xpandr.removeClass('unpublished');
                            }
                            
                            link.dom.setAttribute(
                                'data-publish_state',
                                r.radix.publish_flags
                            );

                            if (permissionQuestionLink) {
                                permissionQuestionLink.toggleClass('hidden');
                                permissionQuestionLink.toggleClass('rollover');
                            }
                            if (publicColumn) {
                                publicColumn.toggleClass("air2-icon-uncheck");
                                publicColumn.toggleClass("air2-icon-check");
                                publicColumn.set({'ext:qtip': qtip});
                            }
                            
                            xpandr.unmask();
                            xpandr.inFlight = false;
                        },

                        // rollback on failure
                        failure: function (resp, ajax, opts) {
                            Logger(resp);
                            Logger('failed to PUT change to srs_public_flag');
                            rec.data.srs_public_flag = 0;
                            xpandr.unmask();
                            xpandr.inFlight = false;
                        }
                    });
                }
                else if (
                    publish_state == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
                ) {
                    perm_resp = xpandr.getAttribute('data-perm_resp');

                    if (xpandr.dv) {
                        if (xpandr.dv.isVisible()) {
                            xpandr.dv.hide();
                        }
                        else {
                            Logger('xpandr is hidden');
                            xpandr.dv.show();
                        }
                    }
                    else {
                        Logger('no xpandr.dv');
                        if (!perm_resp || perm_resp === 'undefined') {
                            return;
                        }

                        clickListener = function (xpdv, idx, node, e) {
                            var edit_target,
                                edit_view,
                                responsePanel,
                                scroller;

                            if (e.getTarget('.pub-save')) {
                                if (AIR2.Reader.showEditWindow) {
                                    permissionQuestionLink.dom.click();
                                    AIR2.Reader.scrollToPermission(
                                        permissionQuestionLink
                                    );
                                }
                                else {
                                    responsePanel = Ext.getCmp(
                                        'air2-submission-responses'
                                    );
                                    //find the permission question
                                    // and show its' edit view
                                    edit_target = responsePanel.getBody(
                                    ).el.child(
                                        '.' + perm_resp
                                    );

                                    edit_view =
                                        AIR2.Submission.Responses.showEdit(
                                            edit_target,
                                            perm_resp
                                        );
                                    edit_view.show();
                                    scroller = function (scroll_target) {
                                        Ext.getBody().scrollTo(
                                            'top',
                                             scroll_target.el.getY(),
                                             false
                                        );
                                    };
                                    if (edit_view.isVisible()) {
                                        scroller(edit_view);
                                    }
                                }
                                xpandr.unmask();
                                xpandr.inFlight = false;
                                xpandr.dv.hide();
                            }
                            else if (e.getTarget('.pub-cancel')) {
                                xpandr.unmask();
                                xpandr.inFlight = false;
                                xpandr.dv.hide();
                            }
                        };

                        xpandr.dv = new AIR2.UI.JsonDataView({
                            renderTo:     xpandr.parent(),
                            renderEmpty:  true,
                            tpl:          publishTpl,
                            cls:          'anns-ct',
                            itemSelector: '.pub-row',
                            url:          url,
                            baseParams:   {sort: 'srs_cre_dtim asc'},
                            // create/edit/delete click handlers
                            listeners: {
                                click: clickListener
                            }
                        });
                    }
                }
            }
        });

    });

};

AIR2.Reader.publishButtonMouseOver = function(event, htmlEl, obj) {
    var el = Ext.get(htmlEl);
    var cls = el.getAttribute('class');
    //Logger("mouseover ", cls, ' isPublished='+el.isPublished);
    if (!cls) {
        return;  // often this is the mask
    }
    
    // no-ops
    if (el.hasClass('nothing-to-publish') || el.hasClass('unpublished-private')) {
        //Logger('mouseover, nothing-to-publish || unpublished-private', cls);
        return;
    }
    
    // catch cases where XHR action is in flight
    if (el.inFlight) {
        //Logger('mouseover, inflight, hasClass("published")=', el.hasClass('published'));
        return;
    }
    if (!el.getAttribute('class')) {
        //Logger('mouseover no class defined');
        return;
    }
    if (typeof el.isPublished === 'undefined') {
        //Logger("mouseover isPublished flag is undefined");
        return;
    }
    
    if (el.isPublished) {
        el.removeClass('published');
        el.addClass('unpublish');
        el.removeClass('publish');
        htmlEl.prevHTML = htmlEl.innerHTML;
        htmlEl.innerHTML = 'Unpublish';
    }
    else {
        el.addClass('publish');
        el.removeClass('unpublished');
        el.removeClass('published');
        htmlEl.prevHTML = htmlEl.innerHTML;
        htmlEl.innerHTML = 'Publish';
    }
}

AIR2.Reader.publishButtonMouseOut = function(event, htmlEl, obj) {
    var el = Ext.get(htmlEl);
    var cls = el.getAttribute('class');
    //Logger("mouseout ", cls, ' isPublished='+el.isPublished);
    if (!cls) {
        return;  // often this is the mask
    }
    
    // no-ops
    if (el.hasClass('nothing-to-publish') || el.hasClass('unpublished-private')) {
        return;
    }
    
    // catch cases where XHR action is in flight
    if (el.inFlight) {
        //Logger('mouseout, inflight, hasClass("published")=', el.hasClass('unpublish'));
        return;
    }
    if (!el.getAttribute('class')) {
        //Logger('mouseout no class defined');
        return;
    }
    if (typeof el.isPublished === 'undefined') {
        //Logger("mouseout isPublished flag is undefined");
        return;
    }
    
    // catch cases where we were in flight and now leaving
    if (htmlEl.innerHTML == 'Published' && el.hasClass('publish')) {
        //Logger('got mismatch on Published');
        el.removeClass('publish');
        el.addClass('published');
        return;
    }
    if (htmlEl.innerHTML == 'Unpublished' && el.hasClass('unpublish')) {
        //Logger('got mismatch on Unpublished');
        el.removeClass('unpublish');
        el.addClass('unpublished');
        return;
    }
    
    // normal (no click) mouse out
    if (el.isPublished) {
        el.addClass('published');
        el.removeClass('unpublish');
        el.removeClass('unpublished');
        htmlEl.innerHTML = htmlEl.prevHTML;
    }
    else {
        el.removeClass('publish');
        el.addClass('unpublished');
        el.removeClass('unpublish');
        htmlEl.innerHTML = htmlEl.prevHTML;
    }
}

AIR2.Reader.updatePublicStatus  = function (url, listItem) {
    var xpandr = listItem;
    Ext.Ajax.request({
        url: url,
        failure: function () {
            Logger('fail to update public status');
        },
        callback: function (opt, success, response) {
            var json = Ext.decode(response.responseText);
            AIR2.Reader.setPublishStateDisplay(
                json.radix.publish_flags,
                json.radix.srs_uuid
            );
        }
    });
};

/* Set the display on the column and the expanded-view panel
 * for the Publish State of the SRS.
 */
AIR2.Reader.setPublishStateDisplay = function (publish_flags, srs_uuid) {
    var link,
        list,
        publicColumn,
        publishingListItem,
        qtip;

    publicColumn        = Ext.get('publish-state-' + srs_uuid);
    publishingListItem  = Ext.get('srs-publish-state-' + srs_uuid);
    list = publishingListItem.parent();
    link = publishingListItem.first();

    link.dom.setAttribute('data-publish_state', publish_flags);

    if (publish_flags == AIR2.Reader.CONSTANTS.PUBLISHED) {

        // clear any existing classes
        list.removeClass('notPublished');
        list.removeClass('unpublished-private');
        list.removeClass('nothing-to-publish');

        // add new classes
        list.addClass('published');

        link.dom.innerHTML = "Published";
        link.addClass('published');
       
        // listeners to handle hover labels 
        link.on('mouseover', AIR2.Reader.publishButtonMouseOver);
        link.on('mouseout', AIR2.Reader.publishButtonMouseOut);
        link.isPublished = true;
        
        if (link.tooltip) {
            link.tooltip.html = AIR2.Reader.CONSTANTS.PUBLISHED_TITLE;
        }
        if (publicColumn) {
            publicColumn.removeClass([
                'air2-icon-lock',
                'air2-icon-uncheck',
                'air2-icon-prohibited-disabled',
                'scroll-to-permission',
                'air2-icon-uncheck-disabled'
            ]);
            publicColumn.addClass("air2-icon-check");
            publicColumn.addClass('public-state');
            publicColumn.set({'ext:qtip': qtip});
        }
    }
    else if (publish_flags == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
        list.removeClass('published');
        list.addClass('notPublished');
        link.removeClass('published');
        link.removeClass('nothing-to-publish');
        link.removeClass('unpublished-private');
        link.dom.innerHTML = "Unpublished";
        link.addClass('unpublished');
        
        link.on('mouseover', AIR2.Reader.publishButtonMouseOver);
        link.on('mouseout', AIR2.Reader.publishButtonMouseOut);
        link.isPublished = false;

        qtip = AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE;
        if (link.tooltip) {
            link.tooltip.html = AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE;
        }

        if (publicColumn) {
            publicColumn.removeClass([
                'air2-icon-lock',
                'air2-icon-check',
                'air2-icon-prohibited-disabled',
                'scroll-to-permission',
                'air2-icon-uncheck-disabled'
            ]);
            publicColumn.addClass("air2-icon-uncheck");
            publicColumn.addClass('public-state');
            publicColumn.set({'ext:qtip': qtip});
        }
    }
    else if (publish_flags == AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH) {
        list.removeClass('published', 'unpublished');
        link.dom.innerHTML = "Nothing to Publish";
        link.removeClass('unpublished');
        link.removeClass('unpublished-private');
        link.removeClass('published');
        link.addClass('nothing-to-publish');
        if (link.tooltip) {
            link.tooltip.html = AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH_TITLE;
        }
        link.on('mouseover', AIR2.Reader.publishButtonMouseOver);
        link.on('mouseout', AIR2.Reader.publishButtonMouseOut);
        link.isPublished = false;
        if (publicColumn) {
            publicColumn.removeClass([
                'air2-icon-lock',
                'air2-icon-check',
                'air2-icon-prohibited-disabled',
                'scroll-to-permission',
                'public-state',
                'air2-icon-uncheck'
            ]);
            publicColumn.addClass("air2-icon-uncheck-disabled");
            publicColumn.set({
                'ext:qtip': AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH_TITLE
            });
        }
    }
    else if (publish_flags == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE) {
        list.removeClass('published', 'unpublished');
        link.addClass('unpublished-private');
        link.dom.innerHTML = "Private";
        if (link.tooltip) {
            link.tooltip.html = AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE_TITLE;
        }
        link.on('mouseover', AIR2.Reader.publishButtonMouseOver);
        link.on('mouseout', AIR2.Reader.publishButtonMouseOut);
        link.isPublished = false;
        if (publicColumn) {
            publicColumn.removeClass([
                'air2-icon-uncheck',
                'air2-icon-check',
                'air2-icon-prohibited-disabled',
                'public-state',
                'air2-icon-uncheck-disabled'
            ]);
            publicColumn.addClass("air2-icon-lock");
            publicColumn.addClass('scroll-to-permission');
            publicColumn.set({
                'ext:qtip': AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE_TITLE
            });
        }
    }
    else {
        list.removeClass('published', 'notPublished');
        list.addClass('unpublishable');
        link.remove();
    }

};
