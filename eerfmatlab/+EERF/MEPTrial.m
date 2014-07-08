classdef MEPTrial < EERF.TFTrial
    properties (Dependent = true)
        mep
        isi
        stimA
        stimB
    end
    methods
        function obj = MEPTrial(varargin)
            obj = obj@EERF.TFTrial(varargin{:});
        end
        function mep = get.mep(trial)
            mep = trial.get_single_feature('MEP_p2p');
        end
        function isi = get.isi(trial)
            isi = str2double(trial.get_single_detail('dat_TMS_ISI'));
        end
        function stimA = get.stimA(trial)
            stimA = str2double(trial.get_single_detail('dat_TMS_powerA'));
        end
        function stimB = get.stimB(trial)
            stimB = str2double(trial.get_single_detail('dat_TMS_powerB'));
        end
    end
end