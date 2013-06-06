/**
 * Test running concurrent (synchronous) requests
 */
module("Concurrent (Synchronous) Requests", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.syncRequests();
    }
});


/**
 * Run all within one test
 */
asyncTest('002 sync request', 6, function() {

    // track the order the callbacks come
    var startedRequests = 0;
    var finishedRequests = 0;

    // make the first api call
    AIRAPI.query('source', {limit:1}, function(rsp) {
        finishedRequests++;

        equal( rsp.status, 200, 'req 1 - fetch 200' );
        equal( startedRequests, 2, 'req 1 - both requests have started' );
        equal( AIRAPI.getQueueCount(), 0, 'req 1 - other request NOT queued!' );
        if (finishedRequests == 1) {
            ok( true, 'req 1 - finished first' );
        }
        else {
            start(); // i'm last'
        }
    });
    startedRequests++;

    // make the second call
    AIRAPI.query('user', {limit:1}, function(rsp) {
        finishedRequests++;

        equal( rsp.status, 200, 'req 2 - fetch 200' );
        equal( startedRequests, 2, 'req 2 - both requests have started' );
        if (finishedRequests == 1) {
            ok( true, 'req 2 - finished first' );
        }
        else {
            start(); // i'm last'
        }
    });
    startedRequests++;

});
