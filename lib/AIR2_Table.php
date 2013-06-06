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


/**
 * AIR2_Table base class
 *
 * @author rcavis
 * @package default
 */
class AIR2_Table extends Doctrine_Table {
    /* track any relation-aliases that should NOT be exported */
    protected $no_export = array();


    /**
     * Override bind() to check for an 'export' key in the hasOne/hasMany
     * options.  If set to FALSE, Doctrine will not set a foreign key for that
     * relationship.  For example:
     *
     *  $this->hasOne('Foo as Foobar', array(
     *      'local'   => 'bar_foo_id',
     *      'foreign' => 'foo_id',
     *      'export'  =>  false,
     *  );
     *
     * NOTE: because Doctrine_Table->bind() doesn't return the results of the
     * Parser->bind(), we need to bypass the parent class method entirely.
     *
     * @param array   $args
     * @param integer $type
     */
    public function bind($args, $type) {
        $options = (!isset($args[1])) ? array() : $args[1];
        $options['type'] = $type;
        $rel = $this->_parser->bind($args[0], $options);

        if (isset($rel['export']) && $rel['export'] === false) {
            $this->no_export[] = $rel['alias'];
        }
        parent::bind($args, $type);
    }


    /**
     * Before returning the exportable-version of this table, unset any foreign
     * keys that had the option "export => false".
     *
     * @param bool    $parseForeignKeys
     * @return array
     */
    public function getExportableFormat($parseForeignKeys = true) {
        $data = parent::getExportableFormat($parseForeignKeys);

        // unset any fk's that we shouldn't export
        foreach ($this->no_export as $rel_alias) {
            $key_name = $this->getRelation($rel_alias)->getForeignKeyName();
            unset($data['options']['foreignKeys'][$key_name]);
        }
        return $data;
    }


}
