Ext.ns('AIR2.Import.Utils');

/***************
 * Decode conflicts from a tank_source
 *
 * @param  {Object} tsrc
 * @return {Object} conflicts
 */
AIR2.Import.Utils.decodeConflicts = function (tsrc) {
    var confl, errors;

    confl = { initial: {}, last: false, last_ops: false };
    errors = Ext.decode(tsrc.tsrc_errors);
    if (errors) {
        confl.initial = errors.initial;
        confl.last = errors.last;
        confl.last_ops = errors.last_ops;
    }
    return confl;
};


/***************
 * Find new values in a tank_source object
 *
 * @param  {String} key
 * @param  {Object} tsrc
 * @param  {Object} conflicts
 * @return {Mixed}  value
 */
AIR2.Import.Utils.findNewValue = function (key, tsrc, conflicts) {
    var i, parts, tf;

    if (Ext.isDefined(tsrc[key])) {
        return tsrc[key];
    }

    // look for fact values
    parts = key.split('.');

    if (parts.length === 2 && tsrc.TankFact) {
        for (i = 0; i < tsrc.TankFact.length; i++) {
            tf = tsrc.TankFact[i];
            if (tf.Fact.fact_identifier === parts[0]) {
                if (parts[1] === 'sf_src_value') {
                    return tf.sf_src_value;
                }
                else if (parts[1] === 'sf_src_fv_id' && tf.SourceFV) {
                    return tf.SourceFV.fv_value;
                }
                else if (parts[1] === 'sf_fv_id' && tf.AnalystFV) {
                    return tf.AnalystFV.fv_value;
                }
                else {
                    return '';
                }
            }
        }
    }
    return '';
};


/***************
 * Find existing (old) values in a tank_source object
 *
 * @param  {String} key
 * @param  {Object} tsrc
 * @param  {Object} conflicts
 * @return {Mixed}  value
 */
AIR2.Import.Utils.findOldValue = function (key, tsrc, conflicts) {
    var parts, value;

    if (Ext.isDefined(tsrc.Source[key])) {
        return tsrc.Source[key];
    }

    // look through all "conflicts with" data
    value = '';
    parts = key.split('.');

    Ext.iterate(tsrc.tsrc_withs, function (withkey, withobj) {
        if (parts.length === 2 && withkey.match(new RegExp("^" + parts[0]))) {
            if (parts[1] === 'sf_src_value') {
                return value = withobj.source_text;
            }
            else if (parts[1] === 'sf_src_fv_id') {
                return value = withobj.source_fv;
            }
            else if (parts[1] === 'sf_fv_id') {
                return value = withobj.analyst_fv;
            }
        }
        else if (Ext.isDefined(withobj[key])) {
            return value = withobj[key];
        }
    });
    return value;
};


/***************
 * Format a value to make it more human-readable
 *
 * @param  {String} key
 * @param  {Mixed}  value
 * @return {Mixed}  display
 */
AIR2.Import.Utils.formatValue = function (key, value) {
    return value; //TODO: codemaste/dates/etc
};


/***************
 * Massage tank_source data into something more palatable to a dataview.
 *
 * Specifically creates "rows" and "sections" of data to display
 * within a table.
 *
 * @param  {Object} tsrc
 * @return {Object} data
 */
AIR2.Import.Utils.massageTsrc = function (tsrc) {
    var conflicts,
        errs,
        init,
        mydata,
        num,
        property,
        u;

    u = AIR2.Import.Utils;
    conflicts = u.decodeConflicts(tsrc);
    init = conflicts.initial;
    mydata = [];

    // update window "total"
    num = 0;

    for (property in init) {
        num++;
    }

    AIR2.Import.Resolve.winTotal(num + ' Conflict' + (num === 1 ? '' : 's'));

    // create data from config (DON'T ALTER THE CONFIG!)
    Ext.each(AIR2.Import.CONFIG, function (sectCfg) {
        var addsect = {
            section: sectCfg.section,
            display: false,
            conflict: false,
            items: []
        };

        // go through rows in each section
        Ext.each(sectCfg.items, function (it) {
            var newval, oldval, row;
            // find and format values
            if (it.oldval) {
                oldval = it.oldval(tsrc, init);
            }
            else {
                oldval = u.findOldValue(it.key, tsrc, init);
            }

            if (it.newval) {
                newval = it.newval(tsrc, init);
            }
            else {
                newval = u.findNewValue(it.key, tsrc, init);
            }

            if (it.format) {
                oldval = it.format(oldval);
            }
            else {
                u.formatValue(it.key, oldval);
            }

            if (it.format) {
                newval = it.format(newval);
            }
            else {
                newval = u.formatValue(it.key, newval);
            }

            // create the row
            row = {
                key:      it.key,
                label:    it.label ? it.label : '',
                display:  function () {
                    if (it.display || init[it.key]) {
                        return true;
                    }
                    else {
                        return false;
                    }
                },
                oldval:   oldval,
                newval:   newval,
                conflict: function () {
                    if (init[it.key]) {
                        return true;
                    }
                    else {
                        return false;
                    }
                },
                ops: function () {
                    if (init[it.key]) {
                        return init[it.key].ops;
                    }
                    else {
                        return false;
                    }
                }
            };
            row.display = row.display();
            // check last-conflict keys
            if (conflicts.last) {
                if (conflicts.last_ops) {
                    row.lastop = conflicts.last_ops[it.key];
                }
                else {
                    row.lastop = false;
                }

                if (conflicts.last[it.key]) {
                    row.lastcon = true;
                }
                else {
                    row.lastop = false;
                }
            }

            // set conflict flag on addsection if ANY are in conflict
            addsect.conflict = (addsect.conflict || row.conflict());
            addsect.items.push(row);
        });

        // calculate section display AFTER rows
        if (addsect.conflict || sectCfg.display === true) {
            addsect.display = true;
        }
        else if (Ext.isFunction(sectCfg.display)) {
            addsect.display = sectCfg.display(addsect);
        }
        mydata.push(addsect);
    });

    // check for fatal errors
    if (tsrc.tsrc_status === 'E') {
        if (tsrc.tsrc_errors) {
            errs = tsrc.tsrc_errors;
        }
        else {
            errs = '(Unknown error)';
        }

        mydata.push({display: false, fatal: true, errors: errs});
    }
    return mydata;
};
