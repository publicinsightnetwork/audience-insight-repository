Ext.namespace('AIR2.Util.Response');

/*
 * Create an AIR2.Submission.Responses panel from dynamically-loaded data.
 *
 * @param string    srs_uuid    SrcResponseSet uuid.
 * @param function  callback    Called when panel is created.
 *                              Takes one arg: panel.
 * @param object    config      Config options to pass to AIR2.Submission.
 *                              Responses call.
 *
 * @return void
 */
AIR2.Util.Response.panelFromSrs = function (srs_uuid, callback, config) {
    Ext.Ajax.request({
        // url: AIR2.HOMEURL + '/reader/' + srs_uuid + '.json',
        url: AIR2.HOMEURL + '/submission/query/' + srs_uuid + '.json',

        success: function (resp, opts) {
            var json, panel;

            /*
             * Load and format data so the panel can use it.
             */
            json = Ext.decode(resp.responseText);

            AIR2.Submission.BASE = json;
            AIR2.Submission.INQDATA = {radix: json.radix.Inquiry};
            AIR2.Submission.SRCDATA = {radix: json.radix.Source};
            AIR2.Submission.ALTSUBMS = {radix: []};

            AIR2.Submission.SUBMURL = AIR2.HOMEURL + '/submission/' + srs_uuid;
            AIR2.Submission.URL = AIR2.HOMEURL + '/submission/' + srs_uuid;

            /*
             * Instantiate panel, and give it back to the caller.
             */
            panel = AIR2.Submission.Responses(config);
            callback(panel);
        }
    });
};

/*
 * Format a response to a particular inquiry question.
 *
 * @param object response Response (sr_*) data.
 */
AIR2.Util.Response.formatResponse = function (response, preferOrig) {
    var choices,
        def,
        fmt,
        match,
        name,
        path,
        preview_url,
        sel,
        selects,
        sr_value,
        str,
        type,
        url;

    if (response.sr_mod_value && !preferOrig) {
        sr_value = response.sr_mod_value;
    }
    else {
        sr_value = response.sr_orig_value;
    }
    if (!sr_value) {
        return '<span class="lighter">(no response)</span>';
    }

    // lookup question data
    if (response.Question) {
        choices = Ext.decode(response.Question.ques_choices);
        type = response.Question.ques_type;
    }
    else {
        type = response.ques_type;
    }

    // handle non-text types
    if (type === 'C' || type === 'L' || type === 'M') {
        // TODO: M is there for backwards-compatibility
        str = '<ul class="selections">';

        // multiple values
        selects = sr_value.split('|');
        Ext.each(
            selects,
            function (item) {
                var def, fmt;

                def = AIR2.Util.Response._isDefaultQuestion(choices, item);
                fmt = AIR2.Format.quesChoice(item, type, true, def);
                str += '<li>' + fmt + '</li>';
            },
            this
        );

        str += '</ul>';
    }
    else if (type === 'R' || type === 'O' || type === 'S' || type === 'P' || type === 'p') {
        //TODO: S is there for backwards-compatibility
        str = '<ul class="selections">';

        
        // single value
        sel = sr_value;
        def = AIR2.Util.Response._isDefaultQuestion(choices, sel);
        fmt = AIR2.Format.quesChoice(sel, type, true, def);
        str += '<li>' + fmt + '</li>';

        str += '</ul>';
    }
    else if (type === 'F') {
        // get file name (after the last slash)
        url = sr_value;
        match = url.match(/[^\/]+$/);
        name = (match && match.length) ? match[0] : url;

        // add the server to the url
        path = AIR2.UPLOADSERVER + url;
        str = '<a class="external" target="_blank" href="' + path + '">';
        str += name + '</a>';
        preview_url = sr_value;
        preview_url = preview_url.replace(/\.jpe?g/i, ".png");
        preview_url = preview_url.replace(/\.gif/i, ".png");
        if (preview_url !== sr_value) {
            str += '<span class="air2-preview-img"><img src="';
            str += AIR2.PREVIEWSERVER + preview_url + '"/></span>';
        }
    }
    else {
        // text, textarea, date, and datetime are just plain text
        str = '<pre class="text">' + sr_value + '</pre>';
    }

    if (response.is_contrib_diff) {
        str += ' <div class="air2-contrib-warning"><i class="icon-warning-sign"></i></div>';
    }

   //Logger( response );

    return str;
};

AIR2.Util.Response.formatOptions = function (response) {
    var choices,
        def,
        fmt,
        isChecked,
        sel,
        sr_value,
        str,
        type;

    if (response.sr_mod_value) {
        sr_value = response.sr_mod_value;
    }
    else {
        sr_value = response.sr_orig_value;
    }


    if (response.Question) {
        choices = Ext.decode(response.Question.ques_choices);
        type = response.Question.ques_type;
    }
    else {
        type = response.ques_type;
    }

    if (type === 'T' || type === 'A') {
        return '<textarea>' + sr_value + '</textarea>';
    }
    else if (type === 'R' || type === 'S' || type === 'C' || type === 'P' || type === 'p') {
        //TODO: S is there for backwards-compatibility

        str = '<ul class="selections">';
        sel = sr_value;
        def = '';
        fmt = '';
        isChecked = false;
        var selects = sr_value.split('|');
        Ext.each(choices, function (item) {
            def = AIR2.Util.Response._isDefaultQuestion(choices, item.value);
            if (selects.indexOf(item.value) != -1) {
                isChecked = true;
            }

            fmt = AIR2.Format.liveQuestionChoice(
                item.value,
                type,
                isChecked,
                def,
		        response.Question.ques_uuid
            );
            str += '<li>' + fmt + '</li>';
            isChecked = false;
        }, this);

        str += '</ul>';
        return str;
    } 
    else if (type === 'O' || type === 'L') {
        var name = 'group' + response.Question.ques_uuid;
        var multiselect = '';
        if (type === 'L') {
            multiselect = 'multiple';
        }
        str = '<select name="'+name+'" class="selections" '+multiselect+'>';

        sel = sr_value;
        def = '';
        fmt = '';
        ischecked = false;
        var selects = sr_value.split('|');

        Ext.each(choices, function (item) {
            def = AIR2.Util.Response._isDefaultQuestion(choices, item.value);
            if (selects.indexOf(item.value) != -1) {
                isChecked = true;
            }

            fmt = AIR2.Format.liveQuestionChoice(
                item.value,
                type,
                isChecked,
                def,
                response.Question.ques_uuid
            );
            str += fmt;
            isChecked = false;
        }, this);

        str += '</select>';
        return str;
    }
    else {
        return '<textarea>' + sr_value + '</textarea>';
    }
};

AIR2.Util.Response._isDefaultQuestion = function (choices, value) {
    if (choices) {
        for (var i = 0; i < choices.length; i++) {
            if (choices[i].value === value) {
                if (choices[i].isdefault === '') {
                    return false;
                }
                return choices[i].isdefault;
            }
        }
    }
    return false;
};
