<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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

require_once DOCPATH.'/Doctrine/Validator/Driver.php';

/**
 * Doctrine Validator AirValidHtml
 *
 * Custom Doctrine Validator type to check basic soundness of html
 * Table definitions should include this in their column definitions.
 * For example:
 *
 *    $this->hasColumn('something', 'string', 16, array(
 *        'airvalidhtml' => array(
 *            'display' => 'Some Thing',
 *            'message' => 'Not well formed html',
 *        ),
 *    ));
 *
 * @author astevenson
 * @package default
 */
class Doctrine_Validator_AirValidHtml extends Doctrine_Validator_Driver {


    /**
     * Validate a field value
     *
     * @param mixed   $value
     * @return boolean
     */
    public function validate($value) {
        $errs = $this->invoker->getErrorStack();

        // don't run on null values
        if (is_null($value)) {
            return true;
        }

        // preserve current settings
        $prev = libxml_use_internal_errors(true);

        // this provides a backstop against things like anchors without closing
        // tags breaking the interface in AIR or the published query.

        // need a detailed doctype
        $buffer_top = '<?xml version="1.0" encoding="utf-8"?> ' .
            '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" ' .
            '"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"> ' .
            '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">' .
            '<head>' .
            '<meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />' .
            '<title>Untitled</title>' .
            '</head>' .
            '<body>';

        $buffer_bottom = '</body>' .  '</html>';

        $faux_xml = $buffer_top . $value . $buffer_bottom;

        $domDoc = new DOMDocument();

        $domDoc->loadXML($faux_xml);

        $xml_errors = libxml_get_errors();
        if ($xml_errors) {
            $should_alert = false;

            $error_buffer = ' Details: ';

            foreach ($xml_errors as $error) {
                // avoids choking on HTML Entities
                if ($error->level > 2) {
                    $should_alert = true;
                    $error_buffer .= $error->message;
                }
            }

            if ($should_alert) {
                $errs->add(
                    $this->getArg('display'),
                    $this->getArg('message') . $error_buffer
                );
            }
        }

        libxml_clear_errors();

        // reset settings
        libxml_use_internal_errors($prev);

        return true;
    }


}
