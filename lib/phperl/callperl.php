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

require_once 'PerlException.php';

/**
 * Perl adaptor for PHP
 *
 * Static class that can be used to call perl subroutines from PHP.  Note that
 * all I/O from the sub must be basic types, since it must be json-encodable.
 *
 * @author rcavis
 * @package default
 */
class CallPerl {

    // name of our partner script
    const PERL_SCRIPT = 'callperl.pl';

    // env vars for perl
    protected static $ENV = false;

    // temp file for stderr
    const STDERR_TMP_FILE = '/tmp/callperl.err'; 


    /**
     * Execute a perl subroutine
     *
     * The subroutine $sub must be a valid perl routine that CallPerl.pl will
     * be able to execute (must know the namespace).  Any number of arguments
     * can be passed.  The json-decoded results of the execution will be
     * returned.
     *
     * This function throws all sorts of exceptions when things go awry.
     *
     * @param  string $sub
     * @param  mixed  $arg1
     * @param  mixed  $arg2
     * @return mixed  $result
     */
    public static function exec($sub, $arg1=null, $arg2=null) {
        // command i/o
        $cmd = AIR2_PERL_PATH.'  '.dirname(__FILE__).'/'.self::PERL_SCRIPT;
        if (self::$ENV) {
            $cmd = self::$ENV." $cmd";
        }
       
        // store stderr in file
        // to avoid blocking stdout
        // http://www.php.net/manual/en/function.proc-open.php#89338
        $stderr_file = self::STDERR_TMP_FILE . getmypid();
        $spec = array(
           0 => array("pipe", "r"), // stdin
           1 => array("pipe", "w"), // stdout
           2 => array("file", $stderr_file, "a"), // stderr
        );
        $process = proc_open($cmd, $spec, $pipes, APPPATH);

        // abort if not a resource
        if (!is_resource($process)) {
            throw new Exception('Unable to get proc_open resource');
        }

        // pipe params to perl
        $data = array(
            'fn'   => $sub,
            'argc' => func_num_args()-1,
            'argv' => array_slice(func_get_args(), 1),
        );
        fwrite($pipes[0], json_encode($data));
        fclose($pipes[0]);

        // get output/errors
        $o = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $e = file_get_contents($stderr_file);
        unlink($stderr_file);

        // end process
        $ret = proc_close($process);

        // handle exceptions
        if ($ret !== 0) throw new PerlException($e, $ret);

        // decode and return output
        $json = json_decode($o, true);
        if (!$json || !isset($json['result'])) {
            throw new Exception("Json-decode error on returned: $o");
        }

        // return (+debug)
        //echo "\n---RAWJSON---\n$o\n\n";
        return $json['result'];
    }


    /**
     * Set the environment the perl call will execute with
     *
     * @param type $new_env
     */
    public static function set_env($new_env) {
        self::$ENV = $new_env ? $new_env : false;
    }


}
