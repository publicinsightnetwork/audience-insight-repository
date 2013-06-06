/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

Ext.ns('AIR2.Search.Inquiry');

// global cache
AIR2.Search.Inquiry.CACHE = {};

AIR2.Search.Inquiry.addToCache = function (inqs) {
    var C = AIR2.Search.Inquiry.CACHE;
    Ext.each(inqs, function (item, idx, array) {
        // each inq has array of questions with sequence numbers
        C[item.inq_uuid] = {title: item.inq_title, questions: []};
        Logger("added to inquiry cache: " + item.inq_uuid);
        Ext.each(item.ques_seq_value, function (qsv, idx2, array2) {
            var m = qsv.match(/^(\d+):(.+)/);
            C[item.inq_uuid].questions[parseInt(m[1], 10)] = m[2];
        });
    });
};

AIR2.Search.Inquiry.ChainedPicker = function (pickerPanel) {
    var pickProject, projectList, projectTpl;

    projectTpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item project">' +
                '{prj_display_name}' +
            '</div>' +
        '</tpl>'
    );

    pickProject = function (list) {
        var iP, rec, v;

        v = list.getValue();
        rec = projectList.store.getById(v);
        Logger("project changed: ", v, rec);
        // add a new combobox for selecting an inquiry
        iP = AIR2.Search.Inquiry.InquiryPicker(v, pickerPanel);
        pickerPanel.setInquiryPicker(iP);
        pickerPanel.doLayout();
        pickerPanel.setProjectQuery(rec.get('prj_name'));
        pickerPanel.clause.updateDisplay();
    };

    projectList = new AIR2.Search.Inquiry.PickerBox({
        width : 700,
        searchUrl: AIR2.HOMEURL + '/project',
        baseParams: {
            sort: 'prj_display_name asc'
        },
        pageSize: 10,
        cls: 'air2-magnifier adv-search-list',
        hideTrigger: false,
        mode  : 'remote',
        border: false,
        forceSelection: true,
        triggerAction: 'all',
        selectOnFocus: true,
        fieldLabel: 'Project',
        emptyText: 'Select a Project',
        loadingText: 'Getting list of Projects...',
        valueField: 'prj_uuid',
        displayField: 'prj_display_name',
        tpl: projectTpl,
        listeners : {
            'select' : pickProject
        },
        removeFromParent : function () {
            Logger("remove this picker");
            pickerPanel.resetProjectPicker();
            pickerPanel.updateDisplay();
        }
    });

    return projectList;
};

AIR2.Search.Inquiry.InquiryPicker = function (prj_uuid, pickerPanel) {
    var iP, ipTemplate;

    ipTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item inq">' +
                '<span class="inq_ext_title">' +
                    '{[values["inq_ext_title"]]}' +
                '</span> ' +
                '<span class="inq_title">' +
                    '({[values["inq_title"]]})' +
                '</span>' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    iP = new AIR2.Search.Inquiry.PickerBox({
        searchUrl: AIR2.HOMEURL + '/inquiry',
        baseParams: {
            sort: 'inq_cre_dtim desc',
            prj_uuid: prj_uuid
        },
        pageSize: 10,
        cls: 'air2-magnifier',
        hideTrigger: false,
        emptyText:      'Select a Query',
        fieldLabel:     'Query',
        border:         false,
        width:          700,
        forceSelection: true,
        triggerAction:  'all',
        displayField:   'inq_ext_title',
        valueField:     'inq_uuid',
        wrapFocusClass: 'picker-wrapper',
        loadingText:    'Getting list of Queries...',
        //itemSelector:   'div.inq',
        selectOnFocus: true,
        tpl: ipTemplate,
        listeners: {
            'select' : function (thisBox, ev) {
                var qP, v;

                v = thisBox.getValue();
                Logger("Picked a Query", v);
                qP = AIR2.Search.Inquiry.QuestionPicker(v, pickerPanel);
                pickerPanel.setQuestionPicker(qP);
                pickerPanel.doLayout();
                pickerPanel.setInquiryQuery(v);
                pickerPanel.clause.updateDisplay();
            }
        },
        removeFromParent : function () {
            Logger("remove this picker");
            pickerPanel.resetInquiryPicker();
            pickerPanel.updateDisplay();
        }
    });

    return iP;
};

AIR2.Search.Inquiry.QuestionPicker = function (inq_uuid, pickerPanel) {
    var qP, qpTemplate;

    qpTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item question">' +
                '<span>{ques_value}</span>' +
            '</div>' +
        '</tpl>'
    );

    qP = new AIR2.Search.Inquiry.PickerBox({
        searchUrl: AIR2.HOMEURL + '/inquiry/' + inq_uuid + '/question',
        baseParams: {
            sort: 'ques_dis_seq asc'
        },
        pageSize: 10,
        cls: 'air2-magnifier',
        hideTrigger: false,
        emptyText: 'Select a Question',
        fieldLabel: 'Question',
        border: false,
        width: 700,
        forceSelection: true,
        triggerAction: 'all',
        displayField: 'ques_value',
        valueField: 'ques_uuid',
        loadingText: 'Getting questions...',
        selectOnFocus: true,
        tpl : qpTemplate,
        listeners: {
            'select' : function (cbox, ev) {
                var aP, ques_choices, rec, v;

                v = cbox.getValue();
                Logger("Picked a question:", v);
                rec   = this.store.getById(v);
                Logger(rec);
                ques_choices = rec.get('ques_choices');

                if (ques_choices) {
                    aP = AIR2.Search.Inquiry.AnswerPicker(
                        ques_choices,
                        pickerPanel
                    );
                }
                else {
                    aP = AIR2.Search.Inquiry.AnswerFullText(rec, pickerPanel);
                }
                pickerPanel.setAnswerPicker(aP);
                pickerPanel.doLayout();
                pickerPanel.setQuestionQuery(rec.get('ques_uuid'));
                pickerPanel.clause.updateDisplay();
            }
        },
        removeFromParent : function () {
            //Logger("remove question picker");
            pickerPanel.resetQuestionPicker();
            pickerPanel.updateDisplay();
        }
    });

    return qP;
};

AIR2.Search.Inquiry.AnswerPicker = function (values, pickerPanel) {
    var choices, defaultVal, label, opts, vP, vpTemplate;

    //Logger("values:", values);
    choices = Ext.decode(values);
    //Logger("choices:", choices);

    opts = [];
    Ext.each(choices, function (item, idx, arr) {
        if (item.isdefault) {
            defaultVal = item.value;
        }
        opts.push(item.value);
    });
    label = (values.length) ? 'Select an Answer' : 'Enter an answer';

    vpTemplate = new Ext.XTemplate(
        '<tpl for=".">',
            '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item answer">',
                '<span>{field1}</span>',
            '</div>' +
        '</tpl>'
    );

    vP = new AIR2.Search.Inquiry.PickerBox({
        store: opts,
        emptyText: label,
        fieldLabel: 'Answer',
        border: false,
        width: 700,
        value: defaultVal,
        forceSelection: false,  // allow free-form entry
        hideTrigger: false,
        triggerAction: 'all',
        selectOnFocus: true,
        tpl : vpTemplate,
        listeners: {
            'select' : function (vbox, ev) {
                var v = vbox.getValue();
                Logger("Picked an answer:", v);
                pickerPanel.setAnswerQuery(v);
                pickerPanel.clause.updateDisplay();
            },
            'keyup' : function (vbox, ev) {
                var v = vbox.getRawValue();
                Logger("entered answer:", v);   // TODO this is broken
                pickerPanel.setAnswerQuery(v);
                pickerPanel.updateDisplay();
            }
        },
        removeFromParent : function () {
            //Logger("remove question picker");
            pickerPanel.resetAnswerPicker();
            pickerPanel.updateDisplay();
        }
    });
    return vP;
};

AIR2.Search.Inquiry.AnswerFullText = function (rec, pickerPanel) {
    var aft, aftTemplate, ques_uuid, store;

    ques_uuid = rec.get('ques_uuid');
    store = new AIR2.Search.JsonStore({
        idx: 'responses',
        baseParams: {
            'i' : 'responses'
        },
        listeners:      {
            load: function (thisStore, records, thisOptions) {
                thisStore.isInProcess = false;
                //Logger(thisOptions);
                pickerPanel.setAnswerFullTextQuery(thisStore.rawQuery);
                pickerPanel.clause.updateDisplay();
            }
        }
    });

    aftTemplate =
        '<tpl for=".">' +
            '<div class="{[ xindex % 2 ? "alt" : "" ]} picker-item answer">' +
                '{summary}' +
            '</div>' +
        '</tpl>';

    aft = new Ext.form.ComboBox({
        store           : store,
        triggerClass    : 'x-form-clear-trigger',
        minChars        : 2, // one-char queries return too many hits
        enableKeyEvents : true,
        mode            : 'remote',
        queryParam      : 'q',
        queryDelay      : 300, // ms between typing stop and server request.
        width           : 700,
        border          : false,
        fieldLabel      : 'Answer',
        displayField    : 'summary',
        listClass       : 'picker-box',
        itemSelector    : 'div.picker-item',
        selectedClass   : 'picker-item-selected',
        tpl             : aftTemplate,
        onTriggerClick  : function () {
            //Logger('triggerClick');
            pickerPanel.resetAnswerPicker();
            pickerPanel.updateDisplay();
        },
        listeners       : {
            'beforequery'   : function (queryEvent) {
                var q = queryEvent.query;

                queryEvent.query = 'ques_uuid=' + ques_uuid +
                    ' AND qa=(' + q + ')';
                //Logger("query:" + queryEvent.query);
                store.rawQuery = q;  // what we set for chained query
            }
        }

    });

    return aft;
};


AIR2.Search.Inquiry.PickerBox = Ext.extend(AIR2.UI.SearchBox, {

    initComponent : function () {
        AIR2.Search.Inquiry.PickerBox.superclass.initComponent.call(this);

        this.triggerConfig = {
            tag: 'span',
            cls: 'x-form-twin-triggers',
            cn: [
                {
                    tag: "img",
                    src: Ext.BLANK_IMAGE_URL,
                    cls: "x-form-trigger " + this.trigger1Class
                },
                {
                    tag: "img",
                    src: Ext.BLANK_IMAGE_URL,
                    cls: "x-form-trigger " + this.trigger2Class
                }
            ]
        };
    },

    trigger2Class: 'x-form-clear-trigger',

    listClass:      'picker-box',
    itemSelector:   'div.picker-item',
    selectedClass:  'picker-item-selected',

    getTrigger : function (index) {
        return this.triggers[index];
    },

    initTrigger : function () {
        var triggerField, ts;

        ts = this.trigger.select('.x-form-trigger', true);
        triggerField = this;
        ts.each(
            function (t, all, index) {
                var triggerIndex = 'Trigger' + (index + 1);
                t.hide = function () {
                    var w = triggerField.wrap.getWidth();
                    this.dom.style.display = 'none';
                    triggerField.el.setWidth(
                        w - triggerField.trigger.getWidth()
                    );
                    this['hidden' + triggerIndex] = true;
                };
                t.show = function () {
                    var w = triggerField.wrap.getWidth();
                    this.dom.style.display = '';
                    triggerField.el.setWidth(
                        w - triggerField.trigger.getWidth()
                    );
                    this['hidden' + triggerIndex] = false;
                };

                if (this['hide' + triggerIndex]) {
                    t.dom.style.display = 'none';
                    this['hidden' + triggerIndex] = true;
                }
                this.mon(
                    t,
                    'click',
                    this['on' + triggerIndex + 'Click'],
                    this,
                    {preventDefault: true}
                );

                t.addClassOnOver('x-form-trigger-over');
                t.addClassOnClick('x-form-trigger-click');
            },
            this
        );
        this.triggers = ts.elements;
    },

    getTriggerWidth: function () {
        var tw = 0;
        Ext.each(this.triggers, function (t, index) {
            var triggerIndex, w;

            triggerIndex = 'Trigger' + (index + 1);
            w = t.getWidth();
            if (w === 0 && !this['hidden' + triggerIndex]) {
                tw += this.defaultTriggerWidth;
            } else {
                tw += w;
            }
        }, this);
        return tw;
    },

    // private
    onDestroy : function () {
        Ext.destroy(this.triggers);
        AIR2.Search.Inquiry.PickerBox.superclass.onDestroy.call(this);
    },

    onTrigger1Click  : function () {
        this.onTriggerClick();
    },

    onTrigger2Click : function () {
        // remove the Box (and any children) from the parent
        this.removeFromParent();
    }

});

