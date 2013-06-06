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
 * SrcAlias
 *
 * A name-alias on a Source
 *
 * @property integer $sa_id
 * @property integer $sa_src_id
 * @property string $sa_name
 * @property string $sa_first_name
 * @property string $sa_last_name
 * @property string $sa_post_name
 * @property integer $sa_cre_user
 * @property integer $sa_upd_user
 * @property timestamp $sa_cre_dtim
 * @property timestamp $sa_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcAlias extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_alias');
        $this->hasColumn('sa_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sa_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sa_name', 'string', 64, array(

            ));
        $this->hasColumn('sa_first_name', 'string', 64, array(

            ));
        $this->hasColumn('sa_last_name', 'string', 64, array(

            ));
        $this->hasColumn('sa_post_name', 'string', 64, array(

            ));
        $this->hasColumn('sa_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sa_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sa_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sa_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sa_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
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
     * Same as write
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


    /**
     * Alias will overwrite existing values without conflict.  For now, only
     * allow a source to have one SrcAlias record.
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    public function discriminate($data, &$tsrc, $op=null) {
        // search for existing
        $q = $this->getTable()->createQuery();
        $q->where('sa_src_id = ?', $this->sa_src_id);
        $existing_rec = $q->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
        if ($existing_rec) {
            $this->assignIdentifier($existing_rec['sa_id']);
            $this->hydrate($existing_rec);
        }

        // call parent
        parent::discriminate($data, $tsrc, $op);
    }


    /**
     * Overwrite conflicts for this table
     *
     * @param string  $field
     * @param mixed   $oldval
     * @param mixed   $newval
     * @return boolean
     */
    protected function disc_is_conflict($field, $oldval, $newval) {
        $isconfl = parent::disc_is_conflict($field, $oldval, $newval);

        // overwrite
        if ($isconfl && in_array($field, self::$DISC_CASE_INSENSITIVE_FLDS)) {
            $this->$field = $newval;
            return false;
        }

        // return normal value
        return $isconfl;
    }


}
