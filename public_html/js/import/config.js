Ext.ns('AIR2.Import.CONFIG');
/***************
 * Configuration for how the whole "CONFLICT RESOLVER" will look.
 *
 * SECTION KEYS:
 * @key section {String} - title of the section
 * @key display {Boolean|Function} - decides if the section should be shown
 * @key items   {Array} - rows within the section
 *
 * ITEM ROW KEYS
 * @key key     {String} - field-name/conflict-key
 * @key label   {String} - field-label
 * @key display {Boolean|Function} - show/hide field
 * @key oldval  {Function} - custom old-value finder
 * @key newval  {Function} - custom new-value finder
 * @key format  {Function} - custom formatting of value
 *
 */
AIR2.Import.CONFIG = [{
    section: 'Profile',
    display: true, //always
    items: [{
        key: 'src_username',
        label: 'Username',
        display: true,
        oldval: function(tsrc, conflicts) {
            if (tsrc.Source) {
                var n = '<a target="_blank" class="external" href="';
                n += AIR2.HOMEURL+'/source/'+tsrc.Source.src_uuid+'">';
                n += tsrc.Source.src_username+'</a>';
                return n;
            }
            return '<span class="lighter">(DNE)</span>';
        }
    },{
        key: 'src_first_name',
        label: 'First Name',
        display: true //always
    },{
        key: 'src_last_name',
        label: 'Last Name',
        display: true //always
    },{
        key: 'src_middle_initial',
        label: 'Middle'
    },{
        key: 'src_pre_name',
        label: 'Pre Name'
    },{
        key: 'src_post_name',
        label: 'Post Name'
    },{
        key: 'src_channel',
        label: 'Channel'
    }]
},{
    section: 'Email',
    items: [{
        key: 'sem_primary_flag',
        label: 'Primary',
        display: true,
        format: function(val) {
            return val ? AIR2.Format.bool(val) : '';
        }
    },{
        key: 'sem_context',
        label: 'Type',
        display: true,
        format: function(val) {
            return AIR2.Format.codeMaster('sem_context', val);
        }
    },{
        key: 'sem_email',
        label: 'Email',
        display: true
    },{
        key: 'sem_effective_date',
        label: 'From'
    },{
        key: 'sem_expire_date',
        label: 'Until'
    }]
},{
    section: 'Phone',
    items: [{
        key: 'sph_primary_flag',
        label: 'Primary',
        display: true,
        format: function(val) {
            return val ? AIR2.Format.bool(val) : '';
        }
    },{
        key: 'sph_context',
        label: 'Type',
        display: true,
        format: function(val) {
            return AIR2.Format.codeMaster('sph_context', val);
        }
    },{
        key: 'sph_country',
        label: 'Country'
    },{
        key: 'sph_number',
        label: 'Country',
        display: true
    },{
        key: 'sph_ext',
        label: 'Extension'
    }]
},{
    section: 'Address',
    items: [{
        key: 'smadd_primary_flag',
        label: 'Primary',
        display: true,
        format: function(val) {
            return val ? AIR2.Format.bool(val) : '';
        }
    },{
        key: 'smadd_context',
        label: 'Type',
        display: true,
        format: function(val) {
            return AIR2.Format.codeMaster('smadd_context', val);
        }
    },{
        key: 'smadd_line_1',
        label: 'Address 1',
        display: true
    },{
        key: 'smadd_line_2',
        label: 'Address 2',
        display: true
    },{
        key: 'smadd_city',
        label: 'City',
        display: true
    },{
        key: 'smadd_state',
        label: 'State',
        display: true
    },{
        key: 'smadd_cntry',
        label: 'Country',
        display: true
    },{
        key: 'smadd_zip',
        label: 'Postal Code',
        display: true
    },{
        key: 'smadd_lat',
        label: 'Latitude'
    },{
        key: 'smadd_long',
        label: 'Longitude'
    }]
},{
    section: 'Gender',
    items: [{
        key: 'gender.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'gender.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    },{
        key: 'gender.sf_src_value',
        label: 'Source Text',
        display: true
    }]
},{
    section: 'Household Income',
    items: [{
        key: 'household_income.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'household_income.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    }]
},{
    section: 'Education Level',
    items: [{
        key: 'education_level.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'education_level.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    }]
},{
    section: 'Political Affiliation',
    items: [{
        key: 'political_affiliation.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'political_affiliation.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    }]
},{
    section: 'Ethnicity',
    items: [{
        key: 'ethnicity.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'ethnicity.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    },{
        key: 'ethnicity.sf_src_value',
        label: 'Source Text',
        display: true
    }]
},{
    section: 'Religion',
    items: [{
        key: 'religion.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'religion.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    },{
        key: 'religion.sf_src_value',
        label: 'Source Text',
        display: true
    }]
},{
    section: 'Birth Year',
    items: [{
        key: 'birth_year.sf_src_value',
        label: 'Source Text',
        display: true
    }]
},{
    section: 'Source Website',
    items: [{
        key: 'source_website.sf_src_value',
        label: 'Source Text',
        display: true
    }]
},{
    section: 'Lifecycle',
    items: [{
        key: 'lifecycle.sf_fv_id',
        label: 'Analyst Mapped',
        display: true
    },{
        key: 'lifecycle.sf_src_fv_id',
        label: 'Source Mapped',
        display: true
    }]
},{
    section: 'Timezone',
    items: [{
        key: 'timezone.sf_src_value',
        label: 'Source Text',
        display: true
    }]
}];