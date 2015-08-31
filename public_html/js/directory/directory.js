/***************
 * Directory page - User-Directory Panel
 */
AIR2.Directory.Directory = function () {
    var actCreateOrg,
        actCreateUsr,
        clsValue,
        CURRENTVIEW,
        dv,
        dvTemplate,
        dv2,
        dv2Template,
        emptyTextValue,
        getParams,
        newOrgBtn,
        newUsrBtn,
        pnl,
        queryParam,
        setTheTotal,
        statusFilter,
        textFilter,
        treeTpl,
        typeFilter;

    // default current view
    CURRENTVIEW = 'user';

    // check the URL for "#organizations" or "#users"
    getParams = document.URL.split('#');
    if (getParams.length > 1) {
        if (getParams[1].match(/organization/)) {
            CURRENTVIEW = 'org';
        }
    }

    dvTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            '<tr class="header">' +
                '<th class="sortable" air2fld="user_last_name">' +
                    '<span>Name</span>' +
                '</th>' +
                '<th class="sortable" air2fld="org_display_name">' +
                    '<span>Organization</span>' +
                '</th>' +
                '<th class="sortable" air2fld="uo_user_title">' +
                    '<span>Title</span>' +
                '</th>' +
                '<th>' +
                    '<span>Phone</span>' +
                '</th>' +
                '<th class="sortable" air2fld="uem_address">' +
                    '<span>Email</span>' +
                '</th>' +
            '</tr>' +
            '<tpl for=".">' +
                '<tr class="direct-row">' +
                    '<td>{[AIR2.Format.userName(values, true)]}</td>' +
                    '<td>{[this.formatOrg(values)]}</td>' +
                    '<td>{[this.formatTitle(values)]}</td>' +
                    '<td>{[this.formatPhone(values)]}</td>' +
                    '<td>{[this.formatEmail(values)]}</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatOrg: function (values) {
                if (values.org_uuid) {
                    return AIR2.Format.orgNameLong(values);
                }
                return '<span class="lighter">(none)</span>';
            },
            formatTitle: function (values) {
                if (values.uo_user_title) {
                    return AIR2.Format.userOrgTitle(values);
                }
                return '<span class="lighter">(none)</span>';
            },
            formatPhone: function (values) {
                if (values.uph_number) {
                    return AIR2.Format.userPhone(values);
                }
                return '<span class="lighter">(none)</span>';
            },
            formatEmail: function (values) {
                if (values.uem_address) {
                    return AIR2.Format.userEmail(
                        values,
                        this.isActive(values)
                    );
                }
                return '<span class="lighter">(none)</span>';
            },
            isActive: function (values) {
                return (
                    values.user_status === 'A' ||
                    values.user_status === 'P'
                );
            }
        }
        );

    // primary dataview display
    dv = new AIR2.UI.PagingEditor({
        pageSize: 15,
        cls: 'user-dv',
        url: AIR2.HOMEURL + '/user',
        data: AIR2.Directory.USERDIR,
        baseParams: AIR2.Directory.UPARAMS,
        plugins: [AIR2.UI.PagingEditor.HeaderSort],
        itemSelector: '.direct-row',
        tpl: dvTemplate
    });

    // setup combo-box filtering tools
    statusFilter = new AIR2.UI.ComboBox({
        value: AIR2.Directory.UPARAMS.status,
        choices: [
            ['AP', 'Active'],
            ['F', 'Inactive'],
            ['', 'All']
        ],
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('status', rec.data.value);
                dv.pager.changePage(0);
            }
        }
    });
    typeFilter = new AIR2.UI.ComboBox({
        value: AIR2.Directory.UPARAMS.type,
        choices: [
            ['A', 'Air Users'],
            ['S', 'System'],
            ['', 'All']
        ],
        width: 80,
        listeners: {
            select: function (fld, rec, idx) {
                dv.store.setBaseParam('type', rec.data.value);
                dv.pager.changePage(0);
            }
        }
    });

    // org tree dataview
    treeTpl = new Ext.XTemplate(
        '<tr class="direct-row {[this.rowCls(values)]}">' +
            '<td class="name">' +
                '<span style="{[this.indentStyle(values)]}">' +
                    '{[AIR2.Format.orgNameLong(values, true, 48)]}' +
                    '&nbsp;' +
                    '{[AIR2.Format.orgName(values, true)]}' +
                '</span>' +
        '</td>' +
        '<td class="date">{[AIR2.Format.date(values.org_cre_dtim)]}</td>' +
            '<tpl if="AIR2.Directory.PINMNG">' +
                '<td>{active_users}</td>' +
                '<td>{[this.orgSeats(values)]}</td>' +
            '</tpl>' +
        '<td>' +
            '{[AIR2.Format.codeMaster("org_status", values.org_status)]}' +
        '</td>' +
        '</tr>' +
        '<tpl for="children">' +
            '{[this.formatChildren(values, parent)]}' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            rowCls: function (values) {
                var cls = '';
                if (values.level === 0) {
                    cls += ' root';
                }
                if (values.children.length > 0) {
                    cls += ' expanded';
                }
                if (values.org_status !== 'A' && values.org_status !== 'P') {
                    cls += ' inactive';
                }
                return cls;
            },
            indentStyle: function (values) {
                var amt, style;

                style = '';
                if (values.level > 0) {
                    amt = values.level * 10;
                    style += 'margin-left:' + amt + 'px;';
                }
                return style;
            },
            formatChildren: function (values, parent) {
                values.level = parent.level + 1;
                return treeTpl.apply(values);
            },
            orgSeats: function (values) {
                if (values.org_max_users < 0) {
                    return '999';
                }
                else {
                    return Math.max(
                        0,
                        (values.org_max_users - values.active_users)
                    );
                }
            }
        }
    );

    dv2Template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
          '<tr class="header">' +
            '<th class="sortable" air2fld="org_display_name">' +
              '<span>Name</span>' +
            '</th>' +
            '<th class="sortable" air2fld="org_cre_dtim">' +
              '<span>Created</span>' +
            '</th>' +
            '<tpl if="AIR2.Directory.PINMNG">' +
              '<th><span># of Users</span></th>' +
              '<th><span>Seats Left</span></th>' +
            '</tpl>' +
            '<th><span>Status</span></th>' +
          '</tr>' +
          '<tpl for=".">' +
            '{[this.formatData(values)]}' +
          '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            formatData: function (values) {
                values.level = 0;
                return treeTpl.apply(values);
            }
        }
    );

    dv2 = new AIR2.UI.PagingEditor({
        hidePager: true,
        pageSize: 99,
        cls: 'org-dv',
        url: AIR2.HOMEURL + '/orgtree',
        data: AIR2.Directory.ORGDIR,
        //baseParams: AIR2.Directory.PARMS,
        plugins: [AIR2.UI.PagingEditor.HeaderSort],
        itemSelector: '.direct-row',
        tpl: dv2Template
    });



    // "NEW" buttons
    actCreateUsr = AIR2.Util.Authz.has('ACTION_ORG_USR_CREATE');
    actCreateOrg = AIR2.Util.Authz.has('ACTION_ORG_CREATE');
    newUsrBtn = new AIR2.UI.Button({
        text: 'Add User',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        iconCls: 'air2-icon-add-user',
        handler: function () {
            AIR2.User.Create({
                originEl: newUsrBtn.el,
                callback: function (success, data) {
                    if (success && data && data.radix) {
                        textFilter.setValue(data.radix.user_username);
                    }
                }
            });
        },
        hidden: !actCreateUsr
    });

    newOrgBtn = new AIR2.UI.Button({
        text: 'Add Organization',
        air2type: 'UPLOAD',
        air2size: 'MEDIUM',
        iconCls: 'air2-icon-add-org',
        handler: function () {
            AIR2.Organization.Create({
                originEl: newOrgBtn.el
            });
        },
        hidden: !actCreateOrg,
        disabled: (AIR2.USERINFO.type !== "S")
    });

    emptyTextValue = 'Filter ';
    if (CURRENTVIEW === 'user') {
        emptyTextValue += 'Users';
    }
    else {
        emptyTextValue += 'Organizations';
    }

    if (CURRENTVIEW === 'org') {
        queryParam = 'q';
    }
    else {
        queryParam = 'filter';
    }

    // text filter box
    textFilter = new Ext.form.TextField({
        width: 230,
        emptyText: emptyTextValue,
        validationDelay: 500,
        queryParam: queryParam,
        reset: function () {
            var targetDv;

            if (CURRENTVIEW === 'user') {
                this.queryParam = 'filter';
                this.emptyText = 'Filter Users';
            }
            else {
                this.queryParam = 'q';
                this.emptyText = 'Filter Organizations';
            }

            Ext.form.TextField.superclass.reset.call(this);
            this.applyEmptyText();

            // check for an existing filter
            if (CURRENTVIEW === 'user') {
                targetDv = dv;
            }
            else {
                targetDv = dv2;
            }

            if (targetDv.store.baseParams[this.queryParam]) {
                this.setValue(targetDv.store.baseParams[this.queryParam]);
            }
        },
        validateValue: function (v) {
            var targetDv;

            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-1, 2]);
                this.remoteAction.show();

                // reload the store
                if (CURRENTVIEW === 'user') {
                    targetDv = dv;
                }
                else {
                    targetDv = dv2;
                }

                targetDv.store.setBaseParam(this.queryParam, v);
                targetDv.store.on(
                    'load',
                    function () {
                        this.remoteAction.hide();
                    },
                    this,
                    {single: true}
                );
                targetDv.pager.changePage(0);
                this.lastValue = v;
            }
        },
        lastValue: '',
        listeners: {
            render: function (p) {
                p.remoteAction = p.el.insertSibling({
                    cls: 'air2-form-remote-wait'
                });
            }
        }
    });

    clsValue = 'air2-directory-direct ';

    if (CURRENTVIEW === 'org') {
        clsValue += 'show-org';
    }

    // create panel for dataviews
    pnl = new AIR2.UI.Panel({
        colspan: 2,
        rowspan: 2,
        title: 'Directory',
        cls:  clsValue,
        iconCls: 'air2-icon-directory',
        showTotal: false,
        tools: ['->', '<b>Show:</b>', statusFilter, '  ', typeFilter],
        items: [{
            xtype: 'container',
            layout: 'hbox',
            defaults: {margins: '10 10 10 0'},
            items: [textFilter, newOrgBtn, newUsrBtn]
        }, dv, dv2]
    });

    // click listener for changing views
    pnl.header.on('afterrender', function (hdr) {
        hdr.el.on('click', function (event) {
            if (event.getTarget('a.usr.other')) {
                pnl.removeClass('show-org');
                CURRENTVIEW = 'user';
                setTheTotal();
                textFilter.reset();
            }
            else if (event.getTarget('a.org.other')) {
                pnl.addClass('show-org');
                CURRENTVIEW = 'org';
                setTheTotal();
                textFilter.reset();
            }
        });
    });

    // custom store total
    setTheTotal = function () {
        var orgCount, usrCount, str;
        usrCount = dv.store.getTotalCount();
        orgCount = dv2.store.getTotalCount();
        str = '';
        if (CURRENTVIEW === 'org') {
            str += '<a class="usr other">' + usrCount + ' Users</a> | ';
            str += '<a class="org current">' + orgCount + ' Organizations</a>';
        }
        else {
            str += '<a class="usr current">' + usrCount + ' Users</a> | ';
            str += '<a class="org other">' + orgCount + ' Organizations</a>';
        }
        pnl.setCustomTotal(str);
    };
    setTheTotal();
    dv.store.on('load', setTheTotal);
    dv2.store.on('load', setTheTotal);

    // return paging panel
    return pnl;
};
