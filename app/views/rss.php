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

/*
|--------------------------------------------------------------------------
| RSS 2.0 Output
|--------------------------------------------------------------------------
| Prints data as an RSS feed.  This view will also do a bit of sanity
| checking on your data, so be kind!
|
| This view should be passed an $rss assoc-array that contains channel elements
| and the items, which should be under the key 'item'.  Anytime you want your
| xml to contain multiple elements of the same name (as with items), just use
| an array key named the singlular that points at a list of the elements.
|
| $rss = array(
|     'title'       => 'my title',
|     'link'        => 'my link',
|     'description' => 'my desc',
|     'image'       => array(
|         'url'   => 'img url',
|         'title' => 'img title',
|         'link'  => 'img link',
|     ),
|     'item' => array(
|         array('title' => 'rss item 1'),
|         array('title' => 'rss item 2'),
|         array('title' => 'rss item 3'),
|     );
| );
|
*/
if (!function_exists('xml_convert')) {
    $this->load->helper('xml');
}
if (!isset($rss) || !air2_is_assoc_array($rss)) {
    throw new Exception("rss var not defined");
}

// default to list of 0 items
if (!isset($rss['item'])) {
    $rss['item'] = array();
}

// sanity check channel keys
foreach (array('title', 'link', 'description') as $key) {
    if (!isset($rss[$key])) {
        throw new Exception("Missing required channel key '$key'");
    }
}

// sanity check item keys
foreach ($rss['item'] as $idx => $item) {
    if (!air2_is_assoc_array($item)) {
        throw new Exception("Invalid rss item format at index $idx");
    }
    if (!isset($item['title']) && !isset($item['description'])) {
        throw new Exception("Item $idx missing title and description");
    }
}

// helper to recursively print xml
function recursive_item_print($key, $val, $indent=0) {
    $pad = str_pad('', $indent);

    // case 1 - list-array - print each item
    if (is_int($key)) {
        if (air2_is_assoc_array($val)) {
            foreach ($val as $subkey => $subval) {
                recursive_item_print($subkey, $subval, $indent);
            }
        }
        else {
            throw new Exception("Bad item format - $key - $val");
        }
    }

    // case 2 - assoc-array - print the key, then the item
    elseif (is_string($key)) {
        if (air2_is_assoc_array($val)) {
            echo "$pad<$key>\n";
            foreach ($val as $subkey => $subval) {
                recursive_item_print($subkey, $subval, $indent+1);
            }
            echo "$pad</$key>\n";
        }
        elseif (is_array($val)) {
            foreach ($val as $subidx => $subval) {
                if (is_string($subval)) {
                    if ($key == 'media') {
                        echo "$pad<enclosure url='$subval' type='image/png' />\n";
                    } 
                    else {
                        echo "$pad<$key><![CDATA[" . $subval . "]]></$key>\n";
                    }
                }
                else {
                    echo "$pad<$key>\n";
                    recursive_item_print($subidx, $subval, $indent+1);
                    echo "$pad</$key>\n";
                }
            }
        }
        else {
            if ($key == 'media') {
                echo "$pad<enclosure url='$val' type='image/png' />\n";
            }
            else {
                echo "$pad<$key><![CDATA[" . $val . "]]></$key>\n";
            }
        }
    }
    else {
        throw new Exception("Bad item format - $key - $val");
    }
}


// PRINT XML!
// echo the whole thing to make sure we get the correct indentations
echo "<?xml version=\"1.0\"?>\n";
echo "<rss version=\"2.0\">\n";
echo " <channel>\n";
foreach ($rss as $key => $val) {
    recursive_item_print($key, $val, 2);
}
echo " </channel>\n";
echo "</rss>";
