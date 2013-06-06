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


/**
 * Abstract AIR2 Data Writer class
 *
 * This class uses a AIR2_Reader to fetch data from some source, and then writes
 * it to a destination, as implemented by the subclass.
 *
 * Note: this class catches all exceptions, and stores them in $this->errors.
 * After function returns, you must check get_errors() to find out what went
 * wrong.  The writer can continue running with errors, according to what mode
 * it is running in.  See set_mode().
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2_Writer {

    protected $errors = array(); /* Exceptions generated during run */
    protected $atomic = true; /* run writing as a single transaction */
    protected $max_errors; /* abort on nth exception */

    private static $ERRMAX = 400; /* absolute max number of errors to report */

    /**********************************************************************
     * Abstract AIR2_Writer methods
     *********************************************************************/

    /**
     * Perform any setup necessary for writing objects.
     */
    abstract protected function begin_write();


    /**
     * Write a single object to the destination.  The $obj will be an array of
     * data (NOT an associative array).  The $commit param reflects whether the
     * write action is a single-transaction or not.  In some cases, $commit can
     * be ignored, delaying the actual commit until end_write().
     *
     * @param array   $obj
     * @param boolean $commit
     */
    abstract protected function write_object($obj, $commit);


    /**
     * Perform any actions after writing objects is complete.  If the action is
     * cancelled, (and the write was performed in a single transaction), no
     * writing should actually take place.  Should return the number of objects
     * ACTUALLY written to disk.  (The subclass must keep track of this).  In
     * most cases, the count($this->errors) plus this return value should equal
     * the total number of objects read.
     *
     * @param boolean $cancel
     * @return int number of objects written
     */
    abstract protected function end_write($cancel=false);


    /**********************************************************************
     * Public AIR2_Writer methods
     *
     * These methods should NOT be overriden by subclasses!
     *********************************************************************/

    /**
     * Set the write mode for this AIR2_Writer.  All DataWriter default to being
     * atomic and not breaking on errors.  (This means they will attempt to
     * write every object read, and then commit those writes only if they have
     * no errors).  The $is_atomic param determines if the DataWriter will run
     * a single-transaction or not, and $break_on_errors determines if all read
     * objects will be processed, or if the writer will halt on error.  Setting
     * $break_on_error to true means it will break on 1 error.  Setting it to an
     * integer value will cause it to break on that number of errors.
     *
     * @param boolean $is_atomic
     * @param boolean|int $break_on_error
     */
    public function set_mode($is_atomic=true, $break_on_error=false) {
        $this->atomic = $is_atomic;
        if (is_bool($break_on_error)) {
            $this->max_errors = ($break_on_error) ? 1 : 0;
        }
        else {
            $this->max_errors = $break_on_error;
        }
    }


    /**
     * Primary method for the AIR2_Writer class, used to read objects from a
     * AIR2_Reader and write them to a destination (as implemented by the
     * subclass).  This method will return the number of items that were
     * actually written to disk.  This method catches all Exceptions, so you
     * must check get_errors() to find out what Exceptions occured during the
     * run.
     *
     * @param AIR2_Reader $reader
     * @param unknown $validators (optional)
     * @return int the number of items successfully written
     */
    public function write_data(AIR2_Reader $reader, $validators=array()) {
        // clear errors
        $this->errors = array();
        if ($this->max_errors == 0) $this->max_errors = self::$ERRMAX;

        // setup any validators
        if (!is_array($validators)) {
            $validators = array($validators);
        }

        // start reading/writing
        $this->begin_write();
        foreach ($reader as $num => $obj) {
            $data = $obj['data'];
            $row = $obj['row'];

            // validate the object data
            $err_msgs = array(); //all errors for SINGLE object
            foreach ($validators as $v) {
                $t = $v->validate_object($data, $row);

                if ($t !== true) {
                    $err_msgs[] = $t; // string error msg
                    if ($v->break_on_failure) break;
                }
            }

            // check for errors, and write object
            if (count($err_msgs) > 0) {
                // collect all err_msgs into a single error
                $msg = implode(', ', $err_msgs);
                $this->errors[] = new Exception($msg); //TODO: custom Exception class

                // decide how to report the error
                if (count($this->errors) >= $this->max_errors) {
                    return $this->end_write($this->atomic);
                }
            }
            else {
                // attempt to write the object
                try {
                    $this->write_object($data, !$this->atomic);
                }
                catch (Exception $err) {
                    // TODO: should line# be added to this exception?
                    $this->errors[] = $err;

                    if (count($this->errors) >= $this->max_errors) {
                        return $this->end_write($this->atomic);
                    }
                }
            }
        }

        // phew! made it
        if ($this->atomic && count($this->errors) > 0) {
            return $this->end_write(true); // CANCEL!
        }
        else {
            return $this->end_write(); // commit
        }
    }


    /**
     * After write_data() completes, this function will return an array of any
     * Exceptions that occured during the write.
     *
     * @return array Exceptions that occured during write
     */
    public function get_errors() {
        return $this->errors;
    }


}
