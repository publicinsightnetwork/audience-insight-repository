<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'AIR2_DBManager.php';

/**
 * AIR2 Exception
 *
 * @author pkarman
 * @package default
 */
class AIR2_Exception extends Exception {

    private $message_args;

    /**
     * Create an exception message
     *
     * @param int     $code
     * @param array   $message_args (optional)
     */
    public function __construct($code, $message_args=array()) {

        //error_log( "code=$code" );

        $this->message_args = $message_args;

        // look up $message from the db based on $code
        $message = AIR2_Exception::fetch_message($code, $message_args);
        parent::__construct($message, $code);
    }


    /**
     * Output the exception as a string
     *
     * @return string
     */
    public function __toString() {
        return 'Error [' . $this->code . ']: ' . $this->message;
    }


    /**
     * Fetch a message string from the database using the supplied code
     *
     * @param int     $code
     * @param array   $message_args (optional)
     * @return string
     */
    public static function fetch_message($code, $message_args=array()) {
        $proto = new SystemMessage();
        $sysmsg = $proto->getTable()->find($code);
        if (!$sysmsg || !$sysmsg->exists()) {
            throw new Exception("Cannot find $code in system_message");
        }
        $msg = vsprintf($sysmsg->smsg_value, $message_args);
        return $msg;
    }



    /**
     * Sets the message of the exception
     *
     * @param string  $message
     * @return string
     */
    public function set_message($message) {
        $this->message = $message;
        return $message;
    }


}
