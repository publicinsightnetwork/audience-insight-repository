-- MySQL dump 10.13  Distrib 5.7.9, for Linux (x86_64)
--
-- Host: localhost    Database: air2
-- ------------------------------------------------------
-- Server version	5.7.9

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_master`
--

DROP TABLE IF EXISTS `activity_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activity_master` (
  `actm_id` int(11) NOT NULL AUTO_INCREMENT,
  `actm_status` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `actm_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `actm_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `actm_table_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `actm_contact_rule_flag` tinyint(1) NOT NULL,
  `actm_disp_seq` smallint(6) NOT NULL,
  `actm_cre_user` int(11) NOT NULL,
  `actm_upd_user` int(11) DEFAULT NULL,
  `actm_cre_dtim` datetime NOT NULL,
  `actm_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`actm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin_role`
--

DROP TABLE IF EXISTS `admin_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admin_role` (
  `ar_id` int(11) NOT NULL AUTO_INCREMENT,
  `ar_code` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `ar_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `ar_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `ar_cre_user` int(11) NOT NULL,
  `ar_upd_user` int(11) DEFAULT NULL,
  `ar_cre_dtim` datetime NOT NULL,
  `ar_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`ar_id`),
  UNIQUE KEY `ar_code` (`ar_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_key`
--

DROP TABLE IF EXISTS `api_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `api_key` (
  `ak_id` int(11) NOT NULL AUTO_INCREMENT,
  `ak_key` varchar(32) NOT NULL,
  `ak_approved` tinyint(1) DEFAULT '0',
  `ak_email` varchar(255) NOT NULL,
  `ak_contact` varchar(255) NOT NULL,
  `ak_cre_dtim` datetime NOT NULL,
  `ak_upd_dtim` datetime NOT NULL,
  PRIMARY KEY (`ak_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_stat`
--

DROP TABLE IF EXISTS `api_stat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `api_stat` (
  `as_id` int(11) NOT NULL AUTO_INCREMENT,
  `as_ak_id` int(11) NOT NULL,
  `as_ip_addr` varchar(16) NOT NULL,
  `as_cre_dtim` datetime NOT NULL,
  PRIMARY KEY (`as_id`),
  KEY `api_stat_api_key_fk` (`as_ak_id`),
  CONSTRAINT `api_stat_api_key_fk` FOREIGN KEY (`as_ak_id`) REFERENCES `api_key` (`ak_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bin`
--

DROP TABLE IF EXISTS `bin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bin` (
  `bin_id` int(11) NOT NULL AUTO_INCREMENT,
  `bin_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `bin_user_id` int(11) NOT NULL,
  `bin_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `bin_desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bin_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'S',
  `bin_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `bin_shared_flag` tinyint(1) NOT NULL DEFAULT '0',
  `bin_cre_user` int(11) NOT NULL,
  `bin_upd_user` int(11) DEFAULT NULL,
  `bin_cre_dtim` datetime NOT NULL,
  `bin_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`bin_id`),
  UNIQUE KEY `bin_uuid` (`bin_uuid`),
  KEY `bin_user_id_idx` (`bin_user_id`),
  CONSTRAINT `bin_bin_user_id_user_user_id` FOREIGN KEY (`bin_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bin_source`
--

DROP TABLE IF EXISTS `bin_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bin_source` (
  `bsrc_src_id` int(11) NOT NULL DEFAULT '0',
  `bsrc_bin_id` int(11) NOT NULL DEFAULT '0',
  `bsrc_notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bsrc_meta` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bsrc_cre_dtim` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bsrc_src_id`,`bsrc_bin_id`),
  KEY `bin_source_bsrc_bin_id_bin_bin_id` (`bsrc_bin_id`),
  CONSTRAINT `bin_source_bsrc_bin_id_bin_bin_id` FOREIGN KEY (`bsrc_bin_id`) REFERENCES `bin` (`bin_id`) ON DELETE CASCADE,
  CONSTRAINT `bin_source_bsrc_src_id_source_src_id` FOREIGN KEY (`bsrc_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_source_stale_insert
after insert on bin_source
for each row
insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrc_src_id,'S',now())
on duplicate key update str_upd_dtim=now() */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_source_stale_update
after update on bin_source
for each row 
insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrc_src_id,'S',now())
on duplicate key update str_upd_dtim=now() */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_source_stale_delete
after delete on bin_source
for each row 
insert into stale_record (str_xid,str_type,str_upd_dtim) values (old.bsrc_src_id,'S',now())
on duplicate key update str_upd_dtim=now() */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `bin_src_response_set`
--

DROP TABLE IF EXISTS `bin_src_response_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bin_src_response_set` (
  `bsrs_bin_id` int(11) NOT NULL DEFAULT '0',
  `bsrs_srs_id` int(11) NOT NULL DEFAULT '0',
  `bsrs_inq_id` int(11) NOT NULL,
  `bsrs_src_id` int(11) NOT NULL,
  `bsrs_cre_dtim` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bsrs_bin_id`,`bsrs_srs_id`),
  KEY `bsrs_inq_id_idx` (`bsrs_inq_id`),
  KEY `bsrs_src_id_idx` (`bsrs_src_id`),
  KEY `bin_src_response_set_bsrs_srs_id_src_response_set_srs_id` (`bsrs_srs_id`),
  CONSTRAINT `bin_src_response_set_bsrs_bin_id_bin_bin_id` FOREIGN KEY (`bsrs_bin_id`) REFERENCES `bin` (`bin_id`) ON DELETE CASCADE,
  CONSTRAINT `bin_src_response_set_bsrs_inq_id_inquiry_inq_id` FOREIGN KEY (`bsrs_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `bin_src_response_set_bsrs_src_id_source_src_id` FOREIGN KEY (`bsrs_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE,
  CONSTRAINT `bin_src_response_set_bsrs_srs_id_src_response_set_srs_id` FOREIGN KEY (`bsrs_srs_id`) REFERENCES `src_response_set` (`srs_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_src_response_set_stale_insert
after insert on bin_src_response_set
for each row begin
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrs_src_id,'S',now())
        on duplicate key update str_upd_dtim=now();
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrs_srs_id,'R',now())
        on duplicate key update str_upd_dtim=now();
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_src_response_set_stale_update
after update on bin_src_response_set
for each row begin
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrs_src_id,'S',now())
        on duplicate key update str_upd_dtim=now();
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (new.bsrs_srs_id,'R',now())
        on duplicate key update str_upd_dtim=now();
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 trigger trigger_bin_src_response_set_stale_delete
after delete on bin_src_response_set
for each row begin
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (old.bsrs_src_id,'S',now())
        on duplicate key update str_upd_dtim=now();
    insert into stale_record (str_xid,str_type,str_upd_dtim) values (old.bsrs_srs_id,'R',now())
        on duplicate key update str_upd_dtim=now();
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `code_master`
--

DROP TABLE IF EXISTS `code_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `code_master` (
  `cm_id` int(11) NOT NULL AUTO_INCREMENT,
  `cm_field_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `cm_code` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `cm_table_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `cm_disp_value` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cm_disp_seq` smallint(6) NOT NULL DEFAULT '10',
  `cm_area` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cm_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `cm_cre_user` int(11) NOT NULL,
  `cm_upd_user` int(11) DEFAULT NULL,
  `cm_cre_dtim` datetime NOT NULL,
  `cm_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`cm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `country` (
  `cntry_id` int(11) NOT NULL AUTO_INCREMENT,
  `cntry_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `cntry_code` char(2) COLLATE utf8_unicode_ci NOT NULL,
  `cntry_disp_seq` smallint(6) NOT NULL,
  PRIMARY KEY (`cntry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dezi_stats`
--

DROP TABLE IF EXISTS `dezi_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dezi_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tstamp` int(11) DEFAULT NULL,
  `q` text,
  `build_time` float DEFAULT NULL,
  `search_time` float DEFAULT NULL,
  `remote_user` text,
  `path` varchar(255) DEFAULT NULL,
  `s` text,
  `o` int(11) DEFAULT NULL,
  `p` int(11) DEFAULT NULL,
  `h` int(11) DEFAULT NULL,
  `c` int(11) DEFAULT NULL,
  `L` text,
  `f` int(11) DEFAULT NULL,
  `r` int(11) DEFAULT NULL,
  `t` varchar(128) DEFAULT NULL,
  `b` varchar(32) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `email`
--

DROP TABLE IF EXISTS `email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email` (
  `email_id` int(11) NOT NULL AUTO_INCREMENT,
  `email_org_id` int(11) NOT NULL,
  `email_usig_id` int(11) DEFAULT NULL,
  `email_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `email_campaign_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `email_from_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email_from_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email_subject_line` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email_headline` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email_body` text COLLATE utf8_unicode_ci,
  `email_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'O',
  `email_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'D',
  `email_cre_user` int(11) NOT NULL,
  `email_upd_user` int(11) DEFAULT NULL,
  `email_cre_dtim` datetime NOT NULL,
  `email_upd_dtim` datetime DEFAULT NULL,
  `email_schedule_dtim` datetime DEFAULT NULL,
  `email_report` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`email_id`),
  UNIQUE KEY `email_uuid` (`email_uuid`),
  KEY `email_org_id_idx` (`email_org_id`),
  KEY `email_usig_id_idx` (`email_usig_id`),
  CONSTRAINT `email_email_org_id_organization_org_id` FOREIGN KEY (`email_org_id`) REFERENCES `organization` (`org_id`),
  CONSTRAINT `email_email_usig_id_user_signature_usig_id` FOREIGN KEY (`email_usig_id`) REFERENCES `user_signature` (`usig_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `email_inquiry`
--

DROP TABLE IF EXISTS `email_inquiry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email_inquiry` (
  `einq_email_id` int(11) NOT NULL DEFAULT '0',
  `einq_inq_id` int(11) NOT NULL DEFAULT '0',
  `einq_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `einq_cre_user` int(11) NOT NULL,
  `einq_upd_user` int(11) DEFAULT NULL,
  `einq_cre_dtim` datetime NOT NULL,
  `einq_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`einq_email_id`,`einq_inq_id`),
  KEY `email_inquiry_einq_inq_id_inquiry_inq_id` (`einq_inq_id`),
  CONSTRAINT `email_inquiry_einq_email_id_email_email_id` FOREIGN KEY (`einq_email_id`) REFERENCES `email` (`email_id`) ON DELETE CASCADE,
  CONSTRAINT `email_inquiry_einq_inq_id_inquiry_inq_id` FOREIGN KEY (`einq_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fact`
--

DROP TABLE IF EXISTS `fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fact` (
  `fact_id` int(11) NOT NULL AUTO_INCREMENT,
  `fact_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `fact_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `fact_identifier` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `fact_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `fact_cre_user` int(11) NOT NULL,
  `fact_upd_user` int(11) DEFAULT NULL,
  `fact_cre_dtim` datetime NOT NULL,
  `fact_upd_dtim` datetime DEFAULT NULL,
  `fact_fv_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`fact_id`),
  UNIQUE KEY `fact_uuid` (`fact_uuid`),
  UNIQUE KEY `fact_identifier` (`fact_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fact_value`
--

DROP TABLE IF EXISTS `fact_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fact_value` (
  `fv_id` int(11) NOT NULL AUTO_INCREMENT,
  `fv_fact_id` int(11) NOT NULL,
  `fv_parent_fv_id` int(11) DEFAULT NULL,
  `fv_seq` smallint(6) NOT NULL DEFAULT '10',
  `fv_value` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `fv_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `fv_cre_user` int(11) NOT NULL,
  `fv_upd_user` int(11) DEFAULT NULL,
  `fv_cre_dtim` datetime NOT NULL,
  `fv_upd_dtim` datetime DEFAULT NULL,
  `fv_loc_id` int(11) NOT NULL DEFAULT '52',
  PRIMARY KEY (`fv_id`),
  UNIQUE KEY `fv_uniq_idx` (`fv_fact_id`,`fv_value`,`fv_loc_id`),
  KEY `fv_fact_id_idx` (`fv_fact_id`),
  KEY `fact_value_fv_loc_id_locale_loc_id` (`fv_loc_id`),
  CONSTRAINT `fact_value_fv_fact_id_fact_fact_id` FOREIGN KEY (`fv_fact_id`) REFERENCES `fact` (`fact_id`),
  CONSTRAINT `fact_value_fv_loc_id_locale_loc_id` FOREIGN KEY (`fv_loc_id`) REFERENCES `locale` (`loc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `geo_lookup`
--

DROP TABLE IF EXISTS `geo_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `geo_lookup` (
  `zip_code` varchar(16) NOT NULL,
  `state` varchar(128) NOT NULL,
  `city` varchar(255) DEFAULT NULL,
  `county` varchar(128) DEFAULT NULL,
  `latitude` float(10,6) DEFAULT NULL,
  `longitude` float(10,6) DEFAULT NULL,
  `population` int(11) DEFAULT NULL,
  PRIMARY KEY (`zip_code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `image`
--

DROP TABLE IF EXISTS `image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `image` (
  `img_id` int(11) NOT NULL AUTO_INCREMENT,
  `img_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `img_xid` int(11) NOT NULL,
  `img_ref_type` varchar(1) COLLATE utf8_unicode_ci NOT NULL,
  `img_file_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `img_file_size` int(11) DEFAULT NULL,
  `img_content_type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `img_dtim` datetime DEFAULT NULL,
  `img_cre_user` int(11) NOT NULL,
  `img_upd_user` int(11) DEFAULT NULL,
  `img_cre_dtim` datetime NOT NULL,
  `img_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`img_id`),
  UNIQUE KEY `img_uuid` (`img_uuid`),
  KEY `image_img_ref_type_idx` (`img_ref_type`),
  KEY `image_img_xid_idx` (`img_xid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inq_org`
--

DROP TABLE IF EXISTS `inq_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inq_org` (
  `iorg_inq_id` int(11) NOT NULL DEFAULT '0',
  `iorg_org_id` int(11) NOT NULL DEFAULT '0',
  `iorg_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `iorg_cre_user` int(11) NOT NULL,
  `iorg_upd_user` int(11) DEFAULT NULL,
  `iorg_cre_dtim` datetime NOT NULL,
  `iorg_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`iorg_inq_id`,`iorg_org_id`),
  KEY `inq_org_iorg_org_id_organization_org_id` (`iorg_org_id`),
  CONSTRAINT `inq_org_iorg_inq_id_inquiry_inq_id` FOREIGN KEY (`iorg_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `inq_org_iorg_org_id_organization_org_id` FOREIGN KEY (`iorg_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inq_outcome`
--

DROP TABLE IF EXISTS `inq_outcome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inq_outcome` (
  `iout_inq_id` int(11) NOT NULL DEFAULT '0',
  `iout_out_id` int(11) NOT NULL DEFAULT '0',
  `iout_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `iout_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `iout_notes` text COLLATE utf8_unicode_ci,
  `iout_cre_user` int(11) NOT NULL,
  `iout_upd_user` int(11) DEFAULT NULL,
  `iout_cre_dtim` datetime NOT NULL,
  `iout_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`iout_inq_id`,`iout_out_id`),
  KEY `inq_outcome_iout_out_id_outcome_out_id` (`iout_out_id`),
  CONSTRAINT `inq_outcome_iout_inq_id_inquiry_inq_id` FOREIGN KEY (`iout_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `inq_outcome_iout_out_id_outcome_out_id` FOREIGN KEY (`iout_out_id`) REFERENCES `outcome` (`out_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inquiry`
--

DROP TABLE IF EXISTS `inquiry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inquiry` (
  `inq_id` int(11) NOT NULL AUTO_INCREMENT,
  `inq_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `inq_title` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `inq_ext_title` text COLLATE utf8_unicode_ci,
  `inq_publish_dtim` datetime DEFAULT NULL,
  `inq_deadline_dtim` datetime DEFAULT NULL,
  `inq_desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `inq_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'F',
  `inq_xid` int(11) DEFAULT NULL,
  `inq_loc_id` int(11) NOT NULL DEFAULT '52',
  `inq_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `inq_expire_msg` text COLLATE utf8_unicode_ci,
  `inq_expire_dtim` datetime DEFAULT NULL,
  `inq_cre_user` int(11) NOT NULL,
  `inq_upd_user` int(11) DEFAULT NULL,
  `inq_cre_dtim` datetime NOT NULL,
  `inq_upd_dtim` datetime DEFAULT NULL,
  `inq_ending_para` text COLLATE utf8_unicode_ci,
  `inq_rss_intro` text COLLATE utf8_unicode_ci,
  `inq_intro_para` text COLLATE utf8_unicode_ci,
  `inq_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `inq_stale_flag` tinyint(1) NOT NULL DEFAULT '1',
  `inq_tpl_opts` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `inq_deadline_msg` text COLLATE utf8_unicode_ci,
  `inq_confirm_msg` text COLLATE utf8_unicode_ci,
  `inq_cache_user` int(11) DEFAULT NULL,
  `inq_cache_dtim` datetime DEFAULT NULL,
  `inq_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  `inq_rss_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'N',
  PRIMARY KEY (`inq_id`),
  UNIQUE KEY `inq_uuid` (`inq_uuid`),
  KEY `inq_loc_id_idx` (`inq_loc_id`),
  KEY `inq_public_flag_idx` (`inq_public_flag`),
  CONSTRAINT `inquiry_inq_loc_id_locale_loc_id` FOREIGN KEY (`inq_loc_id`) REFERENCES `locale` (`loc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inquiry_activity`
--

DROP TABLE IF EXISTS `inquiry_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inquiry_activity` (
  `ia_id` int(11) NOT NULL AUTO_INCREMENT,
  `ia_actm_id` int(11) NOT NULL,
  `ia_inq_id` int(11) NOT NULL,
  `ia_dtim` datetime NOT NULL,
  `ia_desc` varchar(255) DEFAULT NULL,
  `ia_notes` text,
  `ia_cre_user` int(11) NOT NULL,
  `ia_cre_dtim` datetime NOT NULL,
  `ia_upd_user` int(11) NOT NULL,
  `ia_upd_dtim` datetime NOT NULL,
  PRIMARY KEY (`ia_id`),
  KEY `inquiry_activity_actm_fk` (`ia_actm_id`),
  KEY `inquiry_activity_inq_fk` (`ia_inq_id`),
  CONSTRAINT `inquiry_activity_actm_fk` FOREIGN KEY (`ia_actm_id`) REFERENCES `activity_master` (`actm_id`) ON DELETE CASCADE,
  CONSTRAINT `inquiry_activity_inq_fk` FOREIGN KEY (`ia_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inquiry_annotation`
--

DROP TABLE IF EXISTS `inquiry_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inquiry_annotation` (
  `inqan_id` int(11) NOT NULL AUTO_INCREMENT,
  `inqan_inq_id` int(11) NOT NULL,
  `inqan_value` text COLLATE utf8_unicode_ci,
  `inqan_cre_user` int(11) NOT NULL,
  `inqan_upd_user` int(11) DEFAULT NULL,
  `inqan_cre_dtim` datetime NOT NULL,
  `inqan_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`inqan_id`),
  KEY `inqan_inq_id_idx` (`inqan_inq_id`),
  CONSTRAINT `inquiry_annotation_inqan_inq_id_inquiry_inq_id` FOREIGN KEY (`inqan_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inquiry_user`
--

DROP TABLE IF EXISTS `inquiry_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inquiry_user` (
  `iu_id` int(11) NOT NULL AUTO_INCREMENT,
  `iu_type` char(1) NOT NULL DEFAULT 'W',
  `iu_status` char(1) NOT NULL DEFAULT 'A',
  `iu_inq_id` int(11) NOT NULL,
  `iu_user_id` int(11) DEFAULT NULL,
  `iu_cre_user` int(11) NOT NULL,
  `iu_cre_dtim` datetime NOT NULL,
  `iu_upd_user` int(11) NOT NULL,
  `iu_upd_dtim` datetime NOT NULL,
  PRIMARY KEY (`iu_id`),
  KEY `inquiry_user_user_fk` (`iu_user_id`),
  KEY `inquiry_user_idx` (`iu_inq_id`,`iu_user_id`,`iu_type`),
  CONSTRAINT `inquiry_user_inq_fk` FOREIGN KEY (`iu_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `inquiry_user_user_fk` FOREIGN KEY (`iu_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `iptc_master`
--

DROP TABLE IF EXISTS `iptc_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `iptc_master` (
  `iptc_id` int(11) NOT NULL AUTO_INCREMENT,
  `iptc_concept_code` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `iptc_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `iptc_cre_user` int(11) NOT NULL,
  `iptc_upd_user` int(11) DEFAULT NULL,
  `iptc_cre_dtim` datetime NOT NULL,
  `iptc_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`iptc_id`),
  UNIQUE KEY `iptc_name` (`iptc_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `job_queue`
--

DROP TABLE IF EXISTS `job_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_queue` (
  `jq_id` int(11) NOT NULL AUTO_INCREMENT,
  `jq_job` text COLLATE utf8_unicode_ci NOT NULL,
  `jq_pid` int(11) DEFAULT NULL,
  `jq_host` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `jq_error_msg` text COLLATE utf8_unicode_ci,
  `jq_cre_user` int(11) NOT NULL,
  `jq_cre_dtim` datetime NOT NULL,
  `jq_start_dtim` datetime DEFAULT NULL,
  `jq_complete_dtim` datetime DEFAULT NULL,
  `jq_start_after_dtim` datetime DEFAULT NULL,
  `jq_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `jq_xid` int(11) DEFAULT NULL,
  PRIMARY KEY (`jq_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `locale`
--

DROP TABLE IF EXISTS `locale`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locale` (
  `loc_id` int(11) NOT NULL AUTO_INCREMENT,
  `loc_key` char(5) COLLATE utf8_unicode_ci NOT NULL,
  `loc_lang` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `loc_region` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`loc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `org_sys_id`
--

DROP TABLE IF EXISTS `org_sys_id`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `org_sys_id` (
  `osid_id` int(11) NOT NULL AUTO_INCREMENT,
  `osid_org_id` int(11) NOT NULL,
  `osid_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `osid_xuuid` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `osid_cre_user` int(11) NOT NULL,
  `osid_upd_user` int(11) DEFAULT NULL,
  `osid_cre_dtim` datetime NOT NULL,
  `osid_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`osid_id`),
  KEY `osid_org_id_idx` (`osid_org_id`),
  CONSTRAINT `org_sys_id_osid_org_id_organization_org_id` FOREIGN KEY (`osid_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `org_uri`
--

DROP TABLE IF EXISTS `org_uri`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `org_uri` (
  `ouri_id` int(11) NOT NULL AUTO_INCREMENT,
  `ouri_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `ouri_org_id` int(11) NOT NULL,
  `ouri_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `ouri_value` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `ouri_feed` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ouri_upd_int` int(11) DEFAULT NULL,
  `ouri_handle` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ouri_id`),
  UNIQUE KEY `ouri_uuid` (`ouri_uuid`),
  KEY `ouri_org_id_idx` (`ouri_org_id`),
  CONSTRAINT `org_uri_ouri_org_id_organization_org_id` FOREIGN KEY (`ouri_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `organization`
--

DROP TABLE IF EXISTS `organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organization` (
  `org_id` int(11) NOT NULL AUTO_INCREMENT,
  `org_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `org_name` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `org_logo_uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_display_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_parent_id` int(11) DEFAULT NULL,
  `org_default_prj_id` int(11) NOT NULL DEFAULT '1',
  `org_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'N',
  `org_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `org_max_users` int(11) DEFAULT '0',
  `org_html_color` char(6) COLLATE utf8_unicode_ci NOT NULL DEFAULT '000000',
  `org_cre_user` int(11) NOT NULL,
  `org_upd_user` int(11) DEFAULT NULL,
  `org_cre_dtim` datetime NOT NULL,
  `org_upd_dtim` datetime DEFAULT NULL,
  `org_summary` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_desc` text COLLATE utf8_unicode_ci,
  `org_city` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_state` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_site_uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_welcome_msg` text COLLATE utf8_unicode_ci,
  `org_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_zip` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `org_suppress_welcome_email_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`org_id`),
  UNIQUE KEY `org_uuid` (`org_uuid`),
  UNIQUE KEY `org_name` (`org_name`),
  KEY `org_default_prj_id_idx` (`org_default_prj_id`),
  KEY `org_parent_id_idx` (`org_parent_id`),
  CONSTRAINT `organization_org_default_prj_id_project_prj_id` FOREIGN KEY (`org_default_prj_id`) REFERENCES `project` (`prj_id`),
  CONSTRAINT `organization_org_parent_id_organization_org_id` FOREIGN KEY (`org_parent_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `out_annotation`
--

DROP TABLE IF EXISTS `out_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `out_annotation` (
  `oa_id` int(11) NOT NULL AUTO_INCREMENT,
  `oa_out_id` int(11) NOT NULL DEFAULT '1',
  `oa_value` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `oa_cre_user` int(11) NOT NULL,
  `oa_upd_user` int(11) DEFAULT NULL,
  `oa_cre_dtim` datetime NOT NULL,
  `oa_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`oa_id`),
  KEY `oa_out_id_idx` (`oa_out_id`),
  CONSTRAINT `out_annotation_oa_out_id_outcome_out_id` FOREIGN KEY (`oa_out_id`) REFERENCES `outcome` (`out_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `outcome`
--

DROP TABLE IF EXISTS `outcome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `outcome` (
  `out_id` int(11) NOT NULL AUTO_INCREMENT,
  `out_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `out_org_id` int(11) NOT NULL DEFAULT '1',
  `out_headline` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `out_internal_headline` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `out_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `out_teaser` text COLLATE utf8_unicode_ci NOT NULL,
  `out_internal_teaser` text COLLATE utf8_unicode_ci,
  `out_show` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `out_survey` text COLLATE utf8_unicode_ci,
  `out_dtim` text COLLATE utf8_unicode_ci NOT NULL,
  `out_meta` text COLLATE utf8_unicode_ci,
  `out_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'S',
  `out_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `out_cre_user` int(11) NOT NULL,
  `out_upd_user` int(11) DEFAULT NULL,
  `out_cre_dtim` datetime NOT NULL,
  `out_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`out_id`),
  UNIQUE KEY `out_uuid` (`out_uuid`),
  KEY `out_org_id_idx` (`out_org_id`),
  CONSTRAINT `outcome_out_org_id_organization_org_id` FOREIGN KEY (`out_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_reset`
--

DROP TABLE IF EXISTS `password_reset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_reset` (
  `pwr_uuid` char(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `pwr_expiration_dtim` datetime NOT NULL,
  `pwr_user_id` int(11) NOT NULL,
  PRIMARY KEY (`pwr_uuid`),
  KEY `pwr_user_id_idx` (`pwr_user_id`),
  CONSTRAINT `password_reset_pwr_user_id_user_user_id` FOREIGN KEY (`pwr_user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preference_type`
--

DROP TABLE IF EXISTS `preference_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preference_type` (
  `pt_id` int(11) NOT NULL AUTO_INCREMENT,
  `pt_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `pt_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `pt_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `pt_cre_user` int(11) NOT NULL,
  `pt_upd_user` int(11) DEFAULT NULL,
  `pt_cre_dtim` datetime NOT NULL,
  `pt_upd_dtim` datetime DEFAULT NULL,
  `pt_identifier` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`pt_id`),
  UNIQUE KEY `pt_uuid` (`pt_uuid`),
  UNIQUE KEY `preference_type_pt_identifier_idx` (`pt_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preference_type_value`
--

DROP TABLE IF EXISTS `preference_type_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preference_type_value` (
  `ptv_id` int(11) NOT NULL AUTO_INCREMENT,
  `ptv_pt_id` int(11) NOT NULL,
  `ptv_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `ptv_seq` smallint(6) NOT NULL DEFAULT '10',
  `ptv_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ptv_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `ptv_cre_user` int(11) NOT NULL,
  `ptv_upd_user` int(11) DEFAULT NULL,
  `ptv_cre_dtim` datetime NOT NULL,
  `ptv_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`ptv_id`),
  UNIQUE KEY `ptv_uuid` (`ptv_uuid`),
  KEY `ptv_pt_id_idx` (`ptv_pt_id`),
  CONSTRAINT `preference_type_value_ptv_pt_id_preference_type_pt_id` FOREIGN KEY (`ptv_pt_id`) REFERENCES `preference_type` (`pt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `prj_outcome`
--

DROP TABLE IF EXISTS `prj_outcome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `prj_outcome` (
  `pout_prj_id` int(11) NOT NULL DEFAULT '0',
  `pout_out_id` int(11) NOT NULL DEFAULT '0',
  `pout_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `pout_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `pout_notes` text COLLATE utf8_unicode_ci,
  `pout_cre_user` int(11) NOT NULL,
  `pout_upd_user` int(11) DEFAULT NULL,
  `pout_cre_dtim` datetime NOT NULL,
  `pout_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`pout_prj_id`,`pout_out_id`),
  KEY `prj_outcome_pout_out_id_outcome_out_id` (`pout_out_id`),
  CONSTRAINT `prj_outcome_pout_out_id_outcome_out_id` FOREIGN KEY (`pout_out_id`) REFERENCES `outcome` (`out_id`) ON DELETE CASCADE,
  CONSTRAINT `prj_outcome_pout_prj_id_project_prj_id` FOREIGN KEY (`pout_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `profile_map`
--

DROP TABLE IF EXISTS `profile_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `profile_map` (
  `pmap_id` int(11) NOT NULL AUTO_INCREMENT,
  `pmap_name` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `pmap_display_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `pmap_meta` text COLLATE utf8_unicode_ci,
  `pmap_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `pmap_cre_user` int(11) NOT NULL,
  `pmap_upd_user` int(11) DEFAULT NULL,
  `pmap_cre_dtim` datetime NOT NULL,
  `pmap_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`pmap_id`),
  UNIQUE KEY `pmap_name` (`pmap_name`),
  UNIQUE KEY `pmap_display_name` (`pmap_display_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project`
--

DROP TABLE IF EXISTS `project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project` (
  `prj_id` int(11) NOT NULL AUTO_INCREMENT,
  `prj_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `prj_name` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `prj_display_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `prj_desc` text COLLATE utf8_unicode_ci,
  `prj_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `prj_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `prj_cre_user` int(11) NOT NULL,
  `prj_upd_user` int(11) DEFAULT NULL,
  `prj_cre_dtim` datetime NOT NULL,
  `prj_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`prj_id`),
  UNIQUE KEY `prj_uuid` (`prj_uuid`),
  UNIQUE KEY `prj_name` (`prj_name`),
  UNIQUE KEY `prj_display_name` (`prj_display_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_activity`
--

DROP TABLE IF EXISTS `project_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_activity` (
  `pa_id` int(11) NOT NULL AUTO_INCREMENT,
  `pa_actm_id` int(11) NOT NULL,
  `pa_prj_id` int(11) NOT NULL,
  `pa_dtim` datetime NOT NULL,
  `pa_desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pa_notes` text COLLATE utf8_unicode_ci,
  `pa_cre_user` int(11) NOT NULL,
  `pa_upd_user` int(11) DEFAULT NULL,
  `pa_cre_dtim` datetime NOT NULL,
  `pa_upd_dtim` datetime DEFAULT NULL,
  `pa_xid` int(11) DEFAULT NULL,
  `pa_ref_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`pa_id`),
  KEY `pa_prj_id_idx` (`pa_prj_id`),
  KEY `pa_actm_id_idx` (`pa_actm_id`),
  CONSTRAINT `project_activity_pa_actm_id_activity_master_actm_id` FOREIGN KEY (`pa_actm_id`) REFERENCES `activity_master` (`actm_id`) ON DELETE CASCADE,
  CONSTRAINT `project_activity_pa_prj_id_project_prj_id` FOREIGN KEY (`pa_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_annotation`
--

DROP TABLE IF EXISTS `project_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_annotation` (
  `prjan_id` int(11) NOT NULL AUTO_INCREMENT,
  `prjan_prj_id` int(11) NOT NULL,
  `prjan_value` text COLLATE utf8_unicode_ci,
  `prjan_cre_user` int(11) NOT NULL,
  `prjan_upd_user` int(11) DEFAULT NULL,
  `prjan_cre_dtim` datetime NOT NULL,
  `prjan_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`prjan_id`),
  KEY `prjan_prj_id_idx` (`prjan_prj_id`),
  CONSTRAINT `project_annotation_prjan_prj_id_project_prj_id` FOREIGN KEY (`prjan_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_inquiry`
--

DROP TABLE IF EXISTS `project_inquiry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_inquiry` (
  `pinq_prj_id` int(11) NOT NULL DEFAULT '0',
  `pinq_inq_id` int(11) NOT NULL DEFAULT '0',
  `pinq_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `pinq_cre_user` int(11) NOT NULL,
  `pinq_upd_user` int(11) DEFAULT NULL,
  `pinq_cre_dtim` datetime NOT NULL,
  `pinq_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`pinq_prj_id`,`pinq_inq_id`),
  KEY `project_inquiry_pinq_inq_id_inquiry_inq_id` (`pinq_inq_id`),
  CONSTRAINT `project_inquiry_pinq_inq_id_inquiry_inq_id` FOREIGN KEY (`pinq_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `project_inquiry_pinq_prj_id_project_prj_id` FOREIGN KEY (`pinq_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_message`
--

DROP TABLE IF EXISTS `project_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_message` (
  `pm_id` int(11) NOT NULL AUTO_INCREMENT,
  `pm_pj_id` int(11) NOT NULL,
  `pm_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `pm_channel` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `pm_channel_xid` int(11) DEFAULT NULL,
  `pm_cre_user` int(11) NOT NULL,
  `pm_upd_user` int(11) DEFAULT NULL,
  `pm_cre_dtim` datetime NOT NULL,
  `pm_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`pm_id`),
  KEY `pm_pj_id_idx` (`pm_pj_id`),
  CONSTRAINT `project_message_pm_pj_id_project_prj_id` FOREIGN KEY (`pm_pj_id`) REFERENCES `project` (`prj_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_org`
--

DROP TABLE IF EXISTS `project_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_org` (
  `porg_prj_id` int(11) NOT NULL DEFAULT '0',
  `porg_org_id` int(11) NOT NULL DEFAULT '0',
  `porg_contact_user_id` int(11) NOT NULL,
  `porg_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `porg_cre_user` int(11) NOT NULL,
  `porg_upd_user` int(11) DEFAULT NULL,
  `porg_cre_dtim` datetime NOT NULL,
  `porg_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`porg_prj_id`,`porg_org_id`),
  KEY `porg_contact_user_id_idx` (`porg_contact_user_id`),
  KEY `project_org_porg_org_id_organization_org_id` (`porg_org_id`),
  CONSTRAINT `project_org_porg_contact_user_id_user_user_id` FOREIGN KEY (`porg_contact_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `project_org_porg_org_id_organization_org_id` FOREIGN KEY (`porg_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `project_org_porg_prj_id_project_prj_id` FOREIGN KEY (`porg_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_saved_search`
--

DROP TABLE IF EXISTS `project_saved_search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_saved_search` (
  `pss_prj_id` int(11) NOT NULL DEFAULT '0',
  `pss_ssearch_id` int(11) NOT NULL DEFAULT '0',
  `pss_cre_user` int(11) NOT NULL,
  `pss_upd_user` int(11) DEFAULT NULL,
  `pss_cre_dtim` datetime NOT NULL,
  `pss_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`pss_prj_id`,`pss_ssearch_id`),
  KEY `project_saved_search_pss_ssearch_id_saved_search_ssearch_id` (`pss_ssearch_id`),
  CONSTRAINT `project_saved_search_pss_prj_id_project_prj_id` FOREIGN KEY (`pss_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE,
  CONSTRAINT `project_saved_search_pss_ssearch_id_saved_search_ssearch_id` FOREIGN KEY (`pss_ssearch_id`) REFERENCES `saved_search` (`ssearch_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `question`
--

DROP TABLE IF EXISTS `question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `question` (
  `ques_id` int(11) NOT NULL AUTO_INCREMENT,
  `ques_inq_id` int(11) NOT NULL,
  `ques_dis_seq` smallint(6) DEFAULT NULL,
  `ques_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `ques_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'T',
  `ques_value` text COLLATE utf8_unicode_ci NOT NULL,
  `ques_choices` text COLLATE utf8_unicode_ci,
  `ques_cre_user` int(11) NOT NULL,
  `ques_upd_user` int(11) DEFAULT NULL,
  `ques_cre_dtim` datetime NOT NULL,
  `ques_upd_dtim` datetime DEFAULT NULL,
  `ques_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `ques_pmap_id` int(11) DEFAULT NULL,
  `ques_locks` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ques_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  `ques_resp_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'S',
  `ques_resp_opts` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ques_template` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ques_id`),
  UNIQUE KEY `ques_uuid` (`ques_uuid`),
  KEY `ques_inq_id_idx` (`ques_inq_id`),
  KEY `ques_public_flag_idx` (`ques_public_flag`),
  CONSTRAINT `question_ques_inq_id_inquiry_inq_id` FOREIGN KEY (`ques_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `saved_search`
--

DROP TABLE IF EXISTS `saved_search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `saved_search` (
  `ssearch_id` int(11) NOT NULL AUTO_INCREMENT,
  `ssearch_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'My Search',
  `ssearch_shared_flag` tinyint(1) NOT NULL DEFAULT '0',
  `ssearch_params` text COLLATE utf8_unicode_ci NOT NULL,
  `ssearch_cre_user` int(11) NOT NULL,
  `ssearch_upd_user` int(11) DEFAULT NULL,
  `ssearch_cre_dtim` datetime NOT NULL,
  `ssearch_upd_dtim` datetime DEFAULT NULL,
  `ssearch_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`ssearch_id`),
  UNIQUE KEY `ssearch_name` (`ssearch_name`),
  UNIQUE KEY `ssearch_uuid` (`ssearch_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sma_annotation`
--

DROP TABLE IF EXISTS `sma_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sma_annotation` (
  `smaan_id` int(11) NOT NULL AUTO_INCREMENT,
  `smaan_sma_id` int(11) NOT NULL,
  `smaan_value` text COLLATE utf8_unicode_ci,
  `smaan_cre_user` int(11) NOT NULL,
  `smaan_upd_user` int(11) DEFAULT NULL,
  `smaan_cre_dtim` datetime NOT NULL,
  `smaan_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`smaan_id`),
  KEY `smaan_sma_id_idx` (`smaan_sma_id`),
  CONSTRAINT `sma_annotation_smaan_sma_id_src_media_asset_sma_id` FOREIGN KEY (`smaan_sma_id`) REFERENCES `src_media_asset` (`sma_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `source`
--

DROP TABLE IF EXISTS `source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `source` (
  `src_id` int(11) NOT NULL AUTO_INCREMENT,
  `src_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `src_username` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `src_first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_middle_initial` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_pre_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_post_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `src_has_acct` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'N',
  `src_channel` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_cre_user` int(11) NOT NULL,
  `src_upd_user` int(11) DEFAULT NULL,
  `src_cre_dtim` datetime NOT NULL,
  `src_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`src_id`),
  UNIQUE KEY `src_uuid` (`src_uuid`),
  UNIQUE KEY `src_username` (`src_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sr_annotation`
--

DROP TABLE IF EXISTS `sr_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sr_annotation` (
  `sran_id` int(11) NOT NULL AUTO_INCREMENT,
  `sran_sr_id` int(11) NOT NULL,
  `sran_value` text COLLATE utf8_unicode_ci,
  `sran_cre_user` int(11) NOT NULL,
  `sran_upd_user` int(11) DEFAULT NULL,
  `sran_cre_dtim` datetime NOT NULL,
  `sran_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sran_id`),
  KEY `sran_sr_id_idx` (`sran_sr_id`),
  CONSTRAINT `sr_annotation_sran_sr_id_src_response_sr_id` FOREIGN KEY (`sran_sr_id`) REFERENCES `src_response` (`sr_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_activity`
--

DROP TABLE IF EXISTS `src_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_activity` (
  `sact_id` int(11) NOT NULL AUTO_INCREMENT,
  `sact_actm_id` int(11) NOT NULL,
  `sact_src_id` int(11) NOT NULL,
  `sact_prj_id` int(11) DEFAULT NULL,
  `sact_dtim` datetime NOT NULL,
  `sact_desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sact_notes` text COLLATE utf8_unicode_ci,
  `sact_cre_user` int(11) NOT NULL,
  `sact_upd_user` int(11) DEFAULT NULL,
  `sact_cre_dtim` datetime NOT NULL,
  `sact_upd_dtim` datetime DEFAULT NULL,
  `sact_xid` int(11) DEFAULT NULL,
  `sact_ref_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`sact_id`),
  KEY `sact_ix_3_idx` (`sact_prj_id`,`sact_dtim`),
  KEY `sact_ix_4_idx` (`sact_upd_dtim`),
  KEY `sact_ix_5_idx` (`sact_cre_user`),
  KEY `sact_src_id_idx` (`sact_src_id`),
  KEY `sact_actm_id_idx` (`sact_actm_id`),
  KEY `sact_prj_id_idx` (`sact_prj_id`),
  CONSTRAINT `src_activity_sact_actm_id_activity_master_actm_id` FOREIGN KEY (`sact_actm_id`) REFERENCES `activity_master` (`actm_id`) ON DELETE CASCADE,
  CONSTRAINT `src_activity_sact_prj_id_project_prj_id` FOREIGN KEY (`sact_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE,
  CONSTRAINT `src_activity_sact_src_id_source_src_id` FOREIGN KEY (`sact_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_alias`
--

DROP TABLE IF EXISTS `src_alias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_alias` (
  `sa_id` int(11) NOT NULL AUTO_INCREMENT,
  `sa_src_id` int(11) NOT NULL,
  `sa_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sa_first_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sa_last_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sa_post_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sa_cre_user` int(11) NOT NULL,
  `sa_upd_user` int(11) DEFAULT NULL,
  `sa_cre_dtim` datetime NOT NULL,
  `sa_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sa_id`),
  KEY `sa_src_id_idx` (`sa_src_id`),
  CONSTRAINT `src_alias_sa_src_id_source_src_id` FOREIGN KEY (`sa_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_annotation`
--

DROP TABLE IF EXISTS `src_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_annotation` (
  `srcan_id` int(11) NOT NULL AUTO_INCREMENT,
  `srcan_src_id` int(11) NOT NULL,
  `srcan_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'S',
  `srcan_value` text COLLATE utf8_unicode_ci,
  `srcan_cre_user` int(11) NOT NULL,
  `srcan_upd_user` int(11) DEFAULT NULL,
  `srcan_cre_dtim` datetime NOT NULL,
  `srcan_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`srcan_id`),
  KEY `srcan_src_id_idx` (`srcan_src_id`),
  CONSTRAINT `src_annotation_srcan_src_id_source_src_id` FOREIGN KEY (`srcan_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_email`
--

DROP TABLE IF EXISTS `src_email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_email` (
  `sem_id` int(11) NOT NULL AUTO_INCREMENT,
  `sem_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sem_src_id` int(11) NOT NULL,
  `sem_primary_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sem_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sem_email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `sem_effective_date` date DEFAULT NULL,
  `sem_expire_date` date DEFAULT NULL,
  `sem_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'G',
  `sem_cre_user` int(11) NOT NULL,
  `sem_upd_user` int(11) DEFAULT NULL,
  `sem_cre_dtim` datetime NOT NULL,
  `sem_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sem_id`),
  UNIQUE KEY `sem_uuid` (`sem_uuid`),
  UNIQUE KEY `sem_email` (`sem_email`),
  KEY `sem_src_id_idx` (`sem_src_id`),
  CONSTRAINT `src_email_sem_src_id_source_src_id` FOREIGN KEY (`sem_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_export`
--

DROP TABLE IF EXISTS `src_export`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_export` (
  `se_id` int(11) NOT NULL AUTO_INCREMENT,
  `se_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `se_prj_id` int(11) DEFAULT NULL,
  `se_inq_id` int(11) DEFAULT NULL,
  `se_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `se_cre_user` int(11) NOT NULL,
  `se_upd_user` int(11) DEFAULT NULL,
  `se_cre_dtim` datetime NOT NULL,
  `se_upd_dtim` datetime DEFAULT NULL,
  `se_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'L',
  `se_notes` text COLLATE utf8_unicode_ci,
  `se_xid` int(11) DEFAULT NULL,
  `se_ref_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `se_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `se_email_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`se_id`),
  UNIQUE KEY `se_uuid` (`se_uuid`),
  KEY `se_prj_id_idx` (`se_prj_id`),
  KEY `se_inq_id_idx` (`se_inq_id`),
  CONSTRAINT `src_export_se_inq_id_inquiry_inq_id` FOREIGN KEY (`se_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `src_export_se_prj_id_project_prj_id` FOREIGN KEY (`se_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_fact`
--

DROP TABLE IF EXISTS `src_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_fact` (
  `sf_src_id` int(11) NOT NULL DEFAULT '0',
  `sf_fact_id` int(11) NOT NULL DEFAULT '0',
  `sf_fv_id` int(11) DEFAULT NULL,
  `sf_src_value` text COLLATE utf8_unicode_ci,
  `sf_src_fv_id` int(11) DEFAULT NULL,
  `sf_lock_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sf_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sf_cre_user` int(11) NOT NULL,
  `sf_upd_user` int(11) DEFAULT NULL,
  `sf_cre_dtim` datetime NOT NULL,
  `sf_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sf_src_id`,`sf_fact_id`),
  KEY `sf_fv_id_idx` (`sf_fv_id`),
  KEY `sf_src_fv_id_idx` (`sf_src_fv_id`),
  KEY `src_fact_sf_fact_id_fact_fact_id` (`sf_fact_id`),
  CONSTRAINT `src_fact_sf_fact_id_fact_fact_id` FOREIGN KEY (`sf_fact_id`) REFERENCES `fact` (`fact_id`),
  CONSTRAINT `src_fact_sf_fv_id_fact_value_fv_id` FOREIGN KEY (`sf_fv_id`) REFERENCES `fact_value` (`fv_id`),
  CONSTRAINT `src_fact_sf_src_fv_id_fact_value_fv_id` FOREIGN KEY (`sf_src_fv_id`) REFERENCES `fact_value` (`fv_id`),
  CONSTRAINT `src_fact_sf_src_id_source_src_id` FOREIGN KEY (`sf_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_inquiry`
--

DROP TABLE IF EXISTS `src_inquiry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_inquiry` (
  `si_id` int(11) NOT NULL AUTO_INCREMENT,
  `si_src_id` int(11) NOT NULL,
  `si_inq_id` int(11) NOT NULL,
  `si_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'P',
  `si_sent_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `si_cre_user` int(11) NOT NULL,
  `si_upd_user` int(11) DEFAULT NULL,
  `si_cre_dtim` datetime NOT NULL,
  `si_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`si_id`),
  KEY `si_src_id_idx` (`si_src_id`),
  KEY `si_inq_id_idx` (`si_inq_id`),
  CONSTRAINT `src_inquiry_si_inq_id_inquiry_inq_id` FOREIGN KEY (`si_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `src_inquiry_si_src_id_source_src_id` FOREIGN KEY (`si_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_mail_address`
--

DROP TABLE IF EXISTS `src_mail_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_mail_address` (
  `smadd_id` int(11) NOT NULL AUTO_INCREMENT,
  `smadd_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `smadd_src_id` int(11) NOT NULL,
  `smadd_primary_flag` tinyint(1) NOT NULL DEFAULT '0',
  `smadd_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_line_1` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_line_2` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_city` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_state` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_cntry` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_zip` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_lat` float(10,6) DEFAULT NULL,
  `smadd_long` float(10,6) DEFAULT NULL,
  `smadd_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `smadd_cre_user` int(11) NOT NULL,
  `smadd_upd_user` int(11) DEFAULT NULL,
  `smadd_cre_dtim` datetime NOT NULL,
  `smadd_upd_dtim` datetime DEFAULT NULL,
  `smadd_county` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`smadd_id`),
  UNIQUE KEY `smadd_uuid` (`smadd_uuid`),
  KEY `smadd_src_id_idx` (`smadd_src_id`),
  KEY `smadd_zip_idx` (`smadd_zip`),
  CONSTRAINT `src_mail_address_smadd_src_id_source_src_id` FOREIGN KEY (`smadd_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_media_asset`
--

DROP TABLE IF EXISTS `src_media_asset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_media_asset` (
  `sma_id` int(11) NOT NULL AUTO_INCREMENT,
  `sma_src_id` int(11) NOT NULL,
  `sma_sr_id` int(11) NOT NULL,
  `sma_file_ext` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `sma_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `sma_file_uri` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `sma_file_size` int(11) DEFAULT NULL,
  `sma_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sma_export_flag` tinyint(1) NOT NULL,
  `sma_public_flag` tinyint(1) NOT NULL,
  `sma_archive_flag` tinyint(1) NOT NULL,
  `sma_delete_flag` tinyint(1) NOT NULL,
  `sma_cre_user` int(11) NOT NULL,
  `sma_upd_user` int(11) DEFAULT NULL,
  `sma_cre_dtim` datetime NOT NULL,
  `sma_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sma_id`),
  KEY `sma_src_id_idx` (`sma_src_id`),
  CONSTRAINT `src_media_asset_sma_src_id_source_src_id` FOREIGN KEY (`sma_src_id`) REFERENCES `source` (`src_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_org`
--

DROP TABLE IF EXISTS `src_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_org` (
  `so_src_id` int(11) NOT NULL DEFAULT '0',
  `so_org_id` int(11) NOT NULL DEFAULT '0',
  `so_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `so_effective_date` date NOT NULL DEFAULT '1970-01-01',
  `so_home_flag` tinyint(1) NOT NULL DEFAULT '0',
  `so_lock_flag` tinyint(1) NOT NULL DEFAULT '0',
  `so_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `so_cre_user` int(11) NOT NULL,
  `so_upd_user` int(11) DEFAULT NULL,
  `so_cre_dtim` datetime NOT NULL,
  `so_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`so_src_id`,`so_org_id`),
  UNIQUE KEY `so_uuid` (`so_uuid`),
  KEY `src_org_so_org_id_organization_org_id` (`so_org_id`),
  CONSTRAINT `src_org_so_org_id_organization_org_id` FOREIGN KEY (`so_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `src_org_so_src_id_source_src_id` FOREIGN KEY (`so_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_org_cache`
--

DROP TABLE IF EXISTS `src_org_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_org_cache` (
  `soc_src_id` int(11) NOT NULL DEFAULT '0',
  `soc_org_id` int(11) NOT NULL DEFAULT '0',
  `soc_status` char(1) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`soc_src_id`,`soc_org_id`),
  KEY `src_org_cache_soc_org_id_organization_org_id` (`soc_org_id`),
  CONSTRAINT `src_org_cache_soc_org_id_organization_org_id` FOREIGN KEY (`soc_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `src_org_cache_soc_src_id_source_src_id` FOREIGN KEY (`soc_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_org_email`
--

DROP TABLE IF EXISTS `src_org_email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_org_email` (
  `soe_id` int(11) NOT NULL AUTO_INCREMENT,
  `soe_sem_id` int(11) NOT NULL,
  `soe_org_id` int(11) NOT NULL,
  `soe_status` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `soe_status_dtim` datetime NOT NULL,
  `soe_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'L',
  PRIMARY KEY (`soe_id`),
  UNIQUE KEY `soe_uniqueidx_1_idx` (`soe_sem_id`,`soe_org_id`,`soe_type`),
  KEY `soe_sem_id_idx` (`soe_sem_id`),
  KEY `soe_org_id_idx` (`soe_org_id`),
  CONSTRAINT `src_org_email_soe_org_id_organization_org_id` FOREIGN KEY (`soe_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `src_org_email_soe_sem_id_src_email_sem_id` FOREIGN KEY (`soe_sem_id`) REFERENCES `src_email` (`sem_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_outcome`
--

DROP TABLE IF EXISTS `src_outcome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_outcome` (
  `sout_src_id` int(11) NOT NULL DEFAULT '0',
  `sout_out_id` int(11) NOT NULL DEFAULT '0',
  `sout_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `sout_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sout_notes` text COLLATE utf8_unicode_ci,
  `sout_cre_user` int(11) NOT NULL,
  `sout_upd_user` int(11) DEFAULT NULL,
  `sout_cre_dtim` datetime NOT NULL,
  `sout_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sout_src_id`,`sout_out_id`),
  KEY `src_outcome_sout_out_id_outcome_out_id` (`sout_out_id`),
  CONSTRAINT `src_outcome_sout_out_id_outcome_out_id` FOREIGN KEY (`sout_out_id`) REFERENCES `outcome` (`out_id`) ON DELETE CASCADE,
  CONSTRAINT `src_outcome_sout_src_id_source_src_id` FOREIGN KEY (`sout_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_phone_number`
--

DROP TABLE IF EXISTS `src_phone_number`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_phone_number` (
  `sph_id` int(11) NOT NULL AUTO_INCREMENT,
  `sph_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sph_src_id` int(11) NOT NULL,
  `sph_primary_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sph_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_country` char(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_number` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `sph_ext` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sph_cre_user` int(11) NOT NULL,
  `sph_upd_user` int(11) DEFAULT NULL,
  `sph_cre_dtim` datetime NOT NULL,
  `sph_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sph_id`),
  UNIQUE KEY `sph_uuid` (`sph_uuid`),
  KEY `sph_src_id_idx` (`sph_src_id`),
  CONSTRAINT `src_phone_number_sph_src_id_source_src_id` FOREIGN KEY (`sph_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_pref_org`
--

DROP TABLE IF EXISTS `src_pref_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_pref_org` (
  `spo_id` int(11) NOT NULL AUTO_INCREMENT,
  `spo_src_id` int(11) NOT NULL,
  `spo_org_id` int(11) NOT NULL,
  `spo_effective` datetime NOT NULL,
  `spo_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `spo_xid` int(11) NOT NULL,
  `spo_lock_flag` tinyint(1) NOT NULL,
  `spo_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `spo_cre_user` int(11) NOT NULL,
  `spo_upd_user` int(11) DEFAULT NULL,
  `spo_cre_dtim` datetime NOT NULL,
  `spo_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`spo_id`),
  KEY `spo_src_id_idx` (`spo_src_id`),
  KEY `spo_org_id_idx` (`spo_org_id`),
  CONSTRAINT `src_pref_org_spo_org_id_organization_org_id` FOREIGN KEY (`spo_org_id`) REFERENCES `organization` (`org_id`),
  CONSTRAINT `src_pref_org_spo_src_id_source_src_id` FOREIGN KEY (`spo_src_id`) REFERENCES `source` (`src_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_preference`
--

DROP TABLE IF EXISTS `src_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_preference` (
  `sp_src_id` int(11) NOT NULL DEFAULT '0',
  `sp_ptv_id` int(11) NOT NULL DEFAULT '0',
  `sp_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sp_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sp_lock_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sp_cre_user` int(11) NOT NULL,
  `sp_upd_user` int(11) DEFAULT NULL,
  `sp_cre_dtim` datetime NOT NULL,
  `sp_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sp_src_id`,`sp_ptv_id`),
  UNIQUE KEY `sp_uuid` (`sp_uuid`),
  KEY `src_preference_sp_ptv_id_preference_type_value_ptv_id` (`sp_ptv_id`),
  CONSTRAINT `src_preference_sp_ptv_id_preference_type_value_ptv_id` FOREIGN KEY (`sp_ptv_id`) REFERENCES `preference_type_value` (`ptv_id`) ON DELETE CASCADE,
  CONSTRAINT `src_preference_sp_src_id_source_src_id` FOREIGN KEY (`sp_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_relationship`
--

DROP TABLE IF EXISTS `src_relationship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_relationship` (
  `srel_src_id` int(11) NOT NULL DEFAULT '0',
  `src_src_id` int(11) NOT NULL DEFAULT '0',
  `srel_context` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `srel_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `srel_cre_user` int(11) NOT NULL,
  `srel_upd_user` int(11) DEFAULT NULL,
  `srel_cre_dtim` datetime NOT NULL,
  `srel_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`srel_src_id`,`src_src_id`),
  KEY `src_relationship_src_src_id_source_src_id` (`src_src_id`),
  CONSTRAINT `src_relationship_src_src_id_source_src_id` FOREIGN KEY (`src_src_id`) REFERENCES `source` (`src_id`),
  CONSTRAINT `src_relationship_srel_src_id_source_src_id` FOREIGN KEY (`srel_src_id`) REFERENCES `source` (`src_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_response`
--

DROP TABLE IF EXISTS `src_response`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_response` (
  `sr_id` int(11) NOT NULL AUTO_INCREMENT,
  `sr_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sr_src_id` int(11) NOT NULL,
  `sr_ques_id` int(11) NOT NULL,
  `sr_srs_id` int(11) NOT NULL,
  `sr_media_asset_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sr_orig_value` text COLLATE utf8_unicode_ci,
  `sr_mod_value` text COLLATE utf8_unicode_ci,
  `sr_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sr_cre_user` int(11) NOT NULL,
  `sr_upd_user` int(11) DEFAULT NULL,
  `sr_cre_dtim` datetime NOT NULL,
  `sr_upd_dtim` datetime DEFAULT NULL,
  `sr_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sr_id`),
  UNIQUE KEY `sr_uuid` (`sr_uuid`),
  KEY `sr_srs_id_idx` (`sr_srs_id`),
  KEY `sr_ques_id_idx` (`sr_ques_id`),
  KEY `sr_src_id_idx` (`sr_src_id`),
  KEY `sr_public_flag_idx` (`sr_public_flag`),
  CONSTRAINT `src_response_sr_ques_id_question_ques_id` FOREIGN KEY (`sr_ques_id`) REFERENCES `question` (`ques_id`) ON DELETE CASCADE,
  CONSTRAINT `src_response_sr_src_id_source_src_id` FOREIGN KEY (`sr_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE,
  CONSTRAINT `src_response_sr_srs_id_src_response_set_srs_id` FOREIGN KEY (`sr_srs_id`) REFERENCES `src_response_set` (`srs_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_response_set`
--

DROP TABLE IF EXISTS `src_response_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_response_set` (
  `srs_id` int(11) NOT NULL AUTO_INCREMENT,
  `srs_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `srs_src_id` int(11) NOT NULL,
  `srs_inq_id` int(11) NOT NULL,
  `srs_date` datetime NOT NULL,
  `srs_uri` text COLLATE utf8_unicode_ci,
  `srs_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'F',
  `srs_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_delete_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_translated_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_export_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_loc_id` int(11) NOT NULL DEFAULT '52',
  `srs_conf_level` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_cre_user` int(11) NOT NULL,
  `srs_upd_user` int(11) DEFAULT NULL,
  `srs_cre_dtim` datetime NOT NULL,
  `srs_upd_dtim` datetime DEFAULT NULL,
  `srs_xuuid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_fb_approved_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_city` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_state` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_country` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_county` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_lat` float DEFAULT NULL,
  `srs_long` float DEFAULT NULL,
  PRIMARY KEY (`srs_id`),
  UNIQUE KEY `srs_uuid` (`srs_uuid`),
  KEY `srs_src_id_idx` (`srs_src_id`),
  KEY `srs_inq_id_idx` (`srs_inq_id`),
  KEY `srs_loc_id_idx` (`srs_loc_id`),
  KEY `srs_public_flag_idx` (`srs_public_flag`),
  KEY `srs_xuuid_idx` (`srs_xuuid`),
  KEY `srs_type_idx` (`srs_type`),
  CONSTRAINT `src_response_set_srs_inq_id_inquiry_inq_id` FOREIGN KEY (`srs_inq_id`) REFERENCES `inquiry` (`inq_id`) ON DELETE CASCADE,
  CONSTRAINT `src_response_set_srs_loc_id_locale_loc_id` FOREIGN KEY (`srs_loc_id`) REFERENCES `locale` (`loc_id`),
  CONSTRAINT `src_response_set_srs_src_id_source_src_id` FOREIGN KEY (`srs_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_stat`
--

DROP TABLE IF EXISTS `src_stat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_stat` (
  `sstat_src_id` int(11) NOT NULL DEFAULT '0',
  `sstat_export_dtim` datetime DEFAULT NULL,
  `sstat_contact_dtim` datetime DEFAULT NULL,
  `sstat_submit_dtim` datetime DEFAULT NULL,
  `sstat_bh_play_dtim` datetime DEFAULT NULL,
  `sstat_bh_signup_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sstat_src_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_uri`
--

DROP TABLE IF EXISTS `src_uri`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_uri` (
  `suri_id` int(11) NOT NULL AUTO_INCREMENT,
  `suri_src_id` int(11) NOT NULL,
  `suri_primary_flag` tinyint(1) NOT NULL,
  `suri_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `suri_value` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `suri_handle` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `suri_feed` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_upd_int` int(11) DEFAULT NULL,
  `suri_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `suri_cre_user` int(11) NOT NULL,
  `suri_upd_user` int(11) DEFAULT NULL,
  `suri_cre_dtim` datetime NOT NULL,
  `suri_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`suri_id`),
  KEY `suri_src_id_idx` (`suri_src_id`),
  CONSTRAINT `src_uri_suri_src_id_source_src_id` FOREIGN KEY (`suri_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `src_vita`
--

DROP TABLE IF EXISTS `src_vita`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `src_vita` (
  `sv_id` int(11) NOT NULL AUTO_INCREMENT,
  `sv_src_id` int(11) NOT NULL,
  `sv_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sv_seq` smallint(6) NOT NULL DEFAULT '10',
  `sv_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `sv_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sv_origin` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2',
  `sv_conf_level` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'U',
  `sv_lock_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sv_start_date` date DEFAULT NULL,
  `sv_end_date` date DEFAULT NULL,
  `sv_lat` float(18,2) DEFAULT NULL,
  `sv_long` float(18,2) DEFAULT NULL,
  `sv_value` text COLLATE utf8_unicode_ci,
  `sv_basis` text COLLATE utf8_unicode_ci,
  `sv_notes` text COLLATE utf8_unicode_ci,
  `sv_cre_user` int(11) NOT NULL,
  `sv_upd_user` int(11) DEFAULT NULL,
  `sv_cre_dtim` datetime NOT NULL,
  `sv_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`sv_id`),
  UNIQUE KEY `sv_uuid` (`sv_uuid`),
  KEY `sv_src_id_idx` (`sv_src_id`),
  CONSTRAINT `src_vita_sv_src_id_source_src_id` FOREIGN KEY (`sv_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `srs_annotation`
--

DROP TABLE IF EXISTS `srs_annotation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `srs_annotation` (
  `srsan_id` int(11) NOT NULL AUTO_INCREMENT,
  `srsan_srs_id` int(11) NOT NULL,
  `srsan_value` text COLLATE utf8_unicode_ci,
  `srsan_cre_user` int(11) NOT NULL,
  `srsan_upd_user` int(11) DEFAULT NULL,
  `srsan_cre_dtim` datetime NOT NULL,
  `srsan_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`srsan_id`),
  KEY `srsan_srs_id_idx` (`srsan_srs_id`),
  CONSTRAINT `srs_annotation_srsan_srs_id_src_response_set_srs_id` FOREIGN KEY (`srsan_srs_id`) REFERENCES `src_response_set` (`srs_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stale_record`
--

DROP TABLE IF EXISTS `stale_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stale_record` (
  `str_xid` int(11) NOT NULL,
  `str_upd_dtim` datetime NOT NULL,
  `str_type` char(1) NOT NULL,
  PRIMARY KEY (`str_xid`,`str_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `state`
--

DROP TABLE IF EXISTS `state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `state` (
  `state_id` int(11) NOT NULL AUTO_INCREMENT,
  `state_name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `state_code` char(2) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`state_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_message`
--

DROP TABLE IF EXISTS `system_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `system_message` (
  `smsg_id` int(11) NOT NULL DEFAULT '0',
  `smsg_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smsg_status` char(1) COLLATE utf8_unicode_ci DEFAULT 'A',
  `smsg_cre_user` int(11) NOT NULL,
  `smsg_upd_user` int(11) DEFAULT NULL,
  `smsg_cre_dtim` datetime NOT NULL,
  `smsg_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`smsg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tag`
--

DROP TABLE IF EXISTS `tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tag` (
  `tag_tm_id` int(11) NOT NULL DEFAULT '0',
  `tag_xid` int(11) NOT NULL DEFAULT '0',
  `tag_ref_type` varchar(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `tag_cre_user` int(11) NOT NULL,
  `tag_upd_user` int(11) DEFAULT NULL,
  `tag_cre_dtim` datetime NOT NULL,
  `tag_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`tag_tm_id`,`tag_xid`,`tag_ref_type`),
  KEY `tag_tag_ref_type_idx` (`tag_ref_type`),
  CONSTRAINT `tag_tag_tm_id_tag_master_tm_id` FOREIGN KEY (`tag_tm_id`) REFERENCES `tag_master` (`tm_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tag_master`
--

DROP TABLE IF EXISTS `tag_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tag_master` (
  `tm_id` int(11) NOT NULL AUTO_INCREMENT,
  `tm_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'J',
  `tm_name` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tm_iptc_id` int(11) DEFAULT NULL,
  `tm_cre_user` int(11) NOT NULL,
  `tm_upd_user` int(11) DEFAULT NULL,
  `tm_cre_dtim` datetime NOT NULL,
  `tm_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`tm_id`),
  UNIQUE KEY `tm_name` (`tm_name`),
  UNIQUE KEY `tm_iptc_id` (`tm_iptc_id`),
  KEY `tm_iptc_id_idx` (`tm_iptc_id`),
  CONSTRAINT `tag_master_tm_iptc_id_iptc_master_iptc_id` FOREIGN KEY (`tm_iptc_id`) REFERENCES `iptc_master` (`iptc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank`
--

DROP TABLE IF EXISTS `tank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank` (
  `tank_id` int(11) NOT NULL AUTO_INCREMENT,
  `tank_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `tank_user_id` int(11) NOT NULL,
  `tank_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tank_notes` text COLLATE utf8_unicode_ci,
  `tank_meta` text COLLATE utf8_unicode_ci,
  `tank_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `tank_status` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `tank_cre_user` int(11) NOT NULL,
  `tank_upd_user` int(11) DEFAULT NULL,
  `tank_cre_dtim` datetime NOT NULL,
  `tank_upd_dtim` datetime DEFAULT NULL,
  `tank_errors` text COLLATE utf8_unicode_ci,
  `tank_xuuid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`tank_id`),
  UNIQUE KEY `tank_uuid` (`tank_uuid`),
  KEY `tank_user_id_idx` (`tank_user_id`),
  CONSTRAINT `tank_tank_user_id_user_user_id` FOREIGN KEY (`tank_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_activity`
--

DROP TABLE IF EXISTS `tank_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_activity` (
  `tact_id` int(11) NOT NULL AUTO_INCREMENT,
  `tact_tank_id` int(11) NOT NULL,
  `tact_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'S',
  `tact_actm_id` int(11) NOT NULL,
  `tact_prj_id` int(11) DEFAULT NULL,
  `tact_dtim` datetime DEFAULT NULL,
  `tact_desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tact_notes` text COLLATE utf8_unicode_ci,
  `tact_xid` int(11) DEFAULT NULL,
  `tact_ref_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`tact_id`),
  KEY `tact_tank_id_idx` (`tact_tank_id`),
  KEY `tact_actm_id_idx` (`tact_actm_id`),
  KEY `tact_prj_id_idx` (`tact_prj_id`),
  CONSTRAINT `tank_activity_tact_actm_id_activity_master_actm_id` FOREIGN KEY (`tact_actm_id`) REFERENCES `activity_master` (`actm_id`) ON DELETE CASCADE,
  CONSTRAINT `tank_activity_tact_prj_id_project_prj_id` FOREIGN KEY (`tact_prj_id`) REFERENCES `project` (`prj_id`) ON DELETE CASCADE,
  CONSTRAINT `tank_activity_tact_tank_id_tank_tank_id` FOREIGN KEY (`tact_tank_id`) REFERENCES `tank` (`tank_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_fact`
--

DROP TABLE IF EXISTS `tank_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_fact` (
  `tf_id` int(11) NOT NULL AUTO_INCREMENT,
  `tf_fact_id` int(11) NOT NULL,
  `tf_tsrc_id` int(11) NOT NULL,
  `sf_fv_id` int(11) DEFAULT NULL,
  `sf_src_value` text COLLATE utf8_unicode_ci,
  `sf_src_fv_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`tf_id`),
  KEY `tf_tsrc_id_idx` (`tf_tsrc_id`),
  KEY `tf_fact_id_idx` (`tf_fact_id`),
  KEY `sf_fv_id_idx` (`sf_fv_id`),
  KEY `sf_src_fv_id_idx` (`sf_src_fv_id`),
  CONSTRAINT `tank_fact_sf_fv_id_fact_value_fv_id` FOREIGN KEY (`sf_fv_id`) REFERENCES `fact_value` (`fv_id`),
  CONSTRAINT `tank_fact_sf_src_fv_id_fact_value_fv_id` FOREIGN KEY (`sf_src_fv_id`) REFERENCES `fact_value` (`fv_id`),
  CONSTRAINT `tank_fact_tf_fact_id_fact_fact_id` FOREIGN KEY (`tf_fact_id`) REFERENCES `fact` (`fact_id`),
  CONSTRAINT `tank_fact_tf_tsrc_id_tank_source_tsrc_id` FOREIGN KEY (`tf_tsrc_id`) REFERENCES `tank_source` (`tsrc_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_log`
--

DROP TABLE IF EXISTS `tank_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_log` (
  `tlog_id` int(11) NOT NULL AUTO_INCREMENT,
  `tlog_tank_id` int(11) NOT NULL,
  `tlog_user_id` int(11) NOT NULL,
  `tlog_dtim` datetime NOT NULL,
  `tlog_text` text COLLATE utf8_unicode_ci,
  `tlog_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `tlog_status` char(1) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`tlog_id`),
  KEY `tlog_tank_id_idx` (`tlog_tank_id`),
  KEY `tlog_user_id_idx` (`tlog_user_id`),
  CONSTRAINT `tank_log_tlog_tank_id_tank_tank_id` FOREIGN KEY (`tlog_tank_id`) REFERENCES `tank` (`tank_id`) ON DELETE CASCADE,
  CONSTRAINT `tank_log_tlog_user_id_user_user_id` FOREIGN KEY (`tlog_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_org`
--

DROP TABLE IF EXISTS `tank_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_org` (
  `to_id` int(11) NOT NULL AUTO_INCREMENT,
  `to_tank_id` int(11) NOT NULL,
  `to_org_id` int(11) NOT NULL,
  `to_so_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `to_so_home_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`to_id`),
  KEY `to_tank_id_idx` (`to_tank_id`),
  KEY `to_org_id_idx` (`to_org_id`),
  CONSTRAINT `tank_org_to_org_id_organization_org_id` FOREIGN KEY (`to_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `tank_org_to_tank_id_tank_tank_id` FOREIGN KEY (`to_tank_id`) REFERENCES `tank` (`tank_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_preference`
--

DROP TABLE IF EXISTS `tank_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_preference` (
  `tp_id` int(11) NOT NULL AUTO_INCREMENT,
  `tp_tsrc_id` int(11) NOT NULL,
  `sp_ptv_id` int(11) NOT NULL DEFAULT '0',
  `sp_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `sp_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sp_lock_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`tp_id`,`sp_ptv_id`),
  UNIQUE KEY `sp_uuid` (`sp_uuid`),
  KEY `tp_tsrc_id_idx` (`tp_tsrc_id`),
  CONSTRAINT `tank_preference_tp_tsrc_id_tank_source_tsrc_id` FOREIGN KEY (`tp_tsrc_id`) REFERENCES `tank_source` (`tsrc_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_response`
--

DROP TABLE IF EXISTS `tank_response`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_response` (
  `tr_id` int(11) NOT NULL AUTO_INCREMENT,
  `tr_tsrc_id` int(11) NOT NULL,
  `tr_trs_id` int(11) NOT NULL,
  `sr_ques_id` int(11) NOT NULL,
  `sr_media_asset_flag` tinyint(1) NOT NULL DEFAULT '0',
  `sr_orig_value` text COLLATE utf8_unicode_ci,
  `sr_mod_value` text COLLATE utf8_unicode_ci,
  `sr_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `sr_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sr_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`tr_id`),
  KEY `tr_trs_id_idx` (`tr_trs_id`),
  KEY `sr_ques_id_idx` (`sr_ques_id`),
  KEY `tr_tsrc_id_idx` (`tr_tsrc_id`),
  CONSTRAINT `tank_response_sr_ques_id_question_ques_id` FOREIGN KEY (`sr_ques_id`) REFERENCES `question` (`ques_id`),
  CONSTRAINT `tank_response_tr_trs_id_tank_response_set_trs_id` FOREIGN KEY (`tr_trs_id`) REFERENCES `tank_response_set` (`trs_id`) ON DELETE CASCADE,
  CONSTRAINT `tank_response_tr_tsrc_id_tank_source_tsrc_id` FOREIGN KEY (`tr_tsrc_id`) REFERENCES `tank_source` (`tsrc_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_response_set`
--

DROP TABLE IF EXISTS `tank_response_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_response_set` (
  `trs_id` int(11) NOT NULL AUTO_INCREMENT,
  `trs_tsrc_id` int(11) NOT NULL,
  `srs_inq_id` int(11) NOT NULL,
  `srs_date` datetime NOT NULL,
  `srs_uri` text COLLATE utf8_unicode_ci,
  `srs_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'F',
  `srs_public_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_delete_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_translated_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_export_flag` tinyint(1) NOT NULL DEFAULT '0',
  `srs_loc_id` int(11) NOT NULL DEFAULT '52',
  `srs_conf_level` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_xuuid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srs_fb_approved_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`trs_id`),
  KEY `trs_tsrc_id_idx` (`trs_tsrc_id`),
  KEY `srs_inq_id_idx` (`srs_inq_id`),
  CONSTRAINT `tank_response_set_srs_inq_id_inquiry_inq_id` FOREIGN KEY (`srs_inq_id`) REFERENCES `inquiry` (`inq_id`),
  CONSTRAINT `tank_response_set_trs_tsrc_id_tank_source_tsrc_id` FOREIGN KEY (`trs_tsrc_id`) REFERENCES `tank_source` (`tsrc_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_source`
--

DROP TABLE IF EXISTS `tank_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_source` (
  `tsrc_id` int(11) NOT NULL AUTO_INCREMENT,
  `tsrc_tank_id` int(11) NOT NULL,
  `tsrc_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'N',
  `tsrc_errors` text COLLATE utf8_unicode_ci,
  `tsrc_cre_user` int(11) NOT NULL,
  `tsrc_upd_user` int(11) DEFAULT NULL,
  `tsrc_cre_dtim` datetime NOT NULL,
  `tsrc_upd_dtim` datetime DEFAULT NULL,
  `tsrc_tags` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_id` int(11) DEFAULT NULL,
  `src_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_middle_initial` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_pre_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_post_name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_status` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `src_channel` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_primary_flag` tinyint(1) DEFAULT NULL,
  `smadd_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_line_1` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_line_2` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_city` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_state` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_cntry` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_zip` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `smadd_lat` float(10,6) DEFAULT NULL,
  `smadd_long` float(10,6) DEFAULT NULL,
  `sph_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_primary_flag` tinyint(1) DEFAULT NULL,
  `sph_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_country` char(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_number` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sph_ext` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sem_uuid` char(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sem_primary_flag` tinyint(1) DEFAULT NULL,
  `sem_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sem_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sem_effective_date` date DEFAULT NULL,
  `sem_expire_date` date DEFAULT NULL,
  `suri_primary_flag` tinyint(1) DEFAULT NULL,
  `suri_context` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_handle` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suri_feed` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srcan_type` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srcan_value` text COLLATE utf8_unicode_ci,
  `tsrc_created_flag` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`tsrc_id`),
  KEY `tsrc_tank_id_idx` (`tsrc_tank_id`),
  CONSTRAINT `tank_source_tsrc_tank_id_tank_tank_id` FOREIGN KEY (`tsrc_tank_id`) REFERENCES `tank` (`tank_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_vita`
--

DROP TABLE IF EXISTS `tank_vita`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tank_vita` (
  `tv_id` int(11) NOT NULL AUTO_INCREMENT,
  `tv_tsrc_id` int(11) NOT NULL,
  `sv_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'I',
  `sv_origin` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2',
  `sv_start_date` date DEFAULT NULL,
  `sv_end_date` date DEFAULT NULL,
  `sv_lat` float(18,2) DEFAULT NULL,
  `sv_long` float(18,2) DEFAULT NULL,
  `sv_value` text COLLATE utf8_unicode_ci,
  `sv_basis` text COLLATE utf8_unicode_ci,
  `sv_notes` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`tv_id`),
  KEY `tv_tsrc_id_idx` (`tv_tsrc_id`),
  CONSTRAINT `tank_vita_tv_tsrc_id_tank_source_tsrc_id` FOREIGN KEY (`tv_tsrc_id`) REFERENCES `tank_source` (`tsrc_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trackback`
--

DROP TABLE IF EXISTS `trackback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `trackback` (
  `tb_id` int(11) NOT NULL AUTO_INCREMENT,
  `tb_src_id` int(11) NOT NULL,
  `tb_user_id` int(11) NOT NULL,
  `tb_ip` int(10) unsigned NOT NULL,
  `tb_dtim` datetime NOT NULL,
  PRIMARY KEY (`tb_id`),
  KEY `tb_src_id_idx` (`tb_src_id`),
  KEY `tb_user_id_idx` (`tb_user_id`),
  CONSTRAINT `trackback_tb_src_id_source_src_id` FOREIGN KEY (`tb_src_id`) REFERENCES `source` (`src_id`) ON DELETE CASCADE,
  CONSTRAINT `trackback_tb_user_id_user_user_id` FOREIGN KEY (`tb_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `translation_map`
--

DROP TABLE IF EXISTS `translation_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `translation_map` (
  `xm_id` int(11) NOT NULL AUTO_INCREMENT,
  `xm_fact_id` int(11) NOT NULL,
  `xm_xlate_from` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `xm_xlate_to_fv_id` int(11) NOT NULL,
  `xm_cre_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`xm_id`),
  KEY `xm_fact_id_idx` (`xm_fact_id`),
  KEY `xm_xlate_to_fv_id_idx` (`xm_xlate_to_fv_id`),
  CONSTRAINT `translation_map_xm_fact_id_fact_fact_id` FOREIGN KEY (`xm_fact_id`) REFERENCES `fact` (`fact_id`) ON DELETE CASCADE,
  CONSTRAINT `translation_map_xm_xlate_to_fv_id_fact_value_fv_id` FOREIGN KEY (`xm_xlate_to_fv_id`) REFERENCES `fact_value` (`fv_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `user_username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_password` char(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_pswd_dtim` datetime DEFAULT NULL,
  `user_first_name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `user_last_name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `user_pref` text COLLATE utf8_unicode_ci,
  `user_type` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `user_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `user_cre_user` int(11) DEFAULT NULL,
  `user_upd_user` int(11) DEFAULT NULL,
  `user_cre_dtim` datetime NOT NULL,
  `user_upd_dtim` datetime DEFAULT NULL,
  `user_summary` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_desc` text COLLATE utf8_unicode_ci,
  `user_login_dtim` datetime DEFAULT NULL,
  `user_encrypted_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_uuid` (`user_uuid`),
  UNIQUE KEY `user_username` (`user_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_email_address`
--

DROP TABLE IF EXISTS `user_email_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_email_address` (
  `uem_id` int(11) NOT NULL AUTO_INCREMENT,
  `uem_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `uem_user_id` int(11) NOT NULL,
  `uem_address` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uem_primary_flag` tinyint(1) NOT NULL,
  `uem_signature` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`uem_id`),
  UNIQUE KEY `uem_uuid` (`uem_uuid`),
  KEY `uem_user_id_idx` (`uem_user_id`),
  CONSTRAINT `user_email_address_uem_user_id_user_user_id` FOREIGN KEY (`uem_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_org`
--

DROP TABLE IF EXISTS `user_org`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_org` (
  `uo_id` int(11) NOT NULL AUTO_INCREMENT,
  `uo_org_id` int(11) NOT NULL,
  `uo_user_id` int(11) NOT NULL,
  `uo_ar_id` int(11) NOT NULL,
  `uo_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `uo_user_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `uo_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `uo_notify_flag` tinyint(1) NOT NULL DEFAULT '0',
  `uo_home_flag` tinyint(1) NOT NULL DEFAULT '0',
  `uo_cre_user` int(11) NOT NULL,
  `uo_upd_user` int(11) DEFAULT NULL,
  `uo_cre_dtim` datetime NOT NULL,
  `uo_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`uo_id`),
  UNIQUE KEY `uo_uuid` (`uo_uuid`),
  UNIQUE KEY `uo_ix_2_idx` (`uo_org_id`,`uo_user_id`),
  KEY `uo_user_id_idx` (`uo_user_id`),
  KEY `uo_org_id_idx` (`uo_org_id`),
  KEY `uo_ar_id_idx` (`uo_ar_id`),
  CONSTRAINT `user_org_uo_ar_id_admin_role_ar_id` FOREIGN KEY (`uo_ar_id`) REFERENCES `admin_role` (`ar_id`),
  CONSTRAINT `user_org_uo_org_id_organization_org_id` FOREIGN KEY (`uo_org_id`) REFERENCES `organization` (`org_id`) ON DELETE CASCADE,
  CONSTRAINT `user_org_uo_user_id_user_user_id` FOREIGN KEY (`uo_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_phone_number`
--

DROP TABLE IF EXISTS `user_phone_number`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_phone_number` (
  `uph_id` int(11) NOT NULL AUTO_INCREMENT,
  `uph_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `uph_user_id` int(11) NOT NULL,
  `uph_country` char(3) COLLATE utf8_unicode_ci NOT NULL,
  `uph_number` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `uph_ext` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `uph_primary_flag` tinyint(1) NOT NULL,
  PRIMARY KEY (`uph_id`),
  UNIQUE KEY `uph_uuid` (`uph_uuid`),
  KEY `uph_user_id_idx` (`uph_user_id`),
  CONSTRAINT `user_phone_number_uph_user_id_user_user_id` FOREIGN KEY (`uph_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_signature`
--

DROP TABLE IF EXISTS `user_signature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_signature` (
  `usig_id` int(11) NOT NULL AUTO_INCREMENT,
  `usig_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `usig_user_id` int(11) NOT NULL,
  `usig_text` text COLLATE utf8_unicode_ci NOT NULL,
  `usig_status` char(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'A',
  `usig_cre_user` int(11) NOT NULL,
  `usig_upd_user` int(11) DEFAULT NULL,
  `usig_cre_dtim` datetime NOT NULL,
  `usig_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`usig_id`),
  UNIQUE KEY `usig_uuid` (`usig_uuid`),
  KEY `usig_user_id_idx` (`usig_user_id`),
  CONSTRAINT `user_signature_usig_user_id_user_user_id` FOREIGN KEY (`usig_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_srs`
--

DROP TABLE IF EXISTS `user_srs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_srs` (
  `usrs_user_id` int(11) NOT NULL DEFAULT '0',
  `usrs_srs_id` int(11) NOT NULL DEFAULT '0',
  `usrs_read_flag` tinyint(1) NOT NULL DEFAULT '0',
  `usrs_favorite_flag` tinyint(1) NOT NULL DEFAULT '0',
  `usrs_cre_dtim` datetime NOT NULL,
  `usrs_upd_dtim` datetime DEFAULT NULL,
  PRIMARY KEY (`usrs_user_id`,`usrs_srs_id`),
  KEY `user_srs_usrs_srs_id_src_response_set_srs_id` (`usrs_srs_id`),
  CONSTRAINT `user_srs_usrs_srs_id_src_response_set_srs_id` FOREIGN KEY (`usrs_srs_id`) REFERENCES `src_response_set` (`srs_id`) ON DELETE CASCADE,
  CONSTRAINT `user_srs_usrs_user_id_user_user_id` FOREIGN KEY (`usrs_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_uri`
--

DROP TABLE IF EXISTS `user_uri`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_uri` (
  `uuri_id` int(11) NOT NULL AUTO_INCREMENT,
  `uuri_uuid` char(12) COLLATE utf8_unicode_ci NOT NULL,
  `uuri_user_id` int(11) NOT NULL,
  `uuri_type` char(1) COLLATE utf8_unicode_ci NOT NULL,
  `uuri_value` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuri_feed` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `uuri_upd_int` int(11) DEFAULT NULL,
  `uuri_handle` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`uuri_id`),
  UNIQUE KEY `uuri_uuid` (`uuri_uuid`),
  KEY `uuri_user_id_idx` (`uuri_user_id`),
  CONSTRAINT `user_uri_uuri_user_id_user_user_id` FOREIGN KEY (`uuri_user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_visit`
--

DROP TABLE IF EXISTS `user_visit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_visit` (
  `uv_id` int(11) NOT NULL AUTO_INCREMENT,
  `uv_user_id` int(11) NOT NULL,
  `uv_ref_type` varchar(1) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `uv_xid` int(11) NOT NULL,
  `uv_ip` int(10) unsigned NOT NULL,
  `uv_cre_user` int(11) NOT NULL,
  `uv_cre_dtim` datetime NOT NULL,
  PRIMARY KEY (`uv_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-11-20 19:58:10
