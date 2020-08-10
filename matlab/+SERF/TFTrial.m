classdef TFTrial < EERF.Trial
    %A trial that also has access to a time-frequency representation of the
    %erp data
    %I may also use the class for calculating specific spectral features
    %(e.g. erd, ana, rel_amp, baseline_pow, prestim_pow) or maybe a
    %sub-class would be better. Might also have shortcut to trial.details
    properties (Dependent = true)
        tf_pow %tf_pow is steps x channels x freqs.
        tf_tvec
        tf_fvec
    end
    properties (Transient = true, Hidden = true)
        tf_pow_ = NaN; %Store the value here for speed.
        tf_tvec_ = NaN;
        tf_fvec_ = NaN;
    end
    methods
        function obj = TFTrial(varargin)
            obj = obj@EERF.Trial(varargin{:});
        end
        function tf_pow = get.tf_pow(trial)
            if isnan(trial.tf_pow_)
                %Use the static methods of TFBox to calculate the
                %time-frequency of this trial. Then store the results.
                [tf_amp, trial.tf_tvec_, trial.tf_fvec_] = EERF.TFBox.process(trial.erp, trial.xvec);
                trial.tf_pow_ = tf_amp.^2;
            end
            tf_pow = trial.tf_pow_;
        end
        function tf_tvec = get.tf_tvec(trial)
            if isnan(trial.tf_tvec_)
                trial.tf_pow; %Calculaing tf_pow will set the other vectors.
            end
            tf_tvec = trial.tf_tvec_;
        end
        function tf_fvec = get.tf_fvec(trial)
            if isnan(trial.tf_fvec_)
                trial.tf_pow;%Calculaing tf_pow will set the other vectors.
            end
            tf_fvec = trial.tf_fvec_;
        end
    end
end