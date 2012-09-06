classdef Subject < handle
    properties
        name
        mep_data
    end
    properties (Hidden = true)
        exp_date
        muscle
        sici_isi
        icf_isi
        fb_ref_ch
        %fb_center_freq
        fifo_buffer
        filterbank
        chad_mep_freq = NaN;
        chad_task_freq = NaN;
        eeg_fs = 600; %Hz
        trial_bool
    end
    properties (Transient = true)
        trials %in-memory version
        spat_filt = [-0.25 -0.25 -0.25 -0.25 1 0 0];
    end
    properties (Dependent = true, Hidden = true)
        CSVFiles
        EEGFiles
        data_dir
    end
    properties (Constant = true, Hidden = true)
        %Eventually these should move to a CSVFile class
        data_root = 'G:\Studies\Takemi_ERD_TMS\data\';
        rc_isis = [0 2 3 5 10 15];
        row_numbers = {[78 198 118 238 158 278];[66 106 146]};
        ch_offset = 19;
        trial_col = 1;
        p2p_col = 6;
        buff_length = 24; %Buffer length in seconds
        %The following are file-specific. Maybe there should be a EEGFile
        %class?
        emg_fs = 1000; %Hz
        emg_channel_labels = {'FCR';'ECR'};
        eeg_channel_labels = {'FC3';'C5';'CP3';'C1';'C3';'task';'trigger'};%task 0 = rest, 3 = imagery
    end
    methods
        function obj=Subject(varargin)%constructor
            if nargin > 0
                sub_metadata = varargin{1};
                obj.name = sub_metadata.name;
                obj.exp_date = sub_metadata.date;
                obj.muscle = sub_metadata.muscle;
                obj.sici_isi = sub_metadata.sici_isi;
                obj.icf_isi = sub_metadata.icf_isi;
                obj.fb_ref_ch = sub_metadata.fb_ch_ref;
                ref_chix = strcmpi(obj.eeg_channel_labels,obj.fb_ref_ch);
                c3_chix = strcmpi(obj.eeg_channel_labels,'C3');
                obj.spat_filt = (c3_chix - ref_chix)';
                %obj.spat_filt = 
%                 obj.fb_center_freq = sub_metadata.center_freq;
%                 if isfield(sub_metadata,'chad_mep_freq')
%                     obj.chad_mep_freq = sub_metadata.chad_mep_freq;
%                 end
%                 if isfield(sub_metadata,'chad_task_freq')
%                     obj.chad_task_freq = sub_metadata.chad_task_freq;
%                 end
%                 if isfield(sub_metadata,'eeg_fs')
%                     obj.eeg_fs = sub_metadata.eeg_fs;
%                 end
%                 if isfield(sub_metadata,'trial_bool')
%                     obj.trial_bool = sub_metadata.trial_bool;
%                 end
            end
%             %Prepare the Fifo_buffer
%             buff.n_samples = obj.buff_length / Takemi.Trial.ft_win_step_sec;
%             buff.n_channels = size(Takemi.Trial.freq_edges,1) * Takemi.Subject.n_chans;
%             obj.fifo_buffer = Takemi.Fifobuffer(buff);
%             %Prepare the filter bank.
%             obj.filterbank = Takemi.Filterbank(struct('freq_edges',Takemi.Trial.freq_edges,'fs',obj.eeg_fs));
        end
        function data_dir = get.data_dir(sub)
            data_dir = [sub.data_root,sub.name,'(',sub.exp_date,')',filesep];
        end
        %Get File Names
        function my_files = get.CSVFiles(sub)
            my_files = sub.get_files('csv');
        end
        function my_files = get.EEGFiles(sub)
            my_files = sub.get_files('mat');
        end
        function my_files = get_files(sub,extension)
            filedir = dir([sub.data_dir,'*.',extension]);
            f_names = {filedir.name};
            f_dates = {filedir.date};
            %Pull out the condition (RC, 5, 15) from the filename.
            match = '\((\w{1,5})';
            output = regexpi(f_names,match,'tokens');
            condition=NaN(length(output),1);
            for oo=1:length(output)
                if ~isempty(output{oo})
                    if strcmp(output{oo}{1},'5') || strcmpi(output{oo}{1},'ERD5')
                        condition(oo)=5;
                    elseif strcmp(output{oo}{1},'15') || strcmpi(output{oo}{1},'ERD15')
                        condition(oo)=15;
                    elseif strcmpi(output{oo}{1},'rc')
                        condition(oo)=0;
                    end
                end
            end
            [condition, I] = sort(condition);
            f_names = f_names(I);
            %my_files=NaN(1,length(f_names));
            for ff=1:length(f_names)
                my_files(ff).name = f_names(ff);
                my_files(ff).condition = condition(ff);
                my_files(ff).date = f_dates{ff};
            end
        end
        
        %Loading Data from Files
        function load_data(sub)
            mep_output = sub.load_csv_data;
            eeg_trials = sub.load_eeg_data; %Takemi.Trials
            
            %Match up the eeg_trials with their mep counterparts
            for tt=1:length(eeg_trials)
                mep_ix = NaN;
                if ~isnan(eeg_trials(tt).mep_ix)
                    mep_ix = find(mep_output(:,1) == eeg_trials(tt).task_ix ...
                        & mep_output(:,3) == eeg_trials(tt).mep_ix);
                end
                if any(~isnan(mep_ix)) && any(mep_ix)
                    eeg_trials(tt).isi = mep_output(mep_ix,2);
                    eeg_trials(tt).mep = mep_output(mep_ix,4);
                else
                    eeg_trials(tt).isi = NaN; 
                    eeg_trials(tt).mep = NaN;
                end
            end
            
            %Add the trials to the subject.
            sub.trials=eeg_trials;
        end
        function mep_output = load_csv_data(sub)%Load data from the CSV files
            mep_output=[];
            for ff = 1:length(sub.CSVFiles)
                this_file = sub.CSVFiles(ff);
                f_name = [sub.data_dir,this_file.name{:}];
                
                %csvread does not like the Japanese text
                %Thus we need to specify row numbers
                %Row numbers depend on the file type because
                %RC file has more ISIs.
                if this_file.condition==0
                    my_isis = sub.rc_isis;
                    my_row_starts = sub.row_numbers{1};
                    %Corrections for some subjects
                    if strcmpi(sub.name,'onose')
                        my_row_starts = [78 200 118 242 158 282];
                    elseif strcmpi(sub.name,'terasaki')
                        my_row_starts = [78 196 118 236 158 276];
                    end
                else
                    my_isis = [0 sub.sici_isi sub.icf_isi];
                    my_row_starts = sub.row_numbers{2};
                    if strcmpi(sub.name,'yazaki') && cc==3
                        my_row_starts = [66 98 130];
                    end
                end
                if any(strfind('ECR',sub.muscle))
                    my_row_starts = my_row_starts + sub.ch_offset;
                end
                
                for isi=1:length(my_isis)
                    row = my_row_starts(isi);
                    row_bounds = [row-1 0 row+8 5];
                    if strcmpi(sub.name,'terasaki') && cc==1 && isi==5
                        row_bounds = [row-1 0 row+7 5];
                    elseif strcmpi(sub.name,'yazaki') && cc==3
                        row_bounds = [row-1 0 row+4 5];
                    end
                    my_csv = csvread(f_name, row-1, 0, row_bounds);
                    n_trials = size(my_csv,1);
                    mep_output = [mep_output; repmat(this_file.condition,n_trials,1), repmat(my_isis(isi),n_trials,1), my_csv(:,1), my_csv(:,6)];
                end
            end
        end
        function eeg_trials = load_eeg_data(sub)
            eeg_trials = [];
            %Choose the files with a real experimental conditions. They
            %should already be sorted.
            eeg_files = sub.EEGFiles;
            conditions = [eeg_files.condition]; %0=RC, 5=ERD5, 15=ERD15
            my_eeg_files = eeg_files(~isnan(conditions));
            conditions = conditions(~isnan(conditions));
            cond_list = unique(conditions);
            
            %Some trials have no TMS pulse, the CSV file is unaware of
            %these. Thus we need to increment trial_ix_eeg and trial_ix_mep
            %separately. Furthermore, these indexes will be different for
            %each condition, so we will have one more global index.
            trial_ix_eeg = [0 0 0]; %Total trials per condition
            trial_ix_mep = [0 0 0]; %TMS trials per condition.
            trial_ix_global = 0; %Total trials across all conditions.
            
            for ff=1:length(my_eeg_files)
                cond_ix = find(cond_list==my_eeg_files(ff).condition);%For indexing trial_ix_eeg/mep
                %Load the raw data
                temp = load([sub.data_dir,my_eeg_files(ff).name{:}]);
                %t_vec = temp.simout.time;
                signals = squeeze(temp.simout.signals.values(1,:,:)); %chans x samples
                
                %Identify trial starts and stops
                task_starts = find(diff(signals(6,:))>0);
                task_stops = find(diff(signals(6,:))<0);
                trial_starts = [1 task_stops(1:end-1)];
                trigger_starts = NaN(size(trial_starts));
                for tt=1:length(trial_starts)
                    %Examine the data from this trial's task_start to the
                    %next trial's task_start for a trigger.
                    if tt<length(trial_starts)
                        trig_ix = task_starts(tt):task_starts(tt+1);
                    else
                        trig_ix = task_starts(tt):size(signals,2);
                    end
                    trig_sig = signals(7,trig_ix);
                    test_sig = signals(5,trig_ix) - signals(5,trig_ix(1));
                    if any(trig_sig>0)
                        trigger_detect = find(test_sig>3000,1,'first');
                        if any(trigger_detect)
                            trigger_starts(tt) = trig_ix(1) + trigger_detect - 1;
                        else
                            trigger_starts(tt) = trig_ix(1) + find(diff(trig_sig)<0,1,'first');
                        end
                        if tt<length(trial_starts)
                            trial_starts(tt+1) = trigger_starts(tt) + 1;
                        end
                    end
                end
                trial_stops = [trial_starts(2:end) task_stops(end)];
                trial_stops(~isnan(trigger_starts)) = trigger_starts(~isnan(trigger_starts));
                
                file_t_vec = 1/sub.eeg_fs:1/sub.eeg_fs:size(signals,2)/sub.eeg_fs;
                file_datetime = my_eeg_files(ff).date;
                
                %For each trial
                for tt=1:length(trial_starts)
                    my_sig = signals(:,trial_starts(tt):trial_stops(tt));
                    
                    %Increment our trial counters.
                    trial_ix_eeg(cond_ix) = trial_ix_eeg(cond_ix) + 1;
                    trial_ix_mep(cond_ix) = trial_ix_mep(cond_ix) + 1*~isnan(trigger_starts(tt));
                    trial_ix_global = trial_ix_global + 1;
                    
                    %Spatial filter.
                    my_sig = sub.spat_filt * my_sig;
                    
                    new_trial.fs = sub.eeg_fs;
%                     new_trial.filterbank = sub.filterbank;
                    new_trial.eeg_ix = trial_ix_eeg(cond_ix);
                    new_trial.task_ix = cond_list(cond_ix);
                    if ~isnan(trigger_starts(tt))
                        new_trial.mep_ix = trial_ix_mep(cond_ix);
                    else
                        new_trial.mep_ix = NaN;
                    end
                    new_trial.trigger_start = trial_stops(tt) - trial_starts(tt);
                    new_trial.task_start = task_starts(tt) - trial_starts(tt);
                    new_trial.raw_data = my_sig;
                    new_trial.datetime = datestr(datenum(file_datetime) + file_t_vec(trial_starts(tt))/(60*60*24));
%                     new_trial.buffer = sub.fifo_buffer.contents;
                    
                    %Make new_trial into Takemi.Trial so we can get the
                    %calculated spectral values.
                    new_trial = Takemi.Trial(new_trial);
%                     %Update the buffer for the next trial.
%                     to_buffer = [new_trial.timefreq_baseline_power;new_trial.timefreq_test_power];
%                     to_buffer = reshape(to_buffer,[size(to_buffer,1), Takemi.Subject.n_chans * size(to_buffer,3)]);
%                     %TODO: pick out the important pieces of the trial.
%                     sub.fifo_buffer.add(to_buffer);
                    
%                     %If this trial had an empty buffer, update it with the
%                     %new buffer.
%                     if ~any(~isnan(new_trial.buffer))
%                         new_trial.buffer = sub.fifo_buffer.contents;
%                     end
                    
                    eeg_trials=[eeg_trials;new_trial];
                    clear new_trial;
                end
            end
        end
        
        function trial_bool = triage_trials(sub)
            addpath([docroot '/techdoc/creating_plots/examples'])
            my_chan = 1;
            
            sub.load_data;
            n_trials = length(sub.trials);
            trial_bool = false(n_trials,1);
            freqs = mean(Takemi.Trial.freq_edges,2);
            freqs = freqs(1:end-1);
            
            meps = [sub.trials.mep]';
            [n,mep_x] = hist(meps);
            arrow_obj = [];
            %For each trial
            for tt=1:n_trials
                %Plot the full trial raw data and full trial frequency
                %transform.
                trial = sub.trials(tt);
                
                
                subplot(3,1,1)
                x = trial.t_vec_task;
                y = trial.raw_data(my_chan,:)';
                ylims = [min(min(y)) max(max(y))];
                plot(x,y)
                axis tight, xlabel('TIME TO IMAGERY (s)'), ylabel('AMP (uV)')
                hold on
                plot(trial.baseline_window,[ylims(1) ylims(1)],'k','LineWidth',5)
                %TODO: Plot test window.
                x2 = trial.t_vec_stim;
                stim_bool = x2 >= trial.test_window(1) & x2 <= trial.test_window(2);
                x2 = x(stim_bool);
                plot(x2,ylims(1)*ones(size(x2)),'r','LineWidth',5)
                hold off
                title([sub.name,' - ',num2str(tt)])
                
                subplot(3,1,2)
                x = trial.timefreq_tvec_task;
                z = 10*log10(squeeze(trial.timefreq_power(:,my_chan,1:end-1)));
                imagesc(x,freqs,z')
                axis xy
                xlabel('TIME TO IMAGERY (s)'),ylabel('FREQ (Hz)')
                hold on
                plot(trial.baseline_window,[freqs(1) freqs(1)],'k','LineWidth',5)
                plot(x2,freqs(1)*ones(size(x2)),'r','LineWidth',5)
                hold off
                
                subplot(3,1,3)
                bar(mep_x,n)
                if ~isnan(meps(tt))
                    [arrowx,arrowy] = dsxy2figxy(gca, [meps(tt) meps(tt)], [max(n) min(n)]);
                    if ~any(arrow_obj)
                       arrow_obj = annotation('arrow',arrowx,arrowy,'Color',[1 0 0]);
                    else
                        set(arrow_obj,'X',arrowx,'Y',arrowy)
                    end
                end
                
                trial_bool(tt)=waitforbuttonpress; %kb good, mouse bad
            end
        end
        
%         function data = trials_to_mat(sub,field_name)
%             %Share trial data in more convenient matrix n_trials x
%             %whatever.
%             ts = sub.trials;
%             nd = ndims(ts(1).(field_name));
%             data = cat(nd+1, ts.(field_name));
%             data = shiftdim(data, nd);
%         end
    end
end