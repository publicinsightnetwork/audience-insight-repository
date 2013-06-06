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

require_once "AIR2_Writer.php";
require_once DOCPATH."Doctrine/Parser/sfYaml/sfYamlDumper.php";

/**
 * Yaml Data Importer
 *
 * Imports bulk data into a database by writing first to YAML files, and then
 * loading those files using Doctrine.  This can be slightly slow, but if you
 * need to insert into multiple related tables, it's the way to go.
 *
 * Example usage:
 *
 *  $config = array(
 *      'DoctrineModelName1' => array(
 *          'field1' =>  array(
 *              'map' => 0,               // <-- column of input data to map to
 *          ),
 *          'field2' => array(
 *              'val' => 'static value',  // <-- set to static value
 *          ),
 *          'field3' => array(
 *              'map' => 1,
 *          ),
 *      ),
 *      'DoctrineModelName2' => array(
 *          'field1' => array(
 *              'map' => 2,
 *          ),
 *      ),
 *  );
 *
 *  $reader = new SomethingReader($params);
 *  $writer = new YamlWriter('/path/to/directory', $config);
 *  $num_file = $writer->write_data($reader);
 *  $writer->load_yaml();
 *
 *  echo "Wrote $num_file objects to file\n";
 *  echo "Encountered ".count($writer->get_errors())." errors\n";
 *
 * @author rcavis
 * @package default
 */
class YamlWriter extends AIR2_Writer {

    /* temporary output files */
    protected $output_dir;
    protected $outfiles;
    protected $outcounts;

    /* mapping from AIR2_Reader */
    protected $config;

    /* track number of objects written */
    protected $num_written_to_file;

    /* yaml dumper helper */
    protected $dumper;


    /**
     * Constructor
     *
     * Make sure temp-file directory is writable.
     *
     * @param string  $directory
     * @param array   $config
     */
    function __construct($directory, $config) {
        // check directory existence
        air2_rmdir($directory); // clean any old files
        if (!air2_mkdir($directory)) {
            throw new Exception("Unable to create directory $directory");
        }

        // make sure directory is writable
        if (!is_writable($directory)) {
            throw new Exception("Unable to write to directory $directory");
        }

        $this->output_dir = $directory;
        $this->config = $config;

        // create a yaml dumper
        $this->dumper = new sfYamlDumper();
    }


    /**
     * Open temporary files for writing.  These will be named after the
     * database tables you're importing into, and will overwrite any existing
     * files.
     */
    protected function begin_write() {
        $this->num_written_to_file = 0;
        $this->outcounts = array();

        // get files we need to write to (model names in mapping)
        $handles = array();
        foreach ($this->config as $modelname => $fields) {
            $str_filename = $this->output_dir."/$modelname.yml";
            $handles[$modelname] = fopen($str_filename, 'w');
            if ($handles[$modelname] === false) {
                throw new Exception("Unable to open file $str_filename");
            }

            // start the yaml file with the model name
            fwrite($handles[$modelname], "$modelname:\n");

            // start counts at 0
            $this->outcounts[$modelname] = 0;
        }
        $this->outfiles = $handles;
    }


    /**
     * Write an object to the yaml files, to be imported into the database
     * after the last object is written.  In this case, we ignore $commit,
     * since any actual commits will take place at the end.
     *
     * @param array   $obj
     * @param boolean $commit
     */
    protected function write_object($obj, $commit) {
        foreach ($this->config as $modelname => $fields) {
            $num = $this->num_written_to_file;

            // get a yaml-data array for this model
            $yml = $this->get_yaml_data($obj, $modelname, $num, $fields);
            if ($yml) {
                $this->write_yaml($yml, $modelname);
            }
        }
        $this->num_written_to_file++;
    }


    /**
     * Write a Yaml object to the appropriate file
     *
     * @param array   $obj       data to write
     * @param array   $modelname model to write to
     * @param int     $idx       object number we're writing
     * @param array   $fields    field mapping def
     * @return array data
     */
    protected function get_yaml_data($obj, $modelname, $idx, $fields) {
        $data = array();
        foreach ($fields as $name => $def) {
            $val = isset($def['map']) ? $obj[$def['map']] : $def['val'];
            $data[$name] = $val;
        }

        // return false for no data
        if (count($data) == 0) {
            return false;
        }
        else {
            return array("{$modelname}_{$idx}" => $data);
        }
    }


    /**
     * Write a Yaml object to the appropriate file
     *
     * @param array   $yaml_array
     * @param string  $modelname
     */
    protected function write_yaml($yaml_array, $modelname) {
        $str = $this->dumper->dump($yaml_array, 2, 2); //indent 2 spaces
        fwrite($this->outfiles[$modelname], $str);

        // increment
        $this->outcounts[$modelname]++;
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
        foreach ($this->outfiles as $modelname => $handle) {
            $str_filename = $this->output_dir."/$modelname.yml";

            // close handle
            if (!fclose($handle)) {
                throw new Exception("Unable to close file $str_filename");
            }

            // unlink any unused files
            if ($this->outcounts[$modelname] == 0) {
                $done = unlink($str_filename);
                unset($this->outfiles[$modelname]);
                if (!$done) {
                    throw new Exception("Unable to unlink file $str_filename");
                }
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
     * Load yaml files into db using doctrine
     *
     * @param bool    $append
     */
    public function load_yaml($append=true) {
        Doctrine::loadData($this->output_dir, $append);
    }


}
