/***************
 * List/edit panel for AIR2 manage source emails
 */
AIR2.SrcEmail.List = function () {
    var dv, pnl, template, textFilter, tools;

    template =  new Ext.XTemplate(
        '<table class="sem-table air2-tbl">' +
            // header
            '<tr class="header">' +
                '<th class="sortable" air2fld="src_first_name">' +
                    '<span>Name</span>' +
                '</th>' +
                '<th class="sortable" air2fld="src_status">' +
                    '<span>PIN Status</span>' +
                '</th>' +
                '<th><span>Home Org</span></th>' +
                '<th class="sortable" air2fld="sem_email">' +
                    '<span>Email</span>' +
                '</th>' +
                '<th><span>Email Status</span></th>' +
                '<th class="sortable" air2fld="sem_upd_dtim" air2dir="desc">' +
                    '<span>Bounce Date</span>' +
                '</th>' +
                '<th class="row-ops"></th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="src-email {[this.rowClass(values)]}">' +
                    '<td>' +
                        '{[AIR2.Format.sourceName(values.Source,1,1,30)]}' +
                    '</td>' +
                    '<td>{[this.pinStatus(values)]}</td>' +
                    '<td>{[this.homeOrg(values)]}</td>' +
                    '<td class="eml" {[this.emailTip(values)]}>' +
                        '{[this.emailValue(values)]}' +
                    '</td>' +
                    '<td>{[this.emailStatus(values)]}</td>' +
                    '<td>{[this.emailDtim(values)]}</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit"></button>' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            rowClass: function (values) {
                var str = '';
                if (values.sem_status === 'C') {
                    str += 'confirmed-bad';
                }
                if (values.sem_status !== 'B') {
                    str += ' hide-rowedit';
                }
                if (AIR2.SrcEmail.List.MERGED[values.sem_uuid]) {
                    str += ' merged';
                }
                return str;
            },
            pinStatus: function (values) {
                var c, cls, fmt;

                c = values.Source.src_status;
                cls = '';

                if (c === 'D' || c === 'F' || c === 'U' || c === 'X') {
                    cls = 'lighter';
                }
                fmt = AIR2.Format.codeMaster('src_status', c);
                return '<span class="' + cls + '">' + fmt + '</span>';
            },
            homeOrg: function (values) {
                var src = values.Source;
                if (src && src.SrcOrg && src.SrcOrg.length) {
                    return AIR2.Format.orgName(
                        src.SrcOrg[0].Organization,
                        true
                    );
                }
                return '<span class="lighter">(none)</span>';
            },
            emailStatus: function (values) {
                if (values.sem_status) {
                    return AIR2.Format.codeMaster(
                        'sem_status',
                        values.sem_status
                    );
                }
                return '';
            },
            emailDtim: function (values) {
                if (values.sem_status === 'B') {
                    return AIR2.Format.date(values.sem_upd_dtim);
                }
                return '';
            },
            emailTip: function (values) {
                if (values.sem_email.length > 30) {
                    return 'ext:qtip="' + values.sem_email + '"';
                }
                return '';
            },
            emailValue: function (values) {
                return Ext.util.Format.ellipsis(values.sem_email, 30);
            }
        }
    );

    // track 'merged' email id's
    AIR2.SrcEmail.List.MERGED = {};

    // primary dataview display
    dv = new AIR2.UI.PagingEditor({
        data: AIR2.SrcEmail.DATA,
        url: AIR2.SrcEmail.URL,
        multiSort: 'Source.src_first_name ASC',
        baseParams: AIR2.SrcEmail.PARMS,
        allowEdit: function (rec) {
            return (rec.data.sem_status === 'B');
        },
        allowDelete: function (rec) {
            return (rec.data.sem_status === 'B');
        },
        plugins: [AIR2.SrcEmail.RowControls, AIR2.UI.PagingEditor.HeaderSort],
        itemSelector: '.src-email',
        tpl: template,
        editRow: function (dv, node, rec) {
            var email, emlEl, fp, uuid1, uuid2;

            emlEl = Ext.fly(node).first('.eml');
            emlEl.update('').setStyle('padding', '2px');

            // uuids, in case we need to merge something
            uuid1 = rec.data.Source.src_uuid;
            uuid2 = false;

            // remote email field
            email = new AIR2.UI.RemoteText({
                name: 'sem_email',
                remoteTable: 'srcemail',
                vtype: 'email',
                allowBlank: false,
                msgTarget: 'under',
                autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
                maxLength: 255,
                uniqueErrorText: function (data) {
                    var link, msg, src;

                    email.mode = false;
                    msg = 'Email in use';
                    if (data.conflict && data.conflict[this.getName()]) {

                        uuid2 = data.conflict[this.getName()].src_uuid;
                        src = data.conflict[this.getName()];
                        link = AIR2.Format.sourceName(src, true, true);

                        if (uuid2 === uuid1) {
                            email.mode = 'CONFIRM';
                            msg = 'Email already owned by Source. ';
                            msg += 'Please confirm this one as bad.';
                        }
                        else {
                            email.mode = 'MERGE';
                            msg += ' by ' + link + '. Merge Sources?';
                        }
                    }
                    return msg;
                },
                listeners: {
                    valid: function () {
                        AIR2.SrcEmail.RowControls.setEditMode(dv);
                    },
                    invalid: function (fld) {
                        AIR2.SrcEmail.RowControls.setEditMode(
                            dv,
                            email.mode,
                            uuid1,
                            uuid2
                        );
                    }
                },
                width: emlEl.getWidth() - 20,
                value: rec.data.sem_email
            });

            // render in formpanel
            fp = new Ext.form.FormPanel({
                unstyled: true,
                hideLabels: true,
                items: email,
                renderTo: emlEl
            });
            return [email];
        },
        saveRow: function (rec, edits) {
            rec.set('sem_email', edits[0].getValue());
            rec.set('sem_status', 'G'); //set status to Good
        }
    });

    // text filter box
    textFilter = new Ext.form.TextField({
        width: 230,
        emptyText: 'Filter Emails',
        validationDelay: 700,
        reset: function () {
            Ext.form.TextField.superclass.reset.call(this);
            this.applyEmptyText();

            // check for an existing filter
            if (dv.store.baseParams.q) {
                this.setValue(dv.store.baseParams.q);
            }
        },
        validateValue: function (v) {
            if (v !== this.lastValue) {
                this.remoteAction.alignTo(this.el, 'tr-tr', [-1, 2]);
                this.remoteAction.show();

                // reload the store
                dv.store.setBaseParam('q', v);
                dv.store.on('load', function () {
                    this.remoteAction.hide();
                }, this, {single: true});
                dv.pager.changePage(0);
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
    tools = new Ext.Container({
        cls: 'filter-tools',
        defaults: {margins: '10 10 10 0'},
        items: [textFilter]
    });

    // create paging panel for dataview
    pnl = new AIR2.UI.Panel({
        colspan: 3,
        title: 'Bounced Emails',
        cls: 'air2-source-email',
        iconCls: 'air2-icon-email',
        items: [tools, dv]
    });
    pnl.setTotal(dv.store.getTotalCount());

    return pnl;
};
