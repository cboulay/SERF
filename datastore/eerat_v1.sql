SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `eerat` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;

USE `eerat`;

CREATE  TABLE IF NOT EXISTS `eerat`.`subject_type` (
  `subject_type_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'Healthy Control' ,
  `Description` VARCHAR(100) NULL DEFAULT NULL ,
  PRIMARY KEY (`subject_type_id`) ,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`detail_type` (
  `detail_type_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'Window_start_ms' ,
  `Description` VARCHAR(100) NULL DEFAULT NULL ,
  `DefaultValue` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`detail_type_id`) ,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`feature_type` (
  `feature_type_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'FeatureName' ,
  `Description` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`feature_type_id`) ,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_type` (
  `datum_type_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'trial HR no reward' ,
  `Description` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`datum_type_id`) ,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_type_has_feature_type` (
  `datum_type_id` INT(11) NOT NULL ,
  `feature_type_id` INT(11) NOT NULL ,
  PRIMARY KEY (`datum_type_id`, `feature_type_id`) ,
  INDEX `fk_datum_type_has_feature_type_feature_type1` (`feature_type_id` ASC) ,
  INDEX `fk_datum_type_has_feature_type_datum_type1` (`datum_type_id` ASC) ,
  CONSTRAINT `fk_datum_type_has_feature_type_datum_type1`
    FOREIGN KEY (`datum_type_id` )
    REFERENCES `eerat`.`datum_type` (`datum_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_type_has_feature_type_feature_type1`
    FOREIGN KEY (`feature_type_id` )
    REFERENCES `eerat`.`feature_type` (`feature_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`subject` (
  `subject_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `subject_type_id` INT(11) NOT NULL ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'SubjectName' ,
  `DateOfBirth` DATE NULL DEFAULT NULL ,
  `IsMale` TINYINT(1) NULL DEFAULT NULL ,
  `Weight` FLOAT(11) NULL DEFAULT NULL ,
  `Notes` LONGTEXT NULL DEFAULT NULL ,
  `species_type` ENUM('rat','human') NULL DEFAULT 'human' ,
  PRIMARY KEY (`subject_id`) ,
  INDEX `fk_subject_subject_type1` (`subject_type_id` ASC) ,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) ,
  CONSTRAINT `fk_subject_subject_type1`
    FOREIGN KEY (`subject_type_id` )
    REFERENCES `eerat`.`subject_type` (`subject_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum` (
  `datum_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `subject_id` INT(11) NOT NULL ,
  `datum_type_id` INT(11) NOT NULL ,
  `Number` INT(11) NOT NULL DEFAULT 0 ,
  `span_type` ENUM('trial','day','period') NOT NULL DEFAULT 'trial' ,
  `IsGood` TINYINT(1) NOT NULL DEFAULT 1 ,
  `StartTime` DATETIME NULL DEFAULT NULL ,
  `EndTime` DATETIME NULL DEFAULT NULL ,
  `MeetsCriteria` TINYINT(1) NULL DEFAULT NULL ,
  PRIMARY KEY (`datum_id`) ,
  INDEX `fk_datum_datum_type1` (`datum_type_id` ASC) ,
  INDEX `fk_datum_subject1` (`subject_id` ASC) ,
  INDEX `subj_dat` (`subject_id` ASC, `datum_type_id` ASC, `IsGood` ASC, `span_type` ASC) ,
  UNIQUE INDEX `SECONDARY` (`subject_id` ASC, `datum_type_id` ASC, `Number` ASC, `span_type` ASC) ,
  CONSTRAINT `fk_datum_datum_type1`
    FOREIGN KEY (`datum_type_id` )
    REFERENCES `eerat`.`datum_type` (`datum_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_subject1`
    FOREIGN KEY (`subject_id` )
    REFERENCES `eerat`.`subject` (`subject_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`trial_criterion` (
  `subject_id` INT(11) NOT NULL ,
  `ls_feature_type_id` INT(11) NOT NULL ,
  `Comparison_operator` ENUM('>','>=','<','<=','==','!=') NOT NULL ,
  `rs_feature_type_id` INT(11) NULL DEFAULT NULL ,
  `Rs_value` FLOAT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`subject_id`, `ls_feature_type_id`, `Comparison_operator`) ,
  INDEX `fk_trial_criterion_feature_type1` (`ls_feature_type_id` ASC) ,
  INDEX `fk_trial_criterion_feature_type2` (`rs_feature_type_id` ASC) ,
  CONSTRAINT `fk_trial_criterion_subject1`
    FOREIGN KEY (`subject_id` )
    REFERENCES `eerat`.`subject` (`subject_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_trial_criterion_feature_type1`
    FOREIGN KEY (`ls_feature_type_id` )
    REFERENCES `eerat`.`feature_type` (`feature_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_trial_criterion_feature_type2`
    FOREIGN KEY (`rs_feature_type_id` )
    REFERENCES `eerat`.`feature_type` (`feature_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_feature_value` (
  `datum_id` INT(11) NOT NULL ,
  `feature_type_id` INT(11) NOT NULL ,
  `Value` FLOAT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`datum_id`, `feature_type_id`) ,
  INDEX `fk_datum_feature_value_datum_id` (`datum_id` ASC) ,
  INDEX `fk_datum_feature_value_feature_type1` (`feature_type_id` ASC) ,
  CONSTRAINT `fk_datum_feature_value_datum_id`
    FOREIGN KEY (`datum_id` )
    REFERENCES `eerat`.`datum` (`datum_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_feature_value_feature_type1`
    FOREIGN KEY (`feature_type_id` )
    REFERENCES `eerat`.`feature_type` (`feature_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`experiment` (
  `experiment_id` INT(11) NOT NULL AUTO_INCREMENT ,
  `Name` VARCHAR(45) NOT NULL DEFAULT 'ExperimentName' ,
  `Description` VARCHAR(100) NULL DEFAULT NULL ,
  PRIMARY KEY (`experiment_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`experiment_has_subject` (
  `experiment_id` INT(11) NOT NULL ,
  `subject_id` INT(11) NOT NULL ,
  PRIMARY KEY (`experiment_id`, `subject_id`) ,
  INDEX `fk_experiment_has_subject_subject1` (`subject_id` ASC) ,
  INDEX `fk_experiment_has_subject_experiment1` (`experiment_id` ASC) ,
  CONSTRAINT `fk_experiment_has_subject_experiment1`
    FOREIGN KEY (`experiment_id` )
    REFERENCES `eerat`.`experiment` (`experiment_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_experiment_has_subject_subject1`
    FOREIGN KEY (`subject_id` )
    REFERENCES `eerat`.`subject` (`subject_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_detail_value` (
  `datum_id` INT(11) NOT NULL ,
  `detail_type_id` INT(11) NOT NULL ,
  `Value` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`datum_id`, `detail_type_id`) ,
  INDEX `fk_datum_detail_value_datum_and_datum_type` (`datum_id` ASC) ,
  INDEX `fk_datum_detail_value_detail_type1` (`detail_type_id` ASC) ,
  CONSTRAINT `fk_datum_detail_value_datum_and_datum_type`
    FOREIGN KEY (`datum_id` )
    REFERENCES `eerat`.`datum` (`datum_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_detail_value_detail_type1`
    FOREIGN KEY (`detail_type_id` )
    REFERENCES `eerat`.`detail_type` (`detail_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`subject_type_has_detail_type` (
  `subject_type_id` INT(11) NOT NULL ,
  `detail_type_id` INT(11) NOT NULL ,
  PRIMARY KEY (`subject_type_id`, `detail_type_id`) ,
  INDEX `fk_subject_type_has_detail_type_detail_type1` (`detail_type_id` ASC) ,
  INDEX `fk_subject_type_has_detail_type_subject_type1` (`subject_type_id` ASC) ,
  CONSTRAINT `fk_subject_type_has_detail_type_subject_type1`
    FOREIGN KEY (`subject_type_id` )
    REFERENCES `eerat`.`subject_type` (`subject_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_subject_type_has_detail_type_detail_type1`
    FOREIGN KEY (`detail_type_id` )
    REFERENCES `eerat`.`detail_type` (`detail_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`subject_detail_value` (
  `subject_id` INT(11) NOT NULL ,
  `detail_type_id` INT(11) NOT NULL ,
  `Value` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`subject_id`, `detail_type_id`) ,
  INDEX `fk_subject_detail_value_subject_and_subject_type` (`subject_id` ASC) ,
  INDEX `fk_subject_detail_value_detail_type1` (`detail_type_id` ASC) ,
  CONSTRAINT `fk_subject_detail_value_subject_and_subject_type`
    FOREIGN KEY (`subject_id` )
    REFERENCES `eerat`.`subject` (`subject_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_subject_detail_value_detail_type1`
    FOREIGN KEY (`detail_type_id` )
    REFERENCES `eerat`.`detail_type` (`detail_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`system` (
  `Name` VARCHAR(45) NOT NULL ,
  `Value` VARCHAR(45) NULL DEFAULT NULL ,
  PRIMARY KEY (`Name`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_type_has_detail_type` (
  `datum_type_id` INT(11) NOT NULL ,
  `detail_type_id` INT(11) NOT NULL ,
  PRIMARY KEY (`datum_type_id`, `detail_type_id`) ,
  INDEX `fk_datum_type_has_detail_type_detail_type1` (`detail_type_id` ASC) ,
  INDEX `fk_datum_type_has_detail_type_datum_type1` (`datum_type_id` ASC) ,
  CONSTRAINT `fk_datum_type_has_detail_type_datum_type1`
    FOREIGN KEY (`datum_type_id` )
    REFERENCES `eerat`.`datum_type` (`datum_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_datum_type_has_detail_type_detail_type1`
    FOREIGN KEY (`detail_type_id` )
    REFERENCES `eerat`.`detail_type` (`detail_type_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE  TABLE IF NOT EXISTS `eerat`.`datum_store` (
  `datum_id` INT(11) NOT NULL ,
  `x_vec` BLOB NULL DEFAULT NULL ,
  `erp` LONGBLOB NULL DEFAULT NULL ,
  `n_channels` SMALLINT(6) NULL DEFAULT NULL ,
  `n_samples` SMALLINT(6) NULL DEFAULT NULL ,
  `channel_labels` TEXT NULL DEFAULT NULL ,
  PRIMARY KEY (`datum_id`) ,
  CONSTRAINT `fk_datum_store_datum1`
    FOREIGN KEY (`datum_id` )
    REFERENCES `eerat`.`datum` (`datum_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;


-- -----------------------------------------------------
-- Placeholder table for view `eerat`.`datum_feature_kvps`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `eerat`.`datum_feature_kvps` (`datum_id` INT, `feature_type_id` INT, `value` INT, `b_feature_type_id` INT, `key_name` INT, `Description` INT);

-- -----------------------------------------------------
-- Placeholder table for view `eerat`.`datum_detail_kvps`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `eerat`.`datum_detail_kvps` (`datum_id` INT, `detail_type_id` INT, `value` INT, `b_detail_type_id` INT, `key_name` INT, `Description` INT, `DefaultValue` INT);

-- -----------------------------------------------------
-- Placeholder table for view `eerat`.`datum_full`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `eerat`.`datum_full` (`subj_name` INT, `type_name` INT, `span_type` INT, `Number` INT, `IsGood` INT, `StartTime` INT, `EndTime` INT, `MeetsCriteria` INT, `x_vec` INT, `erp` INT, `n_channels` INT, `n_samples` INT, `channel_labels` INT, `datum_id` INT, `subject_id` INT, `datum_type_id` INT, `store_id` INT);


USE `eerat`;

-- -----------------------------------------------------
-- View `eerat`.`datum_feature_kvps`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `eerat`.`datum_feature_kvps`;
USE `eerat`;
CREATE  OR REPLACE VIEW `eerat`.`datum_feature_kvps` AS
    SELECT a.datum_id, a.feature_type_id, a.Value value, b.feature_type_id b_feature_type_id,
            b.Name key_name, b.Description
    FROM datum_feature_value a
    INNER JOIN feature_type b ON (a.feature_type_id = b.feature_type_id);


USE `eerat`;

-- -----------------------------------------------------
-- View `eerat`.`datum_detail_kvps`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `eerat`.`datum_detail_kvps`;
USE `eerat`;
CREATE  OR REPLACE VIEW `eerat`.`datum_detail_kvps` AS
    SELECT      a.datum_id, a.detail_type_id, a.Value value,
                b.detail_type_id b_detail_type_id, b.Name key_name, b.Description, b.DefaultValue
    FROM        datum_detail_value a
    INNER JOIN  detail_type b ON (a.detail_type_id = b.detail_type_id);


USE `eerat`;

-- -----------------------------------------------------
-- View `eerat`.`datum_full`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `eerat`.`datum_full`;
USE `eerat`;
CREATE  OR REPLACE VIEW `eerat`.`datum_full` AS
    SELECT      subject.Name subj_name, datum_type.Name type_name,
                a.span_type, a.Number, a.IsGood, a.StartTime, a.EndTime, a.MeetsCriteria,
                b.x_vec, b.erp, b.n_channels, b.n_samples, b.channel_labels,
                a.datum_id, a.subject_id, a.datum_type_id, b.datum_id store_id
    FROM        datum a
    INNER JOIN  datum_store b ON (b.datum_id = a.datum_id)
    INNER JOIN  subject ON (subject.subject_id = a.subject_id)
    INNER JOIN  datum_type ON (datum_type.datum_type_id = a.datum_type_id);

DELIMITER $$

USE `eerat`$$


CREATE TRIGGER insert_datum_feature_value_for_types AFTER INSERT ON datum_type_has_feature_type
FOR EACH ROW
BEGIN
    -- Insert NULLS into datum_feature_value
    INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
        SELECT datum.datum_id, NEW.feature_type_id, NULL
        FROM datum
        WHERE datum.datum_type_id=NEW.datum_type_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER delete_datum_feature_value_for_types AFTER DELETE ON datum_type_has_feature_type
FOR EACH ROW
BEGIN
    -- Delete from datum_feature_value. Only use OLD
    DELETE FROM datum_feature_value
        WHERE datum_id=datum.datum_id
        AND datum.datum_type_id=OLD.datum_type_id
        AND datum_feature_value.feature_type_id=OLD.feature_type_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER subject_update AFTER UPDATE ON subject
FOR EACH ROW
BEGIN
    IF NEW.subject_type_id != OLD.subject_type_id THEN
        DELETE FROM subject_detail_value WHERE subject_detail_value.subject_id = NEW.subject_id AND subject_detail_value.detail_type_id NOT IN 
            (SELECT subject_type_has_detail_type.detail_type_id FROM subject_type_has_detail_type WHERE subject_type_has_detail_type.subject_type_id=NEW.subject_type_id);
        INSERT IGNORE INTO subject_detail_value (subject_id, detail_type_id, Value)
            SELECT NEW.subject_id, sthdt.detail_type_id, detail_type.DefaultValue FROM subject, subject_type_has_detail_type AS sthdt, detail_type
                WHERE sthdt.subject_type_id = NEW.subject_type_id AND detail_type.detail_type_id = sthdt.detail_type_id ORDER BY sthdt.detail_type_id;
    END IF;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER subject_insert AFTER INSERT ON subject
FOR EACH ROW
BEGIN
    INSERT IGNORE INTO subject_detail_value (subject_id, detail_type_id, Value)
        SELECT NEW.subject_id, sthdt.detail_type_id, dt.DefaultValue
        FROM subject_type_has_detail_type sthdt INNER JOIN detail_type dt ON dt.detail_type_id=sthdt.detail_type_id
        WHERE sthdt.subject_type_id = NEW.subject_type_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER datum_before BEFORE INSERT ON datum
FOR EACH ROW
BEGIN
    SET NEW.Number = (SELECT coalesce(max(Number),0)+1 FROM datum
        WHERE datum.subject_id = NEW.subject_id AND datum.datum_type_id = NEW.datum_type_id AND datum.span_type = NEW.span_type
        ORDER BY datum.Number DESC LIMIT 1);
    SET NEW.StartTime = COALESCE(NEW.StartTime, NOW());
    SET NEW.EndTime = COALESCE(NEW.EndTime, NEW.StartTime + INTERVAL 1 SECOND);
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER datum_insert AFTER INSERT ON datum
FOR EACH ROW
BEGIN
    -- But a blank store into datum_store
    INSERT IGNORE INTO datum_store (datum_id) VALUES (NEW.datum_id);
    -- Default datum_detail_values
    CALL getDetailValuesForDatumId(New.datum_id);
    -- NULLS into datum_feature_value
    INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
        SELECT NEW.datum_id, datum_type_has_feature_type.feature_type_id, NULL
        FROM datum_type_has_feature_type
        WHERE datum_type_has_feature_type.datum_type_id=NEW.datum_type_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER datum_update AFTER UPDATE ON datum
FOR EACH ROW
BEGIN
    -- If the datum type has changed
    IF NEW.datum_type_id != OLD.datum_type_id THEN
        -- then we need to delete any detail values that no longer belong to this new datum type.
        DELETE FROM datum_detail_value WHERE datum_detail_value.datum_id = NEW.datum_id AND datum_detail_value.detail_type_id NOT IN 
            (SELECT datum_type_has_detail_type.detail_type_id FROM datum_type_has_detail_type WHERE datum_type_has_detail_type.datum_type_id=NEW.datum_type_id);
        -- and insert default detail values for any new ones
        CALL getDetailValuesForDatumId(NEW.datum_id);
        -- and delete feature_values that are no longer needed.
        DELETE FROM datum_feature_value WHERE datum_feature_value.datum_id = NEW.datum_id AND datum_feature_value.feature_type_id NOT IN
            (SELECT datum_type_has_feature_type.feature_type_id FROM datum_type_has_feature_type WHERE datum_type_has_feature_type.datum_type_id=NEW.datum_type_id);
        -- and insert NULL feature_values
        INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
            SELECT NEW.datum_id, datum_type_has_feature_type.feature_type_id, NULL
            FROM datum_type_has_feature_type
            WHERE datum_type_has_feature_type.datum_type_id=NEW.datum_type_id;
    END IF;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER sthdett_insert AFTER INSERT ON subject_type_has_detail_type
FOR EACH ROW
BEGIN
    INSERT IGNORE INTO subject_detail_value (subject_id, detail_type_id, Value)
        SELECT subject.subject_id, NEW.detail_type_id, detail_type.DefaultValue FROM subject, detail_type
            WHERE subject.subject_type_id = NEW.subject_type_id AND detail_type.detail_type_id = NEW.detail_type_id ORDER BY subject.subject_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER sthdett_delete AFTER DELETE ON subject_type_has_detail_type
FOR EACH ROW
BEGIN
    DELETE FROM subject_detail_value
        WHERE subject_detail_value.subject_id=subject.subject_id
        AND subject.subject_type_id = OLD.subject_type_id
        AND subject_detail_value.detail_type_id = OLD.detail_type_id;
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER datthdett_insert AFTER INSERT ON datum_type_has_detail_type
FOR EACH ROW
BEGIN
    -- insert ignore into datum detail value
    -- Replacing this with a stored procedure so that it uses parent period's values, if available, as default.
    /*
    INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
        SELECT datum.datum_id, NEW.detail_type_id, detail_type.DefaultValue
        FROM datum, detail_type
        WHERE datum.datum_type_id = NEW.datum_type_id
        AND detail_type.detail_type_id = NEW.detail_type_id;
    */
    CALL getDetailValuesForDatumTypeAndDetailType(NEW.datum_type_id,NEW.detail_type_id);
END; $$


DELIMITER ;


DELIMITER $$

USE `eerat`$$


CREATE TRIGGER delete_datum_detail_value_for_types AFTER DELETE ON datum_type_has_detail_type
FOR EACH ROW
BEGIN
    -- Delete from datum_feature_value. Only use OLD
    DELETE FROM datum_detail_value
        WHERE datum_id=datum.datum_id
        AND datum.datum_type_id=OLD.datum_type_id
        AND datum_detail_value.detail_type_id=OLD.detail_type_id;
END; $$


DELIMITER ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
