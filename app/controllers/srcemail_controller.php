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

require_once 'AIR2_HTMLController.php';

/**
 * Source Email Management Controller
 *
 * @author rcavis
 * @package default
 */
class Srcemail_Controller extends AIR2_HTMLController {


    /**
     * Since there's no UUID for the source emails page, just override index
     */
    function index() {
        // inline data
        $inline = array(
            'URL'      => air2_uri_for('srcemail'),
            'DATA'  => $this->api->query('srcemail', array('limit' => 30, 'sort' => 'sem_upd_dtim desc', 'status' => SrcEmail::$STATUS_BOUNCED)),
            'STATS'  => null,
            'PARMS'   => array('status' => SrcEmail::$STATUS_BOUNCED),
        );

        // show page
        $title = 'Bounced Emails - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'SrcEmail', $inline);
        $this->response($data);
    }


}
