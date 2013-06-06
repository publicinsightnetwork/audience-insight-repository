/* AIR2 UI ErrorMsg singleton */
Ext.ns('AIR2.UI.ErrorMsg');
AIR2.UI.ErrorMsg = function (parentEl, title, msg, fn) {
    var box,
        href,
        tpl,
        w;

    box = Ext.Msg.show({
        animEl: parentEl,
        buttons: Ext.Msg.OK,
        cls: 'air2-corners',
        closable: false,
        icon: Ext.Msg.ERROR,
        title: title,
        msg: msg,
        fn: fn,
        minWidth: 300
    });

    // add support link
    if (!AIR2.UI.ErrorMsg.HASLINK) {
        AIR2.UI.ErrorMsg.HASLINK = true;
        href = 'http://support.publicinsightnetwork.org';
        tpl = new Ext.Template(
            '<div style="text-align:center;margin-top:20px;">' +
                '<a class="external" href="' + href + '" target="_blank">' +
                    'Contact Help' +
                '</a>' +
            '</div>'
        );

        // check for rendered
        w = box.getDialog();
        if (w.rendered && w.body) {
            tpl.append(w.body);
        }
        else {
            w.on(
                'afterrender',
                function () {
                    tpl.append(w.body);
                },
                this,
                {single: true}
            );
        }
    }

    return box;
};
