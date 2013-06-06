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

/**
 * Sentiment analyzer. Feed it sentences, and it will make an educated guess whether the statement
 * is positive (e.g. "This is great!") or negative (e.g. "This is awful!").
 *
 * As of 2012-01-08, the algorithm is a naive Bayes classifier, and the seed data are movies reviews
 * combined with statements made on Twitter.
 *
 * @package default
 * @author sgilbertson
 **/
class Sentiment {
    /**
     * Denotes positive seed data.
     *
     * @var string
     **/
    public static $POSITIVE = 'pos';

    /**
     * Denotes negative seed data.
     *
     * @var string
     **/
    public static $NEGATIVE = 'neg';

    /**
     * Shared instance of Sentiment (Singleton pattern).
     *
     * @var Sentiment
     **/
    private static $_instance = null;

    /**
     * Index of positive and negative seed data.
     *
     * @var array
     **/
    private $_index = array();

    /**
     * Total number of lines (documents) in seed files.
     *
     * @var int
     **/
    private $_doc_count = 0;

    /**
     * Number of lines (documents) in each classification, from seed files.
     *
     * @var int
     **/
    private $_classification_doc_counts = 0;

    /**
     * Total number of tokens in seed data.
     *
     * @var int
     **/
    private $_token_count = 0;

    /**
     * Number of tokens in each classification, from seed files.
     *
     * @var array
     **/
    private $_classification_tok_counts = null;

    /**
     * Get the shared instance of Sentiment
     *
     * @return Sentiment
     **/
    public static function instance() {
        // Initialize shared instance.
        if (!Sentiment::$_instance) {
            Sentiment::$_instance = new Sentiment();
        }

        return Sentiment::$_instance;
    }

    /**
     * Private constructor, since this class follows the Singleton pattern.
     *
     * @return void
     **/
    private function __construct() {
        // Initialize count of seed data tokens falling in each classification.
        $this->_classification_tok_counts = array(
            Sentiment::$POSITIVE => 0,
            Sentiment::$NEGATIVE => 0,
        );

        // Initialize count of seed data lines falling in each classification.
        $this->_classification_doc_counts = array(
            Sentiment::$POSITIVE => 0,
            Sentiment::$NEGATIVE => 0,
        );

        // Seed the classifier with positive and negative statements.
        $this->_add_to_index(APPPATH . '../etc/sentiment/positive-seed.txt', Sentiment::$POSITIVE);
        $this->_add_to_index(APPPATH . '../etc/sentiment/negative-seed.txt', Sentiment::$NEGATIVE);
    }

    /**
     * Add seed data to the index.
     *
     * @param string $pathname          Seed data file pathname.
     * @param string $classification    One of Sentiment::$POSITIVE, Sentiment::$NEGATIVE.
     * @return void
     **/
    private function _add_to_index($pathname, $classification) {
        $file = fopen($pathname, 'r');

        while ($line = fgets($file)) {
            $tokens = $this->_tokenize($line);

            foreach($tokens as $token) {
                if(!isset($this->_index[$token][$classification])) {
                    $this->_index[$token][$classification] = 0;
                }

                $this->_index[$token][$classification]++;
                $this->_classification_tok_counts[$classification]++;
                $this->_token_count++;
            }

            $this->_doc_count++;
            $this->_classification_doc_counts[$classification]++;
        }

        fclose($file);
    }

    /**
     * Tokenize a statement for use by this class.
     *
     * @param $statement
     * @return array
     **/
    private function _tokenize($statement) {
        $statement = strtolower($statement);

        $matches = array();
        preg_match_all('/\w+/', $statement, $matches);

        return $matches[0];
    }

    /**
     * Classify a string as positive or negative (and to what degree), based on seed data.
     * String is broken up into sentences to provide more nuanced scoring.
     *
     * @param string $document
     * @return string
     **/
    public function classify($document) {
        $prior = array(
            Sentiment::$POSITIVE => $this->_classification_doc_counts[Sentiment::$POSITIVE] / $this->_doc_count,
            Sentiment::$NEGATIVE => $this->_classification_doc_counts[Sentiment::$NEGATIVE] / $this->_doc_count,
        );

        // How far the sentence weighs against 'positive' and 'negative' classifications.
        $scores = array(
            Sentiment::$POSITIVE => 1,
            Sentiment::$NEGATIVE => 1,
        );
        $tokens = $this->_tokenize($document);


        foreach (array(Sentiment::$POSITIVE, Sentiment::$NEGATIVE) as $class) {
            foreach($tokens as $token) {
                $count = isset($this->_index[$token][$class]) ?
                    $this->_index[$token][$class] : 0;

                $scores[$class] *= ($count + 1) /
                    ($this->_classification_tok_counts[$class] + $this->_token_count);
            }

            $scores[$class] = $prior[$class] * $scores[$class];
        }


        $results = new stdClass();
        $results->positive = $scores[Sentiment::$POSITIVE];
        $results->negative = $scores[Sentiment::$NEGATIVE];

        arsort($scores);
        return key($scores);
    }
} // END class Sentiment
