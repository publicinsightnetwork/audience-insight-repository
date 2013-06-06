Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer DragZone
 *
 * Custom implementation of an Ext.dd.DragZone designed to work with AIR2 and
 * the Bin/Drawer interface.
 *
 * @class AIR2.Drawer.DragZone
 * @extends Ext.dd.DragZone
 *
 */
AIR2.Drawer.DragZone = Ext.extend(Ext.dd.DragZone, {
    ddGroup: 'air2-drawer-ddzone',
    init: function (id, group, config) {

        //cache a reference
        this.drawer = Ext.getCmp('air2-app').drawer;
        AIR2.Drawer.DragZone.superclass.init.call(this, id, group, config);

        // allow dragging/dropping of links
        this.removeInvalidHandleType('A');
    },
    getRepairXY: function () {

        // if proxy is off the screen, DON'T repair it's position!
        return (this.proxy.el.getX() < 0) ? false : this.dragData.repairXY;
    },
    onDrag: function () {
        this.drawer.tempOpen();
    },
    onInvalidDrop: function (e) {
        this.drawer.tempShut();
        AIR2.Drawer.DragZone.superclass.onInvalidDrop.call(this, e);
    },
    afterDragDrop: function () {

        // remove scroller listener
        Ext.getDoc().un('scroll', this.constrainToViewport, this);
    },
    afterInvalidDrop: function () {

        // remove scroller listener
        Ext.getDoc().un('scroll', this.constrainToViewport, this);
    },
    afterRepair: function () {

        // only execute "afterRepair" if ddel is an HtmlElement
        if (!Ext.isString(this.dragData.ddel)) {
            AIR2.Drawer.DragZone.superclass.afterRepair.call(this);
        }
        this.dragging = false;
    },
    onInitDrag: function (x, y) {

        // check if the 'ddel' is a string or an HtmlElement
        if (Ext.isString(this.dragData.ddel)) {
            this.proxy.update('<div>' + this.dragData.ddel + '</div>');
        }
        else {
            this.proxy.update(this.dragData.ddel.cloneNode(true));
        }

        // constrain to viewport, and listen to scroller
        this.cacheView = Ext.getBody().getViewSize();
        this.cacheWidth = this.proxy.el.getWidth();
        this.cacheHeight = this.proxy.el.getHeight();

        //this.constrainToViewport();
        Ext.getDoc().on('scroll', this.constrainToViewport, this);
    },
    constrainToViewport: function () {
        this.drawer.refreshDDLocation();
        var scrolltop = Ext.getBody().getScroll().top;

        this.constrainX = true;
        this.minX = 0;

        //19 for image width
        this.maxX = this.cacheView.width - this.cacheWidth - 19;
        this.constrainY = true;
        this.minY = scrolltop;
        this.maxY = scrolltop + this.cacheView.height - this.cacheHeight;
    }
});
