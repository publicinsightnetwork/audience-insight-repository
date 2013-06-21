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
    var previewPanel;


    previewPanel = new AIR2.UI.Panel({
        autoHeight: true,
        autoScroll: true,
        border:     false,
        html:  '<div id="pin-query-preview" class="pin-query"></div>',
        title:      'Preview',
        unstyled:   true
    });

    previewPanel.on('activate', function (panel) {
        var failPreview, getUnpublishedPreview, json_url, panelEl, previewEl;

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
        };

        getUnpublishedPreview = function () {
            var full_url;

            full_url = AIR2.Inquiry.URL + '/preview.json';
            Ext.Ajax.request({
                url: full_url,
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
        };

        if (AIR2.Inquiry.inqStore.getAt(0).get('inq_stale_flag')) {
        // we don't have a published version of the latest changes
            getUnpublishedPreview();
        }
        else {
            json_url = AIR2.HOMEURL + '/q/' + AIR2.Inquiry.UUID + '.json';
            Ext.Ajax.request({
                url: json_url,
                failure: function (response, options) {
                    getUnpublishedPreview();
                },
                success: function (response, options) {
                    var queryJson;
                    if (response.status === 200 && response.responseText) {
                        queryJson = Ext.decode(response.responseText);
                        // call out to real live published query rendering js
                        PIN.Form.build(queryJson, PIN_QUERY);
                    }
                    else {
                        getUnpublishedPreview();
                    }
                },
                method: 'GET'
            });

        }
    });

    return previewPanel;
};
