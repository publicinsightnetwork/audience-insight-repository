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
require_once 'AIR2Bin.php';

/**
 * Bin API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array('owner', 'owner_flag', 'status', 'type');
    protected $CREATE_DATA = array('bin_name', 'bin_desc', 'bin_shared_flag', 'bin_status', 'bin_type');
    protected $UPDATE_DATA = array('bin_name', 'bin_desc', 'bin_shared_flag', 'bin_status');

    // these are the bulk UPDATE operations allowed on this resource
    // (keys will be added to $UPDATE_DATA)
    protected $BULK_OPS = array(
        'bulk_add',
        'bulk_addsub',
        'bulk_addtank',
        'bulk_addsearch',
        'bulk_addbin',
        'bulk_remove',
        'bulk_removeall',
        'bulk_random',
        'bulk_tag',
        'bulk_annot',
        // special: supplement other operations
        'bulk_add_notes',
    );

    // bulk op applied for an UPDATE request
    protected $bulk_op;
    protected $bulk_rs;

    // default paging/sorting
    protected $query_args_default = array('status' => 'AP');
    protected $sort_default       = 'bin_upd_dtim desc';
    protected $sort_valids        = array('bin_upd_dtim', 'bin_name', 'src_count', 'owner',
        'owner_flag', 'user_first_name', 'user_last_name');

    // metadata
    protected $ident = 'bin_uuid';
    protected $fields = array(
        'bin_uuid',
        'bin_name',
        'bin_desc',
        'bin_type',
        'bin_status',
        'bin_shared_flag',
        'bin_cre_dtim',
        'bin_upd_dtim',
        'User' => 'DEF::USERSTAMP',
        // virtual crazy-sql fields
        'src_count',
        'subm_count',
        'owner_flag',
        'counts', //only used on fetch
    );


    /**
     * Add $BULK_OPS to $UPDATE_DATA
     *
     * @param Rframe_Parser $parser
     * @param array         $path
     * @param array         $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        foreach ($this->BULK_OPS as $key) {
            $this->UPDATE_DATA[] = $key;
        }
        parent::__construct($parser, $path, $inits);
    }


    /**
     * Create
     *
     * @param  array $data
     * @return Bin   $rec
     */
    protected function air_create($data) {
        $b = new Bin();
        $b->bin_user_id = $this->user->user_id;
        return $b;
    }


    /**
     * Query
     *
     * @param  array          $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array(), $include_temp=false) {
        $q = Doctrine_Query::create()->from('Bin b');
        $q->leftJoin('b.User u');

        // source count
        $src_count = 'select count(*) from bin_source where bsrc_bin_id=b.bin_id';
        $q->addSelect("($src_count) as src_count");

        // submission count
        $subm_count = 'select count(*) from bin_src_response_set where bsrs_bin_id=b.bin_id';
        $q->addSelect("($subm_count) as subm_count");

        // is user the bin-owner?
        $my_id = $this->user->user_id;
        $q->addSelect("(b.bin_user_id=$my_id) as owner_flag");

        // skip the temp Bins (print only)
        if (!$include_temp) {
            $q->addWhere("b.bin_type not in ('T')");
        }
        
        // query args
        if (isset($args['owner']) || isset($args['owner_flag'])) {
            $q->addWhere('b.bin_user_id = ?', $this->user->user_id);
        }
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'b.bin_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'b.bin_type');
        }
        return $q;
    }


    /**
     * Fetch
     *
     * @param  string $uuid
     * @param  bool   $minimal
     * @return Bin    $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        $q = ($minimal) ? Doctrine_Query::create()->from('Bin b') : $this->air_query(null, true);
        $q->andWhere('b.bin_uuid = ?', $uuid);
        $rec = $q->fetchOne();

        // add some complex aggregate counts
        if (!$minimal && $rec && $rec->user_may_read($this->user)) {
            $counts = array(
                'src_total'            => $rec->src_count,
                'src_read'             => $this->_get_bin_src_count($rec, ACTION_ORG_SRC_READ),
                'src_update'           => $this->_get_bin_src_count($rec, ACTION_ORG_SRC_UPDATE),
                'src_export_csv'       => $this->_get_bin_src_count($rec, ACTION_EXPORT_CSV),
                'src_export_mailchimp' => $this->_get_bin_src_count($rec, ACTION_EXPORT_MAILCHIMP),
                'src_export_print'     => $this->_get_bin_src_count($rec, ACTION_EXPORT_PRINT),
                'subm_total'           => $rec->subm_count,
                'subm_read'            => $this->_get_bin_subm_count($rec, ACTION_ORG_PRJ_INQ_SRS_READ),
                'subm_update'          => $this->_get_bin_subm_count($rec, ACTION_ORG_PRJ_INQ_SRS_UPDATE),
            );
            $rec->mapValue('counts', $counts);
        }
        return $rec;
    }


    /**
     * Handle bulk-update operations
     *
     * @param Bin $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        // unset bulk_op vars
        $this->bulk_op = null;
        $this->bulk_rs = null;

        // extract any notes for a bulk_add
        $addnotes = null;
        if (array_key_exists('bulk_add_notes', $data)) {
            $addnotes = $data['bulk_add_notes'];
            unset($data['bulk_add_notes']);
            if (strlen($addnotes) < 1 || strlen($addnotes) > 255) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid notes field for add');
            }
        }

        // look for first BULK_OP
        $bulk_op = false;
        foreach ($this->BULK_OPS as $op) {
            if (isset($data[$op])) {
                $bulk_op = $op;
                break;
            }
        }

        // run op
        if ($bulk_op) {
            // add-notes only allowed on 'add' operations
            if ($addnotes && !preg_match('/^bulk_add/', $bulk_op)) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Key bulk_add_notes not allowed for operation $bulk_op");
            }

            // sanity
            if (count($data) > 1) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Bulk operation ".
                    "$bulk_op cannot run with any other updates!");
            }
            $this->run_bulk($rec, $bulk_op, $data[$bulk_op], $addnotes);

            // touch timestamp, since bulk ops usually don't
            $rec->bin_upd_user = $this->user->user_id;
            $rec->bin_upd_dtim = air2_date();
        }
    }


    /**
     * Ignore authz check for bulk_random operation (only need read)
     *
     * @throws Rframe_Exceptions
     * @param Doctrine_Record $rec
     * @param string $authz_type
     */
    protected function check_authz(Doctrine_Record $rec, $authz_type) {
        if ($authz_type == 'write' && $this->bulk_op == 'bulk_random') {
            //no-op
        }
        else {
            parent::check_authz($rec, $authz_type);
        }
    }


    /**
     * Add 'bulk' operation data to $extra params
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid  (optional)
     * @param array   $extra (optional)
     * @return array  $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        if ($method == 'update' && $this->bulk_op) {
            $extra['bulk_op'] = $this->bulk_op;
            $extra['bulk_rs'] = $this->bulk_rs;
        }
        return parent::format($mixed, $method, $uuid, $extra);
    }


    /**
     * Process bulk add/remove/etc operations
     *
     * @param Bin    $rec
     * @param string $bulk_op
     * @param array  $data
     * @param string $notes
     */
    protected function run_bulk($rec, $bulk_op, $data, $notes=null) {
        // check for write-authz on bin (for everything EXCEPT random)
        if ($bulk_op != 'bulk_random' && !$rec->user_may_write($this->user)) {
            $msg = "Insufficient authz for $bulk_op";
            throw new Rframe_Exception(Rframe::BAD_AUTHZ, $msg);
        }
        $this->bulk_op = $bulk_op;

        // rethrow any exceptions as 'data' exceptions
        try {
            if ($bulk_op == 'bulk_add') {
                $this->bulk_rs = AIR2Bin::add_sources($rec, $data, $notes);
            }
            if ($bulk_op == 'bulk_addsub') {
                $this->bulk_rs = AIR2Bin::add_submissions($rec, $data, $notes);
            }
            if ($bulk_op == 'bulk_addsearch') {
                $this->bulk_rs = AIR2Bin::add_search($this->user, $rec, $data, $notes);
            }
            if ($bulk_op == 'bulk_addtank') {
                $tanks = array();
                $data = is_array($data) ? array_unique($data) : array($data);
                foreach ($data as $uuid) {
                    $t = AIR2_Record::find('Tank', $uuid);
                    if (!$t) throw new Exception("Invalid tank_uuid($uuid)");
                    $tanks[] = $t;
                }
                foreach ($tanks as $t) {
                    $counts = AIR2Bin::add_tank($rec, $t, $notes);
                    foreach ($counts as $key => $val) {
                        if (!isset($this->bulk_rs[$key])) $this->bulk_rs[$key] = 0;
                        $this->bulk_rs[$key] += $counts[$key];
                    }
                }
            }
            if ($bulk_op == 'bulk_addbin') {
                $bins = array();
                $data = is_array($data) ? array_unique($data) : array($data);
                foreach ($data as $uuid) {
                    $b = AIR2_Record::find('Bin', $uuid);
                    if (!$b) throw new Exception("Invalid bin_uuid($uuid)");
                    if (!$b->user_may_read($this->user)) throw new Exception("Invalid bin_uuid($uuid)");
                    $bins[] = $b;
                }
                foreach ($bins as $b) {
                    $counts = AIR2Bin::add_bin($rec, $b, $notes);
                    foreach ($counts as $key => $val) {
                        if (!isset($this->bulk_rs[$key])) $this->bulk_rs[$key] = 0;
                        $this->bulk_rs[$key] += $counts[$key];
                    }
                }
            }
            if ($bulk_op == 'bulk_remove') {
                $this->bulk_rs = AIR2Bin::remove_sources($rec, $data);
            }
            if ($bulk_op == 'bulk_removeall') {
                $this->bulk_rs = AIR2Bin::remove_all_sources($rec, $data);
            }
            if ($bulk_op == 'bulk_random') {
                $this->bulk_rs = AIR2Bin::randomize($this->user, $rec, $data);
            }
            if ($bulk_op == 'bulk_tag') {
                $this->bulk_rs = AIR2Bin::tag_sources($this->user, $rec, $data);
            }
            if ($bulk_op == 'bulk_annot') {
                $this->bulk_rs = AIR2Bin::annotate_sources($this->user, $rec, $data);
            }
        }
        catch (Rframe_Exception $e) {
            throw $e; //re-throw as-is
        }
        catch (Exception $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
    }


    /**
     * Get a count of bin sources (not bin_source, but the actual source) with
     * the given authorization.
     *
     * @param  Bin $rec
     * @param  int $action
     * @return int $count
     */
    private function _get_bin_src_count($rec, $action) {
        $org_ids = $this->user->get_authz_str($action, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $org_ids";

        // special case - mailchimp opted-in, optionally in a specific org
        if ($action == ACTION_EXPORT_MAILCHIMP) {
            $cache .= " and soc_status = '".SrcOrg::$STATUS_OPTED_IN."'";
            if (isset($_GET['email_uuid'])) {
                $email_uuid = 'email_uuid = "'.$_GET['email_uuid'].'"';
                $one_org = "select email_org_id from email where $email_uuid";
                $cache .= " and soc_org_id = ($one_org)";
            }
        }

        // exec count query
        $conn = AIR2_DBManager::get_connection();
        $bin_srcs = "select count(*) from bin_source where bsrc_bin_id=? and bsrc_src_id in ($cache)";
        return $conn->fetchOne($bin_srcs, array($rec->bin_id), 0);
    }


    /**
     * Get a count of bin src_response_sets (not bin_src_response_set, but the
     * actual src_response_set table) with the given authorization.
     *
     * @param  Bin $rec
     * @param  int $action
     * @return int $count
     */
    private function _get_bin_subm_count($rec, $action) {
        $read_org_ids = $this->user->get_authz_str($action, 'porg_org_id', true);
        $prj_ids  = "select porg_prj_id from project_org where $read_org_ids";
        $inq_ids  = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // exec count query
        $conn = AIR2_DBManager::get_connection();
        $bin_subms = "select count(*) from bin_src_response_set where bsrs_bin_id=? and bsrs_inq_id in ($inq_ids)";
        return $conn->fetchOne($bin_subms, array($rec->bin_id), 0);
    }


}
