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
 * TagMaster
 *
 * Master record of each tag, containing its shared name.
 *
 * @property integer $tm_id
 * @property string $tm_type
 * @property string $tm_name
 * @property integer $tm_iptc_id
 * @property integer $tm_cre_user
 * @property integer $tm_upd_user
 * @property timestamp $tm_cre_dtim
 * @property timestamp $tm_upd_dtim
 * @property IptcMaster $IptcMaster
 * @property Doctrine_Collection $Tag
 * @author rcavis
 * @package default
 */
class TagMaster extends AIR2_Record {
    /* code_master values */
    public static $TYPE_JOURNALISTIC = 'J';
    public static $TYPE_IPTC = 'I';

    /* cache tm_id's that we've already fetched */
    protected static $TM_ID_CACHE;

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tag_master');
        $this->hasColumn('tm_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tm_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_JOURNALISTIC,
            ));
        $this->hasColumn('tm_name', 'string', 32, array(
                'unique' => true,
                'airvalid' => array(
                    '/^[a-zA-Z0-9 _\-\.]*$/' => 'Invalid character(s)! Use [A-Za-z0-9] and [ -_.]',
                    '/^[\S].*[\S]$/' => 'Invalid leading or trailing whitespace',
                ),
            ));
        $this->hasColumn('tm_iptc_id', 'integer', 4, array(
                'unique' => true,
            ));
        $this->hasColumn('tm_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tm_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('tm_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('tm_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('IptcMaster', array(
                'local' => 'tm_iptc_id',
                'foreign' => 'iptc_id'
            ));
        $this->hasMany('Tag', array(
                'local' => 'tm_id',
                'foreign' => 'tag_tm_id'
            ));
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
        $str = "(".$a."tm_name REGEXP ? OR iptc_name REGEXP ?)";
        if ($useOr) {
            $q->orWhere($str, array("[[:<:]]$search", "[[:<:]]$search"));
        }
        else {
            $q->addWhere($str, array("[[:<:]]$search", "[[:<:]]$search"));
        }
    }


    /**
     * Static function to find the tm_id for a string tag.  If the tag doesn't
     * exist, it will be created.
     *
     * A doctrine exception will be thrown if the tag string is invalid
     *
     * @param string  $tagstr
     * @return int
     */
    public static function get_tm_id($tagstr) {
        if (!$tagstr || !is_string($tagstr) || !strlen($tagstr)) {
            throw new Exception('Invalid non-string tag');
        }

        // check cache
        $lower = strtolower($tagstr);
        if (isset(self::$TM_ID_CACHE[$lower])) {
            return self::$TM_ID_CACHE[$lower];
        }

        // lookup or create
        $tm = Doctrine::getTable('TagMaster')->findOneBy('tm_name', $tagstr);
        if (!$tm) {
            $tm = new TagMaster();
            $tm->tm_name = $tagstr;
            $tm->tm_type = TagMaster::$TYPE_JOURNALISTIC;
            $tm->save(); // could throw exception
        }

        // cache and return
        self::$TM_ID_CACHE[$lower] = $tm->tm_id;
        return $tm->tm_id;
    }


}
