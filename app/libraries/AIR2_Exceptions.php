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

/**
 * AIR2 Exceptions
 *
 * Override the default CI "Exceptions" class to output the correct response
 * type.  WARNING: Only works correctly for "show_error" calls from within
 * a CodeIgniter Controller!
 *
 * @author rcavis
 * @package default
 */
class AIR2_Exceptions extends CI_Exceptions {

    /* some better html error $heading, $message for certain status codes */
    public static $HTML_MSGS = array(
        403 => array('403 Permission Denied', 'You do not have sufficient authorization to view this resource'),
    );


    /**
     * Show an error, attempting to output the correct response type.  If CI
     * base classes cannot be found, the error is simply printed as plain text.
     *
     * @param string  $heading
     * @param string  $message
     * @param string  $template
     * @param int     $status_code (optional)
     */
    function show_error($heading, $message, $template=null, $status_code=500) {
        // set different headers for some status codes
        $std_err = preg_match('/an error was encountered/i', $heading);
        if ($std_err && isset(self::$HTML_MSGS[$status_code])) {
            $heading = self::$HTML_MSGS[$status_code][0];
        }

        if ($status_code == 415) {
            set_status_header(415);
            header('Content-type: text/plain', true);
            $def = 'Error: Unsupported HTTP_ACCEPT format requested: '.$_SERVER['HTTP_ACCEPT'];
            echo ($message && strlen($message)) ? $message : $def;
        }
        else {
            if (class_exists('CI_Base')) {
                $CI =& get_instance();
                if (is_subclass_of($CI, 'AIR2_Controller')) {
                    $CI->airoutput->write_error($status_code, $heading, $message);
                }
                else {
                    // non-AIR2_Controller
                    set_status_header($status_code);
                    echo "$status_code - $message";
                }
            }
            else {
                // not called from a controller!  Just use plaintext
                set_status_header($status_code);
                echo "$message";
            }
        }
    }


    /**
     * DO THE RIGHT THING with an Exception, depending on what environment
     * we're running in.
     *
     * @param Exception $e
     */
    function show_exception(Exception $e) {
        $msg = 'There was an error';
        if (defined('AIR2_ENVIRONMENT') && AIR2_ENVIRONMENT != 'prod') {
            $msg = $e->__toString();
        }
        else {
            Carper::carp($e->__toString());
        }
        $this->show_error('An error was encountered', $msg);
    }


}
