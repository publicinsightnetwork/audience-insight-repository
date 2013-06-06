Ext.ns('AIR2.Util.Console');
/***************
 * AIR2 Console Logging Utility
 *
 * Sets up the global "Logger" variable to be cross-browser compatible.
 *
 * NOTES: firebug logger may not be installed, safari has its own console at
 * window.console.
 *
 */
if (!AIR2.Util.Console.log) {
    if (!AIR2.DEBUG) {
        AIR2.Util.Console.log = function () {}; // a no-op. be quiet.
    }
    else if (typeof console !== 'undefined') {
        if (window.console && !console.debug) {
            // safari
            //alert("window.console is defined");
            AIR2.Util.Console.log = function () {
                window.console.log(arguments[0]);
            };
        }
        else if (console.debug) {
            AIR2.Util.Console.log = function () {
                console.log.apply(console, arguments);
            };
        }
        else {
            //alert("no window.console or console.debug");
            AIR2.Util.Console.log = function () { }; // no-op
        }
        AIR2.Util.Console.log("console logger ok");
    }
    else if (Ext.isIE) {
        //AIR2.Util.Console.log = function () {} // no-op
        // IE console based on /* Faux Console by Chris Heilmann
        // http://wait-till-i.com */
        AIR2.Util.Console.logger = {
            init: function () {
                /*jshint scripturl:true*/
                var a, console, id;

                console = AIR2.Util.Console.logger;
                //alert("init logger");
                console.d = document.createElement('div');
                document.body.appendChild(console.d);
                a = document.createElement('a');
                a.href = 'javascript:AIR2.Util.Console.logger.hide()';
                a.innerHTML = 'close';
                console.d.appendChild(a);
                a = document.createElement('a');
                a.href = 'javascript:AIR2.Util.Console.logger.clear();';
                a.innerHTML = 'clear';
                console.d.appendChild(a);
                id = 'fauxconsole';
                if (!document.getElementById(id)) {
                    console.d.id = id;
                }
                console.hide();
                //alert("init done");
            },
            hide: function () {
                AIR2.Util.Console.logger.d.style.display = 'none';
            },
            show: function () {
                AIR2.Util.Console.logger.d.style.display = 'block';
            },
            log: function (o) {
                var console = AIR2.Util.Console.logger;
                if (!console.d) {
                    //alert("console not ready");
                    if (!document.body) {
                        //alert("document.body not ready");
                        return;
                    }
                    console.init();
                }
                if (typeof o === "object") {
                    //alert("arg is an object");
                    try {
                        o = Ext.util.JSON.encode(o);
                    } catch (e) {
                        // TODO?
                    }
                }
                console.d.innerHTML += '<br/>' + o;
                console.show();
            },
            clear: function () {
                var console = AIR2.Util.Console.logger;
                console.d.parentNode.removeChild(console.d);
                console.init();
                console.show();
            }
        };
        AIR2.Util.Console.log = function (stuff) {
            AIR2.Util.Console.logger.log(stuff);
        };
        Ext.onReady(function () { AIR2.Util.Console.logger.init(); });
    }
    else {
        AIR2.Util.Console.log = function () {}; // no-op
    }
}

// global shortcut
var Logger = AIR2.Util.Console.log;
