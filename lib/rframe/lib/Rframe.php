<?php
/*******************************************************************************
 *
 *  Copyright (c) 2011, Ryan Cavis
 *  All rights reserved.
 *
 *  This file is part of the rframe project <http://code.google.com/p/rframe/>
 *
 *  Rframe is free software: redistribution and use with or without
 *  modification are permitted under the terms of the New/Modified
 *  (3-clause) BSD License.
 *
 *  Rframe is provided as-is, without ANY express or implied warranties.
 *  Implied warranties of merchantability or fitness are disclaimed.  See
 *  the New BSD License for details.  A copy should have been provided with
 *  rframe, and is also at <http://www.opensource.org/licenses/BSD-3-Clause/>
 *
 ******************************************************************************/

require_once dirname(__FILE__).'/Rframe_Resource.php';
require_once dirname(__FILE__).'/Rframe_StaticResource.php';
require_once dirname(__FILE__).'/Rframe_Exception.php';
require_once dirname(__FILE__).'/Rframe_Parser.php';

/**
 * Base class of a Restful API, representing a hierarchical organization of
 * ORM models.
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
class Rframe {

    // return codes
    const BAD_PATH       = 1;
    const BAD_IDENT      = 2;
    const BAD_AUTHZ      = 3;
    const BAD_DATA       = 4;
    const BAD_METHOD     = 5;
    const BAD_PATHMETHOD = 6;
    const ONE_EXISTS     = 7;
    const ONE_DNE        = 8;
    const UNKNOWN_ERROR  = 10;
    const OKAY           = 20;
    const BGND_CREATE    = 21;

    // default messaging for codes
    protected static $DEFAULT_MESSAGES = array(
        self::BAD_PATH       => 'Invalid resource path',
        self::BAD_IDENT      => 'Invalid resource identifier',
        self::BAD_AUTHZ      => 'Insufficient authz for request',
        self::BAD_DATA       => 'Invalid request data',
        self::BAD_METHOD     => 'Invalid method',
        self::BAD_PATHMETHOD => 'Invalid path for method',
        self::UNKNOWN_ERROR  => 'Unknown error',
        self::OKAY           => 'Okay',
    );

    // path/route parser for this instance
    public static $PARSER_CLS = 'Rframe_Parser';
    protected $parser;


    /**
     * Constructor.  The namespace represents the first part of the classname
     * for all parts of the api.  (NAMESPACE_RscName).
     *
     * To pass custom parameters to each resource created within the API,
     * use key-value pairs within $init.
     *     example: $init = array('user'=>$usr_obj)
     *
     * @param string  $api_path
     * @param string  $api_namespace
     * @param array   $init (optional)
     */
    public function __construct($api_path, $api_namespace, $init=array()) {
        $cls = self::$PARSER_CLS;
        $this->parser = new $cls($api_path, $api_namespace, $init);
    }


    /**
     * Get the default message for a return code.
     *
     * @param int     $code
     * @return string $msg
     */
    public static function get_message($code) {
        if (isset(self::$DEFAULT_MESSAGES[$code])) {
            return self::$DEFAULT_MESSAGES[$code];
        }
        return 'Unknown';
    }


    /**
     * Get a full description of the loaded API
     *
     * @param boolean $as_tree (optional)
     * @return array $all_descs
     */
    public function describe($as_tree=false) {
        return $this->parser->describe_all($as_tree);
    }


    /**
     * Public function to fetch a resource.  Optional arguments passed include:
     *   with => include certain related resources in the returned data
     *
     * @param string  $path
     * @param array   $args
     * @return array $response
     */
    public function fetch($path, $args=array()) {
        $rsc = $this->parser->resource($path);
        $found = $rsc;
        if (!$found) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
        }

        $uuid = $this->parser->uuid($path);
        return $rsc->fetch($uuid, $args);
    }


    /**
     * Public function to query a resource
     *
     * @param string  $path
     * @param array   $args (optional)
     * @return array $response
     */
    public function query($path, $args=array()) {
        $rsc = $this->parser->resource($path);
        $found = $rsc;
        if (!$found) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
        }

        $uuid = $this->parser->uuid($path);
        if ($found && $uuid) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATHMETHOD;
            $rsc->message = "Invalid path for query: '$path'";
        }
        return $rsc->query($args);
    }


    /**
     * Public function to create a resource
     *
     * @param string  $path
     * @param array   $data
     * @return array $response
     */
    public function create($path, $data) {
        $rsc = $this->parser->resource($path);
        $found = $rsc;
        if (!$found) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
        }

        $uuid = $this->parser->uuid($path);
        if ($found && $uuid) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATHMETHOD;
            $rsc->message = "Invalid path for create: '$path'";
        }

        // make sure resource DNE, for one-to-one's
        if ($found && $rsc->get_rel_type(get_class($rsc)) == Rframe_Resource::ONE_TO_ONE) {
            $rsp = $rsc->fetch(null);
            if ($rsp['code'] == Rframe::OKAY) {
                $rsc = new Rframe_StaticResource($this->parser);
                $rsc->code = Rframe::ONE_EXISTS;
                $rsc->message = "Unable to create: resource already exists!";
            }
        }
        return $rsc->create($data);
    }


    /**
     * Public function to update a resource
     *
     * @param string  $path
     * @param array   $data
     * @return array $response
     */
    public function update($path, $data) {
        $rsc = $this->parser->resource($path);
        $found = $rsc;
        if (!$found) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
        }

        $uuid = $this->parser->uuid($path);
        return $rsc->update($uuid, $data);
    }


    /**
     * Public function to delete a resource
     *
     * @param string  $path
     * @return array $response
     */
    public function delete($path) {
        $rsc = $this->parser->resource($path);
        $found = $rsc;
        if (!$found) {
            $rsc = new Rframe_StaticResource($this->parser);
            $rsc->code = Rframe::BAD_PATH;
            $rsc->message = "Invalid path: '$path'";
        }

        $uuid = $this->parser->uuid($path);
        return $rsc->delete($uuid);
    }


}
