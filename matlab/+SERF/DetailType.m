classdef DetailType < EERF.GenericType
    properties (Constant) %These are abstract in parent class
        table_name='detail_type';
        key_names={'detail_type_id'};
    end
    properties
        detail_type_id;
    end
    properties (Dependent = true, Transient = true)
        DefaultValue;
    end
    methods
        function obj = DetailType(varargin)
            obj = obj@EERF.GenericType(varargin{:});
        end
        function DefaultValue=get.DefaultValue(obj)
            DefaultValue=obj.get_col_value('DefaultValue');
        end
        function set.DefaultValue(obj,DefaultValue)
            obj.set_col_value('DefaultValue',DefaultValue);
        end
    end
end