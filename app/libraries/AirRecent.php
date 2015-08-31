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

/**
 * AirRecent Library
 *
 * Logs successful HTML views in user preferences
 *
 * @author rcavis
 * @package default
 */
class AirRecent {

    // user to log against
    protected $user;

    // configure logging
    protected $recent_max = 5;
    protected $config = array(
        'email'   => array(
            'email_uuid', 'email_campaign_name',
        ),
        'project' => array(
            'prj_uuid', 'prj_name', 'prj_display_name',
        ),
        'source' => array(
            'src_uuid', 'src_first_name', 'src_last_name', 'src_username',
        ),
        'inquiry' => array(
            'inq_uuid', 'inq_title', 'inq_ext_title',
        ), 
        'submission' => array(
            'srs_uuid', 'Inquiry:inq_ext_title', 'Source:src_first_name', 
            'Source:src_last_name', 'Source:src_username',
        ),
    );


    /**
     * Constructor
     *
     * @param array $params
     */
    public function __construct($params=null) {
        if (!isset($params['user'])) {
            throw new Exception("User required");
        }
        $this->user = $params['user'];
    }


    /**
     * Logs a successful html visit to a resource
     *
     * @param User $u
     * @param array $segments
     */
    public function log($rs) {
        if ($rs['code'] < Rframe::OKAY) {
            return;
        }
        if (!preg_match('/^\w+\/\w+$/', $rs['path'])) {
            return;
        }
        $my_path = preg_replace('/\/\w+$/', '', $rs['path']);

        // do we log this path?
        if (!array_key_exists($my_path, $this->config)) {
            return;
        }
        $columns = $this->config[$my_path];

        // load recent from user
        $recent = $this->user->get_pref('recent');

        // collect data for this resource
        $data = array();
        foreach ($columns as $col) {
            $parts = explode(':', $col);
            $val = $rs['radix'];
            foreach ($parts as $part) {
                $col = $part;
                $val = $val[$part];
            }
            $data[$col] = $val;
        }

        // log this data
        $this->add_data($my_path, $data, $recent);

        // save recent
        $this->user->set_pref('recent', $recent);
        $this->user->save();
    }


    /**
     * Helper to add data to the recent views
     *
     * @param array $recent
     * @param string $type
     * @param array $data 
     */
    protected function add_data($type, $data, &$recent) {
        // set the list, if DNE
        if (!isset($recent[$type])) {
            $recent[$type] = array();
        }

        // avoid copies of items
        $idx = array_search($data, $recent[$type]);
        if ($idx !== false) {
            array_splice($recent[$type], $idx, 1);
        }

        // push on front of recent
        array_unshift($recent[$type], $data);
        if (count($recent[$type]) > $this->recent_max) {
            array_pop($recent[$type]);
        }
    }


}
