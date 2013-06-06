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

/**
 * Submission Controller
 *
 * @author rcavis
 * @package default
 */
class Submission_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {

        // redmine #7667 redirect all-but-administrators to the reader page
        if (!$this->user->is_system() && !$this->input->get('profile')) {
            $redirect_uri = $this->uri_for(
                'search/responses',
                array('q' => 'srs_uuid:'.$uuid, 'exp' => 1)
            );
            redirect($redirect_uri);
            return;
        }

        // Record a visit by the current user against this SrcResponseSet.
        $srs = AIR2_Record::find('SrcResponseSet', $uuid);
        $srs->visit(
            array(
                'ip' => $this->input->ip_address(),
                'user' => $this->user,
            )
        );


        $src_uuid = $base_rs['radix']['Source']['src_uuid'];
        $inq_uuid = $base_rs['radix']['Inquiry']['inq_uuid'];
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'SRCDATA'   => $this->api->fetch("submission/$uuid/source"),
            'INQDATA'   => $this->api->fetch("submission/$uuid/inquiry"),
            'RESPDATA'  => $this->api->query("submission/$uuid/response", array('limit' => 0, 'sort' => 'ques_dis_seq asc')),
            'ANNOTDATA' => $this->api->query("submission/$uuid/annotation", array('limit' => 6, 'sort' => 'srsan_upd_dtim desc')),
            'TAGDATA'   => $this->api->query("submission/$uuid/tag", array('limit' => 0, 'sort' => 'tag_upd_dtim desc')),
            // paging stuff
            'ALTSUBMS'  => $this->_get_other_subms($src_uuid),
        );

        // show page
        $title = $this->_get_subm_title($base_rs);
        $data = $this->airhtml->get_inline($title, 'Submission', $inline);
        $this->response($data);
    }


    /**
     * Load data for html printing
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_print_html($uuid, $base_rs) {
        $args = array('limit' => 0, 'sort' => 'ques_dis_seq asc');
        $rsp = $this->api->query("submission/$uuid/response", $args);
        $src = $this->api->fetch("submission/$uuid/source");
        $inq = $this->api->fetch("submission/$uuid/inquiry");
        $args = array('limit' => 0, 'sort' => 'srsan_cre_dtim asc');
        $ann = $this->api->query("submission/$uuid/annotation", $args);

        // get sr_annotations
        $args = array('limit' => 0, 'sort' => 'sran_cre_dtim asc');
        foreach ($rsp['radix'] as &$sr) {
            if ($sr['annot_count'] > 0) {
                $srid = $sr['sr_uuid'];
                $rs = $this->api->query("submission/$uuid/response/$srid/annotation", $args);
                $sr['SrAnnotation'] = $rs['radix'];
            }
            else {
                $sr['SrAnnotation'] = array();
            }
        }

        $raw = $base_rs['radix'];
        $raw['SrcResponse']   = $rsp['radix'];
        $raw['Source']        = $src['radix'];
        $raw['Inquiry']       = $inq['radix'];
        $raw['SrsAnnotation'] = $ann['radix'];
        $raw['title']         = $this->_get_subm_title($base_rs);
        $this->airoutput->view = 'print/submission';
        $this->response($raw);
    }


    /**
     * Show a special error for AUTHZ, explaining which users may be contacted
     * to gain access to a submission.
     *
     * @param int $code
     * @param string $msg
     * @param array $rs
     */
    protected function show_html_error($code, $msg, $rs) {
        if ($code == AIRAPI::BAD_AUTHZ) {
            $srs = AIR2_Record::find('SrcResponseSet', $rs['uuid']);
            if (!$srs) {
                show_error('Unable to find SrcResponseSet!!!', 500);
            }

            // find inq-org assignments
            $srs_org_ids = array();
            foreach ($srs->Inquiry->InqOrg as $inqorg) {
                $srs_org_ids[$inqorg->iorg_org_id] = true;
            }

            // find all possible contact-users
            $q = Doctrine_Query::create()->from('ProjectOrg po');
            $q->leftJoin('po.ContactUser cu');
            $q->leftJoin('cu.UserEmailAddress e with e.uem_primary_flag = true');
            $q->leftJoin('po.Project p');
            $q->leftJoin('p.ProjectInquiry pi');
            $q->leftJoin('pi.Inquiry i');
            $q->addWhere("i.inq_id = ?", $srs->srs_inq_id);
            $porgs = $q->fetchArray();

            // determine the contact (no system users)
            $contacts = array();
            foreach ($porgs as $porg) {
                if (isset($srs_org_ids[$porg['porg_org_id']])) {
                    if ($porg['ContactUser']['user_type'] == User::$TYPE_AIR_USER) {
                        $contacts[] = $porg['ContactUser'];
                    }
                }
            }
            if (!count($contacts) && count($porgs)) {
                foreach ($porgs as $porg) {
                    if ($porg['ContactUser']['user_type'] == User::$TYPE_AIR_USER) {
                        $contacts[] = $porg['ContactUser']; //not found - add 1st
                    }
                }
            }

            // translate to markup
            foreach ($contacts as $idx => $user) {
                $f = $user['user_first_name'];
                $l = $user['user_last_name'];
                $u = $user['user_username'];
                $s = '<a href="'.air2_uri_for('/user/'.$user['user_uuid']).'">';
                $s .= ($f && $l) ? "$f $l" : "$u";
                $s .= '</a>';

                // optional mailto
                if (isset($user['UserEmailAddress'][0]['uem_address'])) {
                    $uem = $user['UserEmailAddress'][0]['uem_address'];
                    $s .= ' at '.$this->_mailto_markup($uem, $rs['uuid']);
                }
                $contacts[$idx] = $s;
            }
            if (!count($contacts)) {
                $default = AIR2_SUPPORT_EMAIL;
                $contacts[0] = $this->_mailto_markup($default, $rs['uuid']);
            }

            // text
            $contacts = implode(' or ', $contacts);
            $title = "You do not have access to this response";
            $msg = "You're seeing this message because this source shared this ".
                "particular response with a PIN newsroom that isn't your newsroom. " .
                "If you want access to this response, feel free to contact " .
                "$contacts and ask to have it emailed to you.";
            $msg .= "<br/><br/>";
            $msg .= "Remember: This is a shared network of sources, but responses ".
                "to queries are considered the work product of the newsroom(s) that ".
                "asked the questions. If you do request access to the submission, be ".
                "aware of that. And if you do get access and choose to contact the source ".
                "who responded, be clear about how you learned about their response.";
            $this->airoutput->write_error(403, $title, $msg);
        }
        else {
            return parent::show_html_error($code, $msg, $rs);
        }
    }


    /**
     * Generate a mailto link to request access to a submission.
     *
     * @param  string $email
     * @param  string $srs_uuid
     * @return string $link
     */
    private function _mailto_markup($email, $srs_uuid) {
        $url = air2_uri_for("/submission/$srs_uuid");
        $subj = rawurlencode("Access request for submission $srs_uuid");
        $body = rawurlencode("Submission URL: $url");
        $href = "href=\"mailto:$email?subject=$subj&body=$body\"";
        return "<a class=\"email\" $href>$email</a>";
    }


    /**
     * Get other submissions for this source
     *
     * @param type $srs_uuid
     * @return array $srs_uuids
     */
    private function _get_other_subms($src_uuid) {
        //TODO: is this fast enough?
        $subms = $this->api->query("submission", array(
                'src_uuid' => $src_uuid,
                'limit' => 0,
                'sort' => 'srs_date asc',
            )
        );

        $srs_uuids = array();
        foreach ($subms['radix'] as $srs) {
            $srs_uuids[] = $srs['srs_uuid'];
        }
        return $srs_uuids;
    }


    /**
     * Get a title from the base submission response
     *
     * @param array $base_rs
     * @return string $title
     */
    private function _get_subm_title($base_rs) {
        $uname = $base_rs['radix']['Source']['src_username'];
        $fname = $base_rs['radix']['Source']['src_first_name'];
        $lname = $base_rs['radix']['Source']['src_last_name'];
        $src = ($fname && $lname) ? "$fname $lname" : $uname;
        $inq = $base_rs['radix']['Inquiry']['inq_ext_title'];
        return "$src: $inq - ".AIR2_SYSTEM_DISP_NAME;
    }


}
