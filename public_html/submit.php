<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
 * submission.php receives, validates and stores PIN submissions.
 *
 */

require_once '../app/init.php';
require_once 'Encoding.php';
require_once 'UploadException.php';
require_once 'querybuilder/AIR2_PublishedQuery.php';

$valid_methods = array('POST', 'OPTIONS');
$request_method = $_SERVER['REQUEST_METHOD'];
if (!in_array($request_method, $valid_methods)) {
    header('X-PIN: invalid request: ' . $request_method, false, 405);
    header('Allow: ' . implode(' ', $valid_methods));
    exit(0);
}

if ($request_method == 'OPTIONS') {
    // cross-domain requirement for embedded queries
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type, Content-Range, Content-Disposition, Content-Description, X-Requested-With');
    exit(0);
}

// query uuid always passed via GET (in URL)
if (!isset($_GET['query'])) {
    header('X-PIN: missing query param', false, 400);
    print "Missing query uuid\n";
    exit(0);
}
$query_uuid = $_GET['query'];

/*
    PHP param parsing is awful, mostly because it requires funky var[] syntax
    on the client side to indicate multiple values per param name.
    We can parse php://input ourselves -- except when the form type
    is multipart/form-data (file uploads) which is a documented PHP limitation.
    We could:

     * require PUT method (which isn't particular RESTful, but allows reading of php://input)
     * require var[] syntax
     * rewrite in a different language

    In the end, it becomes the Least Necessary Evil Thing to require
    the var[] syntax and use the $_POST and $_FILES built-ins.

    If it were easier to deploy a Perl submit script, I would do it in a heartbeat.
*/

$post_params = array();

// ensure all values are UTF8
foreach ($_POST as $key=>$value) {

    // skip some special key names
    if (substr($key, 0, 6) == "X-PIN-") {
        continue;
    }

    if (is_array($value)) {
        $utf8ified = array();
        foreach ($value as $item) {
            $utf8ified[] = Encoding::convert_to_utf8($item);
        }
        $value = $utf8ified;
    }
    else {
        $value = Encoding::convert_to_utf8($value);
    }

    $post_params[$key] = $value;
}

// handle any files
$upload_error = false;
if ($_FILES) {

    foreach ($_FILES as $key=>$file) {

        if (isset($file['error']) && $file['error'] === UPLOAD_ERR_NO_FILE) {
            $post_params[$key] = false;
            continue; // silently skip it
        }

        //Carper::carp(var_export($file,true));
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $err = new UploadException($file['error']);
            error_log("$key: $err");
            $upload_error = $key;
            break;
        }

        $filename = $file['name'];
        $path_parts = pathinfo($filename);
        $file_ext = isset($path_parts['extension']) ? $path_parts['extension'] : "";

        $post_params[$key] = array(
            'tmp_name'  => $file['tmp_name'],
            'orig_name' => $filename,
            'file_ext'  => $file_ext,
        );

    }

}

// special mode for unit tests
if (isset($post_params['DEBUG_MODE']) && $post_params['DEBUG_MODE'] == 'params') {
    print Encoding::json_encode_utf8($post_params);
    exit(0);
}

$published_query = new AIR2_PublishedQuery($query_uuid);
$meta = array('referer' => get_referer(), 'mtime' => time(), 'query' => $query_uuid);
$submission = $published_query->validate($post_params, $meta);

// at this point we care if this is an XHR request or normal form POST,
// since we want to return HTML for the latter.
$this_is_ajax = false;
if ((isset($_SERVER['HTTP_X_REQUESTED_WITH'])
        && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest'
    )
    ||
    (isset($_POST['X-PIN-Requested-With'])
        && strtolower($_POST['X-PIN-Requested-With']) == 'xmlhttprequest'
    )
) {
    $this_is_ajax = true;
}

if ($this_is_ajax) {

    // response format via Accept request header
    // jquery form plugin needs text/html content-type
    // so wrap json in textarea in that case
    $client_accepts = $_SERVER['HTTP_ACCEPT'];
    $response_content_type = 'text/html'; // default
    if (preg_match('/application\/json/', $client_accepts)) {
        $response_content_type = 'application/json';
    }

    header("Content-Type: $response_content_type");
    header('Access-Control-Allow-Origin: *'); // cross-domain requirement for embedded queries

    if (!$submission->ok() || $upload_error) {
        $errors = $submission->get_errors();
        if ($upload_error) {
            $errors[]= array('msg' => 'Problem with file upload', 'question' => $upload_error);
        }
        header('X-PIN: validation failed', false, 400);
        $response = array('errors' => $errors, 'success' => false);

    }

    // ok. submission is valid, so write it and respond with uuid
    elseif ($submission->write_file()) {
        $response = array(
            'uuid'          => $submission->uuid,
            'permission'    => $submission->gives_permission,
            'success'       => true,
        );
        header('X-PIN: success', false, 202);

    }
    else {
        // problem writing the temp file (bad news)
        header('X-PIN: internal server error with storing submission. Try again later.', false, 500);

    }

    // send response
    if ($response_content_type == 'text/html') {
        print '<textarea>';
        print Encoding::json_encode_utf8($response);
        print '</textarea>';
    }
    elseif ($response_content_type == 'application/json') {
        $needs_jsonp = isset($_GET['callback']) ? $_GET['callback'] : false;
        if ($needs_jsonp) {
            print "${needs_jsonp}(";
        }
        print Encoding::json_encode_utf8($response);
        if ($needs_jsonp) {
            print ")";
        }
    }

}
else {
    // TODO handle HTML response

}


/**
 * Returns referer value from either X-PIN-referer POST param or HTTP header.
 *
 * @return unknown
 */
function get_referer() {
    if (isset($_POST['X-PIN-referer'])) {
        return htmlspecialchars($_POST['X-PIN-referer']);
    }
    if (isset($_SERVER['HTTP_REFERER'])) {
        return htmlspecialchars($_SERVER['HTTP_REFERER']);
    }
    return null;
}
