Ext.ns('AIR2.UI');
/***************
 * AIR2 DataView Component
 *
 * Custom implementation of Ext.DataView to allow both links and selections to
 * work at the same time.
 *
 * @class AIR2.UI.DataView
 * @extends Ext.DataView
 * @event afterrefresh(dataview)
 * @xtype air2dataview
 *
 */
AIR2.UI.DataView = Ext.extend(Ext.DataView, {
    initComponent: function () {
        AIR2.UI.DataView.superclass.initComponent.call(this);
        this.addEvents('afterrefresh');
    },
    onItemClick: function (item, index, e) {
        var clickTarget, mouseDown;

        clickTarget = e.getTarget();
        if (this.fireEvent("beforeclick", this, index, item, e) === false) {
            return false;
        }
        if (this.multiSelect) {
            // if already selected, don't process
            // click until the mouseup happens
            if (this.isSelected(index)) {
                mouseDown = e.getXY();

                // listen for SINGLE mouseup anywhere, and check if the mouse
                // moved since the mousedown (signals DRAG rather than CLICK)
                Ext.getDoc().on(
                    'mouseup',
                    function (e2) {
                        var mouseUp = e2.getXY();
                        if (
                            mouseDown[0] === mouseUp[0] &&
                            mouseDown[1] === mouseUp[1]
                        ) {
                            this.doMultiSelection(item, index, e2);
                        }
                    },
                    this,
                    {single: true}
                );
            }
            else {
                this.doMultiSelection(item, index, e);
            }
        }
        else if (this.singleSelect) {
            this.doSingleSelection(item, index, e);
            if (!Ext.isDefined(clickTarget.href)) {
                e.preventDefault();
            }
        }
        return true;
    },
    // changed to listen on "mousedown" instead of "click"
    // so that selection events fire before drag-drop starts
    afterRender: function () {
        AIR2.UI.DataView.superclass.afterRender.call(this);

        // unregister "click" listener, replace with "mousedown"
        this.mun(this.getTemplateTarget(), 'click', this.onClick, this);
        this.mon(this.getTemplateTarget(), 'mousedown', this.onClick, this);
    },
    refresh: function () {
        AIR2.UI.DataView.superclass.refresh.call(this);
        this.fireEvent('afterrefresh', this);
    }
});
Ext.reg('air2dataview', AIR2.UI.DataView);
