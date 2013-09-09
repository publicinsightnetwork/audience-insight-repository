Ext.ns('AIR2.UI');
/***************
 * AIR2 CKEditor Component
 *
 * AIR2 Plugin.
 *
 *
 */

AIR2.UI.CKEditor = Ext.extend(Ext.form.TextArea,  {
    ckEditorInstance: null,

    constructor: function (config) {
        config = Ext.apply({ grow: true }, config);

        config.ckEditorConfig = Ext.apply(
            { autoParagraph: false },
            config.ckEditorConfig
        );


        AIR2.UI.CKEditor.superclass.constructor.call(this, config);
    },

    onRender: function (ct, position) {
        if (!this.el) {
            this.defaultAutoCreate = {
                tag: "textarea",
                autocomplete: "off"
            };
        }
        Ext.form.TextArea.superclass.onRender.call(this, ct, position);

        this.initCkEditor();
        this.initTidyEditor();

        // make sure we have a separate instance for tidying
        this.initTidyEditor();
    },

    initCkEditor : function () {
        var editor;

        editor = CKEDITOR.replace(
            this.id,
            this.initialConfig.ckEditorConfig
        );

        this.ckEditorInstance = editor;
    },

    setValue : function (value) {
        Ext.form.TextArea.superclass.setValue.apply(this, [value]);
    },

    getValue : function () {
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
        return this.ckEditorInstance.getData();
    },

    onDestroy: function () {
        if (CKEDITOR.instances[this.id]) {
            delete CKEDITOR.instances[this.id];
        }
    },

    insertHtml: function (html) {
        this.ckEditorInstance.insertHtml(html);
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

            config = Ext.apply({ autoParagraph: false }, config);

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
