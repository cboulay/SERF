classdef DatumFeature < EERF.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='datum_feature_value';
        key_names={'datum_id','feature_type_id'};
    end
    properties (Hidden=true)
        datum_id;
        feature_type_id;
    end
    properties (Dependent=true)
        feature_type;
        Value;
        Name; %Read-only
        Description; %Read-only
    end
    methods
        function obj = DatumFeature(varargin)
            obj = obj@EERF.Db_obj(varargin{:});
        end
        function value=get.Value(feature)
            value=feature.get_col_value('value');
        end
        function set.Value(feature,value)
            feature.set_col_value('value',value);
        end
        function feature_type=get.feature_type(self)
            feature_type=self.get_x_to_one('feature_type_id',...
                'FeatureType','feature_type_id');
        end
        function Name=get.Name(feature)
            stmnt = ['SELECT name FROM feature_type WHERE feature_type_id=',num2str(feature.feature_type_id)];
            mo=feature.dbx.statement(stmnt);
            Name=mo.Name{1};
        end
        function Description=get.Description(feature)
            stmnt = ['SELECT description FROM feature_type WHERE feature_type_id=',num2str(feature.feature_type_id)];
            mo=feature.dbx.statement(stmnt);
            Description=mo.Description{1};
        end
    end
end