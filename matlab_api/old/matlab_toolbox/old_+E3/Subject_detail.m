classdef Subject_detail < E3.Subject_property_array
    properties (Constant = true, Hidden = true)
        table_name='subject_detail';
        other_ind_name='subject_detail_type_id';
    end
    properties (Hidden = true)
        subject_detail_type_id
    end
    properties (Dependent = true)
        Name
        Value
    end
    methods (Static = true)
        function detail_array=get_property_array_for_subject(ani)
            detail_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Subject_detail');
            %Subject_details can only be created by a GUI. Make sure to set
            %subject_id and subject_detail_type_id before setting Value.
        end
    end
    methods
        function value=get.Name(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT Name FROM `e3analysis`.`subject_detail_type` WHERE id={Si}',obj.subject_detail_type_id);
            %mym(cid,'close');
            value=mo.Name{1};
        end
        function value = get.subject_detail_type_id(obj)
            value = obj.other_ind_value;
        end
        function set.subject_detail_type_id(obj,value)
            obj.other_ind_value=value;
        end
        function value = get.Value(obj)
            value=obj.get_property('Value','string');
        end
        function set.Value(obj,value)
            obj.set_property('Value',value,'string');
        end
    end
end