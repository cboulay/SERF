classdef Trial < handle
    properties (Constant = true)
    end
    properties
        rt
        target
        result
        sess_n
        raw_data
        t_vec
        trial_datenum
    end
    properties (Hidden = true)
        trialType %1 fo Go, 0 for NoGo
    end
    properties (Dependent = true)
        task_level
    end
    methods
        function obj=Trial(varargin)%constructor
            if nargin == 0
            else
                trial_metadata=varargin{1};
                obj.rt=trial_metadata.rt;
                obj.trialType=trial_metadata.trialType;
                obj.target = trial_metadata.target;
                obj.result = trial_metadata.result;
                obj.raw_data = trial_metadata.raw_data;
                obj.t_vec = trial_metadata.t_vec;
                obj.sess_n = trial_metadata.sess_n;
                obj.trial_datenum = trial_metadata.trial_datenum;
            end
        end
        function task_level = get.task_level(trial)
            switch trial.target
                case 1
                    task_level = 'REST';
                case 2
                    task_level = 'IMAGERY';
            end
        end
    end
end