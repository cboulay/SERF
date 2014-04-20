classdef Trial < EERAT.Datum
    properties (Dependent = true)
        periods;
    end
    methods
        function obj = Trial(varargin)
            obj = obj@EERAT.Datum(varargin{:});
        end
        function periods = get.periods(trial)
            %Since I have not implemented span_type="day", the only
            %possible parents are periods, thus I can use the parent class
            %method.
            periods=trial.get_many_to_many('datum_has_datum',...
                'child_datum_id','datum_id','parent_datum_id','datum_id','Period');
        end
        function set.periods(trial,periods)
            trial.set_many_to_many(periods,'datum_has_datum',...
                'child_datum_id','datum_id','parent_datum_id','datum_id');
        end
    end
end