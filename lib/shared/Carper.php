<?php

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
