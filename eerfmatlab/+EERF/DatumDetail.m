classdef DatumDetail < EERF.GenericDetail
    properties (Constant) %These are abstract in parent class
        table_name = 'datum_detail_value';
        key_names = {'datum_id','detail_type_id'};
    end
    properties (Hidden=true)
        datum_id;
    end
    methods
        function obj = DatumDetail(varargin)
            obj = obj@EERF.GenericDetail(varargin{:});
        end
    end
end