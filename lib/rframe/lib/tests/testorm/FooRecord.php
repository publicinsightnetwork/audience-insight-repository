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


class FooRecord {
    /* internal params */
    protected $id;
    protected $value;

    /* externel references */
    protected $bar_refs = array();
    protected $foo_refs = array();
    protected $ham_ref  = false;

    public function __construct($foo_id, $foo_value) {
        $this->id = $foo_id;
        $this->value = $foo_value;
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

    public function add_bar(BarRecord $bar) {
        $this->bar_refs[] = $bar;
    }

    public function remove_bar(BarRecord $bar) {
        foreach ($this->bar_refs as $idx => $b) {
            if ($bar->get_id() == $b->get_id()) {
                array_splice($this->bar_refs, $idx, 1);
                unset($b);
            }
        }
    }

    public function get_bars() {
        return $this->bar_refs;
    }

    public function add_foo(FooRecord $foo) {
        $this->foo_refs[] = $foo;
    }

    public function get_foos() {
        return $this->foo_refs;
    }

    public function get_ham() {
        return $this->ham_ref;
    }

    public function set_ham(HamRecord $ham) {
        $this->ham_ref = $ham;
    }

    public function remove_ham() {
        $this->ham_ref = false;
    }


}
