Ext.ns('AIR2.Project');
/***************
 * Project Organizations Panel
 */
AIR2.Project.Organizations = function () {
    var editTemplate,
        template;

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th><span>Name</span></th>' +
                '<th><span>Contact</span></th>' +
                '<th><span>Phone</span></th>' +
                '<th class="fixw center"><span>Email</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td>' +
                        '{[AIR2.Format.orgName(values.Organization,1)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.userName(values.ContactUser,1,1)]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.userPhone(values.ContactUser)]}' +
                    '</td>' +
                    '<td class="center">' +
                        '{[this.userEmail(values.ContactUser)]}' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            userEmail: function (user) {
                var e;
                if (
                    user.UserEmailAddress &&
                    user.UserEmailAddress.length > 0
                ) {
                    e = user.UserEmailAddress[0].uem_address;
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
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="org-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(' +
                            'values.porg_cre_dtim' +
                        ')]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.orgNameLong(' +
                            'values.Organization,' +
                            '1' +
                        ')]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.userName(' +
                            'values.ContactUser,' +
                            '1,' +
                            '1' +
                        ')]}' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.userPhone(' +
                            'values.ContactUser' +
                        ')]}' +
                    '</td>' +
                    '<td class="center">' +
                        '{[this.userEmail(values.ContactUser)]}' +
                    '</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit"></button>' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            userEmail: function (user) {
                var e;
                if (
                    user.UserEmailAddress &&
                    user.UserEmailAddress.length > 0
                ) {
                    e = user.UserEmailAddress[0].uem_address;
                    return '<a class="email" href="mailto:' + e +
                        '"></a>';
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    return new AIR2.UI.Panel({
        storeData: AIR2.Project.ORGDATA,
        url: AIR2.Project.URL + '/organization',
        colspan: 1,
        title: 'Organizations',
        showTotal: true,
        cls: 'air2-project-organization',
        iconCls: 'air2-icon-organization',
        itemSelector: '.org-row',
        tpl: template,
        modalAdd: 'Add Organization',
        editModal: {
            title: 'Project Organizations',
            allowAdd: function () {
                if (AIR2.Project.BASE.authz.may_manage) {
                    return 'Add Organization';
                }
                else {
                    return false;
                }
            },
            width: 650,
            height: 500,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.Project.URL + '/organization',
                multiSort: 'org_display_name asc',
                newRowDef: {ContactUser: ''},
                allowEdit: AIR2.Project.BASE.authz.may_manage,
                allowDelete: function (rec) {
                    if (!AIR2.Project.BASE.authz.may_manage) {
                        return false;
                    }
                    if (rec.store.getCount() < 2) {
                        return false;
                    }
                    return true;
                },
                itemSelector: '.org-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate,
                editRow: function (dv, node, rec) {
                    var edits, org, orgEl, raw, user, usrEl;

                    edits = [];
                    usrEl = Ext.fly(node).first('td').next().next();
                    usrEl.update('').setStyle('padding', '4px');
                    user = new AIR2.UI.SearchBox({
                        searchUrl: AIR2.HOMEURL + '/user',
                        pageSize: 10,
                        baseParams: {
                            sort: 'user_last_name asc'
                        },
                        valueField: 'user_uuid',
                        displayField: 'user_username',
                        cls: 'air2-magnifier',
                        disabled: true,
                        emptyText: 'Search Org Users',
                        listEmptyText:
                            '<div style="padding:4px 8px">' +
                                'No Users Found' +
                            '</div>',
                        formatComboListItem: function (v) {
                            return AIR2.Format.userName(v);
                        },
                        setOrg: function (orguuid) {
                            this.reset();
                            delete this.lastQuery;
                            if (orguuid) {
                                this.store.setBaseParam(
                                    'incl_contact_org',
                                    orguuid
                                );
                                this.doQuery(this.allQuery, true);
                                this.store.on(
                                    'load',
                                    function () {
                                        this.enable();
                                        this.onTriggerClick();
                                    },
                                    this,
                                    {single: true}
                                );
                            }
                            else {
                                this.disable();
                            }
                        },
                        renderTo: usrEl,
                        width: 150
                    });

                    // initial load
                    if (!rec.phantom) {
                        user.setOrg(rec.data.org_uuid);
                        raw = AIR2.Format.userName(rec.data.ContactUser);
                        user.setValue(rec.data.user_uuid);
                        user.selectRawValue(raw);
                    }
                    edits.push(user);

                    if (rec.phantom) {
                        orgEl = Ext.fly(node).first('td').next();
                        orgEl.update('').setStyle('padding', '2px');
                        org = new AIR2.UI.SearchBox({
                            searchUrl: AIR2.HOMEURL + '/organization',
                            pageSize: 10,
                            baseParams: {
                                sort: 'org_display_name',
                                excl_proj: AIR2.Project.UUID
                            },
                            valueField: 'org_uuid',
                            displayField: 'org_display_name',
                            cls: 'air2-magnifier',
                            emptyText: 'Search Organizations',
                            listEmptyText:
                                '<div style="padding:4px 8px">' +
                                    'No Organizations Found' +
                                '</div>',
                            formatComboListItem: function (v) {
                                return v.org_display_name;
                            },
                            renderTo: orgEl,
                            width: 185,
                            listeners: {
                                select: function (cb, rec) {
                                    user.setOrg(rec.data.org_uuid);
                                }
                            }
                        });
                        edits.push(org);
                    }

                    return edits;
                },
                saveRow: function (rec, edits) {
                    rec.set('user_uuid', edits[0].getValue());
                    if (rec.phantom) {
                        rec.set('org_uuid', edits[1].getValue());
                    }
                }
            }
        }
    });
};
