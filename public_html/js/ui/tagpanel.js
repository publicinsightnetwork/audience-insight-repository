/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

Ext.ns('AIR2.UI');
/***************
 * AIR2 TagPanel Component
 *
 * AIR2 Panel for tagging resources
 *
 * @class AIR2.UI.TagPanel
 * @extends AIR2.UI.Panel
 * @xtype air2tagpanel
 * @cfg {Object/Array} storeData
 *   Initial tag data to load store with
 * @cfg {String} url
 *   Restful url for adding/removing tags
 * @cfg {Boolean} allowEdit
 *   False to disable adding/removing tags.  Defaults to true.
 *
 */
AIR2.UI.TagPanel = function (config) {
    var searchArea, s;

    config.showTotal = true;
    config.itemSelector = 'li.air2-tag-list-item';
    config.tpl = new Ext.XTemplate(
        '<div style="display:inline-block"><ul class="air2-tag-list">' +
          '<tpl for=".">' +
            '<li class="air2-tag-list-item" {[this.quickTip(values)]}">' +
              '{[AIR2.Format.tagName(values)]}' +
              '<span class="air2-tag-delete-icon"/>' +
            '</li>' +
          '</tpl>' +
        '</ul></div>',
        {
            quickTip: function (values) {
                if (values.tm_type === 'I') {
                    return 'ext:qtip="' + values.iptc_name + '"';
                }
                return '';
            }
        }
    );

    // create the searchbox for tagmaster records
    this.tagsearch = new AIR2.UI.SearchBox({
        cls: 'air2-magnifier',
        autoCreate: {
            tag: 'input',
            type: 'text',
            autocomplete: 'off',
            maxlength: '32'
        },
        maskRe: /[a-zA-Z0-9 _\-\.]/,
        searchUrl: AIR2.HOMEURL + '/tag',
        valueField: 'tm_id',
        displayField: 'tm_name',
        formatComboListItem: function (values) {
            var name, usage;

            name = AIR2.Format.tagName(values);
            name = name.replace(
                this.queryRegExp,
                '<b>' + this.queryString + '</b>'
            );
            usage = values.usage ? " (" + values.usage + ")" : '';
            return name + usage;
        },
        formatToolTip: function (values) {
            var n;
            if (values.tm_type === 'I') {
                if (values.IptcMaster) {
                    n = values.IptcMaster.iptc_name;
                }
                else {
                    n = values.iptc_master;
                }
                return 'ext:qtip="' + n + '"';
            }
            return '';
        },
        forceSelection: false,
        width: 220,
        allowBlank: true,
        listeners: {
            beforequery: function (queryevent) {
                queryevent.query = this.getRawValue();
                this.tpl.queryString = queryevent.query;
                this.tpl.queryRegExp = new RegExp(queryevent.query, 'i');
            },
            select: function (combo, record, index) {
                if (record.get('tm_type') === 'I') {
                    combo.selectedDisplay = record.data.IptcMaster.iptc_name;
                } else {
                    combo.selectedDisplay = record.get('tm_name');
                }
                combo.setRawValue(combo.selectedDisplay);
            },
            specialkey: {fn: function (combo, e) {
                if (e.getKey() === e.ENTER) {
                    this.addTag();
                }
            }, scope: this}
        }
    });
    this.tagbutton = new AIR2.UI.Button({
        air2type: 'FRIENDLY',
        air2size: 'MEDIUM',
        iconCls: 'air2-icon-tag-plus',
        text: 'Add',
        handler: this.addTag,
        scope: this
    });
    searchArea = new Ext.Container({
        cls: 'tag-add',
        items: [this.tagsearch, this.tagbutton]
    });

    // call parent constructor
    AIR2.UI.TagPanel.superclass.constructor.call(this, config);

    // hide the editing functionality
    if (config.allowEdit === false) {
        this.addClass('read-only');
    }

    // searchbox at the top of the body
    this.getBody().insert(0, searchArea);

    // remote action
    s = this.getStore();
    s.on('beforesave', function () {
        this.remoteStart();
    }, this);
    s.on('save', function () {
        this.remoteEnd();
        this.setTotal(s.getCount());
    }, this);
    s.on('load', function () {
        this.setStatus(null);
    }, this);

    // setup click listener
    this.on('afterrender', function () {
        this.el.on('click', function (ev, htmlEl) {
            var d, r, tagname;

            if (ev.getTarget('.air2-tag-delete-icon')) {
                d = this.getDataView();
                r = d.getRecord(ev.getTarget(d.itemSelector));
                d.store.remove(r);
                d.store.save();
                tagname = AIR2.Format.tagName(r.data);
                this.setStatus(
                    'Removed tag "' + tagname +
                    '" <a class="air2-button undo">Undo</a> <a href="#"><img src="../css/img/icons/cross-small.png"></a>' 
                );
                this.undoRec = r;
            }
            else if (ev.getTarget('.undo')) {
                this.setStatus(false);
                this.ajaxCreate({tm_id: this.undoRec.get('tm_id')});
            }
        }, this);
    }, this);
};
Ext.extend(AIR2.UI.TagPanel, AIR2.UI.Panel, {
    cls: 'air2-panel air2-tagpanel',
    onRender: function (ct, position) {
        AIR2.UI.TagPanel.superclass.onRender.call(this, ct, position);
        this.remoteAction = ct.createChild({cls: 'air2-form-remote-wait'});
    },
    remoteStart: function () {
        this.tagsearch.disable();
        this.tagbutton.disable();
        this.remoteAction.alignTo(this.tagsearch.el, 'tr-tr', [0, 2]).show();
    },
    remoteEnd: function () {
        this.tagsearch.enable();
        this.tagbutton.enable();
        this.remoteAction.hide();
    },
    addTag: function () {
        var raw, rec;

        raw = this.tagsearch.getRawValue().trim();
        if (raw.length > 0) {
            this.setStatus(false);
            rec = this.tagsearch.getSelectedRecord();
            if (raw === this.tagsearch.selectedDisplay) {
                this.ajaxCreate({tm_id: rec.get('tm_id')});
            } else {
                this.ajaxCreate({tm_name: raw});
            }
        }
        this.tagsearch.clearValue();
    },
    ajaxCreate: function (data) {
        var s, self;

        s = this.getStore();
        this.remoteStart();

        // fire!
        self = this;
        Ext.Ajax.request({
            url: this.getStore().url,
            params: {radix: Ext.encode(data)},
            callback: function (opt, success, rsp) {
                var data, msg, rec, title;

                this.remoteEnd();

                data = Ext.decode(rsp.responseText);
                success = (success) ? data.success : false;
                if (!success) {
                    if (rsp.status === 403) {
                        title =  'Permission Denied';
                    }
                    else {
                        title = 'Error';
                    }
                    msg = (data) ? data.message : 'Unknown server error';
                    AIR2.UI.ErrorMsg(this.tagsearch.el, title, msg);
                    return;
                }

                // show the created tag
                if (data.radix) {
                    rec = s.getById(data.radix.tag_tm_id);
                    if (!rec) {
                        rec = new s.recordType(data.radix);
                        s.insert(0, rec);
                    }
                }
                self.reload();
            },
            scope: this
        });
    },
    setStatus: function (msg, timeoutMs) {
        if (!this.status) {
            this.status = this.body.el.insertSibling({cls: 'tag-status'});
            this.status.sequenceFx();
        }

        var s = this.status, l = this.body.el, o = this.status.opened;
        if (msg) {
            s.opened = true;
            if (o) {
                s.update(msg);
                s.alignTo(l, 'b-b', [0, -15]);
            }
            else {
                s.shift({
                    duration: 0,
                    callback: function () {
                        s.update(msg);
                        s.alignTo(l, 'b-b', [0, -15]);
                        s.slideIn('b', {duration: 0.1});
                    }
                });
            }
        }
        else {
            s.opened = false;
            if (o) {
                s.slideOut('b', {duration: 0.1});
            }
        }
    },
    getStore: function () {
        return this.getDataView().store;
    },
    getDataView: function () {
        return this.getBody().get(1);
    }
});
Ext.reg('air2tagpanel', AIR2.UI.TagPanel);
