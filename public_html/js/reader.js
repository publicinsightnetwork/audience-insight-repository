Ext.ns('AIR2.Reader');
/***************
 * Submissions Reader page
 *
 * NOTE: can only be called from within an Ext.onReady()
 */

AIR2.Reader = function () {

    // create the application
    AIR2.APP = new AIR2.UI.App({
        cls: 'air2-reader-app',
        items: new AIR2.UI.PanelGrid({
            columnLayout: '3',
            items: AIR2.Reader.Inbox()
        })
    });
    AIR2.APP.hideLocation();

    // fire the expand listener if the URL param is present
    if (window.location.search.match(/\bexp=1/)) {
        //Logger('found exp=1 in url');
        AIR2.Reader.expandAll();
    }

};

// constants used for Publishing API
AIR2.Reader.CONSTANTS = {};
AIR2.Reader.CONSTANTS.PUBLISHABLE         = 1;
AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH  = 2;
AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE = 3;
AIR2.Reader.CONSTANTS.PUBLISHED           = 4;
AIR2.Reader.CONSTANTS.UNPUBLISHABLE       = 5;

AIR2.Reader.CONSTANTS.PUBLISHABLE_TITLE         =
    "Unpublished: Click to publish this submission.";
AIR2.Reader.CONSTANTS.NOTHING_TO_PUBLISH_TITLE  =
    "Nothing to Publish: This submission cannot be published because there " +
    "is nothing to approve. Please select responses to include.";
AIR2.Reader.CONSTANTS.UNPUBLISHED_PRIVATE_TITLE =
    "Private: Source has not given permission to publish this submission. If " +
    "you've received permission, click to override.";
AIR2.Reader.CONSTANTS.PUBLISHED_TITLE           =
    "Published: Click to unpublish this submission.";
AIR2.Reader.CONSTANTS.UNPUBLISHABLE_TITLE       =
    "Unpublishable: This submission cannot be published because there are no " +
    "publishable questions.";
