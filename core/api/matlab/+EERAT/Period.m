classdef Period < EERAT.Datum
    properties (Dependent = true, Transient = true)
        trials;
    end
    methods
        function self = Period(varargin)
            self = self@EERAT.Datum(varargin);
        end
        function trials = get.trials(self)
            %Since I have not implemented span_type="day", the only
            %possible children are trials, thus I can use the parent class
            %method.
            trials=self.get_many_to_many('datum_has_datum',...
                'parent_datum_id','datum_id','child_datum_id','datum_id','Trial');
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
        
        function set_trials_features(self,feature_names,feature_matrix)
            trial_id=[self.trials.datum_id];
            %TODO: Throw an error if trial_id length ~= feature_matrix
            %length.
            stmnt=['UPDATE datum_feature_value,feature_type SET ',...
                'datum_feature_value.Value={S4} WHERE ',...
                'datum_feature_value.datum_id={Si} AND ',...
                'datum_feature_value.feature_type_id=feature_type.feature_type_id AND ',...
                'feature_type.Name LIKE "{S}"'];
            self.dbx.statement('BEGIN');
            for ff=1:size(feature_matrix,2)
                feature_name=feature_names{ff};
                for tt=1:size(feature_matrix,1)
                    self.dbx.statement(stmnt,{feature_matrix(tt,ff),...
                        trial_id(tt),feature_name});
                end
            end
            self.dbx.statement('COMMIT');
        end
        function set_trials_details(self,detail_names,detail_matrix)
            trial_id=[self.trials.datum_id];
            %TODO: Throw an error if trial_id length ~= feature_matrix
            %length.
            stmnt=['UPDATE datum_detail_value,detail_type SET ',...
                'datum_detail_value.Value="{S}" WHERE ',...
                'datum_detail_value.datum_id={Si} AND ',...
                'datum_detail_value.detail_type_id=detail_type.detail_type_id AND ',...
                'detail_type.Name LIKE "{S}"'];
            self.dbx.statement('BEGIN');
            for dd=1:size(detail_matrix,2)
                detail_name=detail_names{dd};
                for tt=1:size(detail_matrix,1)
                    if isnumeric(detail_matrix(tt,dd))
                        detail_value=num2str(detail_matrix(tt,dd));
                    else
                        detail_value=detail_matrix(tt,dd);
                    end
                    self.dbx.statement(stmnt,{detail_value,trial_id(tt),detail_name});
                end
            end
            self.dbx.statement('COMMIT');
        end
    end
end