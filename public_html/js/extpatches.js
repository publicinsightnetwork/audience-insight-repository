/***************
 * Monkey-patching ExtJS
 *
 * Execute anonymous-closure functions to override/extend some default ExtJS
 * functionality.
 */


/*
 * Patch to make <label>'s enable/disable along with their fields
 */
(function () {
    var oldAfterRndr, oldOnDisable, oldOnEnable;

    oldOnDisable = Ext.form.Field.prototype.onDisable;
    oldOnEnable  = Ext.form.Field.prototype.onEnable;
    oldAfterRndr = Ext.form.Field.prototype.afterRender;

    Ext.override(Ext.form.Field, {
        onDisable: function () {
            var c, label, up;
            // also disable any labels
            c = this.disabledClass;
            if (this.el && this.el.dom && this.el.dom.labels) {
                Ext.each(this.el.dom.labels, function (label) {
                    Ext.fly(label).addClass(c);
                });
            }
            else if (this.el && this.el.dom) {
                // look for label manually
                up = this.el.parent('.x-form-item');
                label = up ? up.first('label') : null;
                if (label) {
                    label.addClass(c);
                }
            }

            // call the original function
            oldOnDisable.apply(this, arguments);
        },
        onEnable: function () {
            var c, label, up;

            // enable the labels
            c = this.disabledClass;
            if (this.el && this.el.dom && this.el.dom.labels) {
                Ext.each(this.el.dom.labels, function (label) {
                    Ext.fly(label).removeClass(c);
                });
            }
            else if (this.el && this.el.dom) {
                // look for label manually
                up = this.el.parent('.x-form-item');
                label = up ? up.first('label') : null;
                if (label) {
                    label.removeClass(c);
                }
            }

            // call the original function
            oldOnEnable.apply(this, arguments);
        },
        afterRender: function () {
            if (this.labelTip && this.label) {
                var tip = 'ext:qtip="' + this.labelTip + '"';
                tip = ' <span class="air2-tipper" ' + tip;
                tip += ' hide="user" show="user">?</span>';
                this.label.update(this.fieldLabel + tip);
            }
            oldAfterRndr.apply(this, arguments);
        }
    });
})(); //execute immediately!


/*
 * Patch to allow a "box" shadow (expands only left, right, and bottom)
 */
Ext.override(Ext.menu.Menu, {
    shadow: 'air2box'
});
(function () {
    var offset, oldShow;

    oldShow = Ext.Shadow.prototype.show;
    offset = 8;

    Ext.override(Ext.Shadow, {
        show: function () {
            if (this.mode.toLowerCase() === 'air2box' && !this.adjusts.w) {
                this.adjusts.w = offset * 2;
                this.adjusts.l = -offset;
                this.adjusts.t = 0;
                this.adjusts.h = offset;

                // IE junk
                if (Ext.isIE) {
                    var rad = Math.floor(offset / 2);
                    this.adjusts.l -= (offset - rad);
                    this.adjusts.t -= offset + rad;
                    this.adjusts.l += 1;
                    this.adjusts.w -= (offset - rad) * 2;
                    this.adjusts.w -= rad + 1;
                    this.adjusts.h -= 1;
                }
            }
            oldShow.apply(this, arguments);

            if (this.mode.toLowerCase() === 'air2box' && this.el) {
                this.el.addClass('x-shadow-box');
            }
        }
    });
})(); //execute immediately!


/*
 * Hide tooltips on document scrolling
 */
(function () {
    var oldInit = Ext.ToolTip.prototype.initTarget;

    Ext.override(Ext.ToolTip, {
        initTarget : function (target) {
            var t = Ext.get(target);
            if (t) {
                if (this.target) {
                    this.mun(
                        Ext.get(this.target),
                        'scroll',
                        this.onTargetScroll,
                        this
                    );
                }
                this.mon(t, {scroll: this.onTargetScroll, scope: this});
            }
            oldInit.apply(this, arguments);
        },
        onTargetScroll: function (e) {
            this.clearTimer('show');
            this.hide(); //no delay
        }
    });
})(); //execute immediately!


/*
 * Hide menus on document scroll
 */
Ext.getDoc().on('scroll', function (ev, t, o) {
    Ext.menu.MenuMgr.hideAll();
});


/*
 * Fix textarea autosize when "display:none"
 */
Ext.override(Ext.form.TextArea, {
    autoSize: function () {
        var el, h, ts, v, width;

        if (!this.grow || !this.textSizeEl) {
            return;
        }
        el = this.el;
        v = Ext.util.Format.htmlEncode(el.dom.value);
        ts = this.textSizeEl;

        // must have valid width for this to work
        width = this.el.getWidth() ? this.el.getWidth() : this.width;
        if (!width) {
            return;
        }
        Ext.fly(ts).setWidth(width);
        if (v.length < 1) {
            v = "&#160;&#160;";
        } else {
            v += this.growAppend;
            if (Ext.isIE) {
                v = v.replace(/\n/g, '&#160;<br />');
            }
        }
        ts.innerHTML = v;
        h = Math.min(this.growMax, Math.max(ts.offsetHeight, this.growMin));
        if (h !== this.lastHeight) {
            this.lastHeight = h;
            this.el.setHeight(h);
            this.fireEvent("autosize", this, h);
        }
    }
});


/*
 * Steal the 3.4 Ext.form.BasicForm.findField to fix some bugs.
 */
Ext.override(Ext.form.BasicForm, {
    findField: function (id) {
        var field, findMatchingField;

        field = this.items.get(id);

        if (!Ext.isObject(field)) {
            findMatchingField = function (f) {
                if (f.isFormField) {
                    if (
                        f.dataIndex === id ||
                        f.id === id ||
                        f.getName() === id
                    ) {
                        field = f;
                        return false;
                    } else if (f.isComposite) {
                        return f.items.each(findMatchingField);
                    } else if (
                        f instanceof Ext.form.CheckboxGroup &&
                        f.rendered
                    ) {
                        return f.eachItem(findMatchingField);
                    }
                }
            };
            this.items.each(findMatchingField);
        }
        return field || null;
    }
});

/*
 * Allow force-writing record fields
 */
Ext.override(Ext.data.Record, {
    forceSet: function (fld, value) {
        this.fields.map[fld] = {name: fld};
        delete this.data[fld];
        this.set(fld, value);
    }
});


/*
 * Allow different sizes of Ext.MessageBoxes
 */
(function () {
    var oldShow, oldUpdateText, setH, setW;

    oldShow = Ext.MessageBox.show;
    oldUpdateText = Ext.MessageBox.updateText;

    // need to record some opts on show
    Ext.MessageBox.show = function (opt) {
        setH = opt.height;
        setW = opt.width;
        return oldShow.apply(this, arguments);
    };

    // set size and center
    Ext.MessageBox.updateText = function (txt) {
        var d, ret, sz;

        ret = oldUpdateText.apply(this, arguments);
        if (setH || setW) {
            d = Ext.MessageBox.getDialog();
            sz = d.getSize();
            sz.height = setH || sz.height;
            sz.width = setW || sz.width;
            d.setSize(sz).center();
        }
        return ret;
    };
})(); //execute immediately!


/*
 * Completely hijack QuickTips singleton
 * (have to duplicate all the code, because of the way it's scoped)
 */
Ext.QuickTips = (function () {
    var tip, disabled = false;
    return {
        init: function (autoRender) {
            if (!tip) {
                if (!Ext.isReady) {
                    Ext.onReady(function () {Ext.QuickTips.init(autoRender); });
                    return;
                }
                tip = new Ext.QuickTip({
                    elements: 'header,body',
                    disabled: disabled,
                    hideDelay: 0,
                    showDelay: 0,
                    frame: false,
                    floating: {
                        shadow: false,
                        shim: false,
                        useDisplay: true,
                        constrain: false
                    },
                    baseCls: 'air2-tip',
                    afterRender: function () {
                        Ext.QuickTip.superclass.afterRender.call(this);
                        this.down = this.el.createChild({
                            cls: 'arrow arrow-down'
                        });
                        this.up = this.el.createChild({cls: 'arrow arrow-up'});
                    },
                    showAt: function (xy) {
                        var offset, t, w, xyUnsafe;

                        t = this.activeTarget;

                        if (t) {
                            this.el.set({'class': 'air2-tip'}); //reset

                            // TODO: figure out a more graceful way to keep
                            // tips around while you're hovering over them
                            tip.autoHide = t.autoHide;

                            // tip classes - auto-smallify under 25 chars
                            if (!t.text || t.text.length < 25) {
                                t.cls = t.cls ? t.cls + ' small' : 'small';
                            }
                            this.el.addClass(t.cls);

                            // determine offset
                            offset = this.el.hasClass('small') ? 8 : 9;
                            if (t.align) {
                                offset += parseInt(t.align, 10);
                            }

                            // render so we can get the width
                            this.body.update(t.text);
                            Ext.QuickTip.superclass.showAt.call(
                                this,
                                [-1000, -1000]
                            );
                            w = this.getWidth();

                            // position above or below
                            if (this.el.hasClass('below')) {
                                xy = this.el.getAlignToXY(
                                    t.el,
                                    't-b?',
                                    [0, offset]
                                );
                                xyUnsafe = this.el.getAlignToXY(
                                    t.el,
                                    't-b',
                                    [0, offset]
                                );
                                if (xyUnsafe[1] !== xy[1]) {
                                    this.removeClass('below');
                                    xy = this.el.getAlignToXY(
                                        t.el,
                                        'b-t?',
                                        [0, -offset]
                                    );
                                }
                            }
                            else {
                                xy = this.el.getAlignToXY(
                                    t.el,
                                    'b-t?',
                                    [0, -offset]
                                );
                                xyUnsafe = this.el.getAlignToXY(
                                    t.el,
                                    'b-t',
                                    [0, -offset]
                                );
                                if (xyUnsafe[1] !== xy[1]) {
                                    this.addClass('below');
                                    xy = this.el.getAlignToXY(
                                        t.el,
                                        't-b?',
                                        [0, offset]
                                    );
                                }
                            }
                        }
                        Ext.QuickTip.superclass.showAt.call(this, xy);
                    },
                    // override mouse event handlers
                    initTarget: function (target) {
                        var t, tg;

                        t = Ext.get(target);
                        if (t) {
                            if (this.target) {
                                tg = Ext.get(this.target);
                                this.mun(tg, 'click', this.onTargetClick, this);
                            }
                            this.mon(t, 'click', this.onTargetClick, this);
                        }
                        return Ext.QuickTip.prototype.initTarget.call(
                            this,
                            target
                        );
                    },
                    onTargetOver: function (e) {
                        var t = e.getTarget('.air2-tipper');
                        if (t && t.getAttribute('show')) {
                            return;
                        }
                        Ext.QuickTip.prototype.onTargetOver.call(this, e);
                    },
                    onTargetOut: function (e) {
                        Ext.QuickTip.prototype.onTargetOut.call(this, e);
                    },
                    onTargetClick: function (e) {
                        var t = e.getTarget('.air2-tipper');
                        if (t && !t.getAttribute('show')) {
                            return;
                        }
                        Ext.QuickTip.prototype.onTargetOver.call(this, e);
                    }
                });
                if (autoRender !== false) {
                    tip.render(Ext.getBody());
                }
            }
        },
        ddDisable: function () {
            if (tip && !disabled) {
                tip.disable();
            }
        },
        ddEnable: function () {
            if (tip && !disabled) {
                tip.enable();
            }
        },
        enable: function () {
            if (tip) {
                tip.enable();
            }

            disabled = false;
        },
        disable: function () {
            if (tip) {
                tip.disable();
            }
            disabled = true;
        },
        isEnabled: function () {
            return tip !== undefined && !tip.disabled;
        },
        getQuickTip: function () {
            return tip;
        },
        register: function () {
            tip.register.apply(tip, arguments);
        },
        unregister: function () {
            tip.unregister.apply(tip, arguments);
        },
        tips: function () {
            tip.register.apply(tip, arguments);
        }
    };
}());


/*
 * Completely hijack xtemplate rendering to alias "air.something" to
 * AIR2.Format.something().  Lots of copied code here, but Ext just doesn't
 * give me a way to override part of it.
 */
(function () {
    Ext.XTemplate.prototype.compileTpl = function (tpl) {
        var fm = Ext.util.Format,
            air = AIR2.Format,
            useF = this.disableFormats !== true,
            sep = Ext.isGecko ? "+" : ",",
            body;

        function fn(m, name, format, args, math) {
            if (name.substr(0, 4) === 'xtpl') {
                return "'" + sep + 'this.applySubTemplate(' + name.substr(4) +
                ', values, parent, xindex, xcount)' + sep + "'";
            }
            var v;
            if (name === '.') {
                v = 'values';
            } else if (name === '#') {
                v = 'xindex';
            } else if (name.indexOf('.') !== -1) {
                v = name;
            } else {
                v = "values['" + name + "']";
            }
            if (math) {
                v = '(' + v + math + ')';
            }
            if (format && useF) {
                args = args ? ',' + args : "";
                /******************************************************
                 * THIS PART IS CHANGED! - RC
                 ******************************************************/
                if (format.substr(0, 5) === 'this.') {
                    format = 'this.call("' + format.substr(5) + '", ';
                    args = ", values";
                }
                else if (format.substr(0, 4) === "air.") {
                    format = 'air.' + format.substr(4) + '(';
                }
                else {
                    format = "fm." + format + '(';
                }
                /******************************************************
                 * END CHANGE
                 ******************************************************/
            } else {
                args = '';
                format = "(" + v + " === undefined ? '' : ";
            }
            return "'" + sep + format + v + args + ")" + sep + "'";
        }

        function codeFn(m, code) {
            // Single quotes get escaped when the template is compiled,
            // however we want to undo this when running code.
            return "'" + sep + '(' + code.replace(/\\'/g, "'") + ')' + sep +
                "'";
        }

        // branched to use + in gecko and [].join() in others
        if (Ext.isGecko) {
            body = 'tpl.compiled = function(values, parent, xindex, xcount){ ' +
            "return '" +
                   tpl.body.replace(
                        /(\r\n|\n)/g,
                        '\\n'
                    ).replace(
                        /'/g,
                        "\\'"
                    ).replace(
                        this.re,
                        fn
                    ).replace(
                        this.codeRe,
                        codeFn
                    ) + "';};";
        } else {
            body = ["tpl.compiled = function(values, parent, xindex, " +
                "xcount){ return ['"];
            body.push(
                tpl.body.replace(
                    /(\r\n|\n)/g,
                    '\\n'
                ).replace(
                    /'/g,
                    "\\'"
                ).replace(
                    this.re,
                    fn
                ).replace(
                    this.codeRe,
                    codeFn
                )
            );

            body.push("'].join('');};");
            body = body.join('');
        }
        //TODO see about making eval go away
        eval(body);
        return this;
    };

})(); //execute immediately!
