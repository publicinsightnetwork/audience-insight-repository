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


class BarRecord {
    /* internal params */
    protected $id;
    protected $value;

    /* externel references */
    protected $foo_refs = array();

    public function __construct($bar_id, $bar_value) {
        $this->id = $bar_id;
        $this->value = $bar_value;
    }

    public function get_id() {
        return $this->id;
    }

    public function get_value() {
        return $this->value;
    }

    public function set_value($val) {
        $this->value = $val;
    }

    public function add_foo(FooRecord $foo) {
        $this->foo_refs[] = $foo;
    }

    public function get_foos() {
        return $this->foo_refs;
    }

}
