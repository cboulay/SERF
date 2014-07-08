classdef Period < EERF.Datum
    properties (Dependent = true, Transient = true)
        trials
    end
%     properties (Hidden = true)
%         trial_class = 'Trial'; %Saved to disk.
%     end
    methods
        function period = Period(varargin)
            period = period@EERF.Datum(varargin{:});
        end
        function trials = get.trials(period)
            %Since I have not implemented span_type="day", the only
            %possible children are trials, thus I can use the parent class
            %method.
            stmnt = sprintf(['SELECT datum_id FROM datum WHERE subject_id={Si} '...
                'AND span_type=''trial'' AND start_time>=''%s'' AND stop_time<=''%s'''], period.StartTime, period.StopTime);
            mo = period.dbx.statement(stmnt, {period.subject.subject_id});
            n_trials = length(mo.datum_id);
            if n_trials>0
                trials(n_trials) = EERF.Trial(period.dbx);
                trial_ids = num2cell(mo.datum_id);
                [trials(:).datum_id] = trial_ids{:};
            else
                trials = [];
            end
        end
        
        %The following functions are provided for convenience to speed up
        %the retrieval of data and features without requiring each trial to
        %retrieve it by itself.
        %TODO: Modify this so that it retrieves as many features as
        %feature_names provided.
        function varargout=get_trials_features(period,feature_name)
            %It is important to use a left join so that all trials get a
            %return value, even if null, otherwise period.trials and
            %period.get_trials_features won't match up.
            stmnt = ['SELECT datum_has_datum.child_datum_id, datum_feature_value.Value, feature_type.Name ',...
                'FROM datum_has_datum, datum_feature_value, feature_type ',...
                'WHERE datum_has_datum.parent_datum_id=',num2str(period.datum_id),...
                ' AND feature_type.Name LIKE "',feature_name,...
                '" AND datum_feature_value.datum_id=datum_has_datum.child_datum_id',...
                ' AND datum_feature_value.feature_type_id=feature_type.feature_type_id'];
%                 'FROM ((datum_has_datum LEFT JOIN datum_feature_value ON datum_feature_value.datum_id=datum_has_datum.child_datum_id) ',...
%                 'INNER JOIN feature_type ON datum_feature_value.feature_type_id=feature_type.feature_type_id) ',...
%                 'WHERE datum_has_datum.parent_datum_id=',num2str(period.datum_id),...
%                 ' AND feature_type.Name LIKE "',feature_name,'"'];
            mo=period.dbx.statement(stmnt);
            varargout{1}=mo.Value;
            if nargout>1
                varargout{2}=mo.child_datum_id;
            end
            if nargout>2
                varargout{3}=mo.Name;
            end
        end
        function varargout=get_trials_details(period,detail_name)
            %It is important to use a left join so that all trials get a
            %return value, even if null, otherwise period.trials and
            %period.get_trials_features won't match up.
            stmnt = ['SELECT datum_has_datum.child_datum_id, datum_detail_value.Value, detail_type.Name ',...
                'FROM (datum_has_datum LEFT JOIN datum_detail_value ON datum_detail_value.datum_id=datum_has_datum.child_datum_id) ',...
                'LEFT JOIN detail_type ON datum_detail_value.detail_type_id=detail_type.detail_type_id ',...
                'WHERE datum_has_datum.parent_datum_id=',num2str(period.datum_id),...
                ' AND detail_type.Name LIKE "',detail_name,'"'];
            mo=period.dbx.statement(stmnt);
            varargout{1}=mo.Value;
            if nargout>1
                varargout{2}=mo.child_datum_id;
            end
            if nargout>2
                varargout{3}=mo.Name;
            end
        end
        
        function set_trials_features(period,feature_names,feature_matrix)
            trial_id=[period.trials.datum_id];
            %TODO: Throw an error if trial_id length ~= feature_matrix
            %length.
            name_stmnt = 'SELECT feature_type_id FROM feature_type WHERE Name LIKE "{S}"';
            val_stmnt = 'UPDATE datum_feature_value SET Value={S4} WHERE datum_id={Si} AND feature_type_id={Si}';
            for ff=1:size(feature_matrix,2)
                %Get the feature_type_id
                mo = period.dbx.statement(name_stmnt,feature_names(ff));
                ft_id = mo.feature_type_id;
                period.dbx.statement('BEGIN');
                for tt=1:size(feature_matrix,1)
                    fval = feature_matrix(tt,ff);
                    if ~isnan(fval) %submitting a nan value really screws things up.
                        period.dbx.statement(val_stmnt,{fval,trial_id(tt),ft_id});
                    end
                end
                period.dbx.statement('COMMIT');
            end
            
        end
        function set_trials_details(period,detail_names,detail_matrix)
            trial_id=[period.trials.datum_id];
            %TODO: Throw an error if trial_id length ~= feature_matrix
            %length.
            name_stmnt = 'SELECT detail_type_id FROM detail_type WHERE Name LIKE "{S}"';
            val_stmnt = 'UPDATE datum_detail_value SET Value="{S}" WHERE datum_id={Si} AND detail_type_id={Si}';
            for dd=1:size(detail_matrix,2)
                mo = period.dbx.statement(name_stmnt,detail_names(dd));
                dt_id = mo.detail_type_id;
                period.dbx.statement('BEGIN');
                for tt=1:size(detail_matrix,1)
                    if isnumeric(detail_matrix(tt,dd)) && ~isnan(detail_matrix(tt,dd))
                        detail_value=num2str(detail_matrix(tt,dd));
                    elseif iscell(detail_matrix(tt,dd))
                        detail_value = detail_matrix{tt,dd};
                    else
                        detail_value=detail_matrix(tt,dd);
                    end
                    if ischar(detail_value) || ~isnan(detail_value)
                        period.dbx.statement(val_stmnt,{detail_value,trial_id(tt),dt_id});
                    end
                end
                period.dbx.statement('COMMIT');
            end
        end
    end
end