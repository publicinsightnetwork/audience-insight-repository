/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

/**
 * @class AIRAPI
 *
 * Light-weight javascript adaptor for interacting with the AIR2 API.
 *
 * Declares a global AIRAPI variable, which is the singleton instance of this
 * adaptor class.  Before making any other calls, you must do an AIRAPI.init()
 * with your AIR login information.  This file is NOT intended for use in
 * public sites/applications, as anything returned from the API is authorized
 * only for the use of the logged in user.
 *
 * @author rcavis
 * @package AIRAPI
 * @version 1.0
 */
var AIRAPI = function() {

    /**
     * @private
     *
     * Internal API variables
     *
     * @property {String}  airUrl              : AIR instance location
     * @property {String}  airUsername         : AIR username
     * @property {String}  airUserpass         : AIR password
     * @property {String}  airAuthTkt          : auth-tkt for user
     * @property {String}  airAuthFailed       : msg returned on login failure
     * @property {String}  airAuthFailedText   : text returned on login failure
     * @property {Integer} airAuthFailedStatus : status returned on failure
     * @property {Boolean} rmtRunConcurrent    : allow overlapping requests
     * @property {Integer} rmtInProgress       : number of outstanding requests
     * @property {Array}   rmtQueue            : requests waiting to run
     */
    var airUrl = null;
    var airUsername = null;
    var airUserpass = null;
    var airAuthTkt = null;
    var airAuthFailed = 'No login credentials! Run init() first.';
    var airAuthFailedText = airAuthFailed;
    var airAuthFailedStatus = 0;
    var rmtRunConcurrent = true;
    var rmtInProgress = 0;
    var rmtQueue = [];


    /**
     * @private function encodeParams
     *
     * URL-encode a parameters object
     *
     * @param  {Object} obj     : the object to stringify
     * @return {String} encoded : string representation of obj
     */
    var encodeParams = function(obj) {
        var s = '';
        for (var key in obj) {
            s += (s.length == 0) ? '' : '&';
            s += encodeURI(key) + '=' + encodeURIComponent(obj[key]);
        }
        return s;
    };


    /**
     * @private function formatServerResponse
     *
     * Create a standardized response object for any XHR request
     *
     * @param  {XmlHttpRequest} oXHR     : object we want to format
     * @return {Object}         response : normalized and decoded response
     */
    var formatServerResponse = function(oXHR) {
        var obj = {
            status:  oXHR.status,
            text:    oXHR.statusText,
            success: (oXHR.status === 200),
            message: oXHR.statusText,
            raw:     oXHR.responseText,
            data:    null
        };

        // attempt json decode
        try {
            obj.data = JSON.parse(oXHR.responseText);
            if (obj.data && obj.data.message) {
                obj.message = obj.data.message;
            }
        }
        catch (err) {
            console.warn('Json decode error:', err);
        }

        // resource not found errors
        if (!obj.status) {
            obj.status = 0;
            obj.text = 'Resource not found';
            obj.success = false;
            obj.message = 'Invalid request URI';
        }
        return obj;
    }


    /**
     * @private function doRemoteRequest
     *
     * Helper to make XHR requests.  Should not be called directly... only
     * by the popRequest() method.
     *
     * @param {String}   path     : the relative path to request
     * @param {String}   method   : HTTP Method to use
     * @param {Object}   params   : parameters for POST/PUT/GET
     * @param {Function} callback : function to call with the response object
     * @param {Object}   scope    : scope for callback
     */
    var doRemoteRequest = function(path, method, params, callback, scope) {
        params = params ? params : {};
        params['x-tunneled-method'] = method.toUpperCase(); //tunnel it!
        if (airAuthTkt) params['air2_tkt'] = airAuthTkt;

        // make xhr request
        var myXHR = new XMLHttpRequest();
        myXHR.open('POST', airUrl+path, true);
        myXHR.setRequestHeader('Accept', 'application/json');
        myXHR.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        myXHR.onreadystatechange = function() {
            if (myXHR.readyState === 4) {
                if (callback) {
                    var rspObj = formatServerResponse(myXHR);
                    callback.call(scope ? scope : this, rspObj);
                }
                rmtInProgress--;
                popRequest();
            }
        };
        myXHR.send(encodeParams(params));
        rmtInProgress++;
    }


    /**
     * @private function getAuthTkt
     *
     * Request the auth-tkt from the server
     *
     * @param {Function} callback : function to call with the response object
     * @param {Object}   scope    : scope for callback
     */
    var getAuthTkt = function(callback, scope) {
        var params = {
            admin: 1,
            username: airUsername,
            password: airUserpass
        };
        doRemoteRequest('login.json', 'POST', params, function(rsp) {
            if (rsp.success && rsp.data.air2_tkt) {
                airAuthTkt = rsp.data.air2_tkt;
                delete airUserpass;
            }
            else {
                airAuthFailed = rsp.message; // credentials failed!
                airAuthFailedStatus = rsp.status;
                airAuthFailedText = rsp.text;
                delete airUserpass;
            }
            if (callback) {
                callback.call(scope ? scope : this, rsp);
            }
        });
    }


    /**
     * @private function queueRequest
     *
     * Queue an API request
     *
     * @param  {String}   path     : the relative air resource path
     * @param  {String}   method   : GET|POST|PUT|DELETE
     * @param  {Object}   params   : key value pairs of parameters
     * @param  {Function} callback : called with response object
     * @param  {Object}   scope    : scope of callback (optional)
     */
    var queueRequest = function(path, method, params, callback, scope) {
        rmtQueue.push(arguments);
        popRequest();
    }


    /**
     * @private function popRequest
     *
     * Run queued requests
     *
     */
    var popRequest = function() {
        if (rmtQueue.length == 0) return;

        // if the login failed, just return an error
        if (airAuthFailed) {
            var next = rmtQueue.shift();
            if (next && next.length > 3 && next[3]) {
                next[3]({
                    status:  airAuthFailedStatus,
                    text:    airAuthFailedText,
                    success: false,
                    message: airAuthFailed,
                    raw:     null,
                    data:    null
                });
            }
            popRequest(); //next!
        }

        // login in-progress
        else if (!airAuthFailed && !airAuthTkt) {
            //no-op
        }

        // logged in, but queueing requests
        else if (airAuthTkt && !rmtRunConcurrent) {
            if (rmtInProgress == 0) {
                doRemoteRequest.apply(this, rmtQueue.shift());
            }
        }

        // logged in, concurrent requests
        else if (airAuthTkt && rmtRunConcurrent) {
            doRemoteRequest.apply(this, rmtQueue.shift());
            popRequest(); //next!
        }
    }


    // Public methods
    return {
        /**
         * @public function init
         *
         * Starting point for API.  Should be called before attempting any
         * remote requests.  Any requests you make before the API can log in
         * will be queued and run afterwards.
         *
         * @param {String}   url            : Location of the AIR instance
         * @param {String}   username       : AIR username
         * @param {String}   password       : AIR password
         * @param {Function} callback (opt) : called with (success, msg)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        init: function(url, username, password, callback, scope) {
            url = url.match(/\/$/) ? url : url+'/';

            // only reset if something changed
            if (url != airUrl || username != airUsername || password != airUserpass) {
                AIRAPI.reset();
                airAuthFailed = false;
                airUrl = url;
                airUsername = username;
                airUserpass = password;
                getAuthTkt(callback, scope);
            }
        },
        /**
         * @public function reset
         *
         * Reset the API, dumping any outstanding requests, deleting any held
         * authorization and user login info.  Must be followed by an init()
         * call to get the API working again.
         *
         */
        reset: function() {
            airUrl = null;
            airUsername = null;
            airUserpass = null;
            airAuthTkt = null;
            airAuthFailed = 'No login credentials! Run init() first.';
            airAuthFailedText = airAuthFailed;
            airAuthFailedStatus = 0;
            rmtRunConcurrent = true;
        },
        /**
         * @public function syncRequests
         *
         * Allow requests to overlap as they are run.  Callbacks may come in
         * any order.  This is the default operating mode.  (Except for the
         * initial login request, which blocks any other requests until it
         * finishes).
         */
        syncRequests: function() {
            rmtRunConcurrent = true;
            popRequest();
        },
        /**
         * @public function sequenceRequests
         *
         * Force all subsequent requests to run in sequence.  Requests will be
         * run 1-at-a-time with no overlap.
         */
        sequenceRequests: function() {
            rmtRunConcurrent = false;
        },
        /**
         * @public function getQueueCount
         *
         * Determine the number of requests that have not been run yet.
         * (They're probably waiting on either login or a sequenced request).
         *
         * @return {Integer} length : the number of queued requests
         */
        getQueueCount: function() {
            return rmtQueue.length;
        },
        /**
         * @public function fetch
         *
         * Fetch a resource from AIR
         *
         * @param {String}   path           : relative path to the resource
         * @param {Function} callback (opt) : called with (rspObj)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        fetch: function(path, callback, scope) {
            queueRequest(path, 'GET', null, callback, scope);
        },
        /**
         * @public function query
         *
         * Query resources from AIR
         *
         * @param {String}   path           : relative path to the resource
         * @param {Object}   args           : arguments in the query
         * @param {Function} callback (opt) : called with (rspObj)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        query: function(path, args, callback, scope) {
            queueRequest(path, 'GET', args, callback, scope);
        },
        /**
         * @public function create
         *
         * Create an AIR resource
         *
         * @param {String}   path           : relative path to the resource
         * @param {Object}   data           : data to create resource
         * @param {Function} callback (opt) : called with (rspObj)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        create: function(path, data, callback, scope) {
            queueRequest(path, 'POST', {radix: JSON.stringify(data)}, callback, scope);
        },
        /**
         * @public function update
         *
         * Update a resource in AIR
         *
         * @param {String}   path           : relative path to the resource
         * @param {Object}   args           : data to modify resource
         * @param {Function} callback (opt) : called with (rspObj)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        update: function(path, data, callback, scope) {
            queueRequest(path, 'PUT', {radix: JSON.stringify(data)}, callback, scope);
        },
        /**
         * @public function remove
         *
         * Delete a resource from AIR (the word 'delete' is reserved in js)
         *
         * @param {String}   path           : relative path to the resource
         * @param {Function} callback (opt) : called with (rspObj)
         * @param {Object}   scope    (opt) : scope to use on callback
         */
        remove: function(path, callback, scope) {
            queueRequest(path, 'DELETE', null, callback, scope);
        }
    };
}();
