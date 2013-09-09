Ext.ns('AIR2.Email');
/***************
 * Email "mailto" shortcut
 *
 * An easy onclick listener to open up an email-sending modal.
 *
 * @function AIR2.Email.Mailto
 * @el       {HTMLElement}   the element to animate from
 * @src_uuid {String}        uuid of the source to send email to
 * @fullname {String}        human readable name for the source
 *
 */
AIR2.Email.Mailto = function (el, src_uuid, fullname) {
    AIR2.Email.Sender({
        originEl: el,
        title: 'Mailto ' + fullname,
        src_uuid: src_uuid,
        internal_name: 'Mailto: ' + fullname,
        type: 'O',
        subject_line: ''
    });

    return false; // cancel default mailto action
}
