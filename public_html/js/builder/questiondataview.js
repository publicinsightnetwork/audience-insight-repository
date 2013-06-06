/***********************
 * Constructs a new question dataview grouping
 */
AIR2.Builder.QuestionDataView = function (isPublic) {
    var cls,
        dataview,
        isAfterStop,
        isBeforeStop,
        lbl,
        not,
        template,
        tif;

    if (isPublic) {
        cls = 'public dropzone';
        lbl = 'Publishable&nbsp;Fields';
        tif = 'if="ques_public_flag"';
        not = 'if="!ques_public_flag"';
    }
    else {
        cls =  'private dropzone';
        lbl =  'Non-publishable&nbsp;Fields';
        tif =  'if="!ques_public_flag"';
        not = 'if="ques_public_flag"';
    }

    // helpers to check if a mouseY is before/after a stop
    isBeforeStop = function (mouseY, stop) {
        var half = stop.top + ((stop.bottom - stop.top) / 2);
        return (mouseY >= stop.top && mouseY <= half);
    };
    isAfterStop = function (mouseY, stop) {
        var half = stop.top + ((stop.bottom - stop.top) / 2);
        return (mouseY >= half && mouseY <= stop.bottom);
    };

    template = new Ext.XTemplate(
        '<table class="divider">' +
            '<tr>' +
                '<td class="left"/><td class="label">' +
                    lbl +
                '</td>' +
                '<td class="right"/>' +
            '</tr>' +
        '</table>' +
        '<tpl for=".">' +
          '<tpl ' + tif + '>' +
            '<div class="ques-row">' +
              '<div class="handle"></div>' +
              '<div class="controls">' +
                '<button class="air2-rowedit"></button>' +
                '<button class="air2-rowdelete"></button>' +
              '</div>' +
              '<div class="question">' +
                '<h4>{ques_dis_seq} - {ques_value}</h4>' +
              '</div>' +
              '<div class="choices">' +
                '{[this.formatChoices(values)]}' +
              '</div>' +
            '</div>' +
          '</tpl>' +
          // render empty, to prevent store-index-lookup error
          '<tpl ' + not + '>' +
            '<div class="ques-row" style="display:none"></div>' +
          '</tpl>' +
        '</tpl>' +
        '<tpl if="this.isEmpty(values)">' +
          '<div class="empty-row">' +
            '<h3>Drag templates here to get started</h3>' +
          '</div>' +
        '</tpl>',
        {
            compiled: true,
            disableFormats: true,
            isEmpty: function (values) {
                var count, i;
                count = 0;
                for (i = 0; i < values.length; i++) {
                    if (values[i].ques_public_flag === isPublic) {
                        return false;
                    }
                }
                return true;
            },
            formatChoices: function (values) {
                var choices, choiceTypes, type, str;
                // questions that will have choices
                // TODO: M and S are there for backwards-compatibility
                choiceTypes = ['C', 'L', 'R', 'O', 'M', 'S'];
                type = values.ques_type;

                if (choiceTypes.indexOf(type) !== -1) {
                    str = '<ul>';

                    // multiple values
                    choices = Ext.decode(values.ques_choices);
                    Ext.each(choices, function (item, idx) {
                        var def, fmt, val;

                        // truncate absurdly long choices
                        if (idx > 8) {
                            str += '<li class="">...</li>';
                            return false;
                        }

                        val = item.value;
                        def = item.isdefault;
                        fmt = AIR2.Format.quesChoice(val, type, false, def);
                        str += '<li>' + fmt + '</li>';
                    });

                    str += '</ul>';
                    return str;
                }

                // text, textarea, date, and datetime have no choices
                if (type === 'T') {
                    return '<input type="text" disabled></input>';
                }
                if (type === 'A') {
                    return '<textarea disabled></textarea>';
                }
                if (type === 'F') {
                    return '<input type="file" disabled></input>';
                }
                if (type === 'D' || type === 'I') {
                    // stolen!
                    return '<div class="' +
                        'x-form-field-wrap ' +
                        'x-form-field-trigger-wrap ' +
                        'x-item-disabled" ' +
                        'style="' +
                        'width:100px;border-left:1px solid #c1c1c1">' +
                        '<input type="text" ' +
                        'class="x-form-text x-form-field" ' +
                        'style="width: 75px;">' +
                        '<img src="data:image/gif;base64,' +
                        'R0lGODlhAQABAID/AMDAwAAAACH5BAE' +
                        'AAAAALAAAAAABAAEAAAICRAEAOw==" ' +
                        'class="x-form-trigger x-form-date-trigger"></div>';
                }
                return '';
            }
        }
    );

    // create new dataview
    dataview = new AIR2.UI.JsonDataView({
        store: AIR2.Builder.QUESSTORE,
        cls: cls,
        itemSelector: '.ques-row',
        overClass: 'ques-over',
        renderEmpty: true,
        tpl: template,
        cacheStops: function () {
            var hasDisplayed, stops, r;

            stops = [];
            hasDisplayed = false;
            this.all.each(function (el) {
                var r = el.getRegion();
                stops.push({top: r.top, bottom: r.bottom});
                if (el.isDisplayed()) {
                    hasDisplayed = true;
                }
            });
            this.stops = stops;

            // stops for empty dataview
            this.emptyEl = null;
            this.emptyStop = null;
            if (!hasDisplayed) {
                this.emptyEl = this.el.child('.empty-row');
                if (!this.emptyEl) {
                    this.emptyEl = this.el.createChild({
                        cls: 'empty-row',
                        html: '<h3>Drag templates here to get started</h3>'
                    });
                }
                r = this.emptyEl.getRegion();
                this.emptyStop = {top: r.top, bottom: r.bottom};
            }
        },
        getHoverTarget: function (mouseY) {
            if (!this.stops) {
                this.cacheStops();
            }
            for (var i = 0; i < this.stops.length; i++) {
                if (isBeforeStop(mouseY, this.stops[i])) {
                    return {
                        'public': isPublic,
                        dv: this,
                        before: this.getNode(i)
                    };
                }
                if (isAfterStop(mouseY, this.stops[i])) {
                    return {
                        'public': isPublic,
                        dv: this,
                        after: this.getNode(i)
                    };
                }
            }

            // empty stop (always show before)
            if (this.emptyEl) {
                if (isBeforeStop(mouseY, this.emptyStop) ||
                    isAfterStop(mouseY, this.emptyStop)) {
                    return {
                        'public': isPublic,
                        dv: this,
                        before: this.emptyEl.dom,
                        empty: true
                    };
                }
            }
        }
    });

    return dataview;
};
