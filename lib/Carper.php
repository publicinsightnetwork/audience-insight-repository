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
 * Carper
 *
 * Carp for PHP, based on Carp for Perl.  Note the class is called Carper
 * because otherwise PHP thinks carp() is a constructor.
 *
 * @author pkarman
 * @package default
 */

class Carper {

    /**
     * Log a debug message
     *
     * @param string  $message
     */
    public static function carp($message) {

        $backtrace = debug_backtrace();
        if (isset($backtrace[2])) {
            $caller = $backtrace[2]['function'] . '()';
        }
        else {
            $caller = 'main()';
        }
        if (isset($backtrace[1])
            && isset($backtrace[1]['file'])
            && isset($backtrace[1]['line'])
        ) {
            $caller_line = $backtrace[1]['file'] . ' line ' . $backtrace[1]['line'];
        }
        else {
            $caller_line = '';
        }
        if (isset($backtrace[0])
            && isset($backtrace[0]['file'])
            && isset($backtrace[0]['line'])
        ) {
            $at = $backtrace[0]['file'] . ' line ' . $backtrace[0]['line'];
        }
        else {
            $at = '';
        }
        error_log('['. date('Y-m-d H:i:s')."] $message at $at \ncalled by $caller $caller_line" );

    }


    /**
     * Calls confess() and exit(1);
     *
     * @param unknown $message
     */
    public static function croak($message) {
        Carper::confess($message);
        exit(1);
    }


    /**
     * Prints full stacktrace to error_log().
     *
     * @param unknown $message (optional)
     */
    public static function confess($message=null) {
        $backtrace = debug_backtrace();
        $backtracestring = '';
        foreach ($backtrace as $item) {
            if (isset($item['file'])) {
                $backtracestring .= $item['file'] . ' ' ;
            }
            if (isset($item['line'])) {
                $backtracestring .= $item['line'] . ' ' ;
            }
            if (isset($item['function']) && $item['function'] !== 'confess' ) {
                $backtracestring .= $item['function'] . ' ';
            }
                $backtracestring .= "\n";
        }

        error_log('['. date('Y-m-d H:i:s') . "] $message backtrace follows $backtracestring");
    }


}
