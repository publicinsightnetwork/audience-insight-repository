/**
 * Update AIR2 resources
 *
 * AIRCURRUSER constant should be set by 005
 * AIRNETWORKUUID constant should be set by 006
 */
module("UPDATE stuff", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});


/**
 * Update network resource we created
 */
asyncTest('007 update the network', 9, function() {
    var done = 0;
    var path = 'user/'+AIRCURRUSER+'/network/'+AIRNETWORKUUID;
    var d = {uuri_handle: 'anotherajaxtest', something: 'nothing'};

    // invalid field
    AIRAPI.update(path, d, function(rsp) {
        equal( rsp.status, 400, 'update extra field 400' );

        // continue
        done++;
        if (done == 2) start();
    });

    // just handle
    d = {uuri_handle: 'anotherajaxtest'};
    AIRAPI.update(path, d, function(rsp) {
        equal( rsp.status, 200, 'update network 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.uuid, 'has uuid' );
        ok( rsp.data.radix, 'has radix' );
        ok( rsp.data.radix.uuri_uuid, 'has radix uuid' );

        // check radix
        equal( rsp.data.radix.uuri_value, 'test ajax api', 'same value' );
        equal( rsp.data.radix.uuri_handle, 'anotherajaxtest', 'changed handle' );

        // continue
        done++;
        if (done == 2) start();
    });

});


/**
 * Update on invalid resource
 */
asyncTest('007 update an invalid', 1, function() {
    var path = 'user/'+AIRCURRUSER+'/network/BLAHBLAHBLAH';
    var d = {fruit: 'snacks'};

    AIRAPI.create(path, d, function(rsp) {
        equal( rsp.status, 405, 'update invalid path 405' );

        // continue
        start();
    });

});
