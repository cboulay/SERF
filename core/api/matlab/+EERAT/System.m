classdef System < EERAT.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='system';
        key_names={'Name'};
    end
    properties (Transient)
        Name;
        Value;
    end
    methods
        function obj = System(varargin)
            obj = obj@EERAT.Db_obj(varargin{:});
        end
        function value=get.Value(obj)
            value=obj.get_col_value('Value');
        end
        function set.Value(obj,value)
            obj.set_col_value('Value',value);
        end
    end
end