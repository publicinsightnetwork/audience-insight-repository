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

        // make sure we have a separate instance for tidying
        this.initTidyEditor();
    },

    setValue : function (value) {
        Ext.form.TextArea.superclass.setValue.apply(this, [value]);
    },

    getValue : function () {
        Logger('get');
        var editor, value;
        editor = CKEDITOR.instances[this.id];
        if (editor) {
            // tell ckeditor to reconcile its data to its current ui
            editor.updateElement();

            // take a rough swipe at catching malformed html
            if (editor.mode == 'source') {
                this.tidy();
            }

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

    hide : function () {
        this.itemCt.setDisplayed('none');
        return Ext.form.TextArea.superclass.hide.call(this);
    },

    show : function () {
        this.itemCt.setDisplayed(true);
        return Ext.form.TextArea.superclass.show.call(this);
    },

    onDestroy: function () {
        if (CKEDITOR.instances[this.id]) {
            delete CKEDITOR.instances[this.id];
        }
    },

    /**
     * background: built in html filter in ckeditor can't be used when in source
     * mode
     *
     * this makes a separate editor in a hidden div used by all the other
     * ckeditor instances to scrub hand edited html.
    **/
    initTidyEditor : function (callback) {
        var config, divEl, divString;

        if (! CKEDITOR.instances.air2TidyEditor) {
            divString = '<div contentEditable="true" id="air2TidyEditor" ' +
                'style="display:none">' +
                '</div>';

            divEl = Ext.getBody().insertHtml('beforeEnd', divString);
            if (Ext.isFunction(callback)) {
                config = {
                    on: {
                        instanceReady: callback
                    }
                };
            }
            else {
                config = {};
            }

            this.tidyEditor = CKEDITOR.inline(divEl, config);
        }
        else {
            this.tidyEditor = CKEDITOR.instances.air2TidyEditor;
            if (Ext.isFunction(callback)) {
                callback();
            }
        }
    },

    /**
     * tidy
     *
     * force hand edited html through the wysiwyg wringer
    **/
    tidy: function () {
        var finalTidy, editorCmp, editor;

        editor = CKEDITOR.instances[this.id];

        editorCmp = this;

        finalTidy = function () {
            var ckTidied, extSafe, processor;

            // this sometimes gets called before the editor has warmed up
            if (editorCmp.tidyEditor.dataProcessor) {
                processor = editorCmp.tidyEditor.dataProcessor;
                ckTidied = processor.toHtml(editor.getData());
                extSafe = processor.toDataFormat(ckTidied);
                editor.setData(extSafe);
            }
        };

        if (!this.tidyEditor) {
            this.initTidyEditor(finalTidy);
        }
        else {
            finalTidy();
        }

        return true;
    }
});
Ext.reg('air2ckeditor', AIR2.UI.CKEditor);
