Ext.ns('AIR2.UI.PagingEditor');
/***************
 * Hover Controls plugin
 *
 * Plugin for a PagingEditor which displays edit/delete controls as a hovering
 * item on the left side of each row.
 *
 * @plugin AIR2.UI.PagingEditor.HoverControls
 * @param {AIR2.UI.PagingEditor} pageEditor
 */
AIR2.UI.PagingEditor.HoverControls = {
    init: function (pageEditor) {
        // get controls
        var controls,
            refreshControls;

        if (pageEditor.rendered) {
            controls = this.makeControls(pageEditor.el);
        }
        else {
            pageEditor.on('render', function () {
                controls = this.makeControls(pageEditor.el);
            }, this);
        }

        // setup edit/delete-ability of row
        refreshControls = function (node) {
            var ad,
                ae,
                mayDelete,
                mayEdit,
                rec;

            if (!pageEditor.el.hasClass('unlocked')) {
                return; //already locked
            }

            ae = pageEditor.allowEdit;
            ad = pageEditor.allowDelete;
            rec = pageEditor.getRecord(node);
            mayEdit = Ext.isFunction(ae) ? ae(rec) : ae;
            mayDelete = Ext.isFunction(ad) ? ad(rec) : ad;

            // return early
            if (!mayEdit && !mayDelete) {
                return;
            }

            // action based on editability
            if (mayEdit && mayDelete) {
                controls.removeClass(['edit-only', 'delete-only']);
            }
            else if (mayEdit) {
                controls.replaceClass('delete-only', 'edit-only');
            }
            else if (mayDelete) {
                controls.replaceClass('edit-only', 'delete-only');
            }
            controls.mouseIn = false;
            controls.rowOver = true;
            controls.setHeight(Ext.fly(node).getHeight() + 1);
            controls.anchorTo(node, 'r-l', [0, -1]);
            controls.show();
        };

        // listen to node enter/leave
        pageEditor.on('mouseenter', function (dv, idx, node) {
            refreshControls(node);
        });
        pageEditor.on('mouseleave', function (dv, idx, node, ev) {
            controls.rowOver = false;
            controls.setVisible(controls.mouseIn || controls.rowOver);
        });
    },
    makeControls: function (el) {
        var controls = el.insertSibling({
            tag: 'table',
            cls: 'air2-paging-editor-hoverctrl',
            html: '<tr><td class="delete"></td>' +
                  '<td class="edit">Edit</td></tr>'
        });
        controls.on('mouseenter', function () {
            controls.mouseIn = true;
            controls.setVisible(controls.mouseIn || controls.rowOver);
        });
        controls.on('mouseleave', function () {
            controls.mouseIn = false;
            controls.setVisible(controls.mouseIn || controls.rowOver);
        });
        return controls;
    }
};
