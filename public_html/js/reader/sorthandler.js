/***************
 * Header-sort handling for the reader
 */
AIR2.Reader.sortHandler = function (dv) {
    var fmt, setSortClasses;

    // helper to set dom header classes
    setSortClasses = function (field, dir) {
        var def = AIR2.Reader.COLUMNS[field];
        if (def && def.sortable) {
            dv.el.select('.header .asc').removeClass('asc');
            dv.el.select('.header .desc').removeClass('desc');
            dv.el.select('.header .' + def.cls).addClass(dir);
        }
    };

    // tie into refresh method, to set asc/desc classes every load
    fmt = Ext.util.Format;
    dv.refresh = dv.refresh.createSequence(function () {
        var dir, fld, parts;

        parts = AIR2.Reader.ARGS.s.split(' ');
        fld = fmt.lowercase(fmt.trim(parts[0]));
        dir = fmt.lowercase(fmt.trim(parts[1]));
        setSortClasses(fld, dir);
    });

    // handle header clicks
    dv.on('containerclick', function (dv, e) {
        var def, dir, el, fld;

        el = e.getTarget('.sortable', 5, true);

        if (el) {
            fld = el.getAttribute('air2fld');
            def = AIR2.Reader.COLUMNS[fld];
            if (!def) {
                return;
            }

            // TODO: remove
            if (['live_favorite'].indexOf(fld) > -1) {
                alert("TODO search sort: " + fld);
                return;
            }

            // flip direction if already sorted on field
            dir = def.sortable || 'asc';
            if (el.hasClass('asc')) {
                dir = 'desc';
            }
            else if (el.hasClass('desc')) {
                dir = 'asc';
            }

            setSortClasses(fld, dir);

            // reload the store (back to page 1)
            AIR2.Reader.ARGS.s = fld + ' ' + dir;
            dv.store.baseParams = AIR2.Reader.ARGS;
            dv.pager.changePage(0);
        }
    });

};
