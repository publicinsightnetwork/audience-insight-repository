/***************
 * Column definitions for the reader inbox.  The layout of the MENU
 * stays constant as the application runs, but the COLUMNS can change
 * parameters and order as the user interacts with them.
 *
 * Note that uid's must NEVER change for that column, since they're
 * used in the cookie to indicate ordering.
 */
AIR2.Reader.MENU = [{
    section: 'Submission',
    iconCls: 'air2-icon-response',
    items: {
        live_favorite:      'Insightful',
        permission_granted: 'Permission',
        publish_state:      'Public',
        score:              'Score',
        srs_date:           'Received',
        inq_ext_title_lc:   'Query',
        org_name:           'Organization',
        prj_display_name:   'Project'
    }
}, {
    section: 'Source',
    iconCls: 'air2-icon-source',
    items: {
        src_first_name_lc:   'First Name',
        src_last_name_lc:    'Last Name',
        src_status:          'Status',
        primary_email:       'Email',
        primary_phone:       'Phone',
        primary_city_lc:     'City',
        primary_state:       'State',
        primary_zip:         'Postal Code',
        primary_county:      'County',
        primary_country:     'Country',
        primary_org_name_lc: 'Home Org'
    }
}, {
    section: 'Demographics',
    iconCls: 'air2-icon-fact',
    items: {
        birth_year:                 'Birth Year',
        education_level_seq:        'Education',
        ethnicity_lc:               'Ethnicity',
        gender_lc:                  'Gender',
        household_income_seq:       'Income',
        political_affiliation_seq:  'Political',
        religion_lc:                'Religion'
    }
}];
AIR2.Reader.COLUMNS = {
    live_favorite: {
        header:   '<img src="' + AIR2.HOMEURL +
            '/css/img/icons/star-empty.png" alt="unstarred" ' +
            'ext:qtip="Insightful"/>',
        cls:      'starred',
        format:   '<a class="mark-fav {[values.live_favorite ? "fav" : ""]}" ' +
            'ext:qtip="{[values.live_favorite ? "Insightful" : ' +
            '"Mark as Insightful"]}"></a>',
        // sortable: 'desc',
        uid:      'g'
    },
    publish_state: {
        header:   'Public',
        cls:      'public',
        format:   function (values) {
            var display, iconClass, publish_state, title;

            publish_state = values.publish_state;
            display = '<span id="publish-state-' + values.srs_uuid;
            display += '" class="air2-icon ';
            title = AIR2.Reader.CONSTANTS.UNPUBLISHABLE_TITLE;
            iconClass = "air2-icon-prohibited-disabled";
            if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                iconClass = "public-state air2-icon-check";
                title = AIR2.Reader.CONSTANTS.PUBLISHED_TITLE;
            }
            else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                iconClass = "public-state air2-icon-uncheck";
                title = AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE;
            }
            else if (
                publish_state == AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH
            ) {
                iconClass = "air2-icon-uncheck-disabled";
                title = AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH_TITLE;
            }
            else if (
                publish_state == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
            ) {
                iconClass = "scroll-to-permission air2-icon-lock";
                title = AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE_TITLE;
            }
            // undo title if no authz
            if (
                !AIR2.Util.Authz.hasAnyId(
                    'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                    values.qa[0].owner_orgs.split(',')
                )
            ) {
                title = 'You do not have permission to change status.';
            }
            display += iconClass + '" ext:qtip="' + title + '"></span>';
            return display;
        },
        sortable: 'desc',
        uid:      'x'
    },
    permission_granted: {
        header:   'Permission',
        cls:      'permission',
        format:   function (values) {
            return '<span id="permission-' + values.srs_uuid + '">' +
                values.permission_granted + '</span>';
        },
        sortable: 'desc',
        uid:      'h'
    },
    score: {
        header:   '<span>#</span>',
        cls:      'score',
        format:   '{score}',
        sortable: 'desc',
        uid:      '0'
    },
    src_first_name_lc: {
        header:   'First Name',
        cls:      'first-name',
        format:   '{src_first_name}',
        sortable: 'asc',
        uid:      'a'
    },
    src_last_name_lc: {
        header:   'Last Name',
        cls:      'last-name',
        format:   '{src_last_name}',
        sortable: 'asc',
        uid:      'b'
    },
    src_status: {
        header:   'Status',
        cls:      'status',
        format:   '{src_status}',
        sortable: 'asc',
        uid:      'S'
    },
    primary_email: {
        header:   'Email',
        cls:      'email',
        format:   '{[values.primary_email_html.replace(/:[A-Z]$/, "")]}',
        sortable: 'asc',
        uid:      'v'
    },
    primary_phone: {
        header:   'Phone',
        cls:      'phone',
        format:   '{primary_phone}',
        sortable: 'asc',
        uid:      'w'
    },
    primary_city_lc: {
        header:   'City',
        cls:      'city',
        format:   '{primary_city}',
        sortable: 'asc',
        uid:      'c'
    },
    primary_state: {
        header:   'State',
        cls:      'state',
        format:   '{primary_state}',
        sortable: 'asc',
        uid:      'd'
    },
    primary_zip: {
        header:   'Postal Code',
        cls:      'postal',
        format:   '{primary_zip}',
        sortable: 'asc',
        uid:      'e'
    },
    primary_county: {
        header:   'County',
        cls:      'county',
        format:   '{primary_county}',
        sortable: 'asc',
        uid:      't'
    },
    primary_country: {
        header:   'Country',
        cls:      'country',
        format:   '{primary_country}',
        sortable: 'asc',
        uid:      'u'
    },
    primary_org_name_lc: {
        header:   'Home Org',
        cls:      'home-org',
        format:   '{primary_org_name}',
        sortable: 'asc',
        uid:      'f'
    },
    srs_date: {
        header:   'Received',
        cls:      'received',
        format:   '{srs_date:air.dateHuman(true)}',
        sortable: 'desc',
        uid:      'i'
    },
    inq_ext_title_lc: {
        header:   'Query',
        cls:      'query',
        format:   '{.:air.inquiryTitle(1, 40)}',
        sortable: 'asc',
        uid:      'j'
    },
    org_name: {
        header:   'Organization',
        cls:      'organization',
        format:   function (values) {
            var color, i, name, obj, out, uuid;

            if (!values.inq_org_name) {
                return '';
            }

            name = values.inq_org_name.split('\003');
            uuid = values.inq_org_uuid.split('\003');
            color = values.inq_org_html_color.split('\003');
            out = [];
            for (i = 0; i < name.length; i++) {
                obj = {
                    org_uuid: uuid[i],
                    org_name: name[i],
                    org_html_color: color[i]
                };
                out.push(AIR2.Format.orgName(obj, true));
            }
            return out.join(''); //pills have margins
        },
        sortable: 'asc',
        uid:      'k'
    },
    prj_display_name: {
        header:   'Project',
        cls:      'project',
        format:   function (values) {
            var disp, i, obj, out, uuid;

            if (!values.prj_display_name) {
                return '';
            }
            disp = values.prj_display_name.split('\003');
            uuid = values.prj_uuid.split('\003');
            out = [];
            for (i = 0; i < disp.length; i++) {
                obj = {prj_display_name: disp[i], prj_uuid: uuid[i]};
                out.push(AIR2.Format.projectName(obj, true));
            }
            return out.join(', ');
        },
        sortable: 'asc',
        uid:      'l'
    },
    birth_year: {
        header:   'Birth Year',
        cls:      'birth-year',
        format:   '{birth_year}',
        sortable: 'asc',
        uid:      'm'
    },
    education_level_seq: {
        header:   'Education',
        cls:      'education',
        format:   '{education_level}',
        sortable: 'asc',
        uid:      'n'
    },
    ethnicity_lc: {
        header:   'Ethnicity',
        cls:      'ethnicity',
        format:   '{ethnicity}',
        sortable: 'asc',
        uid:      'o'
    },
    gender_lc: {
        header:   'Gender',
        cls:      'gender',
        format:   '{gender}',
        sortable: 'asc',
        uid:      'p'
    },
    household_income_seq: {
        header:   'Income',
        cls:      'income',
        format:   function (values) {
            return AIR2.Format.householdIncome(values.household_income);
        },
        sortable: 'asc',
        uid:      'q'
    },
    political_affiliation_seq: {
        header:   'Political',
        cls:      'political',
        format:   '{political_affiliation}',
        sortable: 'asc',
        uid:      'r'
    },
    religion_lc: {
        header:   'Religion',
        cls:      'religion',
        format:   '{religion}',
        sortable: 'asc',
        uid:      's'
    }
};

// helper for cookie state
AIR2.Reader.STATE = (function () {
    var ckname, data;

    ckname = 'air2_reader_state';
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
AIR2.Reader.visColumns = null;
AIR2.Reader.cookieKey = null;

// helper functions to get/set column states
AIR2.Reader.getVisible = function () {
    var cols, i, iterator, parts;

    // initialize
    if (AIR2.Reader.visColumns === null) {
        if (AIR2.Reader.INQUIRY) {
            AIR2.Reader.visColumns = 'ghabcdei';
        }
        else {
            AIR2.Reader.visColumns = 'gh0abcdej';
        }

        if (AIR2.Reader.INQUIRY) {
            AIR2.Reader.cookieKey = 'query';
        }
        else {
            AIR2.Reader.cookieKey = 'default';
        }

        if (AIR2.Reader.STATE.get(AIR2.Reader.cookieKey)) {
            AIR2.Reader.visColumns = AIR2.Reader.STATE.get(
                AIR2.Reader.cookieKey
            );
        }
    }

    // decode
    parts = AIR2.Reader.visColumns.split('');
    cols = [];

    iterator = function (part) {
        Ext.iterate(AIR2.Reader.COLUMNS, function (fld, def) {
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
AIR2.Reader.isVisible = function (fld) {
    var uid = AIR2.Reader.COLUMNS[fld].uid;
    return AIR2.Reader.visColumns.indexOf(uid) > -1;
};
AIR2.Reader.setVisible = function (fld, isVisible) {
    var added, foundSelf, i, uid;

    uid = AIR2.Reader.COLUMNS[fld].uid;
    if (uid && isVisible && !AIR2.Reader.isVisible(fld)) {
        added = false;
        foundSelf = false;

        // find something after self and insert before it
        Ext.iterate(AIR2.Reader.COLUMNS, function (f, def) {
            var i;

            if (f === fld) {
                foundSelf = true;
            }
            else if (foundSelf && AIR2.Reader.isVisible(f)) {
                i = AIR2.Reader.visColumns.indexOf(AIR2.Reader.COLUMNS[f].uid);
                AIR2.Reader.visColumns = AIR2.Reader.visColumns.substr(0, i) +
                    uid + AIR2.Reader.visColumns.substr(i);
                added = true;
                return false; //break
            }
        });
        if (!added) {
            AIR2.Reader.visColumns = AIR2.Reader.visColumns + uid;
        }
        AIR2.Reader.STATE.set(AIR2.Reader.cookieKey, AIR2.Reader.visColumns);
    }
    else if (uid && !isVisible && AIR2.Reader.isVisible(fld)) {
        i = AIR2.Reader.visColumns.indexOf(uid);
        AIR2.Reader.visColumns = AIR2.Reader.visColumns.substr(0, i) +
            AIR2.Reader.visColumns.substr(i + 1);
        AIR2.Reader.STATE.set(AIR2.Reader.cookieKey, AIR2.Reader.visColumns);
    }
};
