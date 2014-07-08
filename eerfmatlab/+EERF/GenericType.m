classdef GenericType < EERF.Db_obj
    properties (Dependent = true, Transient = true)
        Name;
        Description;
    end
    methods
        function obj = GenericType(varargin)
            obj = obj@EERF.Db_obj(varargin{:});
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