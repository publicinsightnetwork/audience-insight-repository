/***************
 * Source response set tag handler for the reader
 */
AIR2.Reader.tagHandler = function (dv) {

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {

        // remove/add clicked
        dv.el.on('click', function (e) {
            var el = e.getTarget('a.delete.tag-telete', 5, true);

            if (el) {
                e.preventDefault();
                e.getTarget('li', 5, true).remove();
                Ext.Ajax.request({
                    url: el.getAttribute('href'),
                    method: 'DELETE',
                    failure: function () {
                        Logger("Error deleting tag", arguments);
                    }
                });
            }

        });

    });

};


/***************
 * Source response set tag-adding handler
 *
 * (uses Ext elements, so must be rendered after the dataview render)
 */
AIR2.Reader.tagRender = function (domRow, rec) {
    var addTag, mkTagMarkup, tagbutton, tagsearch;

    if (rec.data.may_write) {

        // helper to make tag-markup from an object/string
        mkTagMarkup = function (tag) {
            var cls, label, str, url, usage;

            label = tag.data ? AIR2.Format.tagName(tag.data) : tag;
            usage = tag.data ? tag.data.usage : '&nbsp;';
            cls   = tag.data ? 'tag' : 'tag placeholder';
            str = '<a class="' + cls + '">' + label + '&nbsp;<span>' + usage;
            str += '</span></a>';

            if (tag.data) {
                url = rec.data.tag_url + '/' + tag.data.tm_id + '.json';
                str += '<a class="delete tag-telete" href="' + url + '"></a>';
            }
            return {tag: 'li', html: str, id: Ext.id()};
        };

        // helper to do the actual tag add POST-ing/rendering
        addTag = function () {
            var cfg, selObj, selRec, radix, raw, tagList;

            raw = tagsearch.getRawValue().trim();
            if (raw.length > 0) {
                selRec = tagsearch.getSelectedRecord();
                selObj = (raw == tagsearch.selectedDisplay) ? selRec : raw;

                // render tag in list
                tagList = Ext.fly(domRow).child('ul.tags');
                cfg = mkTagMarkup(selObj);
                tagList.createChild(cfg);

                // ajax post the tag
                if (selObj.data) {
                    radix = {tm_id: selObj.data.tm_id};
                }
                else {
                    radix = {tm_name: selObj};
                }

                Ext.Ajax.request({
                    url: rec.data.tag_url + '.json',
                    params: {radix: Ext.encode(radix)},
                    callback: function (opt, success, rsp) {
                        var cfg, data, msg, replace, tagList, title;

                        data = Ext.decode(rsp.responseText);
                        success = (success) ? data.success : false;
                        if (success) {
                            replace = Ext.get(this.id);
                            tagList = Ext.fly(domRow).child('ul.tags');
                            cfg = mkTagMarkup({data: data.radix});
                            replace.replaceWith(cfg);
                        }
                        else {
                            if (rsp.status == 403) {
                                title = 'Permission Denied';
                            }
                            else {
                                title = 'Error';
                            }

                            if (data) {
                                msg = data.message;
                            }
                            else {
                                msg = 'Unknown server error';
                            }

                            AIR2.UI.ErrorMsg(tagsearch.el, title, msg);
                        }
                    },
                    scope: cfg
                });
            }
            tagsearch.clearValue();
        };

        // actual tag search field
        tagsearch = new AIR2.UI.SearchBox({
            renderTo: Ext.fly(domRow).child('.tag-adding-ct'),
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
                usage = '';
                if (values.usage) {
                    usage = " (" + values.usage + ")";
                }

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
            width: 200,
            allowBlank: true,
            listeners: {
                beforequery: function (queryevent) {
                    queryevent.query = this.getRawValue();
                    this.tpl.queryString = queryevent.query;
                    this.tpl.queryRegExp = new RegExp(queryevent.query, 'i');
                },
                select: function (combo, record, index) {
                    if (record.get('tm_type') === 'I') {
                        combo.selectedDisplay =
                            record.data.IptcMaster.iptc_name;
                    }
                    else {
                        combo.selectedDisplay = record.get('tm_name');
                    }
                    combo.setRawValue(combo.selectedDisplay);
                },
                specialkey: {fn: function (combo, e) {
                    if (e.getKey() === e.ENTER) {
                        addTag();
                    }
                }, scope: this}
            }
        });

        // tag add-button
        tagbutton = new Ext.BoxComponent({
            renderTo: Ext.fly(domRow).child('.tag-adding-ct'),
            cls: 'add add-tag',
            html: 'Add tag',
            listeners: {
                render: function (box) {
                    box.el.on('click', addTag);
                }
            }
        });

    }

};
