classdef SubjectType < EERAT.GenericType
    properties (Constant) %These are abstract in parent class
        table_name='subject_type';
        key_names={'subject_type_id'};
    end
    properties (Hidden=true)
        subject_type_id;
    end
    properties (Dependent = true, Transient = true)
        detail_types;
    end
    methods
        function obj = SubjectType(varargin)
            obj = obj@EERAT.GenericType(varargin);
        end
        function detail_types=get.detail_types(self)
            detail_types=self.get_many_to_many('subject_type_has_detail_type',...
                'subject_type_id','subject_type_id','detail_type_id','detail_type_id','DetailType');
        end
        function set.detail_types(self,detail_types)
            self.set_many_to_many(detail_types,'subject_type_has_detail_type',...
                'subject_type_id','subject_type_id','detail_type_id','detail_type_id');
        end
    end
end