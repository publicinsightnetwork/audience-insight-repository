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

require_once 'CSVCodeMapper.php';

/**
 * AIR2 CSVExporter
 *
 * For now, just some helper functions for getting a Doctrine Query that fetches
 * data backwards-compatible with the CSVImporter.
 *
 * @author rcavis
 * @package default
 */
class CSVExporter {
    private static $INI_FILE = 'csv_columns.ini';

    /* cached ini file */
    protected $ini;

    /* cached db values */
    protected $code_master;
    protected $state;
    protected $country;
    protected $fact;
    protected $fact_value;

    /**
     * Constructor
     *
     * Parse configuration file and cache some DB tables
     *
     * @param boolean $less_facts (optional) false to create full fact csv
     */
    public function __construct($less_facts=true) {
        $this->ini = parse_ini_file(self::$INI_FILE, true);

        // remove some of the secondary fact fields
        if ($less_facts) {
            foreach ($this->ini as $header => $def) {
                if (preg_match('/ Src Map$/', $header)) {
                    unset($this->ini[$header]);
                }
                elseif (preg_match('/ Src Text$/', $header)) {
                    unset($this->ini[$header]);
                }
            }
        }

        // cache code_master
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchAll('select cm_field_name, cm_code, cm_disp_value '.
            'from code_master where cm_status = ?', array(CodeMaster::$STATUS_ACTIVE));
        foreach ($rs as $row) {
            $fld = $row['cm_field_name'];
            $code = $row['cm_code'];
            $disp = $row['cm_disp_value'];
            if (!isset($this->code_master[$fld])) {
                $this->code_master[$fld] = array($code => $disp);
            }
            else {
                $this->code_master[$fld][$code] = $disp;
            }
        }

        // cache state
        $rs = $conn->fetchAll('select state_code, state_name from state');
        foreach ($rs as $row) {
            $this->state[$row['state_code']] = $row['state_name'];
        }

        // cache country
        $rs = $conn->fetchAll('select cntry_code, cntry_name from country');
        foreach ($rs as $row) {
            $this->country[$row['cntry_code']] = $row['cntry_name'];
        }

        // cache fact
        $rs = $conn->fetchAll('select fact_id, fact_identifier from fact');
        foreach ($rs as $row) {
            $this->fact[$row['fact_identifier']] = $row['fact_id'];
        }

        // cache fact_value
        $rs = $conn->fetchAll('select fv_id, fv_value from fact_value');
        foreach ($rs as $row) {
            $this->fact_value[$row['fv_id']] = $row['fv_value'];
        }
    }


    /**
     * Get the header for the CSV
     *
     * @return array
     */
    public function get_headers() {
        return array_keys($this->ini);
    }


    /**
     * Format multi-dimensional radix data into flat CSV format.
     *
     * @param array   $data
     * @return array
     */
    public function format_data($data) {
        foreach ($data as $idx => $row) {
            $data[$idx] = $this->format_row($row);
        }
        return $data;
    }


    /**
     * Helper function to format a multidimensional row of data, mapping fields
     * into an importable csv format.  Returns a flat array.
     *
     * @param array   $row
     * @return string
     */
    protected function format_row($row) {
        $flattened = array();
        $colnum = 0;

        // flatten source info
        foreach ($this->ini as $header => $def) {
            if (isset($def['tank_fld'])) {
                // Handle source contact info
                $value = $this->find_field($def['tank_fld'], $row);
                if ($value) {
                    if (isset($def['map'])) {
                        if ($def['map'] == 'code_master') {
                            $map = $this->code_master[$def['tank_fld']];
                            $flattened[$colnum] = isset($map[$value]) ? $map[$value] : $value;
                        }
                        elseif ($def['map'] == 'state') {
                            // NOTE: can't trust these values
                            $flattened[$colnum] = isset($this->state[$value])
                                ? $this->state[$value] : $value;
                        }
                        elseif ($def['map'] == 'country') {
                            $flattened[$colnum] = isset($this->country[$value])
                                ? $this->country[$value] : $value;
                        }
                    }
                    else {
                        $flattened[$colnum] = $value;
                    }
                }
            }
            elseif (isset($def['fact']) && isset($row['SrcFact'])) {
                // Handle facts
                $fact_id = $this->fact[$def['fact']];

                // search this rows facts for the fact_id
                foreach ($row['SrcFact'] as $sf) {
                    if ($sf['sf_fact_id'] == $fact_id) {
                        // grab the correct column
                        $value = $sf[$def['tank_fact_fld']];

                        // translate fact_values
                        if (isset($def['map']) && $def['map'] == 'fact_value') {
                            // take either the analyst or source FV
                            $fv_id = isset($sf['sf_fv_id']) ? $sf['sf_fv_id'] : $sf['sf_src_fv_id'];
                            if ($fv_id) {
                                $value = $this->fact_value[$fv_id];
                            }
                        }

                        // set data
                        $flattened[$colnum] = $value;
                        break;
                    }
                }
            }

            if (!isset($flattened[$colnum])) $flattened[$colnum] = null;
            $colnum++;
        }
        return $flattened;
    }


    /**
     * Recursively searches for the value of a field within an array.  Returns
     * the value of the first array key $name it encounters, or NULL if not
     * found.
     *
     * @param string  $name
     * @param array   $data
     * @return mixed
     */
    protected function find_field($name, $data) {
        if (isset($data[$name])) return $data[$name];

        // recursive search
        foreach ($data as $key => $val) {
            if (is_array($val)) {
                $find = $this->find_field($name, $val);
                if ($find) return $find;
            }
        }
        return null;
    }


}
