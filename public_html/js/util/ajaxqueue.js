Ext.ns('AIR2.Util.AjaxQueue');

AIR2.Util.AjaxQueue = function (config) {
    if (!config.requests) {
        throw "Missing 'requests' config in AjaxQueue.";
    }

    var spin = config.requests.length;

    // Note: All callbacks are handled with one thread,
    // so it's safe to spin down this way.
    Ext.each(config.requests, function (request) {
        Ext.Ajax.request({
            url: request.uri,
            success: function (response, options) {
                response = Ext.decode(response.responseText);

                // Per-request handler.
                request.success(response);

                spin--;

                if (spin === 0) {
                    config.success();
                }
            }
        });
    });
};
