/**
 * Export a bin as a CSV.  Since there's really nothing to do, just wait a bit
 * and then show the link
 *
 * @function AIR2.Bin.Exporter.toCSV
 * @cfg {String}    binuuid  (required)
 * @cfg {Function}  callback (required)
 * @cfg {Boolean}   allfacts (optional)
 */
AIR2.Bin.Exporter.toCSV = function (binuuid, callback, allfacts, email) {
    var loc, msg;
    loc = AIR2.HOMEURL + '/bin/' + binuuid + '/exportsource.csv';
    if (allfacts) {
        loc += '?allfacts=1';
    }

    // email or download
    if (email) {
        loc += allfacts ? '&email=1' : '?email=1';
        Ext.Ajax.request({
            url: loc,
            callback: function (opt, success, resp) {
                var msg = '';
                if (resp.status === 202) {
                    msg = 'The results of your CSV export will be emailed to ' +
                        'you shortly';
                    callback(true, msg);
                }
                else {
                    msg = 'There was a problem emailing your CSV file';
                    callback(false, msg);
                }
            }
        });

    }
    else {
        msg = '<a href="' + loc + '">Click to download CSV</a>';
        if (Ext.isIE) {
            msg = '<a href="' + loc +
                '" target="_blank">Click to download CSV</a>';
        }
        callback.defer(1000, this, [true, msg]);
    }
};


/**
 * Trac #4458
 */
AIR2.Bin.Exporter.MAX_CSV_SIZE = 2500;


/**
 * Export submissions from a bin to an Excel spreadsheet.  The results will
 * be emailed to the user.
 *
 * @function AIR2.Bin.Exporter.toXLS
 * @cfg {String}    binuuid  (required)
 * @cfg {Function}  callback (required)
 */
AIR2.Bin.Exporter.toXLS = function (binuuid, callback) {
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/bin/' + binuuid + '/exportsub.json',
        method: 'POST',
        callback: function (opt, success, resp) {
            if (resp.status === 202) {
                callback(true, 'The results of your submission export will ' +
                    'be emailed to you shortly');
            }
            else {
                callback(false, 'There was a problem submissions export');
                Logger(resp);
            }
        }
    });
};


/**
 * Schedule a Mailchimp export of a bin.
 *
 * @function AIR2.Bin.Exporter.toMailchimp
 * @cfg {String}    emailuuid (required)
 * @cfg {String}    binuuid   (required)
 * @cfg {Boolean}   dostrict
 * @cfg {DateTime}  timestamp
 * @cfg {Function}  callback  (required)
 */
AIR2.Bin.Exporter.toMailchimp = function (emailuuid, binuuid, dostrict, timestamp, callback) {
    if (!emailuuid || !binuuid || !callback) {
        alert("Invalid call to mailchimp exporter!");
        return;
    }

    // setup data
    var data = {
        bin_uuid:     binuuid,
        strict_check: dostrict,
        schedule:     timestamp,
        //dry_run:      true,
        //no_export:    true,
    };

    // fire!
    Ext.Ajax.request({
        url: AIR2.HOMEURL + '/email/' + emailuuid + '/export.json',
        params: {radix: Ext.encode(data)},
        method: 'POST',
        callback: function (opts, success, resp) {
            var data, msg;
            data = Ext.util.JSON.decode(resp.responseText);
            if (success && data.success) {
                msg = 'Your email has been sent';
                if (timestamp) msg = 'Your email has been scheduled for export';
                callback(true, msg);
            }
            else {
                if (data && data.message) {
                    msg = data.message;
                }
                else {
                    msg = 'Unknown remote error';
                }
                msg += '<br/>Contact an administrator for help.';
                callback(false, msg);
            }
        }
    });
};
