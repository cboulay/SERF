classdef FeatureType < EERAT.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='feature_type';
        key_names={'feature_type_id'};
    end
    properties
        feature_type_id;
    end
    properties (Dependent = true, Transient = true)
        Name;
        Description;
    end
    methods
        function obj = FeatureType(varargin)
            obj = obj@EERAT.Db_obj(varargin{:});
        end
        function Name=get.Name(obj)
            Name=obj.get_col_value('Name');
        end
        function set.Name(obj,Name)
            obj.set_col_value('Name',Name);
        end
        function Description=get.Description(obj)
            Description=obj.get_col_value('Description');
        end
        function set.Description(obj,Description)
            obj.set_col_value('Description',Description);
        end
    end
end