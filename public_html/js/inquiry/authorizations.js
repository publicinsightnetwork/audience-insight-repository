/***************
 * Query Authorizations Panel
 */
AIR2.Inquiry.Authorizations = function () {
    var dv,
        panel,
        spinner,
        template,
        tips;

    // support article
    tips = {};
    Ext.iterate(['projects','orgs','authors','watchers'], function(k) {
        tips[k] = {};
        tips[k].tip = AIR2.Util.Tipper.create(k);
        tips[k].tipLight = AIR2.Util.Tipper.create({
            id: k,
            cls: 'lighter',
            align: 15
        }); 
    });

    template = new Ext.XTemplate(
        '<tpl for=".">' +
            '<table class="air2-tbl">' +
                '<tr>' +
                    '<td class="label right">Projects  ' + tips['projects'].tip + '</td>' +
                    '<td class="left">{.:this.formatProjects}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label right">Organizations  ' + tips['orgs'].tip + '</td>' +
                    '<td class="left">{.:this.formatOrganizations}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label right">Authors  ' + tips['authors'].tip + '</td>' +
                    '<td class="left">{.:this.formatAuthors}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label right">Watchers  ' + tips['watchers'].tip + '</td>' +
                    '<td class="left">{.:this.formatWatchers}</td>' +
                '</tr>' +
                '<tr>' +
                    '<td class="label right">Opt-in to Global PIN:</td>' +
                    '<td class="left">{.:this.getGlobalStatus}</td>' +
                '</tr>' +
            '</table>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: false,
            getGlobalStatus: function (values) {
                var s, orgCount, hasGlobal;
                s = AIR2.Inquiry.orgStore;
                hasGlobal = false;
                s.each(function( iorg ) {
                    if (iorg.data.Organization.org_uuid == AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID) {
                        hasGlobal = true;
                    }
                });
                orgCount = s.getCount();

                if (hasGlobal && orgCount > 1) {
                    return '<span class="air2-icon air2-pointer air2-icon-check" onclick="AIR2.Inquiry.Authorizations.toggleGlobal(this)">Yes</span>';
                }
                else if (hasGlobal) {
                    return '<span class="air2-icon air2-icon-check">Yes</span>';
                }
                else {
                    return '<span class="air2-icon air2-pointer air2-icon-prohibited" onclick="AIR2.Inquiry.Authorizations.toggleGlobal(this)">No</span>';
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
                    if (iorg.data.Organization.org_uuid == AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID) {
                        return;
                    }
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

    spinner = new AIR2.UI.Spinner();

    // panel
    panel = new AIR2.UI.Panel({
        allowEdit: AIR2.Inquiry.authzOpts.isWriter,
        colspan: 3,
        editModal: {
            title: 'Authorizations',
            width: 650,
            allowAdd: false,
            tabLayout: true,
            showTotal: false,
            items: {
                xtype: 'tabpanel',
                plain: true,
                activeTab: 0,
                items: [
                    AIR2.Inquiry.Authorizations.Organizations(),
                    AIR2.Inquiry.Authorizations.Projects(),
                    AIR2.Inquiry.Authorizations.Authors(),
                    AIR2.Inquiry.Authorizations.Watchers()
                ],
                listeners: {
                    tabchange: function (tabpnl, tab) {
                        if (!tab) {
                            //Logger('tabchange, tab undefined');
                            return;
                        }
                        var pgr = tabpnl.getBottomToolbar();
                        // unbind listeners, but DON'T destroy old store
                        if (pgr.store) {
                            pgr.store.un(
                                'beforeload',
                                pgr.beforeLoad,
                                this
                            );
                            pgr.store.un(
                                'load',
                                pgr.onLoad,
                                this
                            );
                            pgr.store.un(
                                'exception',
                                pgr.onLoadError,
                                this
                            );
                        }
                        pgr.bindStore(tab.store, true);
                        pgr.show();
                    }
                }
            },
            listeners: {
                beforehide: function (win) {
                    win.get(0).fireEvent('beforehide');
                    AIR2.Inquiry.inqStore.reload();
                    AIR2.Inquiry.orgStore.reload();
                    AIR2.Inquiry.prjStore.reload();
                    AIR2.Inquiry.authorStore.reload();
                    AIR2.Inquiry.watcherStore.reload();
                    AIR2.Inquiry.ActivityPanel.store.reload();
                }
            }
        },
        emptyText: '<div class="air2-panel-empty"><h3>Loading...</h3></div>',
        iconCls: 'air2-icon-project',
        itemSelector: '.air2-tbl',
        showTotal: false,
        showHidden: false,
        title: 'Authorizations',
        tools: [spinner],
        tpl: template,
        url: AIR2.Inquiry.URL
    });

    return panel;
};

AIR2.Inquiry.Authorizations.toggleGlobal = function(checkbox) {
    var globalRec,
        panel,
        params,
        httpMethod,
        url;

    globalRec = false;

    // get an Ext.Element
    checkbox = Ext.get(checkbox);
    panel = checkbox.parent('.air2-panel');
    // get the actual component
    panel = Ext.getCmp(panel.id);

    panel.el.mask('Updating...');

    AIR2.Inquiry.orgStore.each(function( iorg ) {
        if (iorg.data.Organization.org_uuid == AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID) {
            globalRec = iorg;
        }
    });

    if (globalRec) {
        httpMethod  = 'DELETE';
    }
    else {
        httpMethod  = 'POST';
    }

    // fire xhr call
    url = AIR2.Inquiry.URL + '/organization';
    if (httpMethod == 'DELETE') {
        url += '/' + AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID;
    }

    // setup panel unmask postrefresh
    panel.getDataView().on(
        'afterrefresh',
        function(dataview) { panel.el.unmask(); },
        null,
        { single: true }
    );

    // setup panel refresh
    AIR2.Inquiry.orgStore.on(
        'load',
        function (store, records, options) { panel.reload(); },
        null,
        { single: true }
    );


    Ext.Ajax.request({
        url: url + '.json',
        method: httpMethod,
        params: {
            radix: Ext.util.JSON.encode({
                org_uuid: AIR2.CONSTANTS.GLOBAL_PIN_ORG_UUID
            })
        },

        success: function (resp, ajax, opts) {
             AIR2.Inquiry.orgStore.reload();
        },

        // rollback on failure
        failure: function (resp, ajax, opts) {
            Logger('global org failure: ', resp);
            AIR2.Inquiry.orgStore.reload();
        }
    });

}
