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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * Submission/Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission_Source extends AIRAPI_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('fetch');

    // metadata
    protected $ident = 'src_uuid';
    protected $fields = array(
        'DEF::SOURCE',
        'src_cre_dtim',
        'src_upd_dtim',
        'SrcEmail' => 'DEF::SRCEMAIL',
        'SrcPhoneNumber' => 'DEF::SRCPHONE',
        'SrcMailAddress' => 'DEF::SRCMAIL',
        'SrcVita' => array(
            'sv_uuid',
            'sv_seq',
            'sv_type',
            'sv_status',
            'sv_origin',
            'sv_conf_level',
            'sv_lock_flag',
            'sv_lat',
            'sv_long',
            'sv_start_date',
            'sv_end_date',
            'sv_value',
            'sv_basis',
            'sv_cre_dtim',
            'sv_upd_dtim',
        ),
        'SrcFact' => array(
            'sf_src_value',
            'sf_fv_id',
            'sf_src_fv_id',
            'sf_lock_flag',
            'sf_public_flag',
            'sf_cre_dtim',
            'sf_upd_dtim',
            'Fact' => array('fact_uuid', 'fact_name', 'fact_identifier', 'fact_fv_type'),
            'AnalystFV' => 'DEF::FACTVALUE',
            'SourceFV' => 'DEF::FACTVALUE',
        ),

        // flatten email
        'primary_email',

        // flatten demographic info
        'occupation',
    );


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = Doctrine_Query::create()->from('Source a');
        $q->andWhere('a.src_id = ?', $this->parent_rec->srs_src_id);

        // limited src data, with no authz applied
        $q->leftJoin('a.SrcEmail se WITH se.sem_primary_flag = true');
        $q->leftJoin('a.SrcPhoneNumber sp WITH sp.sph_primary_flag = true');
        $q->leftJoin('a.SrcMailAddress sm WITH sm.smadd_primary_flag = true');
        $q->leftJoin('a.SrcVita sv WITH sv.sv_type = ?', SrcVita::$TYPE_EXPERIENCE);
        $q->leftJoin('a.SrcFact sf');
        $q->leftJoin('sf.Fact sff');
        $q->leftJoin('sf.AnalystFV sfav');
        $q->leftJoin('sf.SourceFV sfsv');

        /*
         * Flatten.
         */

        // Primary email.
        $q->leftJoin('a.SrcEmail primary WITH primary.sem_primary_flag = true');
        $q->addSelect('primary.sem_email as primary_email');

        // Occupation. We use the newest (greatest start date) 'experience' record for this.
        $experience = SrcVita::$TYPE_EXPERIENCE;
        $q->addSelect(
            '(select sv_value from src_vita ' .
            ' where  sv_src_id = a.src_id ' .
            " and    sv_type = '$experience' " .
            ' and    sv_end_date is null' .
            ' order by sv_start_date desc limit 1) as occupation'
        );

        return $q->fetchOne();
    }


    /**
     * Allow READ-ing this resource without access to Source
     *
     * @throws Rframe_Exceptions
     * @param Doctrine_Record $rec
     * @param string $authz_type
     */
    protected function check_authz(Doctrine_Record $rec, $authz_type) {
        if ($authz_type != 'read') {
            parent::check_authz($rec, $authz_type);
        }
    }


}
