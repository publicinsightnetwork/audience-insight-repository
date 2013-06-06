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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * Inquiry/Logo API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Logo extends AIRAPI_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('fetch', 'create', 'update', 'delete');
    protected $CREATE_DATA = array('logo');
    protected $UPDATE_DATA = array('logo');

    // metadata
    protected $ident = 'img_uuid';
    protected $fields = array(
        'DEF::IMAGE',
    );


    /**
     * Create
     *
     * @param array   $data
     * @return Doctrine_Record $rec
     */
    protected function rec_create($data) {
        $this->check_authz($this->parent_rec, 'write');
        $this->require_data($data, array('logo'));
        try {
            $this->parent_rec->Logo = new ImageInqLogo();
            $this->parent_rec->Logo->set_image($data['logo']);
        }
        catch (Exception $e) {
            throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
        }

        // save
        $this->parent_rec->save();
        return $this->parent_rec->Logo->img_uuid;
    }


    /**
     * Update
     *
     * @param Doctrine_Record $logo
     * @param array   $data
     * @return string $uuid
     */
    protected function rec_update($logo, $data) {
        $this->check_authz($logo->Inquiry, 'write');
        $this->require_data($data, array('logo'));
        try {
            $logo->set_image($data['logo']);
        }
        catch (Exception $e) {
            throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
        }

        // save
        $logo->save();
        return $logo->img_uuid;
    }


    /**
     * Delete the image
     *
     * @throws Rframe_Exceptions
     * @param object  $rec
     */
    protected function rec_delete($logo) {
        $this->check_authz($logo->Inquiry, 'write');
        $logo->delete();
        $this->parent_rec->clearRelated('Logo');
        $this->update_parent($logo);
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        if (!$this->parent_rec->Logo) {
            throw new Rframe_Exception(RFrame::ONE_DNE, 'Logo not set');
        }
        return $this->parent_rec->Logo;
    }


}
