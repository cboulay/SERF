-- MySQL dump 10.13  Distrib 5.5.25, for Win64 (x86)
--
-- Host: localhost    Database: eerf_subject_template
-- ------------------------------------------------------
-- Server version	5.5.25

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
-- Table structure for table `datum`
--

DROP TABLE IF EXISTS `datum`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datum` (
  `datum_id` int(11) NOT NULL AUTO_INCREMENT,
  `datum_type_id` int(11) NOT NULL,
  `Number` int(11) NOT NULL DEFAULT '0',
  `span_type` enum('trial','day','period') NOT NULL DEFAULT 'trial',
  `IsGood` tinyint(1) NOT NULL DEFAULT '1',
  `StartTime` datetime DEFAULT NULL,
  `EndTime` datetime DEFAULT NULL,
  PRIMARY KEY (`datum_id`),
  UNIQUE KEY `SECONDARY` (`datum_type_id`,`Number`,`span_type`),
  KEY `subj_dat` (`datum_type_id`,`IsGood`,`span_type`),
  KEY `d_dt` (`datum_type_id`),
  CONSTRAINT `d_dt` FOREIGN KEY (`datum_type_id`) REFERENCES `eerf_settings`.`datum_type` (`datum_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,TRADITIONAL,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER datum_before BEFORE INSERT ON datum
FOR EACH ROW
BEGIN
    SET NEW.StartTime = COALESCE(NEW.StartTime, NOW());
    -- TODO: Make this next function smart enough to pick the next smallest free number based on StartTime
    IF NEW.Number IS NULL OR NEW.Number = 0 THEN
        SET NEW.Number = (SELECT coalesce(max(Number),0)+1 FROM datum
            WHERE datum.datum_type_id = NEW.datum_type_id AND datum.span_type = NEW.span_type
            ORDER BY datum.Number DESC LIMIT 1);
    END IF;
    IF NEW.span_type = 'trial' THEN
        -- If an EndTime was not specified, make the trial duration 1 second.
        SET NEW.EndTime = COALESCE(NEW.EndTime, NEW.StartTime + INTERVAL 1 SECOND);
    END IF;
    IF NEW.span_type = 'period' THEN
        -- Default period duration is 1 hr.
        SET NEW.EndTime = COALESCE(NEW.EndTime, NEW.StartTime + INTERVAL 1 HOUR);
    END IF;
END */;;
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
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,TRADITIONAL,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER datum_insert AFTER INSERT ON datum
FOR EACH ROW
BEGIN
    DECLARE prev_id INT;
    -- Initialize this trial with some detail values
    -- Use previous period/trial for same subject x type if it exists
    SET prev_id = (SELECT datum_id FROM datum 
        WHERE datum_type_id = NEW.datum_type_id 
        AND span_type = NEW.span_type 
        AND IsGood = 1
        AND Number < New.Number
        ORDER BY Number DESC LIMIT 1);
    -- If this is a trial, then use the parent
    IF prev_id IS NULL AND NEW.span_type = 'trial' THEN
        SET prev_id = (SELECT MAX(dhd.parent_datum_id)
            FROM datum_has_datum as dhd
            WHERE dhd.child_datum_id = NEW.datum_id);
    END IF;
    IF prev_id IS NOT NULL THEN
        INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
        SELECT NEW.datum_id, ddv.detail_type_id, ddv.Value
        FROM datum_detail_value AS ddv
        WHERE ddv.datum_id = prev_id;
    ELSE
    -- If there is no previous datum, and there is no parent, use defaults.
        INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
        SELECT NEW.datum_id, dthdt.detail_type_id, det_type.DefaultValue
        FROM eerat_settings.datum_type_has_detail_type AS dthdt
        	INNER JOIN eerat_settings.detail_type AS det_type USING (detail_type_id)
        WHERE dthdt.datum_type_id = NEW.datum_type_id;
    END IF;
    
    -- Put a blank store into datum_store
    INSERT IGNORE INTO datum_store (datum_id) VALUES (NEW.datum_id);
    
    -- NULLS into datum_feature_value
    INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
        SELECT NEW.datum_id, dthft.feature_type_id, NULL
        FROM eerat_settings.datum_type_has_feature_type AS dthft
        WHERE dthft.datum_type_id=NEW.datum_type_id;
END */;;
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
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,TRADITIONAL,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER datum_update_bef BEFORE UPDATE ON datum
FOR EACH ROW
BEGIN
    IF NEW.datum_type_id != OLD.datum_type_id THEN
        -- update the number so it is the next highest of those already existing for that type.
        SET NEW.Number = (SELECT coalesce(max(Number),0)+1 FROM datum
            WHERE datum.datum_type_id = NEW.datum_type_id AND datum.span_type = NEW.span_type
            ORDER BY datum.Number DESC LIMIT 1);
    END IF;
END */;;
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
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,TRADITIONAL,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER datum_update AFTER UPDATE ON datum
FOR EACH ROW
BEGIN
    -- If the datum type has changed
    IF NEW.datum_type_id != OLD.datum_type_id THEN
        -- then we need to delete any detail values that no longer belong to this new datum type.
        DELETE FROM datum_detail_value
    	WHERE datum_detail_value.datum_id = NEW.datum_id
		AND datum_detail_value.detail_type_id NOT IN 
        	(SELECT dthdt.detail_type_id
    		FROM eerat_settings.datum_type_has_detail_type AS dthdt
    		WHERE dthdt.datum_type_id=NEW.datum_type_id);
        
        -- and insert default detail values for any new ones
        IF NEW.span_type = 'period' THEN
            INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
        	SELECT NEW.datum_id, dthdt.detail_type_id, det_type.DefaultValue
       		FROM eerat_settings.datum_type_has_detail_type AS dthdt 
        		INNER JOIN eerat_settings.detail_type AS det_type USING (detail_type_id)
        	WHERE dthdt.datum_type_id = NEW.datum_type_id;
        
        -- If not period, then use parent values. Uses most recent parent if there are more than one.
        ELSE
            INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
            SELECT NEW.datum_id, parent_ddv.detail_type_id, parent_ddv.Value
            FROM datum_detail_value AS parent_ddv, datum_has_datum AS dhd
            WHERE parent_ddv.datum_id = MAX(dhd.parent_datum_id)
            AND dhd.child_datum_id = NEW.datum_id;
        END IF;
        
        -- and delete feature_values that are no longer needed.
        DELETE FROM datum_feature_value
        WHERE datum_feature_value.datum_id = NEW.datum_id
        AND datum_feature_value.feature_type_id NOT IN
            (SELECT dthft.feature_type_id
            FROM eerat_settings.datum_type_has_feature_type as dthft
            WHERE dthft.datum_type_id=NEW.datum_type_id);

        -- and insert NULL feature_values
        INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
        SELECT NEW.datum_id, dthft.feature_type_id, NULL
        FROM eerat_settings.datum_type_has_feature_type AS dthft
        WHERE dthft.datum_type_id=NEW.datum_type_id;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `datum_detail_value`
--

DROP TABLE IF EXISTS `datum_detail_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datum_detail_value` (
  `datum_id` int(11) NOT NULL,
  `detail_type_id` int(11) NOT NULL,
  `Value` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`datum_id`,`detail_type_id`),
  KEY `fk_datum_detail_value_datum_and_datum_type` (`datum_id`),
  KEY `ddv_dt` (`detail_type_id`),
  CONSTRAINT `fk_datum_detail_value_datum_and_datum_type` FOREIGN KEY (`datum_id`) REFERENCES `datum` (`datum_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ddv_dt` FOREIGN KEY (`detail_type_id`) REFERENCES `eerf_settings`.`detail_type` (`detail_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `datum_feature_value`
--

DROP TABLE IF EXISTS `datum_feature_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datum_feature_value` (
  `datum_id` int(11) NOT NULL,
  `feature_type_id` int(11) NOT NULL,
  `Value` float DEFAULT NULL,
  PRIMARY KEY (`datum_id`,`feature_type_id`),
  KEY `fk_datum_feature_value_datum_id` (`datum_id`),
  KEY `dfv_ft` (`feature_type_id`),
  CONSTRAINT `fk_datum_feature_value_datum_id` FOREIGN KEY (`datum_id`) REFERENCES `datum` (`datum_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `dfv_ft` FOREIGN KEY (`feature_type_id`) REFERENCES `eerf_settings`.`feature_type` (`feature_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `datum_has_datum`
--

DROP TABLE IF EXISTS `datum_has_datum`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datum_has_datum` (
  `parent_datum_id` int(11) NOT NULL,
  `child_datum_id` int(11) NOT NULL,
  PRIMARY KEY (`parent_datum_id`,`child_datum_id`),
  KEY `fk_datum_has_datum_datum2` (`child_datum_id`),
  KEY `fk_datum_has_datum_datum1` (`parent_datum_id`),
  CONSTRAINT `fk_datum_has_datum_datum1` FOREIGN KEY (`parent_datum_id`) REFERENCES `datum` (`datum_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_has_datum_datum2` FOREIGN KEY (`child_datum_id`) REFERENCES `datum` (`datum_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `datum_store`
--

DROP TABLE IF EXISTS `datum_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datum_store` (
  `datum_id` int(11) NOT NULL,
  `x_vec` longblob,
  `erp` longblob,
  `n_channels` smallint(6) DEFAULT NULL,
  `n_samples` smallint(6) DEFAULT NULL,
  `channel_labels` text,
  PRIMARY KEY (`datum_id`),
  CONSTRAINT `fk_datum_store_datum1` FOREIGN KEY (`datum_id`) REFERENCES `datum` (`datum_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'eerf_subject_template'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-09-07 17:12:24
