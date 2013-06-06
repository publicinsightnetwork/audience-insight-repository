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
 * Validator for CSV uploads of manual-entry submissions.
 *
 * @author rcavis
 * @package default
 */
class ManualEntryValidator extends AIR2_Validator {
    /* does this CSV even have manual entry columns? */
    protected $has_me_columns = false;

    /* only return column-missing errors once */
    protected $column_missing_error = false;
    protected $has_returned_missing_error = false;

    /* which manual-entry columns are present in the input data */
    protected $mapping = array();

    /* valid types */
    protected $valid_types = array();

    /* indexes for relevant columns */
    protected $datecol = false;
    protected $typecol = false;
    protected $desccol = false;
    protected $textcol = false;


    /**
     * Constructor
     *
     * @param array   $headers
     * @param array   $ini
     */
    function __construct($headers, $ini) {
        // look for manual-entry columns
        foreach ($headers as $idx => $col) {
            if (isset($ini[$col]) && isset($ini[$col]['manual_entry'])) {
                $me_type = $ini[$col]['manual_entry'];
                $this->mapping[$me_type] = $idx;
                $this->has_me_columns = true;
            }
        }

        // get valid manual-entry types from Inquiry
        foreach (Inquiry::$MANUAL_TYPES as $code => $def) {
            $this->valid_types[] = $def['label'];
        }

        // trigger validation
        $this->validate_headers();
    }


    /**
     * Validate header information set by the constructor mapping
     *
     * @return string|true
     */
    public function validate_headers() {
        // get column indexes (or null if not present in the header)
        $this->datecol = isset($this->mapping['date']) ? $this->mapping['date'] : null;
        $this->typecol = isset($this->mapping['type']) ? $this->mapping['type'] : null;
        $this->desccol = isset($this->mapping['desc']) ? $this->mapping['desc'] : null;
        $this->textcol = isset($this->mapping['text']) ? $this->mapping['text'] : null;

        // missing a column is a FATAL error!
        if (!($this->datecol && $this->typecol && $this->desccol && $this->textcol)) {
            $missing = array();
            if (!$this->datecol) $missing[] = 'date';
            if (!$this->typecol) $missing[] = 'type';
            if (!$this->desccol) $missing[] = 'description';
            if (!$this->textcol) $missing[] = 'text';
            $missing = implode(', ', $missing);
            $missing = "Missing required submission columns: $missing";

            // cause a validation error
            $this->column_missing_error = $missing;
            $this->break_on_failure = true;
            return $missing;
        }

        // valid headers
        return true;
    }


    /**
     * Helper function to extract submission data from a CSV row
     *
     * @param string  $name
     * @param array   $row
     * @return string data
     */
    public function extract($name, $row) {
        if ($name == 'date') {
            return $row[$this->datecol];
        }
        elseif ($name == 'type') {
            return $row[$this->typecol];
        }
        elseif ($name == 'desc') {
            return $row[$this->desccol];
        }
        elseif ($name == 'text') {
            return $row[$this->textcol];
        }
        else {
            throw new Exception("Invalid name $name");
        }
    }


    /**
     * Make sure we have enough info to create a manual-entry submission.
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $errors = array();

        // anything to do?
        if (!$this->has_me_columns) {
            return true;
        }

        // don't validate if a column is missing in the header
        if ($this->column_missing_error) {
            if ($this->has_returned_missing_error) {
                return true;
            }
            $this->has_returned_missing_error = true;
            return $this->column_missing_error;
        }

        // date must parse to something
        if (!strtotime($this->extract('date', $data))) {
            $errors[] = "bad date";
        }

        // type must be valid string
        if (!in_array($this->extract('type', $data), $this->valid_types)) {
            $errors[] = "invalid type";
        }

        // desc and text must have a length
        if (strlen($this->extract('desc', $data)) < 1) {
            $errors[] = "description required";
        }
        if (strlen($this->extract('text', $data)) < 1) {
            $errors[] = "text value required";
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
