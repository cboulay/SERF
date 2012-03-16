classdef Analysis < E3.Function_db_object
    properties (Transient = true, Hidden=true, Constant = true)
        table_name = 'analysis';
    end
    methods (Static = true)
        function array=get_obj_array
            array=get_obj_array@E3.Named_db_object('Analysis');
        end
    end
    methods
        function obj=Analysis(name)
            if nargin>0
                obj.Name=name;
            end
        end
    end
end