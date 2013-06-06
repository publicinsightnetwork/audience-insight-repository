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

define('RFRAME_DEFAULT_MAX_SCAN_DEPTH', 3);
define('RFRAME_DEFAULT_DELIM', '/');

/**
 * Helper class used to parse and resolve resource path strings.  There are a
 * couple useful definitions within the context of this class:
 *   PATH: string representing a complete resource, including UUID's
 *   ROUTE: a PATH without any UUID's
 *   CLASS: the classname of a resource file (looks like a ROUTE)
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
class Rframe_Parser {

    // routing settings
    public $max_scan_depth;
    public $delimiter;

    // cached routestring => classname
    public $routes = array();

    // data to pass to resource constructors
    protected $rsc_inits = array();


    /**
     * Construct a parser for a particular file path and namespace.
     *
     * @param string  $path
     * @param string  $namespace
     * @param array   $rsc_inits
     * @param string  $delim (optional)
     * @param boolean $depth (optional)
     */
    public function __construct($path, $namespace, $rsc_inits, $delim=null, $depth=null) {
        $this->delimiter = ($delim === null) ? RFRAME_DEFAULT_DELIM : $delim;
        $this->max_scan_depth = ($depth === null) ? RFRAME_DEFAULT_MAX_SCAN_DEPTH : $depth;
        $this->_require_all($path);
        $this->_cache_valid_routes($namespace);
        $this->rsc_inits = $rsc_inits;
    }


    /**
     * Find an API resource from a path.  Returns false if the path couldn't
     * be resolved to an API resource, otherwise returns a resource.
     *
     * @param string|array $path
     * @return Rframe_Resource|boolean
     */
    public function resource($path) {
        if (is_string($path)) {
            $path = $this->_path_explode($path);
        }
        $route = $this->_path_to_route($path);
        if (!$route || count($route) < 1) {
            return false;
        }

        // must not pass any UUID to resource constructor
        if ($this->uuid($path)) {
            array_pop($path);
        }

        // instantiate the resource based on route
        $route_str = implode($this->delimiter, $route);
        $cls = $this->routes[$route_str];
        $rsc = new $cls($this, $path, $this->rsc_inits);
        return $rsc;
    }


    /**
     * Find a resource uuid from a path.  Returns false if there is no uuid
     * attached to this path.
     *
     * @param string|array $path
     * @return string
     */
    public function uuid($path) {
        if (is_string($path)) {
            $path = $this->_path_explode($path);
        }
        $route = $this->_path_to_route($path);
        $path_end  = is_array($path)  && count($path)  ? array_pop($path)  : null;
        $route_end = is_array($route) && count($route) ? array_pop($route) : null;

        if ($path_end && $route_end && $path_end != $route_end) {
            return $path_end;
        }
        return false;
    }


    /**
     * Explode a path string into an array.  Returns false if the path
     * was invalid.
     *
     * @param string  $str
     * @return array|bool $parts
     */
    protected function _path_explode($str) {
        // remove leading/trailing delimiters and explode!
        $d = preg_quote($this->delimiter);
        $d = preg_replace('/\//', '\/', $d);
        $str = preg_replace("/^$d|$d$/", '', $str);
        $split = explode($this->delimiter, $str);

        // validate
        if (count($split) < 1) {
            return false;
        }
        return $split;
    }


    /**
     * Converts a path into a route.  Returns false if the route is invalid.
     *
     * @param  array $path
     * @return array $route
     */
    protected function _path_to_route($path) {
        if (!is_array($path) || count($path) < 1) {
            return false;
        }

        $route = array();
        while (count($path)) {
            $route[] = array_shift($path);
            $so_far = implode($this->delimiter, $route);
            if (!isset($this->routes[$so_far])) {
                return false; //bad route
            }

            $cls = $this->routes[$so_far];
            $type = Rframe_Resource::get_rel_type($cls);
            if (count($path) && $type == Rframe_Resource::ONE_TO_MANY) {
                array_shift($path); //remove a UUID
            }
        }
        return $route;
    }


    /**
     * Convert a string classname into a route string.  Throws an exception
     * if the route is unknown.
     *
     * @param string  $clsname
     * @return string $route
     */
    public function class_to_route($clsname) {
        foreach ($this->routes as $route => $cls) {
            if ($cls == $clsname) {
                return $route;
            }
        }
        throw new Exception("Unrouted classname '$clsname'");
    }


    /**
     * Get children of the given route.
     *
     * @param string $route
     * @return array $child_routes
     */
    public function get_children($route) {
        if ($route != '' && !isset($this->routes[$route])) {
            throw new Exception("Invalid route '$route'");
        }
        $children = array();
        $startswith = '';
        if ($route != '') {
            $startswith = preg_quote($route)."/";
            $startswith = preg_replace('/\//', '\/', $startswith);
        }

        foreach ($this->routes as $rt => $cls) {
            if (preg_match("/^$startswith\w+$/", $rt)) {
                $children[] = preg_replace("/^$startswith/", '', $rt);
            }
        }
        return $children;
    }


    /**
     * Get a description of a specific loaded route.
     *
     * @param string  $route
     * @return array $desc
     */
    public function describe($route) {
        if (!isset($this->routes[$route])) {
            throw new Exception("Invalid describe route '$route'");
        }

        // instantiate class with no parents loaded
        $cls = $this->routes[$route];
        $rsc = new $cls($this, array(), $this->rsc_inits);
        return $rsc->describe();
    }


    /**
     * Get a description of all loaded routes, either as a flat list or as a
     * tree.
     *
     * @param boolean $as_tree (optional)
     * @return array $all_descs
     */
    public function describe_all($as_tree=false) {
        $all = array();
        if ($as_tree) {
            $top_rts = $this->get_children('');
            foreach ($top_rts as $rt) {
                $desc = $this->describe($rt);
                $all[] = $this->_describe_tree($desc);
            }
        }
        else {
            foreach ($this->routes as $rt => $cls) {
                $all[] = $this->describe($rt);
            }
        }
        return $all;
    }


    /**
     * Helper function to recursively organize descriptions into a tree.
     *
     * @param array   $desc
     * @return array $desc
     */
    protected function _describe_tree($desc) {
        foreach ($desc['children'] as $idx => $child) {
            $child_rt = $desc['route'].$this->delimiter.$child;
            $child_desc = $this->describe($child_rt);
            $desc['children'][$child] = $this->_describe_tree($child_desc);
            unset($desc['children'][$idx]);
        }
        return $desc;
    }


    /**
     * Scan the api path, recursively including all PHP files
     *
     * @param string  $dir
     * @param int     $depth (optional)
     */
    protected function _require_all($dir, $depth=0) {
        if ($depth > $this->max_scan_depth) {
            return;
        }

        // require all php files
        $scan = glob("$dir/*");
        foreach ($scan as $path) {
            if (preg_match('/\.php$/', $path)) {
                require_once $path;
            }
            elseif (is_dir($path)) {
                $this->_require_all($path, $depth+1);
            }
        }
    }


    /**
     * Cache an array of routes -> resource classnames
     *
     * @param string  $namespace
     */
    protected function _cache_valid_routes($namespace) {
        $startswith = "/^{$namespace}_/";

        foreach (get_declared_classes() as $name) {
            if (preg_match($startswith, $name)) {
                $short = strtolower(preg_replace($startswith, '', $name));

                //underscores to slashes
                $short = preg_replace("/_/", $this->delimiter, $short);
                $this->routes[$short] = $name;
            }
        }
    }


}
