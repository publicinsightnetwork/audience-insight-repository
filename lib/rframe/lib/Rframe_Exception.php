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

require_once "Rframe.php";

/**
 * Exception specific to an error in the Rframe.
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
class Rframe_Exception extends Exception {


    /**
     * Create an exception, using a static code value found in the Rframe
     * class.
     *
     * @param int     $code
     * @param string  $message (optional)
     */
    public function __construct($code, $message=null) {
        if (!$message) {
            $message = Rframe::get_message($code);
        }
        parent::__construct($message, $code);
    }


    /**
     * True if this exception is still a success for the Rframe.
     *
     * @return boolean
     */
    public function is_success() {
        $code = $this->getCode();
        return $code >= Rframe::OKAY;
    }


}
