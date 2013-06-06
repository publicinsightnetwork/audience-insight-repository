/**********************
 * Source Contact Panel
 */
AIR2.Source.Contact = function () {
    var getChannel,
        getStatus,
        oldTitle,
        pnl,
        template,
        tip,
        tipLight,
        titleLock;


    getStatus = function (sourceObj) {
        var c, cNice, srcStatus;

        srcStatus = 'Inactive';
        c = sourceObj.src_status;

        if (c === 'A' || c === 'E' || c === 'T') {
            //only engaged/enrolled/unverified status show "Active"
            srcStatus = 'Active';
        }

        // get text from fixture
        cNice = AIR2.Format.codeMaster('src_status', c);
        return '<span class="air2-source-contact-' + srcStatus + '-status">' +
            srcStatus + ' - ' + cNice + ' (' + c + ')</span>';
    };
    getChannel = function (sourceObj) {
        return AIR2.Format.codeMaster('src_channel', sourceObj.src_channel);
    };

    // support article
    tip = AIR2.Util.Tipper.create(20998498);
    tipLight = AIR2.Util.Tipper.create({
        id: 20998498,
        cls: 'lighter',
        align: 15
    });

    // include account-lock in title
    titleLock = AIR2.Source.LOCK ? ('&nbsp;' + AIR2.Source.LOCK) : '';

    template = new Ext.XTemplate(
        '<tpl for="."><div class="air2-source-contact">' +
          '<div class="photo">' +
            '<img src="{AIR2.HOMEURL}/css/img/not_found.jpg">' +
          '</div>' +
          '<ul class="address">' +
            '<li>' +
              '<div class="label">Address 1</div>' +
              '<div class="value">{[this.add1(values)]}</div>' +
            '</li>' +
            '<li>' +
              '<div class="label">Address 2</div>' +
              '<div class="value">{[this.add2(values)]}</div>' +
            '</li>' +
            '<li class="clearfix">' +
              '<div class="label">City, State, Postal Code</div>' +
              '<div class="value">{[this.add3(values)]}</div>' +
            '</li>' +
            '<li>' +
              '<div class="label">Country</div>' +
              '<div class="value">{[this.add4(values)]}</div>' +
            '</li>' +
          '</ul>' +
          '<ul class="other">' +
            '<li>' +
              '<div class="label">Phone</div>' +
              '<div class="value" style="display:inline-block">' +
                '{[this.formatPhones(values)]}</div>' +
            '</li>' +
            '<li>' +
              '<div class="label">Email*</div>' +
              '<div class="value">{[this.emAddress(values)]}</div>' +
            '</li>' +
            '<li>' +
              '<div class="label">Status</div>' +
              '<div class="value">{[this.srcStatus(values)]}</div>' +
            '</li>' +
            '<li>'  +
              '<div class="label">Alias</div>' +
              '<div class="value" style="display:inline-block">{[this.formatAliases(values)]}</div>' +
            '</li>' +
            '<tpl if="src_has_acct==\'Y\'">' +
              '<li>' +
                '<div class="label">Account</div>' +
                '<div class="value">' +
                 '<a href="' + AIR2.MYPIN2_URL +
                    '/en/admin/index?filter={src_username}">' +
                    '<b>SOURCE&#8482;</b>' +
                 '</a>' +
                '</div>' +
              '</li>' +
            '</tpl>' +
          '</ul>' +
        '</div></tpl>',
        {
            compiled: true,
            disableFormats: true,
            getFirst: function (values, str) {
                if (values[str] && values[str].length) {
                    return values[str][0];
                }
                return false;
            },
            add1: function (values) {
                var add = this.getFirst(values, 'SrcMailAddress');
                if (add.smadd_line_1) {
                    return add.smadd_line_1;
                }
                return '<span class="none">none</span>';
            },
            add2: function (values) {
                var add = this.getFirst(values, 'SrcMailAddress');
                if (add.smadd_line_2) {
                    return add.smadd_line_2;
                }
                return '<span class="none">none</span>';
            },
            add3: function (values) {
                var add, str;

                add = this.getFirst(values, 'SrcMailAddress');
                if (add.smadd_city || add.smadd_state || add.smadd_zip) {
                    str = '';
                    if (add.smadd_city) {
                        str += add.smadd_city;
                    }
                    if (add.smadd_state) {
                        if (str.length) {
                            str += ', ' + add.smadd_state;
                        }
                        else {
                            str += add.smadd_state;
                        }
                    }
                    if (add.smadd_zip) {
                        if (str.length) {
                            str += ', ' + add.smadd_zip;
                        }
                        else {
                            str += add.smadd_zip;
                        }
                    }
                    return str;
                }
                return '<span class="none">none</span>';
            },
            add4: function (values) {
                var add = this.getFirst(values, 'SrcMailAddress');
                if (add.smadd_cntry) {
                    return add.smadd_cntry;
                }
                return '<span class="none">none</span>';
            },
            orderPhones: function (phones) {
                var context, ordered;

                ordered = [];
                context = {};

                // primary first
                Ext.each(phones, function (item) {
                    if (item.sph_primary_flag) {
                        ordered.push(item);
                        context[item.sph_context] = item;
                    }
                });

                // add one of each context
                Ext.each(phones, function (item) {
                    var c = item.sph_context;
                    if (!c) {
                        return;
                    }

                    if (!context[c]) {
                        ordered.push(item);
                        context[c] = item;
                    }
                });

                // still nothing?  add anything!
                if (ordered.length === 0 && phones.length > 0) {
                    ordered.push(phones[0]);
                }
                return ordered;
            },
            formatPhones: function (values) {
                var phones, str, txt, more;

                if (values.SrcPhoneNumber && values.SrcPhoneNumber.length) {
                    phones = this.orderPhones(values.SrcPhoneNumber);
                    str = '';
                    more = values.SrcPhoneNumber.length - 1;
                    Ext.each(phones, function (item, index) {
                        if (item.sph_primary_flag) {
                            str += AIR2.Format.formatPhone(item.sph_number);
                            if (item.sph_context) {
                                txt = AIR2.Format.codeMaster(
                                    'sph_context',
                                    item.sph_context
                                );
                                str += txt ? ' ' : '';
                                
                            }
                            str += '<span class="lighter';
                            if (item.sph_primary_flag) {
                                str += ' primary" ext:qtip="Primary"> ';
                            }
                            else {
                                str += '">';
                            }

                            str += (txt ? txt : ' ') + '</span>';
                            if(more > 0) {
                                str += '</br><a class="more_phone"><span>+ '+more+' more</span></a>'
                            }
                            
                        }
                    });
                    return str;
                }
                else {
                    return '<span class="lighter">(none)</span>';
                }
            },
            formatAliases: function (values) {
                var aliases, str, txt;
                if (values.SrcAlias && values.SrcAlias.length) {
                    aliases = values.SrcAlias;
                    str = '';
                    Ext.each(aliases, function(item, index) {
                        str += (index !== 0) ? '<br/>' : '';
                        if (item.sa_first_name) {
                            str += item.sa_first_name;
                            str += ' <span class="lighter" ext:qtip="First Name">First Name</span>';
                        }
                        else {
                            str += item.sa_last_name;
                            str += ' <span class="lighter" ext:qtip="Last Name">Last Name</span>';
                        }
                    });
                    return str;
                } else { 
                    return '<span class="lighter">(none)</span>';
                } 
            },
            emAddress: function (values) {
                var em = this.getFirst(values, 'SrcEmail');
                if (em.sem_email) {
                    return AIR2.Format.sourceEmail(em, true);
                }
                return '<span class="none">none</span>';
            },
            srcStatus: getStatus,
            srcChannel: getChannel
        }
    );

    pnl = new AIR2.UI.Panel({
        colspan: 2,
        title: AIR2.Format.sourceTitledName(AIR2.Source.BASE.radix) +
            titleLock + ' ' + tip,
        iconCls: 'air2-icon-contactmethod',
        cls: 'air2-src-contact-panel',
        storeData: AIR2.Source.BASE,
        url: AIR2.Source.URL,
        itemSelector: '.air2-source-contact',
        tpl: template,
        editModal: {
            title: 'Contact Info' + titleLock + tipLight,
            width: 650,
            allowAdd: false,
            tabLayout: true,
            showTotal: false,
            items: {
                xtype: 'tabpanel',
                plain: true,
                activeTab: 0,
                items: [
                    {
                        title: 'Source Info',
                        xtype: 'air2srcconinfo'
                    },
                    AIR2.Source.Contact.Alias(),
                    AIR2.Source.Contact.Email(),
                    AIR2.Source.Contact.Phone(),
                    AIR2.Source.Contact.Address()
                ],
                listeners: {
                    tabchange: function (tabpnl, tab) {
                        var pgr = tabpnl.getBottomToolbar();
                        if (tab.title === 'Source Info') {
                            pgr.hide();
                            tab.setSrcRecord(pnl.store.getAt(0)); //load
                        }
                        else {
                            // unbind listeners, but DON'T destroy old store
                            if (pgr.store) {
                                pgr.store.un(
                                    'beforeload',
                                    pgr.beforeLoad,
                                    this
                                );
                                pgr.store.un(
                                    'load',
                                    pgr.onLoad,
                                    this
                                );
                                pgr.store.un(
                                    'exception',
                                    pgr.onLoadError,
                                    this
                                );
                            }
                            pgr.bindStore(tab.store, true);
                            pgr.show();
                        }
                    }
                }
            },
            listeners: {
                beforehide: function (w) {
                    w.initialConfig.items.activeTab = 0;
                    w.get(0).fireEvent('beforehide');
                }
            }
        }
    });

    // update title/location on a name change
    oldTitle = AIR2.Format.sourceTitledName(AIR2.Source.BASE.radix);
    pnl.store.on('save', function (s) {
        var newTitle, rec, titleEl;

        titleEl = pnl.getHeader().el.child('.header-title');
        rec = s.getAt(0);
        newTitle = AIR2.Format.sourceTitledName(rec.data);
        if (oldTitle !== newTitle) {
            oldTitle = newTitle;
            titleEl.update(newTitle);
            Ext.getCmp('air2-app').setLocation({title: newTitle});
        }
    });

    pnl.getDataView().on('afterrefresh', function(p) {
        var phone_link = Ext.get(Ext.select('.more_phone').elements[0]);
        if (!phone_link) {
            return;
        }
        phone_link.on('click', function (l) {
            if (pnl.editModal.rendered) {
                pnl.editModal.initialConfig.items.activeTab = 3;
            }
            else {
                pnl.editModal.items.activeTab = 3;
            }
            pnl.startEditModal(false);
        });
    });

    return pnl;
};
