-- Some test data for EERAT database.
USE eerat;
DELETE FROM subject WHERE Name LIKE "CHAD_TEST";
INSERT INTO subject (subject_type_id, Name, species_type) 
	SELECT subject_type.subject_type_id, "CHAD_TEST", 2
	FROM subject_type
	WHERE subject_type.Name LIKE "BCPy_healthy";

-- Test subject creation triggers subject_detail_values. Only applicable for subject types with specific details
-- SELECT subject.Name, detail_type.Name, Value from subject INNER JOIN subject_detail_value USING (subject_id) INNER JOIN detail_type USING (detail_type_id);

-- insert a period
INSERT INTO datum (subject_id, datum_type_id, StartTime, EndTime, span_type)
	SELECT subject.subject_id, datum_type.datum_type_id, NOW(), NOW()+INTERVAL 1 MONTH, 3
	FROM subject, datum_type
	WHERE subject.Name LIKE "CHAD_TEST"
	AND datum_type.Name IN ("hr_baseline","mep_baseline","mep_hotspot");

-- check that the period has the appropriate detail values (i.e. defaults)
-- SELECT * FROM eerat.datum_detail_value;

-- adjust period values
UPDATE datum_detail_value ddv INNER JOIN detail_type dt ON (ddv.detail_type_id = dt.detail_type_id)
	SET ddv.Value='8.9'
	WHERE ddv.datum_id = 1 AND dt.Name LIKE "dat_HR_stop_ms";
	
-- insert a trial within that period.
INSERT INTO datum (subject_id, datum_type_id, StartTime, EndTime, span_type)
	SELECT subject.subject_id, datum_type.datum_type_id, NOW(), NOW()+INTERVAL 1 SECOND, 1
	FROM subject, datum_type
	WHERE subject.Name LIKE "CHAD_TEST"
	AND datum_type.Name LIKE "hr_baseline";
	
-- check that the trial has the appropriate detail values (i.e. form parent period)
SELECT (Value LIKE "8.9")
	FROM datum_detail_value ddv INNER JOIN detail_type dt ON (ddv.detail_type_id = dt.detail_type_id)
	WHERE ddv.datum_id=2 AND dt.Name LIKE "dat_HR_stop_ms";
	
DELETE FROM datum WHERE span_type==1;