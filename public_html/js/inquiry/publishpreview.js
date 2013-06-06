/***************
 * Preview query
 *
 *
 * @function AIR2.Inquery.Preview
 *
 * This view taps into unused functionality that will render the published
 * query and preview it inline
 */
AIR2.Inquiry.PublishPreview = function () {
    var fullurl, previewPanel;

    fullurl = AIR2.Inquiry.URL + '/preview.json';

    previewPanel = new AIR2.UI.Panel({
        autoHeight: true,
        autoScroll: true,
        border:     false,
        html:  '<div id="pin-query-preview" class="pin-query"></div>',
        title:      'Preview',
        unstyled:   true
    });

                AIR2.Inquiry.inqStore.getAt(0).get('inq_stale_flag')

    previewPanel.on('activate', function (panel) {
        var panelEl, previewEl;

        panelEl = panel.getEl();

        //chase down the initial panel element and reset it
        previewEl = panel.getBody().get(0).update(
            '<div id="pin-query-preview" class="pin-query"></div>'
        );

        jQuery('#pin-query-preview').on(
            'pinform_built',
            function (jqevent, divId) {
                var resizeAndReveal;

                AIR2.APP.doLayout();
                panelEl.unmask();

                // try again after a 1/2 second in case the browser
                // was slow to render the form
                resizeAndReveal = new Ext.util.DelayedTask(function(){
                    AIR2.APP.doLayout();
                });

                resizeAndReveal.delay(500);

            }
        );

        panelEl.mask('Loading preview...');

        failPreview = function (msg) {
            msg = msg || 'Failed to load preview.';
            panelEl.update('<h2>' + msg + '</h2>');
            panelEl.unmask();
        }

        if (AIR2.Inquiry.inqStore.getAt(0).get('inq_stale_flag')) {
        // we don't have a published version of the latest changes

            Ext.Ajax.request({
                url: fullurl,
                failure: function (response, options) {
                    failPreview();
                },
                success: function (response, options) {
                    var queryJson, responseJson;
                    if (response.status === 200 && response.responseText) {
                        responseJson = Ext.decode(response.responseText);
                        if (responseJson.radix && responseJson.radix.preview_json) {
                            queryJson = Ext.decode(responseJson.radix.preview_json);

                            // call out to real live published query rendering js
                            PIN.Form.build(queryJson, PIN_QUERY);
                        }
                    }
                    else {
                        failPreview();
                    }
                },
                method: 'GET'
            });

        }
        else {
            fullurl = AIR2.HOMEURL + '/q/' + AIR2.Inquiry.UUID + '.json';
            Ext.Ajax.request({
                url: fullurl,
                failure: function (response, options) {
                    failPreview();
                },
                success: function (response, options) {
                    Logger(response, options);
                    var queryJson;
                    if (response.status === 200 && response.responseText) {
                        queryJson = Ext.decode(response.responseText);
                        // call out to real live published query rendering js
                        PIN.Form.build(queryJson, PIN_QUERY);
                    }
                    else {
                        failPreview();
                    }
                },
                method: 'GET'
            });

        }
    });

    return previewPanel;
};
