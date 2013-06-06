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

require_once 'Cache.php';

/**
 * Controller in charge of outputting all RSS feeds from air2.
 *
 * @package default
 */
class Rss_Controller extends Base_Controller {


    /**
     * RSS feed for displaying a project's - or multiple projects' - inquiries.
     *
     * @return void
     * @param string  $prj_name (optional)
     */
    public function project($prj_name=null) {

        // only RSS available
        $this->airoutput->view = 'rss';
        $this->airoutput->format = 'application/rss+xml';

        $project = null;
        $inquiries = null;
        if ($prj_name) {
            // Sanitize and standardize prj_name.
            $prj_name = strtolower($prj_name);

            // Get actual project, to tailor the feed.
            $q = Doctrine_Query::create()->from('Project p');
            $q->leftJoin('p.OrgDefault');
            $q->andWhere('lower(prj_name) = ?', $prj_name);

            $project = $q->fetchOne();

            if (!$project) {
                show_404();
                return;
            }

            $inquiries = $project->get_inquiries_in_rss_feed();
        }
        else {
            $inquiries = Inquiry::get_all_published_rss();
        }


        // Publish date of the feed. Default to now, in case there are no inquiries.
        $pub_date = $this->_rss_datetime();

        if (count($inquiries) > 0) {
            // Use the publish date and time of the most recent inquiry as the
            // publish date-time of the feed.
            $pub_date = $this->_rss_datetime($inquiries[0]->inq_publish_dtim);
        }

        $items = $this->_build_inquiries_feed($inquiries);

        // defaults
        $title = 'Queries from the Public Insight Network';
        $description = 'Answer these questions to inform Public Insight Network reporting.  Share what you know!';
        $link = 'http://www.publicinsightnetwork.org';
        $logo_uri = 'http://www.publicinsightnetwork.org/user/signup/support/standard/images/apm.jpg';
        $cache_path = Project::get_combined_rss_cache_path();

        // override defaults is we were asked for a specific project
        if ($project && count($project->OrgDefault) > 0) {
            $org = $project->OrgDefault[0];
            $logo = $org->Logo;
            if ($logo) {
                $logo_uris = $logo->get_image(true);
                if (trim($logo_uris['original'])) {
                    $logo_uri = $logo_uris['original'];
                }
            }
            if (strlen($org->org_summary)) {
                $description = $org->org_summary;
            }
            if (strlen($org->org_site_uri)) {
                $link = $org->org_site_uri;
            }
        }
        // title and cache regardless of OrgDefault
        if ($project) {
            $title = $project->prj_display_name;
            $cache_path = $project->get_rss_cache_path();
        }

        $this->_build_response($items, $title, $description, $link, $logo_uri, $pub_date, $cache_path);

    }


    /**
     * RSS feed for displaying an organization's inquiries.
     *
     * @return void
     * @param string  $org_name
     */
    public function org($org_name=null) {

        if (!isset($org_name)) {
            show_404();
            return;
        }

        // only RSS available
        $this->airoutput->view = 'rss';
        $this->airoutput->format = 'application/rss+xml';

        $org = null;
        $inquiries = null;
        // Sanitize and standardize name.
        $org_name = strtolower($org_name);

        // Get actual org, to tailor the feed.
        $q = Doctrine_Query::create()->from('Organization o');
        $q->andWhere('lower(org_name) = ?', $org_name);

        $org = $q->fetchOne();

        if (!$org) {
            show_404();
            return;
        }

        $inquiries = $org->get_inquiries_in_rss_feed();

        // Publish date of the feed. Default to now, in case there are no inquiries.
        $pub_date = $this->_rss_datetime();

        if (count($inquiries) > 0) {
            // Use the publish date and time of the most recent inquiry as the
            // publish date-time of the feed.
            $pub_date = $this->_rss_datetime($inquiries[0]->inq_publish_dtim);
        }

        $items = $this->_build_inquiries_feed($inquiries);

        // defaults
        $title = $org->org_display_name;
        $description = 'Answer these questions to inform Public Insight Network reporting.  Share what you know!';
        $link = 'http://www.publicinsightnetwork.org';
        $logo_uri = 'http://www.publicinsightnetwork.org/user/signup/support/standard/images/apm.jpg';

        if (strlen($org->org_summary)) {
            $description = $org->org_summary;
        }
        if (strlen($org->org_site_uri)) {
            $link = $org->org_site_uri;
        }
        $logo = $org->Logo;
        if ($logo) {
            $logo_uris = $logo->get_image(true);
            if (trim($logo_uris['original'])) {
                $logo_uri = $logo_uris['original'];
            }
        }
        $cache_path = $org->get_rss_cache_path();

        $this->_build_response($items, $title, $description, $link, $logo_uri, $pub_date, $cache_path);

    }



    /**
     *
     *
     * @param array   $inquiries
     * @return array $items
     */
    private function _build_inquiries_feed($inquiries) {
        $items = array();
        foreach ($inquiries as $inq) {
            $authors = $inq->get_authors();
            if (!count($authors)) {
                $authors = array($inq->CreUser);
            }
            $authors_str = array();
            foreach ($authors as $author) {
                $authors_str[] = sprintf("%s %s", $author->user_first_name, $author->user_last_name);
            }
            $item = array(
                'guid'        => $inq->inq_uuid,
                'title'       => $inq->inq_ext_title,
                'description' => $inq->inq_rss_intro,
                'link'        => '',
                'pubDate'     => $this->_rss_datetime($inq->inq_publish_dtim),
                'author'      => implode(', ', $authors_str),
            );

            // inq_url can be set explicitly, esp if the query is being embedded on a non-pin site.
            if ($inq->inq_url) {
                $item['link'] = $inq->inq_url;
            }
            else {
                // AIR2_FORM_URL is the base of the URI.
                $item['link'] = $inq->get_uri();
            }

            $items []= $item;
        }
        return $items;
    }


    /**
     *
     *
     * @param array   $items
     * @param string  $title
     * @param string  $description
     * @param string  $link
     * @param string  $logo_uri
     * @param string  $pub_date
     * @param string  $cache_path
     */
    private function _build_response($items, $title, $description, $link, $logo_uri, $pub_date, $cache_path=null) {

        $data = array(
            'title'         => $title,
            'link'          => $link,
            'description'   => $description,
            'image'         => array(
                'url'   => $logo_uri,
                'title' => $title,
                'link'  => $link,
            ),
            'language'      => 'en-US',  // TODO variable
            'pubDate'       => $pub_date,
            'lastBuildDate' => $pub_date,
            'generator'     => AIR2_SYSTEM_DISP_NAME,
            'item'          => $items,
        );

        $view = $this->airoutput->render($data, 200);

        if ($cache_path) {
            // web server can be configured to check this before routing to the app
            file_put_contents($cache_path, $view);
        }

        // response
        $this->airoutput->send_headers();
        echo $view;

    }


    /**
     * RSS Feed for outcomes
     *
     * @param unknown $prj (optional)
     */
    public function outcome($prj=null) {
        if ($this->method != 'GET') {
            header('Allow: GET');
            $m = $this->method;
            show_error("Error: Unsupported request method: $m", 405);
        }
        if ($this->view != 'rss' && $this->view != 'json') {
            show_error("Only rss and json views available", 415);
        }

        // query
        $q = Doctrine_Query::create()->from('Outcome o');
        $q->andWhere('o.out_status = ?', Outcome::$STATUS_ACTIVE_WITH_FEEDS);
        $q->leftJoin('o.CreUser cu');
        $q->leftJoin('o.PrjOutcome po');
        $q->leftJoin('po.Project p');
        $q->leftJoin('o.Organization org');
        $q->leftJoin('org.DefaultProject def');

        // limit to project
        if ($prj) {
            $q2 = Doctrine_Query::create()->from('Project p');
            $q2->addWhere('(p.prj_name = ? or p.prj_uuid = ?)', array($prj, $prj));
            if ($q2->count() == 0) {
                show_error("Unknown project $prj", 404);
            }

            // add to items query
            $q->addWhere('(p.prj_name = ? or p.prj_uuid = ?)', array($prj, $prj));
        }

        // for backwards compatibility with the formbuilder pinfluence feed,
        // also support 'projects' and 'except' array keys
        if (isset($this->input_all['projects']) && strlen($this->input_all['projects'])) {
            $prjs = explode(',', $this->input_all['projects']);
            $q->andWhereIn('p.prj_name', $prjs);
        }
        if (isset($this->input_all['except']) && strlen($this->input_all['except'])) {
            $prjs = explode(',', $this->input_all['except']);
            $q->andWhereNotIn('p.prj_name', $prjs);
        }

        // limit/order and exec
        $q->orderBy('o.out_dtim desc');
        $q->limit(100);
        $rs = $q->execute();

        // assemble data
        $data = array(
            'title'         => 'PIN Outcomes',
            'link'          => air2_uri_for('rss/outcome', $this->input_all),
            'description'   => 'Stories influenced by the Public Insight Network',
            'language'      => 'en-us',
            'pubDate'       => $this->_rss_datetime(),
            'lastBuildDate' => $this->_rss_datetime(),
            'generator'     => 'AIR2',
            'item'          => array(),
        );
        foreach ($rs as $out) {
            $item = array(
                'title'       => $out->out_headline,
                'description' => $out->out_teaser,
                'link'        => $out->out_url,
                'guid'        => $out->out_uuid,
                'pubDate'     => $this->_rss_datetime($out->out_dtim),
                'author'      => $out->CreUser->user_username,
            );

            // for now, replace any newlines with <br/>
            $item['description'] = nl2br($item['description']);
            $item['description'] = str_replace(array("\n", "\r"), '', $item['description']);

            // Use Org DefaultProject prj_name as category
            // TODO: this kind of sucks
            $item['category'] = $out->Organization->DefaultProject->prj_name;

            // append item
            $data['item'][] = $item;
        }

        $this->airoutput->write($data);
    }


    /**
     * RSS Feed for PIN statistics
     */
    public function stats() {
        if ($this->method != 'GET') {
            header('Allow: GET');
            show_error("Error: Unsupported request method: {$this->method}", 405);
        }
        if ($this->view != 'rss' && $this->view != 'json') {
            show_error("Only rss and json views available", 415);
        }

        // CHECK FOR CACHE (stored as json-encoded data array)
        $data = Cache::instance()->get('stats_rss_all');
        if ($data) {
            $data = json_decode($data, true);
        }
        else {
            // count users
            $conn = AIR2_DBManager::get_connection();
            $q = "select count(*) from source where (src_status in ('A','E','T'))";
            $num_sources = $conn->fetchOne($q, array(), 0);

            // attempt to non-prospective orgs in one query... just check 4 levels down
            $nonprospect = "select org_id from organization where org_parent_id is null and org_name != 'prospect'";
            $lvl0 = "org_id in ($nonprospect)";
            $lvl1 = "org_parent_id in ($nonprospect)";
            $lvl2 = "org_parent_id in (select org_id from organization where $lvl1)";
            $lvl3 = "org_parent_id in (select org_id from organization where $lvl2)";
            $where = "$lvl0 or $lvl1 or $lvl2 or $lvl3";
            $q = "select count(*) from organization where (org_status='A' or org_status='P') and ($where)";
            $num_orgs = $conn->fetchOne($q, array(), 0);

            // assemble data
            $link = air2_uri_for('rss/stats', $this->input_all);
            $data = array(
                'title'         => 'PIN Statistics',
                'link'          => $link,
                'description'   => 'Statistics concerning the Public Insight Network',
                'language'      => 'en-us',
                'lastBuildDate' => $this->_rss_datetime(),
                'generator'     => 'AIR2',
                'item'          => array(
                    array(
                        'title'       => 'PIN Organization Count',
                        'link'        => $link,
                        'description' => $num_orgs,
                        'guid'        => 'pin_org_count',
                    ),
                    array(
                        'title'       => 'Active Sources Count',
                        'link'        => $link,
                        'description' => $num_sources,
                        'guid'        => 'active_src_count',
                    ),
                ),
            );

            // cache the data
            Cache::instance()->save(json_encode($data), 'stats_rss_all');
        }

        // output data
        $this->airoutput->write($data);
    }


    /**
     * Take in an epoch or date and/or time string, and convert it into an RSS_compatible timestamp.
     *
     * @param int|string $time If you pass in a string, it must be parse-able by strtotime().
     * @return string Returns null if $time was un-parseable or wasn't a string nor int.
     */
    private function _rss_datetime($time=null) {
        if ($time == null) {
            $time = time();
        }

        if (is_string($time)) {
            $time = strtotime($time);
        }

        if (!is_int($time)) {
            return null;
        }

        return date('D, d M Y H:i:s T', $time);
    }


} // END class Rss_Controller
