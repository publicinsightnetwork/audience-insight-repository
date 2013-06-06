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
 * Validator for the number of columns in an object.
 *
 * @author rcavis
 * @package default
 */
class FactTranslationValidator extends AIR2_Validator {

    /* which facts are present in the input data */
    protected $mapping = array();

    /* headers for error output */
    protected $headers;


    /**
     * Constructor
     *
     * @param array   $fact_mapping
     * @param array   $headers
     */
    function __construct($fact_mapping, $headers) {
        $this->headers = $headers;

        // figure out which csv columns are translates/raw-values.
        foreach ($fact_mapping as $fact_id => $def) {
            $from_column = -1;
            $to_column = -1;
            foreach ($def as $colidx => $mapto) {
                if ($mapto == 'sf_src_value') {
                    $from_column = $colidx;
                }
                elseif ($mapto == 'sf_fv_id') {
                    $to_column = $colidx;
                }
            }

            // only look at facts that have both "from" and "to" mapped
            if ($from_column >= 0 && $to_column >= 0) {
                $this->mapping[$fact_id] = array(
                    'trans_from' => $from_column,
                    'trans_to'   => $to_column,
                );
            }
        }
    }


    /**
     * Check for translations of sf_src_value (text) that with an explicitly
     * set sf_fv_id.
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $errors = array();

        // look for facts
        foreach ($this->mapping as $fact_id => $def) {
            $from = $data[$def['trans_from']];
            $to = $data[$def['trans_to']];

            // if both are set, make sure they don't conflict
            if ($from && strlen($from) && $to && strlen($to)) {
                $fv_id = TranslationMap::find_translation($fact_id, $from);
                if ($fv_id && $fv_id != $to) {
                    $confl = $this->headers[$def['trans_from']].' and '.$this->headers[$def['trans_to']];
                    $errors[] = "(conflicting translated value between $confl)";
                }
            }
        }

        // combine any errors to return
        if (count($errors) > 0) {
            return "Errors on row $row: " . implode(', ', $errors);
        }
        else {
            return true;
        }
    }


}
