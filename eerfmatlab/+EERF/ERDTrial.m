classdef ERDTrial < EERF.TFTrial
    %Assumes the trial has a baseline window and a prestim window.
    %These windows are relative to trial.tvec.
    %For ana, requires that we have a buffer (see Fifobuffer)
    properties (Dependent = true)
        baseline_win %[start stop] in s relative to trial.tvec
        baseline_pow %channels x freqs
        baseline_pow_tf %steps x channels x freqs
        task_win %[start stop] in s relative to trial.tvec
        task_pow %channels x freqs
        task_pow_tf %steps x channels x freqs
        erd %channels x freqs
        anp %channels x freqs
        relpow %channels x freqs
        condition %String representation of task condition.
    end
    properties (Hidden = true)
        %Save to disk?
        %Otherwise have to write a script to insert buffers for every analysis.
        buffer = NaN; %steps x (chans x freqs) (buffer is only 2-d)
    end
    methods
        function obj = ERDTrial(varargin)
            obj = obj@EERF.TFTrial(varargin{:});
            %TODO: set the buffer object if provided.
        end
        
        function win = get.baseline_win(trial)
            %Faster than trial.details
            stmnt = ['SELECT ddv.Value FROM datum_detail_value as ddv, detail_type ',...
                'WHERE ddv.datum_id={Si} AND ddv.detail_type_id=detail_type.detail_type_id ',...
                'AND detail_type.Name LIKE "{S}"'];
            mo = trial.dbx.statement(stmnt,[{trial.datum_id} {'dat_BG_start_ms'}]);
            win1 = str2double(mo.Value{1});
            mo = trial.dbx.statement(stmnt,[{trial.datum_id} {'dat_BG_stop_ms'}]);
            win2 = str2double(mo.Value{1});
            win = [win1 win2]./1000;
        end
        %TODO: baseline_win setter.
        function pow = get.baseline_pow_tf(trial)
            %Full tf is calculated because it is required for filling a buffer.
            %Otherwise this is used in the average below.
            tbool = trial.tf_tvec >= trial.baseline_win(1) & trial.tf_tvec <= trial.baseline_win(2);
            pow = trial.tf_pow(tbool,:,:);
        end
        function pow = get.baseline_pow(trial)
            pow = shiftdim(mean(trial.baseline_pow_tf),1);
        end
        
        function win = get.task_win(trial)
            stmnt = ['SELECT ddv.Value FROM datum_detail_value as ddv, detail_type ',...
                'WHERE ddv.datum_id={Si} AND ddv.detail_type_id=detail_type.detail_type_id ',...
                'AND detail_type.Name LIKE "{S}"'];
            mo = trial.dbx.statement(stmnt,[{trial.datum_id} {'dat_task_start_ms'}]);
            win1 = str2double(mo.Value{1});
            mo = trial.dbx.statement(stmnt,[{trial.datum_id} {'dat_task_stop_ms'}]);
            win2 = str2double(mo.Value{1});
            win = [win1 win2]./1000;
        end
        %TODO: prestim_win setter.
        function pow = get.task_pow_tf(trial)
            tbool = trial.tf_tvec >= trial.task_win(1) & trial.tf_tvec <= trial.task_win(2);
            pow = trial.tf_pow(tbool,:,:);
        end
        function pow = get.task_pow(trial)
            pow = shiftdim(mean(trial.task_pow_tf),1);
        end
        
        function erd = get.erd(trial)
            erd = 100 * (trial.task_pow - trial.baseline_pow) ./ trial.baseline_pow;
        end
        function anp = get.anp(trial)
            if ~isnan(trial.buffer)
                task_pow = trial.task_pow;
                [n_chans, n_freqs] = size(task_pow);
                buff = reshape(trial.buffer, [size(trial.buffer,1) n_chans n_freqs]);
                buff_mean = shiftdim(nanmean(buff),1);
                buff_var = shiftdim(nanvar(buff),1);
                anp = (task_pow - buff_mean) ./ buff_var;
            else
                anp = NaN;
            end
        end
        function relpow = get.relpow(trial)
            refpow = trial.task_pow(:, end);
            relpow = bsxfun(@rdivide, trial.task_pow, refpow);
        end
        
        function condition = get.condition(trial)
            condition = trial.get_single_detail('dat_task_condition');
        end
    end
end