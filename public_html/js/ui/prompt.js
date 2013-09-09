/* AIR2 UI Prompt singleton */
Ext.ns('AIR2.UI.Prompt');
AIR2.UI.Prompt = function (parentEl, title, msg, fn, withField) {
    var box,
        href,
        tpl,
        w;

    box = Ext.Msg.show({
        animEl: parentEl,
        buttons: withField ? Ext.Msg.OKCANCEL : Ext.Msg.YESNO,
        cls: 'air2-corners air2-prompt',
        closable: false,
        icon: withField ? Ext.Msg.INFO : Ext.Msg.QUESTION,
        title: title,
        msg: msg,
        fn: fn,
        minWidth: 300,
        prompt: withField ? true : false,
        value: withField
    });

    return box;
};
