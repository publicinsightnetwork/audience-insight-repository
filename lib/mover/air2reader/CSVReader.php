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

require_once "AIR2_Reader.php";
require_once "Encoding.php";
ini_set('auto_detect_line_endings', true);

/**
 * CSV file reader
 *
 * AIR2_Reader that parses csv files.
 *
 * @author rcavis
 * @package default
 */
class CSVReader extends AIR2_Reader {

    /* file information */
    protected $file_str;
    protected $csv_fp;
    protected $line_num;

    /* csv parsing options */
    protected $csv_delim = ',';
    protected $csv_encl = '"';
    protected $csv_skip = false; //skip line 1 (headers)
    protected $lastcol_skip = false; //skip last column


    /**
     * Constructor
     *
     * If $opts is a string, it is assumed to be the $csv_delim character.
     * Otherwise, pass an array with possible keys ('delimiter', 'enclosure',
     * 'header').
     *
     * @param string  $str_file complete file path and name
     * @param array|string $opts     (optional) parsing options
     */
    function __construct($str_file, $opts=null) {
        // set csv reading options
        if (is_string($opts)) {
            $this->csv_delim = $opts;
        }
        elseif (is_array($opts)) {
            if (isset($opts['delimiter']))
                $this->csv_delim = $opts['delimiter'];
            if (isset($opts['enclosure']))
                $this->csv_encl = $opts['enclosure'];
            if (isset($opts['header']))
                $this->csv_skip = $opts['header'];
            if (isset($opts['skiplast']))
                $this->lastcol_skip = $opts['skiplast'];
        }

        // check for a valid, readable file
        if (is_string($str_file) && is_readable($str_file)) {
            $this->file_str = $str_file;
        }
        else {
            throw new Exception('Invalid file');
        }
    }


    /**
     * Open the CSV file for reading.
     */
    protected function begin_read() {
        $this->line_num = 1;

        // rewind or open file pointer
        if ($this->csv_fp) {
            $success = rewind($this->csv_fp);
            if (!$success) $this->csv_fp = false;
        }
        else {
            $this->csv_fp = fopen($this->file_str, 'r');
        }

        // throw an exception if it didn't work
        if (!$this->csv_fp) {
            throw new Exception("Unable to open file ".$this->file_str);
        }
        else {
            if ($this->csv_skip) {
                fgets($this->csv_fp); // skip first line
            }
        }
    }


    /**
     * Read the next object from the resource.  In this case, the 'row' is the
     * row in the csv file, and 'line' returns the line number in the file that
     * the object STARTED on.  (CSV objects may span multiple lines, if they
     * contain newlines).
     *
     * @return array|false
     */
    protected function read_object() {
        $obj = fgetcsv($this->csv_fp, null, $this->csv_delim, $this->csv_encl);
        $num = $this->line_num;

        if (!$obj) {
            return false;
        }
        else {
            // optionally remove the last, probably blank, column
            if (count($obj) && $this->lastcol_skip) {
                array_pop($obj);
            }
            
            // Increment line number, including any newlines in the object.
            // Also check for UTF-8 encoding
            $this->line_num++;
            foreach ($obj as $i => $col) {
                $this->line_num += substr_count($col, "\n");

                if (!Encoding::is_utf8($col)) {
                    $obj[$i] = Encoding::convert_to_utf8($col);
                }
            }
            return array(
                'row' => $this->position + ($this->csv_skip ? 2 : 1),
                'data' => $obj,
                'line' => $num, // extra -- indicates actual line in file
            );
        }
    }


    /**
     * Close the file pointer.
     */
    public function end_read() {
        fclose($this->csv_fp);
        $this->csv_fp = null;
    }


}
