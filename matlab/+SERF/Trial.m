classdef Trial < EERF.Datum
    properties (Dependent = true)
        periods;
    end
    methods
        function obj = Trial(varargin)
            obj = obj@EERF.Datum(varargin{:});
        end
        function periods = get.periods(trial)
            stmnt = sprintf(['SELECT datum_id FROM datum WHERE subject_id={Si} '...
                'AND span_type=''period'' AND start_time<=''%s'' AND stop_time>=''%s'''],...
                trial.StartTime, trial.StopTime);
            mo = trial.dbx.statement(stmnt, {trial.subject.subject_id});
            n_periods = length(mo.datum_id);
            if n_periods>0
                periods(n_periods) = EERF.Period(trial.dbx);
                trial_ids = num2cell(mo.datum_id);
                [periods(:).datum_id] = trial_ids{:};
            else
                periods = [];
            end
        end
    end
end