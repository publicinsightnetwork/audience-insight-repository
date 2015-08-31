AIR2.Inquiry.editQuestion = function (dv, index, node, event) {

    var buildChoiceSet,
        choiceItems,
        choiceSet,
        ckEditorConfig,
        dTypes,
        editEl,
        editForm,
        editWindow,
        includeOption,
        items,
        moveOption,
        parseChoice,
        ques_choices,
        question_locks,
        record,
        recordUuid,
        response_options,
        rowTypes,
        store,
        type,
        typeNormalized,
        viewport;

    //tell our ckeditor to be _very_ plain here
    ckEditorConfig = {
        removeButtons:'Bold,Italic,Cut,Copy,Paste,Undo,Redo,Anchor,Underline,' +
            'Strike,Subscript,Superscript'
    };

    if (!node) {
        Logger("node not defined:", arguments);
        return;
    }

    recordUuid = node.getAttribute('data-record-uuid');
    store = AIR2.Inquiry.quesStore;
    record = store.getAt(store.find('ques_uuid', recordUuid));

    if (!record) {
        return;
    }

    response_options = Ext.decode(record.get('ques_resp_opts')) || {};
    question_locks = Ext.decode(record.get('ques_locks')) || [];

    items = [
        {
            xtype: 'air2ckeditor',
            ckEditorConfig: ckEditorConfig,
            fieldLabel: 'Question',
            name: 'ques_value'
        }
    ];

    type = record.get('ques_type');

    // hidden questions have lowercase type
    if (!Ext.num(type, false)) {
        typeNormalized = type.toUpperCase();
    }
    else {
        typeNormalized = type;
    }

    // can't edit break type
    if (AIR2.Inquiry.QUESTION.TYPE.BREAK.indexOf(typeNormalized) > -1
        ||
        AIR2.Inquiry.QUESTION.TYPE.PAGEBREAK.indexOf(typeNormalized) > -1
    ) {
        return;
    }

    moveOption = function (dragEl, targetEl, proxy) {
        var container,
            containerEl,
            displacedOption,
            dragIndex,
            dragItem,
            oldIndex,
            newIndex,
            newOption,
            targetIndex;

        containerEl = dragEl.findParentNode('fieldset', null, true);
        if (containerEl) {
            container = Ext.getCmp(Ext.id(containerEl));
            dragIndex = container.items.findIndex('id', dragEl.id);
            targetIndex = container.items.findIndex('id', targetEl.id);

            dragItem = container.items.itemAt(dragIndex);
            newOption = Ext.create(dragItem.cloneConfig());

            newIndex = targetIndex + 1;

            if (newIndex < 0 || newIndex > container.items.getCount()) {
                return;
            }

            if (displacedOption) {
                displacedOption.items.each(function (item, iIndex, itemsArray) {
                    item.airIndex = oldIndex;
                });
            }

            newOption.items.each(function (item, iIndex, itemsArray) {
                var val;

                item.airIndex = newIndex;
                val = dragItem.items.get(iIndex).getValue();
                item.setValue(val);
            });

            if (proxy) {
                proxy.endDrag();
            }

            container.remove(dragItem);
            container.insert(newIndex, newOption);

            container.doLayout();

            container.items.each(function (item, iIndex, itemsArray) {
                item.items.each(function (subItem, subIndex, subItems) {
                    subItem.airIndex = iIndex;
                });
            });
        }
    };

    buildChoiceSet = function (item, index, ques_choices) {
        var buttonSet,
            dragConfig,
            fieldset,
            fieldsetClass,
            fieldsetItems,
            fieldsetListeners;

        if (item.disableForm) {
            buttonSet = [];
            dragConfig = false;
            fieldsetListeners = {};
        }
        else {
            buttonSet = [{
                xtype: 'air2button',
                air2type: 'CLEAR',
                iconCls: 'air2-icon-delete',
                tooltip: 'Delete option',
                handler: function (button, event) {
                    fieldset.destroy();
                },
                scope: this
            }];
            dragConfig = {
                ddGroup: 'questionOptions',
                onDragDrop : function (event, targetElId) {
                    var dragEl, targetEl;
                    dragEl = Ext.get(this.getEl());
                    targetEl = Ext.get(targetElId);
                    targetEl.removeClass('drag-after');
                    moveOption(dragEl, targetEl, this);
                    return true;
                },
                onDragEnter : function (evtObj, targetElId) {
                    var targetEl = Ext.get(targetElId);
                    targetEl.addClass('drag-after');
                },
                onDragOut : function (evtObj, targetElId) {
                    var targetEl = Ext.get(targetElId);
                    targetEl.removeClass('drag-after');
                }
            };

            fieldsetListeners = {
                'afterrender' : function () {
                    fieldset.dd.isTarget = true;
                }
            };
        }

        fieldsetItems = [{
            airIndex: index,
            airKey: 'value',
            airOption: true,
            ckEditorConfig: ckEditorConfig,
            disabled: item.disableForm,
            fieldLabel: 'Value',
            name: 'option_' + index + '_value',
            value: item.value,
            xtype: 'air2ckeditor'
        }];

        if (AIR2.Inquiry.QUESTION.TYPE.CHECKBOX.indexOf(typeNormalized) > -1) {
            fieldsetItems.push({
                airIndex: index,
                airKey: 'isselected',
                airOption: true,
                checked: item.isselected,
                disabled: item.disableForm,
                fieldLabel: 'Checked',
                name: 'option_' + index + '_isselected',
                value: true,
                xtype: 'checkbox'
            });
        }

        fieldsetItems.push({
            airIndex: index,
            airKey: 'isdefault',
            airOption: true,
            checked: item.isdefault,
            disabled: item.disableForm,
            fieldLabel: 'Default',
            name: 'isdefault',
            value: true,
            xtype: 'radio'
        });

        fieldsetClass = 'air2-field-form-option';

        if (dragConfig) {
            fieldsetClass += ' draggable';
        }

        fieldset = new Ext.form.FieldSet({
            buttons: buttonSet,
            cls: fieldsetClass,
            draggable: dragConfig,
            items: fieldsetItems,
            listeners: fieldsetListeners,
            title: 'Option',
            xtype: 'fieldset'
        });

        return fieldset;

    };


    if (
        AIR2.Inquiry.MULTIPLE_CHOICE_TYPE_QUESTIONS.indexOf(typeNormalized) > -1
    ) {
        ques_choices = Ext.decode(record.get('ques_choices'));
        choiceItems = [];

        parseChoice = function (item, index, items) {
            var subChoiceSet;
            if (question_locks.indexOf('ques_choices') > -1) {
                item.disableForm = true;
            }
            else {
                item.disableForm = false;
            }

            subChoiceSet = buildChoiceSet(item, index, items);
            choiceItems.push(subChoiceSet);
        };

        Ext.each(ques_choices, parseChoice);

        choiceSet = new Ext.form.FieldSet({
            buttons: [{
                xtype: 'air2button',
                air2type: 'FRIENDLY',
                air2size: 'SMALL',
                iconCls: 'air2-icon-add',
                tooltip: 'Add an option',
                handler: function () {
                    var newSet;
                    newSet = buildChoiceSet(
                        {value : '', isdefault : '', isselected : ''},
                        choiceSet.items.getCount(),
                        false
                    );

                    choiceSet.add(newSet);
                    choiceSet.doLayout();
                },
                scope: this
            }],
            id: 'air2-field-editor-choice-options',
            items: choiceItems,
            title: 'Options',
            xtype: 'fieldset'
        });

        items.push(choiceSet);
    }

    includeOption = function (key) {
        if (
            response_options &&
            response_options.hasOwnProperty(key) &&
            question_locks.indexOf(key) === -1
        ) {
            return true;
        }
        else {
            return false;
        }
    };

    if (includeOption('minlen')) {
        items.push({
            xtype: 'numberfield',
            allowDecimals: false,
            allowNegative: false,
            fieldLabel: 'Minimum Length',
            name: 'minlen',
            value: response_options.minlen,
            width: 50
        });
    }

    if (includeOption('maxlen')) {
        items.push({
            xtype: 'numberfield',
            allowDecimals: false,
            allowNegative: false,
            fieldLabel: 'Maximum Length',
            name: 'maxlen',
            value: response_options.maxlen,
            width: 50
        });
    }

    if (includeOption('minnum')) {
        items.push({
            xtype: 'numberfield',
            allowDecimals: false,
            allowNegative: true,
            fieldLabel: 'Minimum Number',
            name: 'minnum',
            value: response_options.minnum,
            width: 50
        });
    }


    if (includeOption('maxnum')) {
        items.push({
            xtype: 'numberfield',
            allowDecimals: false,
            allowNegative: true,
            fieldLabel: 'Maximum Number',
            name: 'maxnum',
            value: response_options.maxnum,
            width: 50
        });
    }

    if (includeOption('intnum')) {
        items.push({
            xtype: 'checkbox',
            fieldLabel: 'Require Integer (whole number)',
            name: 'intnum',
            value: 'true'
        });
    }

    if (includeOption('require')) {
        items.push({
            xtype: 'checkbox',
            checked: (response_options && response_options.require === true),
            fieldLabel: 'Required',
            name: 'require',
            style: 'width:auto',
            value: 'true'
        });
    }
    else {
        items.push({
            xtype: 'checkbox',
            checked: (response_options && response_options.require === true),
            disabled: true,
            fieldLabel: 'Required',
            name: 'require',
            style: 'width:auto',
            value: 'true'
        });
    }

    dTypes = AIR2.Inquiry.QUESTION.TYPE.RADIO.concat(
        AIR2.Inquiry.QUESTION.TYPE.CHECKBOX
    );

    if (dTypes.indexOf(typeNormalized) > -1) {

        // deal with questions that are missing this option
        if (! response_options.hasOwnProperty('direction')) {
            response_options.direction = 'V';
        }

        items.push({
            displayField: 'display',
            editable: false,
            fieldLabel: 'Direction',
            forceSelection: true,
            hiddenName: 'direction',
            mode: 'local',
            store: new Ext.data.ArrayStore({
                id: 0,
                fields: [
                    'direction',
                    'display'
                ],
                data: [['V', 'Vertical'], ['H', 'Horizontal']]
            }),
            typeAhead: false,
            triggerAction: 'all',
            valueField: 'direction',
            value: response_options.direction || 'V',
            width: 100,
            xtype: 'combo'
        });
    }

    // hidden checkbox only shown if input is a text field
    // or is hidden already (legacy formbuilder)
    // hidden fields are always output as type='hidden'
    if (
        (!Ext.num(type, false) && type === type.toLowerCase()) ||
         AIR2.Inquiry.QUESTION.TYPE.TEXT.indexOf(typeNormalized) > -1 ||
         AIR2.Inquiry.QUESTION.TYPE.TEXTAREA.indexOf(typeNormalized) > -1
    ) {
        items.push({
            xtype: 'checkbox',
            checked: (type === type.toLowerCase()),
            fieldLabel: 'Hidden Question',
            name: 'question_is_hidden',
            value: 'true'
        });
    }

    rowTypes = AIR2.Inquiry.QUESTION.TYPE.TEXTAREA.concat(
        AIR2.Inquiry.QUESTION.TYPE.MULTI_SELECT
    );

    if (rowTypes.indexOf(typeNormalized) > -1) {
        // deal with questions that are missing this option
        if (! response_options.hasOwnProperty('rows')) {
            response_options.rows = null;
        }

        items.push({
            xtype: 'numberfield',
            allowDecimals: false,
            allowNegative: false,
            fieldLabel: 'Rows',
            name: 'rows',
            value: response_options.rows,
            width: 50
        });
    }

    node = Ext.get(node, true);
    editEl = new Ext.Element(node, true);

    editForm = new Ext.form.FormPanel({
        cls: 'air2-panel-editinplace air2-panel-body ques-row',
        bbar: [
            {
                xtype: 'air2button',
                air2type: 'SAVE',
                air2size: 'MEDIUM',
                text: 'Save',
                handler: function () {
                    editForm.endEdit(true);
                }
            },
            {
                xtype: 'air2button',
                air2type: 'CANCEL',
                air2size: 'MEDIUM',
                text: 'Cancel',
                style: 'margin-left:4px',
                handler: function () {
                    editForm.endEdit(false);
                }
            }
        ],
        bodyCls: 'air2-question-edit-form-body',
        defaults: {style: {width: '96%'}},
        endEdit: function (save) {
            var basicForm, formPanel, quesChoices, responseOptions;

            // hang onto form panel for later
            formPanel = this;
            basicForm = editForm.getForm();

            if (save) {
                quesChoices = [];

                basicForm.items.each(function (item, index, count) {
                    var aIndex, aKey, quesType, name, value;

                    // option re-ordering results in duplicate
                    // objects marked destroyed
                    if (!item.isDestroyed && !item.disabled) {
                        value = item.getValue();
                        name = item.getName();

                        if (item.airOption) {
                            // catch multiple choice choices
                            aIndex = item.airIndex;
                            aKey = item.airKey;
                            if (!quesChoices[aIndex]) {
                                quesChoices[aIndex] = {};
                            }
                            quesChoices[aIndex][aKey] = value;
                        }
                        else if (name == 'question_is_hidden') {
                            quesType = record.get('ques_type');
                            if (value) {
                                record.forceSet(
                                    'ques_type',
                                    quesType.toLowerCase()
                                );
                            }
                            else {
                                record.forceSet(
                                    'ques_type',
                                    quesType.toUpperCase()
                                );
                            }
                        }
                        else if (
                            formPanel.responseOptions &&
                            formPanel.responseOptions.hasOwnProperty(name) &&
                            !question_locks.hasOwnProperty(name)
                        ) {
                            formPanel.responseOptions[name] = value;
                        }
                        else if (!question_locks.hasOwnProperty(name)) {
                            record.forceSet(name, value);
                        }
                    }
                });

                if (quesChoices.length) {
                    record.forceSet('ques_choices', Ext.encode(quesChoices));
                }

                record.forceSet(
                    'ques_resp_opts',
                    Ext.encode(formPanel.responseOptions)
                );

                record.endEdit();
                AIR2.Inquiry.quesStore.save();
            }
            else {
                record.cancelEdit();
            }

            editWindow.close();

            // node.setVisible(true);
        },
        id: 'air2-question-edit-form',
        items: [items],
        renderTo: editEl,
        responseOptions: response_options,
        unstyled: true,
        width: 700
    });

    editForm.getForm().loadRecord(record);

    Ext.getCmp('air2-app').doLayout();

    viewport = Ext.getBody().getViewSize();

    editWindow = new AIR2.UI.Window({
        closable: false,
        height: (viewport.height - 80),
        id: 'air2-question-edit-window',
        items: [editForm],
        layout: 'fit',
        modal: true,
        title: 'Edit Field',
        width: 700
    });

    editWindow.on('show', function (window) {
        var position, viewport;

        viewport = Ext.getBody().getViewSize();

        if (window.getHeight() > (viewport.height - 80)) {
            position = window.getPosition();
            window.setPosition(position[0], 40);
            window.setHeight(viewport.height - 80);
        }

        if (window.getWidth() > (viewport.width - 80)) {
            window.setWidth(viewport.width - 80);
            position = window.getPosition();
            window.setPosition(40, position[1]);
        }

    });

    editWindow.show(node);

};
