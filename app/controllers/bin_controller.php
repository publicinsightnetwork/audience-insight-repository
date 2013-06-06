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

require_once 'AIR2_HTMLController.php';
require_once 'phperl/callperl.php';

/**
 * Bin Controller
 *
 * @author rcavis
 * @package default
 */
class Bin_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param string $uuid
     * @param array  $base_rs
     */
    protected function show_html($uuid, $base_rs) {

        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'SRCDATA'  => $this->api->query("bin/$uuid/srcsub", array('limit' => 15, 'sort' => 'src_last_name asc')),
            'EXPORTS'  => $this->api->query("bin/$uuid/export", array('limit' => 5, 'sort' => 'se_cre_dtim desc')),
        );

        // show page
        $title = $base_rs['radix']['bin_name'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Bin', $inline);
        $this->response($data);
    }


    /**
     * Load data for html printing
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_print_html($uuid, $base_rs) {
        $bin = AIR2_Record::find('Bin', $uuid);
        $base_rs['sources'] = array();

        // authorized sources
        $authz_sources = array();
        $q = Doctrine_Query::create()->from('BinSource bs');
        $q->leftJoin('bs.Source s');
        $q->where('bs.bsrc_bin_id = ?', $bin->bin_id);
        $q->select('bs.bsrc_src_id, s.src_uuid');
        BinSource::query_may_read($q, $this->user, 'bs');
        $bsrcs = $q->fetchArray();
        foreach ($bsrcs as $bsrc) {
            $authz_sources[$bsrc['Source']['src_uuid']] = true;
        }

        // only keep fetching if there is stuff to get
        $authz_responses = array();
        if (count($authz_sources) > 0) {
            $q = Doctrine_Query::create()->from('BinSrcResponseSet bs');
            $q->leftJoin('bs.SrcResponseSet s');
            $q->where('bs.bsrs_bin_id = ?', $bin->bin_id);
            $q->select('bs.bsrs_srs_id, s.srs_uuid');
            BinSrcResponseSet::query_may_read($q, $this->user, 'bs');
            $bsrss = $q->fetchArray();
            foreach ($bsrss as $bsrs) {
                $authz_responses[$bsrs['SrcResponseSet']['srs_uuid']] = true;
            }

            // let perl do the heavy lifting
            $binsources = CallPerl::exec('AIR2::Bin->flatten', $bin->bin_id);
            foreach ($binsources as $src) {
                $src_uuid = $src['src_uuid'];
                if (isset($authz_sources[$src_uuid])) {

                    // apply authz to responses
                    if (is_array($src['response_sets'])) {
                        foreach ($src['response_sets'] as $idx => $srs) {
                            $srs_uuid = $srs['srs_uuid'];
                            if (!isset($authz_responses[$srs_uuid])) {
                                unset($src['response_sets'][$idx]);
                            }
                        }
                        $src['response_sets'] = array_values($src['response_sets']);
                    }

                    // add as value
                    $authz_sources[$src_uuid] = $src;
                }
            }
        }

        // reorganize for the print view
        $raw = array(
            'bin'     => $base_rs['radix'],
            'sources' => array_values($authz_sources),
        );

        $this->airoutput->view = 'print/bin';
        $this->response($raw);
    }


}
