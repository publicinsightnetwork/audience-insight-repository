Ext.ns('AIR2.UI');
/***************
 * AIR2 RemoteText Component
 *
 * An Ext.form.TextField with automatic remote (ajax) validation
 *
 * @class AIR2.UI.RemoteText
 * @extends Ext.form.TextField
 * @xtype air2remotetext
 * @cfg {String} remoteTable
 *   The remote table to validate against.  Examples are "source" or "project".
 * @cfg {Boolean} hideWait
 *   True to hide the remote-wait spinner icon
 *
 */
AIR2.UI.RemoteText = function (cfg) {
    if (!cfg.remoteTable) {
        Logger("ERROR: no remote table defined!!");
        return;
    }
    AIR2.UI.RemoteText.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.RemoteText, Ext.form.TextField, {
    remoteTable: null,
    params: {},
    method: 'POST',
    timeout: 30 * 1000, /* ms */
    defaultErrorText: 'ERROR: validation error',
    ajaxErrorText: 'ERROR: connection error',
    uniqueErrorText: 'Name already in use',
    caseSensitive: false,
    onRender: function (ct, position) {
        AIR2.UI.RemoteText.superclass.onRender.call(this, ct, position);
        this.remoteAction = ct.createChild({cls: 'air2-form-remote-wait'});
    },
    showError: function (title, msg) {
        AIR2.UI.ErrorMsg(this.el, title, msg);
    },
    doRemoteValidation: function (value) {
        // abort any previous requests
        if (this.ajaxId) {
            Ext.Ajax.abort(this.ajaxId);
            this.ajaxId = false;
        }

        // don't try to remote-validate a blank value
        if (value === '') {
            this.remoteIsValid = true;
            this.remoteMsg = '';
            this.preventMark = false; // now allow marking
            this.validate(); // refire the validation
            return;
        }

        // align the 'remote processing' element
        if (!this.hideWait) {
            this.remoteAction.alignTo(this.el, 'tr-tl', [0, 2]);
            this.remoteAction.show();
        }

        // get params, including any defaults
        var params = Ext.apply({}, this.params);
        params[this.getName()] = value;

        // fire the remote request
        this.ajaxId = Ext.Ajax.request({
            method: this.method,
            url: AIR2.HOMEURL + '/validator/' + this.remoteTable + '.json',
            params: params,
            timeout: this.timeout,
            scope: this,
            callback: function (opts, success, resp) {
                this.ajaxId = false;
                if (this.remoteAction) {
                    this.remoteAction.hide();
                }
                if (success) {
                    var data = Ext.util.JSON.decode(resp.responseText);
                    if (data.success) {
                        this.remoteIsValid = true;
                        this.remoteMsg = '';
                    }
                    else {
                        this.remoteIsValid = false;
                        this.remoteMsg = this.getErrorMsg(data);
                    }
                }
                else {
                    this.remoteIsValid = false;
                    this.remoteMsg = this.ajaxErrorText;
                }
                this.preventMark = false; // now allow marking
                this.validate(); // refire the validation
            }
        });
    },
    validator: function (value) {
        var original = this.originalValue;
        if (!this.caseSensitive) {
            if (value) {
                value = value.toLowerCase();
            }
            if (original) {
                original = original.toLowerCase();
            }
        }

        if (!Ext.isDefined(original) && value.length > 0) {
            this.originalValue = value;
            original = value;
        }

        if (value === original) {
            return true;
        }

        // fire remote validation if value has changed
        if (value !== this.lastValue) {
            this.preventMark = true; //don't mark until callback
            this.lastValue = value;
            this.remoteIsValid = false;
            this.doRemoteValidation(value);
        }

        return (this.remoteIsValid) ? true : this.remoteMsg;
    },
    reset: function () {
        delete this.originalValue; // allow changing originalValue on reset
        AIR2.UI.RemoteText.superclass.reset.call(this);
    },
    getErrorMsg: function (ajaxData) {
        var msg = this.defaultErrorText;

        // look for the most specific msg available
        if (ajaxData.message) {
            msg = ajaxData.message;
        }
        if (ajaxData.errors && ajaxData.errors[this.getName()]) {
            msg = ajaxData.errors[this.getName()];
        }
        if (msg === 'unique') {
            if (Ext.isFunction(this.uniqueErrorText)) {
                msg = this.uniqueErrorText(ajaxData);
            }
            else {
                msg = this.uniqueErrorText;
            }
        }
        return msg;
    }
});
Ext.reg('air2remotetext', AIR2.UI.RemoteText);
