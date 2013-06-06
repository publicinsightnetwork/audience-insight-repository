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
 * Tag
 *
 * A generic resource-tag in AIR2
 *
 * @property integer $tag_tm_id
 * @property integer $tag_xid
 * @property string $tag_ref_type
 * @property integer $tag_cre_user
 * @property integer $tag_upd_user
 * @property timestamp $tag_cre_dtim
 * @property timestamp $tag_upd_dtim
 * @property TagMaster $TagMaster
 * @author rcavis
 * @package default
 */
class Tag extends AIR2_Record {
    /* code_master values */
    public static $TYPE_INQUIRY = 'I';
    public static $TYPE_PROJECT = 'P';
    public static $TYPE_SOURCE = 'S';
    public static $TYPE_RESPONSE_SET = 'R';
    public static $TYPE_OUTCOME = 'O';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tag');
        $this->hasColumn('tag_tm_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('tag_xid', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('tag_ref_type', 'string', 1, array(
                'primary' => true,
            ));
        $this->hasColumn('tag_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tag_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('tag_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('tag_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();

        // setup mapping for tag_xid
        $this->setSubclasses(array(
                'TagInquiry'  => array('tag_ref_type' => 'I'),
                'TagProject'  => array('tag_ref_type' => 'P'),
                'TagSource'   => array('tag_ref_type' => 'S'),
                'TagResponseSet' => array('tag_ref_type' => 'R'),
            ));
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('TagMaster', array(
                'local' => 'tag_tm_id',
                'foreign' => 'tm_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Tag an object using raw connections.  Returns true if the tag was added,
     * or false if the tag already existed.
     *
     * @param int     $xid
     * @param string  $type
     * @param string  $tag
     * @return boolean
     */
    public static function make_tag($xid, $type, $tag) {
        // sanity!
        if (!is_numeric($xid) || $xid < 1) {
            throw new Exception("Bad tag XID($xid)");
        }
        if (!in_array($type, array('I', 'P', 'S', 'R'))) {
            throw new Exception("Bad tag TYPE($type)");
        }
        if (!is_string($tag) || strlen($tag) < 1) {
            throw new Exception("Bad tag '$tag'");
        }

        // fetch/create tag master
        $tm_id = TagMaster::get_tm_id($tag);

        // params
        $usrid = defined('AIR2_REMOTE_USER_ID') ? AIR2_REMOTE_USER_ID : 1;
        $dtim = air2_date();
        $cols = array('tag_tm_id', 'tag_xid', 'tag_ref_type', 'tag_cre_user',
            'tag_upd_user', 'tag_cre_dtim', 'tag_upd_dtim');
        $vals = array($tm_id, $xid, $type, $usrid, $usrid, $dtim, $dtim);

        // insert ignore
        $conn = AIR2_DBManager::get_master_connection();
        $colstr = implode(',', $cols);
        $params = air2_sql_param_string($cols);
        $n = $conn->exec("insert ignore into tag ($colstr) values ($params)", $vals);

        // if tag existed, update userstamp
        $tag_was_new = true;
        if ($n == 0) {
            $tag_was_new = false;
            $set = "tag_upd_user=$usrid, tag_upd_dtim='$dtim'";
            $where = "tag_tm_id=$tm_id and tag_xid=$xid and tag_ref_type='$type'";
            $conn->exec("update tag set $set where $where");
        }
        return $tag_was_new;
    }


    /**
     * Create a new, UNSAVED Tag from either a string tm_name or a tm_id.  Will
     * return false if an invalid tm_id is given.
     *
     * @param string  $flavor
     * @param int     $xid
     * @param mixed   $input
     * @param boolean $use_id
     * @return Tag $rec
     */
    public static function create_tag($flavor, $xid, $input, $use_id=false) {
        $tag = new $flavor();
        $tag->tag_xid = $xid;
        if ($use_id) {
            $tm = AIR2_Record::find('TagMaster', $input);
            if (!$tm) return false; //bad tm_id
            $tag->TagMaster = $tm;
        }
        else {
            $tm = Doctrine::getTable('TagMaster')->findOneBy('tm_name', $input);
            if (!$tm) {
                $tm = new TagMaster();
                $tm->tm_type = TagMaster::$TYPE_JOURNALISTIC;
                $tm->tm_name = $input;
            }
            $tag->TagMaster = $tm;
        }

        // check for existing tag on this record
        if ($tag->TagMaster->tm_id) {
            $q = Doctrine_Query::create()->from($flavor);
            $q->andWhere('tag_tm_id = ?', $tag->TagMaster->tm_id);
            $q->andWhere('tag_xid = ?', $xid);
            $dup = $q->fetchOne();
            if ($dup) {
                return $dup;
            }
        }
        return $tag;
    }


    /**
     * Inherit from external ref (implemented in subclasses)
     *
     * @param User $u
     * @return int $bitmask
     */
    public function user_may_read(User $u) {
        $r = $this->tag_ref_type;
        throw new Exception("Authz not implemented for tag_ref_type($r)");
    }


    /**
     * Inherit from external ref (implemented in subclasses)
     *
     * @param User $u
     * @return int $bitmask
     */
    public function user_may_write(User $u) {
        $r = $this->tag_ref_type;
        throw new Exception("Authz not implemented for tag_ref_type($r)");
    }


    /**
     * Same as writing
     *
     * @param User $u
     * @return int $bitmask
     */
    public function user_may_manage(User $u) {
        return $this->user_may_write($u);
    }


}
