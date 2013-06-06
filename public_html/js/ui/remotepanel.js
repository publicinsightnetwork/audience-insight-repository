Ext.ns('AIR2.UI');
/***************
 * AIR2 RemotePanel Component
 *
 * Display a remote URL in that fancy-pants AIR2-style panel
 *
 * @class AIR2.UI.RemotePanel
 * @extends AIR2.UI.Panel
 * @xtype air2remotepanel
 * @cfg {string} url
 *
 */
AIR2.UI.RemotePanel = function (config) {
    // remove any passed-in body elements
    delete config.html;
    delete config.tpl;

    // create a single remote-url body item
    config.items = {border: false, autoLoad: config.url};

    AIR2.UI.RemotePanel.superclass.constructor.call(this, config);
};
Ext.extend(AIR2.UI.RemotePanel, AIR2.UI.Panel, {

});
Ext.reg('air2remotepanel', AIR2.UI.RemotePanel);