/***************
 * Home Alerts Panel
 */
AIR2.Home.Alerts = function () {
    var alertTemplate,
        editTemplate,
        hide;

    if (AIR2.Home.ALERTDATA.radix.length === 0) {
        hide = true;
    }
    else {
        hide = false;
    }

    alertTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Date</span></th>' +
                '<th><span>Type</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>Owner</span></th>' +
                '<th><span>Action</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="alert-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.tank_upd_dtim)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.tankType(values,1)]}</td>' +
                    '<td>{[AIR2.Format.tankName(values)]}</td>' +
                    '<td>{[this.formatOwner(values)]}</td>' +
                    '<td>' +
                        '<a href="{[this.getLink(values)]}">' +
                            '{[this.conflicts(values)]}&nbsp;&raquo;' +
                        '</a> ' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            conflicts: function (values) {
                var count, str;
                if (values.count_conflict) {
                    count = values.count_conflict;
                }
                else {
                    count = 0;
                }

                str = count + '&nbsp;Conflict';
                if (count !== 1) {
                    str += 's';
                }

                return str;
            },
            getLink: function (values) {
                return AIR2.HOMEURL + '/import/' + values.tank_uuid;
            },
            formatOwner: function (values) {
                var org;

                if (values.tank_type.match(/^[FQ]$/) &&
                    values.TankOrg &&
                    values.TankOrg.length
                ) {
                    // just format the first org, for now
                    org = values.TankOrg[0].Organization;
                    return AIR2.Format.orgName(org, 1);
                }
                else {
                    return AIR2.Format.userName(values.User, 1, 1);
                }
            }
        }
    );

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="right fixw"><span>Date</span></th>' +
                '<th><span>Type</span></th>' +
                '<th><span>Name</span></th>' +
                '<th><span>User</span></th>' +
                '<th><span>Organizations</span></th>' +
                '<th><span>Action</span></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="alert-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(values.tank_upd_dtim)]}' +
                    '</td>' +
                    '<td>{[AIR2.Format.tankType(values,1)]}</td>' +
                    '<td>{[AIR2.Format.tankName(values)]}</td>' +
                    '<td>' +
                        '{[AIR2.Format.userName(values.User,1,1)]}' +
                    '</td>' +
                    '<td>{[this.formatOrgs(values)]}</td>' +
                    '<td>' +
                        '<a href="{[this.getLink(values)]}">' +
                            '{[this.conflicts(values)]}&nbsp;&raquo;' +
                        '</a> ' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>',
        {
            compiled: true,
            disableFormats: true,
            conflicts: function (values) {
                var count, str;

                if (values.count_conflict) {
                    count = values.count_conflict;
                }
                else {
                    count = 0;
                }

                str = count + '&nbsp;Conflict';
                if (count !== 1) {
                    str += 's';
                }

                return str;
            },
            getLink: function (values) {
                return AIR2.HOMEURL + '/import/' + values.tank_uuid;
            },
            formatOrgs: function (values) {
                if (values.TankOrg && values.TankOrg.length) {
                    var i, org, remain, str;

                    str = '';
                    for (i = 0; i < values.TankOrg.length; i++) {
                        if (i < 2) {
                            org = values.TankOrg[i].Organization;
                            str += AIR2.Format.orgName(org, 1) + ' ';
                        }
                        else {
                            remain = values.TankOrg.length - i;
                            str += '+ ' + remain + ' more';
                            break;
                        }
                    }
                    return str;
                }
                return '<span class="lighter">(none)</span>';
            }
        }
    );

    return new AIR2.UI.Panel({
        colspan: 2,
        title: 'Alerts',
        cls: 'air2-home-alert',
        iconCls: 'air2-icon-alert',
        showTotal: true,
        showHidden: false,
        storeData: AIR2.Home.ALERTDATA,
        itemSelector: '.alert-row',
        collapsed: hide,
        url: AIR2.HOMEURL + '/alert',
        tpl: alertTemplate,
        editModal: {
            allowAdd: false,
            width: 750,
            items: {
                xtype: 'air2pagingeditor',
                url: AIR2.HOMEURL + '/alert',
                multiSort: 'tank_upd_dtim desc',
                itemSelector: '.alert-row',
                plugins: [AIR2.UI.PagingEditor.InlineControls],
                tpl: editTemplate
            }
        }
    });
};
