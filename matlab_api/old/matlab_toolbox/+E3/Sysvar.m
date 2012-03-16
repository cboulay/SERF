classdef Sysvar < E3.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='default_variables';
        key_names={'Name'};
    end
    properties (Transient)
        Name;
        Value;
        Description;
    end
    methods (Static)
        function array=get_obj_array(e3dbx)
            array=get_obj_array@E3.Db_obj(e3dbx,'Sysvar');
        end
    end
    methods
        function obj = Sysvar(name,e3dbx)
            if nargin < 2
                e3dbx=E3.Dbmym('e3analysis');
            end
            if nargin < 1
                name = {''};
            end
            obj = obj@E3.Db_obj({'Name',name},e3dbx);
        end
        function value=get.Value(obj)
            value=obj.get_col_value('Value');
        end
        function set.Value(obj,value)
            obj.set_col_value('Value',value);
        end
        function description=get.Description(obj)
            description=obj.get_col_value('Description');
        end
        function set.Description(obj,description)
            obj.set_col_value('Description',description);
        end
    end
end