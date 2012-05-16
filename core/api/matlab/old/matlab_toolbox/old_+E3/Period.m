classdef Period < E3.Datum
    properties (Constant)
        table_name='period';
        other_ind_name='period_type_id';
        feature_table_name='period_feature_value';
    end
    properties (Dependent = true)
        Name %getter only.
        StartTime %'YYYY-MM-DD'
        EndTime %'YYYY-MM-DD'
    end
    properties (Dependent = true, Hidden = true)
        period_type_id
    end
    methods (Static = true)
        function per_array=get_property_array_for_subject(ani)
            per_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Period');
            %Periods can only be created by GUIs or command-line.
            %Creation must first set subject_id and period_type_id before setting
            %any other values.
        end
    end
    methods
        function value = get.Name(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT Name FROM `e3analysis`.`period_type` WHERE id={Si}',obj.period_type_id);
            %mym(cid,'close');
            value=mo.Name{1};
        end
        function value = get.period_type_id(obj)
            value = obj.other_ind_value;
        end
        function set.period_type_id(obj,value)
            obj.other_ind_value=value;
        end
        function value = get.StartTime(obj)
            value=obj.get_property('StartTime','datetime');
        end
        function set.StartTime(obj,value)
            obj.set_property('StartTime',value,'datetime');
        end
        function value = get.EndTime(obj)
            value=obj.get_property('EndTime','datetime');
        end
        function set.EndTime(obj,value)
            obj.set_property('EndTime',value,'datetime');
        end
    end
end