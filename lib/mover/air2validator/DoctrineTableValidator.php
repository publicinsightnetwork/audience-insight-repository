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

require_once 'AIR2_Validator.php';

/**
 * Validator to hook into Doctrine models, and call their validation methods.
 *
 * @author rcavis
 * @package default
 */
class DoctrineTableValidator extends AIR2_Validator {

    /* table def */
    protected $table_cache = array();
    protected $record_cache = array();
    protected $col_mapping = array();


    /**
     * Constructor
     *
     * The column map should containing a mapping of column numbers (as found
     * in the validating objects) to doctrine tables and fields.  For instance:
     *
     *  $col_map = array(
     *      0 => 'Source:src_first_name',
     *      1 => 'Source:src_last_name',
     *      2 => 'ModelName:field_name',
     *  );
     *  new DoctrineTableValidator($col_map);
     *
     * @param array   $col_map
     */
    function __construct($col_map) {
        foreach ($col_map as $idx => $str) {
            $parts = explode(':', $str);
            $tbl_name = $parts[0];
            $fld_name = $parts[1];

            // cache references to the tables we're going to need
            if (!isset($this->table_cache[$tbl_name])) {
                $this->table_cache[$tbl_name] = Doctrine::getTable($tbl_name);
                $this->record_cache[$tbl_name] = $this->table_cache[$tbl_name]->getRecord();
            }

            // store the column mapping
            $this->col_mapping[$idx] = array(
                'tbl' => $tbl_name,
                'fld' => $fld_name,
            );
        }
    }


    /**
     * Call Doctrine validation
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $errors = array();
        foreach ($this->col_mapping as $idx => $map) {
            $tbl = $this->table_cache[$map['tbl']];
            $rec = $this->record_cache[$map['tbl']];
            $data[$idx] = $this->pre_clean_value($map['fld'], $data[$idx]);
            $errstack = $tbl->validateField($map['fld'], $data[$idx], $rec);

            // get all the errors for this field
            foreach ($errstack as $fld => $errs) {
                $colnum = $idx + 1;
                $errors[] = "(column $colnum - $fld ".implode(',', $errs).')';
            }
            $errstack->clear();
        }

        // combine any errors to return
        if (count($errors) > 0) {
            return "Errors on row $row: " . implode(', ', $errors);
        }
        else {
            return true;
        }
    }

    /**
     * Strip out white space and special characters, from phone numbers, etc
     * 
     * @param string $field
     * @param string $value
     * @return string
     */
    public function pre_clean_value($field, $value) {
        if ($field == 'sph_number') {
            $value = preg_replace('/\D/', '', $value);
        }
        return $value;
    }
}
