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

require_once APPPATH.'/api/outcome.php';

/**
 * Inquiry/Outcome API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Outcome extends AAPI_Outcome {

    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = parent::air_query($args);

        $inq_id = $this->parent_rec->inq_id;
        $outs = "select iout_out_id from inq_outcome where iout_inq_id=$inq_id";
        $q->addWhere("o.out_id in ($outs)");
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $rec = parent::air_create($data);
        $rec->InqOutcome[0]->iout_inq_id = $this->parent_rec->inq_id;
        return $rec;
    }


}
