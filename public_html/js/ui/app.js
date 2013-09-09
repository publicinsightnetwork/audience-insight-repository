Ext.ns('AIR2.UI.App');
/***************
 * AIR2 App Component
 *
 * Primary application used in AIR2.  Sets up title/project/location info at
 * the top of the page, and loads dragzones and the Drawer component.
 *
 * @class AIR2.UI.App
 * @extends Ext.Container
 * @xtype air2app
 * @cfg {Array} items
 *   Items to render in the body of the application.
 *
 */
AIR2.UI.App = function (config) {
    var addAuthz,
        form,
        isGlobalManager,
        isWriter,
        newstuff,
        showAddMenu,
        showOutExp,
        showQueue,
        stype;

    config.id = 'air2-app'; // ALWAYS set a static ID

    this.bufferEl = document.createElement('div');
    this.headerEl = Ext.get('air2-header');
    this.locationEl = Ext.get('air2-location-wrap').child('.air2-location');

    // recent buttons
    this.addRecentButton({
        view: 'project',
        iconCls: 'air2-icon-project',
        data: AIR2.RECENT.project,
        uuid: 'prj_uuid',
        tooltip: 'Recent&nbsp;Projects',
        textFn: function (data) {return data.prj_display_name; }
    });
    this.addRecentButton({
        view: 'source',
        iconCls: 'air2-icon-source',
        data: AIR2.RECENT.source,
        uuid: 'src_uuid',
        tooltip: 'Recent&nbsp;Sources',
        textFn: function (data) {return AIR2.Format.sourceName(data); }
    });
    this.addRecentButton({
        view: 'inquiry',
        iconCls: 'air2-icon-inquiry',
        data: AIR2.RECENT.inquiry,
        uuid: 'inq_uuid',
        tooltip: 'Recent&nbsp;Queries',
        textFn: function (data) {return AIR2.Format.inquiryTitle(data); }
    });
    this.addRecentButton({
        view: 'submission',
        iconCls: 'air2-icon-responses',
        data: AIR2.RECENT.submission,
        uuid: 'srs_uuid',
        tooltip: 'Recent&nbsp;Submissions',
        textFn: function (data) {
            var s = AIR2.Format.sourceName(data) + ' - ';
            s += Ext.util.Format.ellipsis(data.inq_ext_title, 50);
            return s;
        }
    });

    // new stuff authz
    addAuthz = {
        src: AIR2.Util.Authz.has('ACTION_ORG_SRC_CREATE'),
        srs: AIR2.Util.Authz.has('ACTION_ORG_PRJ_INQ_SRS_CREATE'),
        inq: AIR2.Util.Authz.has('ACTION_ORG_PRJ_INQ_CREATE'),
        prj: AIR2.Util.Authz.has('ACTION_ORG_PRJ_CREATE'),
        //org: AIR2.Util.Authz.has('ACTION_ORG_CREATE'),
        org: (AIR2.USERINFO.type === "S"), //TODO: use actual authz
        usr: AIR2.Util.Authz.has('ACTION_ORG_USR_CREATE'),
        out: AIR2.Util.Authz.has('ACTION_ORG_SRC_UPDATE'), //TODO: specific role
        eml: AIR2.Util.Authz.has('ACTION_EMAIL_CREATE')
    };
    showAddMenu = false;
    Ext.iterate(addAuthz, function (key, val) {
        if (val) {
            showAddMenu = true;
        }
    });

    // create new stuff menu
    newstuff = new AIR2.UI.Button({
        air2type: 'DARKER',
        iconCls: 'air2-icon-add',
        menuAlign: 'tl-bl?',
        hidden: !showAddMenu,
        menu: {
            cls: 'air2-header-menu use-icons',
            showSeparator: false,
            items: [{
                text: 'Email',
                iconCls: 'air2-icon-email',
                hidden: !addAuthz.eml,
                handler: function () {
                    AIR2.Email.Create({
                        originEl: newstuff.el,
                        redirect: true
                    });
                }
            }, {
                text: 'Organization',
                iconCls: 'air2-icon-organization',
                hidden: !addAuthz.org,
                handler: function () {
                    AIR2.Organization.Create({
                        originEl: newstuff.el,
                        redirect: true
                    });
                }
            }, {
                text: 'PINfluence',
                iconCls: 'air2-icon-outcome',
                hidden: !addAuthz.out,
                handler: function () {
                    AIR2.Outcome.Create({
                        originEl: newstuff.el,
                        redirect: true
                    });
                }
            }, {
                text: 'Project',
                iconCls: 'air2-icon-project',
                hidden: !addAuthz.prj,
                handler: function () {
                    AIR2.Project.Create({
                        originEl: newstuff.el,
                        org_obj: AIR2.HOME_ORG,
                        closeAction: 'close',
                        width: 450,
                        height: 365,
                        padding: '6px 0',
                        formAutoHeight: true,
                        redirect: true
                    });
                }
            }, {
                text: 'Query',
                iconCls: 'air2-icon-inquiry',
                hidden: !addAuthz.inq,
                handler: function () {
                    AIR2.Inquiry.Create({
                        originEl: newstuff.el,
                        org_obj: AIR2.HOME_ORG,
                        prj_obj: AIR2.DEFAULT_PROJECT,
                        redirect: true
                    });
                }
            }, {
                text: 'Source',
                iconCls: 'air2-icon-source',
                hidden: !addAuthz.src,
                handler: function () {
                    AIR2.Source.Create({
                        originEl: newstuff.el,
                        redirect: true,
                        org_obj: AIR2.HOME_ORG
                    });
                }
            }, {
                text: 'Submission',
                iconCls: 'air2-icon-response',
                hidden: !addAuthz.srs,
                handler: function () {
                    AIR2.Submission.Create({
                        originEl: newstuff.el,
                        redirect: true
                    });
                }
            }, {
                text: 'User',
                iconCls: 'air2-icon-user',
                hidden: !addAuthz.usr,
                handler: function () {
                    AIR2.User.Create({
                        originEl: newstuff.el,
                        redirect: true
                    });
                }
            }]
        },
        renderTo: this.bufferEl,
        tooltip: {text: 'Create', cls: 'below', align: 6},
        listeners: {
            render: function (btn) {
                var el = this.headerEl.child('.recent-stuff .air2-icon-add');
                btn.el.replace(el.parent());
            },
            scope: this
        }
    });

    // show the background queue
    showQueue = function (b) {
        var w = new AIR2.Background.QueueWin();
        w.show(b.el);
    };

    // show the outcome-exporter window
    isGlobalManager = AIR2.Util.Authz.has('AIR2_AUTHZ_ROLE_M', 'ADKLm8Okenaa');
    isWriter = AIR2.Util.Authz.has('AIR2_AUTHZ_ROLE_W');
    showOutExp = function (b) {
        AIR2.Outcome.Exporter({originEl: b.el, require_org: !isGlobalManager});
    };

    // account button
    new AIR2.UI.Button({
        air2type: 'DARKER',
        iconCls: 'air2-icon-chevron',
        menuAlign: 'tr-br?',
        menu: {
            cls: 'air2-header-menu',
            showSeparator: false,
            items: [
                {
                    text: 'Manage Profile',
                    href: AIR2.HOMEURL + '/user/' + AIR2.USERINFO.uuid
                },
                {
                    text: 'Directory',
                    href: AIR2.HOMEURL + '/directory'
                },
                {
                    text: 'Translations',
                    href: AIR2.HOMEURL + '/translation'
                },
                {
                    text: 'Bounced Emails',
                    href: AIR2.HOMEURL + '/srcemail'
                },
                {
                    text: 'Background Queue',
                    handler: showQueue
                },
                {
                    text: 'PINfluence Export',
                    handler: showOutExp,
                    hidden: !(isGlobalManager || isWriter)
                },
                {
                    text: 'Logout',
                    href: AIR2.LOGOUTURL
                }
            ]
        },
        renderTo: this.bufferEl,
        listeners: {
            render: function (btn) {
                var prev = this.headerEl.child('.account .air2-btn');
                btn.el.replace(prev);
            },
            scope: this
        }
    });

    // search buttons
    form = Ext.get('air2-search-form');
    stype = new AIR2.UI.Button({
        air2type: 'BLUE',
        iconCls: 'air2-icon-' + AIR2.SEARCHIDX,
        cls: 'search-type',
        tooltip: {text: 'Search&nbsp;Type', cls: 'below', align: 6},
        menu: {
            cls: 'air2-header-menu search',
            showSeparator: false,
            defaults: {
                xtype: 'menucheckitem',
                group: 'air2-search-header',
                clickHideDelay: 200,
                checkHandler: function (item, checked) {
                    if (checked) {
                        stype.setIconClass(item.iconCls);
                        form.dom.setAttribute('action', item.viewUrl);
                    }
                }
            },
            items: [
                {text: 'All Sources', view: 'sources'},
                {text: 'Available Sources', view: 'active-sources'},
                {text: 'Primary Sources', view: 'primary-sources'},
                {text: 'Projects', view: 'projects'},
                {text: 'Queries', view: 'inquiries', action: 'queries'},
                {text: 'Submissions', view: 'responses'}
            ]
        },
        renderTo: this.bufferEl,
        listeners: {
            render: function (btn) {
                // fix submit button
                form.addKeyListener(Ext.EventObject.ENTER, function (key, ev) {
                    ev.stopEvent();
                    form.dom.submit();
                });

                // configure menu items
                btn.menu.items.each(function (item) {
                    // note that "queries" is now an alias for "inquiries"
                    var act = item.action ? item.action : item.view;
                    item.viewUrl = AIR2.HOMEURL + '/search/' + act;
                    item.iconCls = 'air2-icon-' + item.view;
                    item.checked = false;

                    // setup the current search index
                    if (item.view === AIR2.SEARCHIDX) {
                        item.checked = true;
                        form.dom.setAttribute('action', item.viewUrl);
                    }
                });
                var el = this.headerEl.child('.search .search-type');
                btn.el.replace(el);
            },
            scope: this
        }
    });
    new AIR2.UI.Button({
        air2type: 'BLUE',
        text: 'Search',
        cls: 'search-norm',
        renderTo: this.bufferEl,
        handler: function () {
            form.dom.submit();
        },
        listeners: {
            render: function (btn) {
                var el = this.headerEl.child('.search .search-norm');
                btn.el.replace(el);
            },
            scope: this
        }
    });
    new AIR2.UI.Button({
        air2type: 'PLAIN',
        text: 'Advanced',
        cls: 'search-adv',
        renderTo: this.bufferEl,
        handler: function () {
            var el = form.createChild({
                tag: 'input',
                type: 'hidden',
                name: 'adv',
                value: 1
            });
            form.dom.submit();
        },
        listeners: {
            render: function (btn) {
                var el = this.headerEl.child('.search .search-adv');
                btn.el.replace(el);
            },
            scope: this
        }
    });

    // add floating bin slide-out
    this.drawer = new AIR2.Drawer();

    // call parent constructor
    AIR2.UI.App.superclass.constructor.call(this, config);
};
Ext.extend(AIR2.UI.App, Ext.Container, {
    renderTo: 'air2-body',
    listeners: {
        render: function (comp) {
            comp.air2DragZone = new AIR2.Drawer.DragZone(Ext.getBody(), {
                getDragData: function (event) {
                    var ddObj,
                        el;

                    el = event.getTarget('.air2-dragzone');

                    // check for hovering over the dragarrow
                    if (!el && event.getTarget('.air2-dragarrow')) {
                        el = AIR2.Drawer.hoverEl.ddEl;
                    }

                    if (el) {
                        ddObj = {
                            repairXY: Ext.fly(el).getXY(),
                            //string OR origin html element (to be cloned)
                            ddel: el,
                            ddBinType: el.getAttribute('air2type')
                        };

                        // show string instead of copying element
                        if (el.getAttribute('air2str')) {
                            ddObj.ddel = el.getAttribute('air2str');
                        }

                        if (el.getAttribute('air2uuid')) {
                            //array of UUID's OR function returning array
                            Logger({
                                uuid: el.getAttribute('air2uuid'),
                                reltype: el.getAttribute('air2rel')
                            });
                            ddObj.selections = [{
                                uuid: el.getAttribute('air2uuid'),
                                reltype: el.getAttribute('air2rel')
                            }];
                        }
                        if (el.getAttribute('air2tank')) {
                            ddObj.selections = {
                                tank_uuid: el.getAttribute('air2tank')
                            };
                        }
                        return ddObj;
                    }
                }
            });
        }
    },
    addRecentButton: function (opt) {
        var i,
            items,
            v;

        // get menu items
        items = [];
        for (i = 0; i < opt.data.length; i++) {
            v = (opt.view === 'inquiry') ? 'query' : opt.view;
            items.push({
                text: opt.textFn(opt.data[i]),
                href: AIR2.HOMEURL + '/' + v + '/' + opt.data[i][opt.uuid]
            });
        }
        if (items.length < 1) {
            items = [{text: '(none)', disabled: true}];
        }

        // create button
        new AIR2.UI.Button({
            air2type: 'DARKER',
            iconCls: opt.iconCls,
            menuAlign: 'tl-bl?',
            menu: {
                cls: 'air2-header-menu',
                showSeparator: false,
                items: items
            },
            renderTo: this.bufferEl,
            tooltip: {text: opt.tooltip, cls: 'below', align: 6},
            listeners: {
                render: function (btn) {
                    var el;
                    el = this.headerEl.child('.recent-stuff .' + opt.iconCls);
                    btn.el.replace(el.parent());
                },
                scope: this
            }
        });
    },
    setLocation: function (cfg) {
        var locEl, titleEl, type, typeEl, uuid;

        locEl = this.locationEl;
        typeEl = locEl.child('.loc-type');
        titleEl = locEl.child('.loc-title');
        if (cfg.typeLink) {
            typeEl.update(
                '<a class="loc-type" href="' + cfg.typeLink + '"></a>'
            );
            typeEl.removeClass('loc-type');
            typeEl = typeEl.first();
        }
        if (cfg.iconCls) {
            typeEl.addClass(cfg.iconCls);
            typeEl.addClass('loc-icon');
        }
        if (cfg.type) {
            typeEl.update(cfg.type);
        }
        if (cfg.title) {
            titleEl.update(cfg.title);
            titleEl.show();
        }
        if (cfg.ddUUID) {
            locEl.addClass('air2-dragzone');

            // setup drag element
            uuid = cfg.ddUUID;
            type = (cfg.ddType) ? cfg.ddType : 'S';
            locEl.set({air2type: type, air2uuid: uuid});

            // optional drag-related element
            if (cfg.ddRelType) {
                locEl.set({air2rel: cfg.ddRelType});
            }
        }
    },
    hideLocation: function () {
        this.locationEl.hide();
    }
});
Ext.reg('air2app', AIR2.UI.App);
