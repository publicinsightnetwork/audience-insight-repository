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

require_once 'shared/phmagick/phmagick.php';

/**
 * Image assets for AIR
 *
 * @property integer   $img_id
 * @property integer   $img_uuid
 * @property integer   $img_xid
 * @property string    $img_ref_type
 *
 * @property string    $img_file_name
 * @property integer   $img_file_size
 * @property string    $img_content_type
 *
 * @property integer   $img_cre_user
 * @property integer   $img_upd_user
 * @property timestamp $img_cre_dtim
 * @property timestamp $img_upd_dtim
 *
 * @author  rcavis
 * @package default
 */
class Image extends AIR2_Record {

    /* define types of images */

    // NOTE sizes are width, height
    public static $CONFIG = array(
        'A' => array(
            'class'      => 'ImageUserAvatar',
            'directory'  => 'user',
            'filename'   => 'avatar',
            'convert_to' => 'png',
            'sizes'      => array(
                'thumb'  => array(100, 100),
                'medium' => array(300, 300),
            ),
        ),
        'B' => array(
            'class'      => 'ImageOrgBanner',
            'directory'  => 'org',
            'filename'   => 'banner',
            'convert_to' => 'png',
            'sizes'      => array(
                'thumb'  => array(150, 150),
                'medium' => array(500, 0),
            ),
        ),
        'L' => array(
            'class'      => 'ImageOrgLogo',
            'directory'  => 'org',
            'filename'   => 'logo',
            'convert_to' => 'png',
            'sizes'      => array(
                'thumb'  => array(50, 50),
                'medium' => array(200, 200),
                'large'  => array(400, 400),
            ),
        ),
        'E' => array(
            'class'      => 'ImageEmailLogo',
            'directory'  => 'email',
            'filename'   => 'logo',
            'convert_to' => 'png',
            'sizes'      => array(
                'thumb'  => array(50, 50),
                'medium' => array(200, 200),
                'large'  => array(400, 400),
            ),
        ),
        'Q' => array(
            'class'      => 'ImageInqLogo',
            'directory'  => 'query',
            'filename'   => 'logo',
            'convert_to' => 'png',
            'sizes'      => array(
                'thumb'  => array(50, 50),
                'medium' => array(200, 200),
                'large'  => array(400, 400),
            ),
        ),
    );

    // used to trigger image operations on postSave
    protected $_set_image = false;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('image');

        // identifiers and foreign keys
        $this->hasColumn('img_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('img_uuid', 'string', 12, array(
                'fixed'   => true,
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('img_xid', 'integer', 4, array('notnull' => true));
        $this->hasColumn('img_ref_type', 'string', 1, array('notnull' => true));

        // file metadata
        $this->hasColumn('img_file_name',    'string', 128,     array());
        $this->hasColumn('img_file_size',    'integer', 4,      array());
        $this->hasColumn('img_content_type', 'string', 64,      array());
        $this->hasColumn('img_dtim',         'timestamp', null, array());

        // stamps
        $this->hasColumn('img_cre_user', 'integer', 4, array('notnull' => true));
        $this->hasColumn('img_upd_user', 'integer', 4, array());
        $this->hasColumn('img_cre_dtim', 'timestamp', null, array('notnull' => true));
        $this->hasColumn('img_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();

        // subclasses (must also be in models directory)
        $subclasses = array();
        foreach (self::$CONFIG as $ref_type => $def) {
            $subclasses[$def['class']] = array('img_ref_type' => $ref_type);
        }
        $this->setSubclasses($subclasses);
    }


    /**
     * Static calculator of image directories.  By default, this is an absolute
     * filesystem path.
     *
     * @param char    $ref_type
     * @param string  $img_uuid
     * @param bool    $relative_path
     * @return string $path
     */
    public static function get_directory($ref_type, $img_uuid, $relative_path=false) {
        $root = $relative_path ? '' : AIR2_DOCROOT;
        $middle = self::$CONFIG[$ref_type]['directory'];
        return "$root/img/$middle/$img_uuid/";
    }



    /**
     * Returns path to original uploaded asset.
     *
     * @return string
     */
    public function get_path_to_orig_asset() {
        $dir = self::get_directory($this->img_ref_type, $this->img_uuid);
        return realpath($dir.$this->img_file_name);
    }


    /**
     * Static calculator of image paths.  By default, these are absolute
     * filesystem paths.
     *
     * @param char    $ref_type
     * @param string  $img_uuid
     * @param unknown $as_uri   (optional)
     * @param string  $dtim
     * @return array  $paths
     */
    public static function get_images($ref_type, $img_uuid, $as_uri=false, $dtim=null) {
        $dir  = self::get_directory($ref_type, $img_uuid, $as_uri);
        $ext  = self::$CONFIG[$ref_type]['convert_to'];
        $name = self::$CONFIG[$ref_type]['filename'];

        $images = array('original' => "{$dir}{$name}.{$ext}");
        if ($as_uri) {
            $images['original'] = air2_uri_for($images['original']);
            if ($dtim) $images['original'] .= '?' . strtotime($dtim);
        }

        foreach (self::$CONFIG[$ref_type]['sizes'] as $size => $dim) {
            $images[$size] = "{$dir}{$name}_{$size}.{$ext}";
            if ($as_uri) {
                $images[$size] = air2_uri_for($images[$size]);
                if ($dtim) $images[$size] .= '?' . strtotime($dtim);
            }
        }
        return $images;
    }


    /**
     * Custom setter to disallow directly modifying image metadata, and allow
     * setting the "image" key.
     *
     * @param unknown $fld
     * @param unknown $value
     * @param unknown $load  (optional)
     * @return unknown
     */
    public function set($fld, $value, $load=true) {
        if (in_array($fld, array('img_file_name', 'img_file_size', 'img_content_type', 'img_dtim'))) {
            throw new Exception("Directly setting $fld not allowed!  Set the 'image' attribute instead.");
        }
        return parent::set($fld, $value, $load);
    }


    /**
     * Custom setter for the image.
     *
     * @param array|string $image
     */
    public function set_image($image) {
        if (is_array($image)) {
            $name = $image['name'];
            $path = $image['tmp_name'];
        }
        elseif (is_string($image) && is_readable($image)) {
            $name = basename($image);
            $path = $image;
        }

        // validate image
        if (!is_readable($path)) {
            throw new Exception("Invalid image path: {$path}");
        }
        $img_info = getimagesize($path);
        if (!$img_info) {
            throw new Exception("Invalid image file: {$name}");
        }

        // check/create image directory
        if (!$this->img_uuid) $this->img_uuid = air2_generate_uuid();
        $dir = self::get_directory($this->img_ref_type, $this->img_uuid);
        air2_mkdir($dir);
        if (!is_writable($dir)) {
            throw new Exception("Cannot write to: $dir");
        }

        // looks okay... raw-set the info
        $this->_set('img_file_name', air2_fileify($name));
        $this->_set('img_file_size', filesize($path));
        $this->_set('img_content_type', $img_info['mime']);
        $this->_set('img_dtim', air2_date());
        $this->_set_image = $path;
    }


    /**
     * Custom getter for the "image", which returns both the original image and
     * any resized ones.
     *
     * @param unknown $as_uri (optional)
     * @return unknown
     */
    public function get_image($as_uri=false) {
        if (!$this->exists() || !$this->img_dtim) {
            return null;
        }
        elseif ($as_uri) {
            $images = self::get_images($this->img_ref_type, $this->img_uuid, true, $this->img_dtim);
            return $images;
        }
        else {
            return self::get_images($this->img_ref_type, $this->img_uuid);
        }
    }


    /**
     * Make sure we have a file
     *
     * @param unknown $event
     */
    public function preValidate($event) {
        parent::preValidate($event);
        if (!$this->img_file_name) {
            throw new Exception('Image cannot be null!');
        }
    }


    /**
     * Do the actual image writing/conversion
     *
     * @param unknown $event
     */
    public function postSave($event) {
        parent::postSave($event);

        if ($this->_set_image) {
            $this->make_sizes();
        }
    }


    /**
     * Create all the normalized sizes for the Image. Called by postSave().
     */
    public function make_sizes() {
        if (!isset($this->_set_image)) {
            Carper::croak("image not set for " . $this->img_uuid);
        }
        $dir  = self::get_directory($this->img_ref_type, $this->img_uuid);
        $ext  = self::$CONFIG[$this->img_ref_type]['convert_to'];
        $name = self::$CONFIG[$this->img_ref_type]['filename'];

        // remove old files, and copy a new one
        array_map("unlink", glob("$dir/*"));
        $fname = $this->img_file_name;
        copy($this->_set_image, "{$dir}{$fname}");

        // convert at full resolution
        $p = new phMagick($this->_set_image, "{$dir}{$name}.{$ext}");
        $p->convert();

        // resized versions
        foreach (self::$CONFIG[$this->img_ref_type]['sizes'] as $size => $dim) {
            $p = new phMagick($this->_set_image, "{$dir}{$name}_{$size}.{$ext}");
            if ($dim[0] == 0 || $dim[1] == 0) {
                $p->resize($dim[0], $dim[1]);
            }
            elseif (is_a($this, 'ImageOrgLogo')) {
                $p->resize($dim[0], $dim[1]);
            }
            else {
                $p->resizeExactly($dim[0], $dim[1]);
            }
        }
        $this->_set_image = false;
    }


    /**
     * Cleanup on delete
     *
     * @param unknown $event
     */
    public function postDelete($event) {
        if ($this->img_uuid) {
            $dir = self::get_directory($this->img_ref_type, $this->img_uuid);
            air2_rmdir($dir);
        }
        parent::postDelete($event);
    }


}
