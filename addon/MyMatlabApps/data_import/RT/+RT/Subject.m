classdef Subject < handle
    properties
        name
        session_subset = 'train'; %'test' or 'screen' or 'train'
    end
    properties (Hidden = true)
        nScreen
        nTrain
        nTest
        fb_freq
        fb_chan
        spat_filt
        test_channel% = {'C3'};
        task_freqs
        rt_freqs
        file_sess_n
        eeg_fs
    end
    properties (Transient = true)
        trials %in-memory version
    end
    properties (Dependent = true, Hidden = true)
        data_dir
        EEGFiles
    end
    properties (Constant = true, Hidden = true)
        data_root = 'G:\data\reaction_time\';
%         eeg_fs = 160; %Hz
        eeg_channel_labels = {'FC5','FC3','FC1','FCz','FC2','FC4','FC6','C5.','C3.','C1.','Cz.','C2.','C4.','C6.','CP5','CP3','CP1','CPz','CP2','CP4','CP6','FP1','FPz','FP2','AF7','AF3','AFz','AF4','AF8','F7.','F5.','F3.','F1.','Fz.','F2.','F4.','F6.','F8.','FT7','FT8','T7.','T8.','T9.','T10','TP7','TP8','P7.','P5.','P3.','P1.','Pz.','P2.','P4.','P6.','P8.','PO7','PO3','POz','PO4','PO8','O1.','Oz.','O2.','Iz.'};
        baseline_win = [-2 0]; %Relative to task start.
        test_win = [-1 0]; %Relative to stim
    end
    methods
        function obj=Subject(varargin)%constructor
            if nargin > 0
                sub_metadata=varargin{1};
                obj.name=sub_metadata.name;
                if isfield(sub_metadata,'nScreen')
                    obj.nScreen = sub_metadata.nScreen;
                end
                if isfield(sub_metadata,'nTrain')
                    obj.nTrain = sub_metadata.nTrain;
                end
                if isfield(sub_metadata,'nTest')
                    obj.nTest = sub_metadata.nTest;
                end
                if isfield(sub_metadata,'fb_freq')
                    obj.fb_freq = sub_metadata.fb_freq;
                end
                if isfield(sub_metadata,'fb_chan')
                    obj.fb_chan = sub_metadata.fb_chan;
                end
                if isfield(sub_metadata,'spat_filt')
                    obj.spat_filt = sub_metadata.spat_filt;
                end
                if isfield(sub_metadata,'test_channel')
                    obj.test_channel = sub_metadata.test_channel;
                end
                if isfield(sub_metadata,'task_freqs')
                    obj.task_freqs = sub_metadata.task_freqs;
                end
                if isfield(sub_metadata,'rt_freqs')
                    obj.rt_freqs = sub_metadata.rt_freqs;
                end
                if isfield(sub_metadata,'session_subset')
                    obj.session_subset = sub_metadata.session_subset;
                end
            end
        end
        function data_dir = get.data_dir(sub)
            data_dir = [sub.data_root,sub.name,filesep];
        end
        
        %Get File Names
        function my_files = get.EEGFiles(sub)
            [my_files,sub.file_sess_n] = sub.get_files('dat');
        end
        function [my_files,my_sess_n] = get_files(sub,extension)
            %Get all subdirs in data_dir
            sd_names = dir(sub.data_dir);
            sd_names = sd_names([sd_names.isdir]);
            sd_names = sd_names(3:end);
            sd_names = {sd_names.name}';
            sd_nums=cell2mat(sd_names);
            sd_nums = str2num(sd_nums(:,end-2:end)); %#ok<ST2NM>
            [~,I]=sort(sd_nums);
            sd_names=sd_names(I);
            clear sd_nums I
%             sd_names = sd_names(sub.nScreen+sub.nTrain+1:end);
            fnames = [];
            fsess = [];
            for sd=1:length(sd_names)
                sd_dir=[sub.data_dir,sd_names{sd},filesep];
                sd_fnames = dir([sd_dir,'*.',extension]);
                sd_fdates = datenum({sd_fnames.date});
                [~,I]=sort(sd_fdates);
                sd_fnames=sd_fnames(I);
                for ff=1:length(sd_fnames)
                    sd_fnames(ff).name = fullfile(sd_dir,sd_fnames(ff).name);
                end
                fnames = cat(1,fnames,sd_fnames);
                fsess = cat(1,fsess,sd*ones(length(sd_fnames),1));
            end
            
            %ftype can be 'screen', 'train', or 'test'
            %Figure out if each file is one we want based on its parameters
            %Screen runs:
            %   TransmitChList 1:16
            %   NormalizerGains [x 0] and Adaptation [x 0]
            %   ISI1, ISI2, ISI3 > 0
            %Train runs:
            %   TransmitChList 5 x chans
            %   NormalizerGains and Adaptation 2nd elements are non-zero.
            %   ISI1, ISI2, ISI3 > 0
            %Test runs:
            %   Same as Train except ISI1, ISI2, ISI3 == 0
            is_good=false(size(fnames));
            for ff=1:length(fnames)
                fn = fnames(ff).name;
                prm = read_bciprm(fn);
                switch sub.session_subset
                    case 'screen'
                        is_good(ff) = prm.ISI1.NumericValue>0 && prm.NormalizerGains.NumericValue(2)==0;
                    case 'train'
                        is_good(ff) = prm.ISI1.NumericValue>0 && prm.NormalizerGains.NumericValue(2)~=0;
                    case 'test'
                        is_good(ff) = prm.ISI1.NumericValue==0;
                end
            end
            my_files=fnames(is_good);
            my_sess_n=fsess(is_good);
            clear is_good ff
        end
        
        %Loading Data from Files and put it into trials.
        function load_data(sub)
            eeg_trials = sub.load_eeg_data;
            temp(length(eeg_trials)) = RT.Trial(eeg_trials(length(eeg_trials)));
            for tt=1:length(eeg_trials)
                temp(tt)=RT.Trial(eeg_trials(tt));
            end
            sub.trials=temp;
        end
        function eeg_trials = load_eeg_data(sub)
            %Get a list of files.
            my_eeg_files=sub.EEGFiles;
            total_trial_ix=0;
            for ff=1:length(my_eeg_files)
                [ signal, states, parameters, total_samples ]=load_bcidat(my_eeg_files(ff).name,'-calibrated');
                signal = signal * sub.spat_filt';
                fs = parameters.SamplingRate.NumericValue;
                sub.eeg_fs = fs;
                t_vec = 1/fs:1/fs:total_samples/fs;
                file_datenum = datenum(parameters.StorageTime.Value, 'ddd mmm dd HH:MM:SS yyyy');
                
                %Identify trial starts
                trialStartBool=logical([1;diff(double(states.RT_State))<0]) & states.RT_State==0;
                trial_start=find(trialStartBool==1);
                trialStopBool=logical([0;diff(double(states.RT_State))>0]) & states.RT_State==50;
                trial_stop=find(trialStopBool==1);
                nTrials=length(trial_start);

                %get output variables for each trial
                %signal, rt, trialType
                for tt=1:nTrials
                    total_trial_ix = total_trial_ix + 1;
                    trial_t = t_vec(trial_start(tt):trial_stop(tt));
                    sig_seg = signal(trial_start(tt):trial_stop(tt),:);
                    tempStates=states.RT_State(trial_start(tt):trial_stop(tt));
                    
                    %Save state variables into trial structure.
                    %Reaction Time
                    if any(tempStates(tempStates==31)) && any(tempStates(tempStates==41))
                        %if the user pressed the correct button.
                        eeg_trials(total_trial_ix).rt=double(states.RT_Result(trial_stop(tt)));
                    elseif (any(tempStates(tempStates==31)) && any(tempStates(tempStates==42))) || ...
                            (any(tempStates(tempStates==32)) && any(tempStates(tempStates==41)))
                        %if the user pressed the wrong button.
                        eeg_trials(total_trial_ix).rt=-1;
                    else
                        eeg_trials(total_trial_ix).rt=NaN;
                    end                    
                    
%                     %Baseline segment.
                    fb_seg = states.Feedback(trial_start(tt):trial_stop(tt));
                    task_start=find(double(fb_seg)>0,1,'first');
                    trial_t = trial_t - trial_t(task_start);
%                     baseline_start = find(trial_t >= sub.baseline_win(1),1,'first');
%                     baseline_stop = baseline_start + diff(sub.baseline_win)*sub.eeg_fs;
%                     eeg_trials(total_trial_ix).baseline_amp = sig_seg(baseline_start:baseline_stop,:,:);
%                     
%                     trigger_start=find(tempStates==31 | tempStates==32,1,'first');
%                     trial_t = trial_t - trial_t(trigger_start);
%                     test_start = find(trial_t>=sub.test_win(1),1,'first');
%                     test_stop = test_start + diff(sub.test_win)*sub.eeg_fs;
%                     eeg_trials(total_trial_ix).test_amp = sig_seg(test_start:test_stop,:,:);
                    
                    %trialType (?), target (control), result (control)
                    eeg_trials(total_trial_ix).trialType=any(tempStates(tempStates==11));
                    eeg_trials(total_trial_ix).target=states.TargetCode(trial_stop(tt));
                    eeg_trials(total_trial_ix).result=states.ResultCode(trial_stop(tt));
                    eeg_trials(total_trial_ix).raw_data = sig_seg;
                    eeg_trials(total_trial_ix).t_vec = trial_t;
                    eeg_trials(total_trial_ix).sess_n = sub.file_sess_n(ff);
                    eeg_trials(total_trial_ix).trial_datenum = file_datenum + trial_t(1)/(66*60*24);
                end
            end
        end
    end
end