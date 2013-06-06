#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use AIR2::DBManager;
use AIR2::Utils;
use AIR2::Config;
use File::Slurp;
use Path::Class;
use Data::Dump qw( dump );
use Pod::Usage;
use JSON;
use AIR2::CodeMaster;
use AIR2::Country;
use AIR2::Fact;
use AIR2::State;
use AIR2::SearchUtils;

sub get_header();
sub get_current_fixtures();
sub get_cm_fixtures();
sub get_facts();
sub get_preferences();
sub get_states();
sub get_countries();
sub get_states_min();
sub get_countries_min();
sub get_admin_roles();

my $js_file = AIR2::Config->get_app_root->file('public_html/js/fixtures.js');
my $js_min_file
    = AIR2::Config->get_app_root->file('public_html/js/cache/fixtures.min.js');

my $body = get_header;
$body .= get_current_fixtures;
$body .= get_cm_fixtures;
$body .= get_facts;
$body .= get_preferences;
$body .= get_states;
$body .= get_countries;
$body .= get_admin_roles;

write_file( "$js_file", "$body" );

# minified states and countries for querymaker
my $min_js = join( "\n", get_states_min(), get_countries_min() );
write_file( "$js_min_file", "$min_js" );

sub get_cm_fixtures() {
    my $dbh   = AIR2::CodeMaster->init_db->retain_dbh;
    my $codes = $dbh->prepare(
        qq/SELECT cm_field_name, cm_code, cm_disp_value
        FROM code_master ORDER BY cm_field_name asc, cm_disp_seq asc/
    );
    $codes->execute();
    my $cm_codes = $codes->fetchall_arrayref();

    #dump \$cm_codes;

    my %table;

    for my $row (@$cm_codes) {
        my $field_name    = $row->[0];
        my $cm_code       = $row->[1];
        my $cm_disp_value = $row->[2];
        push @{ $table{$field_name} }, [ $cm_code => $cm_disp_value ];
    }

    #dump \%table;
    my $json = JSON->new;
    chomp( my $cm_codes_json = $json->pretty->encode( \%table ) );
    return "\nAIR2.Fixtures.CodeMaster = " . $cm_codes_json . ";\n";
}

sub get_facts() {

    my $facts = AIR2::SearchUtils::all_facts_by_id();

    my %table;
    for my $fact_id ( sort { $a <=> $b } keys %$facts ) {
        my $fact = $facts->{$fact_id};

        # we do not care about open-ended facts
        next if !$fact->has_related('fact_values');

        #warn "fact: " . $fact->fact_identifier . "\n";
        my @values;
        for my $fact_value (
            @{ $fact->find_fact_values( sort_by => 'fv_seq ASC' ) } )
        {
            next if $fact_value->fv_status ne 'A';
            my $label = $fact_value->fv_value;
            my $pk    = $fact_value->fv_id;
            push @values, [ $pk => $label ];

            #dump( $fact_value->as_tree );

        }

        $table{ $fact->fact_identifier } = \@values;
    }

    #dump \%table;
    my $json = JSON->new;
    chomp( my $table_json = $json->pretty->encode( \%table ) );
    return "\nAIR2.Fixtures.Facts = " . $table_json . ";\n";
}

sub get_preferences() {
    my $preferences = AIR2::SearchUtils::all_preferences_by_id();

    my %table;
    for my $pt_id ( sort { $a <=> $b } keys %$preferences ) {
        my $preference = $preferences->{$pt_id};

        #dump( $preference );

        next if !$preference->has_related('preference_type_values');

        my @values;
        if ( $preference->pt_identifier eq 'preferred_language' ) {
            
            for my $preference_type_value (
                @{ $preference->find_preference_type_values( sort_by => 'ptv_seq ASC' ) } )
            {
                next if $preference_type_value->ptv_status ne 'A';
                my $label = $preference_type_value->ptv_value;
                if ($label eq 'en_US') {
                    $label = 'English';
                }
                elsif ($label eq 'es_US') {
                    $label = 'Spanish';
                }
                my $pk    = $preference_type_value->ptv_uuid;
                push @values, [ $pk => $label ];

            }
            $table{ $preference->pt_identifier } = \@values;
        }
    }

    #dump \%table;
    my $json = JSON->new;
    chomp( my $table_json = $json->pretty->encode( \%table ) );
    return "\nAIR2.Fixtures.Preferences = " . $table_json . ";\n";
}

sub get_states() {
    my $dbh   = AIR2::State->init_db->retain_dbh;
    my $codes = $dbh->prepare(qq/SELECT * FROM state ORDER BY state_name/);
    $codes->execute();
    my $states = $codes->fetchall_hashref('state_name');

    #dump \$states;
    my @table;

    for my $state_id ( sort keys %$states ) {
        my $state_code = $states->{$state_id}->{state_code};
        my $state_name = $states->{$state_id}->{state_name};
        push @table, [ $state_code => $state_name ];
    }

    my $json = JSON->new;
    chomp( my $state_codes_json = $json->pretty->encode( \@table ) );
    return "\nAIR2.Fixtures.States = " . $state_codes_json . ";\n";
}

sub get_countries() {
    my $dbh = AIR2::State->init_db->retain_dbh;
    my $codes
        = $dbh->prepare(qq/SELECT * FROM country ORDER BY cntry_disp_seq/);
    $codes->execute();
    my $countries = $codes->fetchall_hashref('cntry_disp_seq');

    #dump \$countries;
    my @table;

    for my $cntry_id ( sort { $a <=> $b } keys %$countries ) {
        my $cntry_code = $countries->{$cntry_id}->{cntry_code};
        my $cntry_name = $countries->{$cntry_id}->{cntry_name};
        push @table, [ $cntry_code => $cntry_name ];
    }

    my $json = JSON->new;
    chomp( my $cntry_codes_json = $json->pretty->encode( \@table ) );
    return "\nAIR2.Fixtures.Countries = " . $cntry_codes_json . ";\n";
}

sub get_states_min() {
    my $dbh   = AIR2::State->init_db->retain_dbh;
    my $codes = $dbh->prepare(qq/SELECT * FROM state ORDER BY state_name/);
    $codes->execute();
    my $states = $codes->fetchall_hashref('state_name');

    #dump \$states;
    my @table;

    for my $state_id ( sort keys %$states ) {
        my $state_code = $states->{$state_id}->{state_code};
        my $state_name = $states->{$state_id}->{state_name};
        push @table, [ $state_code => $state_name ];
    }

    chomp( my $state_codes_json = encode_json( \@table ) );
    return "PIN.States = " . $state_codes_json . ";\n";
}

sub get_countries_min() {
    my $dbh = AIR2::State->init_db->retain_dbh;
    my $codes
        = $dbh->prepare(qq/SELECT * FROM country ORDER BY cntry_disp_seq/);
    $codes->execute();
    my $countries = $codes->fetchall_hashref('cntry_disp_seq');

    #dump \$countries;
    my @table;

    for my $cntry_id ( sort { $a <=> $b } keys %$countries ) {
        my $cntry_code = $countries->{$cntry_id}->{cntry_code};
        my $cntry_name = $countries->{$cntry_id}->{cntry_name};
        push @table, [ $cntry_code => $cntry_name ];
    }

    chomp( my $cntry_codes_json = encode_json( \@table ) );
    return "PIN.Countries = " . $cntry_codes_json . ";\n";
}

sub get_admin_roles() {
    my $dbh  = AIR2::AdminRole->init_db->retain_dbh;
    my $stmt = $dbh->prepare(qq/SELECT * FROM admin_role ORDER BY ar_id/);
    $stmt->execute();
    my $roles = $stmt->fetchall_hashref('ar_id');

    my @table;
    for my $ar_id ( sort { $a <=> $b } keys %$roles ) {
        my $ar_code = $roles->{$ar_id}->{ar_code};
        push(
            @table,
            {   ar_id     => $ar_id,
                ar_code   => $ar_code,
                ar_name   => $roles->{$ar_id}->{ar_name},
                ar_status => $roles->{$ar_id}->{ar_status},
            }
        );
    }

    my $json = JSON->new;
    chomp( my $jsonstr = $json->pretty->encode( \@table ) );
    return "\nAIR2.Fixtures.AdminRole = $jsonstr;\n";
}

sub get_header() {
    my $header = <<'END'
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

/*************************************************************************
 *   AIR2 fixtures. Standard lookup tables, etc.
 *
 *   This file is generated by 'bin/mk_fixtures.pl.' Do not edit this file
 *   manually. Any changes will be overwritten the next time that
 *   'bin/mk_fixtures.pl' is run.
 *
 *************************************************************************/
END
}

sub get_current_fixtures() {
    my $current_fixtures = <<'END'
Ext.ns('AIR2.Fixtures');

// About the src_ vs user_ vs no-prefix fields
// user_*  == an AIR user mapped the value
// src_*   == the source mapped the value, or it is a standard AIR2 column
// no prefix == the source entered free text

AIR2.Fixtures.FieldLabels = {
    "annotation"                : "Annotation",
    "birth_year"                : "Birth year",
    "city"                      : "City",
    "country"                   : "Country",
    "county"                    : "County",
    "created_date"              : "Created",
    "modified_date"             : "Modified",
    "credential"                : "Credential",
    "dob"                       : "Birth year",
    "email"                     : "Email",
    "ethnicity"                 : "Ethnicity (untranslated)",
    "experience_what"           : "Experience (what)",
    "experience_where"          : "Experience (where)",
    "first_name"                : "First name",
    "first_responded_date"      : "First response date",
    "gender"                    : "Gender (untranslated)",
    "interest"                  : "Interest",
    "household_income"          : "Household income",
    "last_activity_date"        : "Last activity date",
    "last_contacted_date"       : "Last contacted date",
    "last_queried_date"         : "Last queried date",
    "last_name"                 : "Last name",
    "last_responded_date"       : "Last response date",
    "lifecycle"                 : "Life Cycle",
    "pin_status"                : "PIN status",
    "political_affiliation"     : "Political affiliation",
    "pref_lang"                 : "Preferred language",
    "preferred_language"        : "Preferred language",
    "primary_email"             : "Email",
    "primary_location"          : "Location",
    "ques_value"                : "Question",
    "ques_choice_value"         : "Question choice",
    "religion"                  : "Religion (untranslated)",
    "response"                  : "Response",
    "sact_actm_id"              : "Activity type",
    "sact_desc"                 : "Activity",
    "sact_notes"                : "Activity",
    "source_website"            : "Website",
    "smadd_city"                : "City",
    "smadd_state"               : "State/Province",
    "smadd_zip"                 : "Postal Code",
    "srcan_value"               : "Annotation",
    "src_education_level_id"    : "Education level",
    "src_education_level"       : "Education level",
    "src_first_name"            : "First name",
    "src_household_income_id"   : "Household income",
    "src_household_income"      : "Household income",
    //"src_interests"             : "Interests",
    "src_last_name"             : "Last name",
    "src_login_name"            : "Username",  // in AIR1 always same as primary email
    "src_political_affiliation_id" : "Political affiliation",
    "src_political_affiliation" : "Political affiliation",
    //"src_religion"              : "Religion - source mapping",
    "src_uuid"                  : "UUID",
    "state"                     : "State/Province",
    "tag"                       : "Tag",
    "user_religion"             : "Religion",
    "user_religion_id"          : "Religion",
    "user_gender"               : "Gender",
    "user_gender_id"            : "Gender",
    "user_ethnicity"            : "Ethnicity",
    "user_ethnicity_id"         : "Ethnicity",
    "valid_email"               : "Valid email address",
    "zip"                       : "Postal Code"
};
END
}
