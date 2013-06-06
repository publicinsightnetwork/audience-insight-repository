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
 * Assign a UUID off the stack to a new Test record.
 *
 * @param Doctrine_Record $test_rec
 * @return boolean success
 */
function trec_make_new(&$test_rec) {
    $vars = trec_get_vars($test_rec);

    // cleanup any stale records of this type
    trec_remove_stale($test_rec, $vars['UUIDS']);

    // check that we still have uuid's
    if (count($vars['UUIDS']) < 1) {
        diag("Unable to create new ".$vars['UUID_COL']." -- out of UUID's!");
        return false;
    }

    // set UUID so we can clean up later
    $test_rec->my_uuid = $vars['UUIDS'][0];
    $col = $vars['UUID_COL'];
    $test_rec->$col = $vars['UUIDS'][0];
    array_splice($vars['UUIDS'], 0, 1); // remove from UUID's
    return true;
}


/**
 * Destructor cleanup for a test record
 *
 * @param Doctrine_Record $proto
 * @param string  $uuid
 */
function trec_destruct($proto, $uuid=null) {
    if (!$uuid) {
        if (isset($proto->my_uuid)) {
            $uuid = $proto->my_uuid;
        }
        else {
            return; // nothing to delete
        }
    }

    // setup table vars
    $vars = trec_get_vars($proto);
    $tbl = $proto->getTable();
    $name = get_class($proto);
    $conn = $tbl->getConnection();

    // look for stale record
    $stale = $tbl->findOneBy($vars['UUID_COL'], $uuid);

    if ($stale && $stale->exists()) {
        if (getenv('AIR_DEBUG')) diag("delete()ing stale $name: $uuid");

        try {
            // ACTUALLY ... don't turn off key checks, to get cascading deletes
//            $conn->execute('SET FOREIGN_KEY_CHECKS = 0');
            $stale->delete();
//            $conn->execute('SET FOREIGN_KEY_CHECKS = 1');
        }
        catch (Exception $err) {
            diag($err);
        }
    }

    // put UUID back on the stack
    $vars['UUIDS'][] = $uuid;
}


/**
 * Cleanup existing database objects from some crazy, aborted run.
 *
 * @param Doctrine_Record $proto
 * @param array   $uuids
 */
function trec_remove_stale($proto, $uuids) {
    $name = get_class($proto);
    $glob = 'TREC_'.strtoupper($name).'_IS_CLEAN';
    if (!defined($glob)) {
        foreach ($uuids as $id) {
            trec_destruct($proto, $id);
        }
        define($glob, 1);
    }
}


/**
 * Get static class variables for a Doctrine_Record class.  For some reason,
 * these can only be accessed at this level by an 'eval()'.
 *
 * @param Doctrine_Record $test_rec
 * @return array
 */
function trec_get_vars(&$test_rec) {
    $cls = get_class($test_rec);
    eval('$col = '.$cls.'::$UUID_COL;');
    eval('$uuids =& '.$cls.'::$UUIDS;');
    return array(
        'UUID_COL' => $col,
        'UUIDS'    => &$uuids,
    );
}
