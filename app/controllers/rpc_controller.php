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
 * RPC Controller
 *
 * RPC-style methods available via HTTP. Our junk drawer, till a better structure
 * presents itself.
 *
 * @author pkarman
 * @package default
 */
class RPC_Controller extends AIR2_Controller {

    /**
     * Sends email to user indicated in email POST param.
     * This method proxies through to the authn/ application for now.
     */
    public function send_password_email() {

        // validity checks
        if ($this->method != 'POST') {
            header('Allow: POST', true, 405);
            $this->response(array('success'=>false), 405);
            exit;
        }
        $email = $this->input->post('email');
        if (!$email) {
            header('X-AIR: "email" required', true, 400);
            $this->response(array('success'=>false), 400);
            exit;
        }
        
        // fire the remote call
        $proxy = new Search_Proxy(array(
                'url'       => 'https://www.publicinsightnetwork.org/authn/new_account',
                'params'    => array(
                    'email' => $email,
                )
            )
        );

        $response = $proxy->response();

        if ($response['response']['http_code'] != '200') {
            header('X-AIR: Send mail failed', false, 401);
            $this->response(array('success'=>false), 401);
            exit;
        }

        $this->response(array('success'=>true), 201);

    }


}
