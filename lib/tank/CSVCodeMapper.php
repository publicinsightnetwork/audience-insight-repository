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

require_once 'mover/AIR2_Mutator.php';

/**
 * AIR2 CSVCodeMapper
 *
 * Mutator for parsing mapped fields in a CSV.
 *
 * @author rcavis
 * @package default
 */
class CSVCodeMapper implements AIR2_Mutator {

    // match free form vals
    protected $lang_map = array('English' => 'en_US', 'Spanish' => 'es_US');


    /* cache ini file mapping */
    protected $mapping = array();

    /**
     * Constructor - finds what fields it needs to mapped based on an array of
     * header columns (from the CSV to process) and the csv ini file.
     *
     * @param array   $columns
     * @param array   $ini
     */
    public function __construct($columns, $ini) {
        // build any db mapping required
        foreach ($columns as $idx => $col) {
            // check for column existence in mapping
            if (!isset($ini[$col])) {
                $this->mapping[$idx] = null;
                continue; // column not mapped
            }

            $cfg = $ini[$col];
            if (isset($cfg['map'])) {
                // get correct type of mapping
                if (isset($cfg['tank_fld'])) {
                    $map = $this->get_tank_mapping($cfg['map'], $cfg['tank_fld']);
                    $this->mapping[$idx] = $map;
                }
                elseif (isset($cfg['tank_fact_fld'])) {
                    $map = $this->get_fact_mapping($cfg['fact']);
                    $this->mapping[$idx] = $map;
                }
                elseif (isset($cfg['tank_pref_fld'])) {
                    $map = $this->get_pref_mapping($cfg['pref']);
                    $this->mapping[$idx] = $map;
                }
                else {
                    throw new Exception("UNKNOWN MAP FIELD IN -> $col");
                }
            }
            else {
                $this->mapping[$idx] = false; // no mapping
            }
        }
    }


    /**
     * Creates the mapping for a non-fact CSV column.
     *
     * @param string  $mapto
     * @param string  $field
     * @return array mapping
     */
    protected function get_tank_mapping($mapto, $field) {
        $rs = array();
        if ($mapto == 'code_master') {
            $q = Doctrine_Query::create()->from('CodeMaster');
            $q->addWhere('cm_field_name = ?', $field);
            $q->addWhere('cm_status = ?', CodeMaster::$STATUS_ACTIVE);
            $q->addOrderBy('cm_disp_seq ASC');
            $q->select('cm_code as code, cm_disp_value as value');
            $rs = $q->fetchArray();
        }
        elseif ($mapto == 'state') {
            $q = Doctrine_Query::create()->from('State');
            $q->select('state_code as code, state_name as value');
            $rs = $q->fetchArray();
        }
        elseif ($mapto == 'country') {
            $q = Doctrine_Query::create()->from('Country');
            $q->select('cntry_code as code, cntry_name as value');
            $rs = $q->fetchArray();
        }
        else {
            throw new Exception("Unknown csv ini mapping: $mapto");
        }

        // turn into associative array
        $map = array();
        foreach ($rs as $val) {
            // lowercase disp values
            $map[$val['code']] = strtolower($val['value']);
        }
        return $map;
    }


    /**
     * Creates the mapping for a fact CSV column.
     *
     * @param string  $fact_ident
     * @return array mapping
     */
    protected function get_fact_mapping($fact_ident) {
        $q = Doctrine_Query::create()->from('FactValue fv');
        $q->leftJoin('fv.Fact f');
        $q->addWhere('f.fact_identifier = ?', $fact_ident);
        $q->addWhere('fv.fv_status = ?', FactValue::$STATUS_ACTIVE);
        $q->addOrderBy('fv.fv_seq ASC');
        $q->select('fv_value, fv_id');
        $rs = $q->fetchArray();

        $map = array();
        foreach ($rs as $fv) {
            // lowercase disp values
            $map[$fv['fv_id']] = strtolower($fv['fv_value']);
        }
        return $map;
    }

    /**
     * Creates the mapping for a pref CSV column.
     *
     * @param string  $pref_ident
     * @return array mapping
     */
    protected function get_pref_mapping($pref_ident) {
        $q = Doctrine_Query::create()->from('PreferenceTypeValue ptv');
        $q->leftJoin('ptv.PreferenceType pt');
        $q->addWhere('pt.pt_identifier = ?', $pref_ident);
        $q->addWhere('ptv.ptv_status = ?', PreferenceTypeValue::$STATUS_ACTIVE);
        $q->addOrderBy('ptv.ptv_seq ASC');
        $q->select('ptv_value, ptv_id');
        $rs = $q->fetchArray();

        $map = array();
        foreach ($rs as $ptv) {
            // lowercase disp values
            $map[$ptv['ptv_id']] = strtolower($ptv['ptv_value']);
        }
        return $map;
    }

    /**
     * Mutate CSV data to map code values
     *
     * @param array   $data the row data
     * @param int     $idx  the row index
     * @return array $data the mutated row data
     */
    public function mutate($data, $idx) {
        foreach ($data as $colnum => $val) {
            // skip blank values
            if ($val) {
                if ($this->mapping[$colnum]) {
                    $map = $this->mapping[$colnum];
                    if (!isset($map[$val])) {
                        // only worry about vals that aren't already mapped
                        $code = array_search(strtolower($val), $map);
                        if ($code !== false) {
                            $data[$colnum] = $code;
                        }
                        else if (array_key_exists($val, $this->lang_map)) {
                            // special treatment for English/Spanish
                            $data[$colnum] = array_search(strtolower($this->lang_map[$val]), $map);
                        }
                        else {
                            // unable to map!  abort reading csv!
                            $row = $idx + 2; //skip header
                            $col = $colnum + 1; //1-indexed
                            throw new AIR2_MoverException("Bad mapped value '$val' in column $col row $row");
                        }
                    }
                }
            }
        }
        return $data;
    }


}
