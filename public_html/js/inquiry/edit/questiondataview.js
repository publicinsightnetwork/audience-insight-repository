/***********************
 * Constructs a new question dataview grouping
 */
AIR2.Inquiry.QuestionDataView = function (displayMode) {
    var applyDragConfig,
        canBePublic,
        canDeleteCategory,
        cls,
        contactTypes,
        dataview,
        defaultText,
        dzGroup,
        isAllowedHandler,
        isPublic,
        permissionTypes,
        sectionLabel,
        template;

    contactTypes = AIR2.Inquiry.QUESTION.TYPE.CONTACT;
    permissionTypes = AIR2.Inquiry.QUESTION.TYPE.PERMISSION;
    switch (displayMode) {
    case AIR2.Inquiry.QuestionDataView.CONTACTMODE:
        canDeleteCategory = true;
        cls = 'contact dropzone';
        defaultText = 'Drag questions here to get started';
        dzGroup = 'contact';
        sectionLabel =  'Contact Fields';
        isAllowedHandler =  function (values) {
            var normalizedType;

            if (Ext.num(values.ques_type)) {
                normalizedType = values.ques_type;
            }
            else {
                normalizedType = values.ques_type.toUpperCase();
            }

            if (contactTypes.indexOf(normalizedType) > -1) {
                return true;
            }

            return false;
        };
        break;
    case AIR2.Inquiry.QuestionDataView.PUBLICMODE:
        canDeleteCategory = true;
        cls = 'public dropzone';
        defaultText = 'Drag questions here to get started';
        dzGroup = 'any';
        isPublic = true;
        sectionLabel = 'Publishable&nbsp;Fields';
        isAllowedHandler = function (values, moving) {
            var inqStatus,
                normalizedPublicFlag,
                normalizedType,
                templateRec,
                templateSetting;

            moving = moving || false;

            if (Ext.num(values.ques_type)) {
                normalizedType = values.ques_type;
            }
            else {
                normalizedType = values.ques_type.toUpperCase();
            }


            // non-contributor templates do not have a public flag set and
            // can be placed in either public or private mode dataviews
            normalizedPublicFlag = true;

            // if a query hasn't been published questions in the non-publishable
            // section can be moved, but only if they're based on a publishable
            // question template
            inqStatus = AIR2.Inquiry.inqStore.getAt(0).get('inq_status');

            if (moving && inqStatus === AIR2.Inquiry.STATUS_DRAFT) {

                //get the question template and setting
                //if template is unset assume 'textarea'
                if (
                    !values.hasOwnProperty('ques_template') ||
                    !values.ques_template
                ) {
                    values.ques_template = 'textarea';
                }

                templateRec = AIR2.Inquiry.createQuestionRecord(values.ques_template);
                templateSetting = templateRec.get('ques_public_flag');

                // most questions do not have this flag set and can be ignored
                if (Ext.isDefined(templateSetting)) {
                    normalizedPublicFlag = templateSetting;
                }
            }
            else if (values.hasOwnProperty('ques_public_flag')) {
                normalizedPublicFlag = values.ques_public_flag;
            }

            if (
                normalizedPublicFlag &&
                permissionTypes.indexOf(normalizedType) === -1 &&
                contactTypes.indexOf(normalizedType) === -1
            ) {
                return true;
            }

            return false;
        };
        break;
    case AIR2.Inquiry.QuestionDataView.PRIVATEMODE:
        canDeleteCategory = true;
        cls =  'private dropzone';
        defaultText = 'Drag questions here to get started';
        dzGroup = 'any';
        isPublic = false;
        sectionLabel =  'Non-publishable&nbsp;Fields';
        isAllowedHandler =  function (values, moving) {
            var normalizedPublicFlag, normalizedType;

            if (Ext.num(values.ques_type)) {
                normalizedType = values.ques_type;
            }
            else {
                normalizedType = values.ques_type.toUpperCase();
            }

            if (moving) {
                normalizedPublicFlag = false;
            }
            else {
                normalizedPublicFlag = values.ques_public_flag || false;
            }

            if (
                !normalizedPublicFlag &&
                permissionTypes.indexOf(normalizedType) === -1 &&
                contactTypes.indexOf(normalizedType) === -1
            ) {
                return true;
            }

            return false;
        };
        break;
    case AIR2.Inquiry.QuestionDataView.PERMISSIONMODE:
        canDeleteCategory = false;
        cls =  'permission';
        defaultText = false;
        dzGroup = 'none';
        isPublic = true;
        sectionLabel =  false;
        isAllowedHandler =  function (values) {

            // permission types include 'p' and 'P'
            // no need to normalize
            if (permissionTypes.indexOf(values.ques_type) > -1) {
                return true;
            }

            return false;
        };
        break;
    }

    canBePublic = function (rec) {
        var locks;
        if (rec.data.ques_locks) {
            locks = Ext.decode(rec.data.ques_locks);
        }

        return !(
            locks &&
            locks.length &&
            locks.indexOf('ques_public_flag') > -1
        );
    };

    template = new Ext.XTemplate(
        '<tpl if="this.hasLabel()">' +
            '<table class="divider">' +
                '<tr>' +
                    '<td class="left"/><td class="label">' +
                        sectionLabel +
                    '</td>' +
                    '<td class="right"/>' +
                '</tr>' +
            '</table>' +
        '</tpl>' +
        '<tpl for=".">' +
            '{[this.renderQuestionRow(xindex, xcount, values)]}' +
        '</tpl>' +
        '<tpl if="this.showDefaultText()">' +
            '<div class="ques-row">' + defaultText + '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            hasLabel: function () {
                return sectionLabel;
            },
            isAllowed: isAllowedHandler,
            showDefaultText: function () {
                var isEmpty, my;

                my = this;
                isEmpty = true;

                //if no default message don't bother checking empty state
                if (!defaultText) {
                    return false;
                }

                AIR2.Inquiry.quesStore.each(function (record) {
                    if (my.isAllowed(record.data)) {
                        isEmpty = false;
                        return false;
                    }
                });

                return isEmpty;
            },
            formatChoices: function (values) {
                var choices, choiceTypes, type, str;

                choiceTypes = AIR2.Inquiry.MULTIPLE_CHOICE_TYPE_QUESTIONS;

                // normalize hidden types
                type = values.ques_type.toUpperCase();

                if (choiceTypes.indexOf(type) !== -1) {
                    str = '<ul>';

                    // multiple values
                    choices = Ext.decode(values.ques_choices);
                    Ext.each(choices, function (item, idx) {
                        var def, fmt, val;

                        // truncate absurdly long choices
                        if (idx > 8) {
                            str += '<li class="">...</li>';
                            return false;
                        }

                        val = item.value;
                        def = item.isdefault;
                        fmt = AIR2.Format.quesChoice(val, type, false, def);
                        str += '<li>' + fmt + '</li>';
                    });

                    str += '</ul>';
                    return str;
                }

                // text, textarea, date, and datetime have no choices
                if (AIR2.Inquiry.QUESTION.TYPE.TEXT.indexOf(type) > -1) {
                    return '<input type="text" disabled></input>';
                }
                if (AIR2.Inquiry.QUESTION.TYPE.TEXTAREA.indexOf(type) > -1) {
                    return '<textarea disabled></textarea>';
                }
                if (AIR2.Inquiry.QUESTION.TYPE.FILE.indexOf(type) > -1) {
                    return '<input type="file" disabled></input>';
                }
                if (AIR2.Inquiry.QUESTION.TYPE.DATE.indexOf(type) > -1) {
                    // stolen!
                    return '<div class="' +
                        'x-form-field-wrap ' +
                        'x-form-field-trigger-wrap ' +
                        'x-item-disabled" ' +
                        'style="' +
                        'width:100px;border-left:1px solid #c1c1c1">' +
                        '<input type="text" ' +
                        'class="x-form-text x-form-field" ' +
                        'style="width: 75px;">' +
                        '<img src="data:image/gif;base64,' +
                        'R0lGODlhAQABAID/AMDAwAAAACH5BAE' +
                        'AAAAALAAAAAABAAEAAAICRAEAOw==" ' +
                        'class="x-form-trigger x-form-date-trigger"></div>';
                }
                return '';
            },
            questionDisplayMode: displayMode,
            renderQuestionRow: function (xindex, xcount, values) {
                var canDeleteQuestion,
                    row,
                    templateData,
                    tip;

                row = '<div class="ques-row" style="display:none"></div>';
                canDeleteQuestion = canDeleteCategory;

                if (this.isAllowed(values)) {
                    if (
                        AIR2.Inquiry.QUESTION.REQUIRED.indexOf(
                            values.ques_template
                        ) > -1
                    ) {
                        canDeleteQuestion = false;
                    }

                    templateData = AIR2.Inquiry.QUESTPLS[values.ques_template];

                    row = '<div class="ques-row" data-record-uuid="' +
                                values.ques_uuid + '">';

                    row += '<div class="handle"></div>' +
                        '<div class="controls">';

                    row += '<button ';

                    if (templateData) {
                        tip = AIR2.Inquiry.getLocalizedValue(
                            templateData,
                            'display_tip'
                        );

                        if (tip) {
                            row += 'ext:qtip="' + tip + '" ';
                        }
                    }

                    if (AIR2.Inquiry.QUESTION.TYPE.BREAK.indexOf(values.ques_type) === -1) {
                        row += 'class="air2-rowedit">Edit</button>';
                    }

                    if (canDeleteQuestion) {
                        row += '<button class="air2-rowdelete">Delete</button>';
                    }

                    row += '</div>';

                    row += '<div class="question">' +
                                '<h4>' + values.ques_value + '</h4>' +
                            '</div>';

                    if (templateData) {
                        row += '<div class="air2-questiontype">(' +
                            AIR2.Inquiry.getLocalizedValue(
                                templateData,
                                'display'
                            ) +
                        ')</div>';
                    }


                    row += '<div class="choices">' +
                                this.formatChoices(values) +
                            '</div>';

                    row += '</div>';
                }

                return row;
            }
        }
    );

    applyDragConfig = function (dataview) {
        var dragConfig;
        dragConfig = AIR2.Inquiry.QuestionDragConfig();
        dataview.air2DDProxies = [];

        Ext.each(dataview.getNodes(), function (item) {
            var handle, itemEl, proxy;

            itemEl = Ext.get(item, true);

            proxy = new Ext.dd.DDProxy(
                itemEl.id,
                'questions',
                { isTarget: true }
            );

            Ext.apply(proxy, dragConfig);

            handle = itemEl.down('.handle');

            proxy.setHandleElId(handle);

            dataview.air2DDProxies.push(proxy);
        });

        //TODO: move this somewhere else as it has nothing to do with dragging
        //catches added records
        Ext.getCmp('air2-app').doLayout();
    };

    // create new dataview
    dataview = new AIR2.UI.JsonDataView({
        autoHeight: true,
        cls: cls,
        questionDisplayMode: displayMode,
        isAllowed: isAllowedHandler,
        isPublic: isPublic,
        itemSelector: '.ques-row',
        listeners: {
            afterrefresh: { fn: applyDragConfig }
        },
        overClass: 'ques-over',
        renderEmpty: true,
        store: AIR2.Inquiry.quesStore,
        tpl: template
    });

    dataview.addListener({
        'click' : {
            fn: function (dv, index, node, event) {
                if (event.getTarget('.air2-rowedit')) {
                    AIR2.Inquiry.editQuestion(dv, index, node, event);
                }
                if (event.getTarget('.air2-rowdelete')) {
                    AIR2.Inquiry.questionDelete(dv, node);
                }
            },
            scope: this
        },
        'dblclick' : {
            fn: AIR2.Inquiry.editQuestion
        }
    });

    AIR2.Inquiry.EDITABLECOMPONENTS.push(dataview);

    return dataview;
};

AIR2.Inquiry.QuestionDataView.CONTACTMODE = 1;
AIR2.Inquiry.QuestionDataView.PUBLICMODE = 2;
AIR2.Inquiry.QuestionDataView.PRIVATEMODE = 3;
AIR2.Inquiry.QuestionDataView.PERMISSIONMODE = 4;
