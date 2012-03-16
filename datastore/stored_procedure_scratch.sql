/*
Since I want these to be triggered, then we cannot use prepared statements.
Since I cannot use prepared statements, function names, which are determined upon request, can only be matched using CASE control.
Since we are using CASE control, I must use a proxy procedure that compares the function name to the case switch then calls the appropriate function.

If we are willing to only calculate features upon explicit request, then we use prepared statements.
*/
DELIMITER $$
/*
HELPER PROCEDURES AND FUNCTIONS FOR EERAT
*/
-- Helper function to get the parent period id of a datum. This could easily be a function instead of a procedure.
DROP FUNCTION IF EXISTS `getParentPeriodIdForDatumId` $$
CREATE FUNCTION `getParentPeriodIdForDatumId`(datum_in INT)
RETURNS INT
BEGIN
	DECLARE is_period, is_day BOOLEAN;
	DECLARE parent_id INT;
	SELECT COUNT(*)>0 INTO is_period
		FROM period INNER JOIN datum USING (datum_id)
		WHERE datum.datum_id = datum_in;
	IF is_period THEN
		SET parent_id = datum_in;
	ELSE
		SELECT COUNT(*)>0 INTO is_day
			FROM day WHERE day.datum_id = datum_in;
		IF is_day THEN
			SELECT period.datum_id INTO parent_id
				FROM period, datum as pdatum, day, datum as ddatum
				WHERE day.datum_id = datum_in AND ddatum.datum_id = day.datum_id
				AND pdatum.subject_id=ddatum.subject_id
				AND period.StartTime <= day.Date AND period.EndTime >= day.Date
				ORDER BY period.datum_id LIMIT 1;
		ELSE
			SELECT period.datum_id INTO parent_id
				FROM period, datum as pdatum, trial, datum as tdatum
				WHERE trial.datum_id = datum_in AND tdatum.datum_id = trial.datum_id
				AND pdatum.subject_id = tdatum.subject_id
				AND period.StartTime <= trial.Time AND period.EndTime >= trial.Time
				ORDER BY period.datum_id LIMIT 1;
		END IF;
	END IF;
	RETURN parent_id;
END $$

/*
SPECIFIC FEATURE FUNCTIONS. DON'T FORGET TO UPDATE THE CASE IN callFeatureFunc
AFTER FINISHING YOUR FEATURE FUNCTION.
*/
-- Average absolute value
DROP FUNCTION IF EXISTS `aaa_func` $$
CREATE FUNCTION `aaa_func`(datum_in INT, feature_type_in INT)
RETURNS FLOAT
READS SQL DATA
BEGIN
	DECLARE aaa FLOAT;
	SELECT AVG(ABS(evoked.uV)) INTO aaa
		FROM evoked,
			(SELECT ddv1.Value AS chan_id, ROUND(ddv2.Value,0) AS t1_ms, ROUND(1000.0*(ddv2.Value%1),0) AS t1_us, ROUND(ddv3.Value,0) AS t2_ms, ROUND(1000.0*(ddv3.Value%1),0) AS t2_us
				FROM (datum_detail_value AS ddv1 INNER JOIN feature_type_has_detail_type AS fthdt1 USING (detail_type_id)),
					(datum_detail_value AS ddv2 INNER JOIN feature_type_has_detail_type AS fthdt2 USING (detail_type_id)),
					(datum_detail_value AS ddv3 INNER JOIN feature_type_has_detail_type AS fthdt3 USING (detail_type_id))
				WHERE ddv1.datum_id = getParentPeriodIdForDatumId(datum_in)
					AND ddv2.datum_id = ddv1.datum_id AND ddv3.datum_id = ddv1.datum_id
					AND fthdt1.argument_order = 1
					AND fthdt2.argument_order = 2
					AND fthdt3.argument_order = 3) AS xxx
		WHERE
			evoked.datum_id = datum_in AND
			evoked.channel_id = xxx.chan_id AND
			((evoked.t_ms = xxx.t1_ms AND evoked.t_us >= xxx.t1_us) OR evoked.t_ms > xxx.t1_ms) AND
			((evoked.t_ms = xxx.t2_ms AND evoked.t_us <= xxx.t2_us) OR evoked.t_ms < xxx.t2_ms)
		GROUP BY evoked.datum_id;
	RETURN aaa;
END $$

/*
PROCEDURES AND FUNCTIONS TO CALL FEATURE FUNCTION PROXY.
*/
-- The Proxy to get feature_function name then calls that function
-- The first argument can be a datum_type_id or a dataum_id, according the the 3rd argument flag.
-- If it is a datum_type_id, then this proxy will call the feature function for all eligible rows.
-- If it is a datum_id, then this proxy will call the feature function for that single row.
DROP PROCEDURE IF EXISTS `callFeatureFunc` $$
CREATE PROCEDURE `callFeatureFunc`(IN datum_in INT, IN feature_type_in INT, IN is_type BOOLEAN)
BEGIN
	-- DECLARE variables
	DECLARE sp_name VARCHAR(255);	
	-- construct the feature function statement
	SELECT feature_function.Name INTO sp_name
		FROM feature_function INNER JOIN feature_type USING (feature_function_id)
		WHERE feature_type.feature_type_id = feature_type_in;
		
	CASE sp_name
		WHEN 'aaa_func' THEN
			IF is_type THEN
				INSERT INTO datum_feature_value (datum_id, feature_type_id, Value) 
					SELECT datum.datum_id, feature_type_in, @aaa = aaa_func(datum.datum_id, feature_type_in)
					FROM datum
					WHERE datum.datum_type_id = datum_in
					ON DUPLICATE KEY UPDATE Value=@aaa;
			ELSE
				INSERT INTO datum_feature_value (datum_id, feature_type_id, Value) 
					SELECT datum_in, feature_type_in, @aaa = aaa_func(datum_in, feature_type_in)
					ON DUPLICATE KEY UPDATE Value=@aaa;
			END IF;
	END CASE;
END $$
-- Triggered with entry of a new datum, all we know is the trial id. Get all associated feature_type_ids then call the function proxy for each feature_type_id
DROP PROCEDURE IF EXISTS `calcFeatureValuesForDatumId` $$
CREATE PROCEDURE `calcFeatureValuesForDatumId` (IN datum_in INT)
BEGIN
	DECLARE this_feature_type_id INT;
	DECLARE no_more_rows BOOLEAN;
	DECLARE cur1 CURSOR FOR
		SELECT datum_type_has_feature_type.feature_type_id
			FROM datum_type_has_feature_type INNER JOIN datum USING (datum_type_id)
			WHERE datum.datum_id = datum_in;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = True;
	OPEN cur1;
	SET no_more_rows = False;
	the_loop: LOOP
		FETCH cur1 INTO this_feature_type_id;
		IF no_more_rows THEN
			CLOSE cur1;
			LEAVE the_loop;
		END IF;
		CALL callFeatureFunc(datum_in, this_feature_type_id, False);
	END LOOP the_loop;
END $$
-- Triggered after feature_type_has_detail_type is updated. Find all datum types for this feature then call the proxy for each datum type
DROP PROCEDURE IF EXISTS `callFeatureFuncForFeatureType` $$
CREATE PROCEDURE `callFeatureFuncForFeatureType`(IN feature_type_in INT)
BEGIN
	DECLARE this_datum_type_id INT;
	DECLARE no_more_rows BOOLEAN;
	DECLARE cur1 CURSOR FOR
		SELECT datum_type_has_feature_type.datum_type_id
			FROM datum_type_has_feature_type
			WHERE datum_type_has_feature_type.feature_type_id = feature_type_in;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = True;
	OPEN cur1;
	SET no_more_rows = False;
	the_loop: LOOP
		FETCH cur1 INTO this_datum_type_id;
		IF no_more_rows THEN
			CLOSE cur1;
			LEAVE the_loop;
		END IF;
		CALL callFeatureFunc(this_datum_type_id, feature_type_in, True);
	END LOOP the_loop;
END $$

/*
STORED PROCEDURES TO UPDATE DETAIL VALUES WHEN TRIGGERED
*/
-- Get a datum's datum_detail_values from parent period if it exists. This is triggered after datum entry.
-- This calls a stored function for every trial. Might be slow.
DROP PROCEDURE IF EXISTS `getDetailValuesForDatumId` $$
CREATE PROCEDURE `getDetailValuesForDatumId` (IN datum_in INT)
BEGIN
	DECLARE parent_id INT;
	-- Get the defaults.
	INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
		SELECT datum.datum_id, dthdt.detail_type_id, detail_type.DefaultValue
		FROM (datum INNER JOIN datum_type_has_detail_type AS dthdt USING (datum_type_id))
			INNER JOIN detail_type USING (detail_type_id)
		WHERE datum.datum_id = datum_in
		ORDER BY datum.datum_type_id, datum.datum_id, detail_type.detail_type_id;

	SET parent_id=getParentPeriodIdForDatumId(datum_in);
	IF datum_in != parent_id THEN
		-- Overwrite the defaults with any details the parent might have.
		INSERT INTO datum_detail_value (datum_id, detail_type_id, Value)
			SELECT dddv.datum_id, pddv.detail_type_id, pddv.Value as perVal
			FROM datum_detail_value as dddv, datum_detail_value as pddv
			WHERE pddv.datum_id = parent_id
			AND pddv.detail_type_id = dddv.detail_type_id
			AND dddv.datum_id = datum_in
			ON DUPLICATE KEY UPDATE Value=perVal;
	END IF;
END $$

-- Get datum_detail_values from parent period for a given datum_type and detail_type. Triggered by datum_type_has_detail_type
DROP PROCEDURE IF EXISTS `getDetailValuesForDatumTypeAndDetailType` $$
CREATE PROCEDURE `getDetailValuesForDatumTypeAndDetailType` (IN datum_type_in INT, IN detail_type_in INT)
BEGIN
	-- Set the defaults.
	INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
		SELECT datum.datum_id, detail_type_in, detail_type.DefaultValue
		FROM (datum INNER JOIN datum_type_has_detail_type USING (datum_type_id)) INNER JOIN detail_type USING (detail_type_id)
		WHERE datum.datum_type_id = datum_type_in AND detail_type.detail_type_id = detail_type_in;

	-- Use parent's ddv when available.
	INSERT INTO datum_detail_value (datum_id, detail_type_id, Value)
		SELECT datum.datum_id, p_ddv.detail_type_id, p_ddv.Value
		FROM datum, datum_detail_value as d_ddv, datum_detail_value as p_ddv
		WHERE d_ddv.detail_type_id = p_ddv.detail_type_id
		AND p_ddv.datum_id = getParentPeriodIdForDatumId(datum.datum_id)
		AND datum.datum_type_id = datum_type_in
		AND p_ddv.detail_type_id = detail_type_in
		ON DUPLICATE KEY UPDATE Value=p_ddv.Value;
END $$

DELIMITER ;

/*
-- DEPRECATED PROCEDURES


-- Simple procedure to return the argument list for a given datum, feature_type
DROP PROCEDURE IF EXISTS `getArgumentListAsCSV` $$
CREATE PROCEDURE `getArgumentListAsCSV`(IN datum_in INT, IN feature_type_in INT, OUT arglist VARCHAR(255))
BEGIN
	-- DECLARE
	DECLARE detail_value_holder INT;
	CALL getDetailValueHolderForDatumIdAndFeatureTypeId(datum_in, feature_type_in, detail_value_holder);
	
	SELECT GROUP_CONCAT(datum_detail_value.Value) INTO arglist
			FROM datum_detail_value INNER JOIN feature_type_has_detail_type USING (detail_type_id)
			WHERE datum_detail_value.datum_id = detail_value_holder
			AND feature_type_has_detail_type.feature_type_id = feature_type_in
			ORDER BY feature_type_has_detail_type.argument_order ASC;
END$$
*/