/***************
 * Response include/exclude handler
 */

AIR2.Reader.exclSetIncluded = function(btn) {
    var icon = btn.child('i');
    btn.replaceClass('excluded','included');
    icon.replaceClass('icon-ban-circle','icon-ok');
    icon.set({'ext:qtip':"Click to Include"});
}

AIR2.Reader.exclSetExcluded = function(btn) {
    var icon = btn.child('i');
    btn.replaceClass('included','excluded');
    icon.replaceClass('icon-ok', 'icon-ban-circle');
    icon.set({'ext:qtip':"Click to Exclude"});
}

AIR2.Reader.exclMouseOut = function(event, htmlEl, obj) {
    var el = Ext.get(htmlEl);
    var btn = el.parent('a.override');
        
    if (typeof btn.isIncluded === 'undefined') {
        Logger('include flag set on class');
        btn.isIncluded = btn.hasClass('included');
    }
    //Logger('out', el, btn, span);

    btn.removeClass('tentative');
    if (!btn.isIncluded) {
        AIR2.Reader.exclSetExcluded(btn);
    }
    else {
        AIR2.Reader.exclSetIncluded(btn);
    }
};

AIR2.Reader.exclMouseOver = function(event, htmlEl, obj) {
    var el = Ext.get(htmlEl);
    var btn = el.parent('a.override');
    var span = btn.child('span');
    if (typeof btn.isIncluded === 'undefined') {
        Logger('include flag set on class');
        btn.isIncluded = btn.hasClass('included');
    }
    //Logger('over', el, btn, span);
    
    // skip fresh changes since the updater did it for us
    if (btn.fresh) {
        //Logger('over fresh');
        btn.fresh = false;
        return;
    }
    
    btn.addClass('tentative');
    if (btn.isIncluded) {
        AIR2.Reader.exclSetExcluded(btn);
    }
    else {
        AIR2.Reader.exclSetIncluded(btn);
    }
};

AIR2.Reader.updateIncludeExcludeDisplay = function (isIncluded, xpandr) {
    //Logger('updateIncExl isIncluded:', isIncluded);
    
    if (!isIncluded) {
        AIR2.Reader.exclSetExcluded(xpandr);
        xpandr.isIncluded = false;
        xpandr.fresh = true;
        //Logger('isIncluded now false');
    }
    else {
        AIR2.Reader.exclSetIncluded(xpandr);
        xpandr.isIncluded = true;
        xpandr.fresh = true;
        //Logger('isIncluded now true');
    }
    xpandr.removeClass('tentative');
};
    
AIR2.Reader.exclHandler = function (dv) {

    // attach listeners
    dv.on('afterrender', function (dv) {

        // since the expanded row doesn't get included in the dataview 'click'
        // event, we need to listen to the actual DOM click
        dv.el.on('click', function (e) {
            var current_flag,
                new_flag,
                qa_idx,
                qa_set,
                search_rec,
                sr_uuid,
                sr_response,
                srs_uuid,
                url,
                xpandr;

            if (e.getTarget('a.override')) {
                e.preventDefault();

                xpandr = Ext.Element.get(e.getTarget('a.override'));
                srs_uuid = xpandr.getAttribute('data-submission_uuid');
                sr_uuid  = xpandr.getAttribute('data-resp_id');
                search_rec = AIR2.Reader.DV.store.getById(srs_uuid);
                qa_set = search_rec.get('qa');
                qa_idx = 0;
                sr_response = null;
                Ext.each(qa_set, function (qa, i) {
                    if (qa.sr_uuid == sr_uuid) {
                        sr_response = qa;
                        qa_idx = i;
                        return false; // end loop
                    }
                });
                current_flag = sr_response.public_flag;

                if (current_flag == 0) {
                    current_flag = false;
                } else if (current_flag == 1) {
                    current_flag = true;
                }

                new_flag = !current_flag;

                // toggle display now
                AIR2.Reader.updateIncludeExcludeDisplay(new_flag, xpandr);

                // roll back display on server failure
                url = AIR2.HOMEURL + '/submission/' + srs_uuid + '/response/';
                url += sr_uuid + '.json';
                Ext.Ajax.request({
                    url: url,
                    method: 'PUT',
                    params: {
                        radix: Ext.util.JSON.encode({
                            sr_public_flag: new_flag
                        })
                    },
                    success: function (resp, ajax, opts) {
                        var publishingListItem,
                            r;

                        r = Ext.util.JSON.decode(resp.responseText);

                        // update local store
                        qa_set[qa_idx].public_flag = new_flag;
                        search_rec.set('qa', qa_set);

                        // update parent src_response_set publish-state
                        publishingListItem = Ext.get(
                            'srs-publish-state-' + srs_uuid
                        );

                        AIR2.Reader.updatePublicStatus(
                            AIR2.HOMEURL + '/submission/' + srs_uuid + '.json',
                            publishingListItem
                        );

                    },

                    // rollback on failure
                    failure: function (resp, ajax, opts) {
                        Logger(resp);
                        Logger('failed to PUT change to sr_public_flag');
                        AIR2.Reader.updateIncludeExcludeDisplay(
                            current_flag,
                            xpandr
                        );
                    }
                });

            }
        });

    });

};
