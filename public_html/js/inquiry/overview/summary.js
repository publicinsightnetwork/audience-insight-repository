/***********************
 * Inquiry Summary Panel
 */
AIR2.Inquiry.Summary = function () {
    var duplicateButton,
        tpl,
        inqRadix,
        uuid,
        pinButton,
        embedButton,
        isFormbuilder,
        isNonJourno,
        isQuerymaker;

    inqRadix = AIR2.Inquiry.BASE.radix;
    isFormbuilder = (inqRadix.inq_type === 'F');
    isQuerymaker  = (inqRadix.inq_type === 'Q');
    isNonJourno   = (inqRadix.inq_type === 'N');
    uuid = AIR2.Inquiry.UUID;

    // PINbutton embed code generator
    if (isFormbuilder || isQuerymaker || isNonJourno) {
        pinButton = new AIR2.UI.Button({
            air2type: 'CLEAR',
            iconCls: 'air2-icon-pinbutton',
            ctCls: 'air2-pinbutton',
            text: 'Get Insight Button code',
            handler: function (btn) {
                AIR2.Inquiry.Pinbutton(btn.el);
            }
        });
        embedButton = new AIR2.UI.Button({
            air2type: 'CLEAR',
            iconCls: 'air2-icon-embedcode',
            ctCls: 'air2-embedcode',
            text: 'Get Insight Embed code',
            handler: function (btn) {
                AIR2.Inquiry.EmbedCode(btn.el);
            }
        });
    }
    duplicateButton = new AIR2.UI.Button({
        air2size: 'SMALL',
        air2type: 'FRIENDLY',
        hideParent: false,
        iconCls: 'air2-icon-duplicate',
        id: 'air2-inquiry-duplicate',
        title: 'Duplicate Query',
        text: 'Duplicate',
        handler: function (button, event) {
            var editview, msg, radix;

            AIR2.APP.el.mask('Duplicating...');

            radix = Ext.encode({
                source_query_uuid: AIR2.Inquiry.UUID
            });

            if (!AIR2.Inquiry.BASE.radix.inq_rss_intro) {
                msg = 'You will need to update the Short Description of your new Query.';
                AIR2.UI.ErrorMsg(AIR2.Inquiry.Summary, "Error", msg);
            }

            Ext.Ajax.request({
                url: AIR2.HOMEURL + '/inquiry.json',
                params: {
                    'radix': radix
                },
                callback: function (opt, success, rsp) {
                    var data, msg;

                    data = false;
                    try {
                        data = Ext.decode(rsp.responseText);
                    }
                    catch (err) {
                        data = {
                            success: false,
                            message: 'Json-decode error!'
                        };
                    }

                    success = data.success || false;
                    if (!success) {
                        if (data && data.message) {
                            msg = data.message;
                        }
                        else {
                            msg = 'Unknown Error';
                        }
                        AIR2.APP.el.unmask();
                        AIR2.UI.ErrorMsg(AIR2.Inquiry.Summary, "Error", msg);
                    }
                    else {
                        if (data && data.radix && data.radix.inq_uuid) {
                            location.href = AIR2.HOMEURL + '/query/' + data.radix.inq_uuid;
                        }
                        else {
                            AIR2.APP.el.unmask();
                            msg = 'Unable to retrieve the new query. Please contact support.';
                            AIR2.UI.ErrorMsg(AIR2.Inquiry.Summary, "Error", msg);
                        }
                    }
                }
            });
        }
    });

    // template
    tpl = new Ext.XTemplate(
        '<tpl for=".">' +
            '<table class="inquiry-row">' +
               '<tr>' +
                 '<td class="label">Status</td>' +
                 '<td class="value">' +
                  '<div id="air2-inq-status" class="air2-inq-status-{inq_status}">{[this.getStatus(values)]}</div>' +
                 '</td> ' +
                '</tr>' +
               '<tr>' +
                 '<td class="label">Logo</td>' +
                 '<td class="value">' +
                  '<div id="air2-inq-logo">{[AIR2.Format.inqLogo(values)]}</div>' +
                 '</td> ' +
                '</tr>' +
               '<tr>' +
                 '<td class="label">Title</td>' +
                 '<td class="value">' +
                  '<h2>{inq_ext_title}</h2>' +
                 '</td>' +
               '</tr>' +
                // query meta
               '<tr>' +
                 '<td class="label">Projects</td>' +
                 '<td class="value">{[this.formatProjects(values)]}</td>' +
               '</tr>' +
               '<tr>' +
                 '<td class="label">Organizations</td>' +
                 '<td class="value">{[this.formatOrganizations(values)]}</td>' +
               '</tr>' +
               '<tr>' +
                 '<td class="label">Authors</td>' +
                 '<td class="value">{[this.formatAuthors(values)]}</td>' +
               '</tr>' +
               '<tr>' +
                 '<td class="label">Watchers</td>' +
                 '<td class="value">{[this.formatWatchers(values)]}</td>' +
               '</tr>' +
               '<tr>' +
                 '<td class="label">Created</td>' +
                 '<td class="value">' +
                    '<div>{[AIR2.Format.date(values.inq_cre_dtim)]}' +
                    ' by ' +
                    '{[AIR2.Format.userName(values.CreUser,1,1)]}</div>' +
                 '</td>' +
               '</tr>' +
                '<tpl if="values.inq_publish_dtim">' +
                   '<tr>' +
                      '<td class="label">Published</td>' +
                      '<td class="value">' +
                         '<div>{[AIR2.Format.date(values.inq_publish_dtim)]}</div>' +
                      '</td>' +
                   '</tr>' +
               '</tpl>' +
               '<tpl if="this.isPublished(values)">' +
                 '<tr>' +
                   '<td class="label">Links</td>' +
                   '<td class="value">' +
                    '<div class="inquiry-links">' +
                     '<div>' +
                      '<tpl if="values.inq_url">' +
                       '<div>Custom URL:</div>' +
                       '<div><a target="_blank" href="{inq_url}">{inq_url}</a></div>' +
                      '</tpl>' +
                      '<div>Full:</div>' +
                      '<div><a target="_blank" href="{[this.publishedLink(values)]}">{[this.publishedLink(values)]}</a></div>' +
                     '</div>' +
                     '<div>' +
                      '<div>Short:</th>' +
                      '<div><a target="_blank" href="{[this.shortPublishedLink(values)]}">{[this.shortPublishedLink(values)]}</a></div>' +
                     '</div>' +
                     '<div>' +
                      '<div>Iframe:</div>' +
                      '<div><a target="_blank" href="{[this.iframePublishedLink(values)]}">{[this.iframePublishedLink(values)]}</a></div>' +
                     '</div>' +
                    '</div>' +
                   '</td>' +
                 '</tr>' +
               '</tpl>' +

               // optional RSS intro
               '<tpl if="this.hasRssIntro(values)">' +
                 '<tr>' +
                   '<td class="label">Description</td>' +
                   '<td class="value">' +
                      '<div>{inq_rss_intro}</div>' +
                   '</td>' +
                 '</tr>' +
               '</tpl>' +

               // optional confirmation message
               '<tpl if="inq_confirm_msg">' +
                 '<tr>' +
                    '<td class="label">Custom Confirmation</td>' +
                    '<td class="value">{inq_confirm_msg}</td>' +
                 '</tr>' +
               '</tpl>' +

               // QUESTIONS
               '<tr>' +
                 '<td class="label">Questions</td>' +
                 '<td class="value">' +
                   '<div>{[this.numQuestions(values)]}</div>' +
                 '</td>' +
               '</tr>' +
            '</table>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            isAQuery: function() {
                return isFormbuilder || isQuerymaker || isNonJourno || false;
            },
            isPublished: function(values) {
                if (values.inq_status.match(/^[AELS]$/)
                    && values.inq_publish_dtim
                ) {
                    return true;
                }
                return false;
            },
            getStatus: function(values) {
                var stat, statMap;
                stat = values.inq_status;
                statMap = {
                    'A': 'Published',
                    'E': 'Expired',
                    'D': 'Draft',
                    'F': 'Inactive',
                    'S': 'Scheduled',
                    'L': 'Published with Deadline'
                };
                return statMap[stat];
            },
            shortPublishedLink: function(values) {
                var locale = values.Locale.loc_key.replace(/_US$/, '');
                return AIR2.FORMURL + locale + '/' + values.inq_uuid;
            },
            iframePublishedLink: function(values) {
                var locale = values.Locale.loc_key.replace(/_US$/, '');
                return AIR2.MYPIN2_URL + '/' + locale + '/insight/iframe/' + values.inq_uuid;
            },
            publishedLink: function(values) {
                return AIR2.Inquiry.uriForQuery(values);
            },
            hasRssIntro: function (values) {
                return (values.inq_rss_intro && values.inq_rss_intro.length);
            },
            numQuestions: function (values) {
                var count = AIR2.Inquiry.quesStore.getCount();
                if (!count) {
                    return '<span class="lighter">(none)</span>';
                }
                return count;
            },
            formatExports: function (values) {
                var date, i, sent, sentby, str, user;

                sentby = AIR2.Inquiry.STATSDATA.radix.SentBy;
                if (sentby && sentby.length) {
                    str = '<ul>';

                    for (i = 0; i < sentby.length; i++) {
                        sent = sentby[i].sent_count + ' Source';
                        sent += (sentby[i].sent_count > 1) ? 's' : '';
                        //sent = '<a href="#">'+sent+'</a>';
                        date = Date.parseDate(sentby[i].sent_date, "Y-m-d");
                        date = AIR2.Format.date(date);
                        user = AIR2.Format.userName(sentby[i], true, true);

                        str += '<li>Sent to ' + sent + ' on ' + date + ' by ';
                        str += user + '</li>';
                    }
                    return str + '</ul>';
                }
                else {
                    return '<span class="lighter">(none)</span>';
                }
            },
            formatAuthors: function (values) {
                var s, str, authors;

                s = AIR2.Inquiry.authorStore;
                if (s.getCount() === 0) {
                    return '<span class="lighter">(none)</span>';
                }

                str = '<span class="authors">';
                authors = [];
                s.each(function (rec) {
                    authors.push(AIR2.Format.userName(rec.data.User, true));
                });
                return str + authors.join('; ') + '</span>';
            },
            formatWatchers: function (values) {
                var s, str, watchers;

                s = AIR2.Inquiry.watcherStore;
                if (s.getCount() === 0) {
                    return '<span class="lighter">(none)</span>';
                }

                str = '<span class="watchers">';
                watchers = [];
                s.each(function (rec) {
                    watchers.push(AIR2.Format.userName(rec.data.User, true));
                });
                return str + watchers.join('; ') + '</span>';
            },
            formatOrganizations: function (values) {
                var s, str;

                s = AIR2.Inquiry.orgStore;
                if (s.getCount() === 0) {
                    return '<span class="lighter">(none)</span>';
                }

                str = '<span class="orgs">';
                s.each(function (iorg) {
                    str += AIR2.Format.orgName(iorg.data.Organization, true) +
                        ' ';
                });
                return str + '</span>';
            },
            formatProjects: function (values) {
                var s, str;

                s = AIR2.Inquiry.prjStore;
                if (s.getCount() === 0) {
                    return '<span class="lighter">(none)</span>';
                }
                str = '<span class="prjs">';
                s.each(function (pinq) {
                    str += AIR2.Format.projectName(pinq.data.Project, true) +
                        ', ';
                });
                str = str.substr(0, str.length - 2); //remove last comma
                return str + '</span>';
            }
        }
    );

    // return panel
    AIR2.Inquiry.Summary = new AIR2.UI.Panel({
        cls:            'air2-inquiry-summary',
        colspan:        1,
        dragMode:       false,
        editMode:       false,
        iconCls:        'air2-icon-clipboard',
        id:             'air2-inquiry-summary',
        itemSelector:   '.inquiry-row',
        rowspan:        1, //push other panels to the right
        store:          AIR2.Inquiry.inqStore,
        title:          'Summary',
        tools:          ['->', duplicateButton, pinButton, embedButton],
        tpl:            tpl
    });

    return AIR2.Inquiry.Summary;
};
