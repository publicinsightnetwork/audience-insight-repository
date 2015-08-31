Ext.namespace('AIR2.Util.Tipper');

// cached Ext.Template
AIR2.Util.Tipper.tpl = false;

// some presets (loaded with the id-key)
AIR2.Util.Tipper.presets = {
    projects: {
        text: 'Projects control which organization(s) can view submissions to this query.'
    },
    orgs: {
        text: 'Organizations control which organization(s) sources are opted into ' +
            'when they respond to the query.'
    },
    authors: {
        text: 'Authors get byline credit (displayed on published query).'
    },
    watchers: {
        text: 'Watchers get notified whenever someone responds to the query.'
    },
    20825306: {
        text: 'Click here to discover what all the links on this page mean, ' +
            'and how to resize this page.',
        link: 'http://support.publicinsightnetwork.org/entries/20825306',
        linkText: 'Click here'
    },
    20164797: {
        text: 'Click here to discover how to create a new project for ' +
            'collaboration with another organization.',
        link: 'http://support.publicinsightnetwork.org/entries/20164797',
        linkText: 'Click here'
    },
    20502042: {
        text: 'Click here for an explanation of each AIR authorization role.',
        link: 'http://support.publicinsightnetwork.org/entries/20502042',
        linkText: 'Click here'
    },
    20978291: {
        text: 'Click here to learn all about search functionality in AIR - ' +
            'including filtering, refining, viewing, saving, and merging ' +
            'sources.',
        link: 'http://support.publicinsightnetwork.org/entries/20978291',
        linkText: 'Click here'
    },
    20978266: {
        text: 'Click here to learn how to create, work with, and export bins.',
        link: 'http://support.publicinsightnetwork.org/entries/20978266',
        linkText: 'Click here'
    },
    20998498: {
        text: 'Click here to learn about source statuses, source’s ' +
            'association with organizations, and how to deactivate a source.',
        link: 'http://support.publicinsightnetwork.org/entries/20998498',
        linkText: 'Click here'
    },
    20978401: {
        text: 'Click here to learn how to upload a CSV file, a group of ' +
            'emails, or how to make a bin from a CSV upload.',
        link: 'http://support.publicinsightnetwork.org/entries/20978401',
        linkText: 'Click here'
    },
    20162358: {
        text: 'Click here to learn how to merge two sources into one profile.',
        link: 'http://support.publicinsightnetwork.org/entries/20162358',
        linkText: 'Click here'
    },
    21998162: {
        text: 'Click here to learn about Submission permissions and ' +
            'authorization.',
        link: 'http://support.publicinsightnetwork.org/entries/21998162',
        linkText: 'Click here'
    },
    20164251: {
        text: 'Available sources include those with active status who have opted into your newsroom or the Global PIN',
        link: 'http://support.publicinsightnetwork.org/entries/20164251',
        linkText: 'Available sources'
    },
    92462006: {
        text: 'AIR shows all times in Central time, so this email will be sent out at the time you pick in your timezone, but AIR will always display the time in Central time.',
        link: 'http://support.publicinsightnetwork.org/entries/92462006-What-timezone-is-AIR-in',
        linkText: 'US Central'
    }
};

/*
 * Manufacture the markup for a tooltipper (the question mark that shows
 * a tooltip when you hover over it)
 *
 * @cfg int     id
 * @cfg string  text
 * @cfg string  link
 * @cfg string  linkText
 * @cfg string  cls
 * @cfg int     align
 * @cfg boolean autoHide
 *
 * @return string
 */
AIR2.Util.Tipper.create = function (cfg) {
    var a, hide, re, show, tip;

    if (Ext.isPrimitive(cfg)) {
        cfg = {id: cfg};
    }
    cfg = Ext.apply({}, cfg, {
        text: '',
        link: '',
        linkText: '',
        cls: '',
        align: 0,
        autoHide: false,
        autoShow: false
    });

    // copy values from presets
    if (cfg.id && AIR2.Util.Tipper.presets[cfg.id]) {
        Ext.apply(cfg, AIR2.Util.Tipper.presets[cfg.id]);
    }

    // template singleton
    if (!AIR2.Util.Tipper.tpl) {
        AIR2.Util.Tipper.tpl = new Ext.Template(
            '<span class="air2-tipper" ext:qtip="{0}" ext:qclass="{1}" ' +
                'ext:qalign="{2}" hide="{3}" show="{4}">?</span>'
        );
        AIR2.Util.Tipper.tpl.compile();
    }

    // put the link into the tip, and html-encode it
    tip = cfg.text;
    if (cfg.link) {
        a = '<a href="' + cfg.link + '" class="external" target="_blank">';
        a += (cfg.linkText || 'Click Here') + '</a>';

        if (cfg.linkText && tip) {
            re = new RegExp(cfg.linkText);
            tip = tip.replace(re, a);
            if (tip === cfg.text) {
                tip += a; //default to appending
            }
        }
        else {
            tip += a;
        }
    }
    tip = Ext.util.Format.htmlEncode(tip);
    hide = cfg.autoHide ? '' : 'user';
    show = cfg.autoShow ? '' : 'user';
    return AIR2.Util.Tipper.tpl.apply([tip, cfg.cls, cfg.align, hide, show]);
};
