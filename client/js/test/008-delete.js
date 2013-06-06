/**
 * Delete AIR2 resources
 *
 * AIRCURRUSER constant should be set by 005
 * AIRNETWORKUUID constant should be set by 006
 */
module("DELETE stuff", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});


/**
 * Delete network resource we created
 */
asyncTest('008 delete network', 5, function() {
    var path = 'user/'+AIRCURRUSER+'/network/'+AIRNETWORKUUID;

    // invalid field
    AIRAPI.remove(path, function(rsp) {
        equal( rsp.status, 200, 'remove network 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.uuid, 'has uuid' );
        ok( !rsp.data.radix, 'no radix' );

        // continue
        start();
    });

});


/**
 * Delete on invalid resource
 */
asyncTest('008 delete invalid', 1, function() {
    var path = 'user/'+AIRCURRUSER+'/network/BLAHBLAHBLAH';

    AIRAPI.remove(path, function(rsp) {
        equal( rsp.status, 404, 'update invalid path 404' );

        // continue
        start();
    });

});


/**
 * Fetch to make sure it's gone
 */
asyncTest('008 delete double-check', 1, function() {
    var path = 'user/'+AIRCURRUSER+'/network/'+AIRNETWORKUUID;

    AIRAPI.fetch(path, function(rsp) {
        equal( rsp.status, 404, 'fetch former network 404' );

        // continue
        start();
    });

});
