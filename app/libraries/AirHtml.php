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
 * AirHtml Library
 *
 * Helper function for HTML
 *
 * @author rcavis
 * @package default
 */


class AirHtml {


    /**
     *
     * @return array $js_paths
     */
    public static function third_party_js() {
        return array(
            'lib/extjs/adapter/ext/ext-base.js',
            'lib/extjs/ext-all.js',
            'lib/extjs/examples/ux/datetime.js',
            'lib/extjs/examples/ux/RowEditor.js',
            'lib/extjs/examples/ux/Spinner.js',
            'lib/extjs/examples/ux/SpinnerField.js',
            'lib/extjs/examples/ux/FileUploadField.js',
            'lib/shared/groupcombo.js',
            'lib/shared/groupdataview.js',
            'lib/shared/livedataview.js',
            'lib/shared/search-query.js',
            'lib/shared/hyphenator.js',
            'lib/shared/long.js',
            'lib/ckeditor/ckeditor.js',
            'lib/shared/leafpile.js',
            'lib/shared/jquery-1.7.2.min.js',
            'lib/shared/slidemapper.min.js',
            'lib/extjs/plugins/date-time-ux.js',
        );
    }


    /**
     *
     * @return array $css_paths
     */
    public static function third_party_css() {
        return array(
            'lib/extjs/resources/css/ext-all.css',
            'css/ext-theme-air2.css',
            'lib/extjs/examples/ux/css/RowEditor.css',
            'lib/extjs/examples/ux/css/Spinner.css',
            'lib/extjs/examples/ux/css/FileUploadField.css',
            'lib/shared/livedataview.css',
            'lib/shared/slidemapper.min.css',
        );
    }


    /**
     * Get an array of javascript includes
     *
     * @return array $js
     */
    public function js_includes() {
        // only need compressed file, if it exists
        if (file_exists(AIR2_DOCROOT.'/js/air2-compressed.js')) {
            return array(air2_uri_for('js/air2-compressed.js'));
        }

        // recursively scan js directory
        $js = air2_dirscan(AIR2_DOCROOT.'/js/', '/.js$/');
        air2_array_remove(array('pinform.js'), $js);
        air2_array_remove(array('pinform.min.js'), $js);
        air2_array_remove(array('third_party.js'), $js);

        // fix order (for inheritance), and remove console.js for prod
        $js = air2_fix_js_order($js);
        if (AIR2_ENVIRONMENT == 'prod') {
            air2_array_remove('console.js', $js);
        }

        // change to absolute paths
        foreach ($js as &$file) {
            $mtime = filemtime(AIR2_DOCROOT.'/js/'.$file);
            $file = air2_uri_for("js/$file", array('_'=>$mtime));
        }
        return $js;
    }


    /**
     * Get an array of css includes
     *
     * @return array $css
     */
    public function css_includes() {

        // only need compressed file, if it exists
        if (file_exists(AIR2_DOCROOT.'/css/air2-compressed.css')) {
            return array(air2_uri_for('css/air2-compressed.css'));
        }

        // recursively scan css directory
        $css = air2_dirscan(AIR2_DOCROOT.'/css/', '/.css$/');
        $rmv = array('docbook.css', 'login.css', 'ie.css', 'print.css', 'ext-theme-air2.css', 'query.css', 'pinform.css', 'third_party.css');
        air2_array_remove($rmv, $css);

        // change to absolute paths
        foreach ($css as &$file) {
            $mtime = filemtime(AIR2_DOCROOT.'/css/'.$file);
            $file = air2_uri_for("css/$file", array('_'=>$mtime));
        }
        return $css;
    }


    /**
     * Get inline-js data, to be rendered as an Extjs html page.
     *
     * @param string $title
     * @param string $js_namespace
     * @param array $data
     * @return unknown
     */
    public function get_inline($title, $js_namespace, $data) {
        // format to what view expects
        $data = array(
            'namespace' => $js_namespace,
            'data' => $data,
        );

        // render as extjs json
        $CI =& get_instance();
        $extjs = $CI->load->view('extjs', $data, true);

        // return html-page inline data
        return array(
            'head' => array(
                'title' => $title,
                'js'    => $this->js_includes(),
                'css'   => $this->css_includes(),
                'misc'  => '',
            ),
            'body' => $extjs,
        );
    }


    /**
     * Get the old inline-view format.
     *
     * @param string $title
     * @param array  $payload
     * @param string $view
     * @return unknown
     */
    public function get_deprecated_inline($title, $payload, $view) {
        $CI =& get_instance();
        $js = $CI->load->view($view, $payload, true);

        // return html-page inline data
        return array(
            'head' => array(
                'title' => $title,
                'js'    => $this->js_includes(),
                'css'   => $this->css_includes(),
                'misc'  => '',
            ),
            'body' => $js,
        );
    }


}
