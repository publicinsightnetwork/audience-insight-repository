/***********************
 * Inquiry Pinbutton Overlay
 */
AIR2.Inquiry.Pinbutton = function (el) {
    var defaultOrgText,
        embedFld,
        formUrl,
        imgLarge,
        imgTpl,
        imgUrl,
        linkTpl,
        orgFld,
        prevFld,
        typeFld,
        urlFld,
        w;

    // TODO make querymaker-specific
    formUrl = AIR2.FORMURL + AIR2.Inquiry.UUID;
    
    defaultOrgText = '';

    if (AIR2.Inquiry.orgStore.getCount()) {
        defaultOrgText =
            AIR2.Inquiry.orgStore.getAt(0).data.Organization.org_display_name;
    }

    imgUrl = AIR2.INSIGHTBUTTON_URL + '/img/';
    imgLarge = imgUrl + 'insight-button-lg.png';

    // templates
    imgTpl = new Ext.Template(
        '<a href="{0}" class="pin-inform-button large" target="_blank">' +
            'Insight' +
        '</a>' +
        '<script type="text/javascript" ' +
            'src="' + AIR2.INSIGHTBUTTON_URL + '/js/inform.js">' +
        '</script>'
    );

    linkTpl = new Ext.Template(
        '<a href="{0}" class="pin-inform-button plain" target="_blank">' +
            'Help {1}cover this story' +
        '</a>' +
        '<script type="text/javascript" ' +
            'src="' + AIR2.INSIGHTBUTTON_URL + '/js/inform.js">' +
        '</script>'
    );


    // form items
    typeFld = new AIR2.UI.ComboBox({
        fieldLabel: 'Type',
        choices: [['I', 'Image Link'], ['L', 'Text Link']],
        value: 'I',
        lastval: 'I',
        width: 160,
        listeners: {
            select: function (cb, rec) {
                if (rec.id  !==  this.lastval) {
                    this.lastval = rec.id;
                    embedFld.updateCode();
                    orgFld.itemCt.toggleClass('x-hide-display');
                }
            }
        }
    });
    urlFld = new Ext.form.DisplayField({
        fieldLabel: 'Query URL',
        value: formUrl,
        width: 440
    });
    orgFld = new Ext.form.TextField({
        fieldLabel: 'Newsroom Name',
        value: defaultOrgText,
        width: 440,
        enableKeyEvents: true,
        itemCls: 'x-hide-display',
        listeners: {
            keyup: function () {
                embedFld.updateCode();
            }
        }
    });
    prevFld = new Ext.form.DisplayField({
        fieldLabel: 'Preview',
        itemCls: 'embed-preview',
        height: 40,
        width: 440
    });
    embedFld = new Ext.form.TextArea({
        fieldLabel: 'Embed Code',
        height: 140,
        width: 440,
        style: 'border-style:dashed;background-image:none;',
        readOnly: true,
        selectOnFocus: true,
        updateCode: function () {
            var c, o, t;

            t = typeFld.getValue();
            o = orgFld.getValue();

            if (o && o.length) {
                o = '<strong style="color:#444;">' + o + '</strong> ';
            }
            else {
                o = '';
            }

            if (t  === 'I') {
                c = imgTpl.apply([formUrl]);
            }
            else {
                c = linkTpl.apply([formUrl, o]);
            }

            if (this.rendered) {
                this.setValue(c);
            }
            else {
                this.value = c;
            }

            if (t  === 'I') {
                // cheat a little since the foreign .js won't execute,
                // so we insert img ourselves into the preview
                c = c.replace(/Insight/, '<img src="' + imgLarge + '"/>');
            }

            if (prevFld.rendered) {
                prevFld.setValue(c);
            }
            else {
                prevFld.value = c;
            }
        }
    });
    embedFld.updateCode();

    // modal window
    w = new AIR2.UI.Window({
        title: '&nbsp;Generate Insight Button Embed Code',
        cls: 'air2-pinbutton',
        iconCls: 'air2-icon-pinbutton',
        width: 580,
        formAutoHeight: true,
        items: [{
            xtype: 'form',
            unstyled: true,
            style: 'padding: 10px 10px 0',
            labelWidth: 100,
            items: [typeFld, urlFld, orgFld, prevFld, embedFld]
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
