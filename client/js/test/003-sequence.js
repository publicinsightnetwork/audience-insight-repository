/**
 * Test running Non-concurrent (sequenced) requests
 */
module("NON-Concurrent (Sequenced) Requests", {
    setup: function() {
        AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);
        AIRAPI.sequenceRequests();
    }
});


/**
 * Run all within one test
 */
asyncTest('003 seq request', 6, function() {

    // track the order the callbacks come
    var finishedRequests = 0;

    // make the first api call
    AIRAPI.query('source', {limit:1}, function(rsp) {
        finishedRequests++;

        equal( rsp.status, 200, 'req 1 - fetch 200' );
        equal( AIRAPI.getQueueCount(), 1, 'req 1 - other request queued!' );
        equal( finishedRequests, 1, 'req 1 - only I have finished!' );

        if (finishedRequests == 2) {
            start(); // i'm last'
        }
    });

    // make the second call
    AIRAPI.query('user', {limit:1}, function(rsp) {
        finishedRequests++;

        equal( rsp.status, 200, 'req 2 - fetch 200' );
        equal( AIRAPI.getQueueCount(), 0, 'req 2 - empty queue' );
        equal( finishedRequests, 2, 'req 2 - finished last' );

        if (finishedRequests == 2) {
            start(); // i'm last'
        }
    });

});
