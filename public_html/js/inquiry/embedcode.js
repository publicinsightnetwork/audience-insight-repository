/***********************
 * Inquiry Pinbutton Overlay
 */
AIR2.Inquiry.EmbedCode = function (el) {
    var embedFld,
        docFld,
        supportFld,
        docUrl,
        supportUrl,
        formUrl,
        code,
        w;

    formUrl = AIR2.Inquiry.uriForQuery(AIR2.Inquiry.BASE.radix);
    docUrl  = 'http://www.publicinsightnetwork.org/api-documentation/';
    supportUrl = 'http://support.publicinsightnetwork.org/entries/23666803';
    
    code =  [
        '<script type="text/javascript" src="https://www.publicinsightnetwork.org/source/js/jquery-1.8.1.min.js"></script>',
        '<script type="text/javascript" src="'+AIR2.HOMEURL+'/js/pinform.js?uuid='+AIR2.Inquiry.UUID+'"></script>',
        '<div id="pin-query-'+AIR2.Inquiry.UUID+'"></div>'
    ];

    // form items
    embedFld = new Ext.form.TextArea({
        fieldLabel: 'Embed Code',
        height: 200,
        width: 650,
        style: 'border-style:dashed;background-image:none;',
        readOnly: true,
        value: code.join("\n"),
        selectOnFocus: true
    });
    
    docFld = new Ext.form.DisplayField({
        fieldLabel: 'API Documentation',
        style: 'padding: 6px 0 0 0',
        value: '<a target="_blank" href="'+docUrl+'">'+docUrl+' <i class="icon-external-link"></i></a>',
        width: 440
    });
    
    supportFld = new Ext.form.DisplayField({
        fieldLabel: 'Support Article',
        style: 'padding: 6px 0 0 0',
        value: '<a target="_blank" href="'+supportUrl+'">'+supportUrl+' <i class="icon-external-link"></i></a>',
        width: 440
    });

    // modal window
    w = new AIR2.UI.Window({
        title: '&nbsp;Insight Embed Code',
        cls: 'air2-pin-embed-code',
        iconCls: 'air2-icon-embed-code',
        width: 800,
        formAutoHeight: true,
        items: [{
            xtype: 'form',
            unstyled: true,
            style: 'padding: 10px 10px 0',
            labelWidth: 120,
            items: [docFld, supportFld, embedFld]
        }],
        fbar: [{
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'LARGE',
            text: 'Close',
            style: 'margin-left:106px;',
            handler: function () {
                w.close();
            }
        }]
    });
    w.show(el);
};
