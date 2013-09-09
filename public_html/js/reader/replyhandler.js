/***************
 * Submission reply handler
 */
AIR2.Reader.replyHandler = function (dv) {

    // since the expanded row doesn't get included in the dataview 'click'
    // event, we need to listen to the actual DOM click
    dv.on('afterrender', function (dv) {
        var node, rec, t;

        // expand/add clicked
        dv.el.on('click', function (e) {
            if (t = e.getTarget('a.submission-reply')) {
                e.preventDefault();

                // get the dv record
                node = e.getTarget('.reader-expand', 10, true).prev(dv.itemSelector, true);
                rec = dv.getRecord(node);

                // query and source names
                var queryName, srcFullName;
                queryName = rec.data.inq_title;
                if (rec.data.inq_ext_title) {
                    queryName = Ext.util.Format.stripTags(rec.data.inq_ext_title);
                }
                srcFullName = rec.data.src_username;
                if (rec.data.src_first_name && rec.data.src_last_name) {
                    srcFullName = rec.data.src_first_name + ' ' + rec.data.src_last_name;
                }

                // open a reply modal
                AIR2.Email.Sender({
                    originEl: t,
                    title: 'Reply to ' + srcFullName,
                    srs_uuid: rec.data.srs_uuid,
                    internal_name: 'Re: ' + srcFullName + ' - ' + queryName,
                    type: 'F',
                    subject_line: 'Re: ' + queryName
                });
            }
        });

    });

};
