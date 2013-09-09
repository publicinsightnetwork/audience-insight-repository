Ext.ns('AIR2.Source.Contact');
/***************
 * Source Contact Modal - Email tab
 */
AIR2.Source.Contact.Email = function () {
    var template;
    //Logger("Base");
    //Logger(AIR2.Source.BASE);

    template = new Ext.XTemplate(
        '<table class="air2-tbl">' +
            // header
            '<tr>' +
                '<th class="fixw center"><span>Primary</span></th>' +
                '<th><span>Type</span></th>' +
                '<th><span>Email</span></th>' +
                '<th><span>Status</span></th>' +
                '<th class="row-ops">' +
                    '<tpl if="' + AIR2.Source.BASE.authz.unlock_write + '">' +
                        '<button class="air2-rowadd"></button>' +
                    '</tpl>' +
                '</th>' +
            '</tr>' +
            // rows
            '<tpl for=".">' +
                '<tr class="email-row">' +
                    '<td class="center">' +
                        '<tpl if="sem_primary_flag">' +
                            '<span class="air2-icon air2-icon-check"></span>' +
                        '</tpl>' +
                    '</td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"sem_context",' +
                            'values.sem_context' +
                        ')]}' +
                    '</td>' +
                    '<td>{[this.sourceEmail(values)]}</td>' +
                    '<td>' +
                        '{[AIR2.Format.codeMaster(' +
                            '"sem_status",' +
                            'values.sem_status' +
                        ')]}' +
                    '</td>' +
                    '<td class="row-ops">' +
                        '<button class="air2-rowedit"></button>' +
                        '<button class="air2-rowdelete"></button>' +
                    '</td>' +
                '</tr>' +
            '</tpl>' +
        '</table>' +
        '<tpl if="AIR2.Source.hasAcct">' +
            '<div class="air2-tooltip-inline">' +
             'Note that updating the primary email address does not update the username.' +
            '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            // only enable primary + good mailto links
            sourceEmail: function (v) {
                if (v.sem_status == 'G' && v.sem_primary_flag) {
                    return AIR2.Format.mailTo(v.sem_email, AIR2.Source.BASE.radix);
                }
                return '<span>' + v.sem_email + '</span>';
            }
        }
    );

    return new AIR2.UI.PagingEditor({
        title: 'Email',
        url: AIR2.Source.URL + '/email',
        multiSort: 'sem_primary_flag desc, sem_cre_dtim desc',
        newRowDef: {sem_primary_flag: false, sem_status: 'G'},
        allowEdit: AIR2.Source.BASE.authz.unlock_write,
        allowDelete: AIR2.Source.BASE.authz.unlock_write,
        itemSelector: '.email-row',
        plugins: [AIR2.UI.PagingEditor.InlineControls],
        tpl: template,
        editRow: function (dv, node, rec) {
            var edits,
                email,
                emailEl,
                prime,
                primeEl,
                stat,
                statEl,
                type,
                typeEl;

            // cache dv ref
            rec.dv = dv;
            edits = [];

            // primary
            primeEl = Ext.fly(node).first('td').update('');
            prime = new Ext.form.Checkbox({
                checked: rec.data.sem_primary_flag,
                disabled: rec.data.sem_primary_flag,
                renderTo: primeEl
            });
            edits.push(prime);

            // type
            typeEl = primeEl.next().update('').setStyle('padding', '4px');
            type = new AIR2.UI.ComboBox({
                choices: AIR2.Fixtures.CodeMaster.sem_context,
                value: rec.data.sem_context,
                renderTo: typeEl,
                width: 74
            });
            edits.push(type);

            // email
            emailEl = typeEl.next().update('').setStyle('padding', '4px');
            email = new AIR2.UI.RemoteText({
                autoCreate: {tag: 'input', type: 'text', maxlength: '255'},
                maxLength: 255,
                allowBlank: false,
                vtype: 'email',
                name: 'sem_email',
                remoteTable: 'srcemail',
                uniqueErrorText: function (data) {
                    var link, msg, src;

                    msg = 'Email in use';
                    if (data.conflict && data.conflict[this.getName()]) {
                        src = data.conflict[this.getName()];
                        link = AIR2.Format.sourceName(src, true, true);
                        msg += ' by ' + link;
                    }
                    return msg;
                },
                value: rec.data.sem_email,
                renderTo: emailEl,
                width: 260
            });
            edits.push(email);

            // status
            statEl = emailEl.next().update('').setStyle('padding', '4px');
            stat = new AIR2.UI.ComboBox({
                choices: AIR2.Fixtures.CodeMaster.sem_status,
                value: rec.data.sem_status,
                renderTo: statEl,
                width: 108
            });
            edits.push(stat);
            return edits;
        },
        saveRow: function (rec, edits) {
            // if saving a primary_flag, need to unset others in UI
            var prime = edits[0].getValue();
            if (!rec.phantom && !rec.data.sem_primary_flag && prime) {
                rec.store.on('save', function (s) {
                    s.each(function (r) {
                        if (rec.id !== r.id) {
                            r.data.sem_primary_flag = false;
                            rec.dv.refreshNode(rec.dv.indexOf(r));
                        }
                    });
                }, this, {single: true});
            }

            // update record
            rec.set('sem_primary_flag', edits[0].getValue());
            rec.set('sem_context', edits[1].getValue());
            rec.set('sem_email', edits[2].getValue());
            rec.set('sem_status', edits[3].getValue());
        }
    });
};
