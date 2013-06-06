Ext.ns('AIR2.UI');
/***************
 * AIR2 PanelGrid Container
 *
 * Container to arrange AIR2.UI.Panels into a fixed-width grid
 *
 * @class AIR2.UI.PanelGrid
 * @extends Ext.Container
 * @xtype air2pgrid
 * @cfg {String} columnLayout
 *   Describes the width/number of columns in the layout.  Valid values are:
 *     '111' -> three columns
 *     '21'  -> wide column on left (default)
 *     '12'  -> wide column on right
 *     '3'   -> single column
 *
 */
AIR2.UI.PanelGrid = function (config) {
    var colWidths,
        panels,
        tblDefaults;

    panels = config.items || [];
    if (!Ext.isArray(panels)) {
        panels = [panels];
    }
    this.columnCache = []; // 3-column cache
    this.columnClasses = []; // extra css to apply to a column

    // combine base classes
    config.cls = this.cls + (config.cls ? (' ' + config.cls) : '');

    colWidths = config.columnWidths;
    config.defaultType = 'container';
    config.defaults = {
        columnWidth: 0.3333
    };
    if (colWidths) {
        config.defaults.columnWidth = colWidths[0];
    }
    tblDefaults = {
        cls: 'x-table-layout air2-panel-grid',
        style: {width: '100%'}
    };

    switch (config.columnLayout) {
    case '111':
        config.items = [{/* default */}, {/* default */}, {/* default */}];
        this.columnCache = [0, 1, 2];
        break;
    case '12':
        if (!colWidths) {
            colWidths = [0.3333, 0.6666];
        }
        config.items = [
            {/* default */},
            {
                columnWidth: colWidths[1],
                layout: 'table',
                layoutConfig: {columns: 2, tableAttrs: tblDefaults}
            }
        ];
        this.columnCache = [0, 1, 1];
        break;
    case '3':
        config.items = [{
            columnWidth: 1,
            layout: 'table',
            layoutConfig: {columns: 3, tableAttrs: tblDefaults}
        }];
        this.columnCache = [0, 0, 0];
        break;
    case '1':
        config.items = [{
            columnWidth: 1,
            layout: 'table',
            layoutConfig: {columns: 1, tableAttrs: tblDefaults}
        }];
        this.columnCache = [0, 0, 0];
        break;

    default: /* '21' */
        config.columnLayout = '21';
        if (!colWidths) {
            colWidths = [0.6666, 0.3333];
        }
        config.items = [{
            columnWidth: colWidths[0],
            layout: 'table',
            layoutConfig: {columns: 2, tableAttrs: tblDefaults}
        }, {columnWidth: colWidths[1]}];
        this.columnCache = [0, 0, 1];
        this.columnClasses[2] = 'air2-panel-grid-right';
        break;
    }

    // call parent constructor
    AIR2.UI.PanelGrid.superclass.constructor.call(this, config);

    this.addIndex = 0;
    this.rowSpans = [0, 0, 0];
    this.on('beforeadd', function (container, component, index) {
        var a, c, compIdx, i, l, r;

        l = config.columnLayout;
        c = (component.colspan) ? component.colspan : 1;
        r = (component.rowspan) ? component.rowspan : 1;

        // remove rowspan where comp spans container width
        if (r > 1) {
            if (
                (c == 2 && this.addIndex == 0 && l == '21') ||
                (c == 2 && this.addIndex == 1 && l == '12') ||
                (c == 3 && this.addIndex == 0 && l == '3')
            ) {
                component.rowspan = 1;
            }
        }

        // find the index of the component we're supposed to add to
        compIdx = this.columnCache[this.addIndex];
        container.get(compIdx).add(component);
        // add extra css
        if (this.addIndex === 0 && (l === '111' || l === '12')) {
            component.addClass('air2-panel-grid-left');
        }
        else if (this.addIndex === 2 && (l === '111' || l === '21')) {
            component.addClass('air2-panel-grid-right');
        }
        else if (this.addIndex === 1 && l === '111') {
            component.addClass('air2-panel-grid-center');
        }

        // track any rowspans on this item
        for (i = 0; i < c; i++) {
            this.rowSpans[this.addIndex + i] += (r - 1);
        }

        // find the next addIndex, checking for rowspans
        component.colspan = component.colspan || 1;
        a = (this.addIndex + component.colspan) % 3;
        while (this.rowSpans[a] > 0) {
            this.rowSpans[a]--;
            a = (a + 1) % 3;
        }
        this.addIndex = a;
        return false; // don't add to THIS panel
    }, this);

    // trigger the adding
    this.add(panels);
};
Ext.extend(AIR2.UI.PanelGrid, Ext.Container, {
    layout: 'column',
    cls: 'air2-panelgrid',
    defaults: {
        xtype: 'air2panel'
    }
});
Ext.reg('air2pgrid', AIR2.UI.PanelGrid);
