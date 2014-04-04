delimiter | --
--
CREATE TRIGGER datum_before BEFORE INSERT ON datum
FOR EACH ROW
BEGIN
    SET NEW.start_time = COALESCE(NEW.start_time, NOW());
    -- TODO: Make this next function smart enough to pick the next smallest free number based on start_time
    IF NEW.number IS NULL OR NEW.number = 0 THEN
        SET NEW.number = (SELECT coalesce(max(number),0)+1 FROM datum
            WHERE datum.subject_id = NEW.subject_id AND datum.span_type = NEW.span_type
            ORDER BY datum.number DESC LIMIT 1);
    END IF;
    IF NEW.span_type = 'trial' THEN
        -- If a stop_time was not specified, make the trial duration 1 second.
        SET NEW.stop_time = COALESCE(NEW.stop_time, NEW.start_time + INTERVAL 1 SECOND);
    END IF;
    IF NEW.span_type = 'period' THEN
        -- Default period duration is 1 hr.
        SET NEW.stop_time = COALESCE(NEW.stop_time, NEW.start_time + INTERVAL 1 HOUR);
    END IF;
END;
|
delimiter ;
ALTER TABLE datum MODIFY COLUMN number integer UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE datum MODIFY COLUMN is_good bool NOT NULL DEFAULT 1;
-- ALTER TABLE datum MODIFY COLUMN span_type ENUM('trial','day','period') NOT NULL DEFAULT 'trial';
-- ALTER TABLE datum MODIFY COLUMN span_type smallint UNSIGNED NOT NULL DEFAULT '1';
INSERT INTO datum (subject_id, span_type) VALUES (1, 3), (1, 1);
INSERT INTO datum_has_datum (from_datum_id, to_datum_id) VALUES (1,2);