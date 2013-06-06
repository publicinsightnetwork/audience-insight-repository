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

 require_once 'Cache_Lite.php';

 /**
  * Handles general caching of documents for the AIR2 application.
  *
  * @package default
  **/
class Cache extends Cache_Lite {
    /**
     * Singleton instance of Cache.
     *
     * @var Cache
     **/
    private static $_instance = null;

    /**
     * Returns the singleton instance of Cache
     *
     * @return Cache
     **/
    public static function instance() {
        if (!Cache::$_instance) {
            global $profiles;

            Cache::$_instance = new Cache(
                array(
                    'cacheDir' => AIR2_CACHE_ROOT,
                    'lifeTime' => AIR2_CACHE_TTL,
                )
            );
        }

        return Cache::$_instance;
    }

    /**
     * Overrides Cache_Lite save() method.
     *
     * @access public
     *
     * @param string  $data  Data to put in cache (can be another type than strings
     *                       if automaticSerialization is on).
     * @param string  $id    (optional) Cache id.
     * @param string  $group (optional) Name of the cache group.
     *
     * @return boolean True if no problem (else : false or a PEAR_Error object).
     */
    public function save($data, $id = NULL, $group = 'default') {
        $result = parent::save($data, $id, $group);

        // Change the permissions on the cache file, so users other than the web server
        // user can manage the file.
        chmod($this->_file, 0664);

        return $result;
    }
} // END class Cache
