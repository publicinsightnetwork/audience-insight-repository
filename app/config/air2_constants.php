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


/************************
 * AIR2 Constants
 */
define('AIR2_X_TUNNELED_METHOD_NAME', 'x-tunneled-method');
define('AIR2_X_FORCE_CONTENT_NAME',   'x-force-content');
define('AIR2_AUTH_TKT_NAME',          'air2_tkt');
define('AIR2_AUTH_TKT_CONFIG_FILE',   APPPATH.'../etc/auth_tkt.conf');
define('AIR2_DTIM_FORMAT',            'Y-m-d H:i:s');
define('AIR2_DATE_FORMAT',            'Y-m-d');
define('AIR2_REL_DELIM',              ':');
define('AIR2_BIN_STATE_CK',           'air2_bin_state');
define('AIR2_AUTHZ_IS_OWNER',          1);
define('AIR2_AUTHZ_IS_PUBLIC',         2);
define('AIR2_AUTHZ_IS_ORG',            3);
define('AIR2_AUTHZ_IS_PROJECT',        4);
define('AIR2_AUTHZ_IS_SYSTEM',         5);
define('AIR2_AUTHZ_IS_MANAGER',        6);
define('AIR2_AUTHZ_IS_NEW',            7);
define('AIR2_AUTHZ_IS_DENIED',         0);
define('DBMGR_DOMAIN',                'AIR2_DOMAIN');
define('AIR2_DISCRIM_IGNORE',          1);
define('AIR2_DISCRIM_ADD',             2);
define('AIR2_DISCRIM_REPLACE',         3);


/************************
 * Profile defs
 *
 * Constant name - Profile key - Default value
 *
 * All profiles.ini keys will be the lowercased version of the constant,
 * with "AIR2_" removed.  For example: AIR2_CSV_PATH => csv_path
 */
$profile_defs = array(

    // dev or prod env (changes error handling)
    array('AIR2_ENVIRONMENT',         'dev'),
    array('AIR2_SYSTEM_DISP_NAME',    'AIR ' . AIR2_VERSION),

    // config.php will attempt to guess base_url if not given
    array('AIR2_BASE_URL',            null),
    array('AIR2_REVERSE_PROXY_BASE',  null),

    // SSO config - define trust as false to disable
    array('AIR2_PIN_SSO_TRUST',       false),
    array('AIR2_PIN_SSO_CONFIG',      '/usr/local/air2/etc/auth_tkt.conf'),
    array('AIR2_PIN_SSO_TKT',         'auth_tkt'),
    array('AIR2_PIN_SSO_URL',         'https://your.org/sso/login.cgi'),
    array('AIR2_PIN_SSO_AUTH',        'https://your.org/sso/auth.cgi'),
    array('AIR2_PIN_SSO_LOGOUT',      'https://your.org/sso/logout.cgi');

    // we all need perl
    array('AIR2_PERL_PATH',           '/usr/bin/perl'),

    // forms
    array('AIR2_UPLOAD_SERVER_URL',   'http://your.org/uploads/'),
    array('AIR2_PREVIEW_SERVER_URL',  'http://your.org/thumbs/'),
    array('AIR2_FORM_URL',            'http://your.org/form/'),
    array('AIR2_UPLOAD_BASE_DIR',     '/usr/local/air2/uploads'),

    // file storage - default to assets within codebase
    array('AIR2_CSV_PATH',            AIR2_CODEROOT . '/assets/csv'),
    array('AIR2_QUERY_DOCROOT',       AIR2_CODEROOT . '/assets/query'),
    array('AIR2_QUERY_INCOMING_ROOT', AIR2_CODEROOT . '/assets/incoming'),
    array('AIR2_IMG_ROOT',            AIR2_CODEROOT . '/assets/img'),
    array('AIR2_EMAIL_EXPORT_PATH',   AIR2_CODEROOT . '/assets/email_exports'),
    array('AIR2_CACHE_ROOT',          AIR2_CODEROOT . '/assets/cache'),
    array('AIR2_RSS_CACHE_ROOT',      AIR2_CODEROOT . '/assets/rss_cache'),
    array('AIR2_JS_CACHE_ROOT',       AIR2_CODEROOT . '/assets/js_cache'),
    array('AIR2_QB_TEMPLATES_FILE',   AIR2_CODEROOT . '/assets/js_cache/qb_templates.json'),
    array('AIR2_CACHE_TTL',           300),

    // search settings (root only required if you're running a search server)
    array('AIR2_SEARCH_URI',          'http://localhost:5000'),
    array('AIR2_SEARCH_ROOT',         AIR2_CODEROOT . '/assets/search'),
    array('AIR2_API_KEY_EMAIL',       'you@nosuchemail.org'),
    array('AIR2_PUBLIC_API_URL',      'http://your.org/air2/api/public/search'),

    // google analytics
    array('AIR2_ANALYTICS_ACCT',      null),

    // webtrends analytics
    array('AIR2_WEBTRENDS_ACCT',      null),

    // email alerts
    array('AIR2_EMAIL_ALERTS',        null),

    // support email
    array('AIR2_SUPPORT_EMAIL',       'you@your.org'),

    // SMTP host (override for @pinsight.org testing)
    array('AIR2_SMTP_HOST',           'localhost'),

    // insight button
    array('AIR2_INSIGHT_BUTTON_URL',  'http://your.org/insightbutton'),

    // MyPIN app URL
    array('AIR2_MYPIN2_URL',          'https//your.org/source'),
);

foreach ($profile_defs as $def) {
    $name    = $def[0];
    $default = $def[1];
    $key     = strtolower(substr($name, 5));

    if (defined($name)) {
        continue;
    }
    if (isset($profiles[AIR2_PROFILE][$key])) {
        define($name, $profiles[AIR2_PROFILE][$key]);
    }
    else if ($default !== null && !defined($name)) {
        define($name, $default);
    }
}

