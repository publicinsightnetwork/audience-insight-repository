/***************
 * Create new translation panel
 */
AIR2.Translation.NewPanel = function () {
    var code,
        getFactId,
        pnl,
        text;

    // helper to get fact_ids
    getFactId = function () {
        var id, ident = AIR2.Translation.TYPEBOX.getValue();
        Ext.each(AIR2.Translation.FACTDATA.radix, function (f) {
            if (f.fact_identifier === ident) {
                id = f.fact_id;
            }
        });
        return id;
    };

    // translation text
    text = new AIR2.UI.RemoteText({
        name: 'xm_xlate_from',
        remoteTable: 'translation',
        uniqueErrorText: 'Translation already exists',
        allowBlank: false,
        msgTarget: 'under',
        width: 230,
        reset: function () {
            var fid,
                val;

            val = AIR2.Translation.TYPEBOX.getValue();
            this.emptyText = 'Enter ' + val + ' text';
            fid = getFactId();
            this.params = {xm_fact_id: fid};
            Logger("PARAMS", this.params, fid);
            Ext.form.TextField.superclass.reset.call(this);
        }
    });

    // translation code
    code = new AIR2.UI.ComboBox({
        allowBlank: false,
        msgTarget: 'under',
        width: 230,
        reset: function () {
            var data,
                val;

            val = AIR2.Translation.TYPEBOX.getValue();
            this.emptyText = 'Select ' + val + ' code';
            data = AIR2.Translation.TYPEBOX.getCodes();
            this.store.loadData(data);
            AIR2.UI.ComboBox.superclass.reset.call(this);
        }
    });

    // initial reset and add "type" listener
    text.reset();
    code.reset();
    AIR2.Translation.TYPEBOX.on('select', function () {
        text.reset();
        code.reset();
    });

    // return panel
    pnl = new AIR2.UI.Panel({
        colspan: 1,
        title: 'New Translation',
        cls: 'air2-translation-add',
        iconCls: 'air2-icon-translation-add',
        hidden: !AIR2.Translation.AUTHZ.may_write,
        items: [{
            xtype: 'form',
            unstyled: true,
            hideLabels: true,
            items: [text, code]
        }, {
            xtype: 'container',
            cls: 'add-tools',
            items: {
                xtype: 'air2button',
                air2type: 'UPLOAD',
                air2size: 'LARGE',
                iconCls: 'air2-icon-disk',
                text: 'Save',
                handler: function () {
                    var rec,
                        s;

                    // validation
                    if (!text.isValid() || !code.isValid()) {
                        return;
                    }

                    // create new record
                    s = AIR2.Translation.DATAVIEW.store;
                    rec = new s.recordType();
                    rec.set('xm_fact_id', getFactId());
                    rec.set('xm_xlate_from', text.getValue());
                    rec.set('xm_xlate_to_fv_id', code.getValue());
                    s.add(rec);

                    // mask-save
                    if (s.save() < 1) {
                        return;
                    }
                    AIR2.Translation.DATAVIEW.el.mask('Adding');
                    pnl.el.mask('Adding');
                    s.on('save', function () {
                        AIR2.Translation.DATAVIEW.el.unmask();
                        text.reset();
                        code.reset();
                        pnl.el.unmask();
                        s.reload();
                    }, this, {single: true});
                }
            }
        }]
    });
    return pnl;
};
