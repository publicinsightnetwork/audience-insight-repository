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
 * Base controller for all air2 controllers. Includes airoutput features,
 * along with various other new features.
 *
 * @package default
 * */
abstract class Base_Controller extends Controller {

    // production env flag
    public $is_production = false;

    // request data
    protected $method;
    protected $view;
    protected $input_all;


    /**
     * Constructor. Children who define a __construct method should call this.
     *
     * Connect to db, setup request params, etc.
     */
    public function __construct() {
        // Let CI init things (e.g. loader, etc.).
        parent::__construct();

        AIR2_DBManager::init();

        // load output library ASAP, in case anything goes wrong
        $this->load->library('AirOutput');

        // set the is_production flag based on setting in app/init.php
        if (AIR2_ENVIRONMENT == 'prod') $this->is_production = true;

        // request data
        $this->method = $this->router->http_method;
        $this->view = $this->router->http_view;
        $this->decode_input($this->method);

        $this->begin();
    }


    /**
     * Children can override this, so they can be notified when construction is
     * complete. Children should still call this parent method.
     *
     * @return void
     * */
    public function begin() {
    }


    /**
     * Pull input from GET/POST/PUT requests and apply xss filtering
     */
    protected function decode_input() {
        $this->input_all = array();

        // get input source
        $src = false;
        if ($this->method == 'PUT') {
            $put_input = file_get_contents('php://input');
            parse_str($put_input, $src);

            // if magic quotes are on, strip them out!
            if ($src && get_magic_quotes_gpc()) {
                $src = stripslashes($src);
            }
        }
        elseif ($this->method == 'POST') {
            $src = $_POST;
        }
        elseif ($this->method == 'GET') {
            $src = $_GET;
        }

        // xss filtering
        if ($src) {
            foreach ($src as $key => $val) {

                // allow subclasses of base controller to
                // be really trusting
                if ($this->allow_through($key)) {
                    $this->input_all[$key] = $val;
                }
                else {
                    $this->input_all[$key] = $this->input->xss_clean($val);
                }
            }
        }
    }


    /**
     * uri_for() will return the full URI for a part of the application.
     * Example:
     *   $this->uri_for('foo/bar', array('color'=>'red'));
     *   //  https://myhost/foo/bar?color=red
     *
     * @param string  $path
     * @param array   $query (optional)
     * @return unknown
     */
    public function uri_for($path, $query=array()) {
        return air2_uri_for($path, $query);
    }



    /**
     * Write out a response
     *
     * @param array   $data        (optional)
     * @param int     $status_code (optional)
     */
    protected function response($data=array(), $status_code=200) {
        if (empty($data)) {
            show_404();
        }

        // write
        $this->airoutput->write($data, $status_code);
    }

    /**
     * allows subclassess to override to give an input a pass on xsscleaning
     *
     * @param sttring   $key
     */
    public function allow_through($key) {
        return false;
    }


} // END abstract class Base_Controller
