Ext.ns('AIR2');
/***************
 * AIR2
 *
 * Some global items in AIR2, that I'm really not sure where they should go
 * yet.
 *
 */

/* constants */

AIR2.CONSTANTS = {};
AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID = 'ADKLm8Okenaa';



Ext.onReady(function () {
    Ext.QuickTips.init();
    Ext.Ajax.disableCaching = false;

    // every browser but IE will respect no-cache headers
    if (Ext.isIE) {
        Ext.Ajax.disableCaching = true;
    }
});

// Placeholder for global remote exception handling
Ext.data.DataProxy.on('exception',
                        function (proxy, type, action, options, response, arg) {
    Logger("A REMOTE EXCEPTION HAS OCCURRED!  (this is the global handler)",
            response);
    // Logger(proxy);
    // Logger(type);
    // Logger(action);
    // Logger(options);
    // Logger(response);
    // Logger(arg);
});

// extract an "object" from a prefixed object
// This is the client-side unpacking of the flatten_3dimensional_data()
// CRUD method.
AIR2.unflattenCRUDObj = function (obj, prefix) {
    if (obj[prefix]) {
        return obj[prefix];
    }
    var newObj = {};
    Ext.iterate(obj, function (k, v) {
        var s = k.split(':');
        //Logger(k, s);
        if (s && s.length === 2 && s[0] === prefix) {
            newObj[s[1]] = v;
        }
    });
    return newObj;
};

// focus the screen on a particular element
AIR2.focus = function (el) {
    if (Ext.isElement(el)) {
        el = Ext.fly(el);
    }

    // params
    var body   = Ext.getBody(),
        scroll = body.getScroll(),
        viewp  = body.getViewSize(),
        reg    = Ext.fly(el).getRegion(),
        anim   = {duration: 0.3},
    //  helper to create
        getElement = function (id) {
            return Ext.get(id) ||
                body.createChild({ id: id, cls: 'air2-focus-mask' });
        },
        top    = getElement('air2-focus-top'),
        bottom = getElement('air2-focus-bottom'),
        left   = getElement('air2-focus-left'),
        right  = getElement('air2-focus-right');

    // animate in!
    top.setStyle({
            top: 0,
            width: '100%',
            height: scroll.top + 'px'
        }).setHeight(reg.top, anim);

    bottom.setStyle({
            bottom: 0,
            width: '100%',
            top: (scroll.top + viewp.height) + 'px'
        }).setY(reg.bottom, anim);

    left.setStyle({
            top: reg.top + 'px',
            height: (reg.bottom - reg.top) + 'px',
            left: 0,
            width: 0
        }).setWidth(reg.left, anim);

    right.setStyle({
            top: reg.top + 'px',
            height: (reg.bottom - reg.top) + 'px',
            right: 0
        }).setX(reg.right, anim);

    // freeze the header
    Ext.get('air2-headerwrap').setStyle({position: 'absolute'});
};

// unfocus element
AIR2.unfocus = function () {
    var anim   = {duration: 0.2, remove: true},
        top    = Ext.get('air2-focus-top'),
        bottom = Ext.get('air2-focus-bottom'),
        left   = Ext.get('air2-focus-left'),
        right  = Ext.get('air2-focus-right'),
        all    = [top, bottom, left, right];
    Ext.each(all, function (el) {
        if (el) {
            el.fadeOut(anim);
        }
    });
};

