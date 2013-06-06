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
 * Abstract AIR2 Data Reader class
 *
 * This class provides the iterator interface for subclasses, which are able
 * to read data from some source.  Child classes should override the 3 abstract
 * methods, but NOT any of the Iterator methods.
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2_Reader implements Iterator {

    protected $position; /* position (index) of the current object */
    protected $curr_obj; /* reference to the currently pointed at object */
    protected $mutators = array(); /* mutators to act on returned data */


    /**********************************************************************
     * Abstract AIR2_Reader methods
     *********************************************************************/

    /**
     * Called when an iterator moves to the start of the data.  Subclasses
     * should open the connection/file/etc, and do whatever setup is necessary
     * to read an object.
     */
    abstract protected function begin_read();


    /**
     * Reads a single object from a source.  Subclasses should return an
     * associative-array with keys 'idx' and 'data'.  The key 'idx' should be
     * somehow meaningful for error messages (line number in file, database
     * key, etc).  The key 'data' should be an array containing the object.
     * When there are no objects left to read, subclasses should return false
     * to signal the end of reading.
     *
     * @return assoc-array|boolean object or false
     */
    abstract protected function read_object();


    /**
     * Called when the iterator reaches the end of the data source.  (This
     * happens after read_object() returns false).
     */
    abstract protected function end_read();


    /**********************************************************************
     * Iterator interface methods
     *
     * These methods should NOT be overriden by subclasses!
     *********************************************************************/

    /**
     * Get the current object of the iterator.  The returned object will have
     * keys 'row' and 'data'.  The 'row' has some meaning according to the
     * data source being read, such as a line number, or the PK in a database,
     * etc, as determined by the AIR2_Reader subclass.
     *
     * @return associative-array
     */
    public function current() {
        // mutate the data with any mutators on the stack
        foreach ($this->mutators as $mut) {
            $this->curr_obj['data'] = $mut->mutate($this->curr_obj['data'], $this->position);
        }
        return $this->curr_obj;
    }


    /**
     * Return the position of the current object.
     *
     * @return int
     */
    public function key() {
        return $this->position;
    }


    /**
     * Moves the iterator to the next object.
     */
    public function next() {
        $this->position++;
        $this->curr_obj = $this->read_object();
    }


    /**
     * Reset the iterator, setting the position to 0 and loading the first
     * object.
     */
    public function rewind() {
        $this->position = -1;
        $this->begin_read();
        $this->next();
    }


    /**
     * Determine if the currently pointed-at object is valid.  (Whether it
     * exists, or we have hit the end of the readable objects).
     *
     * @return boolean
     */
    public function valid() {
        $valid = ($this->position >= 0 && $this->curr_obj);
        if ($valid) {
            return true;
        }
        else {
            $this->end_read();
            return false;
        }
    }


    /**
     * Add an AIR2_Mutator to change data as it's being read.
     *
     * @param AIR2_Mutator $mut
     */
    public function add_mutator(AIR2_Mutator $mut) {
        $this->mutators[] = $mut;
    }


}
