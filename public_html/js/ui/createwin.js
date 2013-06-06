Ext.ns('AIR2.UI.CreateWin');
/***************
 * Resource creation modal window
 *
 * Opens a modal window allowing the creation of some resource.  A specific
 * instance must provide form items.
 *
 * @class AIR2.UI.CreateWin
 * @extends AIR2.UI.Window
 * @xtype air2createwin
 * @cfg {Array}    formItems
 *                     Array of fields to create form
 * @cfg {String}   postUrl
 *                     POST url to create the resource
 * @cfg {Function} postParams
 *                     Function to extract POST params from form
 * @cfg {Function} postCallback
 *                     Function to call after POST(success, data, rawresp)
 * @cfg {Integer}  labelWidth (default: 80)
 *                     Width of the form labels
 * @cfg {Boolean}  modal
 *                     false to create a non-modal window
 */
AIR2.UI.CreateWin = function (cfg) {
    var getPostParams,
        postCallback,
        postUrl;

    if (!cfg || !cfg.formItems || !cfg.formItems.length) {
        alert('formItems required');
    }

    // form submit vars
    postCallback = cfg.postCallback;
    postUrl = cfg.postUrl;
    getPostParams = cfg.postParams ? cfg.postParams : function (f) {
        return f.getFieldValues();
    };

    // action buttons
    this.savebtn = new AIR2.UI.Button({
        air2type: 'SAVE',
        air2size: 'MEDIUM',
        text: 'Save',
        scope: this,
        handler: function () {
            var f = this.get(0).getForm(), el = this.get(0).el;

            // validate and fire the ajax save
            if (f.isValid()) {
                el.mask('Saving');
                Ext.Ajax.request({
                    url: postUrl,
                    params: {radix: Ext.encode(getPostParams(f))},
                    callback: function (opt, success, rsp) {
                        var data, msg;

                        data = false;
                        try {
                            data = Ext.decode(rsp.responseText);
                        }
                        catch (err) {
                            data = {
                                success: false,
                                message: 'Json-decode error!'
                            };
                        }
                        success = data ? data.success : false;
                        if (!success) {
                            el.unmask();
                            if (data && data.message) {
                                msg = data.message;
                            }
                            else {
                                msg = 'Unknown Error';
                            }
                            AIR2.UI.ErrorMsg(f, "Error", msg);
                        }

                        if (Ext.isFunction(postCallback)) {
                            postCallback(success, data, rsp);
                        }
                        else {
                            el.unmask();
                        }
                    }
                });
            }
        }
    });
    this.cancelbtn = new AIR2.UI.Button({
        air2type: 'CANCEL',
        air2size: 'MEDIUM',
        text: 'Cancel',
        scope: this,
        handler: function () {this.close(); }
    });

    // setup the form
    cfg.items = {
        xtype: 'form',
        unstyled: true,
        style: cfg.formStyle ? cfg.formStyle : 'padding: 10px 10px 0',
        labelWidth: cfg.labelWidth ? cfg.labelWidth : 80,
        defaults: {
            xtype: 'textfield',
            allowBlank: false,
            width: 200,
            msgTarget: 'under'
        },
        items: cfg.formItems,
        bbar: [this.savebtn, ' ', this.cancelbtn]
    };

    // do autoheight, unless a height was provided
    if (!cfg.height) {
        cfg.formAutoHeight = true;
    }

    // call parent constructor
    AIR2.UI.CreateWin.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.CreateWin, AIR2.UI.Window, {
    title: 'Create',
    iconCls: 'air2-icon-add',
    closeAction: 'close',
    width: 320,
    padding: '6px 0'
});
Ext.reg('air2createwin', AIR2.UI.CreateWin);
