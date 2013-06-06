Ext.namespace('AIR2.Util.User');

/*
  Fetch a User object for a user_uuid, caching it with memo pattern,
  and update a target id with output of Format.userName.
 */

// browser-side cache of User objects
AIR2.Util.User.CACHE = {};
AIR2.Util.User.INPROGRESS = {};
AIR2.Util.User.ME_TOO = {}; // cache of targetIds to update on ajax return

AIR2.Util.User.fetchLink = function (uuid, returnLink, flip, targetId) {
    if (typeof uuid === 'undefined' || uuid === 'undefined') {
        throw new Ext.Error("undefined uuid");
    }
    // if already in our cache, return immediately
    if (Ext.isDefined(AIR2.Util.User.CACHE[uuid])) {
        //Logger("found user_uuid " + uuid + " in cache");
        return AIR2.Format.userName(
            AIR2.Util.User.CACHE[uuid],
            returnLink,
            flip
        );
    }

    // optimization for current USER
    if (
        Ext.isDefined(AIR2.Reader.USER) &&
        AIR2.Reader.USER.user_uuid === uuid
    ) {
        AIR2.Util.User.CACHE[uuid] = AIR2.Reader.USER;
        return AIR2.Format.userName(
            AIR2.Util.User.CACHE[uuid],
            returnLink,
            flip
        );
    }
    // TODO optimize for AIR2.USERINFO too

    // otherwise, fetch, and return null to indicate targetId will be
    // filled sometime in the future
    if (AIR2.Util.User.INPROGRESS[uuid]) {
        if (AIR2.Util.User.INPROGRESS[uuid] === targetId) {
            return null;
        }
        else {
            // cache this targetId to update it
            // with same user info when inprogress targetId is updated
            AIR2.Util.User.ME_TOO[
                AIR2.Util.User.INPROGRESS[uuid]
            ].push(targetId);
            return null;
        }
    }

    AIR2.Util.User.INPROGRESS[uuid] = targetId;

    // cache of other targets needing update
    AIR2.Util.User.ME_TOO[targetId] = [];
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/user/' + uuid + '.json',
        failure: function () {
            Logger('fail to fetch User ' + uuid);
        },
        callback: function (opt, success, response) {
            var el, json, user;

            json = Ext.decode(response.responseText);
            user = json.radix;
            AIR2.Util.User.CACHE[uuid] = user; // cache for next time
            delete AIR2.Util.User.INPROGRESS[uuid]; // no longer in progress
            //Logger(user);
            el = Ext.get(targetId);
            el.dom.innerHTML = AIR2.Format.userName(user, returnLink, flip);

            // do any others
            Ext.each(AIR2.Util.User.ME_TOO[targetId], function (tid) {
                var el = Ext.get(tid);
                el.dom.innerHTML = AIR2.Format.userName(user, returnLink, flip);
            });
        }
    });
    return null;
};
