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

require_once 'air2reader/CSVReader.php';
require_once 'CSVCodeMapper.php';
require_once 'CSVRowPadder.php';
require_once 'HasIdentValidator.php';
require_once 'CSVYamlWriter.php';

/**
 * AIR2 CSVImporter
 *
 * Parse a CSV file, and figure out how to get the data into the AIR2
 * tank_source table.  This includes validating the CSV, and aborting if the
 * entire CSV cannot be crammed into tank_source (and it's related tables).
 *
 * @author rcavis
 * @package default
 */
class CSVImporter {
    private static $INI_FILE = 'csv_columns.ini';
    private static $MAX_ERRS = 5; // maximum errors to allow returned

    /* cached ini file */
    protected $config;

    /* Tank record to import */
    protected $tank;

    /* cached csv headers */
    protected $header_cache;
    protected $ident_columns = array('Username', 'Email Address');
    
    /* ignore a blank last-column of a csv */
    protected $ignore_last_col = false;


    /**
     * Constructor
     *
     * Parse configuratin file and sanity check
     *
     * @param unknown $t (reference)
     */
    public function __construct(Tank &$t) {
        //sanity check the tank
        if ($t->tank_type != Tank::$TYPE_CSV) {
            throw new Exception('Tank record not of type CSV');
        }
        $this->tank = $t;
        $this->config = parse_ini_file(self::$INI_FILE, true);
    }


    /**
     * Make sure the csv file has valid headers.  The column headers must exist
     * in the ini file, be unique, and there must be an ident column.  Returns
     * true if it's valid, otherwise a string validation error.
     *
     * @return string|true
     */
    public function validate_headers() {
        $rdr = $this->get_csv_reader(false);

        // read the first line
        $has_ident = false;
        $invalid_headers = array();
        $this->header_cache = array();
        foreach ($rdr as $idx => $line) {
            $last_colnum = count($line['data']) - 1;
            foreach ($line['data'] as $colnum => $hdr_name) {
                if (isset($this->config[$hdr_name])) {
                    // check for required identifier (username or email)
                    if (in_array($hdr_name, $this->ident_columns)) {
                        $has_ident = true;
                    }

                    // check for duplicate columns
                    if (!in_array($hdr_name, $this->header_cache)) {
                        $this->header_cache[] = $hdr_name;
                    }
                    else {
                        return "Duplicate column header '$hdr_name'";
                    }
                }
                elseif (!$hdr_name && $colnum == $last_colnum) {
                    // just ignore this blank column
                    $this->ignore_last_col = true;
                }
                else {
                    $invalid_headers[] = $hdr_name;
                }
            }
            break;
        }

        if (!$has_ident) {
            $cols = implode(' or ', $this->ident_columns);
            return "$cols column is required!";
        }
        elseif (count($invalid_headers) > 0) {
            $str = "Invalid column headers: ";
            $str .= implode(', ', $invalid_headers);
            return $str;
        }
        else {
            return true;
        }
    }


    /**
     * Returns a preview of the csv file.  The returned array will have indexes
     * 'header' and 'lines', with each item in the header having indexes 'name'
     * and 'valid'.
     *
     * @param int     $num_lines
     * @return array
     */
    public function preview_file($num_lines=3) {
        $this->validate_headers();
        $rdr = $this->get_csv_reader(false);

        // get header and preview
        $header = array();
        $lines = array();
        foreach ($rdr as $idx => $line) {
            // header
            if ($idx == 0) {
                foreach ($line['data'] as $val) {
                    $header[] = array(
                        'name' => $val,
                        'valid' => isset($this->config[$val]),
                    );
                }
            }
            else {
                $lines[] = $line['data'];
                if (count($lines) >= $num_lines) break;
            }
        }
        return array('header' => $header, 'lines' => $lines);
    }


    /**
     * Get a line count of a csv file, stopping at a certain line to make sure
     * we don't spend forever parsing a big csv.
     *
     * @param int     $max_count
     * @return int
     */
    public function get_line_count($max_count=1000) {
        $rdr = $this->get_csv_reader(true);
        $num = 0;
        foreach ($rdr as $line) {
            $num++;
            if ($num > $max_count) return false;
        }
        return $num;
    }


    /**
     * Attempt to import a CSV file into TankSource and related tables.  Returns
     * an integer number of rows imported on success, or a string error message
     * on failure.
     *
     * @return int|string
     */
    public function import_file() {
        // check tank_status
        $s = $this->tank->tank_status;
        if (!in_array($s, array(Tank::$STATUS_CSV_NEW))) {
            return 'Tank record not in an importable tank_status';
        }

        // validate headers (also caches them)
        $valid = $this->validate_headers();
        if ($valid !== true) return $valid;

        // change the tank status
        $this->tank->tank_status = Tank::$STATUS_LOCKED;
        $this->tank->save();

        // setup the mutator to map values/codes
        $mut = new CSVCodeMapper($this->header_cache, $this->config);
        $mut2 = new CSVRowPadder(count($this->header_cache));
        $rdr = $this->get_csv_reader(true);
        $rdr->add_mutator($mut);
        $rdr->add_mutator($mut2);

        // write the yaml file(s)
        $writer = new CSVYamlWriter($this->tank, $this->config, $this->header_cache);
        $writer->set_mode(true, 5); // max 5 errors

        // catch any 'mover' exceptions thrown by the reader
        $errs = array();
        try {
            $ident = new HasIdentValidator($this->header_cache, $this->ident_columns);
            $num = $writer->write_data($rdr, array($ident));
            $errs = $writer->get_errors();
        }
        catch (AIR2_MoverException $e) {
            $errs[] = $e;
        }

        // return any errors as a single string
        if (count($errs) > 0) {
            $this->tank->tank_status = Tank::$STATUS_CSV_NEW;
            $this->tank->save();

            $msg = '';
            foreach ($errs as $e) {
                $msg .= (strlen($msg)) ? ', '.$e->getMessage() : $e->getMessage();
            }
            return 'Failed to import with '.count($errs).' errors: '.$msg;
        }
        else {
            try {
                $writer->load_yaml(); //TODO: how to count this?
                $this->tank->tank_status = Tank::$STATUS_READY;
                $this->tank->save();
                return $num;
            }
            catch (Exception $e) {
                $this->tank->tank_status = Tank::$STATUS_CSV_NEW;
                $this->tank->save();
                return 'Error while loading YAML file! - '.$e->getMessage();
            }
        }
    }


    /**
     * Get a CSV reader for this csv file.
     *
     * @param boolean $skip_headers
     * @param boolean $skip_last_col
     * @return CSVReader
     */
    protected function get_csv_reader($skip_headers=true) {
        $opts = array('header' => $skip_headers);

        // check metadata for csv delimiter and enclosure
        $del = $this->tank->get_meta_field('csv_delim');
        if ($del) $opts['delimiter'] = $del;
        $enc = $this->tank->get_meta_field('csv_encl');
        if ($enc) $opts['enclosure'] = $enc;

        // skip last blank-column
        if ($this->ignore_last_col) {
            $opts['skiplast'] = true;
        }

        return new CSVReader($this->tank->get_file_path(), $opts);
    }


}
