/***********************
 * Preview Modal
 */
AIR2.Inquiry.inquiryPreviewModal = function (display, key) {
    var inquiry, value, window;

    inquiry = AIR2.Inquiry.inqStore.getAt(0);

    value = inquiry.get(key);

    // modal window
    window = new AIR2.UI.Window({
        title: display,
        width: 800,
        formAutoHeight: true,
        items: [{
            xtype: 'container',
            unstyled: true,
            style: 'padding: 10px 10px 0',
            labelWidth: 120,
            html: value
        }],
        fbar: [{
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'LARGE',
            text: 'Close',
            handler: function () {
                window.close();
            }
        }]
    });
    window.show();
};
