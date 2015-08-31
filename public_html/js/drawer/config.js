Ext.ns('AIR2.Drawer.Config');
/***************
 * AIR2 Drawer Config
 *
 * Configuration options for the AIR2 Drawer interface
 *
 */
AIR2.Drawer.Config.SORTFIELDS = {
    lg: [ // large list
        {text: 'Last Modified', fld: 'bin_upd_dtim'},
        {text: 'Name', fld: 'bin_name', flip: true},
        {text: 'Size', fld: 'src_count'},
        {text: 'Owner Name', fld: 'user_last_name', flip: true}
    ],
    si: { // single bin -- must also indicate bin_type
        S: [
            {text: 'Last', fld: 'src_last_name'}
            //{text: 'Email', fld: 'src_username', flip: true},
            //{text: 'Last Name', fld: 'src_last_name', flip: true},
            //{text: 'First Name', fld: 'src_first_name', flip: true},
            //{text: 'Join Date', fld: 'src_cre_dtim'}
        ],
        U: [
            {text: 'Last Name', fld: 'user_last_name', flip: true},
            {text: 'First Name', fld: 'user_first_name', flip: true}
        ]
    }
};
AIR2.Drawer.Config.FILTERS = {
    lg: [
        /*{text: 'Show Deleted', param: 'deleted', checked: false},*/
        /*{text: 'Show Archived', param: 'archived', checked: false},*/
        {text: 'Show only mine', param: 'owner_flag', checked: true}
        /*{text: 'Show Types', menu: {items: [
            {text: 'Source', typeCode: 'S', checked: true},
            {text: 'Project', typeCode: 'P', checked: true},
            {text: 'Organization', typeCode: 'O', checked: true},
            {text: 'User', typeCode: 'U', checked: true}
        ]}}*/
    ],
    sm: [

    ]
};
