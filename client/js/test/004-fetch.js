/**
 * Fetch some AIR2 resources
 */
module("FETCH stuff", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});

// known system user uuid
var AIRSYSUSER = '3fc8faac592b';


/**
 * Fetch user
 */
asyncTest('004 fetch user', 10, function() {

    AIRAPI.fetch('user/'+AIRSYSUSER, function(rsp) {
        equal( rsp.status, 200, 'fetch 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        ok( rsp.data.success, 'has success' );
        equal( rsp.data.code, 20, 'has code 20' );
        equal( rsp.data.uuid, AIRSYSUSER, 'has sysuser uuid' );
        ok( rsp.data.authz, 'has authz' );
        ok( rsp.data.radix, 'has radix' );

        // check radix
        var radix = rsp.data.radix ? rsp.data.radix : {};
        equal( radix.user_uuid, AIRSYSUSER, 'radix uuid' );
        equal( radix.user_username, 'AIR2SYSTEM', 'radix username' );
        equal( radix.user_type, 'S', 'radix type' );

        // continue
        start();
    });

});


/**
 * Call fetch at the "LIST" level (air2/user.json)
 *
 * This works, BUT only because both query/fetch are GET requests
 */
asyncTest('004 fetch LIST', 11, function() {

    AIRAPI.fetch('user', function(rsp) {
        equal( rsp.status, 200, 'fetch 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        ok( rsp.data.success, 'has success' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( !rsp.data.uuid, 'no uuid' );
        ok( !rsp.data.authz, 'no authz' );
        ok( rsp.data.radix, 'has radix' );

        // check radix
        var radix = rsp.data.radix ? rsp.data.radix : {};
        ok( !radix.user_uuid, 'radix no uuid' );
        ok( radix.length > 1, 'radix is a list!' );
        ok( rsp.data.meta.limit, 'has limit' );
        equal( radix.length, rsp.data.meta.limit, 'limit applied' );

        // continue
        start();
    });

});


/**
 * Fetch something that doesn't exist
 */
asyncTest('004 fetch DNE', 1, function() {

    AIRAPI.fetch('user/DNEUSERUUID', function(rsp) {
        equal( rsp.status, 404, 'fetch 404' );

        // continue
        start();
    });

});
