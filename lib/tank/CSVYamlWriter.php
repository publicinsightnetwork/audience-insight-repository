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

require_once 'air2writer/YamlWriter.php';
require_once 'air2validator/ColumnCountValidator.php';
require_once 'air2validator/DoctrineTableValidator.php';
require_once 'air2validator/FactTranslationValidator.php';
require_once 'air2validator/ManualEntryValidator.php';

/**
 * CSV Yaml Data Importer
 *
 * A YamlWriter customized to load all the related tables used in a CSV import.
 *
 * @author rcavis
 * @package default
 */
class CSVYamlWriter extends YamlWriter {
    protected $headers;
    protected $ini;
    protected $map_facts;
    protected $map_preferences;
    protected $map_manual_entry;
    protected $col_valids = array();

    /* manual-entry submission data */
    protected $tank_me_validator;
    protected $tank_me_inq_id = false;
    protected $tank_me_ques_ids = array();


    /**
     * Constructor
     *
     * Make sure temp-file directory is writable.
     *
     * @param Tank    $t
     * @param array   $ini
     * @param array   $csv_headers
     */
    function __construct(Tank $t, $ini, $csv_headers) {
        $this->ini = $ini;
        $this->headers = $csv_headers;

        // create the mapping config
        $config = array(
            'TankSource' => array(
                'tsrc_tank_id' => array('val' => $t->tank_id),
                'tsrc_cre_user' => array('val' => $t->tank_cre_user),
                'tsrc_upd_user' => array('val' => $t->tank_upd_user),
                'tsrc_cre_dtim' => array('val' => air2_date()),
                'tsrc_upd_dtim' => array('val' => air2_date()),
            ),
            'TankFact' => array(),
            'TankVita' => array(),
            'TankResponseSet' => array(),
            'TankResponse' => array(),
            'TankPreference' => array(),
        );

        // setup mapping
        foreach ($csv_headers as $idx => $col) {
            // only tank_fld mappings
            $def = $ini[$col];
            if (isset($def['tank_fld'])) {
                $this->col_valids[$idx] = "TankSource:".$def['tank_fld'];
                $config['TankSource'][$def['tank_fld']] = array('map' => $idx);
            }
            if (isset($def['vita_type'])) {
                $this->col_valids[$idx] = "TankVita:".$def['tank_vita_fld'];

                // setup different types for interests/experience
                $type = $def['vita_type'];
                if (!isset($config['TankVita'][$type])) {
                    $config['TankVita'][$type] = array();
                }
                $config['TankVita'][$type][$def['tank_vita_fld']] = array('map' => $idx);
            }
        }

        // cache fact mappings from headers
        $this->cache_fact_mappings($csv_headers, $ini);

        //cache preference mappings from headers
        $this->cache_preference_mappings($csv_headers, $ini);

        // cache manual-entry mappings from headers
        $this->init_manual_entry($t, $csv_headers, $ini);

        // call parent
        parent::__construct($t->get_folder_path().'/yaml', $config);
    }


    /**
     * Override to provide our own validators
     *
     * @param AIR2_Reader $reader
     * @param array   $validators (optional)
     * @return int the number of items successfully written
     */
    public function write_data(AIR2_Reader $reader, $validators=array()) {
        $validators[] = new ColumnCountValidator(count($this->headers));
        $validators[] = new DoctrineTableValidator($this->col_valids);
        $validators[] = new FactTranslationValidator($this->map_facts, $this->headers);
        $validators[] = $this->tank_me_validator;
        return parent::write_data($reader, $validators);
    }


    /**
     * Cache any fact mappings in the csv header
     *
     * @param array   $headers
     * @param array   $ini
     */
    protected function cache_fact_mappings($headers, $ini) {
        $conn = AIR2_DBManager::get_connection();
        $q = 'select fact_id from fact where fact_identifier = ?';

        // fact_id => array(colidx => fldname)
        $this->map_facts = array();

        // lookup fact fields in header def
        foreach ($headers as $idx => $col) {
            if (isset($ini[$col]) && isset($ini[$col]['fact'])) {
                $ident = $ini[$col]['fact'];
                $fldname = $ini[$col]['tank_fact_fld'];
                $map = isset($ini[$col]['map']) ? $ini[$col]['map'] : false;

                // lookup fact_id
                $fact_id = $conn->fetchOne($q, array($ident), 0);
                if (!isset($this->map_facts[$fact_id])) {
                    $this->map_facts[$fact_id] = array();
                }

                // add this mapping
                $this->map_facts[$fact_id][$idx] = $fldname;
            }
        }
    }

    /**
     * Cache any preferences in the CSV header
     *
     * @param array $headers
     * @param array $ini
     */

    protected function cache_preference_mappings($headers, $ini) {
        $conn = AIR2_DBManager::get_connection();
        $q = 'select pt_id from preference_type where pt_identifier = ?';

        $this->map_preferences = array();

        foreach($headers as $idx=>$col) {
            if (isset($ini[$col]) && isset($ini[$col]['pref'])) {
                $ident = $ini[$col]['pref'];
                $field_name = $ini[$col]['tank_pref_fld'];
                $map = isset($ini[$col]['map']) ? $ini[$col]['map'] : false;

                //look up pt_id
                $preference_id = $conn->fetchOne($q, array($ident), 0);
                if (!isset($this->map_preferences[$preference_id])) {
                    $this->map_preferences[$preference_id] = array();
                }

                //add this mapping
                $this->map_preferences[$preference_id][$idx] = $field_name;

            }
        }
    }

    /**
     * Cache any manual-entry mappings found in the csv header, and make sure
     * we have the correct ones.
     *
     * @param Tank    $tank
     * @param array   $headers
     * @param array   $ini
     */
    protected function init_manual_entry($tank, $headers, $ini) {
        // create validator
        $this->tank_me_validator = new ManualEntryValidator($headers, $ini);
        if ($this->tank_me_validator->validate_headers() === true) {
            //NOTE: for now, disable any additional activities
            /*$actv_rec = false;
            $actv_prj_id = false;
            $actv_dtim = air2_date(); //default

            // make sure we have a "Manual Submission" activity
            foreach ($tank->TankActivity as $tact) {
                $actv_dtim = $tact->tact_dtim;
                if ($tact->tact_prj_id) $actv_prj_id = $tact->tact_prj_id;
                if ($tact->tact_actm_id == ActivityMaster::MANUAL_SUBM) {
                    $actv_rec = $tact;
                    break;
                }
            }

            // create if DNE
            if (!$actv_rec) {
                // get a prj_id from somewhere!
                if (!$actv_prj_id) {
                    if (count($tank->TankOrg) > 0) {
                        $actv_prj_id = $tank->TankOrg[0]->org_default_prj_id;
                    }
                    else {
                        $actv_prj_id = 1; //sys default
                    }
                }
                $actv_rec = new TankActivity();
                $actv_rec->tact_tank_id = $tank->tank_id;
                $actv_rec->tact_type = TankActivity::$TYPE_SOURCE;
                $actv_rec->tact_actm_id = ActivityMaster::MANUAL_SUBM;
                $actv_rec->tact_prj_id = $actv_prj_id;
                $actv_rec->tact_dtim = $actv_dtim;
                $actv_rec->tact_desc = "Uploaded Submissions";
                $actv_rec->tact_xid = $tank->tank_id;
                $actv_rec->tact_ref_type = SrcActivity::$REF_TYPE_TANK;
                $actv_rec->save();
            }*/

            // need the inq_id and ques_ids
            $tank->refreshRelated('TankActivity');
            $actv = count($tank->TankActivity) ? $tank->TankActivity[0] : null;
            $prj = $actv ? $actv->Project : null;
            if (!$prj) {
                throw new Exception("No activity or project set for tank record!");
            }
            $inq = $prj->get_manual_entry_inquiry();
            $this->tank_me_inq_id = $inq->inq_id;
            foreach ($inq->Question as $ques) {
                $this->tank_me_ques_ids[] = $ques->ques_id;
            }
        }
    }


    /**
     * Get yaml data
     *
     * @param array   $obj       data to write
     * @param array   $modelname model to write to
     * @param int     $idx       object number we're writing
     * @param array   $fields    field mapping def
     * @return array data
     */
    protected function get_yaml_data($obj, $modelname, $idx, $fields) {
        if ($modelname == 'TankFact') {
            return $this->get_facts($obj, $idx, $fields);
        }
        elseif ($modelname == 'TankVita') {
            return $this->get_vitae($obj, $idx, $fields);
        }
        elseif ($modelname == 'TankResponseSet') {
            return $this->get_response_sets($obj, $idx, $fields);
        }
        elseif ($modelname == 'TankResponse') {
            return $this->get_responses($obj, $idx, $fields);
        }
        elseif ($modelname == 'TankPreference') {
            return $this->get_preferences($obj, $idx, $fields);
        }
        else {
            return parent::get_yaml_data($obj, $modelname, $idx, $fields);
        }
    }


    /**
     * Get facts from row object
     *
     * @param array   $obj    row object
     * @param int     $idx    row index
     * @param array   $fields field mapping def
     * @return array data
     */
    protected function get_facts($obj, $idx, $fields) {
        $facts = array();

        // determine if there are any facts to write
        foreach ($this->map_facts as $fid => $mapcols) {
            $sf = array();
            foreach ($mapcols as $colidx => $fldname) {
                $val = $obj[$colidx];
                if ($val && strlen($val)) $sf[$fldname] = $val;
            }

            // normalize and translate src_value text
            if (isset($sf['sf_src_value'])) {
                $sf['sf_src_value'] = air2_str_clean($sf['sf_src_value']);
                $fv_id = TranslationMap::find_translation($fid, $sf['sf_src_value']);
                if ($fv_id) $sf['sf_fv_id'] = $fv_id;
            }

            // ignore empty/null facts
            if (count($sf)) {
                $sf['TankSource'] = "TankSource_$idx";
                $sf['tf_fact_id'] = $fid;
                $facts["TankFact_{$idx}_{$fid}"] = $sf;
            }
        }

        // return false for no data
        if (count($facts) == 0) {
            return false;
        }
        else {
            return $facts;
        }
    }

    /**
     * Get Preferences from row object
     *
     * @param array   $obj    row object
     * @param int     $idx    row index
     * @param array   $fields field mapping def
     * @return array data
     */

    protected function get_preferences($obj, $idx, $fields) {
        $preferences = array();
        $source_preference = array();
        foreach ($this->map_preferences as $pref_id => $mapcols) {
            foreach ($mapcols as $colidx => $fldname) {
                $val = $obj[$colidx];
                if ($val && strlen($val)) $source_preference[$fldname] = $val;

                if (isset($source_preference['sp_ptv_id'])) {
                    $source_preference['sp_ptv_id'] = air2_str_clean($source_preference['sp_ptv_id']);
                }

                //ignore empty and null preferences
                if (count($source_preference)) {
                    $source_preference['TankSource'] = "TankSource_$idx";
                    $preferences["TankPreference_{$idx}_{$pref_id}"] = $source_preference;
                }

            }
        }

        if (count($source_preference) == 0) {
            return false;
        }
        else {
            return $preferences;
        }
    }


    /**
     * Get vita from row object
     *
     * @param array   $obj    row object
     * @param int     $idx    row index
     * @param array   $fields field mapping def
     * @return array data
     */
    protected function get_vitae($obj, $idx, $fields) {
        $vitae = array();

        // determine if there is any vita to write
        foreach ($fields as $vita_type => $type_columns) {
            $sv = array();
            foreach ($type_columns as $fldname => $def) {
                $val = $obj[$def['map']];
                if ($val && strlen($val)) {
                    $sv[$fldname] = air2_str_clean($val);
                }
            }

            // ignore empty/null vita
            if (count($sv)) {
                $sv['TankSource'] = "TankSource_$idx";
                $sv['sv_type'] = $vita_type;
                $vitae["TankVita_{$idx}_{$vita_type}"] = $sv;
            }
        }

        // return false for no data
        if (count($vitae) == 0) {
            return false;
        }
        else {
            return $vitae;
        }
    }


    /**
     * Get response sets from row object
     *
     * @param array   $obj    row object
     * @param int     $idx    row index
     * @param array   $fields field mapping def
     * @return array data
     */
    protected function get_response_sets($obj, $idx, $fields) {
        if (!$this->tank_me_inq_id) return false;

        $date = $this->tank_me_validator->extract('date', $obj);
        $date = air2_date(strtotime($date));
        return array(
            "TankResponseSet_{$idx}" => array(
                "TankSource" => "TankSource_{$idx}",
                "srs_inq_id" => $this->tank_me_inq_id,
                "srs_type"   => SrcResponseSet::$TYPE_MANUAL_ENTRY,
                "srs_date"   => $date,
            ),
        );
    }


    /**
     * Get responses from row object
     *
     * @param array   $obj    row object
     * @param int     $idx    row index
     * @param array   $fields field mapping def
     * @return array data
     */
    protected function get_responses($obj, $idx, $fields) {
        if (!$this->tank_me_inq_id) return false;

        // get input, and normalize
        $type = $this->tank_me_validator->extract('type', $obj);
        $desc = $this->tank_me_validator->extract('desc', $obj);
        $desc = air2_str_clean($desc);
        $text = $this->tank_me_validator->extract('text', $obj);
        $text = air2_str_clean($text);
        return array(
            "TankResponse_{$idx}_type" => array(
                "TankSource" => "TankSource_{$idx}",
                "TankResponseSet" => "TankResponseSet_{$idx}",
                "sr_ques_id" => $this->tank_me_ques_ids[0],
                "sr_orig_value" => $type,
            ),
            "TankResponse_{$idx}_desc" => array(
                "TankSource" => "TankSource_{$idx}",
                "TankResponseSet" => "TankResponseSet_{$idx}",
                "sr_ques_id" => $this->tank_me_ques_ids[1],
                "sr_orig_value" => $desc,
            ),
            "TankResponse_{$idx}_text" => array(
                "TankSource" => "TankSource_{$idx}",
                "TankResponseSet" => "TankResponseSet_{$idx}",
                "sr_ques_id" => $this->tank_me_ques_ids[2],
                "sr_orig_value" => $text,
            ),
        );
    }

}
