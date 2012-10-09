DROP TRIGGER IF EXISTS sdv_aft_ins;
CREATE TRIGGER sdv_aft_ins AFTER INSERT ON subject_detail_value
FOR EACH ROW
BEGIN
	SELECT COALESCE(datum.number, 0) INTO @dnum
	FROM datum
	WHERE datum.subject_id = NEW.subject_id
	ORDER BY datum.number DESC LIMIT 1;
	SELECT detail_type.name INTO @dtname
	FROM detail_type
	WHERE detail_type.detail_type_id = NEW.detail_type_id;
	INSERT INTO subject_log (subject_id, time, entry)
		SELECT NEW.subject_id, NOW(), CONCAT('Detail_value ', @dtname, ' set to ', COALESCE(NEW.value, 'EMPTY'), ' after trial ', @dnum);
END;
DROP TRIGGER IF EXISTS sdv_aft_upd;
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
INSERT INTO subject_detail_value (subject_id, detail_type_id, value) VALUES (1, 4, '20.0'), (1, 5, '30.0');