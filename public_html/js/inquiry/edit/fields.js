/***********************
 * Query Builder question templates panel
 */
AIR2.Inquiry.Fields = function () {

    var panel,
        panelTemplate,
        setupDragAndDrop;



    panelTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<tpl if="this.displayLogic(values)">' +
                '{[this.breakLogic(xindex, values)]}' +
                // generic
                '<tpl if="display_group == \'generic\'">' +
                    '<span class="air2-qtpl-type generic" ' +
                        'data-air2qtpl="{ques_template}"' +
                        'ext:qtip="{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display_tip"' +
                        ')]}"' +
                    '>' +
                        '{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display"' +
                        ')]}' +
                    '</span>' +
                '</tpl>' +
                // demographics
                '<tpl if="display_group == \'demographic\'">' +
                    '<span class="air2-qtpl-type demographic" ' +
                        'data-air2qtpl="{ques_template}"' +
                        'ext:qtip="{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display_tip"' +
                        ')]}"' +
                    '>' +
                        '{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display"' +
                        ')]}' +
                    '</span>' +
                '</tpl>' +
                // contact info
                '<tpl if="display_group == \'contact\'">' +
                    '<span class="air2-qtpl-type contact" ' +
                        'data-air2qtpl="{ques_template}"' +
                        'ext:qtip="{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display_tip"' +
                        ')]}"' +
                    '>' +
                        '{[AIR2.Inquiry.getLocalizedValue(' +
                            'values, "display"' +
                        ')]}' +
                    '</span>' +
                '</tpl>' +
            '</tpl>' +
        '</tpl>',
        {
            compiled: true,
            breakLogic: function (xindex, values) {
                var currentGroup,
                    tempLastGroup,
                    displayBreak;

                // default, also covers
                //  values.display_group == 'permission'
                displayBreak = '';

                if (xindex === 1) {
                    this.lastGroup = false;
                    displayBreak = '<h4>Generic Fields</h4>';
                }

                currentGroup = values.display_group;
                tempLastGroup = this.lastGroup;

                this.lastGroup = currentGroup;

                if (tempLastGroup && currentGroup != tempLastGroup) {
                    if (currentGroup === 'demographic') {
                        displayBreak = '<h4>Demographic Fields</h4>';
                    } else if (currentGroup === 'contact') {
                        displayBreak = '<h4>Contact Fields</h4>';
                    }
                }
                return displayBreak;
            },
            displayLogic: function (values) {
                var added;

                // always display non-single instance templates
                if (!values.single_instance) {
                    return true;
                }
                added = AIR2.Inquiry.quesStore.find(
                    'ques_template',
                    values.ques_template
                );

                // only display singe instance templates if
                // they haven't been used
                if (values.single_instance && added === -1) {
                    return true;
                }
                else {
                    return false;
                }

                // fall through to true
                return true;
            }
        }
    );

    // create panel
    panel = new AIR2.UI.Panel({
        autoHeight: true,
        cls:          'air2-builder-templates',
        colspan:      1,
        noHeader:     true,
        iconCls:      'air2-icon-field',
        id:           'air2-inquiry-fields',
        itemSelector: '.air2-qtpl-type',
        store:        AIR2.Inquiry.templateStore,
        title:        'Add a field',
        tpl:          panelTemplate
    });

    setupDragAndDrop = function () {
        var config = AIR2.Inquiry.QuestionDragConfig();

        panel.air2DDProxies = [];

        Ext.each(panel.getDataView().getNodes(), function (item) {
            var itemEl, proxy;

            itemEl = Ext.get(item, true);
            proxy = new Ext.dd.DDProxy(
                itemEl.id,
                'questions',
                { isTarget: false }
            );

            Ext.apply(proxy, config);

            panel.air2DDProxies.push(proxy);
        });
    };

    panel.on('afterrender', function () {
        var dataview = panel.getDataView();
        setupDragAndDrop(dataview);
        dataview.on('afterrefresh', setupDragAndDrop);
    });

    AIR2.Inquiry.EDITABLECOMPONENTS.push(panel);

    return panel;
};
