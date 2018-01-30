<?php
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

/**
 * Source
 *
 * A "Contact" in AIR2
 *
 * @property integer $src_id
 * @property string $src_uuid
 * @property string $src_username
 * @property string $src_password
 * @property string $src_first_name
 * @property string $src_last_name
 * @property string $src_middle_initial
 * @property string $src_pre_name
 * @property string $src_post_name
 * @property string $src_status
 * @property string $src_has_acct
 * @property string $src_channel
 * @property integer $src_cre_user
 * @property integer $src_upd_user
 * @property timestamp $src_cre_dtim
 * @property timestamp $src_upd_dtim
 * @property SrcStat             $SrcStat
 * @property Doctrine_Collection $SrcActivity
 * @property Doctrine_Collection $SrcAlias
 * @property Doctrine_Collection $SrcAnnotation
 * @property Doctrine_Collection $SrcEmail
 * @property Doctrine_Collection $SrcMailAddress
 * @property Doctrine_Collection $SrcPhoneNumber
 * @property Doctrine_Collection $SrcUri
 * @property Doctrine_Collection $SrcFact
 * @property Doctrine_Collection $SrcMediaAsset
 * @property Doctrine_Collection $SrcOrg
 * @property Doctrine_Collection $SrcOutcome
 * @property Doctrine_Collection $SrcPrefOrg
 * @property Doctrine_Collection $SrcPreference
 * @property Doctrine_Collection $SrcRelationship
 * @property Doctrine_Collection $SrcRelationship_2
 * @property Doctrine_Collection $SrcResponse
 * @property Doctrine_Collection $SrcResponseSet
 * @property Doctrine_Collection $SrcVita
 * @property Doctrine_Collection $SrcInquiry
 * @property Doctrine_Collection $BinSource
 * @property Doctrine_Collection $BinSource
 * @property Doctrine_Collection $TankSource
 * @property Doctrine_Collection $Trackback
 * @property Doctrine_Collection $Tags
 * @property Doctrine_Collection $SrcOrgCache
 * @author rcavis
 * @package default
 */
class Source extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ENGAGED = 'A';
    public static $STATUS_DEACTIVATED = 'D';
    public static $STATUS_ENROLLED = 'E';
    public static $STATUS_OPTED_OUT = 'F';
    public static $STATUS_INVITEE = 'I';
    public static $STATUS_UNSUBSCRIBED = 'U';
    public static $STATUS_EDITORIAL_DEACTV = 'X';
    public static $STATUS_DECEASED = 'P';
    public static $STATUS_TEMP_HOLD = 'T';
    public static $STATUS_NO_PRIMARY_EMAIL = 'N';
    public static $STATUS_NO_ORGS = 'G';
    public static $STATUS_ANONYMOUS = 'Z';
    public static $CHANNEL_REFERRED = 'R';
    public static $CHANNEL_QUERY = 'Q';
    public static $CHANNEL_INTERACTIVE = 'I';
    public static $CHANNEL_EVENT = 'E';
    public static $CHANNEL_ONLINE = 'O';
    public static $CHANNEL_IDEA_GENERATOR = 'G';
    public static $CHANNEL_UNKNOWN = 'U';
    public static $CHANNEL_NEWSROOM = 'N';
    public static $CHANNEL_OUTREACH = 'S';
    public static $ACCT_NO = 'N';
    public static $ACCT_YES = 'Y';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('source');
        $this->hasColumn('src_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('src_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('src_username', 'string', 255, array(
                'notnull' => true,
                'unique' => true,
                'airvalid' => array(
                    '/^\S.*\S$/' => 'Invalid src_username! Must be at least '.
                    '2 characters long, with no leading or trailing whitespace',
                ),
            ));
        $this->hasColumn('src_first_name', 'string', 255, array(

            ));
        $this->hasColumn('src_last_name', 'string', 255, array(

            ));
        $this->hasColumn('src_middle_initial', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('src_pre_name', 'string', 64, array(

            ));
        $this->hasColumn('src_post_name', 'string', 64, array(

            ));
        $this->hasColumn('src_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ENGAGED,
            ));
        $this->hasColumn('src_has_acct', 'string', 1, array(
                'fixed'  => true,
                'notnull' => true,
                'default' => self::$ACCT_NO
            )
        );
        $this->hasColumn('src_channel', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('src_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('src_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('src_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('src_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcStat', array(
                'local' => 'src_id',
                'foreign' => 'sstat_src_id',
            ));
        $this->hasMany('SrcActivity', array(
                'local' => 'src_id',
                'foreign' => 'sact_src_id'
            ));
        $this->hasMany('SrcAlias', array(
                'local' => 'src_id',
                'foreign' => 'sa_src_id'
            ));
        $this->hasMany('SrcAnnotation', array(
                'local' => 'src_id',
                'foreign' => 'srcan_src_id'
            ));
        $this->hasMany('SrcEmail', array(
                'local' => 'src_id',
                'foreign' => 'sem_src_id'
            ));
        $this->hasMany('SrcMailAddress', array(
                'local' => 'src_id',
                'foreign' => 'smadd_src_id'
            ));
        $this->hasMany('SrcPhoneNumber', array(
                'local' => 'src_id',
                'foreign' => 'sph_src_id'
            ));
        $this->hasMany('SrcUri', array(
                'local' => 'src_id',
                'foreign' => 'suri_src_id'
            ));
        $this->hasMany('SrcFact', array(
                'local' => 'src_id',
                'foreign' => 'sf_src_id'
            ));
        $this->hasMany('SrcMediaAsset', array(
                'local' => 'src_id',
                'foreign' => 'sma_src_id'
            ));
        $this->hasMany('SrcOrg', array(
                'local' => 'src_id',
                'foreign' => 'so_src_id'
            ));
        $this->hasMany('SrcOutcome', array(
                'local' => 'src_id',
                'foreign' => 'sout_src_id'
            ));
        $this->hasMany('SrcPrefOrg', array(
                'local' => 'src_id',
                'foreign' => 'spo_src_id'
            ));
        $this->hasMany('SrcPreference', array(
                'local' => 'src_id',
                'foreign' => 'sp_src_id'
            ));
        $this->hasMany('SrcRelationship', array(
                'local' => 'src_id',
                'foreign' => 'src_src_id'
            ));
        $this->hasMany('SrcRelationship as SrcRelationship_2', array(
                'local' => 'src_id',
                'foreign' => 'srel_src_id'
            ));
        $this->hasMany('SrcResponse', array(
                'local' => 'src_id',
                'foreign' => 'sr_src_id'
            ));
        $this->hasMany('SrcResponseSet', array(
                'local' => 'src_id',
                'foreign' => 'srs_src_id'
            ));
        $this->hasMany('SrcVita', array(
                'local' => 'src_id',
                'foreign' => 'sv_src_id'
            ));
        $this->hasMany('SrcInquiry', array(
                'local' => 'src_id',
                'foreign' => 'si_src_id'
            ));
        $this->hasMany('BinSource', array(
                'local' => 'src_id',
                'foreign' => 'bsrc_src_id',
            ));
        $this->hasMany('BinSource', array(
                'local' => 'src_id',
                'foreign' => 'bsrc_src_id',
            ));
        $this->hasMany('TankSource', array(
                'local' => 'src_id',
                'foreign' => 'src_id',
            ));
        $this->hasMany('Trackback', array(
                'local' => 'src_id',
                'foreign' => 'tb_src_id',
            ));
        $this->hasMany('SrcOrgCache', array(
                'local' => 'src_id',
                'foreign' => 'soc_src_id',
            ));

        // Tagging
        $this->hasMany('TagSource as Tags', array(
                'local' => 'src_id',
                'foreign' => 'tag_xid'
            ));
    }


    /**
     * By default, discriminate throws conflicts on existing, non-matching
     * values.  Here, we'll allow overwriting the src_status.
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    public function discriminate($data, &$tsrc, $op=null) {
        if (isset($data['src_status']) && strlen($data['src_status']) == 1) {
            $this->src_status = $data['src_status'];
        }
        parent::discriminate($data, $tsrc, $op);
    }


    /**
     * Helper function to create SrcOrg records.
     *
     * @param array   $orgs
     * @param char    $status (optional)
     */
    public function add_orgs(array $orgs, $status=null) {
        // default to opted-in
        if (!$status) $status = SrcOrg::$STATUS_OPTED_IN;

        foreach ($orgs as $org) {
            $sorg = new SrcOrg();
            $sorg->so_status = $status;
            $sorg->so_org_id = $org->org_id;
            $this->SrcOrg[] = $sorg;
        }
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "(".$a."src_username LIKE ? OR ".$a."src_first_name LIKE ? OR ".
            $a."src_last_name like ?)";

        if ($useOr) {
            $q->orWhere($str, array("%$search%", "$search%", "$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%", "$search%", "$search%"));
        }
    }


    /**
     * Restrict user access to Sources based on which Organizations the Sources
     * have opted-in with, and what roles the User has in those Organizations.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_read(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // look in cache for readable sources
        $readable_org_ids = $u->get_authz_str(ACTION_ORG_SRC_READ, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $readable_org_ids";
        $q->addWhere("{$a}src_id in ($cache)");
    }


    /**
     * Restrict user access to Sources based on which Organizations the Sources
     * have opted-in with, and what roles the User has in those Organizations.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_write(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // look in cache for writeable sources
        $readable_org_ids = $u->get_authz_str(ACTION_ORG_SRC_UPDATE, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $readable_org_ids";
        $q->addWhere("{$a}src_id in ($cache)");

    }


    /**
     * Restrict user access to Sources based on which Organizations the Sources
     * have opted-in with, and what roles the User has in those Organizations.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // look in cache for manageable sources
        $readable_org_ids = $u->get_authz_str(ACTION_ORG_SRC_DELETE, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $readable_org_ids";
        $q->addWhere("{$a}src_id in ($cache)");
    }


    /**
     * Returns array of related Organization org_ids that affect
     * the authorization of the Source.
     *
     * NOTE: this implements AIR1-style authz, where so_status DOES NOT matter.
     *
     * @return array $org_ids
     */
    public function get_authz() {
        $org_ids = array();

        // if this is a new Source, there are no orgs yet
        if (!$this->src_id) {
            return array();
        }

        // status doesn't matter for authz, so return all
        $authz = self::get_authz_status($this->src_id);
        return array_keys($authz);
    }


    /**
     * Returns a mapping of org_id => so_status, cascading everything down the
     * org tree.  Only src_orgs with a DELETED status will be ignored here.
     *
     * @param int     $src_id
     * @return array $org_ids
     */
    public static function get_authz_status($src_id) {
        $conn = AIR2_DBManager::get_master_connection();
        $org_status = array();

        // calculate authz
        $sel = "select * from src_org where so_src_id = $src_id";
        $srcorgs = $conn->fetchAll($sel);
        $sorted = Organization::sort_by_depth($srcorgs, 'so_org_id');
        foreach ($sorted as $so) {
            // ignore deleted src_orgs
            $stat = $so['so_status'];
            if ($stat == SrcOrg::$STATUS_DELETED) continue;

            // apply status to self and all children
            $children = Organization::get_org_children($so['so_org_id']);
            foreach ($children as $oid) {
                $org_status[$oid] = $stat;
            }
        }
        return $org_status;
    }


    /**
     * Readable if READER in opted-in Org.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // look for READER role in related organization
        $user_authz = $user->get_authz();
        $src_org_ids = $this->get_authz();
        foreach ($src_org_ids as $org_id) {
            $role = isset($user_authz[$org_id]) ? $user_authz[$org_id] : null;
            if (ACTION_ORG_SRC_READ & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }

        // no reader role found
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Writable if EDITOR in opted-in Org.
     *
     * @param User    $user
     * @param bool    $respect_lock (optional)
     * @return authz integer
     */
    public function user_may_write($user, $respect_lock=true) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($respect_lock && $this->src_has_acct == Source::$ACCT_YES) {
            return AIR2_AUTHZ_IS_DENIED;
        }

        // look for EDITOR role in related organization
        $user_authz = $user->get_authz();
        $src_org_ids = $this->get_authz();
        if (!$this->src_id && !count($src_org_ids)) {
            // new source. must look in-memory rather than via get_authz()
            $src_org_ids = array($this->SrcOrg[0]->so_org_id);
        }
        foreach ($src_org_ids as $org_id) {
            $role = isset($user_authz[$org_id]) ? $user_authz[$org_id] : null;
            if ($this->exists() && (ACTION_ORG_SRC_UPDATE & $role)) {
                return AIR2_AUTHZ_IS_ORG;
            }
            elseif (!$this->exists() && (ACTION_ORG_SRC_CREATE & $role)) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }

        // no writer role found
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manageable if MANAGER in opted-in Org.
     *
     * @param User    $user
     * @param bool    $respect_lock (optional)
     * @return authz integer
     */
    public function user_may_manage($user, $respect_lock=true) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($respect_lock && $this->src_has_acct == Source::$ACCT_YES) {
            return AIR2_AUTHZ_IS_DENIED;
        }

        // look for MANAGER role in related organization
        $user_authz = $user->get_authz();
        $src_org_ids = $this->get_authz();
        foreach ($src_org_ids as $org_id) {
            $role = isset($user_authz[$org_id]) ? $user_authz[$org_id] : null;
            if (ACTION_ORG_SRC_DELETE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }

        // no manager role found
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     *
     *
     * @param unknown $searchDb (optional)
     * @return SrcEmail object
     */
    public function get_primary_email($searchDb=true) {
        if ($searchDb) {
            $q = AIR2_Query::create()
            ->from('SrcEmail')
            ->where('sem_primary_flag=1 and sem_src_id=?', $this->src_id);
            $res = $q->fetchOne();
            $q->free();
            return $res;
        }
        foreach ($this->SrcEmail as $sem) {
            if ($sem->sem_primary_flag) {
                return $sem;
            }
        }
        return false;
    }



    /**
     *
     *
     * @param bool    $searchDb (optional) (optional, default true)
     * @return unknown
     */
    public function get_primary_email_status($searchDb=true) {
        if ($searchDb) {
            $q = AIR2_Query::create()
            ->from('SrcEmail')
            ->where('sem_primary_flag=1 and sem_src_id=?', $this->src_id);
            $res = $q->fetchOne(null, Doctrine_Core::HYDRATE_ARRAY);
            $q->free();
            return $res['sem_status'];
        }
        foreach ($this->SrcEmail as $sem) {
            if ($sem->sem_primary_flag) {
                return $sem->sem_status;
            }
        }
        return false;
    }


    /**
     *
     *
     * @return SrcMailAddress object
     */
    public function get_primary_address() {
        foreach ($this->SrcMailAddress as $smadd) {
            if ($smadd->smadd_primary_flag) {
                return $smadd;
            }
        }
        return false;
    }


    /**
     * Override save() to set src_status after all children are saved.
     * Apparently the postSave() hook happens *before* children are saved,
     * which means the set_src_status() algorithm has immature data.
     *
     * @param Doctrine_Connection $conn
     * @return unknown
     */
    public function save(Doctrine_Connection $conn=null) {
        $ret = parent::save($conn);
        $this->set_and_save_src_status();
        return $ret;
    }


    /**
     * Calls set_src_status() (which just returns the status)
     * and then executes a SQL update directly on the source table.
     */
    public function set_and_save_src_status() {
        // this only works AFTER the source is saved
        if ($this->src_id) {
            AIR2_DBManager::$FORCE_MASTER_ONLY = true;
            $stat = $this->set_src_status();
            $conn = AIR2_DBManager::get_master_connection();
            $conn->execute("update source set src_status='$stat' where src_id=".$this->src_id);
        }
    }


    /**
     * Sets src_status programmatically, according to logic first
     * introduced in AIR1 Contact.php.
     * See http://infoserverwiki.publicradio.org/index.php/PIJ_Source_Status_Business_Rules
     *
     * @return string src_status char
     */
    public function set_src_status() {
        $stat = $this->src_status;

        // special status for MyPIN "T"emp sources
        // that have not yet been confirmed.
        if ($stat == self::$STATUS_TEMP_HOLD) {
            return $stat;
        }

        //error_log("initial status==$stat");
        $sem_status = $this->get_primary_email_status();
        //error_log("sem_status==".$sem_status);
        if (!$sem_status) {
            $this->src_status = self::$STATUS_NO_PRIMARY_EMAIL;

            if (!strlen($this->src_first_name) && !strlen($this->src_last_name)) {
                $this->src_status = self::$STATUS_ANONYMOUS;
            }

            return $this->src_status;
        }
        if ($sem_status == SrcEmail::$STATUS_UNSUBSCRIBED) {
            $this->src_status = self::$STATUS_UNSUBSCRIBED;
            return $this->src_status;
        }
        if ($sem_status != SrcEmail::$STATUS_GOOD) {
            $this->src_status = self::$STATUS_NO_PRIMARY_EMAIL;
            return $this->src_status;
        }

        $orgs_status = self::get_authz_status($this->src_id);
        $num_orgs = count($orgs_status);
        $num_active = 0;
        $num_deactive = 0;
        $num_opted_out = 0;
        $num_deleted = 0;
        foreach ($orgs_status as $o=>$s) {
            switch ($s) {

            case SrcOrg::$STATUS_OPTED_IN:
                $num_active++;
                break;

            case SrcOrg::$STATUS_EDITORIAL_DEACTV:
                $num_deactive++;
                break;

            case SrcOrg::$STATUS_OPTED_OUT:
                $num_opted_out++;
                break;

            case SrcOrg::$STATUS_DELETED:
                $num_deleted++;
                break;

            default:
                throw new Exception("Unknown so_status: $s (org=$o)");
            }
        }

        //error_log("num_orgs=$num_orgs  num_active=$num_active  num_deactive=$num_deactive  num_opted_out=$num_opted_out");

        if (!$num_orgs || $num_deleted == $num_orgs) {
            $this->src_status = self::$STATUS_NO_ORGS;
            return $this->src_status;
        }
        if ($num_deactive == $num_orgs) {
            $this->src_status = self::$STATUS_DEACTIVATED;
            return $this->src_status;
        }
        if ($num_opted_out == $num_orgs) {
            $this->src_status = self::$STATUS_OPTED_OUT;
            return $this->src_status;
        }
        if (!$num_active) {
            if ($num_deactive >= $num_opted_out) {
                $this->src_status = self::$STATUS_DEACTIVATED;
            }
            else {
                $this->src_status = self::$STATUS_OPTED_OUT;
            }
            return $this->src_status;
        }

        // either E or A at this point, depending on number of responses
        if ($this->get_number_involved_activities() <= 1) {
            $this->src_status = self::$STATUS_ENROLLED;
        }
        else {
            $this->src_status = self::$STATUS_ENGAGED;
        }

        return $this->src_status;
    }


    /**
     *
     *
     * @return unknown
     */
    public function get_number_involved_activities() {
        $q = AIR2_Query::create()
        ->from('SrcActivity sact')
        ->where('sact.sact_src_id=?', $this->src_id)
        ->andWhere("sact.sact_actm_id in (select actm_id from activity_master where actm_type in ('I'))");
        $res = $q->execute();
        $c = $res->count();
        $q->free();
        $res->free();
        return $c;
    }


}
