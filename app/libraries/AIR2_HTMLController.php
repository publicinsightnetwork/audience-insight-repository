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

require_once 'AIR2_Controller.php';
require_once 'AIR2_APIController.php';
require_once 'rframe/AIRAPI.php';

/**
 * Controller to show an HTML view of an api resource
 *
 * @author rcavis
 * @package default
 */
class AIR2_HTMLController extends AIR2_Controller {

    // allow optionally defining a different resource base-url than the
    // one this controller is under
    protected $alt_resource_name = false;

    /**
     * Public starting point for any calls to this controller
     */
    public function index() {
        $args = func_get_args();

        // replace $args[0] with alternate resource name
        if ($this->alt_resource_name && count($args)) {
            $args[0] = $this->alt_resource_name;
        }

        // any path with more than a single uuid is invalid for html
        if (count($args) != 2) {
            $path = implode('/', $args);
            $rs = $this->api->query_or_fetch($path);
            if ($rs['code'] == Rframe::OKAY) {
                show_error('HTML view not available', 415);
            }
            else {
                $this->show_html_error($rs['code'], $rs['message'], $rs);
            }
        }

        // check for existence
        $name = $args[0];
        $uuid = $args[1];
        $rs = $this->api->fetch("$name/$uuid");
        if ($rs['code'] < Rframe::OKAY) {
            $this->show_html_error($rs['code'], $rs['message'], $rs);
        }

        // print-friendly or regular flavor
        if ($this->view == 'phtml') {
            $this->load->library('AirPrinter');
            $this->show_print_html($uuid, $rs);
        }
        elseif ($this->view == 'html') {
            $this->airrecent->log($rs); //log recent for html
            $this->show_html($uuid, $rs);
        }
        else {
            show_error('Only HTML view available', 415);
        }
    }

    /**
     * Show an html view.  If you don't override this, it will throw an
     * exception.
     *
     * @param string $uuid
     * @param array $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        throw new Exception('show_html() not defined!');
    }


    /**
     * Show a print-friendly html view.  Unless overriden, will show a 415
     *
     * @param string $uuid
     * @param array $base_rs
     */
    protected function show_print_html($uuid, $base_rs) {
        show_error('Print-friendly HTML view not available', 415);
    }


    /**
     * Show an HTML error, likely because something went wrong while fetching
     * the resource.
     *
     * @param int $code
     * @param string $msg
     * @param array $rs
     */
    protected function show_html_error($code, $msg, $rs) {
        $status = AIR2_APIController::$API_TO_STATUS[$code];
        show_error($msg, $status);
    }


}
