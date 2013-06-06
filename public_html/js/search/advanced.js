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

Ext.ns('AIR2.Search.Advanced');
Ext.ns('AIR2.Search.Advanced.Source');

// custom Vtype for vtype:'Integer'
Ext.apply(Ext.form.VTypes, {
    Integer: function (v) {
        return (/^[\d\?\*]+$/.test(v));   // allow wildcards
    },
    IntegerText: 'Must be an integer'
});

AIR2.Search.Advanced.EXPLAIN = 'adv-search-query-explain';
AIR2.Search.Advanced.BOOLEAN = 'adv-search-master-boolean';
AIR2.Search.Advanced.FORMID  = 'adv-search-form';

// See note in fixtures.js about user_* vs src_* vs *
AIR2.Search.Advanced.Fields = {
    'sources' : [
        //{ name: 'sact_actm_id'              , type: 'auto',
        //  list: function () { return AIR2.Fixtures.Activities }
        // TODO populate this
        //},
        {
            name: 'annotation',
            type: 'string',
            group: 'Profile'
        },
        {
            name: 'email',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'city',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'profile',
            type: 'string',
            group: 'Profile',
            label: 'All Profile Fields'
        },
        {
            name: 'submission',
            type: 'string',
            label: 'Submissions',
            group: 'Activity'
        },
        {
            name: 'state',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.States;
            }
        },
        {
            name: "country",
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Countries;
            }
        },
        {
            name: 'zip',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'county',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'birth_year',
            group: 'Profile',
            type: 'int'
        },
        {
            name: 'src_education_level_id',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.education_level;
            }
        },
        {
            name: 'employer',
            group: 'Profile',
            type: 'string',
            label: 'Employer'
        },  // NOTE this is deprecated for experience_where
        {
            name: 'src_first_name',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'user_gender_id',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.gender;
            }
        },
        {
            name: 'gender',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'household_income',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.household_income;
            },
            sortBy: "key"
        },
        {
            name: 'src_last_name',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'political_affiliation',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.political_affiliation;
            }
        },
        {
            name: 'pref_lang',
            type: 'auto',
            group: 'Profile',
            list: function () {
                return [
                    ['NULL', 'None'],
                    ['es_US', 'Spanish'],
                    ['en_US', 'English']
                ];
            }  // TODO programmatic?
        },
        {
            name: 'experience_where',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'experience_what',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'interest',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'user_religion_id',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.religion;
            }
        },
        {
            name: 'religion',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'user_ethnicity_id',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return AIR2.Fixtures.Facts.ethnicity;
            }
        },
        {
            name: 'ethnicity',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'src_uuid',
            group: 'Profile',
            type: 'string'
        },
        {
            name: 'activity',
            type: 'string',
            label: 'Activity log',
            group: 'Activity'
        },
        {
            name: 'form',
            type: 'form',
            label: 'Query',
            group: 'Activity'
        },
        {
            name: 'first_responded_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'last_responded_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'last_queried_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'last_activity_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'created_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'modified_date',
            group: 'Activity',
            type: 'date'
        },
        {
            name: 'not_queried',
            group: 'Activity',
            type: 'activity',
            defValue: 30,
            label: 'Not queried in the last...'
        },
        {
            name: 'no_activity',
            group: 'Activity',
            type: 'activity',
            defValue: 30,
            label: 'No activity in the last...'
        },
        {
            name: 'new_source',
            group: 'Activity',
            type: 'activity',
            label: 'New in the last...'
        },
        {
            name: 'unsubscribed',
            group: 'Activity',
            type: 'activity',
            label: 'Unsubscribed or opted-out in the last...'
        },
        {
            name: 'org_name',
            group: 'Profile',
            type: 'auto',
            label: 'Organization',
            list: function () {
                var orgs = [];
                Ext.iterate(AIR2.Search.OrgNames, function (k, v, o) {
                    orgs.push([v.org_name, v.org_display_name]);
                });
                // alphabetize by label
                return orgs.sort(function (a, b) {
                    if (a[1].toLowerCase() < b[1].toLowerCase()) {
                        return -1;
                    }
                    if (b[1].toLowerCase() < a[1].toLowerCase()) {
                        return 1;
                    }
                    return 0;
                });
            }
        },
        {
            name: 'valid_email',
            group: 'Profile',
            type: 'auto',
            list: function () {
                return [['0', 'False'], ['1', 'True']];
            }
        },
        {
            name: 'src_has_acct',
            group: 'Profile',
            type: 'auto',
            label: 'Has SOURCE Account',
            list: function () {
                return [['Y', 'Yes'], ['N', 'No']];
            }
        },
        {
            name: 'tag',
            type: 'string',
            label: 'Tag',
            group: 'Profile'
        }
    ],
    'active-sources' : []  //populate below
    // TODO other IDX categories
};

// do not just assign entire array, because we want to
// add src_status just to sources (below)
Ext.each(AIR2.Search.Advanced.Fields.sources, function (item, idx, arr) {
    AIR2.Search.Advanced.Fields['active-sources'].push(item);
});

// alias
AIR2.Search.Advanced.Fields.activesources =
    AIR2.Search.Advanced.Fields['active-sources'];
AIR2.Search.Advanced.Fields['primary-sources'] =
    AIR2.Search.Advanced.Fields['active-sources'];
AIR2.Search.Advanced.Fields.primarysources =
    AIR2.Search.Advanced.Fields['primary-sources'];

// strict versions
AIR2.Search.Advanced.Fields['strict-active-sources'] =
    AIR2.Search.Advanced.Fields['active-sources'];
AIR2.Search.Advanced.Fields['strict-primary-sources'] =
    AIR2.Search.Advanced.Fields['primary-sources'];
AIR2.Search.Advanced.Fields['strict-sources'] =
    AIR2.Search.Advanced.Fields.sources;

// status only relevant when searching all sources
AIR2.Search.Advanced.Fields.sources.push(
    {
        name: 'src_status',
        type: 'auto',
        label: 'Status',
        list: function () {
            return [
                ['a OR e OR t', 'Active'],
                ['d', 'Deactivated'],
                ['e', 'Enrolled'],
                ['f', 'Opted Out'],
                ['u', 'Unsubscribed']
            ];
        }
    }
);

AIR2.Search.Advanced.RemoveButton = function () {

    var b = new AIR2.UI.Button({
        air2type: 'CANCEL',
        text: 'Remove rule',
        iconCls: 'air2-icon-remove',
        handler : function (btn, ev) {
            var anyAll, panel, thisClause;

            thisClause = btn.findParentBy(function (cmp) {
                //Logger(cmp);
                if (cmp.isaClause) {
                    return true;
                }
            });
            //Logger("remove clause: ", thisClause);
            if (thisClause) {
                //Logger("looking for clause panel parent");
                panel = btn.findParentBy(function (cmp) {
                    if (
                        cmp.isaClause && cmp.id !== thisClause.id ||
                        cmp.id === AIR2.Search.Advanced.FORMID
                    ) {
                        return true;
                    }
                    //Logger(cmp);
                    //else if (cmp
                });
                if (panel) {
                    if (panel.isaClause) {
                        //Logger("parent panel: ", panel);
                        panel.remove(thisClause);
                        if (panel.items.getCount() === 5) {
                            anyAll = panel.find('isaAnyAll', true);
                            //Logger(anyAll);
                            panel.remove(anyAll[0]);
                        }
                    }
                    else {
                        panel.remove(thisClause);
                    }
                }
            }

            AIR2.Search.Advanced.Explain();
            AIR2.Search.Advanced.getTermCountTask.delay(50);

        },
        listeners : {
            'beforedestroy' : function (thisBox) {
                //Logger('destroyed button', thisBox);
                //return false;
            }
        }
    });

    return b;
};

AIR2.Search.Advanced.getFieldStore = function () {
    var fields, fieldData, fieldStore;

    if (Ext.isDefined(AIR2.Search.Advanced.FIELDS)) {
        return AIR2.Search.Advanced.FIELDS;
    }

    fields = AIR2.Search.Advanced.Fields[AIR2.Search.IDX];

    // mix in labels
    Ext.each(fields, function (item, idx, fieldList) {
        if (!item) {
            //Logger("no item at idx " + idx);
        }
        if (Ext.isDefined(item.label)) {
            //Logger("Label defined for " + item.label);
            return true;
        }
        if (Ext.isDefined(AIR2.Fixtures.FieldLabels[item.name])) {
            item.label = AIR2.Fixtures.FieldLabels[item.name];
            //Logger("FieldLabels defined for " + item.name);
        }
        else {
            item.label = item.name;
            //Logger("defaulting to " + item.name);
        }
        //Logger("item " + item.name + " set to " + item.label);
    });

    fieldData = [['', 'Any field', 'string']];
    Ext.each(fields, function (item, idx, fieldDefs) {
        fieldData.push([
            item.name,
            item.label,
            item.type,
            (item.list || null),
            (item.sortBy || null),
            (item.defValue || null),
            (item.group || '')
        ]);
    });
    
    fieldStore = new Ext.data.GroupingStore({
        reader: new Ext.data.ArrayReader({}, [
            { name: 'name' },
            { name: 'label' },
            { name: 'type' },
            { name: 'list' },
            { name: 'sortBy' },
            { name: 'defValue' },
            { name: 'group' }
        ]),
        data: fieldData,
        sortInfo: { field: 'label', direction: 'ASC' },
        groupField: 'group'
    });

    AIR2.Search.Advanced.FIELDS = fieldStore;     //cache

    return fieldStore;
};

AIR2.Search.Advanced.Explain = function () {
    var dialect, qlen, searchBtn;

    dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
    dialect.getEl().dom.innerHTML = "<strong>Your search:</strong> " +
        dialect.stringify();
    qlen = dialect.stringify().length;
    searchBtn = Ext.getCmp('air2-adv-search-button');
    if (searchBtn.disabled) {
        if (qlen) {
            searchBtn.enable();
        }
        else {
            searchBtn.disable();
        }
    }
    else if (!qlen) {
        searchBtn.disable();
    }

};

AIR2.Search.Advanced.getTermCount = function () {
    var dialect, div, masterBool, query;

    if (AIR2.Search.Advanced.COUNT_IN_PROGRESS) {
        //Logger('count in progress');
        //return;
    }

    div = Ext.get('adv-search-counter');
    div.dom.innerHTML = AIR2.Search.SPINNER_IMG;
    dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
    query  = dialect.stringify();
    if (!query.length) {
        div.dom.innerHTML = 0;
        return;
    }

    masterBool = Ext.getCmp(AIR2.Search.Advanced.BOOLEAN).getValue();
    AIR2.Search.Advanced.COUNT_IN_PROGRESS = true;

    AIR2.Search.getCount({
        callback: function (json) {
            //Logger("got count");
            AIR2.Search.Advanced.COUNT_IN_PROGRESS = false;
        },
        elId: 'adv-search-counter',
        hideErrors: true,
        url: AIR2.Search.URL + '.json?' +
            Ext.urlEncode({q: query, i: AIR2.Search.IDX, b: masterBool})
    });
};

AIR2.Search.Advanced.getTermCountTask = new Ext.util.DelayedTask(function () {
    AIR2.Search.Advanced.getTermCount();
});

AIR2.Search.Advanced.newClause = function (isFirst) {
    var boolPicker,
        fieldPicker,
        fieldStore,
        items,
        opList,
        query,
        removeButton,
        textField;

    removeButton = AIR2.Search.Advanced.RemoveButton();
    if (isFirst) {
        removeButton.disable();
    }
    opList = AIR2.Search.Advanced.StringOpList();
    textField = AIR2.Search.Advanced.TextField();
    fieldStore = AIR2.Search.Advanced.getFieldStore();
    fieldPicker = new Search.Query.FieldPicker({
        store: fieldStore,
        groupTextTpl: '<b class="air2-advsearch-group">{text}</b>&nbsp;&#187;',
        showGroupName: false,
        startCollapsed: true,
        displayField: 'label',
        hiddenName: 'name',
        mode: 'local',
        triggerAction: 'all',
        editable: false,
        width: 250,
        value: 'Any field',
        onReset: function () {
            var clause, tf;

            // check if we have a combobox as our 3rd item
            // and restore it to a textfield if necessary.
            clause = this.parentClause;
            if (!clause.getValueField().isaAdvTextField) {
                clause.remove(clause.getValueField());
                tf = AIR2.Search.Advanced.TextField();
                tf.parentClause = clause;
                clause.insert(3, tf);
                clause.doLayout();
            }
        }
    });
    boolPicker = new AIR2.UI.ComboBox({
        store: [
            ['AND', 'AND'],
            ['OR', 'OR']
            //,['NOT','NOT']    // too confusing for users
        ],
        width: 50,
        value: 'AND',
        triggerAction: 'all',
        selectOnFocus: true,
        getBoolean : function () {
            var val = this.getValue();
            //Logger("boolean === ", val);
            return val.toLowerCase();
        },
        listeners: {
            'select' : function (thisBox, rec, idx) {
                var clause, prevValue, v;

                v = thisBox.getBoolean();

                clause = thisBox.parentClause;
                prevValue = clause.bool;
                clause.removeFromDialect(prevValue);
                clause.addToDialect(v);
                clause.bool = v;
                AIR2.Search.Advanced.Explain();
                //Logger("clause bool set=="+v);
            }
        }
    });
    items = [];
    items.push(fieldPicker);
    items.push(opList);
    items.push(textField);
    items.push('->');
    items.push(removeButton);

    query = new Search.Query.Clause({
        items: items,
        explainer : function (clause) {
            var div;

            //Logger("explainer:", clause);
            //Logger(clause.toJson());
            if (!Ext.isDefined(clause)) {
                throw new Ext.Error("clause required");
            }

            div = Ext.get('adv-search-counter');
            div.dom.innerHTML = AIR2.Search.SPINNER_IMG;

            // show query
            AIR2.Search.Advanced.Explain();

            // get count
            if (!Ext.isDefined(clause.value) ||
                (!Ext.isObject(clause.value) && !clause.value.length)
            ) {
                //Logger("no value in clause:", clause);
                div.dom.innerHTML = 0;
                return;
            }
            AIR2.Search.Advanced.getTermCountTask.delay(1000);
        },

        getFieldPicker : function () {
            return this.get(0);
        },

        getOpList : function () {
            return this.get(1);
        },

        getValueField : function () {
            return this.get(2);
        },

        getRmButton : function () {
            return this.items.last();
        },

        getFieldFromValue : function (fieldValue) {
            var field;
            //Logger(fieldValue);
            fieldStore.each( function (item) {
                //Logger(item);
                if (item.get('label') === fieldValue) {
                    field = item.json;
                    return false;
                }
            });
            //Logger('field=', field);
            if (!field) {
                //Logger("No such field: ", fieldValue);
                return;
            }
            return field;
        },

        onFieldChange : function (fieldValue) {
            var field,
                fieldType,
                self,
                valuePicker;
                
            self = this;

            // always reset if changing field, since opList will reset
            self.setOp('=');

            // find fieldValue in store and change textField if necessary
            //Logger(fieldStore);
            field = self.getFieldFromValue(fieldValue);
            
            if (!field) {
                return;
            }
            
            // assign field name so stringify() works
            self.field = field[0];
            
            // determine picker based on type
            fieldType = field[2];
            valuePicker = self.getValueField();
            if (fieldType === "auto") {
                if (valuePicker.isaAdvTextField) {

                    // change to a picklist
                    self.convertToPickList(field[3], field[4]);
                }
                else if (valuePicker.isaRangeField) {

                    // change to a picklist
                    self.convertToPickList(field[3], field[4]);

                }
                else if (valuePicker.isaNumberField) {

                    self.convertToPickList(field[3], field[4]);
                }
                else if (valuePicker.isaPickList) {

                    // change the picklist.
                    // easiest to cheat and switch it to a text field first.
                    self.convertToTextField();
                    self.convertToPickList(field[3], field[4]);

                }
            }
            else if (fieldType === "string") {
                return self.convertToTextField();
            }
            else if (fieldType === "date") {
                return self.convertToDateField();
            }
            else if (fieldType === "int") {
                return self.convertToNumberField();
            }
            else if (fieldType === "form") {
                return self.convertToFormPicker();
            }
            else if (fieldType === "activity") {
                return self.convertToActivityField(field);
            }
            else {
                Logger("unknown fieldType:", fieldType);
            }

        },
        swapValueField : function (newVal) {
            this.remove(this.getValueField());
            this.insert(2, newVal);
        },
        swapOpList : function (newList) {
            this.remove(this.getOpList());
            this.insert(1, newList);
        },
        convertToFormPicker : function () {
            var fp,
                fPanel,
                picker,
                thisIdx;

            //Logger("clause -> formPicker");

            fp = new Ext.Panel({
                frame: false,
                border: false,
                isaClause: true,    // cheat for rmButton
                layout: 'column',
                bodyStyle: 'padding-top:3px',
                items: [
                    {
                        columnWidth: 0.80,
                        border: false,
                        frame: false,
                        items: [
                            new Ext.Panel({
                                frame       : false,
                                border      : false,
                                layout      : 'form',
                                labelAlign  : 'right',
                                style       : 'padding:4px',
                                labelWidth  : 60
                            })
                        ]
                    },
                    {
                        columnWidth: 0.20,
                        frame: false,
                        border: false,
                        bodyStyle:
                            'padding:0;padding-top:3px;' +
                            'padding-right:8px;text-align:right',
                        items: [
                            AIR2.Search.Advanced.RemoveButton()
                        ]
                    }
                ],
                disableRmButton : function () {
                    this.get(1).get(0).disable();
                },
                enableRmButton : function () {
                    this.get(1).get(0).enable();
                },
                setItemAt : function (item, at) {
                    var f, fItems, items;

                    fItems = this.get(0).get(0).items;
                    f = this.get(0).get(0);
                    if (fItems.get(at)) {
                        items = fItems.getRange(at);
                        //Logger("remove:",items);
                        Ext.each(items, function (i, idx, arr) {
                            //Logger("removeAt",at+idx);
                            f.remove(i);
                        });
                    }
                    f.insert(at, item);
                },
                resetItemAt : function (at) {
                    var clearBtn, f, fItems, items;

                    fItems = this.get(0).get(0).items;
                    f = this.get(0).get(0);
                    if (fItems.get(at)) {
                        items = fItems.getRange(at);
                        //Logger("remove:",items);
                        Ext.each(items, function (i, idx, arr) {
                            //Logger("removeAt",at+idx);
                            f.remove(i);
                        });
                        // if it was the last item, init a fresh one
                        if (at === 0) {
                            clearBtn = Ext.getCmp('adv-search-clear-button');
                            clearBtn.handler(clearBtn);
                        }
                    }
                },
                resetProjectPicker : function () {

                    // same as clicking remove button
                    var rmBtn = this.get(1).get(0);
                    rmBtn.handler(rmBtn);
                },
                resetInquiryPicker : function () {
                    this.resetItemAt(1);
                    while (this.clause.value.and.length > 1) {
                        this.clause.value.and.pop();
                    }
                },
                resetQuestionPicker : function () {
                    this.resetItemAt(2);
                    while (this.clause.value.and.length > 2) {
                        this.clause.value.and.pop();
                    }
                },
                resetAnswerPicker : function () {
                    this.resetItemAt(3);
                    while (this.clause.value.and.length > 3) {
                        this.clause.value.and.pop();
                    }
                },
                setInquiryPicker : function (iP) {
                    this.setItemAt(iP, 1);
                },
                setQuestionPicker : function (qP) {
                    this.setItemAt(qP, 2);
                },
                setAnswerPicker : function (aP) {
                    this.setItemAt(aP, 3);
                },
                stringify : function () {
                    //Logger("stringify formpicker");
                    return this.clause.stringify();
                },
                setProjectQuery : function (v) {
                    var c, d;

                    d = this.clause.value;
                    //Logger("clause.value=", d);
                    if (!Ext.isDefined(d) || !Ext.isObject(d)) {
                        d = new Search.Query.Dialect({});    // make it a tree
                        this.clause.value = d;
                    }
                    c = new Search.Query.Clause({});
                    c.field = 'project';
                    c.value = '"' + v + '"';
                    c.op    = '=';
                    d.and = [];  // reset no matter what
                    d.and.push(c);
                },
                setInquiryQuery : function (v) {
                    var c, d;

                    d = this.clause.value;
                    c = new Search.Query.Clause({});
                    c.field = 'query';
                    c.value = v;
                    c.op    = '=';
                    while (d.and.length > 1) {
                        d.and.pop();
                    }
                    d.and.push(c);
                },
                setQuestionQuery : function (v) {
                    var c, d;

                    d = this.clause.value;
                    c = new Search.Query.Clause({});
                    c.field = 'qa';
                    c.value = v;
                    c.op    = '=';
                    while (d.and.length > 2) {
                        d.and.pop();
                    }
                    d.and.push(c);
                },
                setAnswerQuery : function (v) {
                    var c, d;

                    d = this.clause.value;
                    c = new Search.Query.Clause({});
                    c.field = 'qa';
                    //Logger("answerQuery:", d);
                    c.value = '"' + v + '"';   // TODO this is broken??
                    c.op    = '=';
                    while (d.and.length > 3) {
                        d.and.pop();
                    }
                    d.and.push(c);
                },
                setAnswerFullTextQuery : function (v) {
                    var c, d;

                    d = this.clause.value;
                    c = new Search.Query.Clause({});
                    c.field = 'qa';
                    c.value = '"' + v + '"';   // TODO this is broken??
                    c.op    = '=';
                    while (d.and.length > 3) {
                        d.and.pop();
                    }
                    d.and.push(c);
                },
                setValue : function (v) {
                    this.setAnswerQuery(v);
                },
                updateDisplay : function () {
                    this.clause.updateDisplay();
                }
            });
            picker = AIR2.Search.Inquiry.ChainedPicker(fp);
            fPanel = Ext.getCmp(AIR2.Search.Advanced.FORMID);
            fp.get(0).get(0).add(picker);
            fp.clause = this;  //delegate to this for query generation

            // replace this clause with picker
            this.removeAll();   // kill kids first
            thisIdx = fPanel.items.indexOf(this);
            fPanel.remove(this);    // removes from Dialect
            fp.clause.addToDialect(this.bool);   // add back to Dialect
            fp.clause.value = new Search.Query.Dialect({});    // make it a tree
            fPanel.insert(thisIdx, fp);
            fPanel.doLayout();

        },
        convertToRange : function () {
            var f, opList;

            //Logger("convertToRange");
            f = AIR2.Search.Advanced.RangeField();
            f.parentClause = this;
            opList = AIR2.Search.Advanced.RangeOpList();
            opList.parentClause = this;
            this.swapValueField(f);
            this.swapOpList(opList);
            this.doLayout();
        },
        convertToDateField : function () {
            var f, opList;

            //Logger("convertToDateField");
            f = AIR2.Search.Advanced.DateRangeField();
            f.parentClause = this;
            opList = AIR2.Search.Advanced.RangeOpList();
            opList.parentClause = this;
            this.setOp('..');  // always a range
            this.swapValueField(f);
            this.swapOpList(opList);
            this.doLayout();
        },
        convertToNumberField : function () {
            var f, OpList;

            //Logger("convertToNumberField");
            f = AIR2.Search.Advanced.NumberField();
            f.parentClause = this;
            opList = AIR2.Search.Advanced.OpList();
            opList.parentClause = this;
            this.swapValueField(f);
            this.swapOpList(opList);
            this.doLayout();
        },
        convertToTextField : function () {
            var f, opList;

            //Logger("convertToTextField");
            f = AIR2.Search.Advanced.TextField();
            f.parentClause = this;
            opList = AIR2.Search.Advanced.StringOpList();
            opList.parentClause = this;
            this.swapValueField(f);
            this.swapOpList(opList);
            this.doLayout();
        },
        convertToActivityField : function (spec) {
            var dayPicker,
                days,
                def,
                hiddenField,
                initialVal,
                key,
                now,
                then,
                updateVisual;

            def  = (spec[5] || 7) + ''; // force string
            key  = spec[0];
            days = def + ' days';
            then = AIR2.Search.NDaysAgo(def);
            now  = new Date();
            initialVal = "( " + then.format('Ymd') + '..' + now.format('Ymd');
            initialVal += ' )';
            if (key === "not_queried") {
                this.field = 'last_queried_date';
                this.op    = '!=';
            }
            else if (key === "no_activity") {
                this.field = 'last_activity_date';
                this.op    = '!=';
            }
            else if (key === "new_source") {
                this.field = 'src_created_date';
                this.op    = '=';
            }
            else if (key === "resubscribed") {
                this.field = 'activity_type_date';
                this.op    = '=';
                this.actm_id = 21;
                initialVal = "(21" + then.format('Ymd') + '..21';
                initialVal += now.format('Ymd') + ')';
            }
            else if (key === "unsubscribed") {
                this.field = 'activity_type_date';
                this.op    = '=';
                this.actm_id = 22;
                initialVal = "(22" + then.format('Ymd') + '..22';
                initialVal += now.format('Ymd') + ')';
            }
            else if (key === "deactivated") {
                this.field = 'activity_type_date';
                this.op    = '=';
                this.actm_id = 38;
                initialVal = "(38" + then.format('Ymd') + '..38';
                initialVal += now.format('Ymd') + ')';
            }
            else if (key === "reactivated") {
                this.field = 'activity_type_date';
                this.op    = '=';
                this.actm_id = 39;
                initialVal = "(39" + then.format('Ymd') + '..39';
                initialVal += now.format('Ymd') + ')';
            }
            else {
                this.field = 'NOSUCHFIELD';
            }
            dayPicker = new AIR2.UI.ComboBox({
                store: [
                    [7, '7 days'],
                    [15, '15 days'],
                    [30, '30 days'],
                    [60, '60 days'],
                    [90, '90 days']
                ],
                value: days,
                width: 100,
                triggerAction: 'all',
                selectOnFocus: true,
                isaDayPicker: true,
                forceSelection: false,  // can manually enter days
                listeners: {
                    'select' : function (thisBox, ev) {
                        var now, then, v;

                        //Logger(thisBox, "changed: ",
                        // thisBox.getValue());
                        // quote the value, unless it is already
                        // correctly escaped.
                        v = thisBox.getValue() + ''; // force string context
                        then = AIR2.Search.NDaysAgo(v);
                        now  = new Date();
                        if (thisBox.parentClause.actm_id) {
                            thisBox.parentClause.value = "(" +
                                thisBox.parentClause.actm_id +
                                then.format('Ymd') + '..' +
                                thisBox.parentClause.actm_id +
                                now.format('Ymd') + ')';
                        }
                        else {
                            thisBox.parentClause.value = "( " +
                                then.format('Ymd') + '..' + now.format('Ymd') +
                                ' )';
                        }
                        thisBox.parentClause.updateDisplay();
                    }
                }
            });
            dayPicker.parentClause = this;

            // placeholder since we only have 2 visible components
            hiddenField = AIR2.Search.Advanced.TextField(initialVal);
            hiddenField.parentClause = this;
            hiddenField.hide();
            this.swapValueField(hiddenField);
            this.swapOpList(dayPicker);
            this.doLayout();

            // this closure will fire after the entire clause is switched,
            // to trigger immediate count+explainer, since we do not have a
            // 3rd component.
            updateVisual = function () {
                hiddenField.parentClause.value = initialVal;
                hiddenField.parentClause.updateDisplay();
            };
            return updateVisual;
        },
        convertToPickList : function (array, sortBy) {
            var listStore, opList, pickList;

            if (Ext.isArray(array)) {
                listStore = array;
            }
            else if (Ext.isFunction(array)) {
                listStore = array();
            }
            else {
                //Logger(array);
                throw new Ext.Error("Unknown data store: ", array);
            }
           //Logger("convertToPickList:", listStore);
            Ext.each(listStore, function (subArray, index) {
                subArray[1] = AIR2.Format.householdIncome(subArray[1]);
            });
            pickList = new AIR2.UI.ComboBox({
                store: listStore,
                width: 200,
                triggerAction: 'all',
                selectOnFocus: true,
                isaPickList: true,
                forceSelection: true,
                editable: true,
                typeAhead: true,
                listeners : {
                    'beforedestroy' : function (thisBox) {
                        //Logger('destroyed opList');
                        //return false;
                    },
                    'select' : function (thisBox, ev) {
                        //Logger(thisBox, "changed: ", thisBox.getValue());
                        // quote the value, unless it is already correctly
                        // escaped.
                        var v = thisBox.getValue();
                        if (v === "NULL") { // keyword
                            thisBox.parentClause.value = v;
                        }
                        else if (v.match(/ (OR|NOT|AND) /)) {
                            thisBox.parentClause.value = v;
                        }
                        else if (v.match(/\(/)) {
                            thisBox.parentClause.value = v;
                        }
                        else {
                            thisBox.parentClause.value = '"' + v + '"';
                        }
                        thisBox.parentClause.updateDisplay();
                    }
                }
            });
            pickList.parentClause = this;
            // only = and !== are valid
            opList = AIR2.Search.Advanced.ListOpList();
            opList.parentClause = this;
            this.remove(this.getOpList());
            this.insert(1, opList);
            this.remove(this.getValueField());
            this.insert(2, pickList);
            this.doLayout();
        },
        onOpChange : function (opValue) {
            var field, fieldPicker, fieldType, fieldValue, valuePicker;

            fieldValue = this.getFieldPicker().getValue();
            field = this.getFieldFromValue(fieldValue);
            if (!field) {
                return;
            }
            fieldType = field[2];
            valuePicker = this.getValueField();

            //Logger("opValue change:", opValue);
            //Logger("field:", field);
            //Logger("opValue fieldType:", fieldType);
            //Logger("valuePicker:", valuePicker);

            // range picker needed?
            if (opValue === ".." || opValue === "!..") {
                if (
                    valuePicker.isaAdvTextField ||
                    valuePicker.isaNumberField
                ) {
                    this.convertToRange(field[3], field[4]);

                }
            }
            else if (opValue === '=' || opValue === '!=') {

                if (valuePicker.isaRangeField && fieldType === 'string') {
                    this.convertToTextField();
                }
                else if (valuePicker.isaRangeField && fieldType === 'int') {
                    this.convertToNumberField();
                }
            }
        },
        onValueChange : function (newVal) {
            var vf = this.getValueField();
            //Logger('onValueChange: "' + newVal + '"', vf);
            if (!Ext.isDefined(vf) || !vf.setValue) {
                return;
            }
            vf.setValue(newVal);
        },
        removeFromDialect : function (bool) {
            var clause, clauses, dialect, i;

            clause = this;
            dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
            clauses = [];
            for (i = 0; i < dialect[bool].length; i++) {
                if (dialect[bool][i].id === clause.id) {
                    continue;
                }
                clauses.push(dialect[bool][i]);
            }
            dialect[bool] = clauses;
            //Logger("dialect removed clause for bool=="+bool);
            //Logger(dialect);
        },
        addToDialect : function (bool) {
            var clause, dialect;

            clause = this;
            dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
            dialect[bool].push(clause);
            //Logger("dialect added clause for bool=="+bool);
            //Logger(dialect);
        },
        listeners : {
            'afterrender' : function (clause) {
                var bool = boolPicker.getBoolean();
                clause.addToDialect(bool);
                //Logger("add clause to dialect:", clause);
                clause.bool = bool;
            },
            'beforedestroy': function (clause) {
                var bool = boolPicker.getBoolean();
                clause.removeFromDialect(bool);
                //Logger("remove clause from dialect:",clause);
                return true; // proceed with destroy
            }
        },

        enableRmButton : function () {
            this.getRmButton().enable();
        },
        disableRmButton : function () {
            this.getRmButton().disable();
        }
    });
    
    Logger('query.field = ', query.field);
    
    return query;
};

AIR2.Search.Advanced.toggleRmButtons = function (sform) {
    //Logger(sform);
    var clauses = sform.getClauses();
    if (clauses.length === 1) {
        clauses[0].disableRmButton();
        return;
    }
    Ext.each(clauses, function (item, idx, len) {
        item.enableRmButton();
    });

};

AIR2.Search.Advanced.OpList = function () {

    var opList = new AIR2.UI.ComboBox({
        value : 'contains',
        width : 120,
        store : [
            ['=',  'contains'],
            ['!=', 'does not contain'],
            ['..', 'includes'],
            ['!..', 'excludes']
        ],
        cls   : 'adv-search-ops',
        border: false,
        forceSelection: true,
        triggerAction: 'all',
        selectOnFocus: true,
        listeners : {
            'select' : function (thisBox, ev) {
                var v = thisBox.getValue();
                //Logger(thisBox, "changed: ", v);
                thisBox.parentClause.setOp(v);
                thisBox.parentClause.updateDisplay();
            }

        }
    });
    return opList;

};

AIR2.Search.Advanced.StringOpList = function () {

    var opList = new AIR2.UI.ComboBox({
        value : 'contains',
        width : 120,
        store : [
            ['=',  'contains'],
            ['!=', 'does not contain']
        ],
        cls   : 'adv-search-ops',
        border: false,
        forceSelection: true,
        triggerAction: 'all',
        selectOnFocus: true,
        listeners : {
            'select' : function (thisBox, ev) {
                var v = thisBox.getValue();
                //Logger(thisBox, "changed: ", v);
                thisBox.parentClause.setOp(v);
                thisBox.parentClause.updateDisplay();
            }

        }
    });
    return opList;

};

AIR2.Search.Advanced.RangeOpList = function () {

    var opList = new AIR2.UI.ComboBox({
        value : 'includes',
        width : 120,
        store : [
            ['..', 'includes'],
            ['!..', 'excludes']
        ],
        cls   : 'adv-search-ops',
        border: false,
        forceSelection: true,
        triggerAction: 'all',
        selectOnFocus: true,
        listeners : {
            'select' : function (thisBox, ev) {
                var v = thisBox.getValue();
                //Logger(thisBox, "changed: ", v);
                thisBox.parentClause.setOp(v);
                thisBox.parentClause.updateDisplay();
            }

        }
    });
    return opList;

};

AIR2.Search.Advanced.ListOpList = function () {

    var opList = new AIR2.UI.ComboBox({
        value : 'is',
        width : 120,
        store : [
            ['=',  'is'],
            ['!=', 'is not']
        ],
        cls   : 'adv-search-ops',
        border: false,
        forceSelection: true,
        triggerAction: 'all',
        selectOnFocus: true,
        listeners : {
            'select' : function (thisBox, ev) {
                var v = thisBox.getValue();
                //Logger(thisBox, "changed: ", v);
                thisBox.parentClause.setOp(v);
                thisBox.parentClause.updateDisplay();
            }

        }
    });
    return opList;

};

AIR2.Search.Advanced.TextField = function (v) {

    var textField = new Ext.form.TextField({
        value : (v || ""),
        cls   : 'adv-search-textfield',
        border: false,
        enableKeyEvents: true,
        width: 450,
        isaAdvTextField : true,
        listeners : {
            'beforedestroy' : function (thisBox) {
                //Logger('destroyed textField');
                //return false;
            },
            'keyup' : function (thisBox, ev) {
                //Logger(thisBox, "changed: ", thisBox.getValue());
                //Logger("key==", ev.getKey());

                // trac #1949 --
                // set value attribute rather than using setValue()
                thisBox.parentClause.value = thisBox.getValue();
                thisBox.parentClause.updateDisplay();
            }
        },
        tryQuery : function () {
            //Logger('fire query');

        }
    });

    textField.on('specialkey', function (thisField, e) {
        if (e.getKey() === e.ENTER) {
            thisField.tryQuery();
            e.stopEvent();
            e.stopPropagation();
        }
    });

    return textField;

};

AIR2.Search.Advanced.NumberField = function () {

    var textField = new Ext.form.TextField({
        value : '',
        vtype : 'Integer',
        cls   : 'adv-search-textfield',
        border: false,
        enableKeyEvents: true,
        width: 350,
        isaNumberField : true,
        listeners : {
            'keyup' : function (thisBox, ev) {
                //Logger(thisBox, "changed: ", thisBox.getValue());
                thisBox.parentClause.value = thisBox.getValue();
                thisBox.parentClause.updateDisplay();
            }
        },
        tryQuery : function () {
            //Logger('fire query');

        }
    });

    textField.on('specialkey', function (thisField, e) {
        if (e.getKey() === e.ENTER) {
            thisField.tryQuery();
            e.stopEvent();
            e.stopPropagation();
        }
    });

    return textField;

};

AIR2.Search.Advanced.RangeField = function () {

    var rangeField;
    rangeField = new Ext.form.CompositeField({
        value : [],
        cls   : 'adv-search-rangefield',
        border: false,
        enableKeyEvents: true,
        width: 380,
        isaRangeField : true,
        items: [
            new Ext.form.Label({
                text: 'Min',
                style: 'padding: 4px'
            }),
            new Ext.form.TextField({
                width: 140,
                vtype: 'Integer',
                enableKeyEvents: true,
                validator : function (curVal) {
                    if (Ext.isDefined(rangeField.parentClause.value[1])) {
                        //Logger("Min is defined");
                        if (
                            parseInt(rangeField.parentClause.value[1], 10) <=
                            parseInt(curVal, 10)
                        ) {
                            return "Value must be greater than " +
                                rangeField.parentClause.value[0];
                        }
                        else if (
                            rangeField.parentClause.value[1].length !==
                            curVal.length
                        ) {
                            return "Must be same length as " +
                                rangeField.parentClause.value[0];
                        }
                    }
                    return true;
                },
                listeners: {
                    'keyup': function (thisField, e) {
                        //Logger("min:", thisField.getValue());
                        if (rangeField.parentClause.value === "") {
                            rangeField.parentClause.value = [];
                        }
                        rangeField.parentClause.value[0] = thisField.getValue();
                        rangeField.parentClause.updateDisplay();
                    }
                }
            }),
            new Ext.form.Label({
                text: '.. Max',
                style: 'padding: 4px'

            }),
            new Ext.form.TextField({
                width: 140,
                vtype: 'Integer',
                enableKeyEvents: true,
                validator : function (curVal) {
                    if (Ext.isDefined(rangeField.parentClause.value[0])) {
                        //Logger("Max is defined");
                        if (
                            parseInt(rangeField.parentClause.value[0], 10) >=
                            parseInt(curVal, 10)
                        ) {
                            return "Value must be greater than " +
                                rangeField.parentClause.value[0];
                        }
                        else if (
                            rangeField.parentClause.value[0].length !==
                            curVal.length
                        ) {
                            return "Must be same length as " +
                                rangeField.parentClause.value[0];
                        }
                    }
                    return true;
                },
                listeners: {
                    'keyup': function (thisField, e) {
                        //Logger("max:", thisField.getValue());
                        if (rangeField.parentClause.value === "") {
                            rangeField.parentClause.value = [];
                        }
                        rangeField.parentClause.value[1] = thisField.getValue();
                        rangeField.parentClause.updateDisplay();
                    }
                }
            })
        ],
        tryQuery : function () {
            //Logger('fire query');
            this.items.each(function (item, idx, len) {
                //Logger('tryQuery each: ', item.getValue());
            });
        }
    });

    rangeField.on('specialkey', function (thisField, e) {
        if (e.getKey() === e.ENTER) {
            thisField.tryQuery();
            e.stopEvent();
            e.stopPropagation();
        }
    });

    return rangeField;

};

AIR2.Search.Advanced.DateRangeField = function () {

    var rangeField;
    rangeField = new Ext.form.CompositeField({
        value : [],
        cls   : 'adv-search-daterangefield',
        border: false,
        enableKeyEvents: true,
        width: 380,
        isaRangeField : true,
        items: [
            new Ext.form.Label({
                text: 'Start',
                style: 'padding: 4px'
            }),
            new Ext.form.DateField({
                width: 140,
                format: 'Ymd',
                enableKeyEvents: true,
                updateDialect : function (thisField) {
                    if (rangeField.parentClause.value === "") {
                        rangeField.parentClause.value = [];
                    }
                    rangeField.parentClause.value[0] =
                        thisField.getValue().format('Ymd');
                    rangeField.parentClause.updateDisplay();
                },
                listeners: {
                    'select': function (thisField, e) {
                        //Logger("start:", thisField.getValue().format('Ymd'));
                        thisField.updateDialect(thisField);
                    },
                    'keyup': function (thisField, e) {
                        //Logger("start:", thisField.getValue().format('Ymd'));
                        thisField.updateDialect(thisField);
                    }
                }
            }),
            new Ext.form.Label({
                text: '.. End',
                style: 'padding: 4px'

            }),
            new Ext.form.DateField({
                width: 140,
                format: 'Ymd',
                enableKeyEvents: true,
                // TODO validator
                updateDialect : function (thisField) {
                    if (rangeField.parentClause.value === "") {
                        rangeField.parentClause.value = [];
                    }
                    rangeField.parentClause.value[1] =
                        thisField.getValue().format('Ymd');
                    rangeField.parentClause.updateDisplay();
                },
                listeners: {
                    'select': function (thisField, e) {
                        //Logger("end:", thisField.getValue().format('Ymd'));
                        thisField.updateDialect(thisField);
                    },
                    'keyup': function (thisField, e) {
                        //Logger("end:", thisField.getValue().format('Ymd'));
                        thisField.updateDialect(thisField);
                    }
                }
            })
        ],
        tryQuery : function () {
            //Logger('fire query');
            this.items.each(function (item, idx, len) {
                //Logger(item.getValue());
            });
        }
    });

    rangeField.on('specialkey', function (thisField, e) {
        if (e.getKey() === e.ENTER) {
            thisField.tryQuery();
            e.stopEvent();
            e.stopPropagation();
        }
    });

    return rangeField;
};

AIR2.Search.Advanced.Panel = function (cfg) {
    var boolPicker, dialect, footer, panel, sform;

    boolPicker = new AIR2.UI.ComboBox({
        store: [
            ['AND', 'AND'], ['OR', 'OR']
        ],
        width: 50,
        value: 'AND',
        id: AIR2.Search.Advanced.BOOLEAN,
        triggerAction: 'all',
        selectOnFocus: true,
        getBoolean : function () {
            var val = this.getValue();
            //Logger("boolean === ", val);
            return val.toLowerCase();
        },
        listeners: {
            'select' : function (thisBox, rec, idx) {
                var dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
                dialect.default_bool = this.getValue();
                dialect.op_map.and = ' ' + this.getValue() + ' ';    // HACK!!
                AIR2.Search.Advanced.Explain();
                AIR2.Search.Advanced.getTermCountTask.delay(1000);
            }
        }
    });

    footer = new Ext.Toolbar({
        cls: "adv-search-clear",
        items: [
            {
                text: 'Search',
                disabled: true, // until a query is created
                xtype: 'air2button',
                id: 'air2-adv-search-button',
                iconClass: 'air2-icon-search',
                air2type: 'BLUE',
                handler: function (btn, ev) {
                    var dialect, masterBool, query, uri;

                    dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
                    query = dialect.stringify();
                    //Logger("adv query="+query);
                    masterBool =
                        Ext.getCmp(AIR2.Search.Advanced.BOOLEAN).getValue();
                    uri = AIR2.Search.URL + '/' + AIR2.Search.IDX + '?';
                    uri += Ext.urlEncode({q: query, b: masterBool});
                    //Logger('uri:', uri);
                    window.location = uri;
                }
            },
            '->',
            {
                id: 'adv-search-clear-button',
                xtype: 'air2button',
                iconClass: 'air2-icon-clear',
                air2type: 'GRAY',
                text: 'Remove all rules',
                handler: function (btn, ev) {
                    var clauses, dialect, parentForm;

                    // clear global dialect object --
                    // IMPORTANT to do this before FORMID
                    dialect = Ext.getCmp(AIR2.Search.Advanced.EXPLAIN);
                    //Logger("dialect before clear():" + dialect, dialect);
                    dialect.clear();
                    //Logger("dialect after clear():" + dialect, dialect);

                    // get parent, delete all but first queryclause
                    parentForm = Ext.getCmp(AIR2.Search.Advanced.FORMID);
                    //Logger(parentForm);
                    clauses = parentForm.getClauses();
                    Ext.each(clauses, function (item, idx, len) {
                        if (item.isaClause) {
                            parentForm.remove(item);
                        }
                    });
                    // insert one fresh clause
                    parentForm.add(AIR2.Search.Advanced.newClause(true));
                    parentForm.doLayout();

                    AIR2.Search.Advanced.Explain();
                    Ext.get('adv-search-counter').dom.innerHTML = '0';

                }
            }
        ]
    });

    sform = new Ext.form.FormPanel({
        id:         AIR2.Search.Advanced.FORMID,
        xtype:      'form',
        cls:        'adv-search-form',
        border:     false,
        listeners: {
            add : function (thisForm, theClause, idx) {
                //Logger(thisForm);
                //Logger(theClause);
                //Logger("add clause at ",idx);
                if (theClause.isaClause) {
                    AIR2.Search.Advanced.toggleRmButtons(thisForm);
                }
            },
            remove : function (thisForm, theClause) {
                //Logger("rm clause", theClause);
                if (theClause.isaClause) {
                    AIR2.Search.Advanced.toggleRmButtons(thisForm);
                }
            }
        },
        getClauses : function () {
            var c = [];
            this.items.each(function (item) {
                if (item.isaClause) {
                    c.push(item);
                }
            });
            return c;
        },
        addClause: function () {
            var isFirst, newClause;

            isFirst = this.getClauses().length ? false : true;
            //Logger("addClause isFirst=="+isFirst);
            newClause = AIR2.Search.Advanced.newClause(isFirst);
            this.add(newClause);
            this.doLayout();
            return newClause;
        },
        items: [
            {
                xtype: 'toolbar',
                border: false,
                cls:   "adv-search-header",
                items: [
                    {
                        xtype:      'air2button',
                        iconCls:    'air2-icon-add-small',
                        air2type:   'BLUE',
                        text:       'Add rule',
                        id:         'air2-advsearch-add-rule-button',
                        handler: function (btn, ev) {
                            var panel = btn.ownerCt.ownerCt;
                            //Logger(panel);
                            panel.addClause();
                        }
                    },
                    ' ',
                    '-',
                    ' ',
                    'Join rules with:',
                    boolPicker,
                    '->',
                    'Number of results: <span id="adv-search-counter">0</span>'
                ]
            }
        ]
    });

    dialect = new Search.Query.Dialect({
        id: AIR2.Search.Advanced.EXPLAIN,
        html: '<strong>Your search</strong>: ()',
        cls: 'query-explain'
    });

    panel = new Ext.Panel({
        border: false,
        items: [
            sform,
            footer,
            dialect
        ]
    });

    return panel;
};
