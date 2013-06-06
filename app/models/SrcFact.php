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
 * SrcFact
 *
 * A Fact about a Source
 *
 * @property integer $sf_src_id
 * @property integer $sf_fact_id
 * @property integer $sf_fv_id
 * @property string $sf_src_value
 * @property integer $sf_src_fv_id
 * @property boolean $sf_lock_flag
 * @property boolean $sf_public_flag
 * @property integer $sf_cre_user
 * @property integer $sf_upd_user
 * @property timestamp $sf_cre_dtim
 * @property timestamp $sf_upd_dtim
 * @property Source $Source
 * @property Fact $Fact
 * @property FactValue $AnalystFV
 * @property FactValue $SourceFV
 * @author rcavis
 * @package default
 */
class SrcFact extends AIR2_Record {
    /* UUID column to map into a related table */
    private static $UUID_COL = 'Fact:fact_uuid';

    /* cache of fact_identifier for discriminator to overwrite */
    private $_disc_fact_ident = false;
    private static $_DISC_OVERWRITE_FACTS = array('household_income',
        'education_level', 'political_affiliation', 'religion',
        'source_website', 'lifecycle', 'timezone');

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_fact');
        $this->hasColumn('sf_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sf_fact_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sf_fv_id', 'integer', 4, array(
            ));
        $this->hasColumn('sf_src_value', 'string', null, array(
            ));
        $this->hasColumn('sf_src_fv_id', 'integer', 4, array(
            ));
        $this->hasColumn('sf_lock_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sf_public_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sf_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sf_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sf_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sf_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sf_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Fact', array(
                'local' => 'sf_fact_id',
                'foreign' => 'fact_id'
            ));
        $this->hasOne('FactValue as AnalystFV', array(
                'local' => 'sf_fv_id',
                'foreign' => 'fv_id'
            ));
        $this->hasOne('FactValue as SourceFV', array(
                'local' => 'sf_src_fv_id',
                'foreign' => 'fv_id'
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
        // if src_has_acct, start caring about what was changed
        if ($this->Source->src_has_acct == Source::$ACCT_YES) {
            $mods = $this->getModified();

            $bad_mods = array('sf_src_fv_id');
            if ($this->Fact->fact_fv_type != Fact::$FV_TYPE_STR_ONLY) {
                $bad_mods[] = 'sf_src_value';
            }

            // ignore lock, if no bad mods
            $has_bad_mods = false;
            foreach ($bad_mods as $fld) {
                if (isset($mods[$fld])) {
                    $has_bad_mods = true;
                }
            }
            if (!$has_bad_mods) {
                return $this->Source->user_may_write($user, false);
            }
        }

        // normal authz
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
     * Get the mapped-uuid column for this table
     *
     * @return string
     */
    public function get_uuid_col() {
        return SrcFact::$UUID_COL;
    }


    /**
     * Check for existing facts
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param unknown $op   (optional)
     */
    public function discriminate($data, &$tsrc, $op=null) {
        $overwrite_facts = array('household_income', 'education_level',
            'political_affiliation', 'religion', 'source_website', 'lifecycle',
            'timezone');
        $overwrite = false;

        // determine if this SrcFact exists yet
        $id = array('sf_src_id' => $this->sf_src_id, 'sf_fact_id' => $this->sf_fact_id);
        $q = Doctrine_Query::create()->from('SrcFact sf');
        $q->leftJoin('sf.Fact f');
        $q->where('sf_fact_id = ?', $this->sf_fact_id);
        $q->andWhere('sf_src_id = ?', $this->sf_src_id);
        $q->select('sf.*, f.fact_identifier as fident');
        $existing_rec = $q->fetchOne(array(), Doctrine_Core::HYDRATE_ARRAY);
        $q->free();

        if ($existing_rec) {
            $this->_disc_fact_ident = $existing_rec['fident'];
            unset($existing_rec['fident']);
            $this->assignIdentifier($id);
            $this->hydrate($existing_rec);
        }

        // update the record
        parent::discriminate($data, $tsrc, $op);
    }


    /**
     * Overwrite conflicts on some fact types
     *
     * @param string  $field
     * @param mixed   $oldval
     * @param mixed   $newval
     * @return boolean
     */
    protected function disc_is_conflict($field, $oldval, $newval) {
        $isconfl = parent::disc_is_conflict($field, $oldval, $newval);

        // overwrite some fact conflicts
        if ($isconfl && in_array($this->_disc_fact_ident, self::$_DISC_OVERWRITE_FACTS)) {
            $this->$field = $newval;
            return false;
        }

        // birth year sanity check
        if ($isconfl && $this->_disc_fact_ident == 'birth_year') {
            $curr_sane = Fact::birth_year_is_sane($this->$field);
            $tank_sane = Fact::birth_year_is_sane($newval);
            if ($curr_sane && !$tank_sane) {
                return false;
            }
            if (!$curr_sane && $tank_sane) {
                $this->$field = $newval;
                return false;
            }
        }

        // return normal value
        return $isconfl;
    }


    /**
     * Add a conflict to the tank_source
     *
     * @param TankSource $tsrc
     * @param string  $field
     * @param mixed   $oldval
     * @param mixed   $newval
     */
    protected function disc_add_conflict($tsrc, $field, $oldval, $newval) {
        $tsrc->add_conflict('Fact.'.$this->sf_fact_id, $field, 'Conflicting tank value');
    }


}
