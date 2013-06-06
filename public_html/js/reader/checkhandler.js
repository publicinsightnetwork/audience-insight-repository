/***************
 * Checkbox/selection handling for the reader
 */
AIR2.Reader.checkHandler = function (dv) {

    // dom-involving stuff
    dv.on('afterrender', function (dv) {

        // stop default checkbox toggle action
        dv.el.on('click', function (e) {
            if (e.getTarget('.checker-box')) {
                e.preventDefault();
            }
        });

        // create checkbox menu
        dv.checkMenu = new Ext.menu.Menu({
            cls: 'air2-reader-menu',
            showSeparator: false,
            shadow: false,
            defaultOffsets: [0, -1],
            items: [
                {
                    text: 'Page <span class="lighter">(10)</span>',
                    handler: function () {
                        dv.checkMenu.selectPage();
                    }
                },
                {
                    text: 'All <span class="lighter">(999)</span>',
                    handler: function () {
                        dv.checkMenu.selectAll();
                    }
                },
                {
                    text: 'None',
                    handler: function () {
                        dv.checkMenu.selectNone();
                    }
                }
            ],
            selectAll: function () {
                dv.allSelected = true;
                dv.selectRange(0, dv.all.elements.length);
                dv.notify(dv.store.getTotalCount());
            },
            selectPage: function () {
                dv.allSelected = false;
                dv.selectRange(0, dv.all.elements.length);
                dv.notify(dv.all.elements.length, dv.store.getTotalCount());
            },
            selectNone: function () {
                dv.allSelected = false;
                dv.clearSelections();
                dv.notify(false);
            },
            listeners: {
                beforeshow: function () {
                    var all, page;

                    page = '(' + dv.all.elements.length + ')';
                    all  = '(' + dv.store.getTotalCount() + ')';

                    dv.checkMenu.items.items[0].el.child(
                        '.lighter'
                    ).update(
                        page
                    );

                    dv.checkMenu.items.items[1].el.child(
                        '.lighter'
                    ).update(
                        all
                    );

                }
            }
        });
    });

    // helper to show/hide notifications
    dv.notify = function (numSel, numTotal) {
        var all, page, pageSize, rowCount;

        all  = dv.el.child('.notify-all');
        page = dv.el.child('.notify-page');
        rowCount = AIR2.Reader.DV.store.getTotalCount();
        pageSize = AIR2.Reader.DV.pager.pageSize;

        if (numSel && numTotal && rowCount > pageSize) {
            all.addClass('hide');
            page.child(
                'b'
            ).update(
                Ext.util.Format.plural(numSel, 'submission')
            );

            page.child('a').update('Select all ' + numTotal);
            page.removeClass('hide');
        }
        else if (numSel) {
            page.addClass('hide');
            all.child(
                'b'
            ).update(
                Ext.util.Format.plural(numSel, 'submission')
            );

            all.removeClass('hide');
        }
        else {
            all.addClass('hide');
            page.addClass('hide');
        }
    };

    // don't clear selections on header clicks
    dv.onContainerClick = function () {};

    // handle header clicks
    dv.on('containerclick', function (dv, e) {
        var el = e.getTarget('.checker', 10, true);

        if (e.getTarget('.checker-box')) {
            if (e.getTarget('.all-checked')) {
                dv.checkMenu.selectNone();
            }
            else {
                dv.checkMenu.selectPage();
            }
        }
        else if (el) {
            e.stopEvent();
            dv.checkMenu.show(el.child('a', true));
        }
        else if (e.getTarget('.notify-all') && e.getTarget('a')) {
            e.preventDefault();
            dv.checkMenu.selectNone();
        }
        else if (e.getTarget('.notify-page') && e.getTarget('a')) {
            dv.checkMenu.selectAll();
        }
    });

    // handle <td> selection changes
    dv.on('selectionchange', function (dv, selections) {
        var chk, el, hdr, i;

        for (i = 0; i < dv.all.elements.length; i++) {
            el = dv.all.elements[i];
            if (selections.indexOf(el) >= 0) {
                Ext.fly(el).child('.checker-box', true).checked = true;
            }
            else {
                Ext.fly(el).child('.checker-box', true).checked = false;
            }
        }

        // alter select state of the header
        hdr = dv.el.child('tr.header');
        chk = hdr.child('.checker-box', true);
        if (selections.length > 0) {
            hdr.addClass('row-checked');
            chk.checked = true;
        }
        else {
            hdr.removeClass('row-checked');
            chk.checked = false;
        }
        if (selections.length === dv.all.elements.length) {
            hdr.addClass('all-checked');
        }
        else {
            hdr.removeClass('all-checked');
        }
    });

    // override multi select for custom checkbox-selecting capability
    dv.doMultiSelection = function (item, index, e) {
        if (e.getTarget('.handle') || e.getTarget('.checker')) {
            dv.notify(false);
            dv.allSelected = false;

            if (e.shiftKey && this.last !== false) {
                this.selectRange(this.last, index, true); //keep existing
            }
            else {
                if (this.isSelected(index)) {
                    this.deselect(index);
                }
                else {
                    this.select(index, true); //keep existing
                }
            }
            e.preventDefault();
        }
    };

};
