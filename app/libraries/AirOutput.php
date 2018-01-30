<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'HTTP_Accept.php';

/**
 * Air Output format Library
 *
 * Contains methods to add authorization restrictions on a Doctrine Query based
 * on the permissions set for the remote user.
 *
 * @author rcavis
 * @package default
 */
class AirOutput {
    public $format = 'text/plain';
    public $view = 'text';
    private $ctrlr = null; //reference to controller
    private $loader = null; //reference to loader helper

    // template for errors
    private static $HTML_ERROR_TPL = '<div id="air2-exception"><div class="body air2-corners"><h1>%s</h1><p>%s</p></div></div>';


    /**
     * Constructor -- get references to a loader, enabling view loads.
     */
    public function AirOutput() {
        if (class_exists('CI_Base')) {
            $this->ctrlr =& get_instance();
            $this->format = $this->ctrlr->router->http_format;
            $this->view   = $this->ctrlr->router->http_view;
            $this->loader = $this->ctrlr->load;
        }
        else {
            $this->loader = new CI_Loader();
        }
    }


    /**
     * Helper function to send headers to the browser for a certain status code
     * and content type.
     *
     * @param int     $status_code (optional) HTTP status code. Default is 200.
     */
    public function send_headers($status_code=200) {
        set_status_header($status_code);

        // NOTE: there's a bug in CI's set_header() so use the PHP one instead!
        header('Content-type: '.$this->format, true);

        // Absolutely NO caching of views!
        header("Cache-Control: no-store");

        // allow external requests
        if (isset($_SERVER['HTTP_ORIGIN'])) {
            header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
        }
    }

    /**
     * Render a view and return the output.
     *
     * @param array $data (optional) The data for the view.
     *
     * @return string
     **/
    public function render($data=array()) {
        // catch undefined views... output not allowed!
        if (!$this->view) {
            $this->_die_with_error(
                'Cannot display resource as \'' . $this->format . '\'',
                415
            );
        }

        // views expect top key named for the view (remove slashes)
        $datakey = preg_replace("/^.*\//", '', $this->view);
        $resp = array($datakey => $data, 'c' => $this->ctrlr);

        $out = $this->loader->view($this->view, $resp, true);

        return $out;
    }

    /**
     * Write out a response to the view requested by the client.
     *
     * @param array   $data        (optional) data to output
     * @param int     $status_code (optional)
     * @param boolean $return      (optional) Return the view as a string, rather
     *                             than outputting it.
     */
    public function write($data=array(), $status_code=200) {
        // csv views cannot handle errors
        if ($status_code != 200 && $this->view == 'csv') {
            $this->format = 'text/plain';
            $this->view = 'text';
        }

        // catch any exceptions the View might throw
        try {
            $this->send_headers($status_code);

            $out = $this->render($data);
            echo $out;
            exit(0);
        }
        catch (Exception $err) {
            // re-throw the exception if we are not in production
            if (!$this->ctrlr->is_production)
                show_error($err);
            else
                show_error("There was a server error. Please try again later.");
        }
    }

    /**
     * Output an error message, with status code, and then exit.
     *
     * @param string $str
     * @param int    $status_code
     *
     * @return void
     **/
    private function _die_with_error($str, $status_code) {
        $this->format = 'text/plain';
        $this->view = 'text';

        // show_error is a CI function. It calls exit().
        show_error("Cannot display resource as '$fmt'", 415);
    }

    /**
     * Write out an error to the view requested by the client.
     *
     * @param int     $status_code
     * @param string  $heading
     * @param string  $message
     */
    public function write_error($status_code, $heading, $message) {
        if ($this->view == 'html') {
            $bodyjs = $this->loader->view('error', array(), true);
            $out = $bodyjs . sprintf(self::$HTML_ERROR_TPL, $heading, $message);

            // load inline stuff
            $data = $this->ctrlr->airhtml->get_inline($heading, null, null);
            $data['body'] = $out;
            $this->write($data, $status_code);
        }
        else {
            $this->write(
                array(
                    'status_code' => $status_code,
                    'heading' => "$heading",
                    'message' => "$message",
                    'success' => false,
                ),
                $status_code
            );
        }
    }


}
