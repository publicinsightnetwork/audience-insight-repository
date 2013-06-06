/**
 * Create AIR2 resources
 *
 * AIRCURRUSER constant should be set by 005
 */
module("CREATE stuff", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});

// record networks created
AIRNETWORKUUID = '';


/**
 * Create network object
 */
asyncTest('006 create network', 9, function() {
    var done = 0;
    var path = 'user/'+AIRCURRUSER+'/network';
    var d = {uuri_handle: 'ajaxtest'};

    // no uuri_value == invalid
    AIRAPI.create(path, d, function(rsp) {
        equal( rsp.status, 400, 'create missing data 400' );

        // continue
        done++;
        if (done == 2) start();
    });

    // set all fields
    d = {uuri_handle: 'ajaxtest', uuri_value: 'test ajax api'};
    AIRAPI.create(path, d, function(rsp) {
        equal( rsp.status, 200, 'create network 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.uuid, 'has uuid' );
        ok( rsp.data.radix, 'has radix' );
        ok( rsp.data.radix.uuri_uuid, 'has radix uuid' );

        // check radix
        equal( rsp.data.radix.uuri_value, 'test ajax api', 'same value' );
        equal( rsp.data.radix.uuri_handle, 'ajaxtest', 'same handle' );

        // set for future tests
        AIRNETWORKUUID = rsp.data.uuid;

        // continue
        done++;
        if (done == 2) start();
    });

});


/**
 * Create on invalid resource
 */
asyncTest('006 create invalid', 1, function() {
    var path = 'user/'+AIRCURRUSER+'/woolensock';
    var d = {somehow: 'somewhere'};

    AIRAPI.create(path, d, function(rsp) {
        equal( rsp.status, 404, 'create invalid path 404' );

        // continue
        start();
    });

});
