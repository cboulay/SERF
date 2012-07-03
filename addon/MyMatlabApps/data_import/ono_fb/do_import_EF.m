% PATHS
toolpath=pwd;
toolpath=toolpath(1:strfind(toolpath,'EERAT')+4);
toolpath=[toolpath,filesep,'core',filesep,'api',filesep,'matlab',filesep];
addpath(toolpath);
addpath([toolpath,'mym']);
clear toolpath

% DATABASE OBJECT
import EERAT.* %Object interfaces.
dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.

ft_names={'buff_amp_mean';'buff_amp_var';'baseline_amp_mean';'task_amp_mean'};
ft_freq_centers=[5 7 9 11 13 15 17 19 21 23 25 27 29];
for xx=1:length(ft_names)
    for yy=1:length(ft_freq_centers)
        comb_feat_name{(xx-1)*length(ft_freq_centers)+yy}=[ft_names{xx},'_',num2str(ft_freq_centers(yy)),'Hz']; %#ok<SAGROW>
    end
end
clear xx yy

freq_edges=NaN(length(ft_freq_centers),2);
start_diff=2; end_diff=2;
for ff=1:length(ft_freq_centers)
    freq_edges(ff,:)=[ft_freq_centers(ff)-start_diff ft_freq_centers(ff)+end_diff];
end
clear ff start_diff end_diff

fbank=Filterbank(struct('freq_edges',freq_edges,'fs',256));

channel_labels{1}={'FC3','C5.','C3.','C1.','CP3','FCz','C1.','Cz.','C2.','CPz','FC4','C2.','C4.','C6.','CP4','trigger'};
channel_labels{2}={'trigger','FC3','C5.','C3.','C1.','CP3','FC4','C2.','C4.','C6.','CP4','EMG1','EMG2'};
channel_labels{3}={'trigger','FC3','C5.','C3.','C1.','CP3','FC4','C2.','C4.','C6.','CP4'};
channel_labels{4}={'trigger','FC3','C5.','C3.','C1.','CP3','FCz','C1.','Cz.','C2.','CPz','FC4','C2.','C4.','C6.','CP4'};

% PREPARE DATABASE
prepare_database;

%IMPORT THE DATA
%Get or create an experiment to group the subjects.
experiment = EERAT.Experiment(dbx,'Name','Ono_FB');
experiment.Description='Ono-san; Effect of different feedback conditions on EEG';

si(1).Name='E';
si(1).folder='Z:\BMIProject\visual_fb\2010\SubE\EEG';
si(2).Name='F';
si(2).folder='Z:\BMIProject\visual_fb\2010\SubF\EEG';

%For each subject,
for ss=1:length(si)
    %Get or create the subject. Subjects and data are special in that they
    %require their type to be passed in as an argument at creation time.
    sub=EERAT.Subject(dbx,'Name',['ONO_',si(ss).Name],'subject_type_id',sub_type.subject_type_id);
    sub.experiments=experiment;
    
    %List folders for this subject.
    folder_list=dir(si(ss).folder);
    folder_list=folder_list(3:end);%get rid of . and ..
    
    %For each folder/day
    buff=Fifobuffer(struct('n_samples',24*256,'n_channels',length(ft_freq_centers)));
    tic
    for dd=1:length(folder_list)
        
        %Identify BMI training files
        dir_files=dir(fullfile(si(ss).folder,folder_list(dd).name,'BMI_training*'));
        
        if ~isempty(dir_files)
            %Get the db list of periods. Get or create the period for this day.
            if ss==1
                file_date=datenum(['2010',folder_list(dd).name],'yyyymmdd');
            else
                file_date=datenum(['20',folder_list(dd).name],'yyyymmdd');
            end
            per_start=datestr(file_date,'yyyy-mm-dd HH:MM:SS');
            per_stop=datestr(file_date+(86399/86400),'yyyy-mm-dd HH:MM:SS');
            this_period=EERAT.Period(dbx,'subject_id',sub.subject_id,...
                'datum_type_id',dat_lr_imagery.datum_type_id,'span_type','period',...
                'StartTime',per_start,'EndTime',per_stop);
            clear file_date per_start per_stop

            per_feature_out=[];
            per_detail_out=[];
            for ff=1:length(dir_files)
                fname=fullfile(si(ss).folder,folder_list(dd).name,dir_files(ff).name);

                %open the data
                load(fname);
                signal=squeeze(permute(simout.signals.values,[3 1 2]));
                [n_samples,n_channels]=size(signal);
                
                fs=mean(1./diff(simout.time));
                clear simout
                
                %I guess 1:10 are EEG
                spatial_filter=zeros(14,1);
                spatial_filter(6:10)=[-0.25 -0.25 1 -0.25 -0.25];
                sig=signal*spatial_filter;
                %11,12,13 appear to be EMG
                %trig_chan is 14
                trig_sig=signal(:,14);

                %find trial indices
                task_starts=find(trig_sig(1:end-1)==0 & trig_sig(2:end)~=0)+1;
                task_stops=find( trig_sig(1:end-1)~=0 & trig_sig(2:end)==0)+1;
                if length(task_stops)<length(task_starts)
                    task_stops=[task_stops;length(trig_sig)]; %#ok<AGROW>
                end
                task_conditions=1+double(trig_sig(task_starts)==1);
                n_trials=length(task_stops);

                %signal processing here if filter-bank&hilbert
%                 sig=fbank.process(sig);
%                 sig=abs(hilbert(squeeze(sig)));
%                 n_freqs=size(sig,2);
%                 base_sig=nan(3*fs,n_trials,n_freqs);
%                 task_sig=nan(2*fs,n_trials,n_freqs);
%                 for tt=1:n_trials
%                     base_sig(:,tt,:)=sig(task_starts(tt)-4*fs:task_starts(tt)-fs-1,:);
%                     task_sig(:,tt,:)=sig(task_stops(tt)-2*fs:task_stops(tt)-1,:);
%                 end
                
                %Index signal to create overlapping windows for fft
                %ix will be samples x steps x trials
                samp_ix = 1:fs;%window is 1 sec long.
                n_overlap = fs/16;%window overlap samples
                step_ix = floor(n_overlap*(0:floor((6*fs-fs-1)/n_overlap))); %window step index
                trial_ix = task_starts - 3*fs;
                ix = zeros(length(samp_ix),length(step_ix),length(trial_ix));
                [n_samps,n_steps,n_trials]=size(ix);
                ix = ix + repmat((1:fs)',[1,n_steps,n_trials]) + ...
                    repmat(step_ix,[n_samps,1,n_trials]) + ...
                    repmat(shiftdim(trial_ix,-2),[n_samps,n_steps,1]);
                multi_sig=sig(ix);
                han_win=hanning(fs);
                multi_sig=abs(fft(multi_sig.*repmat(han_win,[1,n_steps,n_trials])))/fs;
                multi_sig=multi_sig(1:128,:,:);
                multi_sig=multi_sig(ft_freq_centers+1,:,:);
                multi_sig=permute(multi_sig,[2 1 3]);
                base_bool=1:n_steps<(n_steps/2);
                task_bool=step_ix/fs>=4;
                n_freqs=length(ft_freq_centers);

                file_feature_out=NaN(n_trials,n_freqs,4);
                %ft_names={'buff_amp_mean';'buff_amp_var';'baseline_amp_mean';'task_amp_mean'};
                %ft_freq_centers=[5 7 9 11 13 15 17 19 21 23 25 27 29];
                file_feature_out(:,:,3)=squeeze(nanmean(multi_sig(base_bool,:,:)))';
                file_feature_out(:,:,4)=squeeze(nanmean(multi_sig(task_bool,:,:)))';
                
                %Unfortunately the buffer requires stepping through trials.
                for tt=1:n_trials
                    trial=EERAT.Trial(dbx,'new',true,'subject_id',sub.subject_id,...
                        'datum_type_id',dat_lr_imagery.datum_type_id,...
                        'span_type','trial');
                    trial.periods=this_period;

                    buff.add(multi_sig(base_bool,:,tt));
                    file_feature_out(tt,:,1)=nanmean(buff.contents);
                    file_feature_out(tt,:,2)=nanvar(buff.contents);
                    buff.add(multi_sig(task_bool,:,tt));
                end

                per_feature_out=cat(1,per_feature_out,file_feature_out);
                per_detail_out=cat(1,per_detail_out,task_conditions);
                
                clear file_feature_out base_sig task_sig tt
                clear sig n_freqs n_trials task_conditions
                clear fname signal n_channels n_samples fs spatial_filter sig trig_sig
                clear task_starts task_stops task_conditions
                clear trial_ix step_ix ix n_overlap n_samps n_steamps overlapSample
                clear han_win multi_sig n_steps samp_ix fftStartTimes
            end%end for ff
        
            %Reshape per_feature_out. Make sure its order matches feature_names
            %order. Batch add of the features.
            this_period.set_trials_features(comb_feat_name,reshape(per_feature_out,[],length(comb_feat_name)));

            %Batch add the details
            this_period.set_trials_details({'dat_task_condition'},per_detail_out);
        end
        clear dir_files

        toc
    end%end for dd
    clear folder_list
end
%* possible frequency transformations include: filter-bank + hilbert, mem, stfft,
%wavelet, specgramc