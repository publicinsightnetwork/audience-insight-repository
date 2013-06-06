/***************
 * Handle clicks on the Public column
 */

AIR2.Reader.publicHandler = function (dv) {

    // handle row clicks
    dv.on('click', function (dv, index, node, e) {
        var el,
            publish_state,
            rec,
            url;

        if (e.getTarget('.public-state')) {
            e.preventDefault();

            el  = e.getTarget('.public-state', 5, true);
            rec = dv.getRecord(node);

            if (!AIR2.Util.Authz.hasAnyId(
                'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                rec.data.qa[0].owner_orgs.split(',')
            )) {
                return;
            }

            publish_state = rec.data.publish_state;
            url = AIR2.HOMEURL + '/submission/' + rec.data.srs_uuid + '.json';

            // if current state is PUBLISHED or PUBLISHABLE,
            // toggle without expanding
            if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                // assume success, rollback on failure
                el.removeClass("air2-icon-check");
                el.addClass("air2-icon-uncheck");
                rec.data.srs_public_flag = 0;
                el.set({title: AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE});

                Ext.Ajax.request({
                    url: url,
                    method: 'PUT',
                    params: {radix: Ext.util.JSON.encode({srs_public_flag: 0})},

                    success: function (resp, ajax, opts) {
                        var r = Ext.util.JSON.decode(resp.responseText);

                        rec.data.publish_state = r.radix.publish_flags;

                        if (Ext.get('srs-publish-state-' + r.radix.srs_uuid)) {
                            AIR2.Reader.setPublishStateDisplay(
                                r.radix.publish_flags,
                                r.radix.srs_uuid
                            );
                        }
                    },

                    // rollback on failure
                    failure: function (resp, ajax, opts) {
                        Logger(resp);
                        Logger('failed to PUT change to srs_public_flag');
                        rec.data.srs_public_flag = 1;
                        el.addClass('air2-icon-check');
                        el.removeClass('air2-icon-uncheck');
                        el.set({title: AIR2.Reader.CONSTANTS.PUBLISHED_TITLE});
                    }
                });
            }
            else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                // assume success, rollback on failure
                el.removeClass("air2-icon-uncheck");
                el.addClass("air2-icon-check");
                rec.data.srs_public_flag = 1;

                el.set({title: AIR2.Reader.CONSTANTS.PUBLISHED_TITLE});
                Ext.Ajax.request({
                    url: url,
                    method: 'PUT',
                    params: {radix: Ext.util.JSON.encode({srs_public_flag: 1})},

                    success: function (resp, ajax, opts) {
                        var r = Ext.util.JSON.decode(resp.responseText);

                        rec.data.publish_state = r.radix.publish_flags;

                        if (Ext.get('srs-publish-state-' + r.radix.srs_uuid)) {
                            AIR2.Reader.setPublishStateDisplay(
                                r.radix.publish_flags,
                                r.radix.srs_uuid
                            );
                        }
                    },

                    // rollback on failure
                    failure: function () {
                        rec.data.srs_public_flag = 0;
                        el.addClass('air2-icon-uncheck');
                        el.removeClass('air2-icon-check');
                        el.set({
                            title: AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE
                        });
                    }
                });
            }
        }
    });


};
