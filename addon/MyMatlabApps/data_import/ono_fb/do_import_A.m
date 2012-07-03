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

% PREPARE DATABASE - only necessary once. Otherwise all you need is 
prepare_database;

%IMPORT THE DATA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get or create an experiment to group the subjects.
experiment = EERAT.Experiment(dbx,'Name','Ono_FB');
experiment.Description='Ono-san; Effect of different feedback conditions on EEG';

get_subject_info;%subject_info stored in a separate file.

%Prepare filterbank.
freq_edges=NaN(length(ft_freq_centers),2);
for ff=1:length(ft_freq_centers)
%     if ff==1
%         start_diff=(ft_freq_centers(ff+1)-ft_freq_centers(ff))/2;
%     else
%         start_diff=(ft_freq_centers(ff)-ft_freq_centers(ff-1))/2;
%     end
%     if ff==length(ft_freq_centers)
%         end_diff=start_diff;
%     else
%         end_diff=(ft_freq_centers(ff+1)-ft_freq_centers(ff))/2;
%     end
    start_diff=2; end_diff=2;
    freq_edges(ff,:)=[ft_freq_centers(ff)-start_diff ft_freq_centers(ff)+end_diff];
end
fbanks(2)=Filterbank(struct('freq_edges',freq_edges,'fs',1200));
fbanks(1)=Filterbank(struct('freq_edges',freq_edges,'fs',256));
clear ff start_diff end_diff

buffs(2)=Fifobuffer(struct('n_samples',24*1200,'n_channels',length(ft_freq_centers)));
buffs(1)=Fifobuffer(struct('n_samples',24*256,'n_channels',length(ft_freq_centers)));

%For each subject,
for ss=1:1%length(subject_info)
    si=subject_info(ss);
    %Get or create the subject. Subjects and data are special in that they
    %require their type to be passed in as an argument at creation time.
    sub=EERAT.Subject(dbx,'Name',['ONO_',si.Name],'subject_type_id',sub_type.subject_type_id);
    sub.experiments=experiment;
    %For each folder/day
    tic
    for dd=1:length(si.day)
        %Get the list of periods. See if the period corresponding to
        %this day already exists. If not, add it.
        file_date=si.day(dd).folder;
        file_date=datenum(file_date,'yymmdd');
        per_start=datestr(file_date,'yyyy-mm-dd HH:MM:SS');
        per_stop=datestr(file_date+(86399/86400),'yyyy-mm-dd HH:MM:SS');
        this_period=EERAT.Period(dbx,'subject_id',sub.subject_id,...
            'datum_type_id',dat_lr_imagery.datum_type_id,'span_type','period',...
            'StartTime',per_start,'EndTime',per_stop);
        
        per_feature_out=[];
        per_detail_out=[];
        for ff=1:length(si.day(dd).file_names)
            filestem=fullfile(si.base_dir,si.day(dd).folder,si.day(dd).file_names{ff});
            
            %open the text file to get the vector of trial conditions.
            fid=fopen([filestem,'.txt']);
            trial_class=fscanf(fid,'%s')';
            fclose(fid);
            t_class=NaN(length(trial_class),1);
            for tt=1:length(t_class)
                t_class(tt)=strcmpi(trial_class(tt),si.imagery_hand);
            end
            clear fid trial_class tt
            
            %open the data
            load([filestem,'.mat']);
            signal=squeeze(permute(simout.signals.values,[3 1 2]));
            [n_samples,n_channels]=size(signal);
            
            if n_channels==length(channel_labels{1})
                fs=256;
                if sum(~(signal(:,1)==0 | signal(:,1)==5))==0
                    ch_l=channel_labels{4};
                else
                    ch_l=channel_labels{1};
                end
            elseif n_channels==length(channel_labels{2})
                ch_l=channel_labels{2};
                fs=1200;
            else
                ch_l=channel_labels{3};
                fs=256;
            end
            if fs==256
                freq_ix=1;
            else
                freq_ix=2;
            end
            
            %spatial filter. I'm only interested in the lesion hemisphere.
            ref_chan_bool=false(size(ch_l));
            if strcmpi(si.imagery_hand,'L')
                cent_chan_bool=strcmpi(ch_l,'C4.');
                ref_chan_labels={'FC4','C2.','C6.','CP4'};
            else
                cent_chan_bool=strcmpi(ch_l,'C3.');
                ref_chan_labels={'FC3','C5.','C1.','CP3'};
            end
            for cc=1:length(ref_chan_labels)
                ref_chan_bool=ref_chan_bool | strcmpi(ch_l,ref_chan_labels{cc});
            end
            spatial_filter=double(cent_chan_bool)-(1/length(ref_chan_labels))*double(ref_chan_bool);
            spatial_filter=spatial_filter';
            sig=signal*spatial_filter;
            clear cc ref_chan_bool cent_chan_bool ref_chan_labels cc spatial_filter
            
            %find how many trials
            trig_chan_bool=strcmpi(ch_l,'trigger');
            trig_sig=signal(:,trig_chan_bool);
            task_starts=(find(diff([0;trig_sig])>0));
            task_stops=(find(diff([0;trig_sig])<0));
            n_trials=length(task_stops);
            
            %trim t_class to match trial indices
            t_class=t_class(1:n_trials);
            
            %signal processing.
            sig=fbanks(freq_ix).process(sig);
            sig=abs(hilbert(squeeze(sig)));
            n_freqs=size(sig,2);
            
            base_sig=nan(3*fs,n_trials,n_freqs);
            task_sig=nan(2*fs,n_trials,n_freqs);
            for tt=1:n_trials
                base_sig(:,tt,:)=sig(task_starts(tt)-4*fs:task_starts(tt)-fs-1,:);
                task_sig(:,tt,:)=sig(task_stops(tt)-2*fs:task_stops(tt)-1,:);
            end
            
            file_feature_out=NaN(n_trials,length(ft_freq_centers),4);
            %ft_names={'buff_amp_mean';'buff_amp_var';'baseline_amp_mean';'task_amp_mean'};
            %ft_freq_centers=[5 7 9 11 13 15 17 19 21 23 25 27 29];
            %Unfortunately the buffer requires stepping through trials.
            file_feature_out(:,:,3)=nanmean(squeeze(base_sig));
            file_feature_out(:,:,4)=nanmean(squeeze(task_sig));
                        
            isgood=true(n_trials,1);
            %See if there is a file indicating trials not to use.
            if ~isempty(dir([filestem,'_parameter.mat']))
                load([filestem,'_parameter.mat']);
                isgood(nonuseTrial)=false;
            end
            
            for tt=1:n_trials
                trial=EERAT.Trial(dbx,'new',true,'subject_id',sub.subject_id,...
                    'datum_type_id',dat_lr_imagery.datum_type_id,...
                    'span_type','trial','IsGood',isgood(tt));
                trial.periods=this_period;
                
                buffs(freq_ix).add(squeeze(base_sig(:,tt,:)));
                file_feature_out(tt,:,1)=nanmean(buffs(freq_ix).contents);
                file_feature_out(tt,:,2)=nanvar(buffs(freq_ix).contents);
                buffs(freq_ix).add(squeeze(task_sig(:,tt,:)));
            end
            
            per_feature_out=cat(1,per_feature_out,file_feature_out);
            per_detail_out=cat(1,per_detail_out,t_class);
        end%end for ff
        
        %Reshape per_feature_out. Make sure its order matches feature_names
        %order. Batch add of the features.
        this_period.set_trials_features(comb_feat_name,reshape(per_feature_out,[],length(comb_feat_name)));
        
        %Batch add the details
        this_period.set_trials_details({'dat_task_condition'},per_detail_out);
        clear per_feature_out per_detail_out
        toc
    end%end for dd
end
%* possible frequency transformations include: filter-bank + hilbert, mem, stfft,
%wavelet, specgramc