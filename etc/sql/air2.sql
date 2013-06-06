-- ------------------------------------------------------------------------
--
--   Copyright 2010 American Public Media Group
--
--   This file is part of AIR2.
--
--   AIR2 is free software: you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation, either version 3 of the License, or
--   (at your option) any later version.
--
--   AIR2 is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
--
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- DDL forward engineered from MySQL Workbench file air2_from_doctrine_1.20.mwb.
-- $Id: air2.sql 17611 2011-09-28 19:31:11Z rcavis $
-- ------------------------------------------------------------------------
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `air2` DEFAULT CHARACTER SET latin1 ;
USE `air2` ;

-- -----------------------------------------------------
-- Table `air2`.`activity_master`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`activity_master` (
  `actm_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `actm_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `actm_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `actm_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `actm_table_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `actm_contact_rule_flag` TINYINT(1) NOT NULL ,
  `actm_disp_seq` SMALLINT(6) NOT NULL ,
  `actm_cre_user` INT(11) NOT NULL ,
  `actm_upd_user` INT(11) NULL DEFAULT NULL ,
  `actm_cre_dtim` DATETIME NOT NULL ,
  `actm_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`actm_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`admin_role`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`admin_role` (
  `ar_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `ar_code` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `ar_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `ar_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `ar_cre_user` INT(11) NOT NULL ,
  `ar_upd_user` INT(11) NULL DEFAULT NULL ,
  `ar_cre_dtim` DATETIME NOT NULL ,
  `ar_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`ar_id`) ,
  UNIQUE INDEX `ar_code` (`ar_code` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`user`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`user` (
  `user_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `user_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `user_username` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `user_password` CHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `user_pswd_dtim` DATETIME NULL DEFAULT NULL ,
  `user_first_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `user_last_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `user_pref` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `user_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `user_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `user_cre_user` INT(11) NULL DEFAULT NULL ,
  `user_upd_user` INT(11) NULL DEFAULT NULL ,
  `user_cre_dtim` DATETIME NOT NULL ,
  `user_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`user_id`) ,
  UNIQUE INDEX `user_uuid` (`user_uuid` ASC) ,
  UNIQUE INDEX `user_username` (`user_username` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`batch`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`batch` (
  `batch_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `batch_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `batch_user_id` INT(11) NOT NULL ,
  `batch_parent_id` INT(11) NULL DEFAULT NULL ,
  `batch_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `batch_desc` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `batch_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `batch_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `batch_shared_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `batch_cre_user` INT(11) NOT NULL ,
  `batch_upd_user` INT(11) NULL DEFAULT NULL ,
  `batch_cre_dtim` DATETIME NOT NULL ,
  `batch_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`batch_id`) ,
  UNIQUE INDEX `batch_uuid` (`batch_uuid` ASC) ,
  INDEX `batch_user_id_idx` (`batch_user_id` ASC) ,
  CONSTRAINT `batch_batch_user_id_user_user_id`
    FOREIGN KEY (`batch_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`batch_item`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`batch_item` (
  `bitem_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `bitem_batch_id` INT(11) NOT NULL ,
  `bitem_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `bitem_xid` INT(11) NOT NULL ,
  `bitem_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `bitem_cre_user` INT(11) NOT NULL ,
  `bitem_upd_user` INT(11) NULL DEFAULT NULL ,
  `bitem_cre_dtim` DATETIME NOT NULL ,
  `bitem_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`bitem_id`) ,
  UNIQUE INDEX `bitem_uniqueidx_1_idx` (`bitem_batch_id` ASC, `bitem_type` ASC, `bitem_xid` ASC) ,
  INDEX `batch_item_bitem_type_idx` (`bitem_type` ASC) ,
  INDEX `bitem_batch_id_idx` (`bitem_batch_id` ASC) ,
  CONSTRAINT `batch_item_bitem_batch_id_batch_batch_id`
    FOREIGN KEY (`bitem_batch_id` )
    REFERENCES `air2`.`batch` (`batch_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`batch_related`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`batch_related` (
  `brel_bitem_id` INT(11) NOT NULL DEFAULT '0' ,
  `brel_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '' ,
  `brel_xid` INT(11) NOT NULL DEFAULT '0' ,
  `brel_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `brel_cre_user` INT(11) NOT NULL ,
  `brel_upd_user` INT(11) NULL DEFAULT NULL ,
  `brel_cre_dtim` DATETIME NOT NULL ,
  `brel_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`brel_bitem_id`, `brel_type`, `brel_xid`) ,
  CONSTRAINT `batch_related_brel_bitem_id_batch_item_bitem_id`
    FOREIGN KEY (`brel_bitem_id` )
    REFERENCES `air2`.`batch_item` (`bitem_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`code_master`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`code_master` (
  `cm_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `cm_field_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `cm_code` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `cm_table_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `cm_disp_value` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `cm_disp_seq` SMALLINT(6) NOT NULL DEFAULT '10' ,
  `cm_area` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `cm_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `cm_cre_user` INT(11) NOT NULL ,
  `cm_upd_user` INT(11) NULL DEFAULT NULL ,
  `cm_cre_dtim` DATETIME NOT NULL ,
  `cm_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`cm_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`country`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`country` (
  `cntry_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `cntry_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `cntry_code` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `cntry_disp_seq` SMALLINT(6) NOT NULL ,
  PRIMARY KEY (`cntry_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`fact`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`fact` (
  `fact_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `fact_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `fact_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `fact_identifier` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `fact_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `fact_cre_user` INT(11) NOT NULL ,
  `fact_upd_user` INT(11) NULL DEFAULT NULL ,
  `fact_cre_dtim` DATETIME NOT NULL ,
  `fact_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `fact_fv_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`fact_id`) ,
  UNIQUE INDEX `fact_uuid` (`fact_uuid` ASC) ,
  UNIQUE INDEX `fact_identifier` (`fact_identifier` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`fact_value`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`fact_value` (
  `fv_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `fv_fact_id` INT(11) NOT NULL ,
  `fv_parent_fv_id` INT(11) NULL DEFAULT NULL ,
  `fv_seq` SMALLINT(6) NOT NULL DEFAULT '10' ,
  `fv_value` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `fv_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `fv_cre_user` INT(11) NOT NULL ,
  `fv_upd_user` INT(11) NULL DEFAULT NULL ,
  `fv_cre_dtim` DATETIME NOT NULL ,
  `fv_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`fv_id`) ,
  INDEX `fv_fact_id_idx` (`fv_fact_id` ASC) ,
  CONSTRAINT `fact_value_fv_fact_id_fact_fact_id`
    FOREIGN KEY (`fv_fact_id` )
    REFERENCES `air2`.`fact` (`fact_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`locale`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`locale` (
  `loc_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `loc_key` CHAR(5) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`loc_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`inquiry`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`inquiry` (
  `inq_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `inq_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `inq_title` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `inq_ext_title` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `inq_publish_dtim` DATETIME NULL DEFAULT NULL ,
  `inq_deadline_dtim` DATETIME NULL DEFAULT NULL ,
  `inq_desc` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `inq_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'F' ,
  `inq_xid` INT(11) NULL DEFAULT NULL ,
  `inq_loc_id` INT(11) NOT NULL DEFAULT '52' ,
  `inq_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `inq_expire_msg` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `inq_expire_dtim` DATETIME NULL DEFAULT NULL ,
  `inq_cre_user` INT(11) NOT NULL ,
  `inq_upd_user` INT(11) NULL DEFAULT NULL ,
  `inq_cre_dtim` DATETIME NOT NULL ,
  `inq_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`inq_id`) ,
  UNIQUE INDEX `inq_uuid` (`inq_uuid` ASC) ,
  INDEX `inq_loc_id_idx` (`inq_loc_id` ASC) ,
  CONSTRAINT `inquiry_inq_loc_id_locale_loc_id`
    FOREIGN KEY (`inq_loc_id` )
    REFERENCES `air2`.`locale` (`loc_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`iptc_master`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`iptc_master` (
  `iptc_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `iptc_concept_code` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `iptc_name` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `iptc_cre_user` INT(11) NOT NULL ,
  `iptc_upd_user` INT(11) NULL DEFAULT NULL ,
  `iptc_cre_dtim` DATETIME NOT NULL ,
  `iptc_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`iptc_id`) ,
  UNIQUE INDEX `iptc_name` (`iptc_name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`job_queue`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`job_queue` (
  `jq_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `jq_job` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `jq_pid` INT(11) NULL DEFAULT NULL ,
  `jq_host` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `jq_error_msg` TEXT NULL DEFAULT NULL ,
  `jq_cre_user` INT(11) NOT NULL ,
  `jq_cre_dtim` DATETIME NOT NULL ,
  `jq_start_dtim` DATETIME NULL DEFAULT NULL ,
  `jq_complete_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`jq_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project` (
  `prj_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `prj_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `prj_name` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `prj_display_name` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `prj_desc` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `prj_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `prj_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'I' ,
  `prj_cre_user` INT(11) NOT NULL ,
  `prj_upd_user` INT(11) NULL DEFAULT NULL ,
  `prj_cre_dtim` DATETIME NOT NULL ,
  `prj_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`prj_id`) ,
  UNIQUE INDEX `prj_uuid` (`prj_uuid` ASC) ,
  UNIQUE INDEX `prj_name` (`prj_name` ASC) ,
  UNIQUE INDEX `prj_display_name` (`prj_display_name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`organization`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`organization` (
  `org_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `org_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `org_name` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `org_logo_uri` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `org_display_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `org_parent_id` INT(11) NULL DEFAULT NULL ,
  `org_default_prj_id` INT(11) NOT NULL DEFAULT '1' ,
  `org_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'N' ,
  `org_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `org_max_users` INT(11) NULL DEFAULT '0' ,
  `org_html_color` CHAR(6) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '000000' ,
  `org_cre_user` INT(11) NOT NULL ,
  `org_upd_user` INT(11) NULL DEFAULT NULL ,
  `org_cre_dtim` DATETIME NOT NULL ,
  `org_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`org_id`) ,
  UNIQUE INDEX `org_uuid` (`org_uuid` ASC) ,
  UNIQUE INDEX `org_name` (`org_name` ASC) ,
  INDEX `org_default_prj_id_idx` (`org_default_prj_id` ASC) ,
  INDEX `org_parent_id_idx` (`org_parent_id` ASC) ,
  CONSTRAINT `organization_org_default_prj_id_project_prj_id`
    FOREIGN KEY (`org_default_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` ),
  CONSTRAINT `organization_org_parent_id_organization_org_id`
    FOREIGN KEY (`org_parent_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`org_sys_id`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`org_sys_id` (
  `osid_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `osid_org_id` INT(11) NOT NULL ,
  `osid_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `osid_xuuid` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `osid_cre_user` INT(11) NOT NULL ,
  `osid_upd_user` INT(11) NULL DEFAULT NULL ,
  `osid_cre_dtim` DATETIME NOT NULL ,
  `osid_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`osid_id`) ,
  INDEX `osid_org_id_idx` (`osid_org_id` ASC) ,
  CONSTRAINT `org_sys_id_osid_org_id_organization_org_id`
    FOREIGN KEY (`osid_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`password_reset`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`password_reset` (
  `pwr_uuid` CHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '' ,
  `pwr_expiration_dtim` DATETIME NOT NULL ,
  `pwr_user_id` INT(11) NOT NULL ,
  PRIMARY KEY (`pwr_uuid`) ,
  INDEX `pwr_user_id_idx` (`pwr_user_id` ASC) ,
  CONSTRAINT `password_reset_pwr_user_id_user_user_id`
    FOREIGN KEY (`pwr_user_id` )
    REFERENCES `air2`.`user` (`user_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`preference_type`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`preference_type` (
  `pt_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `pt_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `pt_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `pt_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `pt_cre_user` INT(11) NOT NULL ,
  `pt_upd_user` INT(11) NULL DEFAULT NULL ,
  `pt_cre_dtim` DATETIME NOT NULL ,
  `pt_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`pt_id`) ,
  UNIQUE INDEX `pt_uuid` (`pt_uuid` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`preference_type_value`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`preference_type_value` (
  `ptv_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `ptv_pt_id` INT(11) NOT NULL ,
  `ptv_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `ptv_seq` SMALLINT(6) NOT NULL DEFAULT '10' ,
  `ptv_value` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `ptv_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `ptv_cre_user` INT(11) NOT NULL ,
  `ptv_upd_user` INT(11) NULL DEFAULT NULL ,
  `ptv_cre_dtim` DATETIME NOT NULL ,
  `ptv_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`ptv_id`) ,
  UNIQUE INDEX `ptv_uuid` (`ptv_uuid` ASC) ,
  INDEX `ptv_pt_id_idx` (`ptv_pt_id` ASC) ,
  CONSTRAINT `preference_type_value_ptv_pt_id_preference_type_pt_id`
    FOREIGN KEY (`ptv_pt_id` )
    REFERENCES `air2`.`preference_type` (`pt_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_activity`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_activity` (
  `pa_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `pa_actm_id` INT(11) NOT NULL ,
  `pa_prj_id` INT(11) NOT NULL ,
  `pa_dtim` DATETIME NOT NULL ,
  `pa_desc` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `pa_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `pa_cre_user` INT(11) NOT NULL ,
  `pa_upd_user` INT(11) NULL DEFAULT NULL ,
  `pa_cre_dtim` DATETIME NOT NULL ,
  `pa_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `pa_xid` INT(11) NULL DEFAULT NULL ,
  `pa_ref_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  PRIMARY KEY (`pa_id`) ,
  INDEX `pa_prj_id_idx` (`pa_prj_id` ASC) ,
  INDEX `pa_actm_id_idx` (`pa_actm_id` ASC) ,
  CONSTRAINT `project_activity_pa_actm_id_activity_master_actm_id`
    FOREIGN KEY (`pa_actm_id` )
    REFERENCES `air2`.`activity_master` (`actm_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_activity_pa_prj_id_project_prj_id`
    FOREIGN KEY (`pa_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_annotation` (
  `prjan_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `prjan_prj_id` INT(11) NOT NULL ,
  `prjan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `prjan_cre_user` INT(11) NOT NULL ,
  `prjan_upd_user` INT(11) NULL DEFAULT NULL ,
  `prjan_cre_dtim` DATETIME NOT NULL ,
  `prjan_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`prjan_id`) ,
  INDEX `prjan_prj_id_idx` (`prjan_prj_id` ASC) ,
  CONSTRAINT `project_annotation_prjan_prj_id_project_prj_id`
    FOREIGN KEY (`prjan_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_batch`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_batch` (
  `pb_prj_id` INT(11) NOT NULL DEFAULT '0' ,
  `pb_batch_id` INT(11) NOT NULL DEFAULT '0' ,
  `pb_cre_user` INT(11) NOT NULL ,
  `pb_upd_user` INT(11) NULL DEFAULT NULL ,
  `pb_cre_dtim` DATETIME NOT NULL ,
  `pb_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`pb_prj_id`, `pb_batch_id`) ,
  INDEX `project_batch_pb_batch_id_batch_batch_id` (`pb_batch_id` ASC) ,
  CONSTRAINT `project_batch_pb_batch_id_batch_batch_id`
    FOREIGN KEY (`pb_batch_id` )
    REFERENCES `air2`.`batch` (`batch_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_batch_pb_prj_id_project_prj_id`
    FOREIGN KEY (`pb_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_inquiry`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_inquiry` (
  `pinq_prj_id` INT(11) NOT NULL DEFAULT '0' ,
  `pinq_inq_id` INT(11) NOT NULL DEFAULT '0' ,
  `pinq_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `pinq_cre_user` INT(11) NOT NULL ,
  `pinq_upd_user` INT(11) NULL DEFAULT NULL ,
  `pinq_cre_dtim` DATETIME NOT NULL ,
  `pinq_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`pinq_prj_id`, `pinq_inq_id`) ,
  INDEX `project_inquiry_pinq_inq_id_inquiry_inq_id` (`pinq_inq_id` ASC) ,
  CONSTRAINT `project_inquiry_pinq_inq_id_inquiry_inq_id`
    FOREIGN KEY (`pinq_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_inquiry_pinq_prj_id_project_prj_id`
    FOREIGN KEY (`pinq_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_message`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_message` (
  `pm_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `pm_pj_id` INT(11) NOT NULL ,
  `pm_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `pm_channel` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `pm_channel_xid` INT(11) NULL DEFAULT NULL ,
  `pm_cre_user` INT(11) NOT NULL ,
  `pm_upd_user` INT(11) NULL DEFAULT NULL ,
  `pm_cre_dtim` DATETIME NOT NULL ,
  `pm_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`pm_id`) ,
  INDEX `pm_pj_id_idx` (`pm_pj_id` ASC) ,
  CONSTRAINT `project_message_pm_pj_id_project_prj_id`
    FOREIGN KEY (`pm_pj_id` )
    REFERENCES `air2`.`project` (`prj_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_org` (
  `porg_prj_id` INT(11) NOT NULL DEFAULT '0' ,
  `porg_org_id` INT(11) NOT NULL DEFAULT '0' ,
  `porg_contact_user_id` INT(11) NOT NULL ,
  `porg_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `porg_cre_user` INT(11) NOT NULL ,
  `porg_upd_user` INT(11) NULL DEFAULT NULL ,
  `porg_cre_dtim` DATETIME NOT NULL ,
  `porg_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`porg_prj_id`, `porg_org_id`) ,
  INDEX `porg_contact_user_id_idx` (`porg_contact_user_id` ASC) ,
  INDEX `project_org_porg_org_id_organization_org_id` (`porg_org_id` ASC) ,
  CONSTRAINT `project_org_porg_contact_user_id_user_user_id`
    FOREIGN KEY (`porg_contact_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_org_porg_org_id_organization_org_id`
    FOREIGN KEY (`porg_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_org_porg_prj_id_project_prj_id`
    FOREIGN KEY (`porg_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_outcome`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_outcome` (
  `prjo_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `prjo_prj_id` INT(11) NOT NULL ,
  `prjo_headline` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `prjo_link` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `prjo_teaser` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `prjo_dtim` DATETIME NULL DEFAULT NULL ,
  `prjo_cre_user` INT(11) NOT NULL ,
  `prjo_upd_user` INT(11) NULL DEFAULT NULL ,
  `prjo_cre_dtim` DATETIME NOT NULL ,
  `prjo_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`prjo_id`) ,
  INDEX `prjo_prj_id_idx` (`prjo_prj_id` ASC) ,
  CONSTRAINT `project_outcome_prjo_prj_id_project_prj_id`
    FOREIGN KEY (`prjo_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`saved_search`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`saved_search` (
  `ssearch_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `ssearch_name` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'My Search' ,
  `ssearch_shared_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `ssearch_params` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `ssearch_cre_user` INT(11) NOT NULL ,
  `ssearch_upd_user` INT(11) NULL DEFAULT NULL ,
  `ssearch_cre_dtim` DATETIME NOT NULL ,
  `ssearch_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `ssearch_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`ssearch_id`) ,
  UNIQUE INDEX `ssearch_name` (`ssearch_name` ASC) ,
  UNIQUE INDEX `ssearch_uuid` (`ssearch_uuid` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`project_saved_search`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`project_saved_search` (
  `pss_prj_id` INT(11) NOT NULL DEFAULT '0' ,
  `pss_ssearch_id` INT(11) NOT NULL DEFAULT '0' ,
  `pss_cre_user` INT(11) NOT NULL ,
  `pss_upd_user` INT(11) NULL DEFAULT NULL ,
  `pss_cre_dtim` DATETIME NOT NULL ,
  `pss_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`pss_prj_id`, `pss_ssearch_id`) ,
  INDEX `project_saved_search_pss_ssearch_id_saved_search_ssearch_id` (`pss_ssearch_id` ASC) ,
  CONSTRAINT `project_saved_search_pss_prj_id_project_prj_id`
    FOREIGN KEY (`pss_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE,
  CONSTRAINT `project_saved_search_pss_ssearch_id_saved_search_ssearch_id`
    FOREIGN KEY (`pss_ssearch_id` )
    REFERENCES `air2`.`saved_search` (`ssearch_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`question`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`question` (
  `ques_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `ques_inq_id` INT(11) NOT NULL ,
  `ques_dis_seq` SMALLINT(6) NULL DEFAULT NULL ,
  `ques_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `ques_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'T' ,
  `ques_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `ques_choices` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `ques_cre_user` INT(11) NOT NULL ,
  `ques_upd_user` INT(11) NULL DEFAULT NULL ,
  `ques_cre_dtim` DATETIME NOT NULL ,
  `ques_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `ques_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`ques_id`) ,
  UNIQUE INDEX `ques_uuid` (`ques_uuid` ASC) ,
  INDEX `ques_inq_id_idx` (`ques_inq_id` ASC) ,
  CONSTRAINT `question_ques_inq_id_inquiry_inq_id`
    FOREIGN KEY (`ques_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`source`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`source` (
  `src_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `src_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `src_username` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `src_first_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_last_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_middle_initial` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_pre_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_post_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `src_has_acct` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'N' ,
  `src_channel` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_cre_user` INT(11) NOT NULL ,
  `src_upd_user` INT(11) NULL DEFAULT NULL ,
  `src_cre_dtim` DATETIME NOT NULL ,
  `src_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`src_id`) ,
  UNIQUE INDEX `src_uuid` (`src_uuid` ASC) ,
  UNIQUE INDEX `src_username` (`src_username` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_media_asset`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_media_asset` (
  `sma_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sma_src_id` INT(11) NOT NULL ,
  `sma_sr_id` INT(11) NOT NULL ,
  `sma_file_ext` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sma_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sma_file_uri` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sma_file_size` INT(11) NULL DEFAULT NULL ,
  `sma_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sma_export_flag` TINYINT(1) NOT NULL ,
  `sma_public_flag` TINYINT(1) NOT NULL ,
  `sma_archive_flag` TINYINT(1) NOT NULL ,
  `sma_delete_flag` TINYINT(1) NOT NULL ,
  `sma_cre_user` INT(11) NOT NULL ,
  `sma_upd_user` INT(11) NULL DEFAULT NULL ,
  `sma_cre_dtim` DATETIME NOT NULL ,
  `sma_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sma_id`) ,
  INDEX `sma_src_id_idx` (`sma_src_id` ASC) ,
  CONSTRAINT `src_media_asset_sma_src_id_source_src_id`
    FOREIGN KEY (`sma_src_id` )
    REFERENCES `air2`.`source` (`src_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`sma_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`sma_annotation` (
  `smaan_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `smaan_sma_id` INT(11) NOT NULL ,
  `smaan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smaan_cre_user` INT(11) NOT NULL ,
  `smaan_upd_user` INT(11) NULL DEFAULT NULL ,
  `smaan_cre_dtim` DATETIME NOT NULL ,
  `smaan_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`smaan_id`) ,
  INDEX `smaan_sma_id_idx` (`smaan_sma_id` ASC) ,
  CONSTRAINT `sma_annotation_smaan_sma_id_src_media_asset_sma_id`
    FOREIGN KEY (`smaan_sma_id` )
    REFERENCES `air2`.`src_media_asset` (`sma_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_response_set`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_response_set` (
  `srs_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `srs_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `srs_src_id` INT(11) NOT NULL ,
  `srs_inq_id` INT(11) NOT NULL ,
  `srs_date` DATETIME NOT NULL ,
  `srs_uri` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srs_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'F' ,
  `srs_public_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_delete_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_translated_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_export_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_loc_id` INT(11) NOT NULL DEFAULT '52' ,
  `srs_conf_level` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srs_cre_user` INT(11) NOT NULL ,
  `srs_upd_user` INT(11) NULL DEFAULT NULL ,
  `srs_cre_dtim` DATETIME NOT NULL ,
  `srs_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`srs_id`) ,
  UNIQUE INDEX `srs_uuid` (`srs_uuid` ASC) ,
  INDEX `srs_src_id_idx` (`srs_src_id` ASC) ,
  INDEX `srs_inq_id_idx` (`srs_inq_id` ASC) ,
  INDEX `srs_loc_id_idx` (`srs_loc_id` ASC) ,
  CONSTRAINT `src_response_set_srs_inq_id_inquiry_inq_id`
    FOREIGN KEY (`srs_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_response_set_srs_loc_id_locale_loc_id`
    FOREIGN KEY (`srs_loc_id` )
    REFERENCES `air2`.`locale` (`loc_id` ),
  CONSTRAINT `src_response_set_srs_src_id_source_src_id`
    FOREIGN KEY (`srs_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_response`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_response` (
  `sr_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sr_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sr_src_id` INT(11) NOT NULL ,
  `sr_ques_id` INT(11) NOT NULL ,
  `sr_srs_id` INT(11) NOT NULL ,
  `sr_media_asset_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sr_orig_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sr_mod_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sr_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sr_cre_user` INT(11) NOT NULL ,
  `sr_upd_user` INT(11) NULL DEFAULT NULL ,
  `sr_cre_dtim` DATETIME NOT NULL ,
  `sr_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sr_id`) ,
  UNIQUE INDEX `sr_uuid` (`sr_uuid` ASC) ,
  INDEX `sr_srs_id_idx` (`sr_srs_id` ASC) ,
  INDEX `sr_ques_id_idx` (`sr_ques_id` ASC) ,
  INDEX `sr_src_id_idx` (`sr_src_id` ASC) ,
  CONSTRAINT `src_response_sr_ques_id_question_ques_id`
    FOREIGN KEY (`sr_ques_id` )
    REFERENCES `air2`.`question` (`ques_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_response_sr_src_id_source_src_id`
    FOREIGN KEY (`sr_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_response_sr_srs_id_src_response_set_srs_id`
    FOREIGN KEY (`sr_srs_id` )
    REFERENCES `air2`.`src_response_set` (`srs_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`sr_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`sr_annotation` (
  `sran_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sran_sr_id` INT(11) NOT NULL ,
  `sran_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sran_cre_user` INT(11) NOT NULL ,
  `sran_upd_user` INT(11) NULL DEFAULT NULL ,
  `sran_cre_dtim` DATETIME NOT NULL ,
  `sran_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sran_id`) ,
  INDEX `sran_sr_id_idx` (`sran_sr_id` ASC) ,
  CONSTRAINT `sr_annotation_sran_sr_id_src_response_sr_id`
    FOREIGN KEY (`sran_sr_id` )
    REFERENCES `air2`.`src_response` (`sr_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_activity`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_activity` (
  `sact_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sact_actm_id` INT(11) NOT NULL ,
  `sact_src_id` INT(11) NOT NULL ,
  `sact_prj_id` INT(11) NULL DEFAULT NULL ,
  `sact_dtim` DATETIME NOT NULL ,
  `sact_desc` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sact_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sact_cre_user` INT(11) NOT NULL ,
  `sact_upd_user` INT(11) NULL DEFAULT NULL ,
  `sact_cre_dtim` DATETIME NOT NULL ,
  `sact_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `sact_xid` INT(11) NULL DEFAULT NULL ,
  `sact_ref_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  PRIMARY KEY (`sact_id`) ,
  INDEX `sact_ix_3_idx` (`sact_prj_id` ASC, `sact_dtim` ASC) ,
  INDEX `sact_ix_4_idx` (`sact_upd_dtim` ASC) ,
  INDEX `sact_ix_5_idx` (`sact_cre_user` ASC) ,
  INDEX `sact_src_id_idx` (`sact_src_id` ASC) ,
  INDEX `sact_actm_id_idx` (`sact_actm_id` ASC) ,
  INDEX `sact_prj_id_idx` (`sact_prj_id` ASC) ,
  CONSTRAINT `src_activity_sact_actm_id_activity_master_actm_id`
    FOREIGN KEY (`sact_actm_id` )
    REFERENCES `air2`.`activity_master` (`actm_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_activity_sact_prj_id_project_prj_id`
    FOREIGN KEY (`sact_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_activity_sact_src_id_source_src_id`
    FOREIGN KEY (`sact_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_alias`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_alias` (
  `sa_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sa_src_id` INT(11) NOT NULL ,
  `sa_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_first_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_last_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_post_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_cre_user` INT(11) NOT NULL ,
  `sa_upd_user` INT(11) NULL DEFAULT NULL ,
  `sa_cre_dtim` DATETIME NOT NULL ,
  `sa_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sa_id`) ,
  INDEX `sa_src_id_idx` (`sa_src_id` ASC) ,
  CONSTRAINT `src_alias_sa_src_id_source_src_id`
    FOREIGN KEY (`sa_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_annotation` (
  `srcan_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `srcan_src_id` INT(11) NOT NULL ,
  `srcan_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'S' ,
  `srcan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srcan_cre_user` INT(11) NOT NULL ,
  `srcan_upd_user` INT(11) NULL DEFAULT NULL ,
  `srcan_cre_dtim` DATETIME NOT NULL ,
  `srcan_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`srcan_id`) ,
  INDEX `srcan_src_id_idx` (`srcan_src_id` ASC) ,
  CONSTRAINT `src_annotation_srcan_src_id_source_src_id`
    FOREIGN KEY (`srcan_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_email`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_email` (
  `sem_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sem_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sem_src_id` INT(11) NOT NULL ,
  `sem_primary_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sem_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sem_email` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sem_effective_date` DATE NULL DEFAULT NULL ,
  `sem_expire_date` DATE NULL DEFAULT NULL ,
  `sem_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'G' ,
  `sem_cre_user` INT(11) NOT NULL ,
  `sem_upd_user` INT(11) NULL DEFAULT NULL ,
  `sem_cre_dtim` DATETIME NOT NULL ,
  `sem_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sem_id`) ,
  UNIQUE INDEX `sem_uuid` (`sem_uuid` ASC) ,
  UNIQUE INDEX `sem_email` (`sem_email` ASC) ,
  INDEX `sem_src_id_idx` (`sem_src_id` ASC) ,
  CONSTRAINT `src_email_sem_src_id_source_src_id`
    FOREIGN KEY (`sem_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_fact`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_fact` (
  `sf_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `sf_fact_id` INT(11) NOT NULL DEFAULT '0' ,
  `sf_fv_id` INT(11) NULL DEFAULT NULL ,
  `sf_src_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sf_src_fv_id` INT(11) NULL DEFAULT NULL ,
  `sf_lock_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sf_public_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sf_cre_user` INT(11) NOT NULL ,
  `sf_upd_user` INT(11) NULL DEFAULT NULL ,
  `sf_cre_dtim` DATETIME NOT NULL ,
  `sf_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sf_src_id`, `sf_fact_id`) ,
  INDEX `sf_fv_id_idx` (`sf_fv_id` ASC) ,
  INDEX `sf_src_fv_id_idx` (`sf_src_fv_id` ASC) ,
  INDEX `src_fact_sf_fact_id_fact_fact_id` (`sf_fact_id` ASC) ,
  CONSTRAINT `src_fact_sf_fact_id_fact_fact_id`
    FOREIGN KEY (`sf_fact_id` )
    REFERENCES `air2`.`fact` (`fact_id` ),
  CONSTRAINT `src_fact_sf_fv_id_fact_value_fv_id`
    FOREIGN KEY (`sf_fv_id` )
    REFERENCES `air2`.`fact_value` (`fv_id` ),
  CONSTRAINT `src_fact_sf_src_fv_id_fact_value_fv_id`
    FOREIGN KEY (`sf_src_fv_id` )
    REFERENCES `air2`.`fact_value` (`fv_id` ),
  CONSTRAINT `src_fact_sf_src_id_source_src_id`
    FOREIGN KEY (`sf_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_inquiry`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_inquiry` (
  `si_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `si_src_id` INT(11) NOT NULL ,
  `si_inq_id` INT(11) NOT NULL ,
  `si_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'P' ,
  `si_sent_by` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `si_cre_user` INT(11) NOT NULL ,
  `si_upd_user` INT(11) NULL DEFAULT NULL ,
  `si_cre_dtim` DATETIME NOT NULL ,
  `si_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`si_id`) ,
  INDEX `si_src_id_idx` (`si_src_id` ASC) ,
  INDEX `si_inq_id_idx` (`si_inq_id` ASC) ,
  CONSTRAINT `src_inquiry_si_inq_id_inquiry_inq_id`
    FOREIGN KEY (`si_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_inquiry_si_src_id_source_src_id`
    FOREIGN KEY (`si_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_mail_address`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_mail_address` (
  `smadd_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `smadd_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `smadd_src_id` INT(11) NOT NULL ,
  `smadd_primary_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `smadd_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_line_1` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_line_2` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_city` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_state` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_cntry` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_zip` VARCHAR(10) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_lat` FLOAT(18,2) NULL DEFAULT NULL ,
  `smadd_long` FLOAT(18,2) NULL DEFAULT NULL ,
  `smadd_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `smadd_cre_user` INT(11) NOT NULL ,
  `smadd_upd_user` INT(11) NULL DEFAULT NULL ,
  `smadd_cre_dtim` DATETIME NOT NULL ,
  `smadd_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`smadd_id`) ,
  UNIQUE INDEX `smadd_uuid` (`smadd_uuid` ASC) ,
  INDEX `smadd_src_id_idx` (`smadd_src_id` ASC) ,
  CONSTRAINT `src_mail_address_smadd_src_id_source_src_id`
    FOREIGN KEY (`smadd_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_org` (
  `so_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `so_org_id` INT(11) NOT NULL DEFAULT '0' ,
  `so_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `so_effective_date` DATE NOT NULL DEFAULT '1970-01-01' ,
  `so_home_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `so_lock_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `so_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `so_cre_user` INT(11) NOT NULL ,
  `so_upd_user` INT(11) NULL DEFAULT NULL ,
  `so_cre_dtim` DATETIME NOT NULL ,
  `so_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`so_src_id`, `so_org_id`) ,
  UNIQUE INDEX `so_uuid` (`so_uuid` ASC) ,
  INDEX `src_org_so_org_id_organization_org_id` (`so_org_id` ASC) ,
  CONSTRAINT `src_org_so_org_id_organization_org_id`
    FOREIGN KEY (`so_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_org_so_src_id_source_src_id`
    FOREIGN KEY (`so_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_phone_number`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_phone_number` (
  `sph_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sph_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sph_src_id` INT(11) NOT NULL ,
  `sph_primary_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sph_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_country` CHAR(3) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_number` VARCHAR(16) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sph_ext` VARCHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sph_cre_user` INT(11) NOT NULL ,
  `sph_upd_user` INT(11) NULL DEFAULT NULL ,
  `sph_cre_dtim` DATETIME NOT NULL ,
  `sph_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sph_id`) ,
  UNIQUE INDEX `sph_uuid` (`sph_uuid` ASC) ,
  INDEX `sph_src_id_idx` (`sph_src_id` ASC) ,
  CONSTRAINT `src_phone_number_sph_src_id_source_src_id`
    FOREIGN KEY (`sph_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_pref_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_pref_org` (
  `spo_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `spo_src_id` INT(11) NOT NULL ,
  `spo_org_id` INT(11) NOT NULL ,
  `spo_effective` DATETIME NOT NULL ,
  `spo_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `spo_xid` INT(11) NOT NULL ,
  `spo_lock_flag` TINYINT(1) NOT NULL ,
  `spo_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `spo_cre_user` INT(11) NOT NULL ,
  `spo_upd_user` INT(11) NULL DEFAULT NULL ,
  `spo_cre_dtim` DATETIME NOT NULL ,
  `spo_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`spo_id`) ,
  INDEX `spo_src_id_idx` (`spo_src_id` ASC) ,
  INDEX `spo_org_id_idx` (`spo_org_id` ASC) ,
  CONSTRAINT `src_pref_org_spo_org_id_organization_org_id`
    FOREIGN KEY (`spo_org_id` )
    REFERENCES `air2`.`organization` (`org_id` ),
  CONSTRAINT `src_pref_org_spo_src_id_source_src_id`
    FOREIGN KEY (`spo_src_id` )
    REFERENCES `air2`.`source` (`src_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_preference`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_preference` (
  `sp_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `sp_ptv_id` INT(11) NOT NULL DEFAULT '0' ,
  `sp_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sp_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sp_lock_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sp_cre_user` INT(11) NOT NULL ,
  `sp_upd_user` INT(11) NULL DEFAULT NULL ,
  `sp_cre_dtim` DATETIME NOT NULL ,
  `sp_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sp_src_id`, `sp_ptv_id`) ,
  UNIQUE INDEX `sp_uuid` (`sp_uuid` ASC) ,
  INDEX `src_preference_sp_ptv_id_preference_type_value_ptv_id` (`sp_ptv_id` ASC) ,
  CONSTRAINT `src_preference_sp_ptv_id_preference_type_value_ptv_id`
    FOREIGN KEY (`sp_ptv_id` )
    REFERENCES `air2`.`preference_type_value` (`ptv_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_preference_sp_src_id_source_src_id`
    FOREIGN KEY (`sp_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_relationship`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_relationship` (
  `srel_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `src_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `srel_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `srel_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `srel_cre_user` INT(11) NOT NULL ,
  `srel_upd_user` INT(11) NULL DEFAULT NULL ,
  `srel_cre_dtim` DATETIME NOT NULL ,
  `srel_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`srel_src_id`, `src_src_id`) ,
  INDEX `src_relationship_src_src_id_source_src_id` (`src_src_id` ASC) ,
  CONSTRAINT `src_relationship_src_src_id_source_src_id`
    FOREIGN KEY (`src_src_id` )
    REFERENCES `air2`.`source` (`src_id` ),
  CONSTRAINT `src_relationship_srel_src_id_source_src_id`
    FOREIGN KEY (`srel_src_id` )
    REFERENCES `air2`.`source` (`src_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_stat`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_stat` (
  `sstat_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `sstat_export_dtim` DATETIME NULL DEFAULT NULL ,
  `sstat_contact_dtim` DATETIME NULL DEFAULT NULL ,
  `sstat_submit_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sstat_src_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_uri`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_uri` (
  `suri_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `suri_src_id` INT(11) NOT NULL ,
  `suri_primary_flag` TINYINT(1) NOT NULL ,
  `suri_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `suri_value` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `suri_handle` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `suri_feed` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_upd_int` INT(11) NULL DEFAULT NULL ,
  `suri_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `suri_cre_user` INT(11) NOT NULL ,
  `suri_upd_user` INT(11) NULL DEFAULT NULL ,
  `suri_cre_dtim` DATETIME NOT NULL ,
  `suri_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`suri_id`) ,
  INDEX `suri_src_id_idx` (`suri_src_id` ASC) ,
  CONSTRAINT `src_uri_suri_src_id_source_src_id`
    FOREIGN KEY (`suri_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_vita`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_vita` (
  `sv_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `sv_src_id` INT(11) NOT NULL ,
  `sv_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `sv_seq` SMALLINT(6) NOT NULL DEFAULT '10' ,
  `sv_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'I' ,
  `sv_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sv_origin` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '2' ,
  `sv_conf_level` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'U' ,
  `sv_lock_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sv_start_date` DATE NULL DEFAULT NULL ,
  `sv_end_date` DATE NULL DEFAULT NULL ,
  `sv_lat` FLOAT(18,2) NULL DEFAULT NULL ,
  `sv_long` FLOAT(18,2) NULL DEFAULT NULL ,
  `sv_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sv_basis` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sv_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sv_cre_user` INT(11) NOT NULL ,
  `sv_upd_user` INT(11) NULL DEFAULT NULL ,
  `sv_cre_dtim` DATETIME NOT NULL ,
  `sv_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`sv_id`) ,
  UNIQUE INDEX `sv_uuid` (`sv_uuid` ASC) ,
  INDEX `sv_src_id_idx` (`sv_src_id` ASC) ,
  CONSTRAINT `src_vita_sv_src_id_source_src_id`
    FOREIGN KEY (`sv_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`srs_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`srs_annotation` (
  `srsan_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `srsan_srs_id` INT(11) NOT NULL ,
  `srsan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srsan_cre_user` INT(11) NOT NULL ,
  `srsan_upd_user` INT(11) NULL DEFAULT NULL ,
  `srsan_cre_dtim` DATETIME NOT NULL ,
  `srsan_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`srsan_id`) ,
  INDEX `srsan_srs_id_idx` (`srsan_srs_id` ASC) ,
  CONSTRAINT `srs_annotation_srsan_srs_id_src_response_set_srs_id`
    FOREIGN KEY (`srsan_srs_id` )
    REFERENCES `air2`.`src_response_set` (`srs_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`state`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`state` (
  `state_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `state_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `state_code` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`state_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`system_message`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`system_message` (
  `smsg_id` INT(11) NOT NULL DEFAULT '0' ,
  `smsg_value` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smsg_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT 'A' ,
  `smsg_cre_user` INT(11) NOT NULL ,
  `smsg_upd_user` INT(11) NULL DEFAULT NULL ,
  `smsg_cre_dtim` DATETIME NOT NULL ,
  `smsg_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`smsg_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tag_master`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tag_master` (
  `tm_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tm_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'J' ,
  `tm_name` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tm_iptc_id` INT(11) NULL DEFAULT NULL ,
  `tm_cre_user` INT(11) NOT NULL ,
  `tm_upd_user` INT(11) NULL DEFAULT NULL ,
  `tm_cre_dtim` DATETIME NOT NULL ,
  `tm_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`tm_id`) ,
  UNIQUE INDEX `tm_name` (`tm_name` ASC) ,
  UNIQUE INDEX `tm_iptc_id` (`tm_iptc_id` ASC) ,
  INDEX `tm_iptc_id_idx` (`tm_iptc_id` ASC) ,
  CONSTRAINT `tag_master_tm_iptc_id_iptc_master_iptc_id`
    FOREIGN KEY (`tm_iptc_id` )
    REFERENCES `air2`.`iptc_master` (`iptc_id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tag`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tag` (
  `tag_tm_id` INT(11) NOT NULL DEFAULT '0' ,
  `tag_xid` INT(11) NOT NULL DEFAULT '0' ,
  `tag_ref_type` VARCHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '' ,
  `tag_cre_user` INT(11) NOT NULL ,
  `tag_upd_user` INT(11) NULL DEFAULT NULL ,
  `tag_cre_dtim` DATETIME NOT NULL ,
  `tag_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`tag_tm_id`, `tag_xid`, `tag_ref_type`) ,
  INDEX `tag_tag_ref_type_idx` (`tag_ref_type` ASC) ,
  CONSTRAINT `tag_tag_tm_id_tag_master_tm_id`
    FOREIGN KEY (`tag_tm_id` )
    REFERENCES `air2`.`tag_master` (`tm_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank` (
  `tank_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tank_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `tank_user_id` INT(11) NOT NULL ,
  `tank_name` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `tank_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tank_meta` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tank_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `tank_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `tank_cre_user` INT(11) NOT NULL ,
  `tank_upd_user` INT(11) NULL DEFAULT NULL ,
  `tank_cre_dtim` DATETIME NOT NULL ,
  `tank_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`tank_id`) ,
  UNIQUE INDEX `tank_uuid` (`tank_uuid` ASC) ,
  INDEX `tank_user_id_idx` (`tank_user_id` ASC) ,
  CONSTRAINT `tank_tank_user_id_user_user_id`
    FOREIGN KEY (`tank_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_source`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_source` (
  `tsrc_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tsrc_tank_id` INT(11) NOT NULL ,
  `tsrc_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'N' ,
  `tsrc_errors` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tsrc_cre_user` INT(11) NOT NULL ,
  `tsrc_upd_user` INT(11) NULL DEFAULT NULL ,
  `tsrc_cre_dtim` DATETIME NOT NULL ,
  `tsrc_upd_dtim` DATETIME NULL DEFAULT NULL ,
  `tsrc_tags` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_id` INT(11) NULL DEFAULT NULL ,
  `src_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_username` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_first_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_last_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_middle_initial` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_pre_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_post_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `src_channel` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_first_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_last_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sa_post_name` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_primary_flag` TINYINT(1) NULL DEFAULT NULL ,
  `smadd_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_line_1` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_line_2` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_city` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_state` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_cntry` CHAR(2) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_zip` VARCHAR(10) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `smadd_lat` FLOAT(18,2) NULL DEFAULT NULL ,
  `smadd_long` FLOAT(18,2) NULL DEFAULT NULL ,
  `sph_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_primary_flag` TINYINT(1) NULL DEFAULT NULL ,
  `sph_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_country` CHAR(3) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_number` VARCHAR(16) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sph_ext` VARCHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sem_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sem_primary_flag` TINYINT(1) NULL DEFAULT NULL ,
  `sem_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sem_email` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sem_effective_date` DATE NULL DEFAULT NULL ,
  `sem_expire_date` DATE NULL DEFAULT NULL ,
  `suri_primary_flag` TINYINT(1) NULL DEFAULT NULL ,
  `suri_context` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_value` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_handle` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `suri_feed` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srcan_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srcan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  PRIMARY KEY (`tsrc_id`) ,
  INDEX `tsrc_tank_id_idx` (`tsrc_tank_id` ASC) ,
  CONSTRAINT `tank_source_tsrc_tank_id_tank_tank_id`
    FOREIGN KEY (`tsrc_tank_id` )
    REFERENCES `air2`.`tank` (`tank_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_fact`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_fact` (
  `tf_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tf_fact_id` INT(11) NOT NULL ,
  `tf_tsrc_id` INT(11) NOT NULL ,
  `sf_fv_id` INT(11) NULL DEFAULT NULL ,
  `sf_src_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sf_src_fv_id` INT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`tf_id`) ,
  INDEX `tf_tsrc_id_idx` (`tf_tsrc_id` ASC) ,
  INDEX `tf_fact_id_idx` (`tf_fact_id` ASC) ,
  INDEX `sf_fv_id_idx` (`sf_fv_id` ASC) ,
  INDEX `sf_src_fv_id_idx` (`sf_src_fv_id` ASC) ,
  CONSTRAINT `tank_fact_sf_fv_id_fact_value_fv_id`
    FOREIGN KEY (`sf_fv_id` )
    REFERENCES `air2`.`fact_value` (`fv_id` ),
  CONSTRAINT `tank_fact_sf_src_fv_id_fact_value_fv_id`
    FOREIGN KEY (`sf_src_fv_id` )
    REFERENCES `air2`.`fact_value` (`fv_id` ),
  CONSTRAINT `tank_fact_tf_fact_id_fact_fact_id`
    FOREIGN KEY (`tf_fact_id` )
    REFERENCES `air2`.`fact` (`fact_id` ),
  CONSTRAINT `tank_fact_tf_tsrc_id_tank_source_tsrc_id`
    FOREIGN KEY (`tf_tsrc_id` )
    REFERENCES `air2`.`tank_source` (`tsrc_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_log`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_log` (
  `tlog_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tlog_tank_id` INT(11) NOT NULL ,
  `tlog_user_id` INT(11) NOT NULL ,
  `tlog_dtim` DATETIME NOT NULL ,
  `tlog_text` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tlog_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `tlog_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`tlog_id`) ,
  INDEX `tlog_tank_id_idx` (`tlog_tank_id` ASC) ,
  INDEX `tlog_user_id_idx` (`tlog_user_id` ASC) ,
  CONSTRAINT `tank_log_tlog_tank_id_tank_tank_id`
    FOREIGN KEY (`tlog_tank_id` )
    REFERENCES `air2`.`tank` (`tank_id` )
    ON DELETE CASCADE,
  CONSTRAINT `tank_log_tlog_user_id_user_user_id`
    FOREIGN KEY (`tlog_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_response_set`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_response_set` (
  `trs_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `trs_tsrc_id` INT(11) NOT NULL ,
  `srs_inq_id` INT(11) NOT NULL ,
  `srs_date` DATETIME NOT NULL ,
  `srs_uri` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srs_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'F' ,
  `srs_public_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_delete_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_translated_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_export_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `srs_loc_id` INT(11) NOT NULL DEFAULT '52' ,
  `srs_conf_level` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `srs_cre_user` INT(11) NOT NULL ,
  `srs_upd_user` INT(11) NULL DEFAULT NULL ,
  `srs_cre_dtim` DATETIME NOT NULL ,
  `srs_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`trs_id`) ,
  INDEX `trs_tsrc_id_idx` (`trs_tsrc_id` ASC) ,
  INDEX `srs_inq_id_idx` (`srs_inq_id` ASC) ,
  CONSTRAINT `tank_response_set_srs_inq_id_inquiry_inq_id`
    FOREIGN KEY (`srs_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` ),
  CONSTRAINT `tank_response_set_trs_tsrc_id_tank_source_tsrc_id`
    FOREIGN KEY (`trs_tsrc_id` )
    REFERENCES `air2`.`tank_source` (`tsrc_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_response`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_response` (
  `tr_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tr_tsrc_id` INT(11) NOT NULL ,
  `tr_trs_id` INT(11) NOT NULL ,
  `sr_ques_id` INT(11) NOT NULL ,
  `sr_media_asset_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `sr_orig_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sr_mod_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sr_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `sr_cre_user` INT(11) NOT NULL ,
  `sr_upd_user` INT(11) NULL DEFAULT NULL ,
  `sr_cre_dtim` DATETIME NOT NULL ,
  `sr_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`tr_id`) ,
  INDEX `tr_trs_id_idx` (`tr_trs_id` ASC) ,
  INDEX `sr_ques_id_idx` (`sr_ques_id` ASC) ,
  INDEX `tr_tsrc_id_idx` (`tr_tsrc_id` ASC) ,
  CONSTRAINT `tank_response_sr_ques_id_question_ques_id`
    FOREIGN KEY (`sr_ques_id` )
    REFERENCES `air2`.`question` (`ques_id` ),
  CONSTRAINT `tank_response_tr_trs_id_tank_response_set_trs_id`
    FOREIGN KEY (`tr_trs_id` )
    REFERENCES `air2`.`tank_response_set` (`trs_id` )
    ON DELETE CASCADE,
  CONSTRAINT `tank_response_tr_tsrc_id_tank_source_tsrc_id`
    FOREIGN KEY (`tr_tsrc_id` )
    REFERENCES `air2`.`tank_source` (`tsrc_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`translation_map`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`translation_map` (
  `xm_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `xm_fact_id` INT(11) NOT NULL ,
  `xm_xlate_from` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `xm_xlate_to_fv_id` INT(11) NOT NULL ,
  PRIMARY KEY (`xm_id`) ,
  INDEX `xm_fact_id_idx` (`xm_fact_id` ASC) ,
  INDEX `xm_xlate_to_fv_id_idx` (`xm_xlate_to_fv_id` ASC) ,
  CONSTRAINT `translation_map_xm_fact_id_fact_fact_id`
    FOREIGN KEY (`xm_fact_id` )
    REFERENCES `air2`.`fact` (`fact_id` )
    ON DELETE CASCADE,
  CONSTRAINT `translation_map_xm_xlate_to_fv_id_fact_value_fv_id`
    FOREIGN KEY (`xm_xlate_to_fv_id` )
    REFERENCES `air2`.`fact_value` (`fv_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`user_email_address`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`user_email_address` (
  `uem_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `uem_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uem_user_id` INT(11) NOT NULL ,
  `uem_address` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uem_primary_flag` TINYINT(1) NOT NULL ,
  PRIMARY KEY (`uem_id`) ,
  UNIQUE INDEX `uem_uuid` (`uem_uuid` ASC) ,
  INDEX `uem_user_id_idx` (`uem_user_id` ASC) ,
  CONSTRAINT `user_email_address_uem_user_id_user_user_id`
    FOREIGN KEY (`uem_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`user_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`user_org` (
  `uo_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `uo_org_id` INT(11) NOT NULL ,
  `uo_user_id` INT(11) NOT NULL ,
  `uo_ar_id` INT(11) NOT NULL ,
  `uo_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uo_user_title` VARCHAR(64) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `uo_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `uo_notify_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `uo_home_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  `uo_cre_user` INT(11) NOT NULL ,
  `uo_upd_user` INT(11) NULL DEFAULT NULL ,
  `uo_cre_dtim` DATETIME NOT NULL ,
  `uo_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`uo_id`) ,
  UNIQUE INDEX `uo_uuid` (`uo_uuid` ASC) ,
  UNIQUE INDEX `uo_ix_2_idx` (`uo_org_id` ASC, `uo_user_id` ASC) ,
  INDEX `uo_user_id_idx` (`uo_user_id` ASC) ,
  INDEX `uo_org_id_idx` (`uo_org_id` ASC) ,
  INDEX `uo_ar_id_idx` (`uo_ar_id` ASC) ,
  CONSTRAINT `user_org_uo_ar_id_admin_role_ar_id`
    FOREIGN KEY (`uo_ar_id` )
    REFERENCES `air2`.`admin_role` (`ar_id` ),
  CONSTRAINT `user_org_uo_org_id_organization_org_id`
    FOREIGN KEY (`uo_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `user_org_uo_user_id_user_user_id`
    FOREIGN KEY (`uo_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`user_phone_number`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`user_phone_number` (
  `uph_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `uph_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uph_user_id` INT(11) NOT NULL ,
  `uph_country` CHAR(3) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uph_number` VARCHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uph_ext` VARCHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `uph_primary_flag` TINYINT(1) NOT NULL ,
  PRIMARY KEY (`uph_id`) ,
  UNIQUE INDEX `uph_uuid` (`uph_uuid` ASC) ,
  INDEX `uph_user_id_idx` (`uph_user_id` ASC) ,
  CONSTRAINT `user_phone_number_uph_user_id_user_user_id`
    FOREIGN KEY (`uph_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`user_uri`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`user_uri` (
  `uuri_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `uuri_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uuri_user_id` INT(11) NOT NULL ,
  `uuri_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uuri_value` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `uuri_feed` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `uuri_upd_int` INT(11) NULL DEFAULT NULL ,
  `uuri_handle` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`uuri_id`) ,
  UNIQUE INDEX `uuri_uuid` (`uuri_uuid` ASC) ,
  INDEX `uuri_user_id_idx` (`uuri_user_id` ASC) ,
  CONSTRAINT `user_uri_uuri_user_id_user_user_id`
    FOREIGN KEY (`uuri_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_org_email`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_org_email` (
  `soe_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `soe_sem_id` INT(11) NOT NULL ,
  `soe_org_id` INT(11) NOT NULL ,
  `soe_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `soe_status_dtim` DATETIME NOT NULL ,
  PRIMARY KEY (`soe_id`) ,
  UNIQUE INDEX `soe_uniqueidx_1_idx` (`soe_sem_id` ASC, `soe_org_id` ASC) ,
  INDEX `soe_sem_id_idx` (`soe_sem_id` ASC) ,
  INDEX `soe_org_id_idx` (`soe_org_id` ASC) ,
  CONSTRAINT `src_org_email_soe_org_id_organization_org_id`
    FOREIGN KEY (`soe_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_org_email_soe_sem_id_src_email_sem_id`
    FOREIGN KEY (`soe_sem_id` )
    REFERENCES `air2`.`src_email` (`sem_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_export`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_export` (
  `se_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `se_uuid` CHAR(12) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `se_prj_id` INT(11) NULL DEFAULT NULL ,
  `se_inq_id` INT(11) NULL DEFAULT NULL ,
  `se_name` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  `se_cre_user` INT(11) NOT NULL ,
  `se_upd_user` INT(11) NULL DEFAULT NULL ,
  `se_cre_dtim` DATETIME NOT NULL ,
  `se_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`se_id`) ,
  UNIQUE INDEX `se_uuid` (`se_uuid` ASC) ,
  UNIQUE INDEX `se_name` (`se_name` ASC) ,
  INDEX `se_prj_id_idx` (`se_prj_id` ASC) ,
  INDEX `se_inq_id_idx` (`se_inq_id` ASC) ,
  CONSTRAINT `src_export_se_inq_id_inquiry_inq_id`
    FOREIGN KEY (`se_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_export_se_prj_id_project_prj_id`
    FOREIGN KEY (`se_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`src_org_cache`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`src_org_cache` (
  `soc_src_id` INT(11) NOT NULL DEFAULT '0' ,
  `soc_org_id` INT(11) NOT NULL DEFAULT '0' ,
  `soc_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL ,
  PRIMARY KEY (`soc_src_id`, `soc_org_id`) ,
  INDEX `src_org_cache_soc_org_id_organization_org_id` (`soc_org_id` ASC) ,
  CONSTRAINT `src_org_cache_soc_org_id_organization_org_id`
    FOREIGN KEY (`soc_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `src_org_cache_soc_src_id_source_src_id`
    FOREIGN KEY (`soc_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`trackback`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`trackback` (
  `tb_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tb_src_id` INT(11) NOT NULL ,
  `tb_user_id` INT(11) NOT NULL ,
  `tb_ip` INT(10) UNSIGNED NOT NULL ,
  `tb_dtim` DATETIME NOT NULL ,
  PRIMARY KEY (`tb_id`) ,
  INDEX `tb_src_id_idx` (`tb_src_id` ASC) ,
  INDEX `tb_user_id_idx` (`tb_user_id` ASC) ,
  CONSTRAINT `trackback_tb_src_id_source_src_id`
    FOREIGN KEY (`tb_src_id` )
    REFERENCES `air2`.`source` (`src_id` )
    ON DELETE CASCADE,
  CONSTRAINT `trackback_tb_user_id_user_user_id`
    FOREIGN KEY (`tb_user_id` )
    REFERENCES `air2`.`user` (`user_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`inquiry_annotation`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`inquiry_annotation` (
  `inqan_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `inqan_inq_id` INT(11) NOT NULL ,
  `inqan_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `inqan_cre_user` INT(11) NOT NULL ,
  `inqan_upd_user` INT(11) NULL DEFAULT NULL ,
  `inqan_cre_dtim` DATETIME NOT NULL ,
  `inqan_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`inqan_id`) ,
  INDEX `inqan_inq_id_idx` (`inqan_inq_id` ASC) ,
  CONSTRAINT `inquiry_annotation_inqan_inq_id_inquiry_inq_id`
    FOREIGN KEY (`inqan_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`inq_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`inq_org` (
  `iorg_inq_id` INT(11) NOT NULL DEFAULT '0' ,
  `iorg_org_id` INT(11) NOT NULL DEFAULT '0' ,
  `iorg_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `iorg_cre_user` INT(11) NOT NULL ,
  `iorg_upd_user` INT(11) NULL DEFAULT NULL ,
  `iorg_cre_dtim` DATETIME NOT NULL ,
  `iorg_upd_dtim` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`iorg_inq_id`, `iorg_org_id`) ,
  INDEX `inq_org_iorg_org_id_organization_org_id` (`iorg_org_id` ASC) ,
  CONSTRAINT `inq_org_iorg_inq_id_inquiry_inq_id`
    FOREIGN KEY (`iorg_inq_id` )
    REFERENCES `air2`.`inquiry` (`inq_id` )
    ON DELETE CASCADE,
  CONSTRAINT `inq_org_iorg_org_id_organization_org_id`
    FOREIGN KEY (`iorg_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_vita`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_vita` (
  `tv_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tv_tsrc_id` INT(11) NOT NULL ,
  `sv_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'I' ,
  `sv_origin` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT '2' ,
  `sv_start_date` DATE NULL DEFAULT NULL ,
  `sv_end_date` DATE NULL DEFAULT NULL ,
  `sv_lat` FLOAT(18,2) NULL DEFAULT NULL ,
  `sv_long` FLOAT(18,2) NULL DEFAULT NULL ,
  `sv_value` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sv_basis` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `sv_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  PRIMARY KEY (`tv_id`) ,
  INDEX `tv_tsrc_id_idx` (`tv_tsrc_id` ASC) ,
  CONSTRAINT `tank_vita_tv_tsrc_id_tank_source_tsrc_id`
    FOREIGN KEY (`tv_tsrc_id` )
    REFERENCES `air2`.`tank_source` (`tsrc_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_org`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_org` (
  `to_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `to_tank_id` INT(11) NOT NULL ,
  `to_org_id` INT(11) NOT NULL ,
  `to_so_status` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'A' ,
  `to_so_home_flag` TINYINT(1) NOT NULL DEFAULT '0' ,
  PRIMARY KEY (`to_id`) ,
  INDEX `to_tank_id_idx` (`to_tank_id` ASC) ,
  INDEX `to_org_id_idx` (`to_org_id` ASC) ,
  CONSTRAINT `tank_org_to_org_id_organization_org_id`
    FOREIGN KEY (`to_org_id` )
    REFERENCES `air2`.`organization` (`org_id` )
    ON DELETE CASCADE,
  CONSTRAINT `tank_org_to_tank_id_tank_tank_id`
    FOREIGN KEY (`to_tank_id` )
    REFERENCES `air2`.`tank` (`tank_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;


-- -----------------------------------------------------
-- Table `air2`.`tank_activity`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `air2`.`tank_activity` (
  `tact_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `tact_tank_id` INT(11) NOT NULL ,
  `tact_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL DEFAULT 'S' ,
  `tact_actm_id` INT(11) NOT NULL ,
  `tact_prj_id` INT(11) NULL DEFAULT NULL ,
  `tact_dtim` DATETIME NOT NULL ,
  `tact_desc` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tact_notes` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  `tact_xid` INT(11) NULL DEFAULT NULL ,
  `tact_ref_type` CHAR(1) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ,
  PRIMARY KEY (`tact_id`) ,
  INDEX `tact_tank_id_idx` (`tact_tank_id` ASC) ,
  INDEX `tact_actm_id_idx` (`tact_actm_id` ASC) ,
  INDEX `tact_prj_id_idx` (`tact_prj_id` ASC) ,
  CONSTRAINT `tank_activity_tact_actm_id_activity_master_actm_id`
    FOREIGN KEY (`tact_actm_id` )
    REFERENCES `air2`.`activity_master` (`actm_id` )
    ON DELETE CASCADE,
  CONSTRAINT `tank_activity_tact_prj_id_project_prj_id`
    FOREIGN KEY (`tact_prj_id` )
    REFERENCES `air2`.`project` (`prj_id` )
    ON DELETE CASCADE,
  CONSTRAINT `tank_activity_tact_tank_id_tank_tank_id`
    FOREIGN KEY (`tact_tank_id` )
    REFERENCES `air2`.`tank` (`tank_id` )
    ON DELETE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
