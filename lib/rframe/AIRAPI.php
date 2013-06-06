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

require_once 'lib/Rframe.php';

/**
 * AIR-specific restful framework singleton
 *
 * @author rcavis
 * @package default
 */
class AIRAPI extends Rframe {

    // config
    protected $namespace = 'AAPI';
    protected $api_path = 'api/';


    /**
     * Create a new API framework for a given User
     *
     * @param User $u
     */
    public function __construct(User $u) {
        if (!$u || !$u->exists() || !$u->user_id) {
            throw new Exception("Invalid user specified!");
        }

        // send User to parent ini
        $ini = array('user' => $u);
        parent::__construct(APPPATH.$this->api_path, $this->namespace, $ini);
    }


    /**
     * Since it's difficult to determine if a GET request was a FETCH or
     * QUERY, this does the right thing (hopefully)
     *
     * @param  string $path
     * @param  array  $args
     * @return array  $response
     */
    public function query_or_fetch($path, $args=array()) {
        $rsc = $this->parser->resource($path);

        // if not found, it shouldn't matter which we call
        if (!$rsc) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
            return $rsc->query($args);
        }

        // more info about resource
        $uuid = $this->parser->uuid($path);
        $cls = get_class($rsc);
        $is_one = ($rsc->get_rel_type($cls) == Rframe_Resource::ONE_TO_ONE);

        // determine if this is likely a query or fetch path
        if ((!$is_one && $uuid) || ($is_one && !$uuid)) {
            return $rsc->fetch($uuid, $args);
        }
        else {
            return $rsc->query($args);
        }
    }


}
