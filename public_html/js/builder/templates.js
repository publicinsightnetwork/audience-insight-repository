/***********************
 * Query Builder question templates panel
 */
AIR2.Builder.Templates = function () {

    // organize data into groups
    var tmp = {};
    Ext.iterate(AIR2.Builder.QUESTPLS, function (key, def) {
        if (!tmp[def.group]) {
            tmp[def.group] = [];
        }
        def.name = key;
        tmp[def.group].push(def);
    });

    // create panel
    AIR2.Builder.Templates = new AIR2.UI.Panel({
        colspan:    1,
        title:      'Add a field',
        cls:        'air2-builder-templates',
        iconCls:    'air2-icon-printer',
        items: {
            xtype: 'box',
            data: tmp,
            tpl: new Ext.XTemplate(
                // generic
                '<tpl for="generic">' +
                    '<span class="air2-qtpl-type generic" air2qtpl="{name}">' +
                        '{display}' +
                    '</span>' +
                '</tpl>' +
                '<hr/>' +
                // contact info
                '<tpl for="contact">' +
                    '<span class="air2-qtpl-type contact" air2qtpl="{name}">' +
                        '{display}' +
                    '</span>' +
                '</tpl>' +
                '<hr/>' +
                // demographics
                '<tpl for="demographic">' +
                    '<span class="air2-qtpl-type demographic" ' +
                    'air2qtpl="{name}">' +
                        '{display}' +
                    '</span>' +
                '</tpl>'
            )
        }
    });

    // add drag proxy
    AIR2.Builder.Templates.on('render', function (cmp) {

        // custom proxy
        var prox = new Ext.dd.StatusProxy({shadow: false});
        prox.el.update('<div class="x-dd-drop-icon"></div>' +
            '<div class="air2-tpl-proxy"></div>');
        prox.ghost = Ext.get(prox.el.dom.childNodes[1]);

        // create dragzone
        cmp.dragzone = new Ext.dd.DragZone(cmp.el, {
            proxy: prox,
            // custom drag data
            getDragData: function (e) {
                var rec, t, tHeight, tpl, tplKey, tWidth;

                t = e.getTarget('.air2-qtpl-type');
                if (t) {
                    rec = new AIR2.Inquiry.quesStore.recordType();
                    tplKey = Ext.fly(t).getAttribute('air2qtpl');
                    tpl = AIR2.Builder.QUESTPLS[tplKey];
                    rec.forceSet('ques_template', tplKey);

                    // update the record (manually to avoid saving these fields)
                    rec.set('ques_type',        tpl.ques_type);
                    rec.set(
                        'ques_value',
                        AIR2.Inquiry.getLocalizedValue(tpl, 'ques_value')
                    );
                    rec.set(
                        'ques_choices',
                        Ext.encode(
                            AIR2.Inquiry.getLocalizedValue(tpl, 'ques_choices')
                        )
                    );
                    rec.set('ques_locks',       Ext.encode(tpl.ques_locks));
                    rec.set('ques_public_flag', tpl.ques_public_flag);
                    rec.set('ques_resp_type',   tpl.ques_resp_type);
                    rec.set('ques_resp_opts',   Ext.encode(tpl.ques_resp_opts));

                    tWidth  = Ext.fly(t).getWidth();
                    tHeight = Ext.fly(t).getHeight();
                    return {
                        ddel: t,
                        offsetXY: [tWidth / 2, tHeight / 2],
                        repairXY: Ext.fly(t).getXY(),
                        quesRecord: rec,
                        group: tpl.group
                    };
                }
                return false;
            },
            // make drag proxy
            onInitDrag: function (x, y) {
                this.proxy.update(this.dragData.ddel.cloneNode(true));
                this.proxy.el.setWidth(Ext.fly(this.dragData.ddel).getWidth());
                this.onStartDrag(x, y);
                AIR2.Builder.Main.dragMode(true);
                return true;
            },
            // fix offset
            autoOffset: function (iPageX, iPageY) {
                this.setDelta(this.dragData.offsetXY[0],
                    this.dragData.offsetXY[1]);
            },
            // return to origin
            getRepairXY: function () {
                AIR2.Builder.Main.dragMode(false);
                return this.dragData.repairXY;
            }
        });
    });

    return AIR2.Builder.Templates;
};
