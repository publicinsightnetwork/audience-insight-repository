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
 * AirPrinter Library
 *
 * Helper functions for printing an print-friendly html view
 *
 * @author rcavis
 * @package default
 */
class AirPrinter {


    /**
     * Print a user
     *
     * @param array $u
     * @param bool  $flip
     */
    public function user($u, $flip=false) {
        $name = $u['user_username'];
        $f = $u['user_first_name'];
        $l = $u['user_last_name'];
        $sys = ($u['user_type'] == User::$TYPE_SYSTEM);
        if (!$sys && $f && $l) {
            $name = $flip ? "$l, $f" : "$f $l";
        }
        if (isset($u['UserOrg'][0]['Organization'])) {
            $name = "$name (".$u['UserOrg'][0]['Organization']['org_display_name'].")";
        }
        echo $name;
    }


    /**
     * Print a date
     *
     * @param string $d
     * @param bool   $as_time
     */
    function date($d, $as_time=false) {
        $t = strtotime($d);
        echo date($as_time ? 'M. j, Y at g:ia' : 'M. j, Y', $t);
    }


    /**
     * Print a source name
     *
     * @param array $s
     * @param bool  $flip
     */
    function source($s, $flip=false) {
        $name = isset($s['src_username']) ? $s['src_username'] : $s['sem_email'];
        $f = $s['src_first_name'];
        $l = $s['src_last_name'];
        if ($f && $l) {
            $name = $flip ? "$l, $f" : "$f $l";
        }
        elseif ($l) {
            $name = $l;
        }
        echo $name;
    }


    /**
     * Print a source email
     *
     * @param array $s
     * @param bool  $blank
     */
    function source_email($s, $blank=true) {
        $eml = $blank ? '' : '(no email)';
        if (isset($s['primary_email'])) {
            $eml = $s['primary_email'];
        }
        elseif (isset($s['SrcEmail'][0])) {
            $eml = $s['SrcEmail'][0]['sem_email'];
        }
        elseif (isset($s['sem_email'])) {
            $eml = $s['sem_email'];
        }
        echo $eml;
    }


    /**
     * Print a source phone
     *
     * @param array $s
     * @param bool  $blank
     */
    function source_phone($s, $blank=true) {
        $ph = $blank ? '' : '(no phone)';
        if (isset($s['primary_phone'])) {
            $ph = $s['primary_phone'];
        }
        elseif (isset($s['SrcPhoneNumber'][0])) {
            $ph = $s['SrcPhoneNumber'][0]['sph_number'];
            if (isset($s['SrcPhoneNumber'][0]['sph_ext'])) {
                $ph .= $s['SrcPhoneNumber'][0]['sph_ext'];
            }
        }
        elseif (isset($s['sph_number'])) {
            $ph = $s['sph_number'];
            if (isset($s['sph_ext'])) {
                $ph .= $s['sph_ext'];
            }
        }
        echo $ph;
    }


    /**
     * Print a source address
     *
     * @param array $s
     * @param bool  $blank
     */
    function source_address($s, $blank=true) {
        $ml = $blank ? '' : '(no address)';

        // gather city/state/zip
        $vals = array('', '', '');
        $keys = array(
            array('primary_address_city', 'smadd_city'),
            array('primary_address_state', 'smadd_state'),
            array('primary_address_zip', 'smadd_zip'),
        );

        foreach ($keys as $idx => $keydef) {
            foreach ($keydef as $key) {
                if (isset($s['SrcMailAddress'][0][$key])) {
                    $vals[$idx] = $s['SrcMailAddress'][0][$key];
                }
                elseif (isset($s[$key])) {
                    $vals[$idx] = $s[$key];
                }
            }
        }

        // crunch!
        if ($vals[0]) $vals[0] .= ',';
        echo trim(implode(' ', $vals));
    }


    /**
     * Print a source home organization
     *
     * @param array $s
     * @param bool  $blank
     */
    function source_org($s, $blank=true) {
        $org = $blank ? '' : '(no home organization)';
        if ($s['primary_org_uuid']) {
            $org = 'Source for '.$s['primary_org_display_name'];
        }
        elseif (isset($s['SrcOrg'][0]['Organization'])) {
            $org = 'Source for '.$s['SrcOrg'][0]['Organization']['org_display_name'];
        }
        echo $org;
    }


    /**
     * Print the value for a fact
     *
     * @param array $sf
     */
    function fact_val($sf) {
        $val = '(unknown)';
        if (isset($sf['AnalystFV']['fv_value'])) {
            $val = $sf['AnalystFV']['fv_value'];
        }
        elseif (isset($sf['SourceFV']['fv_value'])) {
            $val = $sf['SourceFV']['fv_value'];
        }
        elseif (isset($sf['sf_src_value'])) {
            $val = $sf['sf_src_value'];
        }
        echo $val;
    }


    /**
     * Print the name of a fact
     *
     * @param array $f
     */
    function fact($f) {
        $name = '(unknown)';
        if (isset($f['fact_name'])) {
            $name = $f['fact_name'];
        }
        elseif (isset($f['Fact']['fact_name'])) {
            $name = $f['Fact']['fact_name'];
        }
        echo $name;
    }

    /**
     * Print all fact values
     *
     * @param $s
     */
    function all_facts($s){
         if (isset($s['SrcFact'])) {
            $facts = $s['SrcFact'];
            foreach ($facts as $fact) {
                $val = '(unknown)';
                if (isset($fact['AnalystFV']['fv_value'])) {
                    $val = $fact['AnalystFV']['fv_value'];
                }
                elseif (isset($fact['SourceFV']['fv_value'])) {
                    $val = $fact['SourceFV']['fv_value'];
                }
                elseif (isset($fact['sf_src_value'])) {
                    $val = $fact['sf_src_value'];
                }
                if ($fact['Fact']['fact_identifier'] == 'household_income') {
                    $val = preg_replace('/(\d)(?=(\d\d\d)+\b)/', '$1,', $val);
                }
                if ($fact['Fact']['fact_identifier'] == 'birth_year') {
                    if ($dob = intval($val)) {
                        $today = date("Y");
                        $dob = ($today - $dob);
                        $val = $dob . ' years old';
                    }
                    else {
                        $val = 'Born ' + $val;
                    }
                }
                echo '<p>' . $val . '</p>'; 
            }
         }
    }

    /**
     * Print a source response, inserting <img> tags when necessary
     *
     * @param array $sr
     */
    function response($sr) {
        $orig = $sr['sr_orig_value'];
        $mod  = $sr['sr_mod_value'];
        $val  = $mod ? $mod : ($orig ? $orig : '(no response)');
        $val  = nl2br($val);

        if (!isset($sr['Question'])) {
            $sr['Question'] = $sr;
        }

        // check for image
        if ($sr['Question']['ques_type'] == Question::$TYPE_FILE) {
            $sr_value = $mod ? $mod : $orig;

            // get file name (after the last slash)
            $url = $sr_value;
            $match = preg_match('/[^\/]+$/', $url, $matches);
            $name = $match ? $matches[0] : $url;

            // add the server to the url
            $path = AIR2_UPLOAD_SERVER_URL . $url;
            $val = "<a class=\"external\" target=\"_blank\" href=\"$path\">$name</a>";
            $preview_url = $sr_value;
            $preview_url = preg_replace('/\.jpe?g/i', '.png', $preview_url);
            $preview_url = preg_replace('/\.gif/i', '.png', $preview_url);
            if ($preview_url != $sr_value) {
                $val .= '<div class="air2-preview-img"><img src="'.AIR2_PREVIEW_SERVER_URL.$preview_url.'"/></div>';
            }
        }

        echo $val;
    }

    /**
     * Print a the original response, inserting <img> tags when necessary
     *
     * @param array $sr
     */
    function original_response($sr) {
        $orig = $sr['sr_orig_value'];
        $val  = $orig ? $orig : '(no response)';
        $val  = nl2br($val);

        if (!isset($sr['Question'])) {
            $sr['Question'] = $sr;
        }
        
        // check for image
        if ($sr['Question']['ques_type'] == Question::$TYPE_FILE) {
            $sr_value = $orig;

            // get file name (after the last slash)
            $url = $sr_value;
            $match = preg_match('/[^\/]+$/', $url, $matches);
            $name = $match ? $matches[0] : $url;

            // add the server to the url
            $path = AIR2_UPLOAD_SERVER_URL . $url;
            $val = "<a class=\"external\" target=\"_blank\" href=\"$path\">$name</a>";
            $preview_url = $sr_value;
            $preview_url = preg_replace('/\.jpe?g/i', '.png', $preview_url);
            $preview_url = preg_replace('/\.gif/i', '.png', $preview_url);
            if ($preview_url != $sr_value) {
                $val .= '<div class="air2-preview-img"><img src="'.AIR2_PREVIEW_SERVER_URL.$preview_url.'"/></div>';
            }
        }
        echo $val;
    }
}
