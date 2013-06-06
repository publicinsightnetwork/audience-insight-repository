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
 * Translation Map Controller
 *
 * @author rcavis
 * @package default
 */
class Translation_Controller extends AIR2_HTMLController {


    /**
     * Since there's no UUID for the translations page, just override index
     */
    function index() {
        // valid facts for translations (fv_type_multiple)
        $facts = $this->api->query('fact', array('type' => Fact::$FV_TYPE_MULTIPLE));
        $simplified_facts = array();
        foreach ($facts['radix'] as $fact) {
            $simplified_facts[] = array($fact['fact_identifier'], $fact['fact_name']);
        }

        // potential authz
        $fake = new TranslationMap();
        $user = $this->airuser->get_user();
        $authz = array(
            'may_read'   => $fake->user_may_read($user),
            'may_write'  => $fake->user_may_write($user),
            'may_manage' => $fake->user_may_manage($user),
        );

        // inline data
        $inline = array(
            'URL'      => air2_uri_for('translation'),
            'DATA'     => $this->api->query('translation', array('type' => 'gender', 'limit' => 18, 'sort' => 'xm_xlate_from asc')),
            'PARMS'    => array('type' => 'gender'),
            'FACTDATA' => $facts,
            'FACTS'    => $simplified_facts,
            'AUTHZ'    => $authz,
        );

        // show page
        $title = 'Manage Translations - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Translation', $inline);
        $this->response($data);
    }


}
