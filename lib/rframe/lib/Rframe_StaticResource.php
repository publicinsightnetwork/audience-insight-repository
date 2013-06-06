<?php
/*******************************************************************************
 *
 *  Copyright (c) 2011, Ryan Cavis
 *  All rights reserved.
 *
 *  This file is part of the rframe project <http://code.google.com/p/rframe/>
 *
 *  Rframe is free software: redistribution and use with or without
 *  modification are permitted under the terms of the New/Modified
 *  (3-clause) BSD License.
 *
 *  Rframe is provided as-is, without ANY express or implied warranties.
 *  Implied warranties of merchantability or fitness are disclaimed.  See
 *  the New BSD License for details.  A copy should have been provided with
 *  rframe, and is also at <http://www.opensource.org/licenses/BSD-3-Clause/>
 *
 ******************************************************************************/


/**
 * Static resource that always throws Rframe_Exceptions.  The code/message of
 * the exceptions can be altered through the public $code and $message
 * properties.
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
class Rframe_StaticResource extends Rframe_Resource {

    // allow ALL methods
    protected $ALLOWED = array('create', 'query', 'fetch', 'update', 'delete');

    // public exception code and message
    public $code = Rframe::OKAY;
    public $message = '';


    /**
     * Override to always return an exception.
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null) {
        return array(
            'success' => $this->code >= Rframe::OKAY,
            'message' => $this->message,
            'code'    => $this->code,
        );
    }


    /**
     * Override to throw an exception first.
     *
     * @param array   $data
     * @return array $response
     */
    public function create($data) { return $this->format(null, null); }


    /**
     * Override to throw an exception first.
     *
     * @param array   $args
     * @return array $response
     */
    public function query($args) { return $this->format(null, null); }


    /**
     * Override to throw an exception first.
     *
     * @param string  $uuid
     * @return array $response
     */
    public function fetch($uuid) { return $this->format(null, null); }


    /**
     * Override to throw an exception first.
     *
     * @param string  $uuid
     * @param array   $data
     * @return array $response
     */
    public function update($uuid, $data) { return $this->format(null, null); }


    /**
     * Override to throw an exception first.
     *
     * @param string  $uuid
     * @return array $response
     */
    public function delete($uuid) { return $this->format(null, null); }


    /**
     * Helper function to throw the exception.
     *
     * @throws Rframe_Exception
     */
    protected function exception() {
        throw new Rframe_Exception($this->code, $this->message);
    }


    /**
     * Create a new record at this resource.  If the record cannot be created,
     * an appropriate Exception should be thrown.
     *
     * @throws Rframe_Exception
     * @param array   $data
     * @return string $uuid
     */
    protected function rec_create($data) {
        return $this->exception();
    }


    /**
     * Query this resource for an array of records.  If the query cannot be
     * executed, an appropriate Exception should be thrown.
     *
     * @throws Rframe_Exception
     * @param array   $args
     * @return array $records
     */
    protected function rec_query($args) {
        return $this->exception();
    }


    /**
     * Fetch a single record at this resource.  If the record cannot be fetched
     * or viewed, an appropriate Exception should be thrown.
     *
     * @throws Rframe_Exception
     * @param string  $uuid
     * @return mixed $record
     */
    protected function rec_fetch($uuid) {
        return $this->exception();
    }


    /**
     * Update a record at this resource.  The record was found using the
     * rec_fetch() function.  If the record cannot be updated, an appropriate
     * Exception should be thrown.
     *
     * @throws Rframe_Exception
     * @param mixed   $record
     * @param array   $data
     */
    protected function rec_update($record, $data) {
        $this->exception();
    }


    /**
     * Delete a record at this resource.  The record was found using the
     * rec_fetch() function.  If the record cannot be deleted, an appropriate
     * Exception should be thrown.
     *
     * @throws Rframe_Exception
     * @param mixed   $record
     */
    protected function rec_delete($record) {
        $this->exception();
    }


    /**
     * Format a record into an array, to be used as the 'radix' of the response
     * object.
     *
     * @param mixed   $record
     * @return array $radix
     */
    protected function format_radix($record) {
        return $this->exception();
    }


    /**
     * Format metadata describing this resource for the 'meta' part of the
     * response object.
     *
     * @param mixed   $mixed
     * @param string  $method
     * @return array $meta
     */
    protected function format_meta($mixed, $method) {
        return $this->exception();
    }


}
