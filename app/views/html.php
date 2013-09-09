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

/*
|--------------------------------------------------------------------------
| HTML Output
|--------------------------------------------------------------------------
| Prints data as html
*/

// set search vars
$query = '';
if ($c->input->get_post('q') !== FALSE) {
    $query = $c->input->get_post('q');
}
if (is_a($c, 'Reader_Controller')) {
    $search_idx = 'responses';
}
if (!isset($search_idx)) {
    $search_idx = 'active-sources';
}
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
 <head>
  <title><?php echo $html['head']['title'] ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=EmulateIE8" />
  <link href="<?php echo $c->uri_for('favicon.ico'); ?>" rel="shortcut icon" type="image/ico" />

  <!-- ExtJS and shared stylesheets -->
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/extjs/resources/css/ext-all.css') ?>"/>
  <link rel="stylesheet" href="<?php echo $c->uri_for('css/ext-theme-air2.css') ?>"/>
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/extjs/examples/ux/css/RowEditor.css') ?>"/>
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/extjs/examples/ux/css/Spinner.css') ?>"/>
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/extjs/examples/ux/css/FileUploadField.css') ?>"/>
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/shared/livedataview.css') ?>"/>

  <!-- ExtJS and shared javascript libraries -->
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/adapter/ext/ext-base.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/ext-all.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/examples/ux/datetime.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/examples/ux/RowEditor.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/examples/ux/Spinner.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/examples/ux/SpinnerField.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/examples/ux/FileUploadField.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/groupcombo.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/groupdataview.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/livedataview.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/search-query.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/hyphenator.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/long.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/ckeditor/ckeditor.js') ?>"></script>

  <?php if ($c && is_a($c, 'Search_Controller')) { ?>
  <!-- Mapping libs for search resources -->
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/leaflet/dist/leaflet.css') ?>"/>
  <!--<link rel="stylesheet" href="<?php echo $c->uri_for('lib/leaflet/dist/leaflet.ie.css') ?>"/>-->
  <link rel="stylesheet" href="<?php echo $c->uri_for('lib/shared/slidemapper.min.css') ?>"/>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/leaflet/dist/leaflet.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/leafpile.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/jquery-1.7.2.min.js') ?>"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/shared/slidemapper.min.js') ?>"></script>
  <?php } ?>

  <?php if ($c && is_a($c, 'Query_Controller')) { ?>
  <script type="text/javascript" src="<?php echo $c->uri_for('lib/extjs/plugins/date-time-ux.js') ?>"></script>
  <!-- Form Rendering JS -->
  <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
  <script type="text/javascript" src="<?php echo $c->uri_for('js/pinform.js') ?>"></script>
  <link rel="stylesheet" href="<?php echo $c->uri_for('css/pinform.css') ?>"/>
  <script type="text/javascript">
    PIN_QUERY = {
      uuid:       '<?php echo $data["UUID"]; ?>',
      baseUrl:    '<?php echo $c->uri_for('') ?>/',
      divId:      'pin-query-preview',
      previewMode: true,
      opts: {}
    };
    // load fixtures from AIR, for states, countries, etc.
    if (!PIN.States) {
      jQuery.getScript("<?php echo $c->uri_for('js/cache/fixtures.min.js') ?>", function() {
        //console.log('fixtures.min.js loaded');
        PIN.Form.LOADED['fixtures'] = true;
      });
    }
    else {
      PIN.Form.LOADED['fixtures'] = true;
    }
  </script>
  <?php } ?>

  <!-- AIR2 global variables -->
  <script type="text/javascript">
    Ext.ns('AIR2');
    Ext.ns('AIR2.CACHE');
    <?php if ($c && is_a($c, 'AIR2_Controller')) { ?>
    AIR2.DEBUG = <?php echo ($c->is_production) ? 'false' : 'true';?>;
    AIR2.HOMEURL = '<?php echo $c->uri_for('');?>';
    AIR2.FORMURL = '<?php echo AIR2_FORM_URL; ?>';
    AIR2.INSIGHTBUTTON_URL = '<?php echo AIR2_INSIGHT_BUTTON_URL; ?>';
    AIR2.MYPIN2_URL = '<?php echo AIR2_MYPIN2_URL; ?>';
    AIR2.LOGOUTURL = '<?php echo $c->uri_for('logout');?>';
    <?php if ($c->airuser->get_user()) { ?>
    AIR2.USERNAME = '<?php echo $c->airuser->get_username();?>';
    AIR2.USERINFO = <?php echo json_encode($c->airuser->get_user_info());?>;
    AIR2.USERAUTHZ = <?php echo json_encode($c->airuser->get_user()->get_authz_uuids());?>;
    AIR2.USERAUTHZ_IDS = <?php echo json_encode($c->airuser->get_user()->get_authz());?>;
    AIR2.RECENT = <?php echo $c->airuser->get_recent_views();?>;
    AIR2.AUTHZ = <?php echo json_encode($c->get_authz_action_constants());?>;
     <?php if ($c->airuser->get_user()->get_home_org()) { ?>
    AIR2.HOME_ORG = <?php echo $c->airuser->get_user()->get_home_org()->asJSON();?>;
    AIR2.DEFAULT_PROJECT = <?php echo $c->airuser->get_user()->get_home_org()->DefaultProject->asJSON();?>;
     <?php } ?>
    <?php } ?>
    AIR2.AUTHZCOOKIE = '<?php echo AIR2_AUTH_TKT_NAME; ?>';
    AIR2.BINCOOKIE = '<?php echo AIR2_BIN_STATE_CK; ?>';
    AIR2.BINDATA = <?php echo $c->get_bin_data(); ?>;
    AIR2.BINBASE = <?php echo $c->get_bin_base(); ?>;
    AIR2.SEARCHIDX = '<?php echo $search_idx; ?>';
    AIR2.UPLOADSERVER = '<?php echo AIR2_UPLOAD_SERVER_URL; ?>';
    AIR2.PREVIEWSERVER = '<?php echo AIR2_PREVIEW_SERVER_URL; ?>';
    AIR2.MAX_EMAIL_EXPORT = <?php echo AIR2_MAX_EMAIL_EXPORT ?>;
    <?php } ?>
  </script>

  <!-- AIR2 stylesheets -->
<?php foreach ($html['head']['css'] as $css) { ?>
  <link rel="stylesheet" href="<?php echo $css; ?>" />
<?php } ?>

  <!-- AIR2 scripts -->
<?php foreach ($html['head']['js'] as $js) { ?>
  <script type="text/javascript" src="<?php echo $js; ?>"></script>
<?php } ?>

<?php
// anything else
echo $html['head']['misc'];
?>

<!-- Google Analytics. -->
<? if (defined('AIR2_ANALYTICS_ACCT')): ?>
  <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '<?= AIR2_ANALYTICS_ACCT ?>']);
    _gaq.push(['_trackPageview']);

    <?
    // The following code is only required if you're behind a firewall.
    if (!$c->is_production):
    ?>
      _gaq.push(['_setDomainName', 'none']);
    <? endif; ?>

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();

  </script>
<? endif; ?>

<!-- WebTrends -->
<? if (defined('AIR2_WEBTRENDS_ACCT')): ?>
<!-- Copyright (c) 2012 Webtrends Inc.  All rights reserved. -->
<script type="text/javascript" src="/wp-content/themes/pin/library/js/webtrends.load.js"></script>
<? endif; ?>

 </head>
 <body>
  <!-- header area -->
  <div id="air2-headerwrap">
   <div class="background">
    <div class="wrap" id="air2-header">
     <div class="tools">
      <div class="search">
       <form autocomplete="off" id="air2-search-form" method="get" action="<?php echo $c->uri_for('search/'.$search_idx) ?>">
        <input type="text" class="text-input" name="q" size="50" value="<?php echo htmlspecialchars($query) ?>" />
        <div class="air2-btn air2-btn-blue air2-btn-small x-btn-icon search-type">
         <button class="x-btn-text air2-icon-<?php echo $search_idx; ?>">&nbsp;</button>
        </div>
        <div class="air2-btn air2-btn-blue air2-btn-small x-btn-noicon search-norm">
         <button class="x-btn-text">Search</button>
        </div>
        <div class="air2-btn air2-btn-plain air2-btn-small x-btn-noicon search-adv">
         <button class="x-btn-text">Advanced</button>
        </div>
       </form>
      </div>
      <div class="recent-stuff">
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-project">&nbsp;</button>
       </div>
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-source">&nbsp;</button>
       </div>
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-inquiry">&nbsp;</button>
       </div>
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-responses">&nbsp;</button>
       </div>
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-add">&nbsp;</button>
       </div>
      </div>
      <div class="account">
       <div class="name"><a href="<?php echo $c->uri_for('user/'.$c->airuser->get_user()->user_uuid); ?>">
        <?php echo $c->airuser->get_username() ?></a></div>
       <div class="air2-btn air2-btn-darker air2-btn-small x-btn-icon">
        <button class="x-btn-text air2-icon-chevron">&nbsp;</button>
       </div>
      </div>
     </div>
     <div class="logo">
      <a href="<?php echo $c->uri_for('')?>">
       <img src="<?php echo $c->uri_for('css/img/air-logo.png') ?>" alt="Audience Insight Repository" />
      </a>
     </div>
    </div>
   </div>
   <div class="bevel"></div>
  </div>
  <!-- end Header -->

  <!-- Content area -->
  <div id="air2-contentwrap" class="wrap">
   <div id="air2-location-wrap" class="clearfix">
    <table class="air2-location">
     <tr>
      <td class="loc-type"></td>
      <td class="loc-title"></td>
     </tr>
    </table>
   </div>
   <div id="air2-body">
<?php
echo $html['body']; // this should be JS to render into "air2-body"
?>
   </div>

   <!-- Drawer elements -->
   <div id="air2-drawer-wrap" class="wrap">
    <div id="air2-drawer" class="collapsed">
     <div class="trigger">
      <div class="tab air2-corners-top">
       <div class="controls"></div>
       <div class="title">Bins</div>
      </div>
     </div>
     <div class="body air2-corners-top">
      <div class="info"></div>
      <div class="tbar"></div>
      <div class="view"></div>
      <div class="fbar"></div>
     </div>
    </div>
   </div>
   <!-- end Drawer -->

  </div>
  <!-- end Content -->

  <!-- Footer -->
  <div id="air2-footer" class="wrap">
    <span>AIR - Audience Insight Repository</span>
    <span>| &copy; 2013 American Public Media Group</span>
    <span>|
      <a class="external" href="http://support.publicinsightnetwork.org" target="_blank">Contact Help</a>
    </span>
  </div>

  <!-- Fields required for history management -->
  <form id="history-form" class="x-hidden">
    <input type="hidden" id="x-history-field" />
    <iframe id="x-history-frame"></iframe>
  </form>

 </body>
</html>
