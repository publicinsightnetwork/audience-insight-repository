Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer DragHelper
 *
 * Add a global listener on the document body to show a hovering "draggable"
 * icon to indicate air2-dragzones.
 *
 * NOTE: this script executes on load.
 *
 */
Ext.onReady(function () {
    AIR2.Drawer.hoverEl = Ext.DomHelper.append('air2-body', {
        cls: 'air2-dragarrow',
        html: '<img src="' + AIR2.HOMEURL + '/css/img/icons/arrow-move.png"/>'
    }, true);

    Ext.getBody().on('mouseover', function (event) {
        var el;

        // ignore mouseovers on the dragarrow
        if (event.getTarget('.air2-dragarrow')) {
            return;
        }

        el = event.getTarget('.air2-dragzone');
        if (el) {
            if (AIR2.Drawer.hoverEl.ddEl !== el) {
                AIR2.Drawer.hoverEl.ddEl = el;
                AIR2.Drawer.hoverEl.alignTo(el, 'r-l?');
                if (!AIR2.Drawer.hoverEl.isVisible()) {
                    AIR2.Drawer.hoverEl.show({duration: 0.1});
                }
            }
        }
        else {
            AIR2.Drawer.hoverEl.hide(false);
            AIR2.Drawer.hoverEl.ddEl = false;
        }
    });
});
