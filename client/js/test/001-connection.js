/**
 * Tests to make sure we can get a valid AIR2 ticket
 */
module("Connection Tests");


/**
 * calling api before init()
 */
asyncTest('001 no init()', 2, function() {

    AIRAPI.reset();
    AIRAPI.fetch('user/1234', function(rsp) {
        equal( rsp.status, 0, 'fetch 0' );
        ok( rsp.text.match(/no login credentials/i), 'fetch text match' );

        start();
    });

});


/**
 * use an invalid login - expect 401 from any api calls
 */
asyncTest('001 bad password', 2, function() {

    AIRAPI.reset();
    AIRAPI.init(AIRCFG.instance, AIRCFG.username, 'fakepass');

    AIRAPI.fetch('user/1234', function(rsp) {
        equal( rsp.status, 401, 'fetch 401' );
        ok( rsp.text.match(/authorization required/i), 'fetch text match' );

        start();
    });

});


/**
 * use an invalid instance - expect 404 from any api calls
 */
asyncTest('001 bad instance', 2, function() {

    AIRAPI.reset();
    var fakeurl = 'https://thisisnotarealairurl.com/air2';
    AIRAPI.init(fakeurl, AIRCFG.username, 'fakepass');

    AIRAPI.fetch('user/1234', function(rsp) {
        equal( rsp.status, 0, 'fetch 0' );
        ok( rsp.text.match(/not found/i), 'fetch text match' );

        start();
    });

});


/**
 * use valid login - expect 404 from DNE api call
 */
asyncTest('001 good password', 1, function() {

    AIRAPI.reset();
    AIRAPI.init(AIRCFG.instance, AIRCFG.username, AIRCFG.password);

    AIRAPI.fetch('user/1234', function(rsp) {
        equal( rsp.status, 404, 'fetch 404' );

        start();
    });

});
