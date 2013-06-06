/***********************
 * Adds a dragzone for re-ordering questions
 */
AIR2.Builder.questionDragHandler = function () {

    // add drag proxy
    AIR2.Builder.Main.on('render', function (cmp) {

        // custom proxy
        var prox = new Ext.dd.StatusProxy({shadow: false});
        prox.el.update('<div class="x-dd-drop-icon"></div>' +
            '<div class="air2-builder-main"></div>');
        prox.ghost = Ext.get(prox.el.dom.childNodes[1]);

        // create dragzone
        cmp.dragzone = new Ext.dd.DragZone(cmp.el, {
            proxy: prox,
            // custom drag data
            getDragData: function (e) {
                var idx, isPublic, node, rec, t;
                t = e.getTarget('.handle');
                if (t) {
                    node = e.getTarget('.ques-row');
                    idx  = AIR2.Builder.PUBLICDV.indexOf(node);
                    rec  = AIR2.Builder.PUBLICDV.getRecord(node);
                    isPublic = true;
                    if (idx < 0) {
                        idx  = AIR2.Builder.PRIVATEDV.indexOf(node);
                        rec  = AIR2.Builder.PRIVATEDV.getRecord(node);
                        isPublic = false;
                    }
                    return {
                        ddel: node,
                        offsetXY: [10, Ext.fly(t).getHeight() / 2],
                        repairXY: Ext.fly(node).getXY(),
                        quesRecord: rec
                    };
                }
                return false;
            },
            // make drag proxy
            onInitDrag: function (x, y) {
                this.proxy.update(this.dragData.ddel.cloneNode(true));
                this.proxy.el.setWidth(Ext.fly(this.dragData.ddel).getWidth());

                // hide the node
                Ext.fly(this.dragData.ddel).setStyle({display: 'none'});
                AIR2.Builder.PUBLICDV.cacheStops();
                AIR2.Builder.PRIVATEDV.cacheStops();
                AIR2.Builder.Main.dragMode(true);

                this.onStartDrag(x, y);
                return true;
            },
            // fix offset
            autoOffset: function (iPageX, iPageY) {
                this.setDelta(
                    this.dragData.offsetXY[0],
                    this.dragData.offsetXY[1]
                );
            },
            // return to origin
            getRepairXY: function () {
                Ext.fly(this.dragData.ddel).slideIn('t', {duration: 0.2});
                AIR2.Builder.Main.dragMode(false);
                return this.dragData.repairXY;
            }
        });
    });


};
