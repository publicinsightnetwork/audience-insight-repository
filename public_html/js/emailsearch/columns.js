/***************
 * Column definitions for the email search page.
 */
AIR2.Email.MENU = {
    // text columns
    email_campaign_name: 'Internal Name',
    email_subject_line:  'Subject Line',
    email_headline:      'Headline',
    org_name:            'Organization',
    owner_first:         'Owner',
    // metadata
    email_type:          'Type',
    email_status:        'Status',
    // timestamps
    email_cre_dtim:      'Created',
    email_upd_dtim:      'Updated',
    first_exported_dtim: 'Sent at',
    email_schedule_dtim: 'Scheduled'
};
AIR2.Email.COLUMNS = {
    // text columns
    email_campaign_name: {
        header:   'Internal Name',
        cls:      'internalname',
        format:   function(v) { return AIR2.Format.emailName(v, 1, 30); },
        sortable: 'asc',
        uid:      'n'
    },
    email_subject_line: {
        header:   'Subject Line',
        cls:      'subjectline',
        format:   '{email_subject_line:ellipsis(30)}',
        sortable: 'asc',
        uid:      'o'
    },
    email_headline: {
        header:   'Headline',
        cls:      'headline',
        format:   '{email_headline:ellipsis(30)}',
        sortable: 'asc',
        uid:      'p'
    },
    org_name: {
        header:   'Organization',
        cls:      'organization',
        format:   function(v) { return AIR2.Format.orgName(v.Organization,1); },
        sortable: 'asc',
        uid:      'q'
    },
    owner_first: {
        header:   'Owner',
        cls:      'owner',
        format:   function(v) { return AIR2.Format.userName(v.CreUser,1,1); },
        sortable: 'asc',
        uid:      'r'
    },
    // metadata
    email_type: {
        header:   'Type',
        cls:      'type',
        format:   function(v) { return AIR2.Format.emailType(v); },
        sortable: false,
        uid:      'g'
    },
    email_status: {
        header:   'Status',
        cls:      'status',
        format:   function(v) { return AIR2.Format.emailStatus(v); },
        sortable: false,
        uid:      'h'
    },
    // timestamps
    email_cre_dtim: {
        header:   'Created',
        cls:      'created',
        format:   '{email_cre_dtim:air.date}',
        sortable: 'desc',
        uid:      'a'
    },
    email_upd_dtim: {
        header:   'Updated',
        cls:      'updated',
        format:   '{email_upd_dtim:air.date}',
        sortable: 'desc',
        uid:      'b'
    },
    first_exported_dtim: {
        header:   'Sent at',
        cls:      'sentat',
        format:   '{first_exported_dtim:air.dateHuman(true)}',
        sortable: 'desc',
        uid:      'c'
    },
    email_schedule_dtim: {
        header:   'Scheduled',
        cls:      'scheduled',
        format:   '{email_schedule_dtim:air.dateHuman(true)}',
        sortable: 'desc',
        uid:      'd'
    }
};

// helper for cookie state
AIR2.Email.STATE = (function () {
    var ckname, data;

    ckname = 'air2_email_state';
    data = Ext.util.Cookies.get(ckname);
    data = (data) ? Ext.decode(data) : null;
    if (!data) {
        Ext.util.Cookies.clear(ckname);
        data = {};
    }
    return {
        set: function (name, value) {
            data[name] = value;
            Ext.util.Cookies.set(ckname, Ext.encode(data));
        },
        get: function (name) {
            return data[name];
        }
    };
}());

// default visible columns (defined at runtime)
AIR2.Email.visColumns = null;
AIR2.Email.cookieKey = null;

// helper functions to get/set column states
AIR2.Email.getVisible = function () {
    var cols, i, iterator, parts;

    // initialize
    if (AIR2.Email.visColumns === null) {
        AIR2.Email.visColumns = 'nqrgha';
        AIR2.Email.cookieKey  = 'default';
        if (AIR2.Email.STATE.get(AIR2.Email.cookieKey)) {
            AIR2.Email.visColumns = AIR2.Email.STATE.get(AIR2.Email.cookieKey);
        }
    }

    // decode
    parts = AIR2.Email.visColumns.split('');
    cols = [];

    iterator = function (part) {
        Ext.iterate(AIR2.Email.COLUMNS, function (fld, def) {
            if (def.uid === part) {
                def.field = fld;
                cols.push(def);
                return false; // break
            }
        });
    };

    for (i = 0; i < parts.length; i++) {
        iterator(parts[i]);
    }
    return cols;
};
AIR2.Email.isVisible = function (fld) {
    var uid = AIR2.Email.COLUMNS[fld].uid;
    return AIR2.Email.visColumns.indexOf(uid) > -1;
};
AIR2.Email.setVisible = function (fld, isVisible) {
    var added, foundSelf, i, uid;

    uid = AIR2.Email.COLUMNS[fld].uid;
    if (uid && isVisible && !AIR2.Email.isVisible(fld)) {
        added = false;
        foundSelf = false;

        // find something after self and insert before it
        Ext.iterate(AIR2.Email.COLUMNS, function (f, def) {
            var i;

            if (f === fld) {
                foundSelf = true;
            }
            else if (foundSelf && AIR2.Email.isVisible(f)) {
                i = AIR2.Email.visColumns.indexOf(AIR2.Email.COLUMNS[f].uid);
                AIR2.Email.visColumns = AIR2.Email.visColumns.substr(0, i) +
                    uid + AIR2.Email.visColumns.substr(i);
                added = true;
                return false; //break
            }
        });
        if (!added) {
            AIR2.Email.visColumns = AIR2.Email.visColumns + uid;
        }
        AIR2.Email.STATE.set(AIR2.Email.cookieKey, AIR2.Email.visColumns);
    }
    else if (uid && !isVisible && AIR2.Email.isVisible(fld)) {
        i = AIR2.Email.visColumns.indexOf(uid);
        AIR2.Email.visColumns = AIR2.Email.visColumns.substr(0, i) +
            AIR2.Email.visColumns.substr(i + 1);
        AIR2.Email.STATE.set(AIR2.Email.cookieKey, AIR2.Email.visColumns);
    }
};
