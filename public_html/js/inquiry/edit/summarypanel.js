/***********************
 * Constructs a new inquiry dataview grouping
 */
AIR2.Inquiry.SummaryPanel = function () {
    var buttonSnippet,
        fullDescriptionHeader,
        fullDescriptionPanel,
        fullDescriptionTemplate,
        inqRadix,
        isFormbuilder,
        shortDescriptionHeader,
        shortDescriptionPanel,
        shortDescriptionTemplate,
        stripTags,
        titlePanel,
        titleTemplate;

    buttonSnippet = '<div class="controls">' +
            '<button class="air2-rowedit">Edit</button>' +
        '</div>';

    stripTags = function (field, newValue, oldValue) {
        field.setRawValue(Ext.util.Format.stripTags(newValue));
    };

    inqRadix = AIR2.Inquiry.BASE.radix;
    isFormbuilder = (inqRadix.inq_type === 'F');

    titleTemplate = new Ext.XTemplate(
        '<tpl for=".">' +
            '<div class="inquiry-row">' +
                '<h2>{inq_ext_title}</h2>' +
                buttonSnippet +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    titlePanel = new AIR2.UI.Panel({
        allowEdit:      true,
        bodyBorder:     false,
        border:         false,
        cls:            'inquiry-row',
        editInPlace:    [
            {
                listeners: {
                    change: stripTags
                },
                name: 'inq_ext_title',
                style: AIR2.Inquiry.QuestionCSS,
                xtype: 'textfield'
            }
        ],
        height:        'auto',
        id:            'air2-inquiry-title',
        itemSelector:   '.inquiry-row',
        labelWidth:     1,
        noHeader:       true,
        overCls:        'over',
        store:          AIR2.Inquiry.inqStore,
        tpl:            titleTemplate
    });

    titlePanel.on('afterrender', function () {
        titlePanel.el.on('click', function (event, target, object) {
            if (event.getTarget('.air2-rowedit')) {
                titlePanel.startEditInPlace();
            }
        });

        titlePanel.el.on('dblclick', function () {
            titlePanel.startEditInPlace();
        });
    });

    shortDescriptionTemplate = new Ext.XTemplate(
        '<strong>Short Description</strong> (Used for RSS Feeds, Facebook, Source, etc.)<br />' +
        '<tpl for=".">' +
            '<div class="inquiry-row">' +
                '<p>{inq_rss_intro}</p>' +
                buttonSnippet +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    shortDescriptionPanel = new AIR2.UI.Panel({
        allowEdit:      true,
        bodyBorder:     false,
        border:         false,
        cls:            'inquiry-row',
        editInPlace:    [
            {
                html: 'SHORT DESCRIPTION',
                tag: 'h4',
                xtype: 'box'
            },
            {
                listeners: {
                    change: stripTags
                },
                name: 'inq_rss_intro',
                style: AIR2.Inquiry.QuestionCSS,
                xtype: 'textarea'
            }
        ],
        height:        'auto',
        id:            'air2-inquiry-short-description',
        itemSelector:   '.inquiry-row',
        labelWidth:     1,
        listeners: {
            afterrender: function (panel) {
                panel.el.on('click', function (event, target, object) {
                    if (event.getTarget('.air2-rowedit')) {
                        panel.startEditInPlace();
                    }
                });

                panel.el.on('dblclick', function () {
                    panel.startEditInPlace();
                });
            }
        },
        noHeader:       true,
        overCls:        'over',
        store:          AIR2.Inquiry.inqStore,
        tpl:            shortDescriptionTemplate
    });

    fullDescriptionTemplate = new Ext.XTemplate(
        '<strong>Full Description</strong><br />' +
        '<tpl for=".">' +
            '<div class="inquiry-row">' +
                '{inq_intro_para}' +
                buttonSnippet +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true
        }
    );

    fullDescriptionPanel = new AIR2.UI.Panel({
        allowEdit:      true,
        bodyBorder:     false,
        border:         false,
        cls:            'inquiry-row',
        editInPlace:    [
            {
                html: 'FULL DESCRIPTION',
                tag: 'h4',
                xtype: 'box'
            },
            {
                name: 'inq_intro_para',
                xtype: 'air2ckeditor'
            }
        ],
        height:        'auto',
        id:            'air2-inquiry-full-description',
        itemSelector:   '.inquiry-row',
        labelWidth:     1,
        listeners: {
            afterrender: function (panel) {
                panel.el.on('click', function (event, target, object) {
                    if (event.getTarget('.air2-rowedit')) {
                        panel.startEditInPlace();
                    }
                });

                panel.el.on('dblclick', function () {
                    panel.startEditInPlace();
                });
            }
        },
        noHeader:       true,
        overCls:        'over',
        store:          AIR2.Inquiry.inqStore,
        tpl:            fullDescriptionTemplate
    });

    return [
        titlePanel,
        shortDescriptionPanel,
        fullDescriptionPanel
    ];
};
