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
 * Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update');
    protected $QUERY_ARGS  = array('email', 'excl_out');
    protected $CREATE_DATA = array('sem_email', 'org_uuid', 'src_first_name',
        'src_last_name', 'src_middle_initial', 'src_pre_name', 'src_post_name',
        'src_has_acct', 'src_channel');
    protected $UPDATE_DATA = array('src_first_name', 'src_last_name',
        'src_middle_initial', 'src_pre_name', 'src_post_name');

    // default paging/sorting
    protected $query_args_default = array();
    protected $sort_default   = 'src_username asc';
    protected $sort_valids    = array('src_username', 'src_first_name',
        'primary_email');

    // metadata
    protected $ident = 'src_uuid';
    protected $fields = array(
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
        'src_cre_dtim',
        'src_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'SrcEmail' => 'DEF::SRCEMAIL',
        'SrcPhoneNumber' => 'DEF::SRCPHONE',
        'SrcMailAddress' => 'DEF::SRCMAIL',
        'SrcOrg' => array(
            'so_uuid',
            'so_home_flag',
            'Organization' => 'DEF::ORGANIZATION',
        ),
        'SrcAlias' => array(
            'sa_id',
            'sa_first_name',
            'sa_last_name',
        ),
        'primary_email',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Source s');
        $q->leftJoin('s.CreUser cu');
        $q->leftJoin('s.UpdUser uu');
        $q->leftJoin('s.SrcEmail e WITH e.sem_primary_flag = true');
        $q->leftJoin('s.SrcPhoneNumber p');
        $q->leftJoin('s.SrcMailAddress m WITH m.smadd_primary_flag = true');
        $q->leftJoin('s.SrcOrg so WITH so.so_home_flag = true');
        $q->leftJoin('s.SrcAlias as');
        $q->leftJoin('so.Organization o');

        // search emails
        if (array_key_exists('email', $args)) {
            $q->addWhere("e.sem_email is not null");
            $e = $args['email'];
            if ($e && strlen($e) > 0) {
                $q->addWhere("e.sem_email like ?", "$e%");
            }
        }

        // exclude an outcome
        if (isset($args['excl_out'])) {
            $outq = "select out_id from outcome where out_uuid = ?";
            $excl = "select sout_src_id from src_outcome where sout_out_id = ($outq)";
            $q->addWhere("s.src_id not in ($excl)", $args['excl_out']);
        }

        // flatten
        $q->addSelect('e.sem_email as primary_email');
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('Source s');
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('s.src_uuid = ?', $uuid);

        // Flatten primary email.
        $q->leftJoin('s.SrcEmail primary WITH primary.sem_primary_flag = true');
        $q->addSelect('primary.sem_email as primary_email');

        $source = $q->fetchOne();

        return $source;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Source
     */
    protected function air_create($data) {
        if (!isset($data['sem_email'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "sem_email required");
        }
        if (!isset($data['org_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "org_uuid required");
        }
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            $u = $data['org_uuid'];
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid org_uuid '$u'");
        }

        $s = new Source();
        $s->src_username = $data['sem_email'];
        $s->SrcEmail[0]->sem_email = $data['sem_email'];
        $s->SrcEmail[0]->sem_primary_flag = true;
        $s->SrcOrg[0]->so_home_flag = true;
        $s->SrcOrg[0]->so_org_id = $org->org_id;

        // force opt-in to APMG
        if ($org->org_id != Organization::$APMPIN_ORG_ID) {
            $s->SrcOrg[1]->so_org_id = Organization::$APMPIN_ORG_ID;
            $s->SrcOrg[1]->so_cre_user = 1;
            $s->SrcOrg[1]->so_upd_user = 1;
        }
        return $s;
    }


    /**
     * Also show 'unlocked' authz (for locked sources)
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @param array   $extra (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $resp = parent::format($mixed, $method, $uuid, $extra);

        // check for fetch-record
        if ($method == 'fetch' && is_a($mixed, 'Doctrine_Record') && isset($resp['authz'])) {
            $resp['authz']['unlock_write'] = $mixed->user_may_write($this->user, false);
            $resp['authz']['unlock_manage'] = $mixed->user_may_manage($this->user, false);
        }
        return $resp;
    }


}
