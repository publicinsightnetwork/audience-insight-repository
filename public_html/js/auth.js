/* AIR2 authn and authz support */
/* see also AIR2.Util.AjaxLogin which automatically detects expired sessions */

Ext.ns('AIR2.Auth');

AIR2.Auth.confirmPassword = function (pswd, el, callback) {
    if (!pswd) {
        throw new Ext.Error("pswd required");
    }
    if (!callback) {
        throw new Ext.Error("callback required");
    }

    var url = AIR2.HOMEURL + '/login.json',
    params = {
        password: pswd,
        username: AIR2.USERNAME
    },
    busyMask = new Ext.LoadMask(Ext.getBody(), { msg: 'Authenticating...' });

    busyMask.show();

    Ext.Ajax.request({
        url: url,
        method: 'POST',
        success: function (resp) {
            //Logger(resp);
            busyMask.hide();
            callback();
        },
        failure: function (resp) {
            //Logger(resp);
            busyMask.hide();
            AIR2.UI.ErrorMsg(el, "Incorrect password.", "Please try again.");
        },
        params: params
    });

};

AIR2.Auth.requirePassword = function (callback) {
    if (!callback) {
        throw new Ext.Error("callback required");
    }
    var loginWindow, loginForm;
    loginForm = new Ext.form.FormPanel({
        style: 'padding: 8px',
        border: false,
        frame: false,
        width: 360,
        labelWidth: 65,
        labelAlign: 'right',
        defaults: {
            width: 250,
            border: false
        },
        items: [
            {
                html: 'You are about to export confidential information.' +
                 'Enter your password to continue.',
                style: 'padding:6px'
            },
            new Ext.form.TextField({
                id: "password",
                fieldLabel: "Password",
                inputType: 'password',
                allowBlank: false,
                blankText: "Enter your password",
                listeners: {
                    'specialkey' : function (thisField, e) {
                        if (e.getKey() === e.ENTER) {
                            var btn = Ext.getCmp('auth-ok-button');
                            btn.handler();
                        }
                    }
                }
            })
        ],
        buttons: [
            {
                xtype: 'air2button',
                air2type: 'BLUE',
                air2size: 'MEDIUM',
                text: 'Submit',
                id: 'auth-ok-button',
                handler: function () {
                    if (loginForm.getForm().isValid()) {
                        var pswd = Ext.get('password').getValue();
                        //Logger(pswd);
                        AIR2.Auth.confirmPassword(pswd, loginForm.getForm(),
                         function () {
                            loginWindow.close();
                            callback();
                        });
                    }
                }
            },
            {
                xtype: 'air2button',
                air2type: 'CANCEL',
                air2size: 'MEDIUM',
                text: 'Cancel',
                handler: function () { loginWindow.close(); }
            }
        ]
    });
    loginWindow = new AIR2.UI.Window({
        title: 'Enter password',
        height: 160,
        formAutoHeight: true,
        width: 360,
        modal: true,
        items: [loginForm]
    });

    loginWindow.show();

};

AIR2.Auth.sendUserPassword = function (username) {
    var url, busyMask, params;

    url = AIR2.HOMEURL + '/rpc/send_password_email.json';

    busyMask = new Ext.LoadMask(Ext.getBody(), { msg: 'Sending email...' });
    busyMask.show();

    params = {
        email: username
    };

    Ext.Ajax.request({
        url: url,
        method: 'POST',
        success: function (resp) {
            //Logger(resp);
            //alert("Mail sent to " + username);
            busyMask.hide();
        },
        failure: function (resp) {
            //Logger(resp);
            AIR2.UI.ErrorMsg(Ext.getBody(), "Error sending mail.",
             "Contact your administrator.");
            busyMask.hide();
        },
        params: { email: username }
    });
};
