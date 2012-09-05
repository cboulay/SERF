% Get x and y values from data
% x = [power(dB)(trials x freqs) ERD(trials x freqs) ANPower(trials x freqs) Task(1 x freqs)
% y = [RT]

%Power calculated from 500 msec preceding stimulus.
%ERD calculated as 100*(1- prestim_pow/baseline_pow), baseline from -4 to
%-1 before task
%AN power uses a ring buffer of 24 s from baseline_pow and prestim_pow for
%normalization
%Task is Rest or Imagery

import RT.*
subjectInfo;
temp(length(subject)) = RT.Subject(subject(length(subject)));
for ss=1:length(subject)
    subject(ss).session_subset='train'; %#ok<SAGROW>
    temp(ss) = RT.Subject(subject(ss));
end
subject = temp;
clear ss temp spat_filt

for ss=3:length(subject)
    sub = subject(ss);
    sub.load_data;
    
    freqs = sub.freq_edges(1:end-1)+1;
    
    sessions = sort(unique(sub.file_sess_n));
    tr_sess = [sub.trials.sess_n];
    tr_targs = [sub.trials.target];
    
    ch_bool = false(1,length(sub.eeg_channel_labels));
    for cc=1:length(sub.fb_chan)
        ch_bool = ch_bool | strcmpi(sub.eeg_channel_labels,sub.fb_chan{cc});
    end
    n_ch=sum(ch_bool);
    
    freq_bool = false(1,length(freqs));
    for ff=1:length(sub.fb_freq)
        freq_bool(find(abs(freqs-sub.fb_freq(ff))==min(abs(freqs-sub.fb_freq(ff))),1,'first'))=true;
    end
    n_freqs=sum(freq_bool);
    
    output = nan(length(sessions),n_ch,n_freqs,4);%last dim is baseline_amp, test_amp, erd, ana, accuracy
    accuracy = nan(length(sessions),1);
    for se = 1:length(sessions)
        this_trial_bool = tr_sess==sessions(se) & tr_targs==1;
        this_trials = sub.trials(this_trial_bool);
        n_trials=length(this_trials);
        %For each session, save 
        %baseline_amp
        sizes=size(this_trials(1).baseline_amp);
        temp = [this_trials.baseline_amp];
        temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
        output(se,:,:,1) = squeeze(mean(mean(temp(:,ch_bool,:,freq_bool)),3));
        %test_amp
        sizes=size(this_trials(1).test_amp);
        temp = [this_trials.test_amp];
        temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
        output(se,:,:,2) = squeeze(mean(mean(temp(:,ch_bool,:,freq_bool)),3));
        %erd
        sizes=size(this_trials(1).erd);
        temp = [this_trials.erd];
        temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
        output(se,:,:,3) = squeeze(mean(mean(temp(:,ch_bool,:,freq_bool)),3));
        %bc2k
        sizes=size(this_trials(1).bc2k);
        temp = [this_trials.bc2k];
        temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
        output(se,:,:,4) = squeeze(mean(mean(temp(:,ch_bool,:,freq_bool)),3));
        %accuracy
        accuracy(se)=sum(1-([this_trials.target]'-[this_trials.result]'))./n_trials;
        
%         for cc=1:n_ch
%             for ff=1:n_freqs
%                 output(se,cc,ff,1)=corr(test_power_db(:,cc,ff),erd(:,cc,ff));
%             end
%         end
%         
%         %correlation between test_power_db and bc2k
%         sizes=size(this_trials(1).bc2k);
%         temp = [this_trials.bc2k];
%         temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
%         temp = permute(temp,[3 1 2 4]);
%         temp = temp(:,:,ch_bool,freq_bool);
%         temp = squeeze(mean(temp,2));
%         temp = reshape(temp,[n_trials,n_ch,n_freqs]);
%         bc2k = temp;
%         
%         for cc=1:n_ch
%             for ff=1:n_freqs
%                 output(se,cc,ff,2)=corr(test_power_db(:,cc,ff),bc2k(:,cc,ff));
%             end
%         end
%         
%         %correlation between test_power_db and anp
%         sizes=size(this_trials(1).anp);
%         temp = [this_trials.bc2k];
%         temp = reshape(temp,[sizes(1:2),n_trials,sizes(3)]);
%         temp = permute(temp,[3 1 2 4]);
%         temp = temp(:,:,ch_bool,freq_bool);
%         temp = squeeze(mean(temp,2));
%         temp = reshape(temp,[n_trials,n_ch,n_freqs]);
%         anp = temp;
%         
%         for cc=1:n_ch
%             for ff=1:n_freqs
%                 output(se,cc,ff,3)=corr(test_power_db(:,cc,ff),anp(:,cc,ff));
%             end
%         end
    end
    
    output=(output-repmat(output(1,:,:,:),length(sessions),1))./repmat(abs(output(1,:,:,:)),length(sessions),1);
    figure;
    for cc=1:n_ch
        for ff=1:n_freqs
            subplot(n_ch,n_freqs,(cc-1)*n_freqs+ff)
%             plot([squeeze(output(:,cc,ff,:)) accuracy],'LineWidth',3)
            plot(squeeze(output(:,cc,ff,:)),'LineWidth',3)
            
            title([sub.name,' ',num2str(sub.fb_freq(ff)),'Hz ',sub.fb_chan{cc}])
        end
    end
    
    clear se this_trial_bool this_trials n_trials sizes temp cc ff
end

%output.with_rt_table is subjects x columns x isi x [rest v imagery , erd5 v erd 15]
%columns: [s_id pow_f pow_rsq pow_p erd_f erd_rsq erd_p anp_f anp_rsq anp_p task_rsq task_p]

%output.with_task_table is subjects x columns x [rest v imagery, erd5 v erd15]
%columns: [s_id pow_f pow_rsq pow_p erd_f erd_rsq erd_p anp_f anp_rsq anp_p]