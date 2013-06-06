/**
 * Query some AIR2 resources
 */
module("QUERY stuff", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});

// known system user uuid
var AIRSYSUSER = '3fc8faac592b';

// current user - used in subsequent tests
var AIRCURRUSER = '';


/**
 * Query users
 */
asyncTest('005 query user', 16, function() {
    var done = 0;
    var p = {limit: 4};

    AIRAPI.query('user', p, function(rsp) {
        equal( rsp.status, 200, 'query 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        ok( rsp.data.success, 'has success' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( !rsp.data.uuid, 'has no uuid' );
        ok( rsp.data.radix, 'has radix' );
        ok( rsp.data.radix.length, 'has radix length' );
        equal( rsp.data.radix.length, 4, 'has radix 4' );

        // continue
        done++;
        if (done == 2) start();
    });

    p = {q: AIRCFG.username};
    AIRAPI.query('user', p, function(rsp) {
        equal( rsp.status, 200, 'query w/q 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        ok( rsp.data.success, 'has success' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( !rsp.data.uuid, 'has no uuid' );
        ok( rsp.data.radix, 'has radix' );
        ok( rsp.data.radix.length, 'has radix length' );
        equal( rsp.data.radix.length, 1, 'has radix 1' );

        // set user_uuid for future tests
        AIRCURRUSER = rsp.data.radix[0].user_uuid;

        // continue
        done++;
        if (done == 2) start();
    });

});


/**
 * Query orgs w/sorting
 */
asyncTest('005 query orgs sort', 11, function() {
    var firstInList;
    var done = 0;
    var p = {limit: 4, sort: 'org_name asc'};

    AIRAPI.query('organization', p, function(rsp) {
        equal( rsp.status, 200, 'query sort asc 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.radix, 'has radix' );
        equal( rsp.data.radix.length, 4, 'has radix 4' );

        // first one should compare firstInList
        if (firstInList) {
            var mine = rsp.data.radix[0];
            ok( firstInList.org_uuid != mine.org_uuid, 'different org_uuids' );
        }
        firstInList = rsp.data.radix[0];

        // continue
        done++;
        if (done == 2) start();
    });

    p = {limit: 2, sort: 'org_name desc'};
    AIRAPI.query('organization', p, function(rsp) {
        equal( rsp.status, 200, 'query sort desc 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.radix, 'has radix' );
        equal( rsp.data.radix.length, 2, 'has radix 2' );

        // first one should compare firstInList
        if (firstInList) {
            var mine = rsp.data.radix[0];
            ok( firstInList.org_uuid != mine.org_uuid, 'different org_uuids' );
        }
        firstInList = rsp.data.radix[0];

        // continue
        done++;
        if (done == 2) start();
    });

});


/**
 * Call query at the FETCH level
 *
 * Fetch should just ignore any parameters and return normally
 */
asyncTest('005 query FETCH', 6, function() {
    var p = {limit: 4};

    AIRAPI.query('user/'+AIRSYSUSER, p, function(rsp) {
        equal( rsp.status, 200, 'query-FETCH 200' );

        // interrogate response data
        ok( rsp.data, 'has data' );
        equal( rsp.data.code, 20, 'has code 20' );
        ok( rsp.data.uuid, 'has uuid' );
        ok( rsp.data.radix, 'has radix' );
        equal( rsp.data.radix.user_uuid, AIRSYSUSER, 'has radix flds' );

        // continue
        start();
    });

});


/**
 * Query something that doesn't exist
 */
asyncTest('005 query DNE', 1, function() {
    var p = {limit: 4};

    AIRAPI.query('user/'+AIRSYSUSER+'/penmanship', p, function(rsp) {
        equal( rsp.status, 404, 'query-FETCH 404' );

        // continue
        start();
    });

});
