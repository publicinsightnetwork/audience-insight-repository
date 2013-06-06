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
 * SrcMailAddress
 *
 * Mailing address for a Source
 *
 * @property integer $smadd_id
 * @property string $smadd_uuid
 * @property integer $smadd_src_id
 * @property boolean $smadd_primary_flag
 * @property string $smadd_context
 * @property string $smadd_line_1
 * @property string $smadd_line_2
 * @property string $smadd_city
 * @property string $smadd_state
 * @property string $smadd_cntry
 * @property string $smadd_zip
 * @property float $smadd_lat
 * @property float $smadd_long
 * @property string $smadd_status
 * @property integer $smadd_cre_user
 * @property integer $smadd_upd_user
 * @property timestamp $smadd_cre_dtim
 * @property timestamp $smadd_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcMailAddress extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $CONTEXT_HOME = 'H';
    public static $CONTEXT_WORK = 'W';
    public static $CONTEXT_OTHER = 'O';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_mail_address');
        $this->hasColumn('smadd_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('smadd_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('smadd_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('smadd_primary_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('smadd_context', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('smadd_line_1', 'string', 128, array(

            ));
        $this->hasColumn('smadd_line_2', 'string', 128, array(

            ));
        $this->hasColumn('smadd_city', 'string', 128, array(

            ));
        $this->hasColumn('smadd_state', 'string', 2, array(
                'fixed' => true,
            ));
        $this->hasColumn('smadd_cntry', 'string', 2, array(
                'fixed' => true,
            ));
        $this->hasColumn('smadd_zip', 'string', 10, array(

            ));
        $this->hasColumn('smadd_county', 'string', 128, array(

            ));
        $this->hasColumn('smadd_lat', 'float', null, array(

            ));
        $this->hasColumn('smadd_long', 'float', null, array(

            ));
        $this->hasColumn('smadd_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('smadd_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('smadd_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('smadd_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('smadd_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'smadd_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read(User $user) {
        return $this->Source->user_may_read($user);
    }


    /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write(User $user) {
        return $this->Source->user_may_write($user);
    }


    /**
     * Same as writing
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


    /**
     * Make sure the source doesn't get duplicate addresses
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param unknown $op   (optional)
     */
    public function discriminate($data, &$tsrc, $op=null) {
        // search for existing
        if ($op != AIR2_DISCRIM_ADD) {
            $q = $this->getTable()->createQuery();
            $q->where('smadd_src_id = ?', $this->smadd_src_id);

            // ID existing by line_1, city, or zip
            $subqry = array();
            $params = array();
            if (isset($data['smadd_line_1'])) {
                $subqry[] = 'smadd_line_1 = ?';
                $params[] = $data['smadd_line_1'];
            }
            if (isset($data['smadd_city'])) {
                $subqry[] = 'smadd_city = ?';
                $params[] = $data['smadd_city'];
            }
            if (isset($data['smadd_zip'])) {
                $subqry[] = 'smadd_zip = ?';
                $params[] = $data['smadd_zip'];
            }
            $subqry = implode(' OR ', $subqry);
            if ($subqry) {
                $q->andWhere("($subqry)", $params);
                $existing_rec = $q->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
                if ($existing_rec) {
                    $this->assignIdentifier($existing_rec['smadd_id']);
                    $this->hydrate($existing_rec);
                }
            }
            $q->free(); //cleanup
        }

        // just set primary --- actual logic in postsave hook
        if (isset($data['smadd_primary_flag'])) {
            $this->smadd_primary_flag = $data['smadd_primary_flag'];
            unset($data['smadd_primary_flag']);
        }

        // set remaining data with parent
        parent::discriminate($data, $tsrc, $op);
    }


    /**
     * Make sure we only have 1 primary
     *
     * @param Doctrine_Event $event
     */
    public function postSave($event) {
        air2_fix_src_primary($this);
        parent::postSave($event);
    }


    /**
     * Look for a primary after delete
     *
     * @param DoctrineEvent $event
     */
    public function preDelete($event) {
        air2_fix_src_primary($this, true);
        parent::preDelete($event);
    }


    /**
     * Override save() to dump to std_err
     *
     * @param object  $conn (optional)
     * @return return value from parent::save($conn)
     */
    public function save(Doctrine_Connection $conn=null) {
        if (    strlen($this->smadd_zip) 
            &&  strlen($this->smadd_zip) < 5
            &&  preg_match('/^\d+$/', $this->smadd_zip)    
        ) {
            $this->smadd_zip = '0' . $this->smadd_zip;
        }
        $ret = parent::save($conn);

        return $ret;
    }


}
