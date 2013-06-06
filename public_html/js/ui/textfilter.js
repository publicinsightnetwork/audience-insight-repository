Ext.ns('AIR2.UI');
/***************
 * AIR2 TextFilter Component
 *
 * A textbox configured to fire typing events that event listeners use to apply
 * a filter to some other component.
 *
 * @class AIR2.UI.TextFilter
 * @extends Ext.form.TextField
 * @xtype air2textfilter
 * @cfg {Integer} keyDelayMs
 * @cfg {String} maskRe
 * @event filterchange(textfield, querystr)
 *
 */
AIR2.UI.TextFilter = function (config) {
    this.addEvents('filterchange');

    if (config.keyDelayMs) {
        this.keyDelayMs = config.keyDelayMs;
    }

    // call parent constructor
    AIR2.UI.TextFilter.superclass.constructor.call(this, config);

    //delayed task for filter change event
    var filterTask = new Ext.util.DelayedTask(function (value) {
        this.fireEvent('filterchange', this, value);
    }, this);

    // event handlers
    this.lastValue = '';
    this.on('keyup', function (field, event) {
        var r = this.getRawValue();
        if (this.lastValue !== r) {
            // value changed! Fire event!
            this.lastValue = r;
            filterTask.delay(this.keyDelayMs, null, null, [r]);
        }
    }, this);
};
Ext.extend(AIR2.UI.TextFilter, Ext.form.TextField, {
    enableKeyEvents: true,
    maskRe: /\w+/,
    keyDelayMs: 700,
    emptyText: 'filter results'
});
Ext.reg('air2textfilter', AIR2.UI.TextFilter);
