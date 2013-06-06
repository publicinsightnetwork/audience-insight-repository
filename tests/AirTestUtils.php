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
 * Helper function to validate air2 json variables.  Includes 4 tests.
 * 
 * @param string|assoc-array $json_obj
 * @param string $name subname to identify the test
 */
function validate_json($json, $name) {
    if (is_string($json)) {
        $json = json_decode($json, true);
    }

    ok( air2_is_assoc_array($json), "$name json check - json OK" );
    ok( isset($json['radix']), "$name json check - radix" );
    ok( isset($json['meta']), "$name json check - metaData" );
    if( isset($json['meta']['total'] ) ) {
        ok( !air2_is_assoc_array($json['radix']), "$name json check - multiple" );
    }
    else {
        ok( air2_is_assoc_array($json['radix']), "$name json check - single" );
    }
}
