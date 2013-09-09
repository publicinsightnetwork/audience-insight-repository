Ext.namespace('AIR2.Util.Activity');

/**
 * AIR2.Util.Activity.format
 *
 * Format an activity description into something readable
 */
AIR2.Util.Activity.format = function (values, cfg) {
    var desc,
        icon,
        tag;

    if (!cfg) {
        cfg = {};
    }
    Ext.applyIf(cfg, {tag: 'div'});

    // get the description string
    desc = 'Unknown';
    if (values.sact_desc) {
        desc = values.sact_desc;
    }
    if (values.pa_desc) {
        desc = values.pa_desc;
    }
    if (values.ia_desc) {
        desc = values.ia_desc;
    }

    // format objects
    if (desc.match(/{\w+}/)) {
        // NEW activity style - replace {TAGS} with links
        desc = AIR2.Util.Activity.replaceTags(desc, values);

        // prepend the actm_name
        if (values.ActivityMaster) {
            desc = '<b>' + values.ActivityMaster.actm_name + '</b> - ' + desc;
        }
    }
    else {
        // OLD activity style - do SUBJECT -> verb -> XID
        desc = AIR2.Util.Activity.oldActivityTags(desc, values);
    }

    // enclose in tag, and add icon class
    icon = AIR2.Util.Activity.iconCls(values.ActivityMaster);
    tag = '<' + cfg.tag + ' class="air2-icon ' + icon + '">';
    tag += desc + '</' + cfg.tag + '>';
    return tag;
};

/**
 * AIR2.Util.Activity.replaceTags
 *
 * Replace object tags in an activity description
 */
AIR2.Util.Activity.replaceTags = function (desc, values) {
    var extLink,
        link,
        prjLink,
        srcLink,
        srs,
        usrLink;

    // replace {SRC} tag
    if (values.Source) {
        srcLink = AIR2.Format.sourceName(values.Source, true, true);
        desc = desc.replace(/\{SRC\}/, srcLink);
    }

    // replace {USER} tag
    if (values.CreUser) {
        usrLink = AIR2.Format.userName(values.CreUser, true, true);
        desc = desc.replace(/{USER}/, usrLink);
    }

    // replace {PROJ} tag
    if (values.Project) {
        prjLink = AIR2.Format.projectName(values.Project, true);
        desc = desc.replace(/{PROJ}/, prjLink);
    }

    // replace {XID} tag
    if (values.sact_ref_type) {
        extLink = 'Unknown external';
        if (values.sact_ref_type === 'R') {
            srs = values.SrcResponseSet;
            link = AIR2.HOMEURL + '/submission/' + srs.srs_uuid;
            extLink = '<a href="' + link + '">submission</a>';
        }
        else if (values.sact_ref_type === 'T') {
            extLink = AIR2.Format.tankName(values.Tank, true);
        }
        else if (values.sact_ref_type === 'O') {
            extLink = AIR2.Format.orgName(values.Organization, true);
        }
        else if (values.sact_ref_type === 'I') {
            extLink = AIR2.Format.inquiryTitle(values.Inquiry, true);
        }
        else if (values.sact_ref_type === 'E') {
            extLink = AIR2.Format.emailName(values.Email, true, 50);
        }
        desc = desc.replace(/{XID}/, extLink);
    }
    else if (values.pa_ref_type) {
        extLink = 'Unknown external';
        if (values.pa_ref_type === 'I') {
            extLink = AIR2.Format.inquiryTitle(values.Inquiry, true);
        }
        else if (values.pa_ref_type === 'O') {
            extLink = AIR2.Format.orgName(values.Organization, true);
        }
        desc = desc.replace(/{XID}/, extLink);
    }

    // clear any remaining tags and return
    return desc.replace(/{\w+}/gm, '');
};

/**
 * AIR2.Util.Activity.oldActivityTags
 *
 * Format deprecated activity (usually from AIR1 conversion)
 */
AIR2.Util.Activity.oldActivityTags = function (desc, values) {
    var act,
        link,
        srs,
        usrLink;

    // append XID link to end of description
    if (values.sact_ref_type) {
        if (values.sact_ref_type === 'R') {
            if (values.SrcResponseSet) {
                srs = values.SrcResponseSet;
                link = AIR2.HOMEURL + '/submission/' + srs.srs_uuid;
                if (srs.srs_type === 'E') {
                    desc = '<a href="' + link + '">Manual Submission Entry</a>';
                }
                else {
                    desc = '<a href="' + link + '">' + desc + '</a>';
                }
            }
            else {
                // can't create a link!
            }
        }
        else if (values.sact_ref_type === 'T') {
            desc += ' ' + AIR2.Format.tankName(values.Tank, true);
        }
        else if (values.sact_ref_type === 'O') {
            desc += ' ' + AIR2.Format.orgName(values.Organization, true);
        }
    }

    // figure out what to do with the activity and user:
    if (values.CreUser) {
        usrLink = AIR2.Format.userName(values.CreUser, true, true);
    }
    else {
        usrLink = '';
    }

    if (values.ActivityMaster) {
        act = '<b>' + values.ActivityMaster.actm_name + '</b>';
    }
    else {
        act = '';
    }

    if (desc.match(/AIR user/i)) {
        // replace "AIR user" with the actual user link, prepend activity
        desc = act + ' - ' + desc.replace(/AIR user/i, usrLink);
    }
    else {
        // put the user before the activity
        desc = usrLink + ' - ' + act + ' - ' + desc;
    }
    return desc;
};


/**
 * AIR2.Util.Activity.iconCls
 *
 * Get the icon class for a type of activity
 */
AIR2.Util.Activity.iconCls = function (actm) {
    switch (actm.actm_type) {
    case 'I': //inbound
        return 'air2-icon-bullet';
    case 'A': //administrative
        return 'air2-icon-tag';
    case 'O': //outbound
        return 'air2-icon-email';
    case 'C': //contact
        return 'air2-icon-inquiry';
    case 'R': //relationship
        return 'air2-icon-organization';
    case 'S': //status
        return 'air2-icon-source';
    case 'M': //message
        return 'air2-icon-email';
    case 'J': //journalism
        return 'air2-icon-source';
    case 'U': //upload
        return 'air2-icon-upload';
    default:
        return 'air2-icon-bullet';
    }
};


/**
 * AIR2.Util.Activity.formatUser
 *
 * Format the activity for a user (mostly meta-activity)
 */
AIR2.Util.Activity.formatUser = function (values, cfg) {
    var desc, icon, org, tag, usr;

    if (!cfg) {
        cfg = {};
    }
    Ext.applyIf(cfg, {tag: 'div'});

    // get a description based on type
    switch (values.type) {
    case 'C': //csv upload
        desc = 'Uploaded CSV ' + AIR2.Format.tankName(values.Tank, true);
        icon = 'air2-icon-upload';
        break;
    case 'A': //added to organization
        org = AIR2.Format.orgName(values.UserOrg.Organization, true);
        usr = AIR2.Format.userName(values.UserOrg.CreUser, true, true);
        desc = 'Added to ' + org + ' by ' + usr;
        icon = 'air2-icon-organization';
        break;
    case 'I': //published inquiry
        desc = 'Published the query ';
        desc += AIR2.Format.inquiryTitle(values.Inquiry, true);
        icon = 'air2-icon-inquiry';
        break;
    case 'O': //created organization
        desc = 'Created the organization ';
        desc += AIR2.Format.orgNameLong(values.Organization, true);
        icon = 'air2-icon-organization';
        break;
    case 'U': //created user
        desc = 'Created the user ';
        desc += AIR2.Format.userName(values.User, true, true);
        icon = 'air2-icon-user';
        break;
    case 'E': //exported bin
        if (values.SrcExport.Email) {
            desc = 'Sent the email ' + AIR2.Format.emailName(values.SrcExport.Email, 1, 30);
            icon = 'air2-icon-email-small';
        }
        else {
            desc = 'Exported the bin ' + values.SrcExport.se_name;
            icon = 'air2-icon-bin-small';
        }
        break;
    case 'P': //created PINfluence
        desc = 'Created PINfluence ' + AIR2.Format.outcome(values.Outcome, true);
        icon = 'air2-icon-outcome';
        break;
    default:
        desc = 'Unknown activity!';
        icon = 'air2-icon-bullet';
        break;
    }

    // enclose in tag, and add icon class
    tag = '<' + cfg.tag + ' class="air2-icon ' + icon + '">';
    tag += desc + '</' + cfg.tag + '>';
    return tag;
};


/**
 * AIR2.Util.Activity.formatOrg
 *
 * Format the activity for an organization (mostly meta-activity)
 */
AIR2.Util.Activity.formatOrg = function (values, cfg) {
    var desc, icon, org, prj, tag, usr;

    if (!cfg) {
        cfg = {};
    }
    Ext.applyIf(cfg, {tag: 'div'});

    // get a description based on type
    switch (values.type) {
    case 'U': //user added
        //var cre = AIR2.Format.userName(values.UserOrg.CreUser, true, true);
        usr = AIR2.Format.userName(values.UserOrg.User, true, true);
        desc = 'User ' + usr + ' joined organization';
        icon = 'air2-icon-user';
        break;
    case 'C': //org created
        org = AIR2.Format.orgNameLong(values.Organization, true);
        usr = AIR2.Format.userName(values.Organization.CreUser, true, true);
        desc = org + ' created by ' + usr;
        icon = 'air2-icon-fact';
        break;
    case 'O': //org updated
        usr = AIR2.Format.userName(values.Organization.UpdUser, true, true);
        desc = 'Updated by ' + usr;
        icon = 'air2-icon-organization';
        break;
    case 'P': //added to project
        prj = AIR2.Format.projectName(values.ProjectOrg.Project, true);
        usr = AIR2.Format.userName(values.ProjectOrg.CreUser, true, true);
        desc = 'Added to project ' + prj + ' by ' + usr;
        icon = 'air2-icon-project';
        break;
    default:
        desc = 'Unknown activity!';
        icon = 'air2-icon-bullet';
        break;
    }

    // enclose in tag, and add icon class
    tag = '<' + cfg.tag + ' class="air2-icon ' + icon + '">';
    tag += desc + '</' + cfg.tag + '>';
    return tag;
};
