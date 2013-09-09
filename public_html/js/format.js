Ext.namespace('AIR2.Format');
/**
 * AIR2.Format
 * Location for Ext.XTemplate formatting functions
 */

/* helper function to optionally create links */
AIR2.Format.createLink = function (text, href, isLinkCls, absLink) {
    var cls, linkTo;

    if (isLinkCls) {
        cls = (Ext.isString(isLinkCls)) ? ' class="' + isLinkCls + '"' : '';
        linkTo = absLink ? href : AIR2.HOMEURL + href;

        return '<a href="' + linkTo + '"' + cls + '>' + text + '</a>';
    }
    else {
        return text;
    }
};


/* Panel-wise dates in AIR2 will display as short dates */
AIR2.Format.date = function (dtimStr) {
    var dt;

    if (!dtimStr) {
        return '';
    }

    dt = Date.parseDate(dtimStr, "Y-m-d H:i:s");
    if (dt) {
        dtimStr = dt;
    }
    else {
        dt = Date.parseDate(dtimStr, 'Ymd');
        if (dt) {
            dtimStr = dt;
        }
        else {
            dt = Date.parseDate(dtimStr, 'Y-m-d');
            if (dt) {
                dtimStr = dt;
            }
        }
    }
    return dtimStr.format("M j, Y").replace(/ /g, '&nbsp;');
};

/* Some search result dates come as 8-character strings. */
AIR2.Format.dateYmd = function (dtimStr) {
    var dt;

    if (!dtimStr) {
        return '';
    }

    dt = Date.parseDate(dtimStr, "Ymd");
    if (dt) {
        dtimStr = dt;
    }

    // special "Epoch" value should be friendlier for non-unix-aware users...
    if (dtimStr.format("m/d/y") === "01/01/70") {
        return "Never";
    }

    return dtimStr.format("m/d/y");
};

/* Some search result dates come as 8-character strings. */
AIR2.Format.dateYear = function (dtimStr) {
    var dt;
    if (!dtimStr) {
        return '';
    }

    dt = new Date(dtimStr);
    dt.format("Y");
    if (dt) {
        dtimStr = dt;
    }
    return dtimStr.format("Y");
};

AIR2.Format.dateWeek = function (dtimStr, boldWeek) {
    var dt, formatr, now;

    if (!dtimStr) {
        return '';
    }

    dt = Date.parseDate(dtimStr, "Y-m-d H:i:s");
    now = new Date();

    if (dt) {
        dtimStr = dt;
    }

    // only include year if it's not the current
    formatr = "D, M j Y";
    if ((new Date()).getFullYear() === dtimStr.format('Y')) {
        formatr = "D, M j";
    }
    if (boldWeek) {
        formatr = "<\\b>" + formatr + "</\\b>";
    }
    return dtimStr.format(formatr + " \\a\\t g:i a").replace(/ /g, '&nbsp;');
};

AIR2.Format.dateYmdLong = function (dtimStr) {
    var dt;

    if (!dtimStr) {
        return '';
    }

    dt = Date.parseDate(dtimStr, "Ymd");
    if (dt) {
        dtimStr = dt;
    }

    // special "Epoch" value should be friendlier for non-unix-aware users...
    if (dtimStr.format("m/d/y") === "01/01/70") {
        return "Never";
    }

    return dtimStr.format("M j, Y").replace(/ /g, '&nbsp;');
};

/* Overlay dates will have the full format YYYY-MM-DD HH:MM:SS am/pm */
AIR2.Format.dateLong = function (dtimStr) {
    var dt;

    if (!dtimStr) {
        return '';
    }
    dt = Date.parseDate(dtimStr, "Y-m-d H:i:s");
    if (dt) {
        dtimStr = dt;
    }

    return dtimStr.format('M j, Y g:i A').replace(/ /g, '&nbsp;');
};

/* In some very specific cases, we need to show "minutes ago" */
AIR2.Format.datePost = function (dtimStr) {
    var elapsed, now;

    if (!dtimStr) {
        return '';
    }

    now = new Date();

    // add a "buffer" minute, for client/server clock differences
    if (dtimStr < now.add(Date.MINUTE, +1)) {
        if (dtimStr > now.add(Date.MINUTE, -1)) {
            // within the last minute
            return '0 minutes ago';
        }
        else if (dtimStr > now.add(Date.HOUR, -1)) {
            // within the last hour
            elapsed = Math.ceil(dtimStr.getElapsed(now) / 1000 / 60);
            return elapsed + ' minutes ago';
        }
        else if (dtimStr.format('Ymd') === now.format('Ymd')) {
            // on the same calendar day
            elapsed = Math.ceil(dtimStr.getElapsed(now) / 1000 / 60 / 60);
            return elapsed + ' hours ago';
        }
    }
    return AIR2.Format.dateLong(dtimStr);
};

/* human-ify the date */
AIR2.Format.dateHuman = function (dtimStr, boldToday) {
    var bt, dt, input, now, today, yesterday;

    if (!dtimStr) {
        return '';
    }

    if (dtimStr.getMonth) {
        // already a date
    }
    else if (dt = Date.parseDate(dtimStr, "Y-m-d H:i:s")) {
        dtimStr = dt;
    }
    else if (dt = Date.parseDate(dtimStr, 'Ymd')) {
        dtimStr = dt;
    }
    else if (dt = Date.parseDate(dtimStr, 'Y-m-d')) {
        dtimStr = dt;
    }
    else {
        return ''; // un-parseable
    }

    now = new Date();
    today = now.format('Ymd');
    yesterday = now.add(Date.DAY, -1).format('Ymd');
    input = dtimStr.format('Ymd');

    if (input === today) {
        bt = boldToday ? "<b>Today</b> at " : "Today at ";
        return bt + dtimStr.format('g:i A');
    }
    else if (input === yesterday) {
        return "Yesterday at " + dtimStr.format('g:i A');
    }
    else {
        return dtimStr.format('M j, Y \\a\\t g:i A');
    }
};

/* machine-ify the date */
AIR2.Format.dateMachine = function (dtimStr) {
    var dt;

    if (!dtimStr) {
        return '';
    }

    dt = Date.parseDate(dtimStr, "Y-m-d H:i:s");
    if (dt) {
        dtimStr = dt;
    }

    return dtimStr.format('Y/m/d H:i:s').replace(/ /g, '&nbsp;');
};

/* format a source name, optionally returning the link */
AIR2.Format.sourceName = function (sourceObj, returnLink, flip, ellipsis) {
    var name;

    if (!sourceObj) {
        return '<span class="lighter">(unknown source)</span>';
    }

    name = sourceObj.src_username;
    if (sourceObj.src_first_name && sourceObj.src_last_name) {
        if (flip) {
            name =  sourceObj.src_first_name + " " + sourceObj.src_last_name;
        }
        else {
            name =  sourceObj.src_last_name + ", " + sourceObj.src_first_name;
        }
    }
    name = (ellipsis) ? Ext.util.Format.ellipsis(name, ellipsis) : name;
    return AIR2.Format.createLink(
        name,
        '/source/' + sourceObj.src_uuid,
        returnLink
    );
};

/* format a source username, optionally returning the link */
AIR2.Format.sourceUsername = function (sourceObj, returnLink) {
    var name = sourceObj.src_username;
    return AIR2.Format.createLink(
        name,
        '/source/' + sourceObj.src_uuid,
        returnLink
    );
};

/* First name, middle initial, last name. Don't use username on blank. */
AIR2.Format.sourceFullName = function (sourceObj, returnLink) {
    var name = '';

    if (!sourceObj) {
        return '<span class="lighter">(unknown source)</span>';
    }

    if (sourceObj.src_first_name) {
        name +=  sourceObj.src_first_name;
    }
    if (sourceObj.src_middle_initial) {
        name += sourceObj.src_middle_initial + '. ';
    }
    else {
        name += ' ';
    }
    if (sourceObj.src_first_name) {
        name += sourceObj.src_last_name;
    }

    return AIR2.Format.createLink(
        name,
        '/source/' + sourceObj.src_uuid,
        returnLink
    );
};

/* Add title and suffix to full name if available */
AIR2.Format.sourceTitledName = function (sourceObj, returnLink) {
    var name;

    if (!sourceObj) {
        return '<span class="lighter">(unknown source)</span>';
    }

    name = sourceObj.src_username;
    if (sourceObj.src_first_name && sourceObj.src_last_name) {
        name = '';
        if (sourceObj.src_pre_name) {
            name += sourceObj.src_pre_name + ' ';
        }
        name += sourceObj.src_first_name + ' ';
        if (sourceObj.src_middle_initial) {
            name += sourceObj.src_middle_initial + '. ';
        }
        name += sourceObj.src_last_name;
        if (sourceObj.src_post_name) {
            name += ', ' + sourceObj.src_post_name;
        }
    }

    return AIR2.Format.createLink(
        name,
        '/source/' + sourceObj.src_uuid,
        returnLink
    );
};

/* Source contact info */
AIR2.Format.sourceEmail = function (srcEmail, returnLink) {
    var e;

    if (!srcEmail || !srcEmail.sem_email) {
        return '<span class="lighter">unknown email</span>';
    }

    e = srcEmail.sem_email;

    return AIR2.Format.createLink(e, 'mailto:' + e, returnLink, true);
};

/* A mailto link that doesn't really open up "mailto" */
AIR2.Format.mailTo = function (email, srcObj) {
    var srcFullName, link;

    srcFullName = srcObj.src_username;
    if (srcObj.src_first_name && srcObj.src_last_name) {
        srcFullName = srcObj.src_first_name + ' ' + srcObj.src_last_name;
    }
    
    // make sure fullname has no html in it,
    // as it might from search highlighting
    srcFullName = srcFullName.replace(/<.+?>/g, '');
    //Logger('srcFullName=', srcFullName);


    link = '<a href="#" onclick="return AIR2.Email.Mailto(';
    link += 'this,';
    link += "'" + srcObj.src_uuid + "',";
    link += "'" + srcFullName + "'";
    link += ');">' + email + '</a>';

    return link;
}

AIR2.Format.sourcePhone = function (srcPhone) {
    var num;

    if (!srcPhone || !srcPhone.sph_number) {
        return '<span class="lighter">unknown phone</span>';
    }

    num = srcPhone.sph_number;

    if (srcPhone.sph_country) {
        num = srcPhone.sph_country + num;
    }

    if (srcPhone.sph_ext) {
        num += srcPhone.sph_ext;
    }

    return num;
};

AIR2.Format.sourceMailShort = function (srcMail) {
    var mail = '';

    if (srcMail.smadd_city) {
        mail += srcMail.smadd_city;
        if (srcMail.smadd_state || srcMail.smadd_zip) {
            mail += ',';
        }
    }
    if (srcMail.smadd_state) {
        mail += ' ' + srcMail.smadd_state;
    }

    if (srcMail.smadd_zip) {
        mail += ' ' + srcMail.smadd_zip;
    }

    return mail;
};

AIR2.Format.sourceChannel = function (code) {
    var channels = {
        R: 'Referred by another source',
        Q: 'Query',
        I: 'Game/Interactive Experience',
        E: 'Event/In Person Signup',
        O: 'Opt-in (via programming)/Online Signup',
        G: 'Idea Generator',
        U: 'Not Known',
        N: 'Invitation by newsroom',
        S: 'Strategic Outreach activity'
    };

    if (channels[code]) {
        return channels[code];
    }
    else {
        return 'Not Known';
    }
};

AIR2.Format.vitaOrigin = function (svObj) {
    var o;

    if (svObj) {
        o = svObj.sv_origin;
    }
    else {
        o = null;
    }

    switch (o) {
    case '2':
        return 'AIR2';
    case 'C':
        return 'AIR1';
    case 'S':
        return 'AIR1';
    case 'M':
        return 'SOURCE';
    default:
        return '<span class="lighter">(unknown origin)</span>';
    }
};

AIR2.Format.orgSysIdType = function (code) {
    var types = {
        E: 'Lyris',
        M: 'Mailchimp'
    };
    return (types[code]) ? types[code] : 'Not Known';
};

/* the organization summary */
AIR2.Format.orgSummary = function (orgObj, ellipsis) {
    var s;
    if (!orgObj) {
        return '';
    }

    if (orgObj.org_summary) {
        s = orgObj.org_summary;
    }
    else {
        s = '<span class="lighter">(none)</span>';
    }

    if (ellipsis) {
        s = Ext.util.Format.ellipsis(s, ellipsis);
    }

    return s;
};

/* the organization description */
AIR2.Format.orgDescription = function (orgObj, ellipsis) {
    var s;
    if (!orgObj) {
        return '';
    }

    if (orgObj.org_desc) {
        s = orgObj.org_desc;
    }
    else {
        s = '<span class="lighter">(none)</span>';
    }

    if (ellipsis) {
        s = Ext.util.Format.ellipsis(s, ellipsis);
    }

    return s;
};

/* format a user name, optionally returning the link */
AIR2.Format.userName = function (userObj, returnLink, flip) {
    var name;

    if (!userObj) {
        return '<span class="lighter">(unknown user)</span>';
    }

    name = userObj.user_username;
    if (userObj.user_type !== 'S') {
        if (flip) {
            name = userObj.user_first_name + " " + userObj.user_last_name;
        }
        else {
            name = userObj.user_last_name + ", " + userObj.user_first_name;
        }
    }

    return AIR2.Format.createLink(
        name,
        '/user/' + userObj.user_uuid,
        returnLink
    );
};

/* short format of a user's organization, with background color */
AIR2.Format.userOrgShort = function (obj, returnLink) {
    var org = obj;
    if (obj && obj.Organization) {
        org = obj.Organization;
    }
    else if (
        obj &&
        obj.UserOrg &&
        obj.UserOrg.length &&
        obj.UserOrg[0].Organization
    ) {
        org = obj.UserOrg[0].Organization;
    }

    if (!org) {
        return '';
    }
    return AIR2.Format.orgName(org, returnLink);
};

/* long format of a user's organization */
AIR2.Format.userOrgLong = function (obj, returnLink) {
    var org = obj;
    if (obj && obj.Organization) {
        org = obj.Organization;
    }
    else if (
        obj &&
        obj.UserOrg &&
        obj.UserOrg.length &&
        obj.UserOrg[0].Organization
    ) {
        org = obj.UserOrg[0].Organization;
    }

    if (!org) {
        return '';
    }
    return AIR2.Format.orgNameLong(org, returnLink);
};

/* the title of a user in an organization */
AIR2.Format.userOrgTitle = function (userOrgObj, ellipsis) {
    var s;
    if (!userOrgObj) {
        return '';
    }

    if (userOrgObj.uo_user_title) {
        s = userOrgObj.uo_user_title;
    }
    else {
        s = '<span class="lighter">(none)</span>';
    }

    if (ellipsis) {
        s = Ext.util.Format.ellipsis(s, ellipsis);
    }

    return s;
};

/* format a user's primary phone number, if it exists */
AIR2.Format.userPhone = function (obj) {
    if (obj.UserPhoneNumber && obj.UserPhoneNumber.length > 0) {
        var p = obj.UserPhoneNumber[0];
        return p.uph_number + (p.uph_ext ? ' (' + p.uph_ext + ')' : '');
    }
    else if (obj.uph_number) {
        return obj.uph_number + (obj.uph_ext ? ' (' + obj.uph_ext + ')' : '');
    }
    return '<span class="lighter">(none)</span>';
};

/* format a user's primary email, if it exists */
AIR2.Format.userEmail = function (obj, returnLink) {
    var e;

    if (obj.UserEmailAddress && obj.UserEmailAddress.length > 0) {
        e = obj.UserEmailAddress[0].uem_address;
        return AIR2.Format.createLink(e, 'mailto:' + e, returnLink, true);
    }
    else if (obj.uem_address) {
        e = obj.uem_address;
        return AIR2.Format.createLink(e, 'mailto:' + e, returnLink, true);
    }
    return '<span class="lighter">(none)</span>';
};

/* format the profile photo of a user */
AIR2.Format.userPhoto = function (obj, width, height, useThumb) {
    var alt, src, tag;

    src = AIR2.HOMEURL + '/css/img/not_found.jpg';
    alt = 'user_photo';

    if (obj.Avatar) {
        src = useThumb ? obj.Avatar.thumb : obj.Avatar.medium;
        alt = obj.Avatar.img_file_name;
    }

    tag = '<img class="avatar" src="' + src + '" alt="' + alt + '"';

    if (width) {
        tag += ' width=' + width;
    }
    else if (height) {
        tag += ' height=' + height;
    }

    tag += '></img>';

    return tag;
};

/* format the title of an inquiry, optionally returning the link */
AIR2.Format.inquiryTitle = function (inquiryObj, returnLink, ellipsis) {
    var fm, len, notags;

    if (!inquiryObj) {
        return '<span class="lighter">(unknown query)</span>';
    }

    fm = Ext.util.Format;
    len = ellipsis ? ellipsis : 110;
    notags = fm.ellipsis(fm.stripTags(inquiryObj.inq_ext_title), len, true);

    return AIR2.Format.createLink(
        notags,
        '/query/' + inquiryObj.inq_uuid,
        returnLink
    );
};

/* format a submission as a "MORE" link */
AIR2.Format.submissionMore = function (submObj) {
    return AIR2.Format.createLink(
        'more&nbsp;&raquo;',
        '/submission/' + submObj.srs_uuid,
        true
    );
};

/* format an organization name, adding color */
AIR2.Format.orgName = function (orgObj, returnLink) {
    if (!orgObj) {
        return '<span class="lighter">(unknown organization)</span>';
    }
    var color = orgObj.org_html_color ? orgObj.org_html_color : 'ccc';
    if (returnLink) {
        return '<a class="air2-newsroom" style="background-color:#' +
            color + '" href="' + AIR2.HOMEURL + '/organization/' +
            orgObj.org_uuid + '">' + orgObj.org_name + '</a>';
    }
    else {
        return '<span class="air2-newsroom" style="background-color:#' +
            color + '">' + orgObj.org_name + '</span>';
    }
};

/* format an org name, optionally returning the link */
AIR2.Format.orgNameLong = function (orgObj, returnLink, ellipsis) {
    if (!orgObj) {
        return '<span class="lighter">(unknown organization)</span>';
    }
    var n = orgObj.org_display_name;
    if (ellipsis) {
        n = Ext.util.Format.ellipsis(n, ellipsis);
    }

    return AIR2.Format.createLink(
        n,
        '/organization/' + orgObj.org_uuid,
        returnLink
    );
};

/* format the organization logo image */
AIR2.Format.orgLogo = function (obj, width, height) {
    var alt, src, tag;

    src = AIR2.HOMEURL + '/css/img/not_found_org.png';
    alt = 'org_logo';

    if (obj.Logo) {
        src = obj.Logo.medium;
        alt = obj.Logo.img_file_name;
    }

    tag = '<img class="logo" src="' + src + '" alt="' + alt + '"';

    if (width) {
        tag += ' width=' + width;
    }
    else if (height) {
        tag += ' height=' + height;
    }

    tag += '></img>';

    return tag;
};

/* format the inquiry logo image */
AIR2.Format.inqLogo = function (obj, width, height) {
    var alt, src, tag;

    src = AIR2.HOMEURL + '/css/img/not_found_org.png';
    alt = 'inq_logo';

    if (obj.Logo) {
        src = obj.Logo.thumb;
        alt = obj.Logo.img_file_name;
    }
    else if (obj.InqOrg[0].OrgLogo) {
        src = obj.InqOrg[0].OrgLogo.thumb;
        alt = obj.InqOrg[0].OrgLogo.img_file_name;
    }

    tag = '<img class="logo" src="' + src + '" alt="' + alt + '"';

    if (width) {
        tag += ' width=' + width;
    }
    else if (height) {
        tag += ' height=' + height;
    }

    tag += '></img>';

    return tag;
};

AIR2.Format.projectName = function (prjObj, returnLink) {
    if (!prjObj) {
        return '<span class="lighter">(unknown project)</span>';
    }
    return AIR2.Format.createLink(
        prjObj.prj_display_name,
        '/project/' + prjObj.prj_uuid,
        returnLink
    );
};

AIR2.Format.outcome = function (outObj, returnLink, ellipsis, exturl) {
    var line, url;
    if (outObj) {
        line = outObj.out_headline;
    }
    else {
        line = outObj;
    }

    if (!line) {
        return '<span class="lighter">(unknown outcome)</span>';
    }
    if (ellipsis) {
        line = Ext.util.Format.ellipsis(line, ellipsis);
    }

    if (exturl) {
        url = outObj.out_url;
    }
    else {
        url = '/outcome/' + outObj.out_uuid;
    }

    return AIR2.Format.createLink(line, url, returnLink);
};

/* format a tag, trimming IPTC tags */
AIR2.Format.tagName = function (tagObj) {
    var iname, result, split;

    result = tagObj.tm_name;

    if (tagObj.tm_type === 'I') {

        if (tagObj.IptcMaster) {
            iname = tagObj.IptcMaster.iptc_name;
        }
        else {
            iname = tagObj.iptc_name;
        }

        split = iname.lastIndexOf('/');

        if (split) {
            result = iname.substr(split + 1);
        }

    }

    return Ext.util.Format.trim(result);
};

/* format bin name */
AIR2.Format.binName = function (binObj, returnLink, ellipsis) {
    if (!binObj) {
        return '<span class="lighter">(unknown bin)</span>';
    }
    var n = binObj.bin_name;
    if (ellipsis) {
        n = Ext.util.Format.ellipsis(n, ellipsis);
    }
    return AIR2.Format.createLink(
        n,
        '/bin/' + binObj.bin_uuid,
        returnLink
    );
}

/* format bin last use */
AIR2.Format.binLastUse = function (binObj) {
    if (binObj.bin_upd_dtim) {
        return AIR2.Format.datePost(binObj.bin_upd_dtim);
    }
    return 'No uses';
};

/* format bin number of items */
AIR2.Format.binCount = function (binObj) {
    var str;

    if (binObj.src_count || Ext.isNumber(binObj.src_count)) {
        str = binObj.src_count;
    }
    else {
        str = 'Unknown';
    }

    str += ' Sources';

    if (binObj.src_count === 1) {
        str = str.substr(0, str.length - 1);
    }

    return str;
};

/* format a boolean in friendly way */
AIR2.Format.bool = function (bool) {
    if (bool) {
        return 'Yes';
    }
    else {
        return 'No';
    }
};

/* format tank info */
AIR2.Format.tankName = function (tankObj, returnLink) {
    if (!tankObj) {
        return '<span class="lighter">(unknown import)</span>';
    }
    var name = tankObj.tank_name;
    return AIR2.Format.createLink(
        name,
        '/import/' + tankObj.tank_uuid,
        returnLink
    );
};
AIR2.Format.tankType = function (tankObj, addText) {
    var def, str, t;

    /* type => [icon, tooltip] */
    t = {
        F: ['air2-icon-formbuilder', 'Query Import'],
        Q: ['air2-icon-formbuilder', 'Query Import'],
        C: ['air2-icon-upload', 'CSV Import'],
        S: ['air2-icon-upload', 'AIR1Sync Process'],
        B: ['air2-icon-formbuilder', 'BudgetHero'] //TODO:
    };
    def = t[tankObj.tank_type];
    str = '<span class="air2-icon ' + def[0] + '"';

    if (addText) {
        str += '>' + def[1] + '</span>';
    }
    else {
        str += ' ext:qtip="' + def[1] + '"></span>';
    }

    return str;
};
AIR2.Format.tankStatus = function (tankObj, returnText, returnBoth) {
    var def, s, st;

    /* status => [icon, tooltip] */
    s = {
        C:   ['air2-icon-warning', 'Import Conflicts'],
        E:   ['air2-icon-warning', 'Import Errors'],
        R:   ['air2-icon-check', 'Ready'],
        L:   ['air2-icon-working', 'Background processing'],
        K:   ['air2-icon-error', 'Fatal error!'],
        N:   ['air2-icon-warning', 'CSV Needs work'],
        // default
        DEF: ['air2-icon-error', 'UNKNOWN STATUS']
    };

    st  = tankObj.tank_status;
    def = s[st] ? s[st] : s.DEF;

    if (returnText) {
        return def[1];
    }
    else if (returnBoth) {
        return '<span class="air2-icon ' + def[0] + '">' +
            def[1] + '</span>';
    }
    else {
        return '<span class="air2-icon ' + def[0] +
            '" ext:qtip="' + def[1] + '"></span>';
    }

};

AIR2.Format.tsrcStatus = function (code) {
    var s = {
        N: 'New',
        C: 'Conflict',
        L: 'Working',
        D: 'Done',
        R: 'Resolved',
        E: 'Error'
    };

    if (s[code]) {
        return s[code];
    }
    else {
        return 'Unknown';
    }

};

AIR2.Format.shared = function (isShared) {
    if (isShared) {
        return '<li class="green">Yes</li>';
    }
    else {
        return '<li class="red">No</li>';
    }
};

AIR2.Format.status = function (status) {
    if (status === 'A') {
        return '<li class="green">Active</li>';
    }
    else {
        return '<li class="red">Inactive</li>';
    }
};

/* helper for formatting stuff in the code_master fixture */
AIR2.Format.codeMaster = function (fldname, code) {
    var fix, i;

    if (!code) {
        return ''; // nulls get empty string
    }

    fix = AIR2.Fixtures.CodeMaster[fldname];
    if (!fix) {
        return 'No Fixture for ' + fldname;
    }

    for (i = 0; i < fix.length; i++) {
        if (fix[i][0] === code) {
            return fix[i][1];
        }
    }
    return '(Not Found)';
};

/* format a question choice with the correct icon */
AIR2.Format.quesChoice = function (value, type, ischecked, isdefault) {
    var cls = 'air2-question-choice ' +
        AIR2.Format.quesChoiceCls(type, ischecked);

    // formatting
    if (!value) {
        cls += ' lighter';
        value = '(none)';
    }
    if (isdefault) {
        value += ' <span class="lighter">(default)</span>';
    }

    return '<span class="' + cls + '">' + value + '</span>';
};

AIR2.Format.quesChoiceCls = function (type, ischecked) {
    var cls = '';
    if (type === 'R' || type === 'P' || type === 'p') {
        cls += 'radio'; //radio (single-select)
    }
    else if (type === 'O') {
        cls += 'combobox'; //dropdown (single-select)
    }
    else if (type === 'C') {
        cls += 'checkbox'; //checkbox (multi-select)
    }
    else if (type === 'L') {
        cls += 'picklist'; //dropdown (multi-select)
    }

    //TODO: REMOVE! this is for backwards-compatability
    if (type === 'S') {
        cls += 'radio';
    }
    if (type === 'M') {
        cls += 'checkbox';
    }

    if (ischecked) {
        cls += ' checked';
    }
    else {
        cls += ' unchecked';
    }

    return cls;
};

AIR2.Format.liveQuestionChoice = function (value, type, ischecked, isdefault, ques_id) {
    var cls, inputType, checked, name;

    name = 'group' + ques_id;

    checked = '';

    cls = 'air2-question-choice ' +
        AIR2.Format.quesChoiceCls(type, ischecked);
    inputType = '';

    if (type === 'R' || type === 'P' || type === 'p') {
        inputType += 'radio'; //radio (single-select)
    }
    else if (type === 'O' || type === 'L') { // Combobox (single-select) and pick list (multi-select)
        if (ischecked) {
            checked = 'selected';
        }
        return '<option value="'+value+'" '+checked+'>'+value+'</option>';
    }
    else if (type === 'C') {
        inputType += 'checkbox'; //checkbox (multi-select)
    }

    if (isdefault) {
        value += ' <span class="lighter">(default)</span>';
    }

    if (ischecked){
        checked = 'checked';
    }
    return '<input class ="' + cls + '" type="' + inputType +
        '" name="'+name+'" value="' + value + '" ' + checked + '> ' + value + ' </input>';
};

AIR2.Format.quesType = function (type) {
    switch (type) {
    case 'T':
        return 'Text field';
    case 'A':
        return 'Multi-line text field';
    case 'D':
        return 'Date field';
    case 'I':
        return 'Date/Time field';
    case 'F':
        return 'File Upload field';
    case 'R':
        return 'Single-select field';
    case 'O':
        return 'Single-select field';
    case 'S':
        return 'State selection field';
    case 'Y':
        return 'Country selection field';
    case 'C':
        return 'Multi-select field';
    case 'L':
        return 'Multi-select field';
    case '2':
        return 'Line break';
    case '3':
        return 'Display field';
    }
    return '<span class="lighter">Unknown "' + type + '"</span>';
};

AIR2.Format.quesRespType = function (type) {
    switch (type) {
    case 'S':
        return 'Text String';
    case 'N':
        return 'Numeric';
    case 'D':
        return 'Date';
    case 'T':
        return 'Date-time';
    case 'E':
        return 'E-mail';
    case 'U':
        return 'URL';
    case 'P':
        return 'Phone Number';
    case 'Z':
        return 'Postal code';
    }
    return '<span class="lighter">Unknown "' + type + '"</span>';
};

AIR2.Format.householdIncome = function (values) {
    var factValueString = '';
    if (!Ext.isString(values)) {
        factValueString = AIR2.Source.factValue(values);
    }
    else {
        factValueString = values;
    }
    return factValueString.replace(/(\d)(?=(\d\d\d)+\b)/g, "$1,");
};

/* similar to the PHP and Perl functions of the same name */
AIR2.Format.urlify = function (val) {
    var str;

    str = val.replace(/([A-Z][a-z])/g, '-$1');
    str = str.toLowerCase();
    str = str.replace(/['\",.!?;:]/g, '');
    str = str.replace(/<.+?>|&[\S];/g, '');
    str = str.replace(/\W+/g, '-');
    str = str.replace(/^-+|-+$/g, '');
    str = str.replace(/--*/, '-');
    return str;
};

AIR2.Format.formatPhone = function (phone_number) {
    if (phone_number && phone_number.length == 10) {
        pattern = new RegExp(/^(\d\d\d)(\d\d\d)(\d\d\d\d)$/g);
        matches = pattern.exec(phone_number);
        phone_number = '('+matches[1]+') '+matches[2]+'-'+matches[3];
    }
    else if (phone_number && phone_number.length == 15) {
        pattern = new RegExp(/^(\d\d)(\d\d)(\d)(\d\d\d\d)(\d\d\d\d\d\d)$/g);
        matches = pattern.exec(phone_number);
        phone_number = matches[1] + ' ' + matches[2] + ' (' + matches[3] + ') ' + matches[4] + ' ' + matches[5];
    }
    return phone_number;
};

AIR2.Format.toggle = function(btn, parent_id, clsName) {
    var parEl, childEls, isVisible, btnEl;
    parEl = Ext.get(parent_id);
    if (!parEl) {
        Logger("can't find parent_id");
        return;
    }
    childEls = parEl.select('.'+clsName);
    //Logger(childEls);
    childEls.toggleClass('air2-hidden');
    if (childEls.last()) {
        isVisible = childEls.last().isVisible();
    }
    btnEl = Ext.get(btn);
    //Logger(btnEl, hidden);
    if (isVisible) {
        btnEl.child('.label').dom.innerHTML = 'Hide';
    }
    else {
        btnEl.child('.label').dom.innerHTML = 'Show';
    }
}

AIR2.Format.emailName = function (emailObj, returnLink, ellipsis) {
    if (!emailObj) {
        return '<span class="lighter">(unknown email)</span>';
    }
    var n = emailObj.email_campaign_name;
    if (ellipsis) {
        n = Ext.util.Format.ellipsis(n, ellipsis);
    }
    return AIR2.Format.createLink(
        n,
        '/email/' + emailObj.email_uuid,
        returnLink
    );
}
AIR2.Format.emailType = function (emailObj) {
    var def, t;
    t = {
        Q: ['air2-icon-inquiries', 'Query'],
        F: ['air2-icon-retry', 'Follow Up'],
        R: ['air2-icon-activity', 'Reminder'],
        T: ['air2-icon-outcome', 'Thank You'],
        O: ['air2-icon-annotation', 'Other']
    };
    def = t[emailObj.email_type] || t.O;
    return '<span class="air2-icon ' + def[0] + '">' + def[1] + '</span>';
}
AIR2.Format.emailStatus = function (emailObj) {
    if (emailObj.email_status == 'A') {
        return '<span class="air2-email-status sent">Sent</span>';
    }
    else if (emailObj.email_status == 'Q') {
        return '<span class="air2-email-status scheduled">Scheduled</span>';
    }
    else if (emailObj.email_status == 'D') {
        return '<span class="air2-email-status draft">Draft</span>';
    }
    else {
        return '<span class="air2-email-status archived">Archived</span>';
    }
}
AIR2.Format.emailLogo = function (obj, width, height) {
    var alt, src, tag;

    src = AIR2.HOMEURL + '/css/img/not_found_org.png';
    alt = 'email_logo';
    if (obj.Logo) {
        src = obj.Logo.medium;
        alt = obj.Logo.img_file_name;
    }
    tag = '<img class="logo" src="' + src + '" alt="' + alt + '"';
    if (width) tag += ' width=' + width;
    else if (height) tag += ' height=' + height;
    tag += '></img>';
    return tag;
};
AIR2.Format.signature = function (obj, ellipsis) {
    var f, t;
    f = Ext.util.Format;
    t = obj.usig_text || obj;

    // ext has a bad html-decoder, so jump through some hoops
    var tmpEl = Ext.get(document.createElement('div'));
    tmpEl.update(f.stripTags(t.replace(/&nbsp;/g, ' ')));
    return f.ellipsis(tmpEl.dom.innerHTML, ellipsis || 40);
}
