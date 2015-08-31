Ext.ns('AIR2.Inquiry');
/***************
 * Inquiry page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */
AIR2.Inquiry = function () {
    var activeCard,
        cards,
        inqRadix,
        isAdmin,
        isManager,
        isOwner,
        isWriter,
        managerMayEdit,
        ownerMayEdit,
        tabs;
        
    // shortcut
    inqRadix = AIR2.Inquiry.BASE.radix;

    // create all our data stores
    AIR2.Inquiry.initStores();

    // create new project authz
    isAdmin = (AIR2.USERINFO.type === "S");
    isOwner = (AIR2.USERINFO.uuid === AIR2.User.UUID);
    isWriter = (AIR2.USERINFO.type === 'S') ? true : false;

    // MANAGER role in any organization? show the button
    isManager = AIR2.Util.Authz.has('ACTION_ORG_USR_UPDATE');

    // helper to determine if a user may edit
    managerMayEdit = function (org_uuid) {
        return AIR2.Util.Authz.has('ACTION_ORG_PRJ_INQ_UPDATE', org_uuid);
    };

    ownerMayEdit = function (org_uuid) {
        // TODO: explicit action for this case
        return isOwner && AIR2.Util.Authz.has(
            'ACTION_ORG_PRJ_BE_CONTACT',
            org_uuid
        );
    };

    // if not an admin, check for organization specific write access
    if (!isWriter) {
        AIR2.Inquiry.orgStore.each(function (orgRecord) {
            var orgUuid;
            orgUuid = orgRecord.get('org_uuid');

            if (AIR2.Util.Authz.has('ACTION_ORG_PRJ_INQ_UPDATE', orgUuid)) {
                isWriter = true;
            }
        });
    }

    AIR2.Inquiry.authzOpts = {
        mayManage: managerMayEdit,
        isOwner: isOwner,
        isWriter: isWriter,
        isAdmin: isAdmin,
        ownerMayEdit: ownerMayEdit
    };

    AIR2.Inquiry.EDITABLECOMPONENTS = [];

    // setup tab content
    cards = [AIR2.Inquiry.Overview()];

    if (isWriter || isAdmin || isOwner) {
        cards.push(AIR2.Inquiry.Edit());
    }

    cards.push(
        AIR2.Inquiry.PublishPreview(),
        AIR2.Inquiry.Outcomes(),
        AIR2.Inquiry.Annotations()
    );

    tabs = [];

    // build the tab buttons
    Ext.each(cards, function (card, index) {
        var tab, tabText;

        tabText = card.title

        if (card.airTotal) {
            tabText += ' <span id="air2-inquiry-tab-count-' +
                index + '">(' + card.airTotal + ')</span>';
        }

        tab = {
            air2size: 'SMALL',
            air2type: 'FRIENDLY',
            cls: 'air2-inquiry-tab-button',
            handler: function (button, event) {
                AIR2.Inquiry.Cards.setActiveCard(index);

                //clear active tab
                AIR2.Inquiry.Tabs.items.each(function (tab, index, total) {
                    var tabCard;

                    tabCard = AIR2.Inquiry.Cards.items.itemAt(index);

                    if (tabCard.airTotal) {
                        tab.updateTabTotal(tab, tabCard.airTotal);
                    }
                    else {
                        tab.setText(tabCard.title);
                    }

                    tab.removeClass('active-tab');


                    tab.resumeEvents();
                });
                //set this as the active tab
                button.addClass('active-tab');
                button.suspendEvents();
            },
            updateTabTotal: function (tab, total) {
                var tabIndex, tabCard, tabText;
                tabIndex = AIR2.Inquiry.Tabs.items.indexOf(tab);
                tabCard = AIR2.Inquiry.Cards.items.itemAt(tabIndex);
                tabText = tabCard.title;

                tabCard.airTotal = total;

                tabText += ' <span id="air2-inquiry-tab-count-' +
                    tabIndex + '">(' + total + ')</span>';

                tab.setText(tabText);
            },
            text: tabText,
            tooltip: card.tabTip || '',
            width: 100,
            xtype: 'air2button'
        };

        tabs[index] = tab;
    });

    AIR2.Inquiry.Tabs = new Ext.Panel({
        autoHeight: true,
        id: 'air2-inquiry-tabs',
        items: tabs,
        layout: 'column',
        width: 100,
        unstyled: true
    });

    //start with overview
    activeCard = 0;

    //if stale or not published (and we have edit perms), load edit tab
    if (isWriter) {
        if (inqRadix.inq_status == 'D' || inqRadix.inq_stale_flag) {
            activeCard = 1;
        }
    }

    AIR2.Inquiry.Tabs.on('afterrender', function () {
        var activeTab = AIR2.Inquiry.Tabs.items.get(activeCard);
        activeTab.addClass('active-tab');
        activeTab.suspendEvents();
    });

    AIR2.Inquiry.Cards = new Ext.Panel({
        activeItem: activeCard,
        autoHeight: true,
        defaults: {
            // applied to each contained panel
            border: false,
            layoutOnCardChange: true
        },
        flex: 1,
        items: cards,
        layout: 'card',
        layoutOnCardChange: true,
        setActiveCard: function (itemIndex) {
            var layout;

            layout = this.getLayout();
            layout.setActiveItem(itemIndex);

            if (AIR2.APP) {
                AIR2.APP.syncSize();
            }
        },
        unstyled: true
    });

    /* create the application */
    AIR2.APP = new AIR2.UI.App({
        autoHeight: true,
        id: 'air2-app',
        items: [
            AIR2.Inquiry.Tabs,
            AIR2.Inquiry.Cards
        ],
        layout: 'hbox',
        listeners: {
            'afterrender': function () {
                this.doLayout();
            }
        }
    });

    AIR2.APP.setLocation({
        iconCls: 'air2-icon-inquiry',
        type: 'Query',
        typeLink: AIR2.HOMEURL + '/search/queries',
        title: AIR2.Inquiry.BASE.radix.inq_ext_title
    });

};

// util methods
AIR2.Inquiry.uriForQuery = function(inq) {
    var locale = 'en';
    if (inq.Locale && inq.Locale.loc_key) {
        locale = inq.Locale.loc_key.replace(/_US$/, '');
    }
    return AIR2.MYPIN2_URL + '/' + locale + '/insight/' + inq.inq_uuid + '/' + AIR2.Format.urlify(inq.inq_ext_title);
}

// CONSTANTS
AIR2.Inquiry.STATUS_ACTIVE    = 'A';
AIR2.Inquiry.STATUS_DEADLINE  = 'L';
AIR2.Inquiry.STATUS_EXPIRED   = 'E';
AIR2.Inquiry.STATUS_DRAFT     = 'D';
AIR2.Inquiry.STATUS_INACTIVE  = 'F';
AIR2.Inquiry.STATUS_SCHEDULED = 'S';

AIR2.Inquiry.PUBLISHED_STATUS_FLAGS = [
    AIR2.Inquiry.STATUS_ACTIVE,
    AIR2.Inquiry.STATUS_DEADLINE
];

//Inquiry question types which have choices (selects etc)
AIR2.Inquiry.MULTIPLE_CHOICE_TYPE_QUESTIONS = [
    'C',
    'L',
    'R',
    'O',
    'M',
    'Y',
    'S',
    'P'
];

// maps to 'ques_type' field in a question record in
// AIR2.Inquiry.quesStore
AIR2.Inquiry.QUESTION                     = {};
AIR2.Inquiry.QUESTION.TYPE                = {};
AIR2.Inquiry.QUESTION.TYPE.SELECT         = ['O'];
AIR2.Inquiry.QUESTION.TYPE.RADIO          = ['R'];
AIR2.Inquiry.QUESTION.TYPE.CHECKBOX       = ['C'];
AIR2.Inquiry.QUESTION.TYPE.MULTI_SELECT   = ['L'];
AIR2.Inquiry.QUESTION.TYPE.COUNTRY_SELECT = ['Y'];
AIR2.Inquiry.QUESTION.TYPE.STATE_SELECT   = ['S'];
AIR2.Inquiry.QUESTION.TYPE.PERMISSION     = ['p', 'P'];
AIR2.Inquiry.QUESTION.TYPE.CONTACT        = ['Z', 'Y', 'S'];
AIR2.Inquiry.QUESTION.TYPE.TEXT           = ['T'];
AIR2.Inquiry.QUESTION.TYPE.TEXTAREA       = ['A'];
AIR2.Inquiry.QUESTION.TYPE.FILE           = ['F'];
AIR2.Inquiry.QUESTION.TYPE.DATE           = ['D'];
AIR2.Inquiry.QUESTION.TYPE.BREAK          = ['2'];
AIR2.Inquiry.QUESTION.TYPE.DISPLAY        = ['3'];
AIR2.Inquiry.QUESTION.TYPE.PAGEBREAK      = ['4'];


AIR2.Inquiry.QUESTION.DIRECTION            = {};
AIR2.Inquiry.QUESTION.DIRECTION.VERTICAL   = 'V';
AIR2.Inquiry.QUESTION.DIRECTION.HORIZONTAL = 'H';


AIR2.Inquiry.QUESTION.REQUIRED = ['firstname', 'lastname', 'email', 'zip'];

AIR2.Inquiry.QuestionCSS = {width: '540px'};

