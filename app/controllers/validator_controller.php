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

require_once 'AIR2_Controller.php';

/**
 * Validator Controller
 *
 * Used to perform AJAX validation on a model. Example usage:
 *    POST => air2/validator/source => params('src_username' => 'blahman')
 *
 * @author rcavis
 * @package default
 */
class Validator_Controller extends AIR2_Controller {
    /* validation static table method */
    public static $VALIDATE_METHOD_NAME = 'remote_validate';

    /* Map url-string to model name */
    protected $can_validate = array(
        'source'        => 'Source',
        'srcemail'      => 'SrcEmail',
        'project'       => 'Project',
        'organization'  => 'Organization',
        'user'          => 'User',
        'useremail'     => 'UserEmailAddress',
        'bin'           => 'Bin',
        'savedsearch'   => 'SavedSearch',
        'translation'   => 'TranslationMap',
        'outcome'       => 'Outcome',
    );

    /* enforce uniques outside of the models */
    protected $enforce_uniques = array(
        'bin_name',
        'org_display_name',
        'uem_address',
        'out_url',
    );

    /* include the unique conflict in the response */
    protected $return_conflicting = array(
        'uem_address' => 'User',
        'sem_email'   => 'Source',
        'out_url'     => true,
    );


    /**
     * HTTP entry point to validate a record. The model name string must be
     * described in $can_validate, or a 404 will be returned.  POST data will
     * indicate what to run validation on.
     *
     * @param string  $model_name
     */
    public function validate_record($model_name) {
        if ($this->method != 'POST' && $this->method != 'GET') {
            show_error("Invalid method", 405);
        }

        $model_name = strtolower($model_name);
        if (!isset($this->can_validate[$model_name])) {
            show_404();
        }

        // get the table object
        $tbl = Doctrine::getTable($this->can_validate[$model_name]);

        // run validation
        $errs = $this->do_validate($tbl, $this->input_all);

        // response
        $data = array(
            'success' => true,
            'message' => '',
        );
        if (count($errs)) {
            $data['success'] = false;
            $data['message'] = count($errs)." validation errors: ";
            $data['message'].= implode('; ', array_values($errs));
            $data['errors'] = $errs;
            $data['conflict'] = array();

            // lookup any existing stuff that caused unique conflicts
            foreach ($errs as $fld => $err) {
                if ($err == 'unique' && isset($this->return_conflicting[$fld])) {
                    $relname = $this->return_conflicting[$fld];
                    $with = $tbl->findOneBy($fld, $this->input_all[$fld]);
                    if ($with) {
                        $with = ($relname === true) ? $with->toArray() : $with[$relname]->toArray();
                        air2_clean_radix($with);
                        $data['conflict'][$fld] = $with;
                    }
                }
            }
        }
        $this->response($data);
    }


    /**
     * Helper function to run doctrine level validation on data.  Returns an
     * array('colname' => 'error message').  Only 1 validation error message
     * will be returned per column.
     *
     * @param Doctrine_Table $table
     * @param array   $data
     * @return array
     */
    protected function do_validate($table, $data) {
        $errs = array();
        if ($data) {
            // check for static "remote_validate" function on table
            $cls = $table->getClassnameToReturn();
            if (method_exists($cls, self::$VALIDATE_METHOD_NAME)) {
                $myerrs = call_user_func(array($cls, self::$VALIDATE_METHOD_NAME), $data);
                if (count($myerrs)) {
                    return $myerrs; // return early
                }
            }

            // normal doctrine validation
            foreach ($data as $column => $value) {
                if (!$table->hasColumn($column)) {
                    $errs[$column] = 'Unknown column';
                }
                else {
                    $col_err = false;
                    $stack = $table->validateField($column, $value);

                    // get the first problem (if any)
                    if (isset($stack[$column]) && count($stack[$column])) {
                        $col_err = $stack[$column][0];
                    }
                    $stack->clear();

                    // check extra unique columns, which aren't unique in the
                    // models, but should be validated as such
                    if (!$col_err && in_array($column, $this->enforce_uniques)) {
                        $found = $table->findOneBy($column, $value);
                        if ($found) $col_err = 'unique';
                    }

                    // set error for this column
                    if ($col_err) $errs[$column] = $col_err;
                }
            }
        }
        return $errs;
    }


}
