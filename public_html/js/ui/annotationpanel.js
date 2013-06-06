Ext.ns('AIR2.UI');
/***************
 * AIR2 AnnotationPanel Component
 *
 * AIR2 Panel for adding/editing/viewing annotations on a resource.
 *
 * @class AIR2.UI.AnnotationPanel
 * @extends AIR2.UI.Panel
 * @xtype air2annotationpanel
 * @cfg {String} valueField
 *   Data field containing the annotation value to display.
 * @cfg {String} creField
 *   Data field containing the annotation creation dtim
 * @cfg {String} updField
 *   Data field containing the annotation update dtim
 * @cfg {String} winTitle
 *   Optional title to give the modal annotation window
 * @cfg {Object/Array} storeData
 *   Initial annotation data to load
 * @cfg {String} url
 *   Restful url to access annotations
 * @cfg {Boolean} allowEdit
 *   False to disable adding/editing/deleting annotations. (default true)
 *
 */
AIR2.UI.AnnotationPanel = function (cfg) {
    var editTemplate,
        thisUser,
        userMayWrite,
        valueField;

    // add class
    if (!cfg.cls) {
        cfg.cls = '';
    }

    cfg.cls = 'air2-annotationpanel ' + cfg.cls;

    // references to field names
    valueField = cfg.valueField;

    // create the panel template, if not supplied
    if (!cfg.tpl) {
        cfg.itemSelector = "annot-row";
        cfg.tpl = new Ext.XTemplate(
            '<table class="air2-tbl">' +
                // header
                '<tr>' +
                    '<th class="fixw right"><span>Created</span></th>' +
                    '<th><span>User</span></th>' +
                    '<th><span>Text</span></th>' +
                '</tr>' +
                // rows
                '<tpl for=".">' +
                    '<tr class="annot-row">' +
                        '<td class="date right">' +
                            '{[AIR2.Format.date(values.' +
                                cfg.updField +
                            ')]}' +
                        '</td>' +
                        '<td>' +
                            '{[AIR2.Format.userName(values.CreUser,1,1)]}' +
                        '</td>' +
                        '<td>{' + cfg.valueField + ':ellipsis(75)}</td>' +
                    '</tr>' +
                '</tpl>' +
            '</table>',
            {
                compiled: true,
                disableFormats: false
            }
        );
    }

    // Default URI, when none provided.
    if (!cfg.hasOwnProperty('url') || !cfg.url) {
        cfg.url = AIR2.Util.URI.INVALID_URI;
    }

    // object for current user
    thisUser = {
        user_username: AIR2.USERINFO.username,
        user_first_name: AIR2.USERINFO.first_name,
        user_last_name: AIR2.USERINFO.last_name,
        user_uuid: AIR2.USERINFO.uuid,
        user_status: AIR2.USERINFO.status,
        user_type: AIR2.USERINFO.type
    };

    // create the modal window config
    userMayWrite = (cfg.allowEdit === false) ? false : true;
    editTemplate = new Ext.XTemplate(
        '<table class="air2-annotation air2-tbl">' +
            '<tpl for=".">' +
                '<tr class="annot-row">' +
                    // photo and info
                    '<td>' +
                        '<table class="who air2-corners">' +
                            '<tr>' +
                                '<td class="photo">' +
                                    '{[AIR2.Format.userPhoto(' +
                                        'values.CreUser,' +
                                        '50' +
                                    ')]}' +
                                '</td>' +
                                '<td class="info">' +
                                    '<b>' +
                                        '{[AIR2.Format.userName(' +
                                            'values.CreUser,' +
                                            '1,' +
                                            '1' +
                                        ')]}' +
                                    '</b>' +
                                    '{[this.moreInfo(values.CreUser)]}' +
                                '</td>' +
                            '</tr>' +
                        '</table>' +
                    '</td>' +
                    // text value
                    '<td class="text">' +
                        '<p>{' + cfg.valueField + '}</p>' +
                        '<div class="meta">' +
                                '{[this.postdate(values)]}' +
                        '</div>' +
                    '</td>' +
                    // edit buttons
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
            moreInfo: function (usr) {
                var org,
                    str,
                    title;

                str = '';
                if (usr.user_type === 'S') {
                    str += '<p>System User</p>';
                }
                else {
                    if (usr.UserOrg && usr.UserOrg.length) {
                        title = usr.UserOrg[0].uo_user_title;
                        if (title) {
                            str += '<p>' + title + '</p>';
                        }

                        org = AIR2.Format.userOrgShort(usr.UserOrg[0], 1);
                        str += '<div class="room">' + org + '</div>';
                    }
                }
                return str;
            },
            postdate: function (v) {
                if (v[cfg.updField] > v[cfg.creField]) {
                    return 'Updated ' + AIR2.Format.dateLong(v[cfg.updField]);
                }
                else {
                    return 'Posted ' + AIR2.Format.dateLong(v[cfg.creField]);
                }
            }
        }
    );

    cfg.editModal = {
        title: (cfg.winTitle) ? cfg.winTitle : 'Annotations',
        allowAdd: userMayWrite,
        items: {
            xtype: 'air2pagingeditor',
            url: cfg.url,
            multiSort: cfg.creField + ' desc',
            newRowDef: {CreUser: thisUser},
            allowEdit: function (rec) {
                if (!userMayWrite) {
                    return false;
                }
                if (rec.phantom) {
                    return true;
                }
                var cre = rec.data.CreUser.user_uuid;
                return (AIR2.USERINFO.uuid === cre);
            },
            allowDelete: function (rec) {
                if (!userMayWrite) {
                    return false;
                }
                if (rec.phantom) {
                    return true;
                }
                var cre = rec.data.CreUser.user_uuid;
                return (AIR2.USERINFO.uuid === cre);
            },
            plugins: [AIR2.UI.PagingEditor.InlineControls],
            itemSelector: '.annot-row',
            tpl: editTemplate,
            editRow: function (dv, node, rec) {
                var text,
                    textEl;

                textEl = Ext.fly(node).first('td.text');
                textEl.update('').setStyle('padding', '6px 4px');
                text = new Ext.form.TextArea({
                    grow: false,
                    renderTo: textEl,
                    value: rec.data[valueField],
                    width: 400
                });
                return [text];
            },
            saveRow: function (rec, edits) {
                rec.set(valueField, edits[0].getValue());
            }
        }
    };

    Ext.applyIf(cfg, this);
    AIR2.UI.AnnotationPanel.superclass.constructor.call(this, cfg);
};
Ext.extend(AIR2.UI.AnnotationPanel, AIR2.UI.Panel, {
    colspan: 1,
    title: 'Annotations',
    iconCls: 'air2-icon-annotation',
    showTotal: true
});
