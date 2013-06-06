/***************
 * Query Author Authorizations Panel
 */
AIR2.Inquiry.Authorizations.Authors = function () {

    var editTemplate,
        panel;

    editTemplate = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw right"><span>Added</span></th>' +
                '<th><span>Email</span></th>' +
                '<th><span>First Name</span></th>' +
                '<th><span>Last Name</span></th>' +
                '<th class="row-ops">' +
                    '<tpl if="' + AIR2.Inquiry.authzOpts.isWriter + '">' +
                        '<button class="air2-rowadd"></button>' +
                    '</tpl>' +
                '</th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="author-row">' +
                    '<td class="date right">' +
                        '{[AIR2.Format.date(' +
                            'values.iu_cre_dtim' +
                        ')]}' +
                    '</td>' +
                    '<td>{values.User.user_username}</td>' +
                    '<td>' +
                        '{values.User.user_first_name}' +
                    '</td>' +
                    '<td>' +
                        '{values.User.user_last_name}' +
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
            disableFormats: true
        }
    );
    //Logger(AIR2.Inquiry.authzOpts);
    //Logger(AIR2.Inquiry.BASE.authz);

    panel = new AIR2.UI.PagingEditor({
        title: 'Authors',
        url: AIR2.Inquiry.URL + '/author',
        multiSort: 'u.user_last_name asc',
        newRowDef: {
            User: {user_uuid: ''},
            inq_uuid: AIR2.Inquiry.UUID,
            iu_cre_dtim: ''
        },
        allowEdit: function(rec) {
            //Logger(rec);
            return AIR2.Inquiry.authzOpts.isWriter;
        },
        allowDelete: function (rec) {
            //Logger(rec);
            if (!AIR2.Inquiry.authzOpts.isWriter) {
                return false;
            }
            if (rec.store.getCount() < 2) {
                return false;
            }
            return true;
        },
        itemSelector: '.author-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: editTemplate,
        editRow: function (dv, node, rec) {
            var edits,
                div,
                user,
                userEl;

            edits = [];

            // initial load
            if (rec.phantom) {
                userEl = Ext.fly(node).first('td').next();
                userEl.update('').setStyle('padding', '2px');
                user = new AIR2.UI.SearchBox({
                    searchUrl: AIR2.HOMEURL + '/user',
                    pageSize: 10,
                    baseParams: {
                        sort: 'user_last_name'
                    },
                    valueField: 'user_uuid',
                    displayField: 'user_username',
                    cls: 'air2-magnifier',
                    emptyText: 'Search Users',
                    listEmptyText:
                        '<div style="padding:4px 8px">' +
                            'No Users Found' +
                        '</div>',
                    formatComboListItem: function (v) {
                        return AIR2.Format.userName(v);
                    },
                    renderTo: userEl,
                    width: 160,
                    listeners: {
                        select: function (cb, rec) {
                            // TODO ?
                        }
                    }
                });
                edits.push(user);
            }

            return edits;
        },
        saveRow: function (rec, edits) {
            //Logger(rec, edits);
            var user_uuid;

            user_uuid = edits[0].getValue();
            //Logger('user_uuid:', user_uuid);
            rec.set('User', {user_uuid: user_uuid});
        }
    });

    return panel;
}
