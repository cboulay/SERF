classdef Trial < handle
    properties (Constant = true)
        %Some constants for data analysis.
        ft_type = 'fft';%'filterbank' 'mem' 'fft'
        window_uses_timefreq = true(1,1);%For baseline_ and test_,
                %either average across the timefreq or use the raw window
                %and calculate the ft using that window only
        freq_edges = [[(3:3:45) 1]' [(6:3:48) 5]']; %The last entry will be used as a normalizer for rel_amp
        %freq_edges = [4 7;7 14;14 30;30 100;1 4];
        baseline_window = [-3.5 -0.5];
        test_window = [-1 0];
        ft_win_sec = 1;
        ft_win_step_sec = 1/8;
        n_freqs = size(Takemi.Trial.freq_edges,1);
        %Note that, to simulate online functionality, it will be presumed
        %that we only have data up to 'now' when calculating spectra. This
        %means that the spectral amplitude at the time of stimulation will
        %include data only up until the last step before the stimulus.
    end
    properties %Interesting properties
        raw_data %Data from previous stimulus to this stimulus.
        isi
        mep
        datetime
    end
    properties (Hidden = true)
        %Uninteresting properties or ones that might be too slow to show.
        fs
        eeg_ix
        mep_ix
        task_ix
        trigger_start
        task_start
        buffer
        filterbank
    end
    properties (Dependent = true)
        task_level
        t_vec_task
        t_vec_stim
    end
    properties (Dependent = true, Hidden = true)
        baseline_power
        test_power
        test_power_db
        erd
        an_amp
        rel_amp
        timefreq_power
        timefreq_tvec_task
        timefreq_tvec_test
        timefreq_baseline_power
        timefreq_test_power
    end
    properties (Transient = true, Hidden = true)
        timefreq_pow_ = NaN;
        baseline_pow_ = NaN;
        test_pow_ = NaN;
    end
    methods
        function obj=Trial(varargin)%constructor
            if nargin > 0
                trial_metadata=varargin{1};
                obj.fs = trial_metadata.fs;
                obj.task_ix = trial_metadata.task_ix;
                obj.eeg_ix = trial_metadata.eeg_ix;
                obj.mep_ix = trial_metadata.mep_ix;
                obj.raw_data = trial_metadata.raw_data;
                obj.trigger_start = trial_metadata.trigger_start;
                obj.task_start = trial_metadata.task_start;
%                 obj.buffer = trial_metadata.buffer;
                if isfield(trial_metadata,'datetime')
                    obj.datetime = trial_metadata.datetime;
                end
                if isfield(trial_metadata,'isi')
                    obj.isi = trial_metadata.isi;
                end
                if isfield(trial_metadata,'mep')
                    obj.mep = trial_metadata.mep;
                end
%                 if isfield(trial_metadata,'filterbank')
%                     obj.filterbank = trial_metadata.filterbank;
%                 end
            end
        end
        function task_level = get.task_level(trial)
            switch trial.task_ix
                case 0
                    task_level = 'RC';
                case 5
                    task_level = 'ERD5';
                case 15
                    task_level = 'ERD15';
            end
        end
        
%         function ftsig = freq_transform(trial,dat)
%             %dat is samples x channels. ftsig is steps x channels x freqs
%             temp_dat = dat;
%             [n_samps, n_chans] = size(temp_dat);
%             new_freqs = Takemi.Trial.freq_edges;
%             n_fs = Takemi.Trial.n_freqs;
%             n_samps_per_win = ceil(trial.ft_win_sec*trial.fs);
%             n_samps_per_step = ceil(trial.ft_win_step_sec * trial.fs);
%             step_starts = 1 : n_samps_per_step : n_samps - n_samps_per_win +1;
%             last_step_start = n_samps - n_samps_per_win + 1;
%             do_extra_block = step_starts(end) ~= last_step_start;
%             if do_extra_block
%                 step_starts = [step_starts last_step_start];
%             end
%             n_steps = length(step_starts);
% 
%             %reindex the data into its windows.
%             reindex_col = (0:1:n_samps_per_win-1)';%The window.
%             reindex_chans = shiftdim(0:n_samps:n_samps*n_chans-1,-1);
%             reindex = bsxfun(@plus,bsxfun(@plus,step_starts,reindex_col),reindex_chans);
% 
%             if strcmpi(trial.ft_type,'filterbank')
%                 temp_ft = trial.filterbank.process(temp_dat);
%                 temp_ft = reshape(temp_ft,[n_samps, n_chans*n_fs]);
%                 temp_ft = abs(hilbert(temp_ft));
%                 temp_ft = temp_ft.^2;
%                 temp_ft = reshape(temp_ft,[n_samps n_chans n_fs]);
%                 reindex_freqs = shiftdim(0:n_samps*n_chans:n_samps*n_chans*n_fs-1,-2);
%                 reindex = bsxfun(@plus,reindex,reindex_freqs);
%                 temp_ft = temp_ft(reindex);
%                 temp_ft = mean(temp_ft);
%                 ftsig = shiftdim(temp_ft,1); %steps x chans x freqs
%             elseif strcmpi(trial.ft_type,'mem')
%                 temp_dat = temp_dat(reindex);
%                 temp_dat = reshape(temp_dat,[n_samps_per_win n_chans*n_steps]);
%                 temp_ft = NaN(n_fs,n_chans*n_steps);%Instantiate our output variable.
%                 for ff=1:n_fs
%                     order = min(floor(trial.fs/new_freqs(ff,1)),trial.fs/2);
%                     width = new_freqs(ff,2)-new_freqs(ff,1);
%                     f_cent = mean(new_freqs(ff,:));
%                     %parms = [order f_cent f_cent width 10 2 trial.fs n_samps_per_step n_samps_per_win/n_samps_per_step];
%                     parms = [order f_cent f_cent width 10 2 trial.fs];
%                     temp_ft(ff,:) = mem(temp_dat,parms);
%                 end
%                 temp_ft = reshape(temp_ft,[n_fs n_chans n_steps]); %freqs x chans x steps
%                 ftsig = permute(temp_ft,[3 2 1]); %steps x chans x freqs
%             elseif strcmpi(trial.ft_type,'fft')
%                 temp_dat = temp_dat(reindex); %[n_samps_per_win x n_steps x n_chans]
%                 temp_dat = reshape(temp_dat,[n_samps_per_win n_steps*n_chans]);
%                 temp_dat = detrend(temp_dat,'linear');
%                 blwindow = blackman(size(temp_dat,1));%like a gaussian window
%                 temp_dat = bsxfun(@times,temp_dat,blwindow);%window the steps
%                 NFFT = trial.fs;
%                 n_fft_freqs = NFFT/2+1;
%                 freq_out = trial.fs/2*linspace(0,1,n_fft_freqs);
%                 temp_ft = fft(temp_dat,NFFT)/trial.fs;
%                 temp_ft = 2*abs(temp_ft(1:n_fft_freqs,:,:));
%                 gt_bool = bsxfun(@ge,freq_out,new_freqs(:,1));
%                 lt_bool = bsxfun(@le,freq_out,new_freqs(:,2));
%                 freq_bool = gt_bool & lt_bool;
%                 temp_ft = freq_bool * temp_ft;%This sums up values for each frequency bin.
%                 temp_ft = bsxfun(@rdivide, temp_ft, sum(freq_bool,2));%Divide by the number of frequencies.
%                 temp_ft = reshape(temp_ft,[n_fs n_steps n_chans]);
%                 ftsig = permute(temp_ft,[2 3 1]);%steps x chans x freqs
%             end
%         end
                
        function t_vec = get_t_vec(trial,ref_point)
            t_vec = 1:1:length(trial.raw_data);
            t_vec = t_vec/trial.fs;
            if strcmpi(ref_point,'task')
                t_vec = t_vec - t_vec(trial.task_start);
            elseif strcmpi(ref_point,'stim')
                t_vec = t_vec - t_vec(trial.trigger_start);
            end
        end
        function t_vec_task = get.t_vec_task(trial)
            t_vec_task = trial.get_t_vec('task');
        end
        function t_vec_stim = get.t_vec_stim(trial)
            t_vec_stim = trial.get_t_vec('stim');
        end
%         function baseline_power = get.baseline_power(trial)
%             if isnan(trial.baseline_pow_)
%                 if Takemi.Trial.window_uses_timefreq
%                     temp_ft = trial.timefreq_power;
%                     t_vec = trial.timefreq_tvec_task;
%                     t_bool = t_vec >= trial.baseline_window(1) & t_vec < trial.baseline_window(2);
%                     temp_ft = temp_ft(t_bool,:,:);
%                 else
%                     temp_dat = trial.raw_data';
%                     start_stop = Takemi.Trial.baseline_window*trial.fs + trial.task_start;
%                     temp_dat = temp_dat(start_stop(1)+1:start_stop(2),:);
%                     temp_ft = trial.freq_transform(temp_dat);
%                 end
%                 temp_ft = mean(temp_ft,1);
%                 temp_ft = shiftdim(temp_ft,1); %chans x freqs
%                 trial.baseline_pow_ = temp_ft;
%             end
%             baseline_power = trial.baseline_pow_;
%         end
%         function test_power = get.test_power(trial)
%             if isnan(trial.test_pow_)
%                 %Use this method to only use the raw data in the test
%                 %window.
%                 if Takemi.Trial.window_uses_timefreq
%                     temp_ft = trial.timefreq_power;
%                     t_vec = trial.timefreq_tvec_test;
%                     t_bool = t_vec >= trial.test_window(1) & t_vec < trial.test_window(2);
%                     temp_ft = temp_ft(t_bool,:,:);
%                 else
%                     temp_dat = trial.raw_data';
%                     start_stop = Takemi.Trial.test_window*trial.fs + trial.trigger_start;
%                     temp_dat = temp_dat(start_stop(1)+1:start_stop(2),:);
%                     temp_ft = trial.freq_transform(temp_dat);
%                 end
%                 temp_ft = mean(temp_ft,1);
%                 temp_ft = shiftdim(temp_ft,1); %chans x freqs
%                 trial.test_pow_ = temp_ft;
%             end
%             test_power = trial.test_pow_;
%         end
%         function test_power_db = get.test_power_db(trial)
%             test_power_db = 10*log10(trial.test_power+eps);
%         end
%         function erd = get.erd(trial)
%             erd_of_power = true(1,1);
%             if erd_of_power
%                 test = trial.test_power; %chans x freqs
%                 base = trial.baseline_power;%Average baseline.
%             else
%                 test = sqrt(trial.test_power); %chans x freqs
%                 base = sqrt(trial.baseline_power);%Average baseline.
%             end
%             erd = 100 * test ./ base;
%             %erd = 100 * bsxfun(@rdivide,test_amp,base_amp);
%         end
%         function an_amp = get.an_amp(trial)
%             %In BCI2000, expression filter is before normalizer.
%             %Thus the signal and buffer COULD be converted to dB by the
%             %time the data are normalized.
%             %test = sqrt(trial.test_power);%uV
%             %test = trial.test_power_db;%dB
%             test = trial.test_power;%uV2
%             [n_c,n_f] = size(test);
%             %buff = sqrt(trial.buffer);%uV
%             %buff = 10*log10(trial.buffer);%db
%             buff = trial.buffer;%uV2
%             buff = reshape(buff, [size(buff,1) n_c, n_f]);
%             buff_mean = shiftdim(nanmean(buff),1);
%             buff_var = shiftdim(nanvar(buff),1);
%             an_amp = (test-buff_mean)./buff_var;
%             %buff = 10*log10(trial.buffer);
%         end
%         function rel_amp = get.rel_amp(trial)
%             %test_amp = sqrt(trial.test_power);
%             test_amp = trial.test_power;
%             ref_amp = test_amp(:,end);
%             rel_amp = bsxfun(@rdivide, test_amp, ref_amp);
%         end
%         
%         function timefreq_tvec = get_timefreq_tvec(trial,ref_point)
%             t_vec = trial.get_t_vec(ref_point);
%             n_samps_total = size(trial.raw_data,2);
%             n_samps_per_win = ceil(trial.ft_win_sec*trial.fs);
%             n_samps_per_step = ceil(trial.ft_win_step_sec * trial.fs);
%             step_starts = 1 : n_samps_per_step : n_samps_total - n_samps_per_win +1;
%             last_step_start = n_samps_total - n_samps_per_win + 1;
%             if step_starts(end) ~= last_step_start;
%                 step_starts = [step_starts last_step_start];
%             end
%             step_stops = step_starts + n_samps_per_win - 1;
%             timefreq_tvec = t_vec(step_stops);
%         end
%         function timefreq_tvec_task = get.timefreq_tvec_task(trial)
%             timefreq_tvec_task = trial.get_timefreq_tvec('task');
%         end
%         function timefreq_tvec_test = get.timefreq_tvec_test(trial)
%             timefreq_tvec_test = trial.get_timefreq_tvec('stim');
%         end
%         function timefreq_power = get.timefreq_power(trial)
%             if isnan(trial.timefreq_pow_)
%                 trial.timefreq_pow_ = trial.freq_transform(trial.raw_data');
%             end
%             timefreq_power = trial.timefreq_pow_;
%         end
%         function baseline_timefreq_power = get.timefreq_baseline_power(trial)
%             timefreq_power = trial.timefreq_power;
%             timefreq_tvec = trial.timefreq_tvec_task;
%             t_bool = timefreq_tvec >= Takemi.Trial.baseline_window(1) & timefreq_tvec <= Takemi.Trial.baseline_window(2);
%             baseline_timefreq_power = timefreq_power(t_bool,:,:);
%         end
%         function test_timefreq_power = get.timefreq_test_power(trial)
%             timefreq_power = trial.timefreq_power;
%             timefreq_tvec = trial.timefreq_tvec_test;
%             t_bool = timefreq_tvec >= Takemi.Trial.test_window(1) & timefreq_tvec <= Takemi.Trial.test_window(2);
%             test_timefreq_power = timefreq_power(t_bool,:,:);
%         end
       
    end
end