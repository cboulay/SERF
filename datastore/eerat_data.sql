/*
Since I want these to be triggered, then we cannot use prepared statements.
Since I cannot use prepared statements, function names, which are determined upon request, can only be matched using CASE control.
Since we are using CASE control, I must use a proxy procedure that compares the function name to the case switch then calls the appropriate function.

If we are willing to only calculate features upon explicit request, then we use prepared statements.

http://www.mysqludf.org/participation.php
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
	DECLARE span_type, parent_id INT;
	SELECT datum.span_type INTO span_type
		FROM datum
		WHERE datum.datum_id = datum_in;
	IF span_type=3 THEN
		SET parent_id = datum_in;
	ELSE
		SELECT pdatum.datum_id INTO parent_id
			FROM datum pdatum INNER JOIN datum this_datum ON (pdatum.datum_type_id=this_datum.datum_type_id)
			WHERE pdatum.datum_type_id=this_datum.datum_type_id
			AND pdatum.subject_id=this_datum.subject_id
			AND this_datum.datum_id=datum_in
			AND pdatum.span_type=3
			AND pdatum.StartTime <= this_datum.StartTime
			AND pdatum.EndTime >= this_datum.EndTime
			AND pdatum.IsGood=1
			ORDER BY pdatum.datum_id DESC LIMIT 1;
	END IF;
	RETURN parent_id;
END $$

DROP FUNCTION IF EXISTS `getNowPeriodIdForSubjectIdDatumTypeId` $$
CREATE FUNCTION `getNowPeriodIdForSubjectIdDatumTypeId`(subject_in INT, datum_type_in INT)
RETURNS INT
BEGIN
	DECLARE datum_out INT;
    SELECT datum_id INTO datum_out
        FROM datum
        WHERE subject_id=subject_in
        AND datum_type_id=datum_type_in
        AND span_type=3
		AND NOW() BETWEEN StartTime AND EndTime
        AND IsGood=1
        ORDER BY datum_id DESC LIMIT 1;
	RETURN datum_out;
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
			SELECT datum_in, pddv.detail_type_id, pddv.Value
			FROM datum_detail_value as dddv, datum_detail_value as pddv
			WHERE pddv.datum_id = parent_id
			AND pddv.detail_type_id = dddv.detail_type_id
			ON DUPLICATE KEY UPDATE Value=pddv.Value;
	END IF;
END $$

-- Triggered by datum_type_has_detail_type. Assume bad datum_detail_values have already been deleted by trigger. This function is used to set the default detail values for any data that match this datum_type.
DROP PROCEDURE IF EXISTS `getDetailValuesForDatumTypeAndDetailType` $$
CREATE PROCEDURE `getDetailValuesForDatumTypeAndDetailType` (IN datum_type_in INT, IN detail_type_in INT)
BEGIN
	INSERT IGNORE INTO datum_detail_value (datum_id, detail_type_id, Value)
		SELECT datum.datum_id, detail_type_in, detail_type.DefaultValue
		FROM  (datum INNER JOIN datum_type_has_detail_type USING (datum_type_id)) 
			INNER JOIN detail_type USING (detail_type_id)
		WHERE datum.datum_type_id = datum_type_in AND detail_type.detail_type_id = detail_type_in;
END $$

DELIMITER ;

-- 1 `subject_type`
DELETE FROM `subject_type`;
INSERT IGNORE INTO `subject_type` (Name, Description) VALUES 
	('BCPy healthy','Control subject collected using BCPy2000'),
	('BCPy stroke','Stroke subject collected using BCPy2000'),
	('E3rat emg-eeg','Rat from emg-eeg collected using E3');
-- 2 `datum_type`.
DELETE FROM `datum_type`;
INSERT IGNORE INTO `datum_type` (Name, Description) VALUES
	('hr_baseline','Baseline H-reflex'),
	('hr_cond','Operant conditioning H-reflex'),
	('mep_baseline','Simple MEP'),
	('mep_cond','Operant conditioning MEP');
-- 3 `feature_type`
-- TODO: get rid of period-specific features. They will not be persisted.
DELETE FROM `feature_type`;
INSERT IGNORE INTO `feature_type` (Name, Description) VALUES 
	('BEMG_aaa','Avg abs amp of EMG in Background window'),
	('MR_aaa','Avg abs amp of EMG in Mresponse window'),
	('HR_aaa','Avg abs amp of EMG in Hreflex window'),
	('HR_res','H-reflex residual size'),
	('HR_thresh',''),
	('HR_thresh_err',''),
	('HR_halfmax',''),
	('HR_halfmax_err',''),
	('M_max','maximum M value in this period'),
	('MEP_aaa','Avg abs amp of EMG in MEP wind window'),
	('MEP_thresh',''),
	('MEP_thresh_err',''),
	('MEP_halfmax',''),
	('MEP_halfmax_err',''),
	('MEP_max','');
-- 4 `detail_type`
DELETE FROM `detail_type`;
INSERT IGNORE INTO `detail_type` (Name, Description, DefaultValue) VALUES 
	('subj_strain','strain, used for rats','Sprague-Dawley'),
	('subj_stroke','Primary affected site',''),
	('subj_injury_date','Date of injury',''),
	('subj_E3DB','name of E3 database',''),
	('dat_BG_start_ms','Bkgnd EMG start window in ms','-500'),
	('dat_BG_stop_ms','Bkgnd EMG stop window in ms','-1'),
	('dat_BG_chan_label','Bkgnd EMG channel_label','EDC'),
	('dat_MR_start_ms','M-response window start in ms','2'),
	('dat_MR_stop_ms','M-response window stop in ms','4'),
	('dat_MR_chan_label','M-response channel_label','EDC'),
	('dat_HR_start_ms','H-reflex window start in ms','6'),
	('dat_HR_stop_ms','H-reflex window stop in ms','9'),
	('dat_HR_chan_label','H-reflex  channel_label','EDC'),
	('dat_Nerve_stim_output','Amplitude of nerve stimulator output (units?)','0'),
	('dat_MEP_start_ms','MEP window start in ms','20'),
	('dat_MEP_stop_ms','MEP window stop in ms','30'),
	('dat_MEP_chan_label','MEP channel_label','EDC'),
	('dat_TMS_powerA','Stimulator output in percent','0'),
	('dat_TMS_powerB','Second intensity in Bistim','0'),
	('dat_TMS_ISI','TMS ISI in ms','0'),
	('dat_conditioned_feature_name','Name of feature conditioned','HR_res'),
	('dat_conditioned_result','Whether the conditioned feature was rewarded','0');
	-- Maybe I need to add subj_first, subj_last
-- 5 `subject_type_has_detail_type`
INSERT IGNORE INTO `subject_type_has_detail_type` (subject_type_id, detail_type_id)
	SELECT st.subject_type_id, dt.detail_type_id
	FROM subject_type st JOIN detail_type dt
	WHERE (st.Name LIKE "BCPy stroke" AND dt.Name IN ("subj_stroke","subj_injury_date"))
		OR (st.Name LIKE "E3rat emg-eeg" AND dt.Name IN ("subj_strain","subj_E3DB"));
-- 6 `datum_type_has_feature_type`
INSERT IGNORE INTO `datum_type_has_feature_type` (datum_type_id, feature_type_id)
	SELECT dt.datum_type_id, ft.feature_type_id
	FROM datum_type dt JOIN feature_type ft
	WHERE 	(ft.Name LIKE "BEMG%")
		OR	(dt.Name LIKE "hr%" AND ft.Name IN ("MR_aaa","HR_aaa","HR_res","HR_thresh","HR_thrsh_err","HR_halfmax","HR_halfmax_err","M_max"))
		OR 	(dt.Name LIKE "mep%" AND ft.Name IN ("MEP_aaa", "MEP_thresh", "MEP_thresh_err", "MEP_halfmax", "MEP_halfmax_err"));
-- 11 `datum_type_has_detail_type`
INSERT IGNORE INTO `datum_type_has_detail_type` (datum_type_id, detail_type_id)
	SELECT dat.datum_type_id, det.detail_type_id
	FROM datum_type dat JOIN detail_type det
	WHERE	(det.Name IN ("dat_ERP_channel_label","dat_ERP_channel_id","dat_BG_start_ms","dat_BG_stop_ms","dat_BG_chan_label"))
		OR	(dat.Name LIKE "hr_%" AND det.Name IN ("dat_MR_start_ms","dat_MR_stop_ms","dat_HR_start_ms","dat_HR_stop_ms","dat_MR_chan_label","dat_HR_chan_label","dat_Nerve_stim_output"))
		OR	(dat.Name LIKE "mep_%" AND det.Name IN ("dat_MEP_start_ms","dat_MEP_stop_ms","dat_MEP_chan_label","dat_TMS_powerA","dat_TMS_powerB","dat_TMS_ISI","dat_MEP_chan_label"))
		OR	(dat.Name LIKE "%_cond%" AND det.Name IN ("dat_conditioned_feature_name","dat_conditioned_result"));