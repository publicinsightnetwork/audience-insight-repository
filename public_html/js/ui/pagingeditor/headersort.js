Ext.ns('AIR2.UI.PagingEditor');
/***************
 * Header sort plugin
 *
 * Plugin for a PagingEditor which lets you sort columns based on certain
 * parameters in their markup.  To enable a column for sorting, it must be
 * under the CSS 'header' class, and have the class 'sortable'.  It must also
 * have the attributes 'air2fld' and 'air2dir'.
 *
 * Example: <tr class="header">
 *            <td class="sortable" air2fld="src_last_name" air2dir="asc"></td>
 *          </tr>
 *
 * @plugin AIR2.UI.PagingEditor.HeaderSort
 * @param {AIR2.UI.PagingEditor} pageEditor
 */
AIR2.UI.PagingEditor.HeaderSort = (function () {
    var firstSort,
        parseSort,
        refreshHeaders,
        setFirstSort,
        SORTPARAM;

    SORTPARAM = 'sort';

    // helper functions for complex sorting
    parseSort = function (str) {
        var commas,
            dir,
            fld,
            i,
            parts,
            sorts;

        sorts = [];

        // split the string by commas
        commas = str.split(/\s*,\s*/);
        for (i = 0; i < commas.length; i++) {
            // split by whitespace, to find sort direction
            parts = commas[i].split(/\s+/);
            fld = parts[0];
            dir = (parts.length > 1) ? parts[1].toLowerCase() : 'asc';
            sorts.push([fld, dir]);
        }
        return sorts;
    };
    firstSort = function (baseParms) {
        var all, str;

        str = '';
        if (baseParms[SORTPARAM]) {
            str = baseParms[SORTPARAM];
        }
        all = parseSort(str);
        return (all.length > 0) ? all[0] : false;
    };
    setFirstSort = function (store, fld, dir) {
        var i,
            newsort;

        newsort = fld + ' ' + dir;

        // add other extra sort fields
        for (i = 0; i < store.extraSorts.length; i++) {
            if (store.extraSorts[i][0] !== fld) {
                newsort += ',' + store.extraSorts[i][0] + ' ';
                newsort += store.extraSorts[i][1];
            }
        }

        // set params
        store.setBaseParam(SORTPARAM, newsort);
    };

    // helper function for setting up sorting
    refreshHeaders = function () {
        var el,
            first,
            hdrs,
            sortDir,
            sortFld;

        // store extra sorting fields on the store
        this.store.extraSorts = [];

        // calculate the sort
        first = firstSort(this.store.baseParams);
        sortFld = first ? first[0] : null;
        sortDir = first ? first[1] : null;

        // look for "sortable" column headers
        el = this.getTemplateTarget();
        hdrs = el.query('.header .sortable');
        Ext.each(hdrs, function (hdrEl) {
            var dir, fld;

            fld = hdrEl.getAttribute('air2fld');
            if (fld === sortFld) {
                hdrEl.setAttribute('air2dir', sortDir);
                Ext.fly(hdrEl).addClass('sort' + sortDir);
            }
            else if (fld) {
                dir = hdrEl.getAttribute('air2dir');
                dir = dir ? dir : 'asc';
                this.store.extraSorts.push([fld, dir]);
            }
        }, this);
    };

    return {
        init: function (pageEditor) {
            // intercept refresh to render the sorting
            var seqFn = pageEditor.refresh.createSequence(
                refreshHeaders,
                pageEditor
            );
            pageEditor.refresh = seqFn;

            // catch header clicks
            pageEditor.on('containerclick', function (dv, event) {
                var dir, el, fld;

                el = event.getTarget('.sortable');
                if (el) {
                    fld = el.getAttribute('air2fld');
                    dir = el.getAttribute('air2dir');
                    dir = (dir === 'asc') ? 'desc' : 'asc';
                    setFirstSort(dv.store, fld, dir);
                    dv.mask();
                    dv.pager.changePage(0);
                }
            });
        }
    };
}());
