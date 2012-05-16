classdef Channel < E3.Subject_property_array
    properties (Dependent = true)
        Number
        IsGood = true;
        IsRectified = true;
        IsInverted = false;
        ADRange = 5;
        ADBits = 12;
        TotalAmplification = 1000;
        MRStartms
        MRStopms
        HRStartms
        HRStopms
        RewardLow
        RewardHigh
        ad2uv
        Name
    end
    properties (Constant = true, Hidden = true)
        table_name='channel';
        other_ind_name='Number';
    end
    methods (Static = true)
        function chan_array=get_property_array_for_subject(ani)
            chan_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Channel');
        end
    end
    methods
        function value = get.ad2uv(obj)
            value=(1000000/obj.TotalAmplification)*((2*obj.ADRange)/(2^obj.ADBits));
            if obj.IsInverted
                value=value*(-1);
            end
        end
        function value = get.Name(obj)
            value=num2str(obj.Number);
        end
        function value = get.Number(obj)
            value = obj.other_ind_value;
        end
        function set.Number(obj,value)
            obj.other_ind_value=value;
        end
        function value = get.IsGood(obj)
            value=obj.get_property('IsGood','bool');
        end
        function set.IsGood(obj,value)
            obj.set_property('IsGood',value,'int');
        end
        function value = get.IsRectified(obj)
            value=obj.get_property('IsRectified','bool');
        end
        function set.IsRectified(obj,value)
            obj.set_property('IsRectified',value,'int');
        end
        function value = get.IsInverted(obj)
            value=obj.get_property('IsInverted','bool');
        end
        function set.IsInverted(obj,value)
            obj.set_property('IsInverted',value,'int');
        end
        function value = get.ADRange(obj)
            value=obj.get_property('ADRange','float');
        end
        function set.ADRange(obj,value)
            obj.set_property('ADRange',value,'float');
        end
        function value = get.ADBits(obj)
            value=obj.get_property('ADBits','int');
        end
        function set.ADBits(obj,value)
            obj.set_property('ADBits',value,'int');
        end
        function value = get.TotalAmplification(obj)
            value=obj.get_property('TotalAmplification','float');
        end
        function set.TotalAmplification(obj,value)
            obj.set_property('TotalAmplification',value,'float');
        end
        function value = get.MRStartms(obj)
            value=obj.get_property('MRStartms','float');
        end
        function set.MRStartms(obj,value)
            obj.set_property('MRStartms',value,'float');
        end
        function value = get.MRStopms(obj)
            value=obj.get_property('MRStopms','float');
        end
        function set.MRStopms(obj,value)
            obj.set_property('MRStopms',value,'float');
        end
        function value = get.HRStartms(obj)
            value=obj.get_property('HRStartms','float');
        end
        function set.HRStartms(obj,value)
            obj.set_property('HRStartms',value,'float');
        end
        function value = get.HRStopms(obj)
            value=obj.get_property('HRStopms','float');
        end
        function set.HRStopms(obj,value)
            obj.set_property('HRStopms',value,'float');
        end
        function value = get.RewardLow(obj)
            value=obj.get_property('RewardLow','float');
        end
        function set.RewardLow(obj,value)
            obj.set_property('RewardLow',value,'float');
        end
        function value = get.RewardHigh(obj)
            value=obj.get_property('RewardHigh','float');
        end
        function set.RewardHigh(obj,value)
            obj.set_property('RewardHigh',value,'float');
        end
    end
end