DROP TRIGGER IF EXISTS ddv_aft_ins;
CREATE TRIGGER ddv_aft_ins AFTER INSERT ON datum_detail_value
FOR EACH ROW
BEGIN
	SELECT datum.number, datum.span_type, datum.subject_id INTO @dnum, @dspan, @dsub
	FROM datum
	WHERE datum.datum_id = NEW.datum_id;
	IF @dspan LIKE 'period' THEN
		SELECT detail_type.name INTO @dtname
		FROM detail_type
		WHERE detail_type.detail_type_id = NEW.detail_type_id;
		
		INSERT INTO subject_log (subject_id, time, entry)
			SELECT @dsub, NOW(), CONCAT('Detail_value for period ', @dnum, ' ', @dtname, ' set to ', NEW.value);
	END IF;
END;
DROP TRIGGER IF EXISTS ddv_aft_upd;
CREATE TRIGGER ddv_aft_upd AFTER UPDATE ON datum_detail_value
FOR EACH ROW
BEGIN
	IF NEW.value NOT LIKE OLD.value AND NEW.value IS NOT NULL THEN
		SELECT datum.number, datum.span_type, datum.subject_id INTO @dnum, @dspan, @dsub
		FROM datum
		WHERE datum.datum_id = NEW.datum_id;
		IF @dspan LIKE 'period' THEN
			SELECT detail_type.name INTO @dtname
			FROM detail_type
			WHERE detail_type.detail_type_id = NEW.detail_type_id;
			
			INSERT INTO subject_log (subject_id, time, entry)
				SELECT @dsub, NOW(), CONCAT('Detail_value for period ', @dnum, ' ', @dtname, ' changed to ', NEW.value);
		END IF;
	END IF;
END;

INSERT INTO datum_detail_value (datum_id, detail_type_id, value) VALUES (2, 4, '20.0'), (2, 5, '30.0');