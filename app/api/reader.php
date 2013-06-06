<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

require_once 'rframe/AIRAPI_ArrayResource.php';

/**
 * Submission Reader API.
 *
 * Note: Using AIRAPI_ArrayResource instead of AIRAPI_Resource, because 
 * hydrating a Doctrine_Record takes a long time.
 */
class AAPI_Reader extends AIRAPI_ArrayResource {

    // API definitions.
    // protected $ALLOWED = array('query', 'fetch');
    protected $ALLOWED = array('query', 'fetch');
    // protected $QUERY_ARGS  = array('inq_uuid', 'type', 'filter');
    protected $QUERY_ARGS = array('inq_uuid');

    // Default paging/sorting.
    protected $query_args_default = array('type' => 'F'); //default to only FORMBUILDER submissions
    protected $sort_default   = 'srs_date desc';
    protected $sort_valids    = array(
        'srs_date',
        // 'srs_cre_dtim', 'srs_upd_dtim',
        // 'src_last_name', 'src_first_name',
        // 'smadd_zip', 'smadd_state', 'smadd_city',
    );

    // Metadata.
    protected $ident = 'inq_uuid';
    protected $fields = array(
        // 'DEF::INQUIRY',
        
        'DEF::SrcResponseSet',
        
        // 'SrcResponseSet'    => array(
        //     'DEF::SRCRESPONSESET',
        //     
        //     'Source'        => 'DEF::SOURCE',
        //     'SrcResponse'   => 'DEF::SRCRESPONSE',
        // ),
    );

    /**
     * Fetch function.
     *
     * @param   string      $uuid
     * @param   boolean     $minimal (optional) Default false.
     * @return  array
     **/
    protected function air_fetch__NO_AUTHZ($uuid, $minimal=false) {
        $q = Doctrine_Query::create()->from('Inquiry i');
        $q->innerJoin('i.SrcResponseSet isrs');
        $q->innerJoin('isrs.Source isrss');
        $q->innerJoin('isrs.SrcResponse isrssr');
        
        $q->innerJoin('i.ProjectInquiry ipi');
        $q->innerJoin('ipi.Project ipip');
        $q->innerJoin('ipip.ProjectOrg ipippo');
        $q->innerJoin('ipippo.Organization ipippoo');
        
        $q->addWhere('i.inq_uuid = ?', $uuid);
        
        return $q->fetchOne();
        
        // $data = $q->fetchArray();
        // $data = $data[0];
        // 
        // return $data;
    }

    /**
     * Query. Return SrcResponseSets
     *
     * @param   array   $args
     * @return  array
     **/
    protected function rec_query($args=array()) {
        if (!isset($args['inq_uuid'])) {
            die('No inquiry UUID specified.');
        }
        
        $q = Doctrine_Query::create()->from('SrcResponseSet a');
        // $q->addWhere('')
        
        return $q->fetchArray();
    }

    /*
    protected $ident = 'srs_uuid';
    protected $fields = array(
        'srs_uuid',
        'srs_date',
        'srs_uri',
        'srs_type',
        'srs_public_flag',
        'srs_delete_flag',
        'srs_translated_flag',
        'srs_export_flag',
        'srs_conf_level',
        'srs_cre_dtim',
        'srs_upd_dtim',
        // flattened inquiry
        'inq_uuid',
        'inq_title',
        'inq_ext_title',
        'inq_publish_dtim',
        'inq_deadline_dtim',
        'inq_desc',
        'inq_type',
        'inq_status',
        // flattened source
        'src_uuid',
        'src_username',
        'src_first_name',
        'src_last_name',
        'src_middle_initial',
        'src_pre_name',
        'src_post_name',
        'src_status',
        'src_has_acct',
        'src_channel',

        'smadd_city',
        'smadd_state',
        'smadd_zip',

        'CreUser' => array('UserOrg'),

        // responses (only included in fetch-single)
        'SrcResponse' => array(
            'sr_uuid',
            'sr_media_asset_flag',
            'sr_orig_value',
            'sr_mod_value',
            'sr_status',

            'Question' => array(
                'ques_uuid',
                'ques_dis_seq',
                'ques_status',
                'ques_type',
                'ques_value',
                'ques_choices',
            ),
        ),

        // Annotations.
        'SrsAnnotation' => array(
            'srsan_id',
            'srsan_value',
            'srsan_cre_dtim',
            'srsan_upd_dtim',
            'CreUser' => array(
                'DEF::USERSTAMP',
                'UserOrg' => 'DEF::USERORG',
            ),
        ),

        'primary_email',
        'gender',
        'age',
        'occupation',

        // Only used on fetch.
        'sentiment',
        'sentiment_score',

        'Source' => array(
            'DEF::SOURCE',

    		'SrcEmail' => 'DEF::SRCEMAIL',
            'SrcPhoneNumber' => 'DEF::SRCPHONE',
            'SrcMailAddress' => 'DEF::SRCMAIL',
        ),

        'Inquiry' => array(
            'DEF::INQUIRY',
            'ProjectInquiry' => array('Project'),
            'CreUser' => array(
                'DEF::USERSTAMP',
                'UserOrg' => 'DEF::USERORG'
            )
        ),

        'UserVisitSrs' => array(
            'uv_id'
        )
    );
    */

    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    // protected function air_query($args=array()) {
    //     $q = Doctrine_Query::create()->from('SrcResponseSet a');
    //     $q->leftJoin('a.Inquiry i');
    //     $q->leftJoin('a.Source s');
    // 
    //     // Let the caller know if this record has been visited by the current user before.
    //     $q->leftJoin('a.UserVisitSrs v with v.uv_user_id = ?', $this->user->user_id);
    // 
    //     // Add primary email address.
    //     $q->leftJoin('s.SrcMailAddress m');
    //     $q->addWhere('m.smadd_primary_flag = true');
    // 
    //     // filter by srs_type
    //     if (isset($args['type'])) {
    //         air2_query_in($q, $args['type'], 'a.srs_type');
    //     }
    // 
    //     // filter by inquiry
    //     if (isset($args['inq_uuid'])) {
    //         $q->addWhere('i.inq_uuid = ?', $args['inq_uuid']);
    //     }
    // 
    //     /*
    //      * Filter by text of SrcResponse.
    //      */
    //     if (isset($args['filter'])) {
    //         $filter = $args['filter'];
    // 
    //         // 'Wildcard' the filter.
    //         $filter = trim($filter);
    //         $filter = "%$filter%";
    // 
    //         $q->addWhere(
    //             'a.srs_id in ' .
    //             '(select sr_srs_id from src_response where sr_srs_id = a.srs_id and sr_orig_value like ?)',
    //             $filter
    //         );
    //     }
    // 
    //     $this->flatten($q);
    //     return $q;
    // }

    /**
     * Fetch function.
     *
     * @param   string              $uuid
     * @param   boolean             $minimal (optional) Default false.
     * @return  Doctrine_Record
     **/
    // protected function air_fetch($uuid, $minimal=false) {
    //     
    // }

    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $rec
     */
    // protected function air_fetch($uuid, $minimal=false) {
    //     $q = Doctrine_Query::create()->from('SrcResponseSet a');
    //     $q->leftJoin('a.Inquiry i');
    //     $q->leftJoin('a.Source s');
    //     $q->andWhere('a.srs_uuid = ?', $uuid);
    // 
    //     $q->leftJoin('a.CreUser acu');
    //     $q->leftJoin('acu.UserOrg acuo');
    // 
    //     $q->leftJoin('i.ProjectInquiry ipi');
    //     $q->leftJoin('ipi.Project ipip');
    //     $q->leftJoin('i.CreUser icu');
    //     $q->leftJoin('icu.UserOrg icuo');
    //     $q->leftJoin('icuo.Organization icuoo');
    // 
    //     // Srs annotations.
    //     $q->leftJoin('a.SrsAnnotation srsa');
    // 
    //     // Add primary email address.
    //     $q->leftJoin('s.SrcEmail sem with sem.sem_primary_flag = true');
    // 
    //     // Add primary address.
    //     $q->leftJoin('s.SrcMailAddress m with m.smadd_primary_flag = true');
    // 
    //     // Add primary phone number.
    //     $q->leftJoin('s.SrcPhoneNumber phone with phone.sph_primary_flag = true');
    // 
    //     // Gender info.
    //     $q->leftJoin('s.SrcFact sf');
    //     $q->leftJoin('sf.Fact sff with sff.fact_identifier = \'gender\'');
    // 
    //     // Birth year/age.
    //     $q->leftJoin('s.SrcFact sfa');
    //     $q->leftJoin('sfa.Fact sfaf with sfaf.fact_identifier = \'birth_year\'');
    // 
    //     // add responses/questions
    //     $q->leftJoin('a.SrcResponse sr');
    //     $q->leftJoin('sr.Question q');
    //     $q->addOrderBy('q.ques_dis_seq asc'); //3rd-level orderby
    // 
    //     /*
    //      * Add any special selects. Note that this has to be done at the end, or data doesn't
    //      * get selected correctly. Doctrine bug?
    //      */
    //     // gender.
    //     $q->addSelect('sf.sf_src_value as gender');
    // 
    //     // age.
    //     $q->addSelect('(year(curdate()) - cast(sfa.sf_src_value as unsigned)) as age');
    // 
    //     // primary_email.
    //     $q->addSelect('sem.sem_email as primary_email');
    // 
    //     // occupation. We use the newest (greatest start date) 'experience' record for this.
    //     $experience = SrcVita::$TYPE_EXPERIENCE;
    //     $q->addSelect(
    //         '(select sv_value from src_vita ' .
    //         ' where  sv_src_id = s.src_id ' .
    //         " and    sv_type = '$experience' " .
    //         ' and    sv_end_date is null' .
    //         ' order by sv_start_date desc limit 1) as occupation'
    //     );
    // 
    //     /*
    //      * Prep and send to caller.
    //      */
    //     $this->flatten($q);
    //     $srs = $q->fetchOne();
    // 
    //     // Record a 'visit' to this SrcResponseSet.
    //     $ip = $_SERVER['REMOTE_ADDR'];
    //     $srs->visit(array('user' => $this->user, 'ip' => $ip));
    // 
    //     return $srs;
    // }

    /**
     * Fix up records to include extra data, etc.
     *
     * Overridden Rframe_Resource method.
     *
     * @see Rframe_Resource
     * @param Doctrine_Record $record
     * @return array
     **/
    // protected function format_radix(Doctrine_Record $record) {
    //     // Inherit AIRAPI_Resource functionality.
    //     $record = parent::format_radix($record);
    // 
    //     if (isset($record['SrcResponse'])) {
    //         $all_responses = '';
    // 
    //         foreach ($record['SrcResponse'] as $sr) {
    //             // Only consider open text fields.
    //             $text_or_textarea = array(Question::$TYPE_TEXT, Question::$TYPE_TEXTAREA);
    // 
    //             if (in_array($sr['Question']['ques_type'], $text_or_textarea)) {
    //                 $all_responses .= $sr['sr_orig_value'];
    //             }
    //         }
    // 
    //         // If there were some textual responses, classify them.
    //         if ($all_responses) {
    //             // Break statements up into sentences first
    //             $sentence = strtok($all_responses, ".\n");
    // 
    //             $num_pos = 0;
    //             $num_neg = 0;
    // 
    //             while ($sentence) {
    //                 $sentiment = Sentiment::instance()->classify($sentence);
    // 
    //                 if ($sentiment == Sentiment::$POSITIVE) {
    //                     $num_pos++;
    //                 }
    //                 else {
    //                     $num_neg++;
    //                 }
    // 
    //                 $sentence = strtok(".\n");
    //             }
    // 
    //             $record['sentiment_score'] = round((($num_pos - $num_neg) / ($num_pos + $num_neg)) * 100.0);
    //         }
    //         // No textual responses.
    //         else {
    //             $record['sentiment']       = null;
    //             $record['sentiment_score'] = null;
    //         }
    //     }
    // 
    //     return $record;
    // }

    /**
     * Flatten some frequently-used fields.
     *
     * @param Doctrine_Query $q
     */
    // private function flatten(Doctrine_Query $q) {
    //     foreach ($this->fields as $idx => $val) {
    //         if (is_string($val) && preg_match('/^src\_/', $val)) {
    //             $q->addSelect("s.$val as $val");
    //         }
    //         elseif (is_string($val) && preg_match('/^inq\_/', $val)) {
    //             $q->addSelect("i.$val as $val");
    //         }
    //         elseif (is_string($val) && preg_match('/^smadd\_/', $val)) {
    //             $q->addSelect("m.$val as $val");
    //         }
    //     }
    // }
}
