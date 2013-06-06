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

require_once "mover/AIR2_Writer.php";

/**
 * MySql data importer
 *
 * Imports bulk data into a MySql database using the "LOAD DATA INFILE"
 * command.
 *
 * Example usage:
 *
 *  $db_mapping = array(
 *      'db_table1' => array(
 *          'db_col1' => array(
 *              'map' => 0,               // <-- column of input data to map to
 *          ),
 *          'db_col2' => array(
 *              'val' => 'static value',  // <-- set to static value
 *          ),
 *          'db_col3' => array(
 *              'map' => 1,
 *          ),
 *      ),
 *      'db_table2' => array(
 *          'db_col1' => array(
 *              'map' => 2,
 *          ),
 *      ),
 *  );
 *
 *  $reader = new SomethingReader($params);
 *  $writer = new MySqlImporter('/path/to/directory', $db_mapping);
 *  $num_file = $writer->write_data($reader);
 *  $num_db = $writer->exec_load_data();
 *
 *  echo "Wrote $num_file objects to file\n";
 *  echo "Wrote $num_db objects to database\n";
 *  echo "Encountered ".count($writer->get_errors())." errors\n";
 *
 * @author rcavis
 * @package default
 */
class MySqlImporter extends AIR2_Writer {

    /* temporary output files */
    protected $output_dir;
    protected $outfiles;

    /* mapping from AIR2_Reader */
    protected $db_mapping;

    /* track number of objects written */
    protected $num_written_to_file;

    /* database link identifier */
    protected $mysql;


    /**
     * Constructor
     *
     * Make sure temp-file directory is writable, and use the $db_mapping to
     * infer the number of columns expected in the input data.  (Checks for
     * the largest column 'map'-ed).  The $mysql_link is a resource returned
     * from a call to mysql_connect().  If not provided, the default mysql
     * connection will be used.
     *
     * @param string  $directory
     * @param array   $db_mapping
     * @param resource|Doctrine_Connection $mysql_link
     */
    function __construct($directory, $db_mapping, $mysql_link=null) {
        // check directory existence
        if (!is_dir($directory)) {
            // attemp to create the directory
            if (!mkdir($directory)) {
                throw new Exception("Unable to create directory $directory");
            }
        }

        // make sure directory is writable
        if (!is_writable($directory)) {
            throw new Exception("Unable to write to directory $directory");
        }

        // convert doctrine connection to resource
        if (is_a($mysql_link, 'Doctrine_Connection')) {
            $dsn = $mysql_link->getOption('dsn');
            $usr = $mysql_link->getOption('username');
            $pwd = $mysql_link->getOption('password');
            $m1 = preg_match('/host=\w+/', $dsn, $matches1);
            $m2 = preg_match('/dbname=\w+/', $dsn, $matches2);
            if (!($dsn && $usr && $pwd && $m1 && $m2)) {
                throw new Exception('Unable to parse doctrine connection!');
            }
            $host = preg_replace('/host=/', '', $matches1[0]);
            $dbname = preg_replace('/dbname=/', '', $matches2[0]);

            // create resource
            $mysql_link = mysql_connect($host, $usr, $pwd);
            mysql_select_db($dbname, $mysql_link);
        }

        $this->output_dir = $directory;
        $this->db_mapping = $db_mapping;
        $this->mysql = $mysql_link;
    }


    /**
     * Open temporary files for writing.  These will be named after the
     * database tables you're importing into, and will overwrite any existing
     * files.
     */
    protected function begin_write() {
        $this->num_written_to_file = 0;

        // get files we need to write to (table names in mapping)
        $handles = array();
        foreach ($this->db_mapping as $tbl => $cols) {
            $str_filename = $this->output_dir."/$tbl";
            $handles[$tbl] = fopen($str_filename, 'w');
            if ($handles[$tbl] === false) {
                throw new Exception("Unable to open file $str_filename");
            }
        }
        $this->outfiles = $handles;
    }


    /**
     * Write an object to the temp files, to be imported into the database
     * after the last object is written.  In this case, we ignore $commit,
     * since any actual commits will take place at the end.
     *
     * @param array   $obj
     * @param boolean $commit
     */
    protected function write_object($obj, $commit) {
        foreach ($this->db_mapping as $tbl => $cols) {
            $fh = $this->outfiles[$tbl];
            $line = '';

            foreach ($cols as $name => $def) {
                $val = isset($def['map']) ? $obj[$def['map']] : $def['val'];
                $val = addslashes($val);
                $line .= "\"$val\"\t";
            }

            $line .= "\n";
            fwrite($fh, $line);
        }
        $this->num_written_to_file++;
    }


    /**
     * End the write, closing the temp files and returning the number of rows
     * written to file.  (NOT to database!)
     *
     * @param boolean $cancel
     * @return int total number of items written to file
     */
    protected function end_write($cancel=false) {
        // close the writing handles
        foreach ($this->outfiles as $tbl => $handle) {
            if (!fclose($handle)) {
                $str_filename = $this->output_dir."/$tbl";
                throw new Exception("Unable to close file $str_filename");
            }
        }

        if ($cancel) {
            return 0;
        }
        else {
            return $this->num_written_to_file;
        }
    }


    /**
     * Execute the LOAD DATA INFILE command on the mysql database
     *
     * @return int number of rows successfully written
     */
    public function exec_load_infile() {
        // TODO: handle warnings/errors!
        $loaded_recs = 0;

        foreach ($this->db_mapping as $tbl => $cols) {
            $cmd = $this->_get_infile_command($tbl);

            if ($this->mysql) {
                mysql_query($cmd, $this->mysql);
                $info = mysql_info($this->mysql);
            }
            else {
                mysql_query($cmd); // default mysql link
                $info = mysql_info();
            }

            $info = $this->_parse_mysql_info($info);
            $loaded_recs += $info['Records'];
        }

        return $loaded_recs;
    }


    /**
     * Get the string LOAD DATA INFILE command for a particular table.
     *
     * @param string  $tblname
     * @return string
     */
    private function _get_infile_command($tblname) {
        $file = $this->output_dir."/$tblname";

        // get a comma-separated list of column names
        $cols = '';
        foreach ($this->db_mapping[$tblname] as $name => $def) {
            if (strlen($cols) > 0) {
                $cols .= ", $name";
            }
            else {
                $cols .= $name;
            }
        }

        $opts = "FIELDS ENCLOSED BY '\"' ";
        $cmd = "LOAD DATA LOCAL INFILE '$file' INTO TABLE $tblname $opts ($cols);";
        return $cmd;
    }


    /**
     * Parse a mysql_info() string, to get the numeric parts.
     *
     * @param string  $info_str
     * @return array
     */
    private function _parse_mysql_info($info_str) {
        $info = array();
        preg_match("/Records: ([0-9]+)/", $info_str, $arr);
        $info['Records'] = isset($arr[1]) ? $arr[1] : 0;
        preg_match("/Deleted: ([0-9]+)/", $info_str, $arr);
        $info['Deleted'] = isset($arr[1]) ? $arr[1] : 0;
        preg_match("/Skipped: ([0-9]+)/", $info_str, $arr);
        $info['Skipped'] = isset($arr[1]) ? $arr[1] : 0;
        preg_match("/Warnings: ([0-9]+) /", $info_str, $arr);
        $info['Warnings'] = isset($arr[1]) ? $arr[1] : 0;

        return $info;
    }


}
