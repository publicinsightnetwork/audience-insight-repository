/***************
 * Organization Projects Panel
 */
AIR2.Organization.Projects = function () {
    var creAction,
        editTemplate,
        p,
        template,
        tip,
        tipLight,
        updAction;

    // actions in this org
    creAction = AIR2.Util.Authz.has(
        'ACTION_ORG_PRJ_CREATE',
        AIR2.Organization.UUID
    );

    updAction = AIR2.Util.Authz.has(
        'ACTION_ORG_PRJ_UPDATE',
        AIR2.Organization.UUID
    );

    // support article
    tip = AIR2.Util.Tipper.create(20164797);
    tipLight = AIR2.Util.Tipper.create({
        id: 20164797,
        cls: 'lighter',
        align: 15
    });

    // panel

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th><span>Name</span></th>' +
            '<th><span>Queries</span></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="org-row">' +
              '<td>{[AIR2.Format.projectName(values.Project,1)]}</td>' +
              '<td>{inq_count}</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            userEmail: function (user) {
                if (user.UserEmailAddress && user.UserEmailAddress.length > 0) {
                    var e = user.UserEmailAddress[0].uem_address;
                    return '<a class="email" href="mailto:' + e + '"></a>';
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          // header
          '<tr>' +
            '<th class="fixw right"><span>Added</span></th>' +
            '<th><span>Name</span></th>' +
            '<th><span>Contact</span></th>' +
            '<th><span>Phone</span></th>' +
            '<th class="fixw center"><span>Email</span></th>' +
            '<th><span>Queries</span></th>' +
            '<th class="row-ops"></th>' +
          '</tr>' +
          // rows
          '<tpl for=".">' +
            '<tr class="project-row">' +
              '<td class="date right">' +
                '{[AIR2.Format.date(values.porg_cre_dtim)]}' +
              '</td>' +
              '<td>{[AIR2.Format.projectName(values.Project,1)]}</td>' +
              '<td>{[AIR2.Format.userName(values.ContactUser,1,1)]}</td>' +
              '<td>{[AIR2.Format.userPhone(values.ContactUser)]}</td>' +
              '<td class="center">{[this.userEmail(values.ContactUser)]}</td>' +
              '<td>{inq_count}</td>' +
              '<td class="row-ops"><button class="air2-rowedit">' +
                '</button><button class="air2-rowdelete"></button>' +
              '</td>' +
            '</tr>' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            userEmail: function (user) {
                if (user.UserEmailAddress && user.UserEmailAddress.length > 0) {
                    var e = user.UserEmailAddress[0].uem_address;
                    return '<a class="email" href="mailto:' + e + '"></a>';
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    p = new AIR2.UI.Panel({
        url: AIR2.Organization.URL + '/project',
        colspan: 1,
        title: 'Projects ' + tip,
        showTotal: true,
        showHidden: false,
        cls: 'air2-project-organization',
        iconCls: 'air2-icon-project',
        storeData: AIR2.Organization.PRJDATA,
        itemSelector: '.project-row',
        tpl: template,
        modalAdd: 'Add Project',
        editModal: {
            title: 'Organization Projects ' + tipLight,
            allowAdd: updAction ? 'Add Project' : false,
            allowNew: creAction ? 'New Project' : false,
            createNewFn: AIR2.Project.Create,
            createNewCfg: {
                org_uuid: AIR2.Organization.UUID
            },
            width: 700,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Organization.URL + '/project',
                multiSort: 'prj_display_name asc',
                newRowDef: {Project: {prj_cre_dtim: ''}, ContactUser: {}},
                itemSelector: '.project-row',
                allowEdit: true,
                allowDelete: function (rec) {
                    if (!AIR2.Organization.BASE.authz.may_manage) {
                        return false;
                    }
                    if (rec.store.getCount() < 2) {
                        return false;
                    }
                    return true;
                },
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits,
                        prjEl,
                        proj,
                        raw,
                        user,
                        usrEl;

                    edits = [];
                    if (rec.phantom) {
                        prjEl = Ext.fly(node).first('td').next();
                        prjEl.update('').setStyle('padding', '4px');
                        proj = new AIR2.UI.SearchBox({
                            cls: 'air2-magnifier',
                            searchUrl: AIR2.HOMEURL + '/project',
                            pageSize: 10,
                            baseParams: {
                                manage: 1,
                                excl_org: AIR2.Organization.UUID
                            },
                            valueField: 'prj_uuid',
                            displayField: 'prj_display_name',
                            listEmptyText:
                                '<div style="padding:4px 8px">' +
                                    'No Projects Found' +
                                '</div>',
                            emptyText: 'Search Manageable Projects',
                            formatComboListItem: function (v) {
                                return AIR2.Format.projectName(v);
                            },

                            renderTo: prjEl,
                            width: 200
                        });
                        edits.push(proj);
                    }
                    usrEl = Ext.fly(node).first('td').next().next();
                    usrEl.update('').setStyle('padding', '4px');
                    user = new AIR2.UI.SearchBox({
                        searchUrl: AIR2.HOMEURL + '/user',
                        pageSize: 10,
                        baseParams: {
                            sort: 'user_last_name asc',
                            incl_contact_org: AIR2.Organization.UUID
                        },
                        valueField: 'user_uuid',
                        displayField: 'user_username',
                        cls: 'air2-magnifier',
                        emptyText: 'Search Org Users',
                        listEmptyText:
                            '<div style="padding:4px 8px">' +
                                'No Users Found' +
                            '</div>',
                        formatComboListItem: function (v) {
                            return AIR2.Format.userName(v);
                        },
                        setProject: function () {
                            this.reset();
                            delete this.lastQuery;
                        },
                        renderTo: usrEl,
                        width: 150
                    });

                    // initial load
                    if (!rec.phantom) {
                        user.setProject();
                        raw = AIR2.Format.userName(rec.data.ContactUser);
                        user.setValue(rec.data.user_uuid);
                        user.selectRawValue(raw);
                    }
                    edits.push(user);
                    return edits;
                },
                saveRow: function (rec, edits) {
                    if (rec.phantom) {
                        rec.set('prj_uuid', edits[0].getValue());
                        rec.set('user_uuid', edits[1].getValue());
                    }
                    else {
                        rec.set('user_uuid', edits[0].getValue());
                    }
                    rec.set('org_uuid', AIR2.Organization.UUID);
                }
            }
        }
    });
    return p;
};
