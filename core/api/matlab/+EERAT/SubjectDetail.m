classdef SubjectDetail < EERAT.GenericDetail
    properties (Constant) %These are abstract in parent class
        table_name='subject_detail_value';
        key_names={'subject_id','detail_type_id'};
    end
    properties (Hidden=true)
        subject_id;
    end
    methods
        function obj = SubjectDetail(varargin)
            obj = obj@EERAT.GenericDetail(varargin{:});
        end
    end
end