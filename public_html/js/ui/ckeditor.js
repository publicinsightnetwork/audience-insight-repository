Ext.ns('AIR2.UI');
/***************
 * AIR2 CKEditor Component
 *
 * AIR2 Plugin.
 *
 *
 */

AIR2.UI.CKEditor = function (config) {
    this.config = config;
    AIR2.UI.CKEditor.superclass.constructor.call(this, config);
};

Ext.extend(AIR2.UI.CKEditor, Ext.form.TextArea,  {
    onRender : function (ct, position) {
        if (!this.el) {
            this.defaultAutoCreate = {
                tag: "textarea",
                autocomplete: "off"
            };
        }
        Ext.form.TextArea.superclass.onRender.call(this, ct, position);
        CKEDITOR.replace(this.id, this.config.CKConfig);
    },

    setValue : function (value) {
        Ext.form.TextArea.superclass.setValue.apply(this, [value]);
    },

    getValue : function () {
        Logger('get');
        var editor, value;
        editor = CKEDITOR.instances[this.id];
        if (editor) {
            editor.updateElement();
            value = editor.getData();
            Ext.form.TextArea.superclass.setValue.apply(this, [value]);
            return value;
        }
        return Ext.form.TextArea.superclass.getValue(this);
    },

    getRawValue : function () {
        var editor = CKEDITOR.instances[this.id];
        if (editor) {
            editor.updateElement();
            return editor.getData();
        }
        return Ext.form.TextArea.superclass.getRawValue(this);
    },
    onDestroy: function () {
        if (CKEDITOR.instances[this.id]) {
            delete CKEDITOR.instances[this.id];
        }
    }

});
Ext.reg('air2ckeditor', AIR2.UI.CKEditor);
