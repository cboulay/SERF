-- These triggers were used to update datum_detail_value and datum_feature_value whenever
-- the association between datum_type and feature_type or detail_type changed.
-- However, with one schema per subject, these triggers would have to do this for each subject.
-- This is possible, with stored procedures, but it is not urgent.
DELIMITER $$

USE `eerat_settings`$$

CREATE TRIGGER datthdett_insert AFTER INSERT ON datum_type_has_detail_type
FOR EACH ROW
BEGIN
    -- When a datum type is given a new detail_type, none of the current data (including periods) will have values
    -- Thus we can insert the defaults into datum_detail_value for ALL data
    INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
        SELECT datum.datum_id, NEW.detail_type_id, detail_type.DefaultValue
        FROM datum, detail_type
        WHERE datum.datum_type_id = NEW.datum_type_id
        AND detail_type.detail_type_id = NEW.detail_type_id;
    -- CALL getDetailValuesForDatumTypeAndDetailType(NEW.datum_type_id,NEW.detail_type_id);
END; $$

CREATE TRIGGER delete_datum_detail_value_for_types AFTER DELETE ON datum_type_has_detail_type
FOR EACH ROW
BEGIN
    -- Delete from datum_feature_value. Only use OLD
    DELETE datum_detail_value FROM datum_detail_value, datum
        WHERE datum_detail_value.datum_id=datum.datum_id
        AND datum.datum_type_id=OLD.datum_type_id
        AND datum_detail_value.detail_type_id=OLD.detail_type_id;
END; $$

-- Trigger DDL Statements
DELIMITER $$

USE `eerat_settings`$$

CREATE TRIGGER insert_datum_feature_value_for_types AFTER INSERT ON datum_type_has_feature_type
FOR EACH ROW
BEGIN
    -- Insert NULLS into datum_feature_value
    INSERT IGNORE INTO datum_feature_value (datum_id, feature_type_id, Value)
        SELECT datum.datum_id, NEW.feature_type_id, NULL
        FROM datum
        WHERE datum.datum_type_id=NEW.datum_type_id;
END; $$

CREATE TRIGGER delete_datum_feature_value_for_types AFTER DELETE ON datum_type_has_feature_type
FOR EACH ROW
BEGIN
    -- Delete from datum_feature_value. Only use OLD
    DELETE datum_feature_value FROM datum_feature_value, datum
        WHERE datum_feature_value.datum_id=datum.datum_id
        AND datum.datum_type_id=OLD.datum_type_id
        AND datum_feature_value.feature_type_id=OLD.feature_type_id;
END; $$
