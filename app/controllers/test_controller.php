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
 * Test Controller
 *
 * Used for AIR2_Controller testing
 *
 * @author pkarman
 * @package default
 */
class Test_Controller extends AIR2_Controller {


    /**
     *
     */
    function begin() {
        parent::begin();    // authn check

        // are we in production? If so, this is a 404.
        //Carper::carp("is_production=".$this->is_production);
        if ($this->is_production) {
            show_404();
            return;
        }
        require_once APPPATH.'../tests/models/TestSystemMessage.php';
        $this->view = 'test';
        $this->airoutput->view = 'test';
    }


    /**
     *
     */
    function index() {
        $this->response(array('text' => 'hello world'));
    }


    /**
     *
     */
    function exception() {
        $sysmsg = TestSystemMessage::make_new(123456, 'Something is wrong.');
        throw new AIR2_Exception($sysmsg->smsg_id);
    }


    /**
     *
     */
    function native_exception() {
        throw new Exception("Sometimes bad things happen to good requests.");
    }


    /**
     *
     */
    function view_exception() {
        //Carper::carp("view_exception called");
        $this->response(array('exception' => 'A view to a kill'));
    }


    /**
     *
     */
    function html_render() {
        $this->airoutput->view = 'html';
        $html = array(
            'body' => 'this is the body',
            'head' => array(
                'js' => array($this->uri_for('js/test.js')),
                'css' => array($this->uri_for('css/test.css')),
                'misc' => '<script type="text/javascript">alert("test ok")</script>',
                'title' => 'test html render',
            )
        );
        $this->response($html);

    }


    /**
     * Expires an authz cookie a given number of seconds from now.
     */
    function expire($time_in_seconds=1) {
        $ck = AIR2_AUTH_TKT_NAME;
        setcookie($ck, $_COOKIE[$ck], time()+$time_in_seconds, '/');

        // show something helpful
        $this->airoutput->view = 'text';
        $this->response("Your authz cookie will expire in $time_in_seconds seconds");
    }


}
