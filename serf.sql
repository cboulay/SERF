delimiter |
CREATE TRIGGER sdv_aft_ins AFTER INSERT ON subject_detail_value
FOR EACH ROW
BEGIN
	SELECT datum.number INTO @dnum
        FROM datum
        WHERE datum.subject_id = NEW.subject_id
        ORDER BY datum.number DESC LIMIT 1;
	SELECT COALESCE(@dnum, COUNT(@dnum)) INTO @dnum;
	SELECT detail_type.name INTO @dtname FROM detail_type
	    WHERE detail_type.detail_type_id = NEW.detail_type_id;
    INSERT INTO subject_log (subject_id, time, entry)
        SELECT NEW.subject_id, NOW(), CONCAT('Detail_value ', @dtname, ' set to ', COALESCE(NEW.value, 'EMPTY'), ' after trial ', @dnum);
END;
|
CREATE TRIGGER sdv_aft_upd AFTER UPDATE ON subject_detail_value
FOR EACH ROW
BEGIN
    IF NEW.value NOT LIKE OLD.value AND NEW.value IS NOT NULL THEN
        SELECT COALESCE(datum.number, 0) INTO @dnum
            FROM datum
            WHERE datum.subject_id = NEW.subject_id
            ORDER BY datum.number DESC LIMIT 1;
        SELECT detail_type.name INTO @dtname
            FROM detail_type
            WHERE detail_type.detail_type_id = NEW.detail_type_id;
        INSERT INTO subject_log (subject_id, time, entry)
            SELECT NEW.subject_id, NOW(), CONCAT('Detail_value ', @dtname, ' changed to ', NEW.value, ' after trial ', @dnum);
    END IF;
END;
|
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
CREATE TRIGGER sl_bef_ins BEFORE INSERT ON subject_log
    FOR EACH ROW
    SET NEW.time = COALESCE(NEW.time, NOW());