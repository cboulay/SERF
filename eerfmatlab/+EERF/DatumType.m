classdef DatumType < EERF.GenericType
    properties (Constant) %These are abstract in parent class
        table_name='datum_type';
        key_names={'datum_type_id'};
    end
    properties (Hidden=true)
        datum_type_id;
    end
    properties
        detail_types
        feature_types
        TrialClass
    end
    methods
        function obj = DatumType(varargin)
            obj = obj@EERF.GenericType(varargin{:});
        end
        function detail_types=get.detail_types(self)
            detail_types=self.get_many_to_many('datum_type_has_detail_type',...
                'datum_type_id','datum_type_id','detail_type_id','detail_type_id','DetailType');
        end
        function set.detail_types(self,detail_types)
            self.set_many_to_many(detail_types,'datum_type_has_detail_type',...
                'datum_type_id','datum_type_id','detail_type_id','detail_type_id');
        end
        function feature_types=get.feature_types(self)
            feature_types=self.get_many_to_many('datum_type_has_feature_type',...
                'datum_type_id','datum_type_id','feature_type_id','feature_type_id','FeatureType');
        end
        function set.feature_types(self,feature_types)
            self.set_many_to_many(feature_types,'datum_type_has_feature_type',...
                'datum_type_id','datum_type_id','feature_type_id','feature_type_id');
        end
        function TrialClass=get.TrialClass(obj)
            TrialClass=obj.get_col_value('TrialClass');
        end
        function set.TrialClass(obj,TrialClass)
            obj.set_col_value('TrialClass',TrialClass);
        end
    end
end