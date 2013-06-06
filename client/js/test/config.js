/***************
 * AIRAPI Test Instance configuration
 *
 * This script attempts to get an air username/password/instance, checking in:
 * 1) this file
 * 2) URL ? parameter
 * 3) URL # parameter
 *
 */
var AIRCFG = {
    username: '',
    password: '',
    instance: '',
    // get query strings IMMEDIATELY!
    qstrings: function() {
        var qobj = {}, q = window.location.search.substring(1);
        var parts = q.split('&');
        for (var i=0; i<parts.length; i++) {
            var keyval = parts[i].split('=');
            if (keyval.length == 2) {
                qobj[keyval[0]] = keyval[1];
            }
        }
        return qobj;
    } (),
    // get anchor strings IMMEDIATELY!
    astrings: function() {
        var aobj = {}, q = window.location.hash.substring(1);
        var parts = q.split('&');
        for (var i=0; i<parts.length; i++) {
            var keyval = parts[i].split('=');
            if (keyval.length == 2) {
                aobj[keyval[0]] = keyval[1];
            }
        }
        return aobj;
    } ()
}

// look through vars
if (!AIRCFG.username && AIRCFG.qstrings.username) {
    AIRCFG.username = AIRCFG.qstrings.username;
}
if (!AIRCFG.username && AIRCFG.astrings.username) {
    AIRCFG.username = AIRCFG.astrings.username;
}
if (!AIRCFG.password && AIRCFG.qstrings.password) {
    AIRCFG.password = AIRCFG.qstrings.password;
}
if (!AIRCFG.password && AIRCFG.astrings.password) {
    AIRCFG.password = AIRCFG.astrings.password;
}
if (!AIRCFG.instance && AIRCFG.qstrings.instance) {
    AIRCFG.instance = AIRCFG.qstrings.instance;
}
if (!AIRCFG.instance && AIRCFG.astrings.instance) {
    AIRCFG.instance = AIRCFG.astrings.instance;
}

// attempt to DIE if we don't have all 3
if (!AIRCFG.username || !AIRCFG.password || !AIRCFG.instance) {
    var msg = 'You MUST provide a valid AIR2 username, password, and instance'
        + ' in order for these tests to run! Please supply these in either'
        + ' the test URL, or airconfig.js.';
    alert(msg);
    if (console && console.error) console.error(msg);
    throw new Error(msg);
}
