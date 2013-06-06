<?php

/**
 * UserVisit
 *
 * Log visits to various resources by Users.
 *
 * @package default
 **/
class UserVisit extends AIR2_Record {
    /**
     * Maps model names to UserVisit::$TYPE... codes.
     *
     * @var array
     **/
    public static $VISITABLE = array(
        'Source'            => 'S',
        'SrcResponseSet'    => 'R',
    );

    /**
     * Create a UserVisit record linking a user to a record at a specific time.
     *
     * @param array $config Keys: record (@see AIR2_Record), user (@see User), ip (string|int).
     * @return void
     * @author sgilbertson
     **/
    public static function create_visit($config) {
        $record = null;
        $user = null;
        $ip = null;
        extract($config);
        
        // Make sure all required data is available.
        if (!$record || !$user || !$ip) {
            throw new Exception ('Invalid or missing record, user, or ip.');
        }
        
        // Determine if this record type is 'visitable.'
        $code = null;
        $model_class = get_class($record);
        if (in_array($model_class, array_keys(UserVisit::$VISITABLE))) {
            $code = UserVisit::$VISITABLE[$model_class];
        }
        
        // Not a visitable record type? Throw an exception.
        if (!$code) {
            throw new Exception("Record type '$model_class' not visitable.");
        }
        
        // We only support single-keyed records.
        $pkey = $record->identifier();
        if (count($pkey) > 1) {
            throw new Exception("Can't visit records with multi-column primary keys.");
        }
        $pkey = array_values($pkey);
        $pkey = $pkey[0];
        
        $visit = new UserVisit();
        
        // Allow int and string IPs.
        if (is_string($ip)) {
            $ip = ip2long($ip);
        }
        
        // If invalid IP address, throw an exception.
        if (!$ip) {
            throw new Exception('Invalid IP address.');
        }
        
        /**
         * Populate new UserVisit record.
         */
        $visit->uv_ip = $ip;
        $visit->uv_xid = $pkey;
        $visit->uv_user_id = $user->user_id;
        
        // Type of record, as we determined above.
        $visit->uv_ref_type = $code;
        
        $visit->save();
    }

    /**
     * Find UserVisit records.
     *
     * @param array $config Keys: type (@see UserVisits::$VISITABLE); xid (integer).
     * @return Doctrine_Collection
     * @author sgilbertson
     **/
    public static function find($config) {
        $type = null;
        $xid = null;
        extract($config);
        
        // Require record type and xid.
        if (!$type || !$xid) {
            throw new Exception('Invalid or missing record type or xid.');
        }
        
        $q = Doctrine_Query::create()->from('UserVisit uv');
        $q->addWhere('uv.uv_ref_type = ?', $type);
        $q->addWhere('uv.uv_xid = ?', $xid);
        $recs = $q->execute();
        
        return $recs;
    }

    /**
     * Define table columns. Doctrine method.
     *
     * @return void
     **/
    public function setTableDefinition() {
        $this->setTableName('user_visit');

        $this->hasColumn(
            'uv_id',
            'integer',
            4,
            array(
                'primary' => true,
                'autoincrement' => true
            )
        );
        
        $this->hasColumn(
        	'uv_user_id',
        	'integer',
        	4,
        	array('notnull' => true)
        );
        
        $this->hasColumn(
        	'uv_ref_type',
        	'string',
        	1,
        	array('notnull' => true)
        );
        
        $this->hasColumn(
			'uv_xid',
			'integer',
			4,
			array('notnull' => true)
        );
        
        $this->hasColumn(
        	'uv_ip',
        	'integer',
        	4,
        	array('notnull' => true)
        );
        
        $this->hasColumn(
        	'uv_cre_user',
        	'integer',
        	4,
        	array('notnull' => true)
        );
        
        $this->hasColumn(
        	'uv_cre_dtim',
        	'timestamp',
        	null,
        	array('notnull' => true)
        );

        parent::setTableDefinition();
        
        $this->setSubclasses(
            array(
                'UserVisitSrs' => array('uv_ref_type' => UserVisit::$VISITABLE['SrcResponseSet'])
            )
        );
    }
} // END class UserVisit extends AIR2_Record
