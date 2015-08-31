Ext.namespace('AIR2.Util.Authz');


/**
 * AIR2.Util.Authz.has
 *
 * Returns true if the current user has the given action in the specified
 * organization.  Blows up if you pass an invalid ACTION.  If no org-uuid is
 * given, all organizations will be checked.
 *
 * Valid actions are defined by app/config/actions.ini
 */
AIR2.Util.Authz.has = function (action, orguuid) {
    var hasAction,
        longAction;

    if (!action || !AIR2.AUTHZ[action]) {
        Logger("INVALID ACTION: ", action);
        alert("INVALID ACTION SPECIFIED - " + action);
    }
    longAction = goog.math.Long.fromNumber(AIR2.AUTHZ[action]);

    hasAction = (AIR2.USERINFO.type === "S");
    Ext.iterate(AIR2.USERAUTHZ, function (uuid, role, obj) {
        if (orguuid && orguuid !== uuid) {
            return; // skip this one
        }

        var longRole = goog.math.Long.fromNumber(role);

        // must check explicitly for roles
        if (action.match(/^AIR2_AUTHZ_ROLE/)) {
            if (longRole.and(longAction).equals(longAction)) {
                hasAction = (orguuid === false) ? uuid : true;
                return true;
            }
        }
        else {
            if (!longAction.and(longRole).isZero()) {
                hasAction = (orguuid === false) ? uuid : true;
                return true;
            }
        }
    });
    return hasAction;
};

/**
 * AIR2.Util.Authz.isGlobalManager
 *
 * Returns Boolean indicating whether the current user has Manager authz in the Global org.
 *
 */
AIR2.Util.Authz.isGlobalManager = function() {
    return AIR2.Util.Authz.has('AIR2_AUTHZ_ROLE_M', 'ADKLm8Okenaa');
};

/**
 * AIR2.Util.Authz.hasAnyId
 *
 * Like has() but takes an array of org_ids instead of a single org_uuid.
 *
 * Valid actions are defined by app/config/actions.ini
 */
AIR2.Util.Authz.hasAnyId = function (action, org_ids) {
    var hasAction,
        longAction;

    if (!action || !AIR2.AUTHZ[action]) {
        Logger("INVALID ACTION: ", action);
        alert("INVALID ACTION SPECIFIED - " + action);
    }
    longAction = goog.math.Long.fromNumber(AIR2.AUTHZ[action]);
    hasAction = (AIR2.USERINFO.type === "S");
    Ext.iterate(AIR2.USERAUTHZ_IDS, function (oid, role, obj) {
        var i, longRole, org_id;

        for (i = 0; i < org_ids.length; i++) {
            org_id = org_ids[i];
            if (org_id && org_id !== oid) {
                continue; // skip this one
            }

            longRole = goog.math.Long.fromNumber(role);

            // must check explicitly for roles
            if (action.match(/^AIR2_AUTHZ_ROLE/)) {
                if (longRole.and(longAction).equals(longAction)) {
                    hasAction = (org_id === false) ? oid : true;
                    return true;
                }
            }
            else {
                if (!longAction.and(longRole).isZero()) {
                    hasAction = (org_id === false) ? oid : true;
                    return true;
                }
            }
        }
    });
    return hasAction;
};


/**
 * AIR2.Util.Authz.checkPwd
 *
 * Checks a password against the remote air2 login controller.  Calling this
 * function will cancel any currently pending authz.checkPwd() ajax requests.
 *
 * @param {String}   username
 * @param {String}   password
 * @param {Function} callback
 *     Will be called with the following parameters:
 *       +success {Boolean}
 *       +value   {Cookie|String}
 *           returns the authz cookie on successful remote validation;
 *           otherwise a string error message.
 */
AIR2.Util.Authz.checkPwd = function (username, password, callback) {
    // require something
    if (username.length < 1 || password.length < 1) {
        callback(false, 'Invalid username/password provided');
    }

    // abort any previous requests
    if (AIR2.Util.Authz.pwdRemoteAction) {
        Ext.Ajax.abort(AIR2.Util.Authz.pwdRemoteAction);
        AIR2.Util.Authz.pwdRemoteAction = false;
    }

    // fire the remote request
    var ajaxId = Ext.Ajax.request({
        method: 'POST',
        url: AIR2.HOMEURL + '/login.json',
        params: {username: username, password: password},
        timeout: 30000,
        scope: this,
        callback: function (opts, success, resp) {
            var data, msg, tkt;

            AIR2.Util.Authz.pwdRemoteAction = false;
            data = Ext.util.JSON.decode(resp.responseText);

            if (success && data.success) {
                tkt = data[AIR2.AUTHZCOOKIE];
                callback(true, tkt);
            }
            else {
                if (data && data.message) {
                    msg = data.message;
                }
                else {
                    msg = 'Unknown remote error';
                }
                callback(false, msg);
            }
        }
    });

    // record the remote ajaxId
    AIR2.Util.Authz.pwdRemoteAction = ajaxId;

};
