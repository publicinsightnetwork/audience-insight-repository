/***************
 * Row-expander for the reader
 */
AIR2.Reader.expandHandler = function (dv) {
    var closeNode,
        exclude,
        expandNode,
        expandTpl,
        getExpandedIdx,
        scrollTo;

    // expand template
    expandTpl = new Ext.XTemplate(
        '<tr class="reader-expand" id="air2-reader-row-{srs_uuid}">' +
            '<td colspan="99">' +
                // submission data
                '<div class="submission">' +
                    '<div class="sub-act clearfix">' +
                        '<a href="{inq_uuid:this.queryLink(values)}" target="_blank" class="view-query">Insights Page <i class="icon-external-link"></i></a>' +
                        '<a href="{srs_uuid:this.printLink}" target="_blank" class="print-submission"><i class="icon-print"></i> Print Submission</a>' +                         '<a href="{srs_uuid:this.permaLink}" class="submission-permalink"><i class="icon-link"></i> Submission Permalink</a>' +
                    '</div>' +
                    '<h4 class="sub-inq">{.:air.inquiryTitle(1)}</h4>' +
                    '<div style="clear: left;">' +
                        '{inq_publish_dtim:this.publishedAt} ' +
                        '{inq_org_uuid:this.inqOrg}' +
                    '</div>' +
                    // metadata
                    '<ul class="sub-meta {publish_state:this.publishState}">' +
                        '<li>' +
                            'Received on <a href="{srs_uuid:this.permaLink}">' +
                            '{srs_date:air.dateWeek(true)}</a> ' +
                            'from {.:air.sourceName(1,1)}' +
                        '</li>' +
                        '<li>Referring URL: {srs_uri:this.refUrl}</li>' +
                        '<li id="srs-publish-state-{srs_uuid}" ' +
                        'class="publishStatusItem">' +
                            '{publish_state:this.displayPublishState}' +
                        '</li>' +
                    '</ul>' +
                   // questions and answers
                   '<tpl if="this.hasContributorResponses(values)">' +
                    '<div class="sub-act">' +
                     '<a href="#air2-reader-row-{srs_uuid}" ' +
                       'onclick="AIR2.Format.toggle(this,&quot;air2-reader-row-{srs_uuid}&quot;,&quot;contributor-question&quot;);return false;" ' +
                       'class="contributor-qa-toggle">' +
                      '<i class="icon-angle-down"></i> <span class="label">Show</span> Contributor Responses' +
                     '</a>' +
                    '</div>' +
                   '</tpl>' +
                    '<tpl for="friendly">' +
                        '<div id="response-entry-{sr_uuid}" class="{[this.qaClass(values)]}">' +
                            '<h4>{ques_value}</h4>' +
                            '<div id="response-value-{sr_uuid}" class="response-value">' +
                                '{[AIR2.Util.Response.formatResponse(values)]}' +
                            '</div>' +
                            '<div class="last-mod" id="lastUpdate{sr_uuid}">' +
                                '{sr_upd_user:this.lastUpdatedResponse}' +
                            '</div>' +
                            // response meta
                            '<div id="response-meta-{sr_uuid}" class="response-meta clearfix">' +
                                // response annotations
                                '<div class="annotate">' +
                                    '<a href="{sran_url}" ' +
                                    'class="sran-expand">' +
                                        '<i class="icon-comment"></i> <span class="sran-count ' +
                                        '{sran_count:this.emptyCls}">' +
                                            '{sran_count}' +
                                        '</span>' +
                                    '</a>' +
                                    '<img class="spinner" src="' +
                                        AIR2.HOMEURL + '/css/img/loading.gif"' +
                                    '/>' +
                                '</div>' +
                                // response publish status
                                '<div class="publishing">' +
                                    '{sr_public_flag:' +
                                    'this.displayResponseOptions}' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                    '</tpl>' +
                 '</div>' +
                // source data
                '<div class="sub-side">' +
                    '<h4 class="sub-source">{.:air.sourceName(1,1)}</h4>' +
                    '<ul class="src-info">' +
                        '{.:this.srcInfo}' +
                    '</ul>' +
                    '<hr>' +
                    // submission annotations
                    '<h4 class="sub-ann">Submission Annotations</h4>' +
                    '<a href="{srsan_url}" class="add-srsan">' +
                        '<span class="ann-total">{live_srsan_count}</span>' +
                        '<span class="add">Add annotation</span>' +
                    '</a>' +
                    '<hr>' +
                    // submission tags
                    '<h4 class="sub-tags">Submission Tags</h4>' +
                    '<ul class="tags">' +
                        '<tpl for="live_tags">' +
                            '<li>' +
                                '<a class="tag">' +
                                    '{.:air.tagName}&nbsp;' +
                                    '<span>{usage_count}</span>' +
                                '</a>' +
                                '<tpl if="parent.may_write">' +
                                    '<a class="delete tag-telete" ' +
                                    'href="{parent.tag_url}/{tm_id}.json">' +
                                    '</a>' +
                                '</tpl>' +
                            '</li>' +
                        '</tpl>' +
                    '</ul>' +
                    '<tpl if="may_write">' +
                        //taghandler will render here
                        '<div class="tag-adding-ct"></div>' +
                    '</tpl>' +
                '</div>' +
            '</td>' +
        '</tr>',
        {
            compiled: true,
            isSpinning: false,
            hasContributorResponses: function(values) {
                //Logger(values);
                var nContrib = 0;
                Ext.each(values.qa, function(item,idx,all) {
                    if (item.type == 'Z') {
                        nContrib++;
                    }
                });
                return nContrib;
            },
            publishState: function (publish_state) {
                switch (publish_state) {
                case AIR2.Reader.CONSTANTS.PUBLISHED:
                    return 'published';
                case AIR2.Reader.CONSTANTS.UNPUBLISHABLE:
                    return 'unpublishable';
                default:
                    return 'notPublished';
                }
            },
            qaClass: function (srs) {
                if (srs.ques_type.toLowerCase() === 'p') {
                    return 'permission-question';
                }
                if (srs.is_contrib) {
                    return 'contributor-question air2-hidden';
                }
                return '';
            },
            lastUpdatedResponse: function (myClass, values) {

                var dateText,
                    fetchedLink,
                    userLink,
                    userLinkDOMid,
                    userTargetId;

                // set in the tmpl
                userLinkDOMid = 'lastUpdate' + values.sr_uuid;
                userTargetId  = Ext.id(null, 'air2-sr-upd-user');
                userLink = '';

                if (values.sr_mod_value) {
                    dateText = 'Last modified on ';
                    dateText += AIR2.Format.dateWeek(values.srs_date, true);

                    fetchedLink = AIR2.Util.User.fetchLink(
                        values.sr_upd_user,
                        true,
                        true,
                        userTargetId
                    );

                    if (fetchedLink) {
                        // we have text now
                        userLink = dateText + ' by ' + fetchedLink;
                    }
                    else {
                        // fetchLink() will fill it in using userTargetId
                        userLink = dateText + ' by <span id="' + userTargetId;
                        userLink += '"></span>';
                    }
                }
                return userLink;
            },
            displayResponseOptions: function (sr_public_flag, values) {
                var responseOptions = '';

                if (
                    values.publish_state != AIR2.Reader.CONSTANTS.UNPUBLISHABLE
                ) {
                    if (!values.is_contrib) {
                        responseOptions += this.includeExcludeButton(sr_public_flag, values);
                    }
                    responseOptions += this.editButton(
                        sr_public_flag,
                        values
                    );
                    responseOptions += this.showOriginal(
                        values.sr_mod_value,
                        values
                    );
                }
                return responseOptions;
            },
            editButton: function (sr_public_flag, values) {
                var classes, editResponse;

                //Logger('editButton:', sr_public_flag, values);

                editResponse = '';
                // authz check
                if (
                    !AIR2.Util.Authz.hasAnyId(
                        'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                        values.owner_org_ids.split(',')
                    )
                ) {
                    return '';
                }

                classes = 'edit ';
                if (values.ques_type.toLowerCase() === 'p') {
                    classes += 'permission ';
                }

                editResponse = '<a id="response-edit-button-'+values.sr_uuid;
                editResponse += '" data-sr_uuid="'+values.sr_uuid+'" href="' + values.resp_edit_url;
                editResponse += '" class="' + classes;
                editResponse += '"><span class="submission-edit">';
                editResponse += '<i class="icon-pencil" ext:qtip="Edit Response"></i></span>';
                editResponse += '</a>';

                return editResponse;

            },
            displayPublishState: function (publish_state, values) {
                var display,
                    status,
                    theClass,
                    linkId,
                    title;
                linkId = 'air2-publish-link-' + values.srs_uuid;
                if (
                    values.perm_resp &&
                    publish_state != AIR2.Reader.CONSTANTS.UNPUBLISHABLE
                ) {
                    display = '<a id="'+linkId+'" href="' + values.srs_url;
                    display += '" data-srs_uuid="' + values.srs_uuid;
                    display += '" data-perm_resp="' + values.perm_resp;
                    display += '" data-publish_state="' + publish_state;
                    display += '" class="publishStatus ';
                }
                else {
                    //If it's unpublishable, we don't want to display anything.
                    return '';
                }
                status = 'Unpublishable';
                title = 'This submission cannot be published because there ';
                title += 'are no publishable questions.';
                theClass = '';

                if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                    theClass = 'published';
                    status = 'Published';
                    title = 'Unpublishing this submission will remove it from ';
                    title += 'the Publish API, making it private.';
                }
                else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
                    status = 'Unpublished';
                    title = 'Publishing this submission will include it in the';
                    title += ' Publish API, making it visible to the public.';
                    theClass = 'unpublished';
                }
                else if (
                    publish_state == AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH
                ) {
                    theClass = 'nothing-to-publish';
                    status = 'Nothing to publish';
                    title = 'This submission cannot be published because ';
                    title += 'there is nothing to approve. Please select ';
                    title += 'responses to include.';
                }
                else if (
                    publish_state == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
                ) {
                    theClass = 'unpublished-private';
                    status = 'Private';
                    title = 'Source has not given permission to publish ';
                    title += 'this submission. If you\'ve received ';
                    title += 'permission, click to override.';
                }

                // undo if no authz
                if (
                    !AIR2.Util.Authz.hasAnyId(
                        'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                        values.qa[0].owner_orgs.split(',')
                    )
                ) {
                    display = '<span';
                    title = 'You do not have permission to change status.';
                    display += 'title="' + title + '">' + status + '</span>';
                    return display;
                }
                display += theClass + '" ';
                display += '>' + status + '</a>';

                return display;
            },
            refUrl: function (srs_uri) {
                if (srs_uri) {
                    return '<span class="copy-ref-url">' +
                        Ext.util.Format.ellipsis(srs_uri, 50) + '</span>';
                }
                return "(none)";
            },
            emptyCls: function (count) {
                if (count) {
                    return '';
                }
                else {
                    return 'norm';
                }
            },
            queryLink: function (inq_uuid, values) {
                if (inq_uuid) {
                    // mock up fake Inquiry object
                    return AIR2.Inquiry.uriForQuery({
                        inq_uuid:inq_uuid,
                        inq_ext_title:values.inq_ext_title,
                        Locale: {loc_key: 'en_US'} // TODO include locale in search results
                    });
                }
                return '#';
            },
            permaLink: function (srs_uuid) {
                if (srs_uuid) {
                    return AIR2.HOMEURL + '/submission/' + srs_uuid;
                }
                return '#';
            },
            printLink: function (srs_uuid) {
                if (srs_uuid) {
                    return AIR2.HOMEURL + '/submission/' + srs_uuid + '.phtml';
                }
                return '#';
            },
            publishedAt: function (inq_publish_dtim, values) {
                var cre, fetchedLink, pub, pubAtStr, userLink, userTargetId;

                pubAtStr = '';
                userTargetId = Ext.id(null, 'air2-inq-cre-user');
                fetchedLink = AIR2.Util.User.fetchLink(
                    values.inq_cre_user,
                    true,
                    true,
                    userTargetId
                );
                if (fetchedLink !== null) {
                    // we have text now
                    userLink = fetchedLink;
                }
                else {
                    // fetchLink() will fill it in using userTargetId
                    userLink = '<span id="' + userTargetId + '"></span>';
                }
                if (inq_publish_dtim) {
                    pub = AIR2.Format.dateWeek(inq_publish_dtim, true);
                    pubAtStr = pub + ' by ' + userLink;
                }
                else {
                    cre = AIR2.Format.dateWeek(values.inq_cre_dtim, true);
                    pubAtStr = 'Query created on ' + cre + ' by ' + userLink;
                }
                return pubAtStr;
            },
            includeExcludeButton: function (sr_public_flag, values) {
                if (values.ques_public_flag == 0 || values.ques_public_flag == false) {
                    return '';
                }
                // if no authz, display only with no clickable item
                if (
                    !AIR2.Util.Authz.hasAnyId(
                        'ACTION_ORG_PRJ_INQ_SRS_UPDATE',
                        values.owner_org_ids.split(',')
                    )
                ) {
                    if (sr_public_flag == 1 || sr_public_flag == true) {
                        return '<a href="javascript://" class="included">' +
                            '<span>' +
                                '<i class="icon-ok" ext:qtip="' +
                                    'Included for Publishing. You do not ' +
                                    'have permission to change this."></i>' +
                            '</span>' +
                        '</a>';
                    }
                    else {
                        return '<a href="javascript://" class="excluded">' +
                            '<span>' +
                                '<i class="icon-ban-circle" ext:qtip="' +
                                'Excluded from Publishing. You do not have ' +
                                'permission to change this."></i>' +
                            '</span>' +
                        '</a>';
                    }
                }

                if (sr_public_flag == 1 || sr_public_flag == true) {
                    return '<a href="' + values.resp_edit_url +
                         '" class="included override" data-resp_id="' +
                         values.sr_uuid + '" data-submission_uuid="' +
                         values.srs_uuid + '">' +
                        '<span><i class="icon-ok" ext:qtip="Click to Exclude"></i></span>'+
                       '</a>';
                }
                else {
                    return '<a href="' + values.resp_edit_url +
                         '" class="excluded override" data-resp_id="' +
                         values.sr_uuid + '" data-submission_uuid="' +
                         values.srs_uuid + '">' +
                        '<span><i class="icon-ban-circle" ext:qtip="Click to Include"></i></span>'+
                       '</a>';
                }
            },
            showOriginal: function (sr_mod_value, values) {
                return AIR2.Reader.makeShowOriginalLink(sr_mod_value, values);
            },
            inqOrg: function (org_uuid, values) {
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
            srcInfo: function (v) {
                var all, dob, e1, e2, norm, s;

                s = '';

                e1 = v.primary_email;
                if (e1) {
                    e2 = v.primary_email_html;
                    s += '<li style="list-style:none;">';
                    s += AIR2.Format.createLink(
                        e2,
                        'mailto:' + e1,
                        true,
                        true
                    );
                    s += '</li>';
                }
                if (v.primary_phone) {
                    s += '<li style="list-style:none;">';
                    s += v.primary_phone;
                    s += '</li>';
                }
                if (
                    v.primary_city ||
                    v.primary_state ||
                    v.primary_zip ||
                    v.primary_country
                ) {
                    all = [
                        v.primary_city,
                        v.primary_state,
                        v.primary_zip,
                        v.primary_country
                    ];
                    if (v.primary_city && v.primary_state) {
                        all[0] += ',';
                    }

                    s += '<li style="list-style:none;">';
                    s += all.join(' ');
                    s += '</li>';
                }
                if (v.birth_year) {
                    dob = parseInt(v.birth_year, 10);
                    if (dob) {
                        dob = (new Date()).getFullYear() - dob;
                        s += '<li>' + dob + ' years old</li>';
                    }
                    else {
                        s += '<li>Born ' + v.birth_year + '</li>';
                    }
                }

                // just print normally the remaining facts
                norm = [
                    'education_level',
                    'ethnicity',
                    'gender',
                    'household_income',
                    'political_affiliation',
                    'religion'
                ];

                Ext.each(norm, function (key) {
                    if (key === 'household_income') {
                        v[key] = AIR2.Format.householdIncome(v[key]);
                    }
                    if (v[key]) {
                        s += '<li>' + v[key] + '</li>';
                    }
                });
                return s;
            },
            updateUser: function (updater, v) {
                if (!updater) {
                    return '';
                }
                if (v.updater_fl === 'AIR2SYSTEM AIR2SYSTEM') {
                    v.updater_fl = 'AIR2SYSTEM';
                }

                return ' by ' + AIR2.Format.createLink(
                    v.updater_fl,
                    '/user/' + v.updater_uuid,
                    true
                );
            }
        }
    );

    // exclude clicks on these <td> classes
    exclude = ['handle', 'checker', 'starred'];

    // handler to expand a node
    expandNode = function (node, e) {
        var dom,
            expanded,
            next,
            permHeader,
            rec,
            rsp,
            srids,
            srsDv,
            top,
            submissionButton,
            overrideButtons,
            publish_state,
            title,
            magicSorter;

        next = Ext.fly(node).next();

        if (next && next.hasClass('reader-expand')) {
            return false; //already expanded
        }
        Ext.fly(node).addClass('row-expanded');

        rec = dv.getRecord(node);
        srids = rec.data.sr_ids.split(':');

        // mark as read
        if (!rec.data.live_read) {
            rec.data.live_read = true;
            Ext.fly(node).removeClass('row-unread');
            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/reader/read/' + rec.data.srs_uuid +
                    '.json',
                failure: function () {
                    rec.data.live_read = false;
                    Ext.fly(node).addClass('row-unread');
                }
            });
        }

        // template-friendlify data
        rec.data.friendly = [];
        Ext.each(rec.data.qa, function (qa, i) {
            var modValue = null;

            if (
                rec.data.qa_mod &&
                rec.data.qa_mod[i] &&
                rec.data.qa_mod[i].substring(0, 1) === ':'
            ) {
                modValue = rec.data.qa_mod[i].substring(1);
            }
            // normalize data from multiple fields
            rsp = {
                authz:            qa.authz_orgs,
                owner_org_ids:    qa.owner_orgs,
                inq_uuid:         qa.inq_uuid,
                srs_uuid:         rec.data.srs_uuid,
                sr_id:            srids[i],
                ques_dis_seq:     parseInt(qa.seq, 10),
                ques_type:        qa.type,
                ques_value:       qa.ques_value,
                srs_date:         qa.date,
                sr_orig_value:    qa.resp,
                sr_mod_value:     modValue,
                sran_count:       rec.data.live_sran_counts[i],
                sr_public_flag:   qa.public_flag,
                publish_state:    rec.data.publish_state,
                sr_upd_user:      qa.upd_user_uuid,
                sr_uuid:          qa.sr_uuid,
                ques_public:      rec.data.public_flags.ques,
                ques_public_flag: qa.ques_public_flag
            };

            rsp.sran_url = AIR2.HOMEURL + '/submission/' + rsp.srs_uuid;
            rsp.sran_url += '/response/' + rsp.sr_id + '/annotation.json';

            rsp.resp_edit_url = AIR2.HOMEURL + '/submission/' + rsp.srs_uuid;
            rsp.resp_edit_url += '/response/' + rsp.sr_uuid + '.json';

            if (rsp.ques_type.toLowerCase() === 'p') {
                rec.data.perm_resp = qa.sr_uuid;
            }

            rec.data.friendly.push(rsp);

        });


        // sort responses by question type and dis_seq, similar
        // to how they display in the Form
        magicSorter = function(responses) {
            var sorted, perm_ques, flattened;

            // group questions into 3 groups
            sorted = {
                contributor: [],
                public: [],
                private: []
            };
            Ext.each(responses, function(r, i) {
                if (r.ques_type.toLowerCase() == 'z'
                 || r.ques_type.toLowerCase() == 's'
                 || r.ques_type.toLowerCase() == 'y'
                ) {
                    r.is_contrib = true;
                    if (r.ques_value && r.ques_value.match(/e-?mail/i) && r.sr_orig_value != rec.data.primary_email) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/first name/i) && r.sr_orig_value != rec.data.src_first_name) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/last name/i) && r.sr_orig_value != rec.data.src_last_name) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/phone/i) && r.sr_orig_value != rec.data.primary_phone) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/state/i) && r.sr_orig_value != rec.data.primary_state) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/city/i) && r.sr_orig_value != rec.data.primary_city) {
                        r.is_contrib_diff = true;
                    }
                    if (r.ques_value && r.ques_value.match(/postal|zip/i) && r.sr_orig_value != rec.data.primary_zip) {
                        r.is_contrib_diff = true;
                    }
                    sorted.contributor.push(r);
                }
                else if (r.ques_type.toLowerCase() == 'p') {
                    perm_ques = r;
                }
                else if (r.ques_type == AIR2.Inquiry.QUESTION.TYPE.BREAK ||
                         r.ques_type == AIR2.Inquiry.QUESTION.TYPE.DISPLAY ) {
                    //no-op on breaks and displays
                }
                else if (r.ques_public_flag == 1) {
                    sorted.public.push(r);
                }
                else {
                    sorted.private.push(r);
                }
            });

            // if perm ques is private, respect dis_seq
            if (!sorted.public.length && perm_ques) {
                sorted.private.push(perm_ques);
            }

            // now sort by sequence
            sorted.contributor.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });
            sorted.public.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });
            sorted.private.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });

            // if perm question is public, force last
            if (sorted.public.length && perm_ques) {
                sorted.public.push(perm_ques);
            }

            // finally flatten the arrays into a single list
            flattened = [];
            Ext.each(sorted.contributor, function(q,i) {
                flattened.push(q);
            });
            Ext.each(sorted.public, function(q,i) {
                flattened.push(q);
            });
            Ext.each(sorted.private, function(q,i) {
                flattened.push(q);
            });

            //Logger(flattened);

            return flattened;
        };

        rec.data.friendly = magicSorter(rec.data.friendly);

        rec.data.srs_url = AIR2.HOMEURL + '/submission/' + rec.data.srs_uuid;
        rec.data.srs_url += '.json';

        rec.data.srsan_url = AIR2.HOMEURL + '/submission/' + rec.data.srs_uuid;
        rec.data.srsan_url += '/annotation.json';

        rec.data.tag_url = AIR2.HOMEURL + '/submission/' + rec.data.srs_uuid;
        rec.data.tag_url += '/tag';

        // determine if user can write to this submission (have to check the
        // actual org_uuids, since subm-write authz does NOT cascade down like
        // read authz)
        rec.data.may_write = false;
        Ext.each(rec.data.org_uuid.split('\003'), function (uuid) {
            if (AIR2.Util.Authz.has('ACTION_ORG_PRJ_INQ_SRS_UPDATE', uuid)) {
                rec.data.may_write = true;
            }
        });

        // render expanded data template
        dom = expandTpl.insertAfter(node, rec.data);

        // post-render hooks
        AIR2.Reader.tagRender(dom, rec);

        expanded = Ext.select('div.submission');

        overrideButtons  = Ext.select('a.override');
        if (overrideButtons) {
            overrideButtons.on('mouseover', AIR2.Reader.exclMouseOver);
            overrideButtons.on('mouseout',  AIR2.Reader.exclMouseOut);
        }

        submissionButton = Ext.select('a.publishStatus');
        submissionButton = Ext.get(submissionButton.elements[0]);
        if (submissionButton) {
            publish_state = submissionButton.getAttribute('data-publish_state');
        }
        else {
            publish_state = 0;
        }
        title = 'This submission cannot be published because there ';
        title += 'are no publishable questions.';


        if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
            title = 'Unpublishing this submission will remove it from ';
            title += 'the Publish API, making it private.';
        }
        else if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHABLE) {
            title = 'Publishing this submission will include it in the';
            title += ' Publish API, making it visible to the public.';
        }
        else if (
            publish_state == AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH
        ) {
            title = 'This submission cannot be published because ';
            title += 'there is nothing to approve. Please select ';
            title += 'responses to include.';
        }
        else if (
            publish_state == AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE
        ) {
            title = 'Source has not given permission to publish ';
            title += 'this submission. If you\'ve received ';
            title += 'permission, click to override.';
        }

        if (submissionButton) {
            submissionButton.tooltip = new Ext.ToolTip({
                target: submissionButton.id,
                html: title,
                showDelay: 2000,
                baseCls: 'air2-tip'
            });
            submissionButton.on('mouseover', AIR2.Reader.publishButtonMouseOver);
            submissionButton.on('mouseout', AIR2.Reader.publishButtonMouseOut);
            if (publish_state == AIR2.Reader.CONSTANTS.PUBLISHED) {
                submissionButton.isPublished = true;
            }
            else {
                submissionButton.isPublished = false;
            }
        }

        // scroll if class indicates
        if (e && e.getTarget('.scroll-to-permission')) {
            return; // TODO solve scrolling problem
            srsDv = Ext.get(dom);
            permHeader = srsDv.query('.permission-question h4');
            if (!permHeader || !permHeader.length) {
                return;
            }

            Ext.get(permHeader[0]).addClass('highlight');
            top = srsDv.getTop(); // TODO is this the right el to calc from?
            Ext.getBody().scrollTo('top', Math.max(top - 200, 0), false);
        }
    };

    // handler to close a node
    closeNode = function (node) {
        Ext.fly(node).removeClass('row-expanded');
        var next = Ext.fly(node).next();
        if (next && next.hasClass('reader-expand')) {
            next.remove(); // remove from dom
            return true;
        }
        return false;
    };

    // handle row clicks
    AIR2.Reader.toggleRowExpand = function (dv, index, node, e) {
        var el, i;

        el = e.getTarget('td');

        // return if this is a link
        if (e.getTarget('a')) {
            return;
        }

        // special case for Public column which is value-dependent for expand
        if (e.getTarget('.public-state')) {
            return;
        }

        // return if click excluded
        for (i = 0; i < exclude.length; i++) {
            if (
                (
                    ' ' + el.className + ' '
                ).indexOf(
                    ' ' + exclude[i] + ' '
                ) !== -1
            ) {
                return;
            }
        }

        // toggle closed, or expand it
        if (!closeNode(node)) {
            expandNode(node, e);
        }
    };

    // handle row clicks
    dv.on('click', AIR2.Reader.toggleRowExpand);

    // helpers to expand/collapse all
    AIR2.Reader.expandAll = function () {
        var all, i;

        all = dv.getNodes();

        for (i = 0; i < all.length; i++) {
            expandNode(all[i]);
        }
    };
    AIR2.Reader.collapseAll = function () {
        var all, i;

        all = dv.getNodes();
        for (i = 0; i < all.length; i++) {
            closeNode(all[i]);
        }
    };
    AIR2.Reader.makeShowOriginalLink = function (sr_mod_value, values) {
        var classes, originalLink, questionType, responseIsPublic, srs_uuid, resp_edit_url;

        //Logger('showOriginal link gen:', sr_mod_value, values);

        if (sr_mod_value === null) {
            return '';
        }

        if (values.srs_uuid) {
            srs_uuid = values.srs_uuid;
        }
        else if (values.SrcResponseSet) {
            srs_uuid = values.SrcResponseSet.srs_uuid;
        }
        else {
            Logger("no srs_uuid in ", values);
        }

        if (values.resp_edit_url) {
            resp_edit_url = values.resp_edit_url;
        }
        else {
            resp_edit_url = '#';
        }

        originalLink = '<a id="response-show-original-button-'+values.sr_uuid;
        originalLink += '" data-sr_uuid="'+values.sr_uuid;
        originalLink += '" data-srs_uuid="'+srs_uuid;
        originalLink += '" href="' + resp_edit_url + '" class="';
        classes = 'orig';

        // Want to avoid repeating the lowercase conversion,
        // for readability
        if (values.ques_type) {
            questionType = values.ques_type.toLowerCase();
        }
        else if (values.Question) {
            questionType = values.Question.ques_type.toLowerCase();
        }
        else {
            Logger("No ques_type found in values: ", values);
        }

        responseIsPublic = false;

        //consolidating this logic into a variable to make the class
        //determination below easier to read.
        if (
            values.sr_public_flag == 1 ||
            values.sr_public_flag == true
        ) {
            responseIsPublic = true;
        }
        //Logger("Values", values.sr_public_flag);
        if (   values.ques_public_flag == 0
            && questionType != 'p'
            && (values.sr_public_flag == 0 || values.sr_public_flag == false)
            && !values.is_contrib
        ) {
            return '';
        }

        originalLink += classes;
        originalLink += '" title="Click to view original response.">';
        originalLink += '<span>Show Original</span></a>';

        return originalLink;
    };

    getExpandedIdx = function () {
        var xpand = dv.el.query('.reader-expand');
        if (xpand.length === 0) {
            return -1;
        }
        if (xpand.length > 1) {
            return false;
        }

        return dv.indexOf(xpand[0].previousSibling);
    };
    scrollTo = function (nodeIdx) {
        var node, top;

        node = dv.all.elements[nodeIdx];
        top = Ext.fly(node).getTop();
        Ext.getBody().scrollTo('top', Math.max(top - 200, 0), false);
    };

};
