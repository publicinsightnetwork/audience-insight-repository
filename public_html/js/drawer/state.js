Ext.ns('AIR2.Drawer');
/***************
 * AIR2 Drawer State
 *
 * Static STATE of a Drawer at any point, even pre-Ext.onReady(). The STATE is
 * stored in a cookie, and is used on the server-side to store inline Drawer
 * data.  This effectively makes the Drawer appear Stateful across page loads.
 *
 * NOTE: Unlike most components, STATE executes on load, generating the setter
 * and getter functions.
 *
 * @function AIR2.Drawer.STATE.setView
 * @param {String} viewtype
 * @param {Object} params
 * @param {String} uuid (optional)
 *
 * @function AIR2.Drawer.STATE.set
 * @param {String} name
 * @param {String} value
 *
 * @function AIR2.Drawer.STATE.get
 * @param {String} name
 *
 * @function AIR2.Drawer.STATE.sanity
 *
 */
AIR2.Drawer.STATE = (function () {
    var ckname, data, isSane;

    ckname = AIR2.BINCOOKIE || 'air2_bin_state';
    isSane = false; //make sure we check sanity

    data = Ext.util.Cookies.get(ckname);
    data = (data) ? Ext.decode(data) : null;
    if (!data) {
        Ext.util.Cookies.clear(ckname);
        data = {};
        delete AIR2.BINDATA;
        delete AIR2.BINBASE;
        isSane = true;
    }

    return {
        // set all bin-view params at once
        setView: function (vwtype, params, uuid) {
            data.view = vwtype;
            data.params = params;
            if (uuid) {
                data.uuid = uuid;
            }
            else {
                delete data.uuid;
            }
            Ext.util.Cookies.set(ckname, Ext.encode(data));
        },
        // set one bin-view param
        set: function (name, value) {
            data[name] = value;
            Ext.util.Cookies.set(ckname, Ext.encode(data));
        },
        get: function (name) {
            if (!isSane) {
                AIR2.Drawer.STATE.sanity();
            }
            return data[name];
        },
        sanity: function () {
            // IMPORTANT! Sanity-check the cookie, and DELETE it if invalid
            if (
                !(AIR2.BINDATA) ||
                !(
                    data.view === 'sm' ||
                    data.view === 'lg' ||
                    data.view === 'si'
                ) ||
                (data.view === 'si' && !data.uuid) ||
                (data.view === 'si' && !AIR2.BINBASE)
            ) {
                Logger('********** INVALID BIN COOKIE ***********', data);
                Ext.util.Cookies.clear(ckname);
                data = {};
                delete AIR2.BINDATA;
                delete AIR2.BINBASE;
            }
            isSane = true;
        }
    };
}());
