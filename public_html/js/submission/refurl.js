/***************
 * Helper for copying ref url's
 */
AIR2.Submission.refUrl = function (dv) {

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {
        // expand/add clicked
        dv.el.on('click', function (e) {
            var el, rec, txt;


            if (e.getTarget('.copy-ref-url')) {
                el = e.getTarget('.copy-ref-url');
                e.preventDefault();
                rec = dv.store.getAt(0);
                txt = new Ext.form.TextField({
                    width: 300,
                    readOnly: true,
                    value: rec.data.srs_uri,
                    selectOnFocus: true,
                    renderTo: el.parentNode,
                    listeners: {
                        blur: function () {
                            txt.destroy();
                            Ext.fly(el).show();
                        }
                    }
                });
                txt.focus(true, 10);

                Ext.fly(el).enableDisplayMode().hide();
            }

        });

    });

};
