Ext.ns('AIR2.Util.AjaxLogin');
/***************
 * AIR2 AjaxLogin utility
 *
 * Function and associated variables to show/submit an ajax login window when
 * their authtkt cookie has expired.
 */

/* maximum login attempts before kicking user to login page */
AIR2.Util.MAXAJAXLOGINATTEMPTS = 3;

/* global ajax listener to check for authtkt cookie */
Ext.Ajax.on('beforerequest', function (conn, opt) {
    var tkt = Ext.util.Cookies.get(AIR2.AUTHZCOOKIE);
    if (!tkt && !opt.skipB4Hook) {
        AIR2.Util.AjaxLogin(opt);
        return false;
    }
    return true;
});

/**
 * Run an ajax-login.  If a login is already in progress, the callback
 * ajax request will be added to the stack.  All callbacks are processed
 * on a successful login.
 */
AIR2.Util.AjaxLogin = function (queueRequestOpts) {
    var attempts, submitFn;

    // queue the request options
    if (!AIR2.Util.AjaxLogin.queue) {
        AIR2.Util.AjaxLogin.queue = [];
    }

    AIR2.Util.AjaxLogin.queue.push(queueRequestOpts);

    // number of attempted logins
    attempts = 0;

    // submit function
    submitFn = function () {
        var ajaxId, f;

        f = AIR2.Util.AjaxLogin.win.get(0);
        if (f.getForm().isValid()) {
            f.el.mask('Submitting');
            attempts++;

            // ajax-submit the login from
            ajaxId = Ext.Ajax.request({
                skipB4Hook: true, //important!
                method: 'POST',
                url: AIR2.HOMEURL + '/login.json',
                params: f.getForm().getValues(),
                timeout: 10000,
                scope: this,
                callback: function (opts, success, resp) {
                    var data, i, tkt;

                    data = Ext.util.JSON.decode(resp.responseText);

                    if (success && data.success) {
                        // set the authtkt cookie, and run queued requests
                        tkt = data[AIR2.AUTHZCOOKIE];
                        Ext.util.Cookies.set(AIR2.AUTHZCOOKIE, tkt);
                        AIR2.Util.AjaxLogin.win.close();
                        AIR2.Util.AjaxLogin.win = null;

                        // run all queued ajax requests
                        for (i = 0; i < AIR2.Util.AjaxLogin.queue.length; i++) {
                            Ext.Ajax.request(AIR2.Util.AjaxLogin.queue[i]);
                        }
                        AIR2.Util.AjaxLogin.queue = [];
                    }
                    else {
                        if (attempts < AIR2.Util.MAXAJAXLOGINATTEMPTS) {
                            f.get(2).reset();
                            f.el.unmask();
                            f.get(0).update(
                                '<h1 style="color:red">' +
                                    'Invalid username/password.' +
                                '</h1>'
                            );
                        }
                        else {

                            //redirect to login page
                            location.href = AIR2.LOGOUTURL;
                        }
                    }
                }
            });
        }
    };

    // create the window, if it's not already showing
    if (!AIR2.Util.AjaxLogin.win) {
        AIR2.Util.AjaxLogin.win = new AIR2.UI.Window({
            autoShow: true,
            title: 'Session Expired',
            iconCls: 'air2-icon-alert',
            id: 'air2-ajax-login',
            closable: false,
            width: 250,
            height: 150,
            items: {
                xtype: 'form',
                labelWidth: 70,
                unstyled: true,
                padding: '3px 12px',
                monitorValid: true,
                keys: {
                    key: Ext.EventObject.ENTER,
                    fn: submitFn
                },
                defaults: {
                    xtype: 'textfield',
                    width: 140,
                    allowBlank: false
                },
                items: [{
                    xtype: 'box',
                    html: '<h1>Re-enter your credentials:</h1>',
                    width: '100%',
                    style: 'margin-bottom: 8px'
                }, {
                    fieldLabel: 'Username',
                    value: AIR2.USERNAME,
                    name: 'username'
                }, {
                    fieldLabel: 'Password',
                    inputType: 'password',
                    name: 'password'
                }],
                fbar: [{
                    xtype: 'air2button',
                    text: 'Submit',
                    air2type: 'SAVE',
                    air2size: 'MEDIUM',
                    formBind: true,
                    handler: submitFn
                }]
            }
        });
        attempts = 0;
        AIR2.Util.AjaxLogin.win.show(true, function () {
            AIR2.Util.AjaxLogin.win.get(0).get(2).focus(true, 50);
            this.mask.addClass('air2-ajax-login-mask');
        });
    }
};
