/***************
 * Submission Source Panel
 */
AIR2.Submission.Source = function () {
    var lnk, p, srcLink, srcName, template;

    srcLink = AIR2.HOMEURL + '/source/';
    srcLink += AIR2.Submission.SRCDATA.radix.src_uuid;
    srcName = AIR2.Submission.SRCDATA.radix;
    srcName = AIR2.Format.sourceFullName(srcName);

    template = new Ext.XTemplate(
        '<tpl for="."><div class="subm-source">' +
          '<table class="air2-tbl">' +
            // empty header
            '<tr>' +
              '<th class="fixw"><span></span></th>' +
              '<th><span></span></th>' +
            '</tr>' +
            // email
            '<tpl for="SrcEmail">' +
              '<tr>' +
                '<td class="date right">Email</td>' +
                '<td>{[this.sourceEmail(values)]}</td>' +
              '</tr>' +
            '</tpl>' +
            // phone
            '<tpl for="SrcPhoneNumber">' +
              '<tr>' +
                '<td class="date right">Phone</td>' +
                '<td>{[AIR2.Format.sourcePhone(values)]}</td>' +
              '</tr>' +
            '</tpl>' +
            // address
            '<tpl for="SrcMailAddress">' +
              '<tr>' +
                '<td class="date right">Location</td>' +
                '<td>{[AIR2.Format.sourceMailShort(values)]}</td>' +
              '</tr>' +
            '</tpl>' +
            // anything else!
            '{[this.formatOther(values)]}' +
          '</ul>' +
        '</div></tpl>',
        {
            compiled: true,
            disableFormats: true,
            sourceEmail: function (v) {
                return AIR2.Format.mailTo(v.sem_email, AIR2.Submission.SRCDATA.radix);
            },
            formatOther: function (v) {
                var bas,
                    count,
                    i,
                    maxOther,
                    sf,
                    str,
                    sv,
                    val;

                str = '';
                count = 0;

                // format vita experience
                for (i = 0; i < v.SrcVita.length; i++) {
                    sv = v.SrcVita[i];

                    // label
                    str += '<tr><td class="date right">';
                    str += sv.sv_type === 'I' ? 'Interest' : 'Experience';
                    str += '</td>';

                    // value
                    val = (sv.sv_value) ? sv.sv_value : '';
                    bas = (sv.sv_basis) ? sv.sv_basis : '';
                    if (val.length > 0 && bas.length > 0) {
                        str += '<td>' + val + ' - ' + bas + '</td>';
                    }
                    else {
                        str += '<td>' + val + bas + '</td>';
                    }
                    str += '</tr>';
                }

                // format facts
                    for (
                        i = 0;
                        i < v.SrcFact.length;
                        i++
                    ) {
                    sf = v.SrcFact[i];
                    str += '<tr><td class="date right">';
                    if (sf.Fact.fact_identifier == 'birth_year') {
                        str += 'Age </td>';
                    }
                    else {
                        str += sf.Fact.fact_name + '</td>';
                    }
                    val = sf.sf_src_value;

                    if (sf.AnalystFV) {
                        val = sf.AnalystFV.fv_value;
                    }
                    else if (sf.SourceFV) {
                        val = sf.SourceFV.fv_value;
                    }

                    if (sf.Fact.fact_identifier == 'household_income') {
                        val = AIR2.Format.householdIncome(val);
                    }
                    if (sf.Fact.fact_identifier == 'birth_year') {
                        if (dob = parseInt(val)) {
                            src = 'Age';
                            dob = (new Date()).getFullYear() - dob;
                            val = '' + dob + ' years old';
                        }
                        else {
                            val = 'Born ' + val;
                        }
                    }
                    str += '<td>' + val + '</td></tr>';
                }

                return str;
            }
        }
    );

    p = new AIR2.UI.Panel({
        colspan: 1,
        title: srcName,
        iconCls: 'air2-icon-source',
        storeData: AIR2.Submission.SRCDATA,
        url: AIR2.HOMEURL + '/' + AIR2.Submission.SRCDATA.path,
        itemSelector: '.subm-source',
        tpl: template
    });

    // link to source profile
    if (AIR2.Submission.SRCDATA.authz.may_read) {
        lnk = '<a href="' + srcLink + '">View Profile&nbsp;&#187;</a>';
        p.setCustomTotal(lnk);
    }
    return p;
};
