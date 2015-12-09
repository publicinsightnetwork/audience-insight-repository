/*
 *  PIN Form
 *  (c) 2013 American Public Media Group
 *
 *  Requires jQuery >= 1.4
 *
 *  Simple example:

 *  <script type="text/javascript" src="https://www.publicinsightnetwork.org/source/js/jquery-1.8.1.min.js"></script>
 *  <script type="text/javascript" src="https://www.publicinsightnetwork.org/air2/js/pinform.js?uuid=abcd1234"></script>
 *  <div id="pin-query-abcd1234"></div>
 *
 * 
 *  Advanced example:
 * 
 *  <div id="my-query"></div>
 *  <script type="text/javascript" src="https://www.publicinsightnetwork.org/source/js/jquery-1.8.1.min.js"></script>
 *  <script type="text/javascript" src="https://www.publicinsightnetwork.org/air2/js/pinform.js"></script>
 *  <script type="text/javascript">
 *    PIN_QUERY = {
 *      uuid: 'abcd1234',
 *      divId: 'my-query',
 *      baseUrl: 'https://www.publicinsightnetwork.org/air2/',
 *      opts: {
 *          includeLegalFooter: true,
 *          validationErrorMsg: 'Sorry, you have problems!',
 *          showIntro: false,
 *          thankYou: function(divId, respData) {
 *              var div = jQuery('#'+divId);
 *              var queryMeta = PIN.Form.Registry[divId];
 *              div.text('Thanks! Your submission is ' + respData.uuid);
 *          },
 *          onRender: function(divId, queryData) {
 *              var div = jQuery('#'+divId);
 *              div.prepend('<h2>'+queryData.query.inq_ext_title+'</h2>');
 *          }
 *      }
 *    };
 *    jQuery(document).ready(function() { PIN.Form.render(PIN_QUERY) });
 *  </script>
 */

// jquery dependency
if (typeof jQuery === 'undefined') {
    alert('jQuery required');
}
else if (jQuery.jquery < 1.6) {
    alert('jQuery 1.6 or newer required');
}

// carve out namespaces
if (typeof PIN === 'undefined') {
    PIN = {};
}
if (typeof PIN.Form === 'undefined') {
    PIN.Form = {};
    //PIN.Form.DEBUG = true;
    PIN.Form.Registry = {};  // possible to have multiple forms on a page
}
else {
    alert('PIN.Form namespace is reserved');
}

// determine where we are served from, in case baseUrl is not defined
var sc = document.getElementsByTagName("script");
jQuery.each(sc, function(idx, tag) {
    if (!tag.src) {
        return;
    }
    var url = tag.src.match(/^(.+)\/pinform\.js\??(.*)/);
    if (url) {
        PIN.Form.THIS_URL = url[1];
        PIN.Form.THIS_URL_PARAMS = url[2];
    }
});

PIN.Form.includeJs = function(filename, onload) {
    var head    = document.getElementsByTagName('head')[0];
    var script  = document.createElement('script');
    script.src  = filename;
    script.type = 'text/javascript';
    script.onload = script.onreadystatechange = function() {
        if ( script.readyState ) { 
            if ( script.readyState === 'complete' || script.readyState === 'loaded' ) { 
                script.onreadystatechange = null;
                if (onload) onload();
            }   
        }   
        else {
            if (onload) onload();
        }   
    };  
    head.appendChild(script);
}

// note protocol to workaround some same-origin bugs
PIN.Form.isHTTPS    = (window.location.protocol === 'https:' ? true : false );
PIN.Form.thisDomain = window.location.protocol + '//' + window.location.hostname;

// track our dependencies
if (typeof PIN.Form.LOADED === 'undefined') {
    PIN.Form.LOADED = {};
    PIN.Form.LOAD_TRIES = 0;
}

// load fixtures from AIR, for states, countries, etc.
if (!PIN.States && PIN.Form.THIS_URL) {
    PIN.Form.includeJs(PIN.Form.THIS_URL+"/cache/fixtures.min.js", function() {
        PIN.Form.DEBUG && console.log('fixtures.min.js loaded');
        PIN.Form.LOADED['fixtures'] = true;
    });
}
else {
    PIN.Form.LOADED['fixtures'] = true;
}

// jquery ui
if (!jQuery.datepicker) {
    PIN.Form.includeJs('https://www.publicinsightnetwork.org/source/js/jquery-ui-1.10.3.min.js', function() {
        PIN.Form.LOADED['ui'] = true;
    });
}
else {
    PIN.Form.LOADED['ui'] = true;
}

// jquery form
if (!jQuery.ajaxForm && !jQuery.fn.ajaxForm) {
    jQuery.getScript('https://www.publicinsightnetwork.org/source/js/jquery.form.js', function() {
        PIN.Form.LOADED['form'] = true;
    });
}
else {
    PIN.Form.LOADED['form'] = true;
}

// all XHR requests should identify themselves as such
// NOTE Jquery form with file upload doesn't send this so we pass hidden param
jQuery(document).ajaxSend(function (event, request, settings) {
    request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
});


/*
 * PIN.Form.setup(args)
 *
 * Injects dependencies, including CSS and query.json
 * Called internally by render().
 *
 * "args" is an object with keys "uuid" and "baseUrl".
 */

PIN.Form.setup = function(args) {
    PIN.Form.DEBUG && console.log("setup");

    var uuid    = args.uuid;
    var baseUrl = args.baseUrl;

    // load our required CSS, if not already loaded.
    var cssfile = baseUrl + 'css/pinform.css';
    var jQueryUICss = '//www.publicinsightnetwork.org/source/css/jquery-ui-themes-1.10.3/themes/smoothness/jquery-ui.min.css';
    var cssIsLoaded = false;
    var jQueryUICssIsLoaded = false;
    for (var i in document.styleSheets) {
        var css = document.styleSheets[i];
        if (!css || !css.href) {
            continue;
        }
        if (css.href == cssfile) {
            // already loaded
            cssIsLoaded = true;
        }
        if (css.href == jQueryUICss) {
            PIN.Form.DEBUG && console.log('found ' + css.href);
            jQueryUICssIsLoaded = true;
        }
    }
    if (!cssIsLoaded) {
        jQuery('head').prepend('<link rel="stylesheet" type="text/css" href="'+cssfile+'" />');
        PIN.Form.DEBUG && console.log("injected css", cssfile);
    }
    if (!jQueryUICssIsLoaded) {
        jQuery('head').prepend('<link rel="stylesheet" type="text/css" href="'+jQueryUICss+'" />');
        PIN.Form.DEBUG && console.log('injected ' + jQueryUICss);
    }

    // load form data, unless it is already loaded.
    if (!args.queryData) {
        var jsonfile = baseUrl + "querys/" + uuid + '.json?';

        // if not same domain as this window, append jsonp param
        if (!baseUrl.match(PIN.Form.thisDomain)) {
            jsonfile += 'callback=?';
        }
        if (args.opts && args.opts.rendered) {
            jsonfile += '&cachebust=' + args.opts.rendered;
        }
        //console.log(window.location);
        PIN.Form.DEBUG && console.log('loading json from', jsonfile);
        jQuery.getJSON(jsonfile, function(resp) {
            PIN.Form.build(resp, args);
        });
    }
    else {
        PIN.Form.DEBUG && console.log('using local queryData');
        PIN.Form.build(args.queryData, args);
    }

}

// determine form params
PIN.Form.getParams = function(args) {

    var uuid, baseUrl, divId, opts;

    // if args present, prefer them.
    if (args && args.uuid) {
        uuid = args.uuid;
    }
    else if (PIN_QUERY && PIN_QUERY.uuid) {
        uuid = PIN_QUERY.uuid;
    }
    else {
        jQuery.error("uuid not defined");
        return;
    }

    if (args && args.baseUrl) {
        baseUrl = args.baseUrl;
    }
    else if (typeof PIN_QUERY != 'undefined' && PIN_QUERY.baseUrl) {
        baseUrl = PIN_QUERY.baseUrl;
    }
    else {
        baseUrl = 'https://www.publicinsightnetwork.org/air2/';
    }

    if (!baseUrl.match(/\/$/)) {
        baseUrl += '/';
    }
    
    //console.log(PIN.Form.isHTTPS);
    //console.log(baseUrl.match(/^https:/));
    
    if (args && args.divId) {
        divId = args.divId;
    }
    else if (typeof PIN_QUERY != 'undefined' && PIN_QUERY.divId) {
        divId = PIN_QUERY.divId;
    }
    else {
        divId = 'pin-query-'+uuid;
    }

    if (args && args.opts) {
        opts = args.opts;
    }
    else if (typeof PIN_QUERY != 'undefined' && PIN_QUERY.opts) {
        opts = PIN_QUERY.opts;
    }

    return {
        uuid: uuid,
        baseUrl: baseUrl,
        divId: divId,
        queryData: args.queryData,  // pass through if defined
        opts: opts
    };
}

// main public method
PIN.Form.render = function(args) {

    // make sure our dependencies have loaded and defer if not.
    if (!PIN.Form.LOADED['fixtures'] || !PIN.Form.LOADED['ui'] || !PIN.Form.LOADED['form']) {
        PIN.Form.DEBUG && console.log('dependencies not loaded yet', PIN.Form.LOADED);
        if (PIN.Form.WAITING) {
            clearTimeout(PIN.Form.WAITING);
        }
        // 40 tries * 250 ms == 10 sec wait time.
        if (PIN.Form.LOAD_TRIES++ > 40) {
            PIN.Form.DEBUG && console.log("Too many tries loading dependencies");
            return; // give up TODO message?
        }
        PIN.Form.WAITING = setTimeout(function() {
            PIN.Form.render(args);
        }, 250);   // try again in .25 sec
        return;
    }
    else {
        PIN.Form.DEBUG && console.log('LOADED ok:', PIN.Form.LOADED);
    }

    var params = PIN.Form.getParams(args);
    PIN.Form.setup(params);
}

PIN.Form.sortQuestions = function(queryData) {
    // group questions into 3 groups, sorted by sequence
    var sorted = {
        contributor: [],
        public: [],
        private: []
    };
    var perm_ques;
    var hasMultiPage = false;
    jQuery.each(queryData.questions, function(idx, q) {
        if (q.ques_type.toLowerCase() == 'z'
         || q.ques_type.toLowerCase() == 's'
         || q.ques_type.toLowerCase() == 'y'
        ) {
            sorted.contributor.push(q);
        }
        else if (q.ques_type.toLowerCase() == 'p') {
            perm_ques = q;
        }
        else if (q.ques_public_flag == 1) {
            sorted.public.push(q);
        }
        else {
            sorted.private.push(q);
        }

        if (q.ques_type == '4') {
            hasMultiPage = true;
        }
    });

    // sort perm question in explicit dis_seq order if no public questions
    if (!sorted.public.length && perm_ques) {
        sorted.private.push(perm_ques);
    }

    // now sort by sequence
    sorted.contributor.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });
    sorted.public.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });
    sorted.private.sort(function(a,b) { return a.ques_dis_seq - b.ques_dis_seq; });

    // only group perm question with public if other public question exist
    // and force it to be last.
    if (sorted.public.length && perm_ques) {
        sorted.public.push(perm_ques);
    }

    // flatten groups into a single array, retaining overall order.
    var sortedQuestions = [].concat.apply([], [sorted.contributor, sorted.public, sorted.private]);
    PIN.Form.DEBUG && console.log(sortedQuestions);

    // if this is a multi-page form, group them into "pages"
    if (hasMultiPage) {
        var pages     = [];
        var currArray = [];

        jQuery.each(sortedQuestions, function(idx, q) {
            if (q.ques_type == '4' && currArray.length != 0) {
                pages.push(currArray);
                currArray = [];
            }
            else {
                currArray.push(q);
            }
        });
    
        if (currArray.length != 0) {
            pages.push(currArray);
        }
        return pages;
    }
    else {
        return [sortedQuestions]; // single page
    }
}

// generate the HTML
PIN.Form.build = function(queryData, renderArgs) {
    PIN.Form.DEBUG && console.log(renderArgs);
    PIN.Form.DEBUG && console.log(queryData);

    if (typeof renderArgs.opts == 'undefined') {
        renderArgs.opts = {
            showIntro: true
        };
    }

    if (queryData.error) {
        var msg = 'Sorry, there was an error fetching query data.';
        if (queryData.msg) {
            msg = queryData.msg;
        }
        jQuery('#'+renderArgs.divId).html('<div class="error">' + msg + '</div>');
        return;
    }

    // register this form in global var for submit()
    PIN.Form.Registry[renderArgs.divId] = { data: queryData, args: renderArgs };

    var previewAttribute, sortedQuestions, wrapper, formEl;

    sortedQuestions = PIN.Form.sortQuestions(queryData);
    PIN.Form.DEBUG && console.log(sortedQuestions);

    // disable submit if in preview mode
    if (renderArgs.previewMode) {
        previewAttribute = 'disabled="disabled"';
    }        
    else {
        previewAttribute = '';
    }        

    wrapper = jQuery('#'+renderArgs.divId);

    // insert if not found
    if (!wrapper || !wrapper.length) {
        jQuery('body').append('<div id="'+renderArgs.divId+'"></div>');
        wrapper = jQuery('#'+renderArgs.divId);
    }

    // clear to start, in case there were any spinning wheels, etc.
    wrapper.html('<!-- pin.form start -->');

    // deadline msg if defined and deadline has passed
    if (queryData.query.inq_deadline_dtim 
        && queryData.query.inq_deadline_msg 
        && queryData.query.inq_deadline_msg.length
    ) {
        var now      = new Date();
        var deadline = new Date(Date.parse(queryData.query.inq_deadline_dtim.replace(/ /, 'T')));
        PIN.Form.DEBUG && console.log('now=', now);
        PIN.Form.DEBUG && console.log('deadline=', deadline);
        if (now > deadline) {
            wrapper.append('<div class="pin-deadline">'+queryData.query.inq_deadline_msg+'</div>');
        }
    }

    // intro shown by default
    if (typeof renderArgs.opts.showIntro == 'undefined' || renderArgs.opts.showIntro) {
        wrapper.append('<div class="pin-query-intro">'+(queryData.query.inq_intro_para || queryData.query.inq_rss_intro || '')+'</div>');
    }

    // build up form
    formEl = jQuery('<form enctype="multipart/form-data" action="'+queryData.action+'" method="'+queryData.method+'" class="pin-form">');

    // contributorFieldSet = jQuery('<fieldset>');
    jQuery.each(sortedQuestions, function(idx, quesArray) {
        var sectionsRemaining = sortedQuestions.length - idx - 1;
        var fieldSet = jQuery('<fieldset>');
        var divID = 'pin-fs-'+idx;
        var div = jQuery('<div id="'+divID+'" class="pin-mpf-q-div">');
        var data = {questions: quesArray};
        PIN.Form.Registry[divID]= {data: data, args: renderArgs};
        jQuery.each(quesArray, function(idx2, question) {
            var formatter = PIN.Form.Formatter[question.ques_type];
            // lowercase letters are always hidden
            if (question.ques_type.match(/[a-z]/)) {
                formatter = PIN.Form.doHidden;
            }
            if (!formatter) {
                jQuery.error("No formatter for type " + question.ques_type);
                return;
            }
            var el = formatter({question:question, idx:idx2, opts:renderArgs.opts});
            div.append(el);
        });
        fieldSet.append(div);
        div = jQuery('<div class="pin-question">')
        if (idx != 0) {
            div.append('<input type="button" name="previous" class="pin-mpf-previous action-button mp-button" value="Previous"/>')
        }

        if (sectionsRemaining > 0) {
            div.append('<input type="button" name="next" class="pin-mpf-next action-button mp-button" value="Next"/>');
        }
        else {
            div.append('<button ' + previewAttribute + ' onclick="PIN.Form.submit(\''+renderArgs.divId+'\'); return false" class="pin-submit">Submit</button>');
        }
        
        fieldSet.append(div);
        formEl.append(fieldSet);
    });
    
    // insert the form
    //console.log('insert:', wrapper, formEl);
    wrapper.append(formEl);

    wrapper.append('<div class="pin-query-ending">'+(queryData.query.inq_ending_para||'')+'</div>');

    // inject legal unless explicitly asked not to
    if (typeof renderArgs.opts.includeLegalFooter == 'undefined'
        ||
        renderArgs.opts.includeLegalFooter // is true
    ) {
        var legalUrl = renderArgs.baseUrl + 'legal-' + (queryData.query.locale||'en_US') + '.html';
        if (queryData.query.inq_type != "Q" && queryData.query.inq_type != "F") {
          legalUrl = renderArgs.baseUrl + queryData.query.inq_type + '-legal-' + (queryData.query.locale||'en_US') + '.html';
        }
        var legalWrapper = jQuery('<div id="pin-legal-wrapper"></div>');
        wrapper.append(legalWrapper);
        
        var legalMangler = function(legalHtml) {
            var now = new Date();
            var filteredLegalHtml = legalHtml.replace(/<!-- YEAR -->/, now.getFullYear());
            var copyrightText = [];
            jQuery.each(queryData.orgs, function(idx, org) {
                var orgName = org.display_name;
                if (orgName == 'Global PIN Access') {
                    if (queryData.orgs.length > 1) {
                        return; // skip global pin if it is one of multiple
                    }
                    orgName = 'American Public Media';
                }
                var orgUrl = (org.site || 'http://www.publicinsightnetwork.org/source/en/newsroom/'+org.name);
                copyrightText.push('<a href="'+orgUrl+'">'+orgName+'</a>');
            });
            filteredLegalHtml = filteredLegalHtml.replace(/<!-- COPYRIGHT_HOLDER -->/g, copyrightText.join(', '));
            legalWrapper.append(filteredLegalHtml);
        };
 
        // legal text set in caller
        if (typeof renderArgs.opts.includeLegalFooter === 'object') {
            PIN.Form.DEBUG && console.log('using local legal footer');
            legalMangler(renderArgs.opts.includeLegalFooter.legal);
        }
        
        // NOTE that same origin policy will prevent ajax injection if this
        // query is embedded on non-pin site, so in that case use a JSON callback
        else if (legalUrl.match(PIN.Form.thisDomain)) {
            PIN.Form.DEBUG && console.log('legal inject on same domain, using jQuery.get');                
            // we must filter the returned HTML so can't use .load() method
            jQuery.get(legalUrl, function(legalHtml) {
                legalMangler(legalHtml);
            });
        }
        else {
            PIN.Form.DEBUG && console.log('legal inject different doman, using jQuery.getJSON');
            var legalCallback = renderArgs.baseUrl + 
                'legal.php?callback=?&locale='+(queryData.query.locale||'en_US')+
                '&query='+queryData.query.inq_uuid;
            PIN.Form.DEBUG && console.log(legalCallback);
            jQuery.getJSON(legalCallback, function(resp) {
                legalMangler(resp.legal);
            });        
        }
    }

    // add date pickers
    if (!jQuery.datepicker) {
        PIN.Form.includeJs('https://www.publicinsightnetwork.org/source/js/jquery-ui-1.10.3.min.js', function() {
            jQuery('.pin-query-date input').datepicker();
        });  
    }
    else {
        jQuery('.pin-query-date input').datepicker();
    }

    // add countdown watchers
    var maxlenWatcher = function() {
        var tarea = jQuery(this);
        // get matching countdown el
        //console.log(tarea);
        var countdown = tarea.next();
        var maxlen = countdown.data('maxlen');
        if (!maxlen) {
            return;
        }
        // jquery uses encodeURIComponent on textarea when calling serializeArray later in validate.
        var curlen = tarea.val().length;
        var remlen = parseInt(maxlen) - curlen;
        //console.log(tarea.val());
        //console.log(maxlen, curlen, remlen);
        if (remlen < 0) {
            countdown.text('Maximum length exceeded! ('+(remlen*-1)+' characters over)');
        }
        else {
            countdown.text(remlen + ' characters remaining');
        }
    };
    jQuery('.pin-query-textarea textarea').change(maxlenWatcher);
    jQuery('.pin-query-textarea textarea').keyup(maxlenWatcher);

    // add listeners if this is a multi-page form
    PIN.Form.setupMultipage();

    wrapper.trigger('pinform_built', renderArgs.divId);
    if (renderArgs.opts.onRender) {
        renderArgs.opts.onRender(renderArgs.divId, queryData);
    }
}

PIN.Form.multiPageNextClick = function(ev) {
    if (PIN.Form.animationInProgress) return false;

    var currentFs = $(ev.target).parents("fieldset");
    var nextFs = currentFs.next();
    var currentSetId = currentFs.find(".pin-mpf-q-div").attr('id');
    var formEl = jQuery('#'+currentSetId+' :input');
    var pageValidation = PIN.Form.validatePage(currentSetId, formEl);

    if (!pageValidation["isValid"]) return false;

    // do not trigger animation state till we know we are valid.
    PIN.Form.animationInProgress = true;

    // hide the current fieldset with style
    currentFs.animate({opacity: 0}, {
        step: function(now, mx) {
            var scale = 1 - (1 - now) * 0.2;
            var left = (now * 50)+"%";
            var opacity = 1 - now;
            currentFs.css({'transform': 'scale('+scale+')'});
            nextFs.css({'left': left, 'opacity': opacity});
        },
        duration: 800,
        complete: function(){
            currentFs.hide();
            PIN.Form.animationInProgress = false;
        },
        //this comes from the custom easing plugin  
        easing: 'easeInOutBack'
     });
    nextFs.show();
}

PIN.Form.multiPagePrevClick = function(ev) {
    if (PIN.Form.animationInProgress) return false;
    PIN.Form.animationInProgress = true;

    var currentFs = $(ev.target).parents("fieldset");
    var previousFs = currentFs.prev();

    currentFs.animate({opacity: 0}, {
        step: function(now, mx) {
            var scale = 0.8 + (1 - now) * 0.2;
            var left = ((1-now) * 50)+"%";
            var opacity = 1 - now;
            currentFs.css({'left': left});
            previousFs.css({'transform': 'scale('+scale+')', 'opacity': opacity});
        },
        duration: 800,
        complete: function() {
            currentFs.hide();
            PIN.Form.animationInProgress = false;
        },
        //this comes from the custom easing plugin
        easing: 'easeInOutBack'
    });
    previousFs.show();
}

PIN.Form.setupMultipage = function() {
  $(".pin-mpf-next").click(PIN.Form.multiPageNextClick);
  $(".pin-mpf-previous").click(PIN.Form.multiPagePrevClick);
}


PIN.Form.submit = function(divId) {
    var pageValidation, formVals, formEl, formQA, url, btn, validationErrMsg;
    formEl = jQuery('#'+divId+' form');

    // disable button immediately to avoid multiple clicks
    btn = formEl.find('.pin-submit');
    btn.attr('disabled','disabled');
    btn.text('Checking...');

    validationErrMsg = 'Please fix the form errors above and try again.';
    if (PIN.Form.Registry[divId].args.opts.validationErrMsg) {
        validationErrMsg = PIN.Form.Registry[divId].args.opts.validationErrMsg;
    }

    // validate the entire form
    pageValidation = PIN.Form.validatePage(divId, formEl);
    
    PIN.Form.DEBUG && console.log('formEl: ', formEl);
    formVals = pageValidation['formVals'];
    formQA = pageValidation['formQA'];
    PIN.Form.DEBUG && console.log('formVals: ', formVals);

    // validate object
    if (!pageValidation['isValid']) {
        btn.removeAttr('disabled');
        btn.text('Submit');
        btn.after('<div id="pin-submit-errors" class="pin-error">'+validationErrMsg+'</div>');
        return;
    }

    PIN.Form.DEBUG && console.log('validation OK');

    // add some meta
    formEl.append('<input type="hidden" name="X-PIN-referer" value="'+document.referrer+'"/>');
    formEl.append('<input type="hidden" name="X-PIN-Requested-With" value="XMLHttpRequest"/>');

    btn.text('Submitting your responses...');

    // POST to server    
    var errHandler = function(xhr, stat, err) {
        PIN.Form.DEBUG && console.log("ERROR:", xhr, stat, err);

        // massage response errors into the format we expect
        var resp;
        if (xhr.responseText) {
            resp = jQuery.parseJSON(xhr.responseText);
            PIN.Form.DEBUG && console.log(resp);
        }
        if (!resp) {
            btn.text('Server error -- contact support@publicinsightnetwork.org');
            PIN.Form.DEBUG && console.log("ERROR:", xhr, stat, err);
            jQuery.error(xhr.responseText);
            return;
        }

        var errors = {};
        jQuery.each(resp.errors, function(idx, err) {
            var ques_uuid = err.question;
            if (!errors[ques_uuid]) {
                errors[ques_uuid] = [];
            }
            errors[ques_uuid].push(err.msg);
        });
        PIN.Form.decorate(divId, errors);
        btn.removeAttr('disabled');
        btn.text('Submit');
        validationErrMsg = 'Please fix the form errors above and try again.';
        if (PIN.Form.Registry[divId].args.opts.validationErrMsg) {
            validationErrMsg = PIN.Form.Registry[divId].args.opts.validationErrMsg;
        }    
        btn.after('<div id="pin-submit-errors" class="pin-error">'+validationErrMsg+'</div>');
    };
    
    formEl.ajaxForm({
        crossDomain: true,  // allow from non-pin.org domains
        dataType: 'json',
        beforeSubmit: function(formData, jqForm, options) {
            //console.log('submitting...', formData);
            return true;
        },
        error: function(xhr, stat, err) {
            errHandler(xhr, stat, err);
        },
        success: function(respData, stat, xhr) {
            //console.log("SUCCESS:", respData, stat, xhr);
            
            // don't trust server code and client json parsing 
            if (!respData || (respData && respData.success == false)) {
                errHandler(xhr, stat, xhr.responseText);
                return;
            }

            btn.text('Thanks!');

            // show thank you, deferring to user-defined function
            var queryMeta = PIN.Form.Registry[divId];
            if (queryMeta.args.opts.thankYou) {
                queryMeta.args.opts.thankYou(divId, respData);
            }
            else {
                PIN.Form.renderThankYou(divId, respData);
            }
        },
        complete: function(xhr, stat) {
            //console.log("COMPLETE:", xhr, stat);
            // TODO ?
        }
    });
    formEl.submit();

    return false;   // prevent html form submit
}


PIN.Form.validatePage = function(divId, formEl) {
    var formVals, formQA, isValid;

    // clear any existing validation error msg
    jQuery('#pin-submit-errors').remove();

    // extract all data into a single object
    PIN.Form.DEBUG && console.log('formEl: ', formEl);
    formVals = formEl.serializeArray();

    // turn array of objects into one object
    // for easy lookup
    formQA = {};
    jQuery.each(formVals, function(idx, pair) {
        formQA[pair.name] = pair.value;
    });
    
    // fill out our validation array manually.
    // if we have a file upload, must grab it manually.
    // jQuery also ignores unchecked radio and checkbox inputs
    // so we must manually grab those to make sure required
    // questions are validated.

    jQuery.each(PIN.Form.Registry[divId].data.questions, function(idx,q) {
        if (q.ques_resp_type === 'F') {
            var fileQ = jQuery('#pin-q-'+q.ques_uuid);
            formVals.push({name:q.ques_uuid, value: fileQ.val()});
        }
        if ((q.ques_type === 'P' || q.ques_type === 'C' || q.ques_type === 'R')
            && 
            !formQA[q.ques_uuid+'[]']
        ) {
            var inputs = jQuery('input[name^='+q.ques_uuid+']');
            var inputVal = '';
            jQuery.each(inputs, function(inputIdx, input) {
                if (input.checked) {
                    inputVal = input.val();
                }
            });
            formVals.push({name:q.ques_uuid, value: inputVal});
            formQA[q.ques_uuid] = inputVal;
        }
    });

    PIN.Form.DEBUG && console.log('formVals: ', formVals);

    // validate object
    if (!PIN.Form.validate(divId, formVals)) {
        PIN.Form.decorate(divId, PIN.Form.Registry[divId].errors);
        isValid = false;
    }
    else {
        // clear error msg
        if (jQuery('#pin-submit-errors').length) {
            jQuery('#pin-submit-errors').remove();  
        }
    }

    return { formQA: formQA, formVals: formVals, isValid: isValid };
}

// on successful submission, show thank you message and more queries.
// this is an example only.
// use the opts.thankYou feature in render() to define your own.
PIN.Form.renderThankYou = function(divId, response) {
    var div = jQuery('#'+divId);
    var queryMeta = PIN.Form.Registry[divId];
    PIN.Form.DEBUG && console.log(queryMeta);
    var url;
    if (queryMeta.data.orgs.length) {
        url = queryMeta.data.source_url + '/en/newsroom/' + queryMeta.data.orgs[0].name + '/feed.jsonp?limit=10&callback=?';
    }
    var confirmMessage = queryMeta.data.query.inq_confirm_msg;
    if ( !confirmMessage ) {
        confirmMessage = "Thank you for sharing your insight. A reporter or PIN analyst may contact you to hear more. Even if we don't follow up with you, please know that your contribution has been read, and is being used for background research.";
    }
    div.html(confirmMessage + '<div id="pin-query-'+divId+'-others"></div>');
    if (url) {
        jQuery.getJSON(url, function(resp) {
            var others = jQuery('#pin-query-'+divId+'-others');
            others.append("More of what we're asking and what you're saying:");
            jQuery.each(resp.feed, function(idx, item) {
                var ttl = item.item.title||item.item.headline;
                others.append('<div class="pin-more-'+item.type+'"><a href="'+item.item.uri+'">'+ttl+'</a></div>');
            });
        });
    }
}

PIN.Form.getErrorMsg = function(msg) {
    // TODO localize via external errors.js file
    return msg;
}

PIN.Form.decorate = function(divId, errors) {

    // iterate over errors, populating an error div to each affected question
    jQuery.each(errors, function(ques_uuid, errArr) {
        if (!ques_uuid) {
            //console.log("no ques_uuid in errors:", errArr);
            return;
        }
        var field = PIN.Form.getQuestionField(ques_uuid);
        var errMsgs = [];
        jQuery.each(errArr, function(idx, err) {
            errMsgs.push(PIN.Form.getErrorMsg(err));
        });
        field.attr('data-error', errMsgs.join('<br/>'));
        field.closest('div.pin-question').addClass('pin-error');
        field.closest('div.pin-question').append('<div class="pin-error-msg">'+field.attr('data-error')+'</div>');
    });

}

PIN.Form.getQuestionField = function(ques_uuid) {
    var elId = 'pin-q-'+ques_uuid;
    var field = jQuery('#'+elId);
    if (!field || !field.length) {

        // try with name attribute for radios, checkbox, etc
        field = jQuery('input[name^='+ques_uuid+']');

        if (!field || !field.length) {
            PIN.Form.DEBUG && console.log("Cannot find question for "+elId);
            jQuery.error("Cannot find question for "+elId);
            return;
        }
    }
    return field;
}

PIN.Form.clearError = function(ques_uuid) {
    var el = PIN.Form.getQuestionField(ques_uuid);
    el.removeAttr('data-error');
    el.closest('div.pin-question').removeClass('pin-error');
    el.closest('div.pin-question').find('.pin-error-msg').remove();
}

PIN.Form.isRequired = function(q) {
    if (q.ques_resp_opts && q.ques_resp_opts.require) {
        var req = ' <span class="required">*</span>';
        return req;
    } else {
        return '';
    }
}

// called on submit
PIN.Form.validate = function(divId, submission) {
    //return true; // comment in to test server-side errors
    var isValid = true; // innocent until proven guilty
    var query = PIN.Form.Registry[divId];

    // ease question access by keying by uuid,
    // and clear any errors from previous validation
    // while we're at it.
    var questions = {};
    jQuery.each(query.data.questions, function(idx, q) {
        questions[q.ques_uuid] = q;
        if (!PIN.Form.isDisplayOnly[q.ques_type]) {
            PIN.Form.clearError(q.ques_uuid);
        }
    });
    var errors = {};    // key should be ques_uuid

    PIN.Form.DEBUG && console.log('validation:', questions);

    jQuery.each(submission, function(idx, qPair) {
        var qName = qPair.name;
        if (qName.match(/\[\]$/)) {
            qName = qName.replace('[]','');
        }
        var question = questions[qName];
        if (!question) {
            // most likely a hidden field inserted on initial (failed) submit
            PIN.Form.DEBUG && console.log("no question for qName:", qName);
            return;
        }
        var qvalue   = qPair.value;
        var errs = PIN.Form.validateQuestion(question, qvalue);
        if (errs && errs.length) {
            errors[question.ques_uuid] = errs;
            isValid = false;
        }
    });

    // cache for decoration later
    query.errors = errors;

    return isValid;
}

PIN.Form.validateQuestion = function(question, qvalue) {

    var opts, ques_len, ques_uuid, errors;
    if (!question) {
        console.log('question not defined in validateQuestion');
        jQuery.error('question not defined');
    }
    if (question.ques_resp_opts) {
        opts = question.ques_resp_opts;
    }
    else {
        opts = {};
    }

    PIN.Form.DEBUG && console.log('validate:', opts, question, qvalue);

    ques_uuid = question.ques_uuid;
    errors = [];

    // check opts validity
    if (opts.require && (!qvalue.length || !qvalue.match(/\S/))) {
        errors.push('Required');
    }
    ques_len = qvalue.length; 

    // if the question was a textarea, jquery has encoded it so that newlines
    // etc. are preserved. but our maxlen test should be against the raw (decoded) value.
    // NOTE that js .length measures *characters* not bytes, so if there are any multi-byte
    // characters, this length will under-report the actual byte length.
    if (question.ques_type == 'A') {

        // only attempt to decode if we detect an encoded \n or \r
        if (qvalue.match(/%0[AD]/i)) {
            PIN.Form.DEBUG && console.log('found encoded newline. len before=', ques_len);
            try {
                ques_len = decodeURIComponent(qvalue).length;
                PIN.Form.DEBUG && console.log('len after=', ques_len);
            }
            catch(err) {
                PIN.Form.DEBUG && console.log("caught exception: ", err);
                //errors.push(err);  // user can't help it.
            }
        }
    }
    if (opts.maxlen
        && parseInt(opts.maxlen) > 0
        && ques_len > parseInt(opts.maxlen)
    ) {
        errors.push('Max length exceeded (you have '+ques_len+' max is '+opts.maxlen+')');
    }

    // check type validity
    switch(question.ques_resp_type) {

    case 'S':
        // looks like string
        if (typeof qvalue != "undefined"
            && qvalue.length
            && (typeof qvalue != "string" && typeof qvalue != "number")
        ) {
            errors.push('Not a string');
        }
        break;

    case 'N':
        // looks like number
        if (opts.require && parseInt(qvalue) == "NaN") {
            errors.push('Not a number');
        }
        break;

    case 'Y':
        // looks like a 4 digit year
        if (opts.require && !qvalue.match(/^[0-9]{4,}$/)) {
            errors.push('Not a 4 digit year (1900)');
        }
        if (opts.require && opts.hasOwnProperty('startyearoffset') && opts.hasOwnProperty('endyearoffset')) {
            var startyear, endyear, nowyear, selectedYear;
            nowyear = new Date().getFullYear();
            startyear = parseInt(nowyear - opts.startyearoffset);
            endyear = parseInt(nowyear - opts.endyearoffset);
            selectedYear = parseInt(qvalue);
            if (selectedYear < startyear || selectedYear > endyear) {
                PIN.Form.DEBUG && console.log(selectedYear, startyear, endyear, nowyear, opts);
                errors.push(selectedYear + ' is not in range ' + startyear + ' - ' + endyear);
            }
        }
        break;

    case 'D':
        // looks like date
        if (opts.require && !Date.parse(qvalue)) {
            errors.push('Not a date');
        }
        break;

    case 'T':
        // looks like datetime
        if (opts.require && !Date.parse(qvalue)) {
            errors.push('Not a datetime');
        }
        break;

    case 'E':
        // looks like email
        if (opts.require && !qvalue.match(/^.+\@[\-\w\.]+\.\w+$/)) {
            errors.push('Not an email');
        }
        break;

    case 'U':
        // looks like URL
        if (opts.require && !qvalue.match(/^\w+:\/\//)) {
            errors.push('Not a URL (must be of the form http(s)://....)');
        }
        break;

    case 'P':
        // looks like phone number
        if (opts.require && !qvalue.match(/^[\d\.\ \-\(\)]+$/)) {
            errors.push('Not a phone number');
        }
        break;

    case 'Z':
        // looks like postal code
        if (opts.require && !qvalue.match(/^[\w\ \-]+$/)) {
            errors.push('Not a postal code');
        }
        break;

    case 'F':
        // file
        if (qvalue.length && !qvalue.match(/\.(jpg|jpeg|gif|png|pdf)$/i)) {
            errors.push('Unsupported file upload type');
        }
        break;

    default:
        errors.push('Unknown response type: ' + question.ques_resp_type);

    }

    //console.log(question, ' errors:', errors);

    return errors;
}

/**************************************************************************************************/
// field formatters

PIN.Form.escapeHTML = function(v) {
    //console.log('escape:', v);
    return v.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// TODO each field should have a keyup listener to clear errors when validateQuestion() passes.
PIN.Form.doGeneric = function(args) {
    //console.log(args);
    var q = args.question;
    var preFill = args.opts.preFill;
    //console.log('generic preFill:', preFill, q.ques_uuid);
    var t = '<div class="pin-question pin-query-generic seq-'+q.ques_dis_seq+'">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<span class="pin-field-border">';
    t    += '<input type="text" class="pin-field" name="'+q.ques_uuid+'" id="pin-q-'+q.ques_uuid+'" ';
    if (q.ques_resp_opts && q.ques_resp_opts.maxlen) {
        t += 'maxlength="'+q.ques_resp_opts.maxlen+'" ';
    }
    if (q.ques_resp_opts && q.ques_resp_opts.size) {
        t += 'size="'+q.ques_resp_opts.size+'" ';
    }
    else {
        t += 'size="50" ';
    }
    if (preFill && preFill[q.ques_uuid]) {
        t += ' value="'+PIN.Form.escapeHTML(preFill[q.ques_uuid])+'" ';
    }
    t    += '></input>';
    t    += '</span>';
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doDate = function(args) {
    //console.log(args);
    var q = args.question;
    var preFill = args.opts.preFill;
    //console.log('generic preFill:', preFill, q.ques_uuid);
    var t = '<div class="pin-question pin-query-date seq-'+q.ques_dis_seq+'">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<span class="pin-field-border">';
    t    += '<input type="text" class="pin-field" name="'+q.ques_uuid+'" id="pin-q-'+q.ques_uuid+'" ';
    if (q.ques_resp_opts && q.ques_resp_opts.maxlen) {
        t += 'maxlength="'+q.ques_resp_opts.maxlen+'" ';
    }
    if (q.ques_resp_opts && q.ques_resp_opts.size) {
        t += 'size="'+q.ques_resp_opts.size+'" ';
    }
    else {
        t += 'size="50" ';
    }
    if (preFill && preFill[q.ques_uuid]) {
        t += ' value="'+PIN.Form.escapeHTML(preFill[q.ques_uuid])+'" ';
    }
    t    += '></input>';
    t    += '</span>';
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doRadio = function(args) {
    var q = args.question;
    var choices = q.ques_choices;
    var t = '<div class="pin-question pin-query-radio type-'+q.ques_type+' seq-'+q.ques_dis_seq;
    var dir;
    if (q.ques_resp_opts && (q.ques_resp_opts.direction || q.ques_resp_opts.dir)) {
        dir = q.ques_resp_opts.direction || q.ques_resp_opts.dir;
    }
    if (dir && dir === 'H') {
        t += ' pin-query-horizontal';
    }
    t    += '">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';

    jQuery.each(choices, function(idx, choice) {
        t += '<label class="radio option">';
        t += '<input type="radio" class="pin-field" name="'+q.ques_uuid+'[]" id="pin-q-'+idx+'-'+q.ques_uuid+'" ';
        if (choice.isdefault) {
            t += ' checked="checked" ';
        }
        t += 'value="'+choice.value+'" />&nbsp;'+choice.value+'</label>';
    });
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doHidden = function(args) {
    var q = args.question;
    var preFill = args.opts.preFill;
    var t = '<input class="pin-field seq-'+q.ques_dis_seq+'" type="hidden" id="pin-q-'+q.ques_uuid+'" name="'+q.ques_uuid+'"';
    if (preFill && preFill[q.ques_uuid]) {
        t += ' value="'+PIN.Form.escapeHTML(preFill[q.ques_uuid])+'" ';
    }
    t += ' />';
    return jQuery(t);
}

PIN.Form.doTextArea = function(args) {
    var q = args.question;
    var preFill = args.opts.preFill;
    var rows, cols;
    rows = 3;
    cols = 65;
    if (q.ques_resp_opts) {
        if (q.ques_resp_opts.rows) {
            rows = parseInt(q.ques_resp_opts.rows)
        } else {
            rows = 5
        }
        if (q.ques_resp_opts.cols) {
            cols = parseInt(q.ques_resp_opts.cols);
        } else {
            cols = 20
        }
    }
    var t = '<div class="pin-question pin-query-textarea seq-'+q.ques_dis_seq+'">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<span class="pin-field-border">';
    t    += '<textarea class="pin-field" name="'+q.ques_uuid+'" id="pin-q-'+q.ques_uuid+'" rows="'+rows+'" cols="'+cols+'">';
    if (preFill && preFill[q.ques_uuid]) {
        t += ' value="'+PIN.Form.escapeHTML(preFill[q.ques_uuid])+'" ';
    }
    t    += '</textarea>';
    if (q.ques_resp_opts && q.ques_resp_opts.maxlen) {
        var maxlen = parseInt(q.ques_resp_opts.maxlen);
        if (maxlen > 0 && maxlen < 64000) {
            t += '<span class="pin-countdown" data-maxlen="'+maxlen+'" id="pin-countdown-'+q.ques_uuid+'">';
            t += maxlen + ' characters remaining</span>';
        }
    }
    t    += '</span>';
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doText = function(args) {
    var q = args.question;
    var preFill = args.opts.preFill;
    //console.log('preFill:', preFill, q.ques_uuid);
    var t = '<div class="pin-question pin-query-text seq-'+q.ques_dis_seq+'">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<span class="pin-field-border">';
    t    += '<input type="text" class="pin-field" name="'+q.ques_uuid+'" id="pin-q-'+q.ques_uuid+'" ';
    if (q.ques_resp_opts && q.ques_resp_opts.maxlen) {
        t += 'maxlength="'+q.ques_resp_opts.maxlen+'" ';
    }
    if (q.ques_resp_opts && q.ques_resp_opts.size) {
        t += 'size="'+q.ques_resp_opts.size+'" ';
    }
    else {
        t += 'size="50" ';
    }
    if (preFill && preFill[q.ques_uuid]) {
        t += ' value="'+PIN.Form.escapeHTML(preFill[q.ques_uuid])+'" ';
    }
    t    += '></input>';
    t    += '</span>';
    t    += '</div>';
    return jQuery(t);
}

// TODO doDateTime needs time pick
PIN.Form.doDateTime = PIN.Form.doDate;

PIN.Form.doFile = function(args) {
    var q = args.question;
    var t = '<div class="pin-question pin-query-file seq-'+q.ques_dis_seq+'">';
    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<input type="file" class="pin-field" name="'+q.ques_uuid+'" id="pin-q-'+q.ques_uuid+'" ';
    t    += '></input>';
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doMenu = function(args) {
    var q = args.question;
    var choices = q.ques_choices;
    var opts = q.ques_resp_opts || {};

    // handle years pickers
    if (!choices && opts.hasOwnProperty('startyearoffset') && opts.hasOwnProperty('endyearoffset')) {
        var current, endYear, max, now, nowYear, startYear;

        now = new Date();
        nowYear = now.getFullYear();
        choices = new Array();
        startYear = nowYear - opts.startyearoffset;
        endYear = nowYear - opts.endyearoffset
        current = endYear;

        while(current >= startYear) {
            choices.push({'value' : current});
            current--;
        }

        if (opts.hasOwnProperty('order') && opts.order == 'asc') {
            choices.reverse();
        }

    }

    var def, multiple;
    multiple = false;  // definition of doList vs doMenu
    var menuData = [];
    jQuery.each(choices, function(idx, choice) {
        menuData.push([choice.value,choice.value]);
        if (choice.isdefault) {
            def = choice.value;
        }
    });
    return PIN.Form.buildMenu({
        q:q,
        menuData:menuData,
        def: def,
        multiple:multiple,
        opts: args.opts
    });
}

PIN.Form.doStates = function(args) {
    var q = args.question;
    var t = PIN.Form.buildMenu({q:q, menuData:PIN.States, opts:args.opts});
    return t;
}

PIN.Form.doCountries = function(args) {
    var q = args.question;
    var t = PIN.Form.buildMenu({q:q, menuData:PIN.Countries, opts:args.opts});
    return t;
}

PIN.Form.doCheckbox = function(args) {
    var q = args.question;
    var choices = q.ques_choices;
    var t = '<div class="pin-question pin-query-checkbox seq-'+q.ques_dis_seq;
    var dir; 
    if (q.ques_resp_opts && (q.ques_resp_opts.direction || q.ques_resp_opts.dir)) {
        dir = q.ques_resp_opts.direction || q.ques_resp_opts.dir;
    }    
    if (dir && dir === 'H') {
        t += ' pin-query-horizontal';
    }
    t    += '">';

    t    += '<label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';

    jQuery.each(choices, function(idx, choice) {
        t += '<label class="checkbox option">';
        t += '<input type="checkbox" class="pin-field" name="'+q.ques_uuid+'[]" id="pin-q-'+idx+'-'+q.ques_uuid+'" ';
        if (choice.isdefault) {
            t += ' checked="checked" ';
        }
        t += 'value="'+choice.value+'" />&nbsp;'+choice.value+'</label>';
    });
    t    += '</div>';
    return jQuery(t);
}

PIN.Form.doList = function(args) {
    var q = args.question;
    var choices = q.ques_choices;
    var def, multiple, size;
    multiple = true;  // definition of doList vs doMenu
    if (q.ques_resp_opts && q.ques_resp_opts.rows) {
        size = parseInt(q.ques_resp_opts.rows);
    }
    else {
        size = 8;
    }
    var menuData = [];
    jQuery.each(choices, function(idx, choice) {
        menuData.push([choice.value,choice.value]);
        if (choice.isdefault) {
            def = choice.value;
        }
    });
    return PIN.Form.buildMenu({
        q:q,
        menuData:menuData,
        def: def,
        multiple:multiple,
        size:size,
        opts:args.opts
    });
}

PIN.Form.doBreak = function(opts) {
    return '<hr class="pin-break seq-'+opts.question.ques_dis_seq+'" />';
}

PIN.Form.doPageBreak = function(opts) {
    return '<hr class="pin-pagebreak seq-'+opts.question.ques_dis_seq+'" />';
}

PIN.Form.doDisplay = function(opts) {
    return '<div class="pin-display seq-'+opts.question.ques_dis_seq+'">'+opts.question.ques_value+'</div>';
}

PIN.Form.doPermission = PIN.Form.doRadio;
PIN.Form.doContributor = PIN.Form.doGeneric;

// private method
PIN.Form.buildMenu = function(opts) {
    // menuData should be array of arrays
    //console.log(q, menuData, def);

    var q, menuData, def, multiple, rows, size, preFill;
    preFill = opts.opts.preFill;
    q = opts.q;
    menuData = opts.menuData;
    def = opts.def;
    multiple = opts.multiple;
    size = opts.size;

    var t = '<div class="pin-question pin-query-menu seq-'+q.ques_dis_seq;
    if (multiple) {
        t += ' pin-menu-multiple';
    }
    t    += '"><label for="'+q.ques_uuid+'">'+q.ques_value+PIN.Form.isRequired(q)+'</label>';
    t    += '<select class="pin-field" name="'+q.ques_uuid+'[]" id="pin-q-'+q.ques_uuid+'" ';
    if (multiple) {
        t += 'multiple="multiple" ';
    }
    if (size) {
        t += 'size="'+size+'" ';
    }
    t    += '>';
    if (!def) {
        t    += '<option class="pin-field-option" value="" selected="selected"></option>';
    }
    jQuery.each(menuData, function(idx, pair) {
        t += '<option class="pin-field-option" ';
        t += 'value="'+pair[0]+'" ';
        if (preFill && preFill[q.ques_uuid] && pair[0] == preFill[q.ques_uuid]) {
            t += 'selected="selected" ';
        }
        else if (def && pair[0] == def) {
            t += 'selected="selected" ';
        }
        t += '>'+pair[1]+'</option>';
    });
    t    += '</select>';
    t    += '</div>';
    return jQuery(t);
}

// each question type gets its own formatter
PIN.Form.Formatter = {
    A: PIN.Form.doTextArea,
    T: PIN.Form.doText,
    D: PIN.Form.doDate,
    I: PIN.Form.doDateTime,
    F: PIN.Form.doFile,
    H: PIN.Form.doHidden,
    R: PIN.Form.doRadio,
    O: PIN.Form.doMenu,
    S: PIN.Form.doStates,
    Y: PIN.Form.doCountries,
    C: PIN.Form.doCheckbox,
    L: PIN.Form.doList,
    '2': PIN.Form.doBreak,
    '3': PIN.Form.doDisplay,
    '4': PIN.Form.doPageBreak,
    '!': PIN.Form.doDisplay,  // TODO legacy
    '-': PIN.Form.doBreak,    // TODO legacy
    P: PIN.Form.doPermission,
    Z: PIN.Form.doContributor
};

PIN.Form.isDisplayOnly = {
    '2': true,
    '3': true,
    '4': true,
    '!': true,
    '-': true
};

PIN.Form.parseScriptURIParams = function() {
    var query = PIN.Form.THIS_URL_PARAMS,
        map   = {};
    query.replace(/([^&=]+)=?([^&]*)(?:&+|$)/g, function(match, key, value) {
        (map[key] = map[key] || []).push(value);
    });
    return map;
}

// if any param was passed to this script, parse it and treat it like the inq_uuid
if (typeof PIN.Form.THIS_URL_PARAMS !== 'undefined') {
    var params = PIN.Form.parseScriptURIParams();
    if (params['uuid']) {
        jQuery(document).ready(function() {
            PIN.Form.render({baseUrl:PIN.Form.THIS_URL+'/../', uuid:params['uuid']});
        });
    }
}

/* END PIN.Form */
