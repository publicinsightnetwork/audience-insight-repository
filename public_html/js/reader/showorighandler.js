/***************
 * Source response edit handler for the reader
 */
AIR2.Reader.showOrigHandler = function (dv) {

    // orig val template
    var originalTpl = new Ext.XTemplate(
        '<tpl for=".">' +
          '<div id="{id}" class="anns clearfix anns-row">' +
            '<div class="submission original-submission">' +
              '<span>{sr_orig_value}</span>' +
            '</div>' +
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
            if (e.getTarget('a.orig')) {
                var span, 
                    responseMetaEl, 
                    xpandr, 
                    sr_uuid, 
                    srs_uuid, 
                    searchRec,
                    respRec,
                    origVal,
                    origValId,
                    origValEl,
                    renderTarget;

                e.preventDefault();
                xpandr = e.getTarget('a.orig', 5, true);
                span = xpandr.first();
                sr_uuid = xpandr.getAttribute('data-sr_uuid');
                srs_uuid = xpandr.getAttribute('data-srs_uuid');
                renderTarget = Ext.get('response-entry-'+sr_uuid);
                origValId = 'response-orig-val-'+sr_uuid;
                origValEl = Ext.get(origValId);
                // check for already-expanded
                if (origValEl) {
                    origValEl.setVisibilityMode(Ext.Element.DISPLAY);
                    if (origValEl.isVisible()) {
                        origValEl.hide();
                        span.dom.innerHTML = 'Show Original';
                    }
                    else {
                        origValEl.show();
                        span.dom.innerHTML = 'Hide Original';
                    }
                }
                else {
                    responseMetaEl = Ext.get('response-meta-'+sr_uuid);

                    // hide annotations
                    annotations = Ext.select('.sran-expand', false, responseMetaEl.dom).elements;
                    Ext.each(annotations, function (annotation, index) {
                        annotation = Ext.get(annotation);
                        if (annotation.dv) {
                            annotation.dv.hide();
                        }
                    });
                                        
                    // display original value from search store
                    searchRec = AIR2.Reader.DV.store.getById(srs_uuid);
                    if (!searchRec) {
                        Logger("failed to find srs_uuid ", srs_uuid, AIR2.Reader.DV.store);
                        return;
                    }
                    Ext.each(searchRec.get('friendly'), function (qa, i) {
                        if (qa.sr_uuid == sr_uuid) {
                            respRec = qa;
                            return false; // end loop
                        }   
                    });
                    //Logger('respRec=', respRec);
                    origVal = AIR2.Util.Response.formatResponse(respRec, true);
                    //Logger('origVal=', origVal);
                    originalTpl.append(renderTarget, {id:origValId, sr_orig_value:origVal});
                    span.dom.innerHTML = 'Hide Original';
                }
            }
        });

    });

};
