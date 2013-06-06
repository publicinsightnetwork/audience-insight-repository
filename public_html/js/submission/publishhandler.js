/***************
 * Source publish handler for the submission viewer
 */
AIR2.Submission.publishHandler = function (publish_meta_view) {

    var publishTpl, setupListeners;

    publishTpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="clearfix pub-row">' +
                '<p>' +
                    'Source has not given permission to publish this ' +
                    'submission. If you have received permission, ' +
                    'click \'Yes\' to override.' +
                '</p>' +
                '<span class="air2-btn air2-btn-friendly air2-btn-small">' +
                        '<button class="x-btn-text air2-btn pub-save">' +
                            'Yes' +
                        '</button> ' +
                '</span>' +
                '<span class="air2-btn air2-btn-friendly air2-btn-small">' +
                        '<button class="x-btn-text air2-btn pub-cancel">' +
                            'No' +
                        '</button> ' +
                '</span>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true
        }
    );

    /**
     * Add various click handlers to the data view
    **/
    setupListeners = function (data_view) {

        var removeStateClasses,
            setHoverState,
            mouseoutHandler,
            mouseoverHandler,
            clickHandler;

        /**
         * Clear all the potential publish state classes
         * from the supplied Ext.js object
         * @param target Ext.Element
        **/
        removeStateClasses = function (target) {
            target.removeClass(
                AIR2.Submission.publishHandler.PUBLISHED_STATE
            );
            target.removeClass(AIR2.Submission.publishHandler.PUBLISH_STATE);
            target.removeClass(
                AIR2.Submission.publishHandler.UNPUBLISHED_STATE
            );
            target.removeClass(AIR2.Submission.publishHandler.UNPUBLISH_STATE);
        };

        /**
         * Update the text of the tooltip on the publish button
         *
         * @param target Ext.Element
         * @param mode string mating one of the
         * AIR2.Submission.publishHandler state constants
        **/

        createToolTip = function (target, mode) {
            var title = '';
            if (!target.tooltip) {
                switch (mode) {
                case AIR2.Submission.publishHandler.PUBLISHED_STATE:
                    title = 'Unpublishing this submission will remove it from ';
                    title += 'the Publish API, making it private.';
                    break;
                case AIR2.Submission.publishHandler.PUBLISH_STATE:
                    title = 'Publishing this submission will include it in the';
                    title += ' Publish API, making it visible to the public.';
                    break;
                case AIR2.Submission.publishHandler.UNPUBLISHED_STATE:
                    title = 'Publishing this submission will include it in the';
                    title += ' Publish API, making it visible to the public.';
                    break;
                case AIR2.Submission.publishHandler.UNPUBLISH_STATE:
                    title = 'Unpublishing this submission will remove it from ';
                    title += 'the Publish API, making it private.';
                    break;
                }
                target.tooltip = new Ext.ToolTip({
                    target: target.id,
                    html: title,
                    showDelay: 2000,
                    baseCls: 'air2-tip'
                });
            }

        }

        var target = Ext.get(Ext.select('a.publishStatus').elements[0]);
        if(target) {
            if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.PUBLISHED_STATE
                    )
                ) {
                    createToolTip(target, AIR2.Submission.publishHandler.UNPUBLISH_STATE);

                }
                else if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.UNPUBLISHED_STATE
                    )
                ) {
                    createToolTip(target, AIR2.Submission.publishHandler.PUBLISH_STATE);

                }
        }


        setHoverState = function( target, mode) {
            switch(mode) {
                case AIR2.Submission.publishHandler.PUBLISHED_STATE:
                    removeStateClasses(target);
                    target.update('Published');
                    target.addClass('published');
                    break;
                case AIR2.Submission.publishHandler.PUBLISH_STATE:
                    removeStateClasses(target);
                    target.update('Publish');
                    target.addClass('publish');
                    break;
                case AIR2.Submission.publishHandler.UNPUBLISHED_STATE:
                    removeStateClasses(target);
                    target.update('Not Published');
                    target.addClass('unpublished');
                    break;
                case AIR2.Submission.publishHandler.UNPUBLISH_STATE:
                    removeStateClasses(target);
                    target.update('Unpublish');
                    target.addClass('unpublish');
                    break;
            }

        }

        //Handle setting publish button hover state
        mouseoverHandler = function (event) {
            var target = event.getTarget('a.publishStatus', 10, true);
            if (target) {
                if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.PUBLISHED_STATE
                    )
                ) {
                    setHoverState(
                        target,
                        AIR2.Submission.publishHandler.UNPUBLISH_STATE
                    );
                }
                else if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.UNPUBLISHED_STATE
                    )
                ) {
                    setHoverState(
                        target,
                        AIR2.Submission.publishHandler.PUBLISH_STATE
                    );
                }
            }
        };

        data_view.el.on('mouseover', mouseoverHandler);

        //Handle reverting publish button hover state
        mouseoutHandler = function (event) {
            var target = event.getTarget('a.publishStatus', 10, true);
            if (target) {
                if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.UNPUBLISH_STATE
                    )
                ) {
                    setHoverState(
                        target,
                        AIR2.Submission.publishHandler.PUBLISHED_STATE
                    );
                }
                else if (
                    target.hasClass(
                        AIR2.Submission.publishHandler.PUBLISH_STATE
                    )
                ) {
                    setHoverState(
                        target,
                        AIR2.Submission.publishHandler.UNPUBLISHED_STATE
                    );
                }
            }
        };

        data_view.el.on('mouseout', mouseoutHandler);

        //Handle publish/unpublish button click
        clickHandler = function (event) {
            var target_el,
                record,
                publish_state,
                failCallback,
                saveCallback,
                perm_resp;

            target_el = event.getTarget('a.publishStatus', 5, true);
            if (target_el) {

                data_view.tpl.isSpinning = true;

                //remove rollover and click listeners
                data_view.el.un('click', clickHandler);
                data_view.el.un('mouseover', mouseoverHandler);
                data_view.el.un('mouseout', mouseoutHandler);

                //prevent default link behavior
                data_view.el.on('click', function (e) { e.preventDefault(); });
                event.preventDefault();
                record = data_view.store.getAt(0);
                publish_state = record.get('publish_flags');
                if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                    //trick button into showing the new state

                    record.set(
                        'publish_flags',
                        AIR2.Reader.CONSTANTS.PUBLISHABLE
                    );
                    //prevent store from trying to save new state
                    record.commit();
                    //set new state
                    record.set('srs_public_flag', 0);
                }
                else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                    //trick button into showing the new state

                    record.set(
                        'publish_flags',
                        AIR2.Reader.CONSTANTS.PUBLISHED
                    );
                    //prevent store from trying to save new state
                    record.commit();
                    //set new state
                    record.set('srs_public_flag', 1);
                }
                else if (
                    publish_state ==
                    AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
                ) {

                    //find the permission response
                    perm_resp = target_el.getAttribute('data-perm_resp');

                    if (
                        data_view.permision_check_view &&
                        data_view.permision_check_view.isVisible()
                    ) {
                        //toggle already open permission speed bump
                        data_view.permision_check_view.hide();
                    }
                    else {

                        if (!data_view.permision_check_view) {
                            if (!perm_resp || perm_resp === 'undefined') {
                                setupListeners(data_view);
                                return;
                            }
                            data_view.permission_listeners = {
                                click: function (xpdv, idx, node, e) {
                                    var responsePanel,
                                        edit_target,
                                        edit_view,
                                        scroller;

                                    if (e.getTarget('.pub-save')) {
                                        responsePanel = Ext.getCmp(
                                            'air2-submission-responses'
                                        );
                                        //find the permission question and
                                        // show its' edit view
                                        edit_target = responsePanel.getBody(
                                            ).el.child(
                                                '.' + perm_resp
                                            );
                                        edit_view =
                                        AIR2.Submission.Responses.showEdit(
                                            edit_target,
                                            perm_resp
                                        );

                                        // create a callback in case the
                                        // view hasn't rendered yet
                                        scroller = function (
                                            scroll_target
                                        ) {
                                            Ext.getBody().scrollTo(
                                                'top',
                                                scroll_target.el.getY(),
                                                false
                                            );
                                        };

                                        if (edit_view.isVisible()) {
                                            scroller(edit_view);
                                        }
                                        else {
                                            edit_view.addListener(
                                                'show',
                                                scroller,
                                                {single: true}
                                            );
                                        }

                                        //close the dialog
                                        data_view.permision_check_view.hide();
                                    }
                                    else if (e.getTarget('.pub-cancel')) {
                                        data_view.permision_check_view.hide();
                                    }
                                }
                            };


                            data_view.permision_check_view =
                                new AIR2.UI.DataView({
                                    renderTo:     data_view.el.child(
                                        '.publishStatusItem'
                                    ),
                                    renderEmpty:  true,
                                    data:          {},
                                    tpl:          publishTpl,
                                    cls:          'anns-ct',
                                    itemSelector: '.pub-row',
                                    baseParams:   {sort: 'srs_cre_dtim asc'},

                                    // create/edit/delete click handlers
                                    listeners: data_view.permission_listeners
                                });
                            data_view.permision_check_view.show();
                        }
                        else {
                            data_view.permision_check_view.show();
                        }
                    }
                    setupListeners(data_view);
                }
                else {
                    setupListeners(data_view);
                    return;
                }


                //if request fails back out local mod to publish state
                failCallback = function () {
                    data_view.tpl.isSpinning = false;
                    setupListeners(data_view);
                    record.set('publish_flags', publish_state);
                    record.commit();
                };

                // changes can require a panel update to the display of
                // some responses
                saveCallback = function () {
                    var responsePanel = Ext.getCmp('air2-submission-responses');
                    data_view.tpl.isSpinning = false;
                    responsePanel.store.reload({
                        callback: function () {
                            setupListeners(data_view);
                        }

                    });

                };

                data_view.store.addListener({
                    'exception': {
                        fn: failCallback,
                        single: true
                    },
                    'save': {
                        fn: saveCallback,
                        single: true
                    }
                });
                data_view.tpl.isSpinning = false;
                data_view.store.save();

                return;
            }
        };

        data_view.el.on('click', clickHandler);
    };

    publish_meta_view.on(
        'afterrender',
        function (data_view) {
            setupListeners(data_view);
        }
    );

};

//Publish State constants
AIR2.Submission.publishHandler.PUBLISHED_STATE   = 'published';
AIR2.Submission.publishHandler.PUBLISH_STATE     = 'publish';
AIR2.Submission.publishHandler.UNPUBLISHED_STATE = 'unpublished';
AIR2.Submission.publishHandler.UNPUBLISH_STATE   = 'unpublish';

