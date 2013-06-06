Ext.ns('AIR2.UI');
/***************
 * AIR2 Button Component
 *
 * Button specifically designed to look really neat in AIR2
 *
 * @class AIR2.UI.Button
 * @extends Ext.Button
 * @xtype air2button
 * @cfg {String} air2type
 *   'SMALL' (default), 'MEDIUM', or 'LARGE' --- see this.size
 * @cfg {String} air2size
 *   'PLAIN' (default), 'CLEAR', 'SAVE', etc --- see this.types
 *
 */
AIR2.UI.Button = function (cfg) {
    if (cfg.air2type && !this.types[cfg.air2type]) {
        cfg.air2type = this.air2type;
    }
    if (cfg.air2size && !this.sizes[cfg.air2size]) {
        cfg.air2size = this.air2size;
    }

    AIR2.UI.Button.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.Button, Ext.Button, {
    air2type: 'PLAIN',
    air2size: 'SMALL',
    types: {
        PLAIN: 'air2-btn-plain',
        CLEAR: 'air2-btn-clear',
        SAVE: 'air2-btn-save',
        CANCEL: 'air2-btn-cancel',
        DELETE: 'air2-btn-delete',
        BLUE: 'air2-btn-blue',
        NEW: 'air2-btn-new',
        NEW2: 'air2-btn-new2',
        DARK: 'air2-btn-dark',
        DARKER: 'air2-btn-darker',
        DRAWER: 'air2-btn-drawer',
        UPLOAD: 'air2-btn-upload',
        ROUND: 'air2-btn-round',
        FRIENDLY: 'air2-btn-friendly'
    },
    sizes: {
        SMALL: 'air2-btn-small',
        MEDIUM: 'air2-btn-medium',
        LARGE: 'air2-btn-large'
    },
    getTemplateArgs: function () {
        var size, type;

        type = this.types[this.air2type];
        size = this.sizes[this.air2size];
        return [this.id, type, size];
    },
    template: new Ext.Template(
        '<div id="{0}" class="air2-btn {1} {2}"><button></button></div>'
    ),
    buttonSelector: 'button',
    menuHint: false,
    initButtonEl: function (btn, btnEl) {
        AIR2.UI.Button.superclass.initButtonEl.call(this, btn, btnEl);
        if (this.menuHint) {
            btnEl.createChild({
                tag: 'span',
                cls: 'air2-btn-menu-hint'
            });
        }
    },
    // QuickTips.register seems to be broken, so just use DOM quicktips
    setTooltip: function (tooltip, initial) {
        if (this.rendered) {
            if (!initial) {
                this.clearTip();
            }
            var changeKeys = {
                text: 'qtip',
                cls: 'qclass'
            };

            // turn strings into object
            if (Ext.isString(tooltip)) {
                tooltip = {text: tooltip};
            }
            Ext.iterate(tooltip, function (key, val) {
                key = changeKeys[key] ? changeKeys[key] : 'q' + key;
                this.btnEl.dom[key] = val;
            }, this);
        }
        else {
            this.tooltip = tooltip;
        }
        return this;
    }
});
Ext.reg('air2button', AIR2.UI.Button);
