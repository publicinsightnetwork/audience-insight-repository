Ext.ns('AIR2.UI');
/***************
 * AIR2 Spinner Component
 *
 * Custom implementation of Ext.Panel to show a spinner
 *
 * @class AIR2.UI.Spinner
 * @extends Ext.Panel
 * @xtype air2spinner
 *
 */
AIR2.UI.Spinner = Ext.extend(Ext.Panel, {
    baseCls: 'air2-spinner',
    frame: false,
    hidden: true,
    html: '<img src="' + AIR2.HOMEURL + '/css/img/loading.gif' +
        '" align="top" />'
});
Ext.reg('air2spinner', AIR2.UI.Spinner);
