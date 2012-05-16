classdef Subject_detail_type < E3.Named_db_object
    properties (Transient = true, Hidden=true, Constant = true)
        table_name = 'subject_detail_type';
    end
    methods (Static = true)
        function array=get_obj_array
            array=get_obj_array@E3.Named_db_object('Subject_detail_type');
        end
    end
    methods
        function obj=Subject_detail_type(name)
            if nargin>0
                obj.Name=name;
            end
        end
    end
end