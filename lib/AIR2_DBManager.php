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

require_once 'AIR2_Exception.php';
require_once 'DBManager.php';
require_once DOCPATH.'/Doctrine.php';
require_once 'AirValid.php'; //custom validator extension

// this will allow Doctrine to load Model classes automatically
spl_autoload_register(array('Doctrine', 'autoload'));
spl_autoload_register(array('Doctrine', 'modelsAutoload'));

// must include our base classes before any models can be loaded.
require_once 'AIR2_Table.php';
require_once 'AIR2_Record.php';
require_once 'AIR2_Query.php';

// set our overloaded classes as the defaults
Doctrine_Manager::getInstance()->setAttribute(Doctrine_Core::ATTR_QUERY_CLASS, 'AIR2_Query');
Doctrine_Manager::getInstance()->setAttribute(Doctrine_Core::ATTR_TABLE_CLASS, 'AIR2_Table');

// telling Doctrine where our models are located
// pass the CONSERVATIVE flag explicitly so that models are actually required
// only on demand.
Doctrine_Core::setModelsDirectory(APPPATH.'/models');
Doctrine::loadModels(array(APPPATH.'/models'), Doctrine_Core::MODEL_LOADING_CONSERVATIVE);

// this will allow us to use "mutators"
Doctrine_Manager::getInstance()->setAttribute(
    Doctrine::ATTR_AUTO_ACCESSOR_OVERRIDE, true);

// turn on data validations in doctrine, to catch things before database ops
Doctrine_Manager::getInstance()->setAttribute(Doctrine::ATTR_VALIDATE,
    Doctrine::VALIDATE_ALL);

// disable any "smart" caching
Doctrine_Manager::getInstance()->setAttribute(Doctrine::ATTR_QUERY_CACHE, null);
Doctrine_Manager::getInstance()->setAttribute(Doctrine::ATTR_RESULT_CACHE, null);

/**
 * AIR2 Database Manager
 *
 * Allows caching of AIR2 database connections
 *
 * This class relies on the presence of 2 files:
 *  etc/db_registry.ini
 *  etc/my_profile
 *
 * The .ini file should have one or more profiles listed. The profile
 * is picked based on the following order:
 * -  passed explicitly to the constructor
 * -  AIR2_DOMAIN env var
 * -  contents of etc/my_profile
 *
 * If there is a <profilename>_master profile defined in the .ini file,
 * it is automatically used for all DB writes by the AIR2_Record class.
 *
 * Example usage:
 *
 * AIR2_DBManager::init();  // profile picked from etc/my_profile
 * $conn = AIR2_DBManager::get_master_connection();  // a Doctrine_Connection object
 * $conn->execute("update foo set bar=456 where bar=123");
 *
 * @author pkarman
 * @package default
 */
class AIR2_DBManager extends DBManager {

    private static $i_am_ready = false;


    /**
     * Override parent method to set internal readiness var, preventing multiple initializations.
     */
    public static function init($profile_name=null, $app_path=null) {
        $air2_profile = parent::init($profile_name, $app_path);
        if (self::$i_am_ready) {
            return $air2_profile;
        }
        self::$i_am_ready = true;
        return $air2_profile;
    }


}
